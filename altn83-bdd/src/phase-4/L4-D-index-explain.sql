ALTER SESSION SET CURRENT_SCHEMA = ACADEMY_NANOORBIT_PROJECT;

-- ============================================================
-- Ex.17 -- Index strategiques
-- Objectif : ameliorer les jointures et filtres frequents
-- identifies lors de la modelisation (L1-C).
--
-- Strategie :
--   a) Index sur FK non couvertes par PK (evite TABLE ACCESS FULL
--      lors des jointures parent -> enfant)
--   b) Index sur colonnes de filtrage recurrentes (statut, datetime)
--   c) Index composite pour les requetes multi-colonnes
--   d) Index fonctionnel pour les regroupements tronques par mois
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.17 : Creation des index strategiques ==='); END;
/

-- ----------------------------------------------------------
-- Drop conditionnel des index pour rendre le script idempotent.
-- Oracle ne supporte pas CREATE OR REPLACE INDEX. On capture
-- ORA-01418 (index inexistant) au premier run pour ne pas planter.
-- ----------------------------------------------------------
DECLARE
    TYPE t_index_list IS TABLE OF VARCHAR2(30);
    l_indexes t_index_list := t_index_list(
        'IDX_FC_SATELLITE',
        'IDX_FC_STATION',
        'IDX_PART_MISSION',
        'IDX_HIST_SATELLITE',
        'IDX_AFF_STATION',
        'IDX_SAT_STATUT',
        'IDX_FC_STATUT',
        'IDX_FC_DATETIME',
        'IDX_SAT_STATUT_FORMAT',
        'IDX_ORB_TYPE',
        'IDX_FC_MOIS'
    );
BEGIN
    FOR i IN 1 .. l_indexes.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX ' || l_indexes(i);
            DBMS_OUTPUT.PUT_LINE('[OK] Index ' || l_indexes(i) || ' supprime.');
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -1418 THEN
                    DBMS_OUTPUT.PUT_LINE('[Info] Index ' || l_indexes(i) || ' inexistant, skip.');
                ELSE
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

-- Nettoyage de la PLAN_TABLE pour avoir des plans frais a chaque run
DELETE FROM PLAN_TABLE
WHERE  statement_id IN (
    'PLAN_AVANT', 'PLAN_APRES',
    'PLAN_INVIS', 'PLAN_INVIS_SESSION', 'PLAN_VISIBLE'
);
COMMIT;

-- ----- a) Index sur cles etrangeres ------

-- FENETRE_COM.id_satellite : jointure SATELLITE -> FENETRE_COM (tres frequente)
CREATE INDEX idx_fc_satellite
    ON FENETRE_COM (id_satellite);

-- FENETRE_COM.code_station : jointure STATION_SOL -> FENETRE_COM
CREATE INDEX idx_fc_station
    ON FENETRE_COM (code_station);

-- PARTICIPATION.id_mission : jointure MISSION -> PARTICIPATION
CREATE INDEX idx_part_mission
    ON PARTICIPATION (id_mission);

-- HISTORIQUE_STATUT.id_satellite : jointure SATELLITE -> HISTORIQUE_STATUT
CREATE INDEX idx_hist_satellite
    ON HISTORIQUE_STATUT (id_satellite);

-- AFFECTATION_STATION.code_station : jointure STATION_SOL -> AFFECTATION_STATION
CREATE INDEX idx_aff_station
    ON AFFECTATION_STATION (code_station);

-- ----- b) Index sur colonnes de filtrage ------

-- SATELLITE.statut : filtre WHERE statut = 'Operationnel' (V1, L3-A/B/C)
CREATE INDEX idx_sat_statut
    ON SATELLITE (statut);

-- FENETRE_COM.statut : filtre WHERE statut = 'Realisee' tres recurrent
CREATE INDEX idx_fc_statut
    ON FENETRE_COM (statut);

-- FENETRE_COM.datetime_debut : ORDER BY et filtres temporels (Ex.13, Ex.14)
CREATE INDEX idx_fc_datetime
    ON FENETRE_COM (datetime_debut);

-- ----- c) Index composite ------

-- NOTE CDC : le sujet mentionne un index composite (statut, type_orbite) sur
-- SATELLITE, mais type_orbite est une colonne de la table ORBITE, pas de
-- SATELLITE. Un index ne peut couvrir que les colonnes de sa propre table.
-- Deux index sont donc crees :
--   1) SATELLITE(statut, format_cubesat) -- composite pertinent dans SATELLITE,
--      couvre les requetes qui filtrent sur statut ET groupent sur format_cubesat
--      (mv_volumes_mensuels, V1, rapport de pilotage section B)
--   2) ORBITE(type_orbite) -- couvre les requetes PARTITION BY type_orbite
--      des Ex.11 et Ex.14, ou la jointure SATELLITE->ORBITE est filtre sur type
CREATE INDEX idx_sat_statut_format
    ON SATELLITE (statut, format_cubesat);

-- ORBITE(type_orbite) : esprit du CDC (composite statut+type_orbite) -- couvre
-- les GROUP BY / PARTITION BY type_orbite dans les fonctions analytiques
CREATE INDEX idx_orb_type
    ON ORBITE (type_orbite);

-- ----- d) Index fonctionnel ------

-- TRUNC(datetime_debut, 'MM') : correspond exactement au GROUP BY de
-- mv_volumes_mensuels et des requetes mensuelles (Ex.13, Rapport pilotage)
CREATE INDEX idx_fc_mois
    ON FENETRE_COM (TRUNC(datetime_debut, 'MM'));

-- Verification des index crees
BEGIN DBMS_OUTPUT.PUT_LINE('--- Index crees : verification ---'); END;
/

SELECT index_name,
       table_name,
       index_type,
       uniqueness,
       status,
       visibility
FROM   user_indexes
WHERE  index_name IN (
    'IDX_FC_SATELLITE',  'IDX_FC_STATION',     'IDX_PART_MISSION',
    'IDX_HIST_SATELLITE','IDX_AFF_STATION',
    'IDX_SAT_STATUT',    'IDX_FC_STATUT',       'IDX_FC_DATETIME',
    'IDX_SAT_STATUT_FORMAT', 'IDX_ORB_TYPE',    'IDX_FC_MOIS'
)
ORDER BY table_name, index_name;
-- Attendu : 11 lignes, STATUS=VALID, VISIBILITY=VISIBLE

-- Resume des index par table
SELECT table_name,
       COUNT(*)                               AS nb_index_total,
       COUNT(CASE WHEN uniqueness = 'UNIQUE' THEN 1 END) AS nb_unique
FROM   user_indexes
WHERE  table_name IN (
    'ORBITE','SATELLITE','HISTORIQUE_STATUT','INSTRUMENT',
    'EMBARQUEMENT','CENTRE_CONTROLE','STATION_SOL',
    'AFFECTATION_STATION','MISSION','FENETRE_COM','PARTICIPATION'
)
GROUP  BY table_name
ORDER  BY table_name;


-- ============================================================
-- Ex.18 -- EXPLAIN PLAN : requete de reporting mensuel
--
-- Requete analysee : volume mensuel par centre et format CubeSat
-- (equivalent logique de mv_volumes_mensuels mais sans la MView,
--  pour forcer Oracle a lire les tables de base et montrer le plan).
--
-- On utilise NO_MERGE pour desactiver la reutilisation de la MView
-- et observer le plan sur les tables brutes.
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.18 : EXPLAIN PLAN -- Requete de reporting mensuel ==='); END;
/

-- ----- Etape 1 : Plan AVANT creation de idx_fc_mois ------
-- (idx_fc_mois a ete cree ci-dessus ; pour simuler le plan "sans",
--  on le rend invisible temporairement puis on le reaffiche)

ALTER INDEX idx_fc_mois INVISIBLE;

EXPLAIN PLAN SET STATEMENT_ID = 'PLAN_AVANT' FOR
SELECT
    TRUNC(fc.datetime_debut, 'MM')        AS mois,
    TO_CHAR(fc.datetime_debut, 'YYYY-MM') AS mois_label,
    cc.id_centre,
    cc.nom_centre,
    s.format_cubesat,
    COUNT(fc.id_fenetre)                  AS nb_fenetres,
    SUM(fc.volume_donnees)                AS volume_total_mo
FROM   FENETRE_COM        fc
JOIN   SATELLITE          s   ON fc.id_satellite = s.id_satellite
JOIN   STATION_SOL        st  ON fc.code_station  = st.code_station
JOIN   AFFECTATION_STATION aff ON st.code_station = aff.code_station
JOIN   CENTRE_CONTROLE    cc  ON aff.id_centre    = cc.id_centre
WHERE  fc.statut = 'Realisee'
GROUP  BY TRUNC(fc.datetime_debut, 'MM'),
          TO_CHAR(fc.datetime_debut, 'YYYY-MM'),
          cc.id_centre, cc.nom_centre, s.format_cubesat
ORDER  BY mois, cc.id_centre, s.format_cubesat;

BEGIN DBMS_OUTPUT.PUT_LINE('[Plan AVANT idx_fc_mois visible]'); END;
/

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    statement_id => 'PLAN_AVANT',
    format       => 'TYPICAL'
));
-- Observations attendues :
--   FENETRE_COM : INDEX RANGE SCAN (idx_fc_statut) ou TABLE ACCESS FULL
--   SATELLITE   : TABLE ACCESS BY INDEX ROWID (pk) ou FULL
--   Pas d'utilisation de idx_fc_mois (invisible)
--   Hash Join ou Nested Loop pour les jointures

-- ----- Etape 2 : Plan APRES activation de idx_fc_mois ------

ALTER INDEX idx_fc_mois VISIBLE;

EXPLAIN PLAN SET STATEMENT_ID = 'PLAN_APRES' FOR
SELECT
    TRUNC(fc.datetime_debut, 'MM')        AS mois,
    TO_CHAR(fc.datetime_debut, 'YYYY-MM') AS mois_label,
    cc.id_centre,
    cc.nom_centre,
    s.format_cubesat,
    COUNT(fc.id_fenetre)                  AS nb_fenetres,
    SUM(fc.volume_donnees)                AS volume_total_mo
FROM   FENETRE_COM        fc
JOIN   SATELLITE          s   ON fc.id_satellite = s.id_satellite
JOIN   STATION_SOL        st  ON fc.code_station  = st.code_station
JOIN   AFFECTATION_STATION aff ON st.code_station = aff.code_station
JOIN   CENTRE_CONTROLE    cc  ON aff.id_centre    = cc.id_centre
WHERE  fc.statut = 'Realisee'
GROUP  BY TRUNC(fc.datetime_debut, 'MM'),
          TO_CHAR(fc.datetime_debut, 'YYYY-MM'),
          cc.id_centre, cc.nom_centre, s.format_cubesat
ORDER  BY mois, cc.id_centre, s.format_cubesat;

BEGIN DBMS_OUTPUT.PUT_LINE('[Plan APRES idx_fc_mois visible]'); END;
/

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    statement_id => 'PLAN_APRES',
    format       => 'TYPICAL'
));
-- Observations attendues avec data set reduit (5 fenetres) :
--   Oracle peut garder TABLE ACCESS FULL (cout faible sur petite table)
--   Sur volume important : INDEX RANGE SCAN sur idx_fc_mois attendu
--   idx_fc_statut couvre le WHERE statut = 'Realisee'
--   Gainers principaux en prod : idx_fc_mois + idx_fc_statut + idx_fc_satellite

-- ----- Etape 3 : Comparaison des deux plans ------
BEGIN DBMS_OUTPUT.PUT_LINE('[Comparaison AVANT / APRES]'); END;
/

SELECT p.id           AS plan_id,
       p.operation,
       p.options,
       p.object_name,
       p.cost,
       p.cardinality  AS card_estimee,
       p.bytes
FROM   PLAN_TABLE p
WHERE  p.statement_id IN ('PLAN_AVANT', 'PLAN_APRES')
ORDER  BY p.statement_id, p.id;


-- ============================================================
-- Ex.19 -- Index invisible : simulation d'activation selective
--
-- Objectif : montrer comment INVISIBLE permet de tester un index
-- sans impacter les sessions de production (autre que la session
-- courante qui peut le forcer avec OPTIMIZER_USE_INVISIBLE_INDEXES).
--
-- Sequence :
--   1. idx_sat_statut -> INVISIBLE => plan TABLE ACCESS FULL
--   2. idx_sat_statut -> VISIBLE   => plan INDEX RANGE SCAN
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.19 : Index invisible -- idx_sat_statut ==='); END;
/

-- Etape 1 : rendre l'index invisible
ALTER INDEX idx_sat_statut INVISIBLE;

BEGIN DBMS_OUTPUT.PUT_LINE('[Etape 1] idx_sat_statut INVISIBLE'); END;
/

EXPLAIN PLAN SET STATEMENT_ID = 'PLAN_INVIS' FOR
SELECT id_satellite, nom_satellite, statut, format_cubesat
FROM   SATELLITE
WHERE  statut = 'Operationnel'
ORDER  BY id_satellite;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    statement_id => 'PLAN_INVIS',
    format       => 'BASIC +COST'
));
-- Attendu : TABLE ACCESS FULL SATELLITE (index ignore car invisible)
-- Le CBO ne voit pas idx_sat_statut => scan complet

-- Etape 2 : activer l'index pour la session courante uniquement
-- (simule un test A/B sans toucher les autres sessions)
ALTER SESSION SET OPTIMIZER_USE_INVISIBLE_INDEXES = TRUE;

EXPLAIN PLAN SET STATEMENT_ID = 'PLAN_INVIS_SESSION' FOR
SELECT id_satellite, nom_satellite, statut, format_cubesat
FROM   SATELLITE
WHERE  statut = 'Operationnel'
ORDER  BY id_satellite;

BEGIN DBMS_OUTPUT.PUT_LINE('[Etape 2] Session avec OPTIMIZER_USE_INVISIBLE_INDEXES=TRUE'); END;
/

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    statement_id => 'PLAN_INVIS_SESSION',
    format       => 'BASIC +COST'
));
-- Attendu : INDEX RANGE SCAN idx_sat_statut + TABLE ACCESS BY INDEX ROWID
-- (index visible pour cette session seulement => validation sans risque prod)

-- Etape 3 : remettre l'index VISIBLE (retablissement definitif)
ALTER SESSION SET OPTIMIZER_USE_INVISIBLE_INDEXES = FALSE;
ALTER INDEX idx_sat_statut VISIBLE;

EXPLAIN PLAN SET STATEMENT_ID = 'PLAN_VISIBLE' FOR
SELECT id_satellite, nom_satellite, statut, format_cubesat
FROM   SATELLITE
WHERE  statut = 'Operationnel'
ORDER  BY id_satellite;

BEGIN DBMS_OUTPUT.PUT_LINE('[Etape 3] idx_sat_statut VISIBLE (retabli)'); END;
/

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    statement_id => 'PLAN_VISIBLE',
    format       => 'BASIC +COST'
));
-- Attendu : INDEX RANGE SCAN idx_sat_statut (visible pour tous)

-- Verification finale de l'etat des index
SELECT index_name, visibility, status
FROM   user_indexes
WHERE  index_name IN ('IDX_SAT_STATUT', 'IDX_FC_MOIS')
ORDER  BY index_name;
-- Attendu : les deux VISIBLE / VALID


-- ============================================================
-- RAPPORT DE PILOTAGE INTEGRAL
-- Dashboard analytique final NanoOrbit
--
-- Objectif : requete unique combinant CTE, fonctions analytiques,
-- vue materialisee et calculs de tendance pour un tableau de bord
-- operationnel complet.
--
-- Sections du rapport :
--   A. Classement des centres par volume telecharge (avec % et LAG)
--   B. Activite par satellite : volume cumule + rang global + rang par orbite
--   C. Synthese des missions actives
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== Rapport de pilotage integral NanoOrbit ==='); END;
/

-- ---- A. Classement des centres de controle par volume -----
BEGIN DBMS_OUTPUT.PUT_LINE('--- A. Classement centres de controle ---'); END;
/

WITH centres_volumes AS (
    -- Agregation depuis la vue materialisee (deja calculee)
    SELECT
        id_centre,
        nom_centre,
        ville_centre,
        region_geo,
        SUM(nb_fenetres)       AS total_fenetres,
        SUM(volume_total_mo)   AS volume_total_mo,
        SUM(nb_satellites_actifs) AS satellites_distincts
    FROM   mv_volumes_mensuels
    GROUP  BY id_centre, nom_centre, ville_centre, region_geo
),
centres_ranked AS (
    SELECT
        cv.*,
        RANK() OVER (ORDER BY cv.volume_total_mo DESC NULLS LAST) AS rang_volume,
        ROUND(
            cv.volume_total_mo * 100.0
            / NULLIF(SUM(cv.volume_total_mo) OVER (), 0),
            1
        )                                                          AS pct_volume_global,
        LAG(cv.volume_total_mo) OVER (ORDER BY cv.volume_total_mo DESC NULLS LAST)
                                                                   AS volume_centre_precedent,
        ROUND(
            (cv.volume_total_mo - LAG(cv.volume_total_mo) OVER (ORDER BY cv.volume_total_mo DESC NULLS LAST))
            * 100.0
            / NULLIF(LAG(cv.volume_total_mo) OVER (ORDER BY cv.volume_total_mo DESC NULLS LAST), 0),
            1
        )                                                          AS ecart_pct_vs_precedent
    FROM   centres_volumes cv
)
SELECT
    rang_volume                                    AS rang,
    id_centre,
    nom_centre,
    ville_centre,
    region_geo,
    total_fenetres,
    volume_total_mo                                AS volume_mo,
    pct_volume_global                              AS pct_global,
    NVL(TO_CHAR(ecart_pct_vs_precedent)||'%', 'N/A') AS ecart_vs_rang_sup
FROM   centres_ranked
ORDER  BY rang_volume;
-- Attendu (avec jeu de donnees actuel) :
--   Rang 1 : CTR-001 | NanoOrbit Paris HQ | Paris | Europe | 3 fenetres | 3820 Mo | 100%
--   CTR-002 (Houston) absent car GS-SGP-01 en Maintenance, aucune fenetre Realisee

-- ---- B. Activite par satellite : volume cumule + rang -----
BEGIN DBMS_OUTPUT.PUT_LINE('--- B. Activite par satellite ---'); END;
/

WITH sat_activite AS (
    SELECT
        s.id_satellite,
        s.nom_satellite,
        s.statut,
        s.format_cubesat,
        o.type_orbite,
        o.altitude,
        NVL(SUM(CASE WHEN fc.statut = 'Realisee' THEN fc.volume_donnees END), 0) AS volume_realise_mo,
        COUNT(CASE WHEN fc.statut = 'Realisee' THEN 1 END)                        AS nb_fenetres_realisees,
        COUNT(CASE WHEN fc.statut = 'Planifiee' THEN 1 END)                       AS nb_fenetres_planifiees,
        MAX(CASE WHEN fc.statut = 'Realisee' THEN fc.datetime_debut END)          AS derniere_realisation
    FROM   SATELLITE    s
    JOIN   ORBITE       o  ON s.id_orbite    = o.id_orbite
    LEFT JOIN FENETRE_COM fc ON s.id_satellite = fc.id_satellite
    GROUP  BY s.id_satellite, s.nom_satellite, s.statut, s.format_cubesat,
              o.type_orbite, o.altitude
),
sat_ranked AS (
    SELECT
        sa.*,
        RANK()       OVER (ORDER BY sa.volume_realise_mo DESC)                   AS rang_global,
        DENSE_RANK() OVER (PARTITION BY sa.type_orbite ORDER BY sa.volume_realise_mo DESC)
                                                                                 AS rang_par_orbite,
        SUM(sa.volume_realise_mo) OVER (ORDER BY sa.volume_realise_mo DESC
                                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                                                                 AS volume_cumule_mo,
        ROUND(
            sa.volume_realise_mo * 100.0
            / NULLIF(SUM(sa.volume_realise_mo) OVER (), 0),
            1
        )                                                                        AS pct_volume_global,
        ROUND(
            sa.volume_realise_mo - AVG(sa.volume_realise_mo) OVER (),
            0
        )                                                                        AS ecart_vs_moyenne
    FROM   sat_activite sa
)
SELECT
    rang_global,
    rang_par_orbite                                AS rang_orbite,
    id_satellite,
    nom_satellite,
    statut,
    format_cubesat,
    type_orbite,
    altitude                                       AS alt_km,
    volume_realise_mo                              AS volume_mo,
    pct_volume_global                              AS pct_global,
    volume_cumule_mo,
    ecart_vs_moyenne,
    nb_fenetres_realisees                          AS fc_realisees,
    nb_fenetres_planifiees                         AS fc_planifiees,
    TO_CHAR(derniere_realisation, 'DD/MM/YYYY')    AS derniere_fc
FROM   sat_ranked
ORDER  BY rang_global, id_satellite;
-- Attendu :
--   Rang 1 | Rang orbite 1 | SAT-003 | NanoOrbit-Gamma | Operationnel | 6U | SSO | 700km | 1680 Mo | 44% | 1680  | +406.7 | 1 | 1 | 15/01/2024
--   Rang 2 | Rang orbite 2 | SAT-001 | NanoOrbit-Alpha  | Operationnel | 3U | SSO | 550km | 1250 Mo | 32.7% | 2930  | -23.3 | 1 | 1 | 10/01/2024
--   Rang 3 | Rang orbite 3 | SAT-002 | NanoOrbit-Beta   | Operationnel | 3U | SSO | 550km |  890 Mo | 23.3% | 3820  | -383.3| 1 | 0 | 12/01/2024
--   Rang 4 | Rang orbite 4 | SAT-004 | NanoOrbit-Delta  | En veille    | 3U | SSO | 550km |    0 Mo |  0%   | 3820  | -...  | 0 | 0 | NULL
--   Rang 4 | Rang orbite 4 | SAT-005 | NanoOrbit-Epsilon| Desorbite    | 3U | LEO |400km  |    0 Mo |  0%   | 3820  | -...  | 0 | 0 | NULL
--   (SAT-004 et SAT-005 a egalite, RANK=4, volume_cumule reste 3820)

-- ---- C. Synthese missions actives -----
BEGIN DBMS_OUTPUT.PUT_LINE('--- C. Synthese missions actives ---'); END;
/

WITH missions_stats AS (
    SELECT
        m.id_mission,
        m.nom_mission,
        m.statut_mission,
        m.date_debut,
        m.date_fin,
        COUNT(DISTINCT p.id_satellite)                                        AS nb_satellites,
        LISTAGG(DISTINCT s.nom_satellite, ' | ')
            WITHIN GROUP (ORDER BY s.nom_satellite)                           AS satellites,
        NVL(SUM(CASE WHEN fc.statut = 'Realisee' THEN fc.volume_donnees END), 0)
                                                                              AS volume_realise_mo,
        COUNT(DISTINCT CASE WHEN fc.statut = 'Realisee' THEN fc.id_fenetre END)
                                                                              AS nb_fenetres_realisees,
        ROUND(SYSDATE - m.date_debut)                                         AS jours_depuis_debut
    FROM   MISSION        m
    LEFT JOIN PARTICIPATION p  ON m.id_mission   = p.id_mission
    LEFT JOIN SATELLITE     s  ON p.id_satellite = s.id_satellite
    LEFT JOIN FENETRE_COM   fc ON p.id_satellite = fc.id_satellite
    GROUP  BY m.id_mission, m.nom_mission, m.statut_mission, m.date_debut, m.date_fin
)
SELECT
    id_mission,
    nom_mission,
    statut_mission,
    TO_CHAR(date_debut, 'DD/MM/YYYY')                    AS debut,
    NVL(TO_CHAR(date_fin, 'DD/MM/YYYY'), 'En cours')     AS fin,
    jours_depuis_debut                                   AS age_jours,
    nb_satellites,
    satellites,
    nb_fenetres_realisees                                AS fc_realisees,
    volume_realise_mo                                    AS volume_mo,
    RANK() OVER (ORDER BY volume_realise_mo DESC)        AS rang_volume,
    ROUND(
        volume_realise_mo * 100.0
        / NULLIF(SUM(volume_realise_mo) OVER (), 0),
        1
    )                                                    AS pct_volume_total
FROM   missions_stats
ORDER  BY rang_volume, id_mission;
-- Attendu :
--   Rang 1 | MSN-ARC-2023  | ArcticWatch 2023  | Active   | 3 sats | 3 fc | 3820 Mo | ~40%
--   Rang 2 | MSN-COAST-2024| CoastGuard 2024   | Active   | 2 sats | 1 fc | 1680 Mo | ~21%
--   Rang 3 | MSN-DEF-2022  | DeforestAlert     | Terminee | 2 sats | 1 fc | 1250 Mo | ~16%
--   (Note : SAT-001 participe a ARC-2023 ET DEF-2022 -> son volume compte dans les deux)
--   pct_volume_total se base sur la somme des volumes par mission
--   (somme > 3820 Mo total reel car double-comptage SAT-001 : 3820+1680+1250=6750 denominateur)

-- ---- D. Vue d'ensemble mv_volumes_mensuels enrichie -----
BEGIN DBMS_OUTPUT.PUT_LINE('--- D. Vue d ensemble mensuelle (MView enrichie) ---'); END;
/

SELECT
    mois_label,
    nom_centre,
    ville_centre,
    region_geo,
    format_cubesat,
    nb_fenetres,
    volume_total_mo,
    volume_moyen_mo,
    nb_satellites_actifs,
    RANK() OVER (PARTITION BY mois ORDER BY volume_total_mo DESC) AS rang_mois,
    ROUND(
        volume_total_mo * 100.0
        / SUM(volume_total_mo) OVER (PARTITION BY mois),
        1
    )                                                              AS pct_mois
FROM   mv_volumes_mensuels
ORDER  BY mois, rang_mois;
-- Attendu :
--   2024-01 | NanoOrbit Paris HQ | Paris | Europe | 6U | 1 fenetre | 1680 Mo | 1680.0 | 1 sat | Rang 1 | 44%
--   2024-01 | NanoOrbit Paris HQ | Paris | Europe | 3U | 2 fenetres| 2140 Mo | 1070.0 | 2 sats| Rang 2 | 56%
--   (Rang 1 : 6U car 1680 > 2140? non 2140 > 1680 -> 3U rang 1)
-- Correction attendu :
--   2024-01 | ... | 3U | 2 fenetres | 2140 Mo | ... | Rang 1 | 56%
--   2024-01 | ... | 6U | 1 fenetre  | 1680 Mo | ... | Rang 2 | 44%

-- ============================================================
-- Verification globale Phase 4 -- recap de tous les objets crees
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== VERIFICATION GLOBALE -- Phase 4 ==='); END;
/

-- Vues et MViews
SELECT object_name, object_type, status
FROM   user_objects
WHERE  object_type IN ('VIEW', 'MATERIALIZED VIEW')
  AND  object_name IN (
       'V_SATELLITES_OPERATIONNELS',
       'V_FENETRES_DETAIL',
       'V_STATS_MISSIONS',
       'MV_VOLUMES_MENSUELS'
  )
ORDER  BY object_type, object_name;
-- Attendu : 4 lignes STATUS=VALID

-- Index de phase 4
SELECT index_name, table_name, index_type, uniqueness, visibility, status
FROM   user_indexes
WHERE  index_name LIKE 'IDX_%'
ORDER  BY table_name, index_name;
-- Attendu : 10 index VISIBLE/VALID

-- ============================================================
-- FIN L4-D -- Index, EXPLAIN PLAN et Rapport de pilotage NanoOrbit
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== FIN Phase 4 -- NanoOrbit ALTN83 ===');
    DBMS_OUTPUT.PUT_LINE('Objets crees : 4 vues (V1-V4) + 11 index + 3 rapports SQL');
END;
/
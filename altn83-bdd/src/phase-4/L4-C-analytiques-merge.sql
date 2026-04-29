ALTER SESSION SET CURRENT_SCHEMA = ACADEMY_NANOORBIT_PROJECT;

-- ============================================================
-- PARTIE 4 -- FONCTIONS ANALYTIQUES OVER
-- ============================================================

-- ------------------------------------------------------------
-- Ex. 11 -- ROW_NUMBER / RANK / DENSE_RANK
-- Classement des satellites par volume total telecharge,
-- d'abord global, puis par type d'orbite (PARTITION BY type_orbite).
--
-- Differente entre les trois fonctions :
--   ROW_NUMBER : numerotation stricte, pas d'ex-aequo (1,2,3,4,5)
--   RANK       : ex-aequo --> meme rang, saut suivant (1,1,3,3,5)
--   DENSE_RANK : ex-aequo --> meme rang, pas de saut (1,1,2,2,3)
--
-- Resultats attendus (classement global par volume DESC) :
--   Rang 1 | SAT-003 | 1680 Mo | SSO
--   Rang 2 | SAT-001 | 1250 Mo | SSO
--   Rang 3 | SAT-002 |  890 Mo | SSO
--   Rang 4 | SAT-004 |    0 Mo | SSO  (ex-aequo avec SAT-005)
--   Rang 4 | SAT-005 |    0 Mo | LEO  (ex-aequo : RANK=4, DENSE_RANK=4)
--
-- Par orbite SSO : SAT-003(1) > SAT-001(2) > SAT-002(3) > SAT-004(4)
-- Par orbite LEO : SAT-005(1)
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.11 : ROW_NUMBER / RANK / DENSE_RANK ==='); END;
/

SELECT
    s.id_satellite,
    s.nom_satellite,
    o.type_orbite,
    NVL(SUM(fc.volume_donnees), 0)                         AS volume_total_mo,
    -- Classement global (toutes orbites)
    ROW_NUMBER() OVER (ORDER BY NVL(SUM(fc.volume_donnees), 0) DESC)
                                                            AS row_num_global,
    RANK()       OVER (ORDER BY NVL(SUM(fc.volume_donnees), 0) DESC)
                                                            AS rank_global,
    DENSE_RANK() OVER (ORDER BY NVL(SUM(fc.volume_donnees), 0) DESC)
                                                            AS dense_rank_global,
    -- Classement par type d'orbite (PARTITION BY)
    RANK() OVER (
        PARTITION BY o.type_orbite
        ORDER     BY NVL(SUM(fc.volume_donnees), 0) DESC
    )                                                       AS rank_par_orbite
FROM   SATELLITE    s
JOIN   ORBITE       o  ON s.id_orbite    = o.id_orbite
LEFT JOIN FENETRE_COM fc ON s.id_satellite = fc.id_satellite
                         AND fc.statut = 'Realisee'
GROUP  BY s.id_satellite, s.nom_satellite, o.type_orbite
ORDER  BY volume_total_mo DESC, s.id_satellite;

-- ------------------------------------------------------------
-- Ex. 12 -- LAG / LEAD
-- Pour chaque fenetre de communication d'une station, comparer
-- le volume avec la fenetre precedente (LAG) et la suivante (LEAD),
-- et calculer l'evolution en pourcentage.
--
-- Fenetres ordonnees par datetime_debut au sein de chaque station :
--   GS-KIR-01 :
--     F#1 (09:14 15/01 | 1250 Mo) -> pas de precedente | suivante = F#3 (1680 Mo)
--     F#3 (08:30 16/01 | 1680 Mo) -> precedente = F#1 (1250) | evol = +34.4%
--   GS-TLS-01 :
--     F#2 (11:52 15/01 |  890 Mo) -> pas de precedente | suivante = F#4 (NULL, planifiee)
--     F#4 (14:22 20/01 |  NULL)   -> precedente = F#2 (890)  | N/A (planifiee)
--     F#5 (07:45 21/01 |  NULL)   -> precedente = F#4 (NULL) | N/A (planifiee)
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.12 : LAG / LEAD -- Evolution volume par station ==='); END;
/

SELECT
    fc.code_station,
    fc.id_fenetre,
    TO_CHAR(fc.datetime_debut, 'DD/MM/YYYY HH24:MI') AS debut,
    fc.statut,
    fc.volume_donnees                                 AS volume_mo,
    -- Volume de la fenetre precedente sur la meme station
    LAG(fc.volume_donnees) OVER (
        PARTITION BY fc.code_station
        ORDER     BY fc.datetime_debut
    )                                                 AS volume_precedent_mo,
    -- Volume de la fenetre suivante sur la meme station
    LEAD(fc.volume_donnees) OVER (
        PARTITION BY fc.code_station
        ORDER     BY fc.datetime_debut
    )                                                 AS volume_suivant_mo,
    -- Evolution en % par rapport a la fenetre precedente
    CASE
        WHEN LAG(fc.volume_donnees) OVER (
                 PARTITION BY fc.code_station ORDER BY fc.datetime_debut
             ) IS NULL
          OR LAG(fc.volume_donnees) OVER (
                 PARTITION BY fc.code_station ORDER BY fc.datetime_debut
             ) = 0
        THEN NULL
        ELSE ROUND(
            (fc.volume_donnees - LAG(fc.volume_donnees) OVER (
                 PARTITION BY fc.code_station ORDER BY fc.datetime_debut
             )) * 100.0
            / LAG(fc.volume_donnees) OVER (
                 PARTITION BY fc.code_station ORDER BY fc.datetime_debut
             ),
            1
        )
    END                                               AS evolution_pct
FROM   FENETRE_COM fc
ORDER  BY fc.code_station, fc.datetime_debut;
-- GS-KIR-01 / F#3 : evolution = ROUND((1680-1250)/1250*100, 1) = +34.4%
-- GS-TLS-01 : 1 seule fenetre realisee (F#2), pas d'evolution calculable realisee

-- ------------------------------------------------------------
-- Ex. 13 -- SUM OVER (cumul + moyenne mobile)
-- Volumes cumules chronologiquement par centre de controle,
-- avec moyenne mobile sur les 3 dernieres fenetres realisees.
--
-- Resultats attendus (CTR-001, fenetres realisees ordonnees par date) :
--   F#1 | 2024-01-15 09:14 | 1250 Mo | cumul=1250 | moy3=1250.0
--   F#2 | 2024-01-15 11:52 |  890 Mo | cumul=2140 | moy3=1070.0
--   F#3 | 2024-01-16 08:30 | 1680 Mo | cumul=3820 | moy3=1273.3
--
-- Note : CTR-002 n'a aucune fenetre realisee -- absent du resultat.
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.13 : SUM OVER -- Volumes cumules + moyenne mobile (3 fenetres) ==='); END;
/

SELECT
    cc.id_centre,
    cc.nom_centre,
    fc.id_fenetre,
    TO_CHAR(fc.datetime_debut, 'DD/MM/YYYY HH24:MI') AS debut,
    fc.code_station,
    fc.volume_donnees                                  AS volume_mo,
    -- Volume cumule chronologique par centre
    SUM(fc.volume_donnees) OVER (
        PARTITION BY cc.id_centre
        ORDER     BY fc.datetime_debut
        ROWS      BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                  AS volume_cumul_mo,
    -- Moyenne mobile sur les 3 dernieres fenetres (fenetre glissante)
    ROUND(
        AVG(fc.volume_donnees) OVER (
            PARTITION BY cc.id_centre
            ORDER     BY fc.datetime_debut
            ROWS      BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        1
    )                                                  AS moy_mobile_3_mo,
    -- Rang de cette fenetre au sein du centre
    ROW_NUMBER() OVER (
        PARTITION BY cc.id_centre
        ORDER     BY fc.datetime_debut
    )                                                  AS rang_chrono
FROM   FENETRE_COM          fc
JOIN   STATION_SOL          st  ON fc.code_station = st.code_station
JOIN   AFFECTATION_STATION  aff ON st.code_station = aff.code_station
JOIN   CENTRE_CONTROLE      cc  ON aff.id_centre   = cc.id_centre
WHERE  fc.statut = 'Realisee'
ORDER  BY cc.id_centre, fc.datetime_debut;

-- ------------------------------------------------------------
-- Ex. 14 -- Tableau de bord constellation
-- Requete de synthese combinant RANK + SUM OVER + ROUND pour
-- produire le rapport mensuel operationnel NanoOrbit :
--   - Rang du satellite par volume (classement mensuel)
--   - Part en % du volume total telecharge
--   - Volume cumule dans le classement
--   - Comparaison a la moyenne (ecart)
--
-- Resultats attendus (janvier 2024, 3 satellites avec fenetres realisees) :
--   Rang 1 | SAT-003 | 1680 Mo | 44.0% | cumul=1680 | ecart=+406.7
--   Rang 2 | SAT-001 | 1250 Mo | 32.7% | cumul=2930 | ecart=-23.3
--   Rang 3 | SAT-002 |  890 Mo | 23.3% | cumul=3820 | ecart=-383.3
--   (SAT-004 et SAT-005 : 0 Mo, exclus car pas de fenetre realisee)
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.14 : Tableau de bord constellation ==='); END;
/

WITH sat_monthly AS (
    SELECT
        s.id_satellite,
        s.nom_satellite,
        s.statut,
        o.type_orbite,
        TO_CHAR(fc.datetime_debut, 'YYYY-MM') AS mois,
        SUM(fc.volume_donnees)                AS volume_mo,
        COUNT(fc.id_fenetre)                  AS nb_fenetres
    FROM   SATELLITE    s
    JOIN   ORBITE       o  ON s.id_orbite    = o.id_orbite
    JOIN   FENETRE_COM  fc ON s.id_satellite = fc.id_satellite
                           AND fc.statut = 'Realisee'
    GROUP  BY s.id_satellite, s.nom_satellite, s.statut,
              o.type_orbite, TO_CHAR(fc.datetime_debut, 'YYYY-MM')
)
SELECT
    mois,
    RANK() OVER (
        PARTITION BY mois
        ORDER     BY volume_mo DESC
    )                                                             AS rang,
    id_satellite,
    nom_satellite,
    type_orbite,
    nb_fenetres,
    volume_mo,
    -- Part en % du volume total du mois
    ROUND(
        volume_mo * 100.0 / SUM(volume_mo) OVER (PARTITION BY mois),
        1
    )                                                             AS pct_volume,
    -- Volume cumule dans l'ordre du classement
    SUM(volume_mo) OVER (
        PARTITION BY mois
        ORDER     BY volume_mo DESC
        ROWS      BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                             AS volume_cumul_mo,
    -- Volume total du mois (pour reference)
    SUM(volume_mo) OVER (PARTITION BY mois)                       AS volume_total_mois_mo,
    -- Ecart a la moyenne mensuelle
    ROUND(
        volume_mo - AVG(volume_mo) OVER (PARTITION BY mois),
        1
    )                                                             AS ecart_moy_mo
FROM   sat_monthly
ORDER  BY mois, rang;

-- ============================================================
-- PARTIE 5 -- MERGE INTO
-- ============================================================

-- ------------------------------------------------------------
-- Ex. 15 -- MERGE INTO : synchronisation statuts satellites (IoT)
-- Scenario : un systeme IoT externe transmet un lot de mises
-- a jour de statuts satellites.
--   - Si le satellite existe : UPDATE statut + orbite courante
--   - Si le satellite n'existe pas : INSERT avec statut 'En veille'
--
-- Lot de mise a jour :
--   SAT-001 : Operationnel -> Operationnel (pas de changement, T5 silencieux)
--   SAT-004 : En veille   -> Operationnel  (T5 trace le changement)
--   SAT-NEW-001 : nouveau  -> insertion avec 'En veille'
--
-- ROLLBACK final pour preserver le jeu de reference.
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.15 : MERGE INTO -- Sync statuts satellites (IoT) ==='); END;
/

-- Source IoT : lot de mises a jour entrantes
-- (en pratique : lue depuis une table de staging ou un fichier externe)
MERGE INTO SATELLITE s
USING (
    SELECT 'SAT-001'     AS id_sat, 'Operationnel' AS new_statut, 'ORB-001' AS new_orbite
                                                                             FROM DUAL
    UNION ALL
    SELECT 'SAT-004',              'Operationnel',                'ORB-002' FROM DUAL
    UNION ALL
    SELECT 'SAT-NEW-001',          'En veille',                  'ORB-001' FROM DUAL
) src
ON (s.id_satellite = src.id_sat)
-- Satellite existant : mettre a jour statut et orbite courante
-- Le trigger T5 (trg_historique_statut) se declenche si statut change.
WHEN MATCHED THEN
    UPDATE SET
        s.statut    = src.new_statut,
        s.id_orbite = src.new_orbite
-- Nouveau satellite : insertion avec valeurs minimales requises
WHEN NOT MATCHED THEN
    INSERT (
        id_satellite, nom_satellite, date_lancement,
        masse, format_cubesat, statut,
        duree_vie_prevue, capacite_batterie, id_orbite
    )
    VALUES (
        src.id_sat,
        'IoT-' || src.id_sat,
        SYSDATE,
        1.00, '1U',
        src.new_statut,
        36, 10.0,
        src.new_orbite
    );

-- Verification post-MERGE
DECLARE
    v_nb_sats   NUMBER;
    v_nb_hist   NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nb_sats FROM SATELLITE;
    SELECT COUNT(*) INTO v_nb_hist FROM HISTORIQUE_STATUT;
    DBMS_OUTPUT.PUT_LINE('[Ex.15] Satellites apres MERGE : ' || v_nb_sats ||
                         ' (attendu : 6 -- SAT-001..005 + SAT-NEW-001)');
    DBMS_OUTPUT.PUT_LINE('[Ex.15] Lignes HISTORIQUE_STATUT : ' || v_nb_hist ||
                         ' (attendu : 1 -- SAT-004 En veille --> Operationnel trace par T5)');
END;
/

SELECT id_satellite, nom_satellite, statut, id_orbite
FROM   SATELLITE
ORDER  BY id_satellite;
-- Attendu :
-- SAT-001     | NanoOrbit-Alpha   | Operationnel | ORB-001 (inchange)
-- SAT-002     | NanoOrbit-Beta    | Operationnel | ORB-001 (non dans lot)
-- SAT-003     | NanoOrbit-Gamma   | Operationnel | ORB-002 (non dans lot)
-- SAT-004     | NanoOrbit-Delta   | Operationnel | ORB-002 (change : En veille->Operationnel)
-- SAT-005     | NanoOrbit-Epsilon | Desorbite    | ORB-003 (non dans lot)
-- SAT-NEW-001 | IoT-SAT-NEW-001   | En veille    | ORB-001 (insere par MERGE)

SELECT id_satellite, ancien_statut, nouveau_statut, date_changement
FROM   HISTORIQUE_STATUT
ORDER  BY date_changement DESC;
-- Attendu : 1 ligne (SAT-004 : En veille --> Operationnel, trace par trigger T5)

ROLLBACK;
BEGIN DBMS_OUTPUT.PUT_LINE('[Ex.15] ROLLBACK effectue -- jeu de reference restaure.'); END;
/

-- ------------------------------------------------------------
-- Ex. 16 -- MERGE INTO : synchronisation configuration stations/centres
-- Scenario : ajout du centre CTR-003 (Singapour) et mise a jour
-- des dates d'affectation depuis un fichier de configuration revise.
--   - Associations existantes : update date_affectation
--   - Nouvelle association CTR-003/GS-SGP-01 : insert
--
-- Etape 1 : creer CTR-003 dans CENTRE_CONTROLE (INSERT direct car
--           la table AFFECTATION_STATION a une FK sur CENTRE_CONTROLE)
-- Etape 2 : MERGE INTO AFFECTATION_STATION depuis la config revisee
--
-- Note (L1-D) : CTR-003 (Singapour) n'est pas dans le jeu initial.
-- Cette insertion constitue l'ajout documente en Phase 4.
--
-- ROLLBACK final pour preserver le jeu de reference.
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.16 : MERGE INTO -- Sync config stations/centres + CTR-003 ==='); END;
/

-- Etape 1 : insertion CTR-003 (prerequis FK pour AFFECTATION_STATION)
MERGE INTO CENTRE_CONTROLE cc
USING (
    SELECT 'CTR-003'              AS id_centre,
           'NanoOrbit Singapour'  AS nom_centre,
           'Singapour'            AS ville,
           'Asie-Pacifique'       AS region_geo,
           'Asia/Singapore'       AS fuseau_horaire,
           'Actif'                AS statut
    FROM DUAL
) src
ON (cc.id_centre = src.id_centre)
WHEN NOT MATCHED THEN
    INSERT (id_centre, nom_centre, ville, region_geo, fuseau_horaire, statut)
    VALUES (src.id_centre, src.nom_centre, src.ville,
            src.region_geo, src.fuseau_horaire, src.statut);

BEGIN DBMS_OUTPUT.PUT_LINE('[Ex.16] CTR-003 insere dans CENTRE_CONTROLE.'); END;
/

-- Etape 2 : MERGE INTO AFFECTATION_STATION depuis la config revisee
MERGE INTO AFFECTATION_STATION aff
USING (
    -- Configuration revisee :
    --   CTR-001 : GS-TLS-01 + GS-KIR-01 (dates mises a jour 2025-01-01)
    --   CTR-002 : GS-SGP-01 (date mise a jour 2025-03-15)
    --   CTR-003 : GS-SGP-01 (nouvelle association -- double gestion transitoire)
    SELECT 'CTR-001' AS id_centre, 'GS-TLS-01' AS code_station,
           DATE '2025-01-01' AS new_date_affectation FROM DUAL
    UNION ALL
    SELECT 'CTR-001', 'GS-KIR-01',  DATE '2025-01-01' FROM DUAL
    UNION ALL
    SELECT 'CTR-002', 'GS-SGP-01',  DATE '2025-03-15' FROM DUAL
    UNION ALL
    SELECT 'CTR-003', 'GS-SGP-01',  DATE '2025-06-01' FROM DUAL
) src
ON (aff.id_centre    = src.id_centre
AND aff.code_station = src.code_station)
-- Association existante : mettre a jour la date d'affectation
WHEN MATCHED THEN
    UPDATE SET aff.date_affectation = src.new_date_affectation
-- Nouvelle association : inserer
WHEN NOT MATCHED THEN
    INSERT (id_centre, code_station, date_affectation)
    VALUES (src.id_centre, src.code_station, src.new_date_affectation);

-- Verification post-MERGE
DECLARE
    v_nb_centres NUMBER;
    v_nb_aff     NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nb_centres FROM CENTRE_CONTROLE;
    SELECT COUNT(*) INTO v_nb_aff     FROM AFFECTATION_STATION;
    DBMS_OUTPUT.PUT_LINE('[Ex.16] Centres apres MERGE : ' || v_nb_centres ||
                         ' (attendu : 3 -- CTR-001, CTR-002, CTR-003)');
    DBMS_OUTPUT.PUT_LINE('[Ex.16] Affectations apres MERGE : ' || v_nb_aff ||
                         ' (attendu : 4 -- 3 initiales + CTR-003/GS-SGP-01)');
END;
/

SELECT cc.id_centre, cc.nom_centre, aff.code_station, aff.date_affectation
FROM   AFFECTATION_STATION aff
JOIN   CENTRE_CONTROLE     cc ON aff.id_centre = cc.id_centre
ORDER  BY cc.id_centre, aff.code_station;
-- Attendu : 4 lignes
-- CTR-001 | Paris HQ     | GS-KIR-01 | 2025-01-01 (MAJ)
-- CTR-001 | Paris HQ     | GS-TLS-01 | 2025-01-01 (MAJ)
-- CTR-002 | Houston      | GS-SGP-01 | 2025-03-15 (MAJ)
-- CTR-003 | Singapour    | GS-SGP-01 | 2025-06-01 (INSERT)

SELECT id_centre, nom_centre, ville, region_geo, statut
FROM   CENTRE_CONTROLE
ORDER  BY id_centre;
-- Attendu : 3 lignes (CTR-001, CTR-002, CTR-003)

ROLLBACK;
BEGIN DBMS_OUTPUT.PUT_LINE('[Ex.16] ROLLBACK effectue -- jeu de reference restaure.'); END;
/

ALTER SESSION SET CURRENT_SCHEMA = ACADEMY_NANOORBIT_PROJECT;

-- ============================================================
-- PARTIE 2 -- CTE AVEC WITH...AS
-- ============================================================

-- ------------------------------------------------------------
-- Ex. 5 -- CTE simple
-- Top 3 des satellites ayant telecharge le plus grand volume
-- de donnees, avec nombre de fenetres realisees et volume moyen.
--
-- Resultats attendus :
--   Rang 1 | SAT-003 | NanoOrbit-Gamma | 1 fenetre | 1680 Mo | 1680.0 moy
--   Rang 2 | SAT-001 | NanoOrbit-Alpha | 1 fenetre | 1250 Mo | 1250.0 moy
--   Rang 3 | SAT-002 | NanoOrbit-Beta  | 1 fenetre |  890 Mo |  890.0 moy
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.5 : CTE simple -- Top 3 satellites par volume ==='); END;
/

WITH sat_volumes AS (
    SELECT
        s.id_satellite,
        s.nom_satellite,
        s.statut,
        s.format_cubesat,
        COUNT(fc.id_fenetre)                   AS nb_fenetres_realisees,
        NVL(SUM(fc.volume_donnees), 0)         AS volume_total_mo,
        NVL(ROUND(AVG(fc.volume_donnees), 1), 0) AS volume_moyen_mo
    FROM   SATELLITE    s
    LEFT JOIN FENETRE_COM fc ON s.id_satellite = fc.id_satellite
                             AND fc.statut = 'Realisee'
    GROUP  BY s.id_satellite, s.nom_satellite, s.statut, s.format_cubesat
)
SELECT
    RANK() OVER (ORDER BY volume_total_mo DESC) AS rang,
    id_satellite,
    nom_satellite,
    statut,
    format_cubesat,
    nb_fenetres_realisees,
    volume_total_mo,
    volume_moyen_mo
FROM   sat_volumes
ORDER  BY volume_total_mo DESC
FETCH  FIRST 3 ROWS ONLY;

-- ------------------------------------------------------------
-- Ex. 6 -- CTEs multiples
-- Analyse comparative par centre de controle :
--   CTE 1 (fenetres_par_centre) : agregats fenetre/volume par centre
--   CTE 2 (volumes_par_station) : volume total par station
--   CTE 3 (station_top_ranked)  : rang de chaque station par centre
-- Resultat final : centre + bilan + station la plus active.
--
-- Resultats attendus :
--   CTR-001 | NanoOrbit Paris HQ | 3 fenetres Realisees | 3820 Mo
--            | station top : GS-KIR-01 Kiruna (2 fenetres)
-- Note : CTR-002 (Houston) n'apparait pas car GS-SGP-01 en Maintenance
--        -- aucune fenetre realisee depuis Houston.
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.6 : CTEs multiples -- Analyse par centre de controle ==='); END;
/

WITH fenetres_par_centre AS (
    -- CTE 1 : agregats par centre de controle
    SELECT
        cc.id_centre,
        cc.nom_centre,
        cc.ville,
        COUNT(fc.id_fenetre)         AS nb_fenetres_total,
        SUM(
            CASE WHEN fc.statut = 'Realisee' THEN 1 ELSE 0 END
        )                            AS nb_fenetres_realisees,
        SUM(fc.volume_donnees)       AS volume_total_mo
    FROM   FENETRE_COM          fc
    JOIN   STATION_SOL          st  ON fc.code_station = st.code_station
    JOIN   AFFECTATION_STATION  aff ON st.code_station = aff.code_station
    JOIN   CENTRE_CONTROLE      cc  ON aff.id_centre   = cc.id_centre
    GROUP  BY cc.id_centre, cc.nom_centre, cc.ville
),
volumes_par_station AS (
    -- CTE 2 : volume realisee par station, avec centre
    SELECT
        aff.id_centre,
        st.code_station,
        st.nom_station,
        COUNT(fc.id_fenetre)         AS nb_fenetres_station,
        NVL(SUM(fc.volume_donnees), 0) AS volume_station_mo
    FROM   FENETRE_COM          fc
    JOIN   STATION_SOL          st  ON fc.code_station = st.code_station
    JOIN   AFFECTATION_STATION  aff ON st.code_station = aff.code_station
    WHERE  fc.statut = 'Realisee'
    GROUP  BY aff.id_centre, st.code_station, st.nom_station
),
station_top_ranked AS (
    -- CTE 3 : rang des stations par centre (1 = la plus active)
    SELECT
        id_centre,
        code_station,
        nom_station,
        nb_fenetres_station,
        volume_station_mo,
        RANK() OVER (
            PARTITION BY id_centre
            ORDER     BY nb_fenetres_station DESC, volume_station_mo DESC
        ) AS rang_station
    FROM   volumes_par_station
)
SELECT
    f.id_centre,
    f.nom_centre,
    f.ville,
    f.nb_fenetres_total,
    f.nb_fenetres_realisees,
    f.volume_total_mo,
    r.code_station         AS station_top,
    r.nom_station          AS nom_station_top,
    r.nb_fenetres_station  AS fenetres_station_top,
    r.volume_station_mo    AS volume_station_top_mo
FROM   fenetres_par_centre f
JOIN   station_top_ranked  r ON f.id_centre = r.id_centre AND r.rang_station = 1
ORDER  BY f.volume_total_mo DESC NULLS LAST;
-- Attendu :
-- CTR-001 | Paris HQ | 5 total | 3 realisees | 3820 Mo | GS-KIR-01 | Kiruna | 2 | 2930 Mo

-- ------------------------------------------------------------
-- Ex. 7 -- CTE recursive
-- Hierarchie : Centre de controle -> Station au sol -> Fenetres recentes
-- avec indentation visuelle via LPAD.
--
-- Principe :
--   1. CTE all_nodes : union plate des 3 niveaux avec id_noeud + id_parent
--   2. CTE hier (recursive) : traverse le graphe depuis les racines (niveau 1)
--      et descend vers les enfants via la jointure id_parent = id_noeud du parent
--
-- La clause WHERE h.niveau < 3 stoppe la recursion aux fenetres (niveau 3).
--
-- Resultats attendus (extrait) :
--   CTR-001 -- NanoOrbit Paris HQ (Paris)
--       GS-KIR-01 -- Kiruna Arctic Station [Active]
--           F#1 | 15/01/2024 09:14 | Realisee | 1250 Mo
--           F#3 | 16/01/2024 08:30 | Realisee | 1680 Mo
--       GS-TLS-01 -- Toulouse Ground Station [Active]
--           F#2 | 15/01/2024 11:52 | Realisee |  890 Mo
--           F#4 | 20/01/2024 14:22 | Planifiee | N/A
--           F#5 | 21/01/2024 07:45 | Planifiee | N/A
--   CTR-002 -- NanoOrbit Houston (Houston)
--       GS-SGP-01 -- Singapore Station [Maintenance]
--           (aucune fenetre)
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.7 : CTE recursive -- Hierarchie Centre/Station/Fenetre ==='); END;
/

WITH
all_nodes(niveau, id_noeud, id_parent, label) AS (
    -- Niveau 1 : centres de controle (racines -- pas de parent)
    SELECT 1,
           id_centre,
           NULL,
           id_centre || ' -- ' || nom_centre || ' (' || ville || ')'
    FROM   CENTRE_CONTROLE
    WHERE  statut = 'Actif'
    UNION ALL
    -- Niveau 2 : stations rattachees a un centre
    SELECT 2,
           st.code_station,
           aff.id_centre,
           st.code_station || ' -- ' || st.nom_station || ' [' || st.statut || ']'
    FROM   AFFECTATION_STATION aff
    JOIN   STATION_SOL         st ON aff.code_station = st.code_station
    UNION ALL
    -- Niveau 3 : fenetres de communication (enfants des stations)
    SELECT 3,
           TO_CHAR(fc.id_fenetre),
           fc.code_station,
           'F#' || fc.id_fenetre ||
           ' | ' || TO_CHAR(fc.datetime_debut, 'DD/MM/YYYY HH24:MI') ||
           ' | ' || fc.statut ||
           ' | ' || NVL(TO_CHAR(fc.volume_donnees) || ' Mo', 'N/A')
    FROM   FENETRE_COM fc
),
-- Etape 2 : CTE recursive -- parcours depuis les racines
hier(niveau, id_noeud, id_parent, label, chemin_tri) AS (
    -- Membre ancre : racines de niveau 1 (centres)
    SELECT niveau, id_noeud, id_parent, label,
           LPAD(id_noeud, 10)                   AS chemin_tri
    FROM   all_nodes WHERE niveau = 1

    UNION ALL

    -- Membre recursif : enfants directs du noeud courant
    SELECT n.niveau, n.id_noeud, n.id_parent, n.label,
           h.chemin_tri || LPAD(n.id_noeud, 12) AS chemin_tri
    FROM   all_nodes n
    JOIN   hier      h ON n.id_parent = h.id_noeud
    WHERE  h.niveau < 3  -- stoppe la recursion : les fenetres n'ont pas d'enfants
)
SELECT
    niveau,
    LPAD(' ', (niveau - 1) * 6) || label AS hierarchie_nanoorbit
FROM   hier
ORDER  BY chemin_tri;

-- ============================================================
--  PARTIE 3 -- SOUS-REQUETES AVANCEES
-- ============================================================

-- ------------------------------------------------------------
-- Ex. 8 -- Sous-requete scalaire
-- Lister les fenetres realisees dont le volume telecharge
-- est superieur a la moyenne generale des fenetres realisees,
-- en affichant l'ecart a la moyenne.
--
-- Calcul :
--   Moyenne realisees = (1250 + 890 + 1680) / 3 = 1273.3 Mo
--   Fenetres au-dessus : id=3 (1680 Mo, ecart = +406.7 Mo)
--   id=1 (1250 < 1273.3) : en dessous
--   id=2 (890 < 1273.3) : en dessous
--
-- Resultats attendus :
--   Fenetre 3 | SAT-003 | GS-KIR-01 | 1680 Mo | moy=1273.3 | ecart=+406.7
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.8 : Sous-requete scalaire -- Fenetres > moyenne ==='); END;
/

SELECT
    fc.id_fenetre,
    fc.id_satellite,
    fc.code_station,
    fc.volume_donnees,
    ROUND(
        (SELECT AVG(volume_donnees) FROM FENETRE_COM WHERE statut = 'Realisee'),
        1
    )                                                         AS moyenne_generale_mo,
    ROUND(
        fc.volume_donnees -
        (SELECT AVG(volume_donnees) FROM FENETRE_COM WHERE statut = 'Realisee'),
        1
    )                                                         AS ecart_mo
FROM   FENETRE_COM fc
WHERE  fc.statut = 'Realisee'
  AND  fc.volume_donnees > (
           SELECT AVG(volume_donnees)
           FROM   FENETRE_COM
           WHERE  statut = 'Realisee'
       )
ORDER  BY fc.volume_donnees DESC;
-- Attendu : 1 ligne
-- Fenetre 3 | SAT-003 | GS-KIR-01 | 1680 Mo | moy=1273.3 | ecart=+406.7 Mo

-- Complement : afficher aussi les fenetres en dessous pour reference
BEGIN DBMS_OUTPUT.PUT_LINE('--- Tableau complet : volume vs moyenne ---'); END;
/

SELECT
    fc.id_fenetre,
    fc.id_satellite,
    fc.code_station,
    fc.volume_donnees,
    ROUND(avg_ref.moy, 1) AS moyenne_mo,
    ROUND(fc.volume_donnees - avg_ref.moy, 1) AS ecart_mo,
    CASE
        WHEN fc.volume_donnees > avg_ref.moy THEN 'AU-DESSUS'
        WHEN fc.volume_donnees < avg_ref.moy THEN 'EN-DESSOUS'
        ELSE 'EGAL'
    END AS position_vs_moyenne
FROM   FENETRE_COM fc
CROSS JOIN (
    SELECT AVG(volume_donnees) AS moy
    FROM   FENETRE_COM WHERE statut = 'Realisee'
) avg_ref
WHERE  fc.statut = 'Realisee'
ORDER  BY fc.volume_donnees DESC;

-- ------------------------------------------------------------
-- Ex. 9 -- Sous-requete correlee
-- Pour chaque satellite operationnel, recuperer sa derniere
-- fenetre de communication realisee (date, station, volume).
-- La sous-requete correlee reference le satellite de la requete externe.
--
-- Resultats attendus :
--   SAT-001 | NanoOrbit-Alpha | GS-KIR-01 | 15/01/2024 09:14 | 1250 Mo
--   SAT-002 | NanoOrbit-Beta  | GS-TLS-01 | 15/01/2024 11:52 |  890 Mo
--   SAT-003 | NanoOrbit-Gamma | GS-KIR-01 | 16/01/2024 08:30 | 1680 Mo
--   SAT-004 | NanoOrbit-Delta | (aucune fenetre realisee)
--   SAT-005 | NanoOrbit-Epsilon | (aucune fenetre realisee)
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.9 : Sous-requete correlee -- Derniere fenetre par satellite ==='); END;
/

SELECT
    s.id_satellite,
    s.nom_satellite,
    s.statut,
    fc_last.code_station,
    TO_CHAR(fc_last.datetime_debut, 'DD/MM/YYYY HH24:MI') AS derniere_fenetre,
    fc_last.volume_donnees                                  AS volume_mo
FROM   SATELLITE s
LEFT JOIN FENETRE_COM fc_last
       ON fc_last.id_satellite = s.id_satellite
      AND fc_last.statut       = 'Realisee'
      AND fc_last.datetime_debut = (
              -- Sous-requete correlee : MAX datetime pour CE satellite
              SELECT MAX(f2.datetime_debut)
              FROM   FENETRE_COM f2
              WHERE  f2.id_satellite = s.id_satellite  -- correlation
                AND  f2.statut       = 'Realisee'
          )
ORDER  BY s.id_satellite;
-- SAT-004 et SAT-005 : code_station = NULL, derniere_fenetre = NULL (LEFT JOIN)

-- ------------------------------------------------------------
-- Ex. 10 -- EXISTS / NOT EXISTS
-- Deux questions en une requete :
--
-- Question A : Quels satellites n'ont AUCUNE fenetre realisee ?
--   (EXISTS teste la presence dans FENETRE_COM Realisee)
--   Attendu : SAT-004 (En veille), SAT-005 (Desorbite)
--
-- Question B : Quelles stations n'ont traite aucune fenetre ce trimestre
--   (Janvier-Mars 2024) ?
--   Attendu : GS-SGP-01 (en Maintenance -- trigger T1 bloque les insertions)
--
-- Explication (en commentaire, demandee par le CDC) :
--   GS-SGP-01 est dans cette situation car son statut est 'Maintenance'.
--   Le trigger T1 (trg_valider_fenetre) bloque toute tentative d'insertion
--   de fenetre vers cette station. De plus, aucune fenetre historique
--   (anterieure au trigger) ne pointait vers elle dans le jeu de reference.
-- ------------------------------------------------------------
BEGIN DBMS_OUTPUT.PUT_LINE('=== Ex.10 : EXISTS / NOT EXISTS ==='); END;
/

-- Question A : satellites sans aucune fenetre realisee
BEGIN DBMS_OUTPUT.PUT_LINE('--- A : Satellites sans fenetre realisee ---'); END;
/

SELECT
    s.id_satellite,
    s.nom_satellite,
    s.statut,
    s.format_cubesat
FROM   SATELLITE s
WHERE  NOT EXISTS (
           SELECT 1
           FROM   FENETRE_COM fc
           WHERE  fc.id_satellite = s.id_satellite
             AND  fc.statut       = 'Realisee'
       )
ORDER  BY s.id_satellite;
-- Attendu : SAT-004 (En veille), SAT-005 (Desorbite)

-- Question B : stations sans aucune fenetre au 1er trimestre 2024
BEGIN DBMS_OUTPUT.PUT_LINE('--- B : Stations sans fenetre au T1 2024 ---'); END;
/

SELECT
    st.code_station,
    st.nom_station,
    st.statut,
    cc.nom_centre
FROM   STATION_SOL          st
JOIN   AFFECTATION_STATION  aff ON st.code_station = aff.code_station
JOIN   CENTRE_CONTROLE      cc  ON aff.id_centre   = cc.id_centre
WHERE  NOT EXISTS (
           SELECT 1
           FROM   FENETRE_COM fc
           WHERE  fc.code_station    = st.code_station
             AND  fc.datetime_debut >= TIMESTAMP '2024-01-01 00:00:00'
             AND  fc.datetime_debut  < TIMESTAMP '2024-04-01 00:00:00'
       )
ORDER  BY st.code_station;
-- Attendu : GS-SGP-01 (Maintenance, rattachee a CTR-002 Houston)
-- Explication : GS-SGP-01 est en Maintenance depuis le jeu de reference initial.
-- Le trigger T1 (RG-G03) bloque toute nouvelle fenetre vers une station en Maintenance.
-- Aucune fenetre n'a ete planifiee ni realisee depuis cette station.


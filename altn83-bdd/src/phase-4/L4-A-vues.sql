ALTER SESSION SET CURRENT_SCHEMA = ACADEMY_NANOORBIT_PROJECT;

-- ============================================================
-- V1 -- v_satellites_operationnels
-- Vue simple filtree : satellites operationnels avec orbite,
-- nombre d'instruments embarques et capacite batterie.
-- Seuls les satellites en statut 'Operationnel' sont inclus (RG-S06).
-- ============================================================

CREATE OR REPLACE VIEW v_satellites_operationnels AS
SELECT
    s.id_satellite,
    s.nom_satellite,
    s.statut,
    s.format_cubesat,
    s.masse,
    s.capacite_batterie,
    s.duree_vie_prevue,
    s.date_lancement,
    ADD_MONTHS(s.date_lancement, s.duree_vie_prevue) AS date_fin_vie_nominale,
    o.id_orbite,
    o.type_orbite,
    o.altitude          AS altitude_km,
    o.inclinaison,
    o.periode_orbitale,
    COUNT(e.ref_instrument) AS nb_instruments
FROM   SATELLITE    s
JOIN   ORBITE       o ON s.id_orbite    = o.id_orbite
LEFT JOIN EMBARQUEMENT e ON s.id_satellite = e.id_satellite
WHERE  s.statut = 'Operationnel'
GROUP BY
    s.id_satellite, s.nom_satellite, s.statut, s.format_cubesat,
    s.masse, s.capacite_batterie, s.duree_vie_prevue, s.date_lancement,
    o.id_orbite, o.type_orbite, o.altitude, o.inclinaison, o.periode_orbitale;

COMMENT ON TABLE v_satellites_operationnels IS
    'Vue des satellites operationnels avec orbite et nb instruments embarques';

-- Test V1
BEGIN DBMS_OUTPUT.PUT_LINE('=== Test V1 : v_satellites_operationnels ==='); END;
/

SELECT id_satellite, nom_satellite, type_orbite, altitude_km,
       nb_instruments, capacite_batterie, statut
FROM   v_satellites_operationnels
ORDER  BY id_satellite;
-- Attendu : 3 lignes (SAT-001, SAT-002, SAT-003)
-- SAT-001 | NanoOrbit-Alpha | SSO | 550 km | 2 instruments | 20 Wh | Operationnel
-- SAT-002 | NanoOrbit-Beta  | SSO | 550 km | 1 instrument  | 20 Wh | Operationnel
-- SAT-003 | NanoOrbit-Gamma | SSO | 700 km | 2 instruments | 40 Wh | Operationnel
-- SAT-004 (En veille) et SAT-005 (Desorbite) sont exclus.

-- ============================================================
-- V2 -- v_fenetres_detail
-- Vue jointure denormalisee : creneaux de communication avec
-- noms complets satellite, station, centre de controle et
-- duree formatee (MM min SS s).
-- Remplace les jointures repetitives dans les requetes de reporting.
-- ============================================================
CREATE OR REPLACE VIEW v_fenetres_detail AS
SELECT
    -- Fenetre
    fc.id_fenetre,
    fc.datetime_debut,
    TO_CHAR(fc.datetime_debut, 'DD/MM/YYYY HH24:MI:SS')  AS debut_formate,
    fc.duree                                               AS duree_secondes,
    TO_CHAR(FLOOR(fc.duree / 60), 'FM00') || 'min ' ||
        TO_CHAR(MOD(fc.duree, 60), 'FM00') || 's'         AS duree_formatee,
    fc.elevation_max,
    fc.volume_donnees,
    fc.statut                                              AS statut_fenetre,
    -- Satellite
    s.id_satellite,
    s.nom_satellite,
    s.statut                                               AS statut_satellite,
    s.format_cubesat,
    -- Station au sol
    st.code_station,
    st.nom_station,
    st.bande_frequence,
    st.debit_max,
    st.statut                                              AS statut_station,
    -- Centre de controle
    cc.id_centre,
    cc.nom_centre,
    cc.ville                                               AS ville_centre,
    cc.region_geo
FROM   FENETRE_COM           fc
JOIN   SATELLITE             s   ON fc.id_satellite = s.id_satellite
JOIN   STATION_SOL           st  ON fc.code_station  = st.code_station
JOIN   AFFECTATION_STATION   aff ON st.code_station  = aff.code_station
JOIN   CENTRE_CONTROLE       cc  ON aff.id_centre    = cc.id_centre;

COMMENT ON TABLE v_fenetres_detail IS
    'Vue denormalisee des creneaux de communication : satellite, station, centre, duree formatee';

-- Test V2
BEGIN DBMS_OUTPUT.PUT_LINE('=== Test V2 : v_fenetres_detail ==='); END;
/

SELECT id_fenetre, nom_satellite, nom_station, nom_centre,
       duree_formatee, NVL(TO_CHAR(volume_donnees), 'NULL') AS volume_mo,
       statut_fenetre
FROM   v_fenetres_detail
ORDER  BY id_fenetre;
-- Attendu : 5 lignes
-- 1 | NanoOrbit-Alpha | Kiruna Arctic Station   | NanoOrbit Paris HQ | 07min 00s | 1250  | Realisee
-- 2 | NanoOrbit-Beta  | Toulouse Ground Station | NanoOrbit Paris HQ | 05min 10s | 890   | Realisee
-- 3 | NanoOrbit-Gamma | Kiruna Arctic Station   | NanoOrbit Paris HQ | 09min 00s | 1680  | Realisee
-- 4 | NanoOrbit-Alpha | Toulouse Ground Station | NanoOrbit Paris HQ | 06min 20s | NULL  | Planifiee
-- 5 | NanoOrbit-Gamma | Toulouse Ground Station | NanoOrbit Paris HQ | 04min 50s | NULL  | Planifiee
-- Note : toutes les fenetres passent par CTR-001 (Paris)
--        car GS-SGP-01 (CTR-002) est en Maintenance (trigger T1 actif).

-- ============================================================
-- V3 -- v_stats_missions
-- Vue avec agregats : statistiques operationnelles par mission.
-- Par mission : nombre de satellites, types d'orbites representes,
-- volume total telecharge depuis les satellites participants.
-- Note : un satellite participant a plusieurs missions (ex : SAT-001
--        dans ARC-2023 et DEF-2022) voit son volume compte dans chacune.
-- ============================================================
CREATE OR REPLACE VIEW v_stats_missions AS
SELECT
    m.id_mission,
    m.nom_mission,
    m.statut_mission,
    m.date_debut,
    m.date_fin,
    COUNT(DISTINCT p.id_satellite)   AS nb_satellites,
    COUNT(DISTINCT o.type_orbite)    AS nb_types_orbite,
    LISTAGG(DISTINCT o.type_orbite, ', ')
        WITHIN GROUP (ORDER BY o.type_orbite) AS types_orbites,
    NVL(SUM(fc.volume_donnees), 0)   AS volume_total_mo
FROM   MISSION          m
LEFT JOIN PARTICIPATION p  ON m.id_mission   = p.id_mission
LEFT JOIN SATELLITE     s  ON p.id_satellite = s.id_satellite
LEFT JOIN ORBITE        o  ON s.id_orbite    = o.id_orbite
LEFT JOIN FENETRE_COM   fc ON p.id_satellite = fc.id_satellite
                           AND fc.statut = 'Realisee'
GROUP BY m.id_mission, m.nom_mission, m.statut_mission, m.date_debut, m.date_fin;

COMMENT ON TABLE v_stats_missions IS
    'Vue agregee des missions : nb satellites, types orbites, volume total telecharge';

-- Test V3
BEGIN DBMS_OUTPUT.PUT_LINE('=== Test V3 : v_stats_missions ==='); END;
/

SELECT id_mission, nom_mission, statut_mission,
       nb_satellites, types_orbites, volume_total_mo
FROM   v_stats_missions
ORDER  BY id_mission;
-- Attendu : 3 lignes
-- MSN-ARC-2023  | ArcticWatch 2023  | Active   | 3 sats | SSO      | 3820 Mo
--   (SAT-001:1250 + SAT-002:890 + SAT-003:1680 = 3820 Mo)
-- MSN-COAST-2024| CoastGuard 2024   | Active   | 2 sats | SSO      | 1680 Mo
--   (SAT-003:1680 + SAT-004:0 = 1680 Mo)
-- MSN-DEF-2022  | DeforestAlert     | Terminee | 2 sats | LEO, SSO | 1250 Mo
--   (SAT-001:1250 + SAT-005:0 = 1250 Mo)

-- ============================================================
-- V4 -- mv_volumes_mensuels
-- Vue materialisee (REFRESH ON DEMAND)
-- Volumes telecharges par mois, par centre de controle
-- et par type de CubeSat (format_cubesat).
-- Prerequis calcul : FENETRE_COM.statut = 'Realisee' uniquement.
-- Rafraichissement manuel : DBMS_MVIEW.REFRESH('MV_VOLUMES_MENSUELS', 'C')
-- ============================================================


BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_volumes_mensuels';
    DBMS_OUTPUT.PUT_LINE('[OK] MV mv_volumes_mensuels supprimee (sera recreee).');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -12003 THEN
            DBMS_OUTPUT.PUT_LINE('[Info] MV mv_volumes_mensuels inexistante, creation directe.');
        ELSE
            RAISE;
        END IF;
END;
/

CREATE MATERIALIZED VIEW mv_volumes_mensuels
REFRESH ON DEMAND
AS
SELECT
    TRUNC(fc.datetime_debut, 'MM')         AS mois,
    TO_CHAR(fc.datetime_debut, 'YYYY-MM')  AS mois_label,
    cc.id_centre,
    cc.nom_centre,
    cc.ville                               AS ville_centre,
    cc.region_geo,
    s.format_cubesat,
    COUNT(fc.id_fenetre)                   AS nb_fenetres,
    SUM(fc.volume_donnees)                 AS volume_total_mo,
    ROUND(AVG(fc.volume_donnees), 1)       AS volume_moyen_mo,
    COUNT(DISTINCT fc.id_satellite)        AS nb_satellites_actifs
FROM   FENETRE_COM          fc
JOIN   SATELLITE             s   ON fc.id_satellite = s.id_satellite
JOIN   STATION_SOL           st  ON fc.code_station  = st.code_station
JOIN   AFFECTATION_STATION   aff ON st.code_station  = aff.code_station
JOIN   CENTRE_CONTROLE       cc  ON aff.id_centre    = cc.id_centre
WHERE  fc.statut = 'Realisee'
GROUP  BY
    TRUNC(fc.datetime_debut, 'MM'),
    TO_CHAR(fc.datetime_debut, 'YYYY-MM'),
    cc.id_centre, cc.nom_centre, cc.ville, cc.region_geo,
    s.format_cubesat;

COMMENT ON MATERIALIZED VIEW mv_volumes_mensuels IS
    'Vue materialisee des volumes mensuels telecharges par centre et format CubeSat (REFRESH ON DEMAND)';

-- Test V4
BEGIN DBMS_OUTPUT.PUT_LINE('=== Test V4 : mv_volumes_mensuels ==='); END;
/

SELECT mois_label, nom_centre, format_cubesat,
       nb_fenetres, volume_total_mo, volume_moyen_mo, nb_satellites_actifs
FROM   mv_volumes_mensuels
ORDER  BY mois, id_centre, format_cubesat;
-- Attendu : 2 lignes (janvier 2024, CTR-001)
-- 2024-01 | NanoOrbit Paris HQ | 3U | 2 fenetres | 2140 Mo | 1070.0 moy | 2 sats
--   (fenetre 1 SAT-001/3U:1250 + fenetre 2 SAT-002/3U:890 = 2140 Mo)
-- 2024-01 | NanoOrbit Paris HQ | 6U | 1 fenetre  | 1680 Mo | 1680.0 moy | 1 sat
--   (fenetre 3 SAT-003/6U:1680 Mo)
-- Note : CTR-002 (Houston) n'apparait pas -- GS-SGP-01 toujours en Maintenance.

-- ============================================================
-- Rafraichissement manuel de la vue materialisee
-- A executer apres toute insertion dans FENETRE_COM
-- pour mettre a jour les donnees aggregees.
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== Rafraichissement mv_volumes_mensuels ==='); END;
/

BEGIN
    DBMS_MVIEW.REFRESH('MV_VOLUMES_MENSUELS', method => 'C');
    DBMS_OUTPUT.PUT_LINE('[OK] Vue materialisee rafraichie (methode Complete).');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Erreur rafraichissement] ' || SQLERRM);
END;
/

-- Verification post-rafraichissement
SELECT COUNT(*) AS nb_lignes_mview FROM mv_volumes_mensuels;
-- Attendu : 2 lignes

-- ============================================================
-- VERIFICATION GLOBALE DES VUES
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== Verification des vues creees ==='); END;
/

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
-- Attendu : 4 lignes avec STATUS = VALID

ALTER SESSION SET CURRENT_SCHEMA = ACADEMY_NANOORBIT_PROJECT;

-- ============================================================
-- 1. ORBITE
-- ============================================================
INSERT INTO ORBITE (id_orbite, type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture)
VALUES ('ORB-001', 'SSO', 550, 97.6, 95.5, 0.0010, 'Polaire globale - Europe / Arctique');

INSERT INTO ORBITE (id_orbite, type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture)
VALUES ('ORB-002', 'SSO', 700, 98.2, 98.8, 0.0008, 'Polaire globale - haute latitude');

INSERT INTO ORBITE (id_orbite, type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture)
VALUES ('ORB-003', 'LEO', 400, 51.6, 92.6, 0.0020, 'Equatoriale - zone tropicale');

BEGIN DBMS_OUTPUT.PUT_LINE('ORBITE : 3 lignes inserees'); END;
/

-- ============================================================
-- 2. SATELLITE 
-- le trigger T1 (trg_valider_fenetre) et la regle RG-S06.
-- ============================================================
INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-001', 'NanoOrbit-Alpha', DATE '2022-03-15', 1.30, '3U', 'Operationnel', 60, 20, 'ORB-001');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-002', 'NanoOrbit-Beta', DATE '2022-03-15', 1.30, '3U', 'Operationnel', 60, 20, 'ORB-001');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-003', 'NanoOrbit-Gamma', DATE '2023-06-10', 2.00, '6U', 'Operationnel', 84, 40, 'ORB-002');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-004', 'NanoOrbit-Delta', DATE '2023-06-10', 2.00, '6U', 'En veille', 84, 40, 'ORB-002');

-- SAT-005 : Desorbite -- teste RG-S06 et T1/T4 apres activation des triggers
INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite)
VALUES ('SAT-005', 'NanoOrbit-Epsilon', DATE '2021-11-20', 4.50, '12U', 'Desorbite', 36, 80, 'ORB-003');

BEGIN DBMS_OUTPUT.PUT_LINE('SATELLITE : 5 lignes inserees'); END;
/

-- ============================================================
-- 3. HISTORIQUE_STATUT 
-- Table alimentee exclusivement par le trigger T5.
-- Aucun INSERT manuel prevu -- cf. CDC Phase 2 section 2.4 note T5.
-- ============================================================

-- ============================================================
-- 4. INSTRUMENT
-- ============================================================
INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-CAM-01', 'Camera optique', 'PlanetScope-Mini', 3, 2.5, 0.400);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-IR-01', 'Infrarouge', 'FLIR-Lepton-3', 160, 1.2, 0.150);

-- resolution NULL : AIS ne produit pas d'image -- RG-I01, Ex.4 Palier 2
INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-AIS-01', 'Recepteur AIS', 'ShipTrack-V2', NULL, 0.8, 0.120);

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse)
VALUES ('INS-SPEC-01', 'Spectrometre', 'HyperSpec-Nano', 30, 3.1, 0.600);

BEGIN DBMS_OUTPUT.PUT_LINE('INSTRUMENT : 4 lignes inserees'); END;
/

-- ============================================================
-- 5. EMBARQUEMENT
-- PK composite (id_satellite, ref_instrument)
-- ============================================================
INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-001', 'INS-CAM-01', DATE '2022-03-15', 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-001', 'INS-IR-01', DATE '2022-03-15', 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-002', 'INS-CAM-01', DATE '2022-03-15', 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-003', 'INS-CAM-01', DATE '2023-06-10', 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-003', 'INS-SPEC-01', DATE '2023-06-10', 'Nominal');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-004', 'INS-IR-01', DATE '2023-06-10', 'Degrade');

INSERT INTO EMBARQUEMENT (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
VALUES ('SAT-005', 'INS-AIS-01', DATE '2021-11-20', 'Hors service');

BEGIN DBMS_OUTPUT.PUT_LINE('EMBARQUEMENT : 7 lignes inserees'); END;
/

-- ============================================================
-- 6. CENTRE_CONTROLE 
-- CTR-003 (Singapour) absent du jeu initial ajoute Phase 4 
-- ============================================================
INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region_geo, fuseau_horaire, statut)
VALUES ('CTR-001', 'NanoOrbit Paris HQ', 'Paris', 'Europe', 'Europe/Paris', 'Actif');

INSERT INTO CENTRE_CONTROLE (id_centre, nom_centre, ville, region_geo, fuseau_horaire, statut)
VALUES ('CTR-002', 'NanoOrbit Houston', 'Houston', 'Ameriques', 'America/Chicago', 'Actif');

BEGIN DBMS_OUTPUT.PUT_LINE('CENTRE_CONTROLE : 2 lignes inserees'); END;
/

-- ============================================================
-- 7. STATION_SOL
-- GS-SGP-01 en Maintenance : teste RG-G03 et trigger T1
-- ============================================================
INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut)
VALUES ('GS-TLS-01', 'Toulouse Ground Station', 43.604700, 1.444200, 3.5, 'S', 150, 'Active');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut)
VALUES ('GS-KIR-01', 'Kiruna Arctic Station', 67.855700, 20.225300, 5.4, 'X', 400, 'Active');

-- GS-SGP-01 en Maintenance : trigger T1 doit bloquer toute fenetre vers cette station
INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut)
VALUES ('GS-SGP-01', 'Singapore Station', 1.352100, 103.819800, 3.0, 'S', 120, 'Maintenance');

BEGIN DBMS_OUTPUT.PUT_LINE('STATION_SOL : 3 lignes inserees'); END;
/

-- ============================================================
-- 8. AFFECTATION_STATION 
-- PK composite (id_centre, code_station)
-- ============================================================
INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation)
VALUES ('CTR-001', 'GS-TLS-01', DATE '2022-01-10');

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation)
VALUES ('CTR-001', 'GS-KIR-01', DATE '2022-01-10');

INSERT INTO AFFECTATION_STATION (id_centre, code_station, date_affectation)
VALUES ('CTR-002', 'GS-SGP-01', DATE '2023-03-15');

BEGIN DBMS_OUTPUT.PUT_LINE('AFFECTATION_STATION : 3 lignes inserees'); END;
/

-- ============================================================
-- 9. MISSION
-- MSN-DEF-2022 en statut Terminee : inserer AVANT les triggers (T4 bloquerait
-- ============================================================
INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission)
VALUES (
    'MSN-ARC-2023',
    'ArcticWatch 2023',
    'Surveillance fonte des glaces et dynamique des banquises',
    'Arctique / Groenland',
    DATE '2023-01-01',
    NULL,
    'Active'
);

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission)
VALUES (
    'MSN-DEF-2022',
    'DeforestAlert',
    'Detection et cartographie de la deforestation en temps quasi-reel',
    'Amazonie / Congo',
    DATE '2022-06-01',
    DATE '2023-05-31',
    'Terminee'
);

INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission)
VALUES (
    'MSN-COAST-2024',
    'CoastGuard 2024',
    'Surveillance evolution du trait de cote et detection derosion',
    'Mediterranee / Atlantique',
    DATE '2024-03-01',
    NULL,
    'Active'
);

BEGIN DBMS_OUTPUT.PUT_LINE('MISSION : 3 lignes inserees'); END;
/

-- ============================================================
-- 10. FENETRE_COM 
-- ============================================================
INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES (TIMESTAMP '2024-01-15 09:14:00.000000', 420, 82.3, 1250, 'Realisee', 'SAT-001', 'GS-KIR-01');

INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES (TIMESTAMP '2024-01-15 11:52:00.000000', 310, 67.1, 890, 'Realisee', 'SAT-002', 'GS-TLS-01');

INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES (TIMESTAMP '2024-01-16 08:30:00.000000', 540, 88.9, 1680, 'Realisee', 'SAT-003', 'GS-KIR-01');

INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES (TIMESTAMP '2024-01-20 14:22:00.000000', 380, 71.4, NULL, 'Planifiee', 'SAT-001', 'GS-TLS-01');

INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
VALUES (TIMESTAMP '2024-01-21 07:45:00.000000', 290, 59.8, NULL, 'Planifiee', 'SAT-003', 'GS-TLS-01');

BEGIN DBMS_OUTPUT.PUT_LINE('FENETRE_COM : 5 lignes inserees'); END;
/

-- ============================================================
-- 11. PARTICIPATION 
-- PK composite (id_satellite, id_mission)
--
-- NOTE : SAT-005 participe a MSN-DEF-2022 (Terminee). Cette insertion
-- est valide car MSN-DEF-2022 etait Active lors de la mission.
-- Apres activation du trigger T4, il sera impossible d'ajouter
-- de nouveaux satellites a MSN-DEF-2022 -- ce cas sert de test T4.
-- ============================================================

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-001', 'MSN-ARC-2023', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-002', 'MSN-ARC-2023', 'Imageur secondaire');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-003', 'MSN-ARC-2023', 'Satellite de relais');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-001', 'MSN-DEF-2022', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-005', 'MSN-DEF-2022', 'Imageur secondaire');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-003', 'MSN-COAST-2024', 'Imageur principal');

INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
VALUES ('SAT-004', 'MSN-COAST-2024', 'Satellite de secours');

BEGIN DBMS_OUTPUT.PUT_LINE('PARTICIPATION : 7 lignes inserees'); END;
/


COMMIT;


BEGIN DBMS_OUTPUT.PUT_LINE('=== VERIFICATION DU JEU DE DONNEES ==='); END;
/

SELECT 'ORBITE'              AS table_name, COUNT(*) AS nb_lignes FROM ORBITE           UNION ALL
SELECT 'SATELLITE',          COUNT(*) FROM SATELLITE          UNION ALL
SELECT 'HISTORIQUE_STATUT',  COUNT(*) FROM HISTORIQUE_STATUT  UNION ALL
SELECT 'INSTRUMENT',         COUNT(*) FROM INSTRUMENT         UNION ALL
SELECT 'EMBARQUEMENT',       COUNT(*) FROM EMBARQUEMENT       UNION ALL
SELECT 'CENTRE_CONTROLE',    COUNT(*) FROM CENTRE_CONTROLE    UNION ALL
SELECT 'STATION_SOL',        COUNT(*) FROM STATION_SOL        UNION ALL
SELECT 'AFFECTATION_STATION',COUNT(*) FROM AFFECTATION_STATION UNION ALL
SELECT 'MISSION',            COUNT(*) FROM MISSION            UNION ALL
SELECT 'FENETRE_COM',        COUNT(*) FROM FENETRE_COM        UNION ALL
SELECT 'PARTICIPATION',      COUNT(*) FROM PARTICIPATION
ORDER BY table_name;

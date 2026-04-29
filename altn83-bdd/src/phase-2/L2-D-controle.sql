-- ============================================================
-- 1. VERIFICATION DES TABLES (user_tables)
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== 1. TABLES ==='); END;
/

SELECT table_name,
       num_rows,
       CASE WHEN table_name IN (
           'ORBITE','SATELLITE','HISTORIQUE_STATUT','INSTRUMENT',
           'EMBARQUEMENT','CENTRE_CONTROLE','STATION_SOL',
           'AFFECTATION_STATION','MISSION','FENETRE_COM','PARTICIPATION'
       ) THEN 'OK' ELSE 'INATTENDUE' END AS statut
FROM   user_tables
WHERE  table_name IN (
    'ORBITE','SATELLITE','HISTORIQUE_STATUT','INSTRUMENT',
    'EMBARQUEMENT','CENTRE_CONTROLE','STATION_SOL',
    'AFFECTATION_STATION','MISSION','FENETRE_COM','PARTICIPATION'
)
ORDER  BY table_name;
-- Attendu : 11 lignes

-- ============================================================
-- 2. VERIFICATION DES CONTRAINTES (user_constraints)
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== 2. CONTRAINTES PAR TABLE ==='); END;
/

SELECT table_name,
       constraint_name,
       constraint_type,  -- P=PK, U=UNIQUE, C=CHECK, R=FK
       status
FROM   user_constraints
WHERE  table_name IN (
    'ORBITE','SATELLITE','HISTORIQUE_STATUT','INSTRUMENT',
    'EMBARQUEMENT','CENTRE_CONTROLE','STATION_SOL',
    'AFFECTATION_STATION','MISSION','FENETRE_COM','PARTICIPATION'
)
ORDER  BY table_name, constraint_type, constraint_name;

BEGIN DBMS_OUTPUT.PUT_LINE('=== Resume des contraintes ==='); END;
/

SELECT constraint_type,
       COUNT(*) AS nb_contraintes
FROM   user_constraints
WHERE  table_name IN (
    'ORBITE','SATELLITE','HISTORIQUE_STATUT','INSTRUMENT',
    'EMBARQUEMENT','CENTRE_CONTROLE','STATION_SOL',
    'AFFECTATION_STATION','MISSION','FENETRE_COM','PARTICIPATION'
)
GROUP  BY constraint_type
ORDER  BY constraint_type;

-- ============================================================
-- 3. VERIFICATION DES CLES ETRANGERES
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== 3. CLES ETRANGERES ==='); END;
/

SELECT uc.table_name           AS table_fille,
       uc.constraint_name      AS fk_name,
       ucc.column_name         AS colonne_fk,
       uc2.table_name          AS table_parent,
       ucc2.column_name        AS colonne_pk
FROM   user_constraints  uc
JOIN   user_cons_columns ucc  ON uc.constraint_name  = ucc.constraint_name
JOIN   user_constraints  uc2  ON uc.r_constraint_name = uc2.constraint_name
JOIN   user_cons_columns ucc2 ON uc2.constraint_name  = ucc2.constraint_name
WHERE  uc.constraint_type = 'R'
  AND  uc.table_name IN (
    'SATELLITE','HISTORIQUE_STATUT','EMBARQUEMENT',
    'AFFECTATION_STATION','FENETRE_COM','PARTICIPATION'
  )
ORDER  BY uc.table_name, uc.constraint_name;

-- ============================================================
-- 4. VERIFICATION DES TRIGGERS (user_triggers)
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== 4. TRIGGERS ==='); END;
/

SELECT trigger_name,
       table_name,
       trigger_type,
       triggering_event,
       status
FROM   user_triggers
WHERE  trigger_name IN (
    'TRG_VALIDER_FENETRE',
    'TRG_NO_CHEVAUCHEMENT',
    'TRG_VOLUME_REALISE',
    'TRG_MISSION_TERMINEE',
    'TRG_HISTORIQUE_STATUT'
)
ORDER  BY trigger_name;
-- Attendu : 5 lignes avec STATUS = ENABLED

-- ============================================================
-- 5. VERIFICATION DES FONCTIONS AUXILIAIRES
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== 5. FONCTIONS AUXILIAIRES ==='); END;
/

SELECT object_name, object_type, status
FROM   user_objects
WHERE  object_type = 'FUNCTION'
  AND  object_name IN ('FN_OVERLAP_SATELLITE', 'FN_OVERLAP_STATION')
ORDER  BY object_name;
-- Attendu : 2 lignes STATUS = VALID

-- ============================================================
-- 6. CONTROLE DES DONNEES -- Comptages par table
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== 6. DONNEES -- COMPTAGES ==='); END;
/

SELECT 'ORBITE'               AS table_name, COUNT(*) AS nb, '3'  AS attendu FROM ORBITE              UNION ALL
SELECT 'SATELLITE',           COUNT(*),           '5'  FROM SATELLITE             UNION ALL
SELECT 'HISTORIQUE_STATUT',   COUNT(*),           '0'  FROM HISTORIQUE_STATUT     UNION ALL
SELECT 'INSTRUMENT',          COUNT(*),           '4'  FROM INSTRUMENT            UNION ALL
SELECT 'EMBARQUEMENT',        COUNT(*),           '7'  FROM EMBARQUEMENT          UNION ALL
SELECT 'CENTRE_CONTROLE',     COUNT(*),           '2'  FROM CENTRE_CONTROLE       UNION ALL
SELECT 'STATION_SOL',         COUNT(*),           '3'  FROM STATION_SOL           UNION ALL
SELECT 'AFFECTATION_STATION', COUNT(*),           '3'  FROM AFFECTATION_STATION   UNION ALL
SELECT 'MISSION',             COUNT(*),           '3'  FROM MISSION               UNION ALL
SELECT 'FENETRE_COM',         COUNT(*),           '5'  FROM FENETRE_COM           UNION ALL
SELECT 'PARTICIPATION',       COUNT(*),           '7'  FROM PARTICIPATION
ORDER  BY table_name;

-- ============================================================
-- 7. CONTROLE METIER -- Validite des donnees de reference
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== 7. CONTROLES METIER ==='); END;
/

-- 7a. Satellites par statut
SELECT statut, COUNT(*) AS nb_satellites
FROM   SATELLITE
GROUP  BY statut
ORDER  BY statut;
-- Attendu : Desorbite=1, En veille=1, Operationnel=3

-- 7b. Fenetres par statut
SELECT statut, COUNT(*) AS nb_fenetres,
       SUM(volume_donnees) AS volume_total_mo
FROM   FENETRE_COM
GROUP  BY statut
ORDER  BY statut;
-- Attendu : Planifiee=2 (volume NULL), Realisee=3 (volume renseigne)

-- 7c. Verification RG-F05 : aucune fenetre Planifiee avec volume renseigne
SELECT COUNT(*) AS violations_rg_f05
FROM   FENETRE_COM
WHERE  statut = 'Planifiee'
  AND  volume_donnees IS NOT NULL;
-- Attendu : 0

-- 7d. Verification RG-F04 : durees dans [1, 900]
SELECT COUNT(*) AS violations_rg_f04
FROM   FENETRE_COM
WHERE  duree NOT BETWEEN 1 AND 900;
-- Attendu : 0

-- 7e. Verification UNIQUE orbite (altitude, inclinaison)
SELECT altitude, inclinaison, COUNT(*) AS nb
FROM   ORBITE
GROUP  BY altitude, inclinaison
HAVING COUNT(*) > 1;
-- Attendu : 0 ligne (aucun doublon)

-- 7f. Participations par mission
SELECT m.id_mission, m.nom_mission, m.statut_mission, COUNT(p.id_satellite) AS nb_satellites
FROM   MISSION m
LEFT JOIN PARTICIPATION p ON m.id_mission = p.id_mission
GROUP  BY m.id_mission, m.nom_mission, m.statut_mission
ORDER  BY m.id_mission;
-- Attendu : MSN-ARC-2023=3, MSN-DEF-2022=2, MSN-COAST-2024=2

-- 7g. Instruments par satellite (via EMBARQUEMENT) -- verifier RG-S03 : 1 a 4 par satellite
SELECT s.id_satellite, s.nom_satellite, COUNT(e.ref_instrument) AS nb_instruments
FROM   SATELLITE s
LEFT JOIN EMBARQUEMENT e ON s.id_satellite = e.id_satellite
GROUP  BY s.id_satellite, s.nom_satellite
ORDER  BY s.id_satellite;
-- Attendu : SAT-001=2, SAT-002=1, SAT-003=2, SAT-004=1, SAT-005=1

-- ============================================================
-- 8. CONTROLE COLONNES INDEXABLES (candidats identifies en Phase 1 / L1-C)
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== 8. INDEX EXISTANTS (PK et UNIQUE auto-crees) ==='); END;
/

SELECT index_name, table_name, uniqueness, index_type, status
FROM   user_indexes
WHERE  table_name IN (
    'ORBITE','SATELLITE','HISTORIQUE_STATUT','INSTRUMENT',
    'EMBARQUEMENT','CENTRE_CONTROLE','STATION_SOL',
    'AFFECTATION_STATION','MISSION','FENETRE_COM','PARTICIPATION'
)
ORDER  BY table_name, index_name;

-- ============================================================
-- 9. COMMENTAIRES DES TABLES (user_tab_comments)
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== 9. COMMENTAIRES TABLES ==='); END;
/

SELECT table_name, comments
FROM   user_tab_comments
WHERE  table_name IN (
    'ORBITE','SATELLITE','HISTORIQUE_STATUT','INSTRUMENT',
    'EMBARQUEMENT','CENTRE_CONTROLE','STATION_SOL',
    'AFFECTATION_STATION','MISSION','FENETRE_COM','PARTICIPATION'
)
ORDER  BY table_name;


BEGIN
    DBMS_OUTPUT.PUT_LINE('=== CONTROLE TERMINE -- Schema NanoOrbit Phase 2 ===');
END;
/

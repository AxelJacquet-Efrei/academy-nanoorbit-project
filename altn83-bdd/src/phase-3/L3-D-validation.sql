ALTER SESSION SET CURRENT_SCHEMA = ACADEMY_NANOORBIT_PROJECT;

-- ============================================================
-- SCENARIO DE VALIDATION COMPLET
-- ============================================================
DECLARE
    v_id_fenetre     NUMBER;                       
    v_stats          pkg_nanoOrbit.t_stats_satellite; 
    v_volume_theo    NUMBER;                        
    v_constellation  VARCHAR2(300);                

    c_satellite      CONSTANT VARCHAR2(20)  := 'SAT-001';
    c_station        CONSTANT VARCHAR2(20)  := 'GS-KIR-01';
    c_datetime       CONSTANT TIMESTAMP     := TIMESTAMP '2024-03-01 10:00:00';
    c_duree          CONSTANT NUMBER        := 450;   
    c_volume_cloture CONSTANT NUMBER        := 1500;  
    c_satellite_msn  CONSTANT VARCHAR2(20)  := 'SAT-004';
    c_mission        CONSTANT VARCHAR2(20)  := 'MSN-ARC-2023';
    c_role           CONSTANT VARCHAR2(100) := 'Satellite de relais';
    c_sat_revision   CONSTANT VARCHAR2(20)  := 'SAT-004';

BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 65, '='));
    DBMS_OUTPUT.PUT_LINE('  SCENARIO DE VALIDATION -- pkg_nanoOrbit');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 65, '='));

    -- ===========================================================
    -- ETAPE 1 : planifier_fenetre
    -- Planifie un nouveau creneau SAT-001 -> GS-KIR-01
    -- La date 2024-03-01 10:00:00 ne chevauche aucune fenetre existante.
    -- T1 verifie : SAT-001 Operationnel, GS-KIR-01 Active -> OK
    -- T2 verifie : aucun chevauchement -> OK
    -- T3 force   : volume_donnees = NULL (statut Planifiee) -> OK
    --
    -- Attendu : "[pkg] Fenetre planifiee : id=6 ..."
    --           (id=6 car 5 fenetres existent deja dans le jeu initial)
    -- ===========================================================
    DBMS_OUTPUT.PUT_LINE('--- Etape 1 : planifier_fenetre ---');
    pkg_nanoOrbit.planifier_fenetre(
        p_id_satellite   => c_satellite,
        p_code_station   => c_station,
        p_datetime_debut => c_datetime,
        p_duree          => c_duree,
        p_id_fenetre     => v_id_fenetre
    );
    DBMS_OUTPUT.PUT_LINE('  id_fenetre retourne (OUT) : ' || v_id_fenetre);

    -- ===========================================================
    -- ETAPE 2 : cloturer_fenetre
    -- La fenetre planifiee est marquee Realisee avec 1500 Mo.
    -- Le trigger T3 n'intervient pas (statut devient Realisee).
    --
    -- Attendu : "[pkg] Fenetre 6 cloturee avec 1500 Mo."
    -- ===========================================================
    DBMS_OUTPUT.PUT_LINE('--- Etape 2 : cloturer_fenetre ---');
    pkg_nanoOrbit.cloturer_fenetre(
        p_id_fenetre     => v_id_fenetre,
        p_volume_donnees => c_volume_cloture
    );

    -- ===========================================================
    -- ETAPE 3 : affecter_satellite_mission
    -- SAT-004 n'est pas encore dans MSN-ARC-2023.
    -- T4 verifie : MSN-ARC-2023 Active et SAT-004 non Desorbite -> OK
    --
    -- Attendu : "[pkg] Affectation : SAT-004 -> MSN-ARC-2023 (role : Satellite de relais)"
    -- ===========================================================
    DBMS_OUTPUT.PUT_LINE('--- Etape 3 : affecter_satellite_mission ---');
    pkg_nanoOrbit.affecter_satellite_mission(
        p_id_satellite => c_satellite_msn,
        p_id_mission   => c_mission,
        p_role         => c_role
    );

    -- ===========================================================
    -- ETAPE 4 : stats_satellite (SAT-001)
    -- Apres les etapes 1 et 2 :
    --   Fenetres realisees SAT-001 = 2 (id=1 + id=6)
    --   Volume total                = 1250 + 1500 = 2750 Mo
    --   Duree moyenne               = (420 + 450) / 2 = 435 s
    --
    -- Attendu :
    --   Nb fenetres realisees : 2
    --   Volume total          : 2750 Mo
    --   Duree moyenne         : 435 s
    -- ===========================================================
    DBMS_OUTPUT.PUT_LINE('--- Etape 4 : stats_satellite(' || c_satellite || ') ---');
    v_stats := pkg_nanoOrbit.stats_satellite(c_satellite);
    DBMS_OUTPUT.PUT_LINE(
        '  Nb fenetres realisees : ' || v_stats.nb_fenetres
    );
    DBMS_OUTPUT.PUT_LINE(
        '  Volume total          : ' || v_stats.volume_total || ' Mo'
    );
    DBMS_OUTPUT.PUT_LINE(
        '  Duree moyenne         : ' || ROUND(v_stats.duree_moy_secondes) || ' s'
    );

    -- ===========================================================
    -- ETAPE 5 : statut_constellation
    -- A ce stade (dans la transaction) :
    --   3 satellites Operationnels (SAT-001, SAT-002, SAT-003)
    --   1 satellite En veille (SAT-004)
    --   1 satellite Desorbite (SAT-005)
    --   2 missions Active (ARC + COAST)
    --   4 fenetres Realisees (1, 2, 3, 6) -- la 4 et 5 restent Planifiees
    --
    -- Attendu : "3/5 satellites operationnels, 2 missions actives, 4 fenetres realisees [...]"
    -- ===========================================================
    DBMS_OUTPUT.PUT_LINE('--- Etape 5 : statut_constellation ---');
    v_constellation := pkg_nanoOrbit.statut_constellation();
    DBMS_OUTPUT.PUT_LINE('  ' || v_constellation);

    -- ===========================================================
    -- ETAPE 6 : calculer_volume_theorique
    -- Fenetre planifiee a l'etape 1 :
    --   GS-KIR-01 debit = 400 Mbps, duree = 450 s
    --   Volume = (400/8) * 450 = 50 * 450 = 22500.0 Mo
    --
    -- Attendu : 22500.0 Mo
    -- ===========================================================
    DBMS_OUTPUT.PUT_LINE('--- Etape 6 : calculer_volume_theorique(fenetre ' || v_id_fenetre || ') ---');
    v_volume_theo := pkg_nanoOrbit.calculer_volume_theorique(v_id_fenetre);
    DBMS_OUTPUT.PUT_LINE(
        '  Volume theorique fenetre ' || v_id_fenetre || ' : ' ||
        TO_CHAR(v_volume_theo, 'FM99999990.0') || ' Mo'
    );

    -- ===========================================================
    -- ETAPE 7 : mettre_en_revision
    -- SAT-004 passe de 'En veille' a 'Defaillant'.
    -- Le trigger T5 journalise le changement dans HISTORIQUE_STATUT.
    --
    -- Attendu :
    --   "T5 (RG-S06 tracabilite) : SAT-004 : En veille --> Defaillant"
    --   "[pkg] SAT-004 mis en revision (Defaillant) depuis En veille"
    -- ===========================================================
    DBMS_OUTPUT.PUT_LINE('--- Etape 7 : mettre_en_revision(' || c_sat_revision || ') ---');
    pkg_nanoOrbit.mettre_en_revision(c_sat_revision);

    DECLARE
        v_nb_hist NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_nb_hist
        FROM   HISTORIQUE_STATUT
        WHERE  id_satellite = c_sat_revision;
        DBMS_OUTPUT.PUT_LINE(
            '  HISTORIQUE_STATUT : ' || v_nb_hist ||
            ' ligne(s) pour ' || c_sat_revision
        );
    END;

    -- ===========================================================
    -- RESUME FINAL
    -- ===========================================================
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 65, '='));
    DBMS_OUTPUT.PUT_LINE('  RESUME SCENARIO');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 65, '='));
    DBMS_OUTPUT.PUT_LINE('  Fenetre planifiee et cloturee : id=' || v_id_fenetre);
    DBMS_OUTPUT.PUT_LINE('  Satellite affecte a mission   : ' || c_satellite_msn || ' -> ' || c_mission);
    DBMS_OUTPUT.PUT_LINE('  Constellation apres scenario  : ' || pkg_nanoOrbit.statut_constellation());

    -- ===========================================================
    -- ROLLBACK : on annule toutes les modifications du scenario
    -- pour preserver le jeu de donnees de reference L2-B.
    -- ===========================================================
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 65, '-'));
    DBMS_OUTPUT.PUT_LINE('  ROLLBACK effectue -- jeu de donnees initial restaure.');
    DBMS_OUTPUT.PUT_LINE('  Constellation post-rollback : ' || pkg_nanoOrbit.statut_constellation());

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[ERREUR INATTENDUE] ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Rollback de securite effectue.');
        RAISE;
END;
/

-- ============================================================
-- TESTS DES CAS D'ERREUR DU PACKAGE
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE(RPAD('=', 65, '=')); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE('  TESTS CAS D''ERREUR pkg_nanoOrbit'); END;
/
BEGIN DBMS_OUTPUT.PUT_LINE(RPAD('=', 65, '=')); END;
/

-- Test erreur planifier_fenetre : duree hors domaine
BEGIN
    DECLARE v_id NUMBER;
    BEGIN
        pkg_nanoOrbit.planifier_fenetre('SAT-001', 'GS-KIR-01',
            TIMESTAMP '2024-03-01 10:00:00', 1000, v_id);
    END;
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[Erreur -20100 attendue] ' || SQLERRM);
END;
/

-- Test erreur planifier_fenetre : satellite Desorbite (T1 leve -20001)
BEGIN
    DECLARE v_id NUMBER;
    BEGIN
        pkg_nanoOrbit.planifier_fenetre('SAT-005', 'GS-TLS-01',
            TIMESTAMP '2024-03-01 10:00:00', 300, v_id);
    END;
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[Erreur T1 -20001 attendue] ' || SQLERRM);
END;
/

-- Test erreur cloturer_fenetre : fenetre inexistante
BEGIN
    pkg_nanoOrbit.cloturer_fenetre(9999, 500);
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[Erreur -20110 attendue] ' || SQLERRM);
END;
/

-- Test erreur cloturer_fenetre : fenetre deja Realisee (fenetre 1)
BEGIN
    pkg_nanoOrbit.cloturer_fenetre(1, 500);
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[Erreur -20111 attendue] ' || SQLERRM);
END;
/

-- Test erreur affecter_satellite_mission : mission Terminee (T4 leve -20005)
BEGIN
    pkg_nanoOrbit.affecter_satellite_mission('SAT-002', 'MSN-DEF-2022', 'Observateur');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[Erreur T4 -20005 attendue] ' || SQLERRM);
END;
/

-- Test erreur affecter_satellite_mission : participation deja existante
BEGIN
    pkg_nanoOrbit.affecter_satellite_mission('SAT-001', 'MSN-ARC-2023', 'Doublon');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[Erreur -20120 attendue] ' || SQLERRM);
END;
/

-- Test erreur mettre_en_revision : satellite Desorbite
BEGIN
    pkg_nanoOrbit.mettre_en_revision('SAT-005');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[Erreur -20131 attendue] ' || SQLERRM);
END;
/

-- Test erreur stats_satellite : satellite inexistant
BEGIN
    DECLARE v_stats pkg_nanoOrbit.t_stats_satellite;
    BEGIN
        v_stats := pkg_nanoOrbit.stats_satellite('SAT-999');
    END;
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('[Erreur -20150 attendue] ' || SQLERRM);
END;
/

-- ============================================================
-- VERIFICATION ETAT FINAL : le jeu de donnees doit etre intact
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('=== Verification etat final post-tests ==='); END;
/

SELECT table_name,
       CASE table_name
           WHEN 'ORBITE'               THEN 3
           WHEN 'SATELLITE'            THEN 5
           WHEN 'HISTORIQUE_STATUT'    THEN 0
           WHEN 'INSTRUMENT'           THEN 4
           WHEN 'EMBARQUEMENT'         THEN 7
           WHEN 'CENTRE_CONTROLE'      THEN 2
           WHEN 'STATION_SOL'          THEN 3
           WHEN 'AFFECTATION_STATION'  THEN 3
           WHEN 'MISSION'              THEN 3
           WHEN 'FENETRE_COM'          THEN 5
           WHEN 'PARTICIPATION'        THEN 7
       END AS attendu,
       nb_lignes AS reel,
       CASE WHEN nb_lignes = CASE table_name
                WHEN 'ORBITE'              THEN 3
                WHEN 'SATELLITE'           THEN 5
                WHEN 'HISTORIQUE_STATUT'   THEN 0
                WHEN 'INSTRUMENT'          THEN 4
                WHEN 'EMBARQUEMENT'        THEN 7
                WHEN 'CENTRE_CONTROLE'     THEN 2
                WHEN 'STATION_SOL'         THEN 3
                WHEN 'AFFECTATION_STATION' THEN 3
                WHEN 'MISSION'             THEN 3
                WHEN 'FENETRE_COM'         THEN 5
                WHEN 'PARTICIPATION'       THEN 7
            END
            THEN '[OK]' ELSE '[DIFF]' END AS statut
FROM (
    SELECT 'ORBITE'               AS table_name, COUNT(*) AS nb_lignes FROM ORBITE           UNION ALL
    SELECT 'SATELLITE',            COUNT(*) FROM SATELLITE          UNION ALL
    SELECT 'HISTORIQUE_STATUT',    COUNT(*) FROM HISTORIQUE_STATUT  UNION ALL
    SELECT 'INSTRUMENT',           COUNT(*) FROM INSTRUMENT         UNION ALL
    SELECT 'EMBARQUEMENT',         COUNT(*) FROM EMBARQUEMENT       UNION ALL
    SELECT 'CENTRE_CONTROLE',      COUNT(*) FROM CENTRE_CONTROLE    UNION ALL
    SELECT 'STATION_SOL',          COUNT(*) FROM STATION_SOL        UNION ALL
    SELECT 'AFFECTATION_STATION',  COUNT(*) FROM AFFECTATION_STATION UNION ALL
    SELECT 'MISSION',              COUNT(*) FROM MISSION            UNION ALL
    SELECT 'FENETRE_COM',          COUNT(*) FROM FENETRE_COM        UNION ALL
    SELECT 'PARTICIPATION',        COUNT(*) FROM PARTICIPATION
)
ORDER BY table_name;

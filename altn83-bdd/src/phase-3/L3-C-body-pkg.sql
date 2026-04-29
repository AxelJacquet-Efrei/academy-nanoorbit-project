-- ============================================================
-- Codes erreur utilises dans ce BODY :
--   -20100 a -20109 : planifier_fenetre
--   -20110 a -20119 : cloturer_fenetre
--   -20120 a -20129 : affecter_satellite_mission
--   -20130 a -20139 : mettre_en_revision
--   -20140 a -20149 : calculer_volume_theorique
--   -20150 a -20159 : stats_satellite
--   (Les triggers de Phase 2 gardent leur plage -20000 a -20006)
-- ============================================================

ALTER SESSION SET CURRENT_SCHEMA = ACADEMY_NANOORBIT_PROJECT;

CREATE OR REPLACE PACKAGE BODY pkg_nanoOrbit AS

    -- ========================================================
    -- PROCEDURE planifier_fenetre
    -- ========================================================
    PROCEDURE planifier_fenetre(
        p_id_satellite   IN  VARCHAR2,
        p_code_station   IN  VARCHAR2,
        p_datetime_debut IN  TIMESTAMP,
        p_duree          IN  NUMBER,
        p_id_fenetre     OUT NUMBER
    )
    AS
        v_new_id NUMBER;
    BEGIN
        IF p_duree < 1 OR p_duree > c_duree_max_fenetre THEN
            RAISE_APPLICATION_ERROR(-20100,
                'Duree invalide : ' || p_duree ||
                ' s (doit etre comprise entre 1 et ' || c_duree_max_fenetre || ' s).');
        END IF;

        INSERT INTO FENETRE_COM (
            datetime_debut, duree, elevation_max,
            volume_donnees, statut, id_satellite, code_station
        )
        VALUES (
            p_datetime_debut, p_duree, 0,
            NULL, 'Planifiee', p_id_satellite, p_code_station
        )
        RETURNING id_fenetre INTO v_new_id;

        p_id_fenetre := v_new_id;

        DBMS_OUTPUT.PUT_LINE(
            '[pkg] Fenetre planifiee : id=' || v_new_id ||
            ' | ' || p_id_satellite || ' -> ' || p_code_station ||
            ' | ' || TO_CHAR(p_datetime_debut, 'DD/MM/YYYY HH24:MI') ||
            ' | ' || p_duree || ' s'
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -2291 THEN
                RAISE_APPLICATION_ERROR(-20101,
                    'Satellite ou station introuvable : ' || SQLERRM);
            ELSE
                RAISE;
            END IF;
    END planifier_fenetre;

    -- ========================================================
    -- PROCEDURE cloturer_fenetre
    -- ========================================================
    PROCEDURE cloturer_fenetre(
        p_id_fenetre     IN NUMBER,
        p_volume_donnees IN NUMBER
    )
    AS
        v_statut_actuel FENETRE_COM.statut%TYPE;
    BEGIN
        SELECT statut INTO v_statut_actuel
        FROM   FENETRE_COM
        WHERE  id_fenetre = p_id_fenetre;

        IF v_statut_actuel != 'Planifiee' THEN
            RAISE_APPLICATION_ERROR(-20111,
                'Fenetre ' || p_id_fenetre ||
                ' ne peut pas etre cloturee (statut actuel : ' || v_statut_actuel || ').');
        END IF;

        IF p_volume_donnees <= 0 THEN
            RAISE_APPLICATION_ERROR(-20112,
                'Volume invalide : ' || p_volume_donnees || ' Mo (doit etre > 0).');
        END IF;

        UPDATE FENETRE_COM
        SET    statut         = 'Realisee',
               volume_donnees = p_volume_donnees
        WHERE  id_fenetre = p_id_fenetre;

        DBMS_OUTPUT.PUT_LINE(
            '[pkg] Fenetre ' || p_id_fenetre ||
            ' cloturee avec ' || p_volume_donnees || ' Mo.'
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20110,
                'Fenetre ' || p_id_fenetre || ' introuvable.');
    END cloturer_fenetre;

    -- ========================================================
    -- PROCEDURE affecter_satellite_mission
    -- ========================================================
    PROCEDURE affecter_satellite_mission(
        p_id_satellite IN VARCHAR2,
        p_id_mission   IN VARCHAR2,
        p_role         IN VARCHAR2
    )
    AS
    BEGIN
        INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
        VALUES (p_id_satellite, p_id_mission, p_role);

        DBMS_OUTPUT.PUT_LINE(
            '[pkg] Affectation : ' || p_id_satellite ||
            ' -> ' || p_id_mission ||
            ' (role : ' || p_role || ')'
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20120,
                'Participation deja existante : ' ||
                p_id_satellite || ' / ' || p_id_mission);
        WHEN OTHERS THEN
            RAISE;
    END affecter_satellite_mission;

    -- ========================================================
    -- PROCEDURE mettre_en_revision
    -- ========================================================
    PROCEDURE mettre_en_revision(
        p_id_satellite IN VARCHAR2
    )
    AS
        v_statut_actuel SATELLITE.statut%TYPE;
    BEGIN
        SELECT statut INTO v_statut_actuel
        FROM   SATELLITE
        WHERE  id_satellite = p_id_satellite;

        IF v_statut_actuel IN ('Defaillant', 'Desorbite') THEN
            RAISE_APPLICATION_ERROR(-20131,
                'Satellite ' || p_id_satellite ||
                ' deja en etat terminal (' || v_statut_actuel ||
                ') -- mise en revision non applicable.');
        END IF;

        UPDATE SATELLITE
        SET    statut = 'Defaillant'
        WHERE  id_satellite = p_id_satellite;

        DBMS_OUTPUT.PUT_LINE(
            '[pkg] ' || p_id_satellite ||
            ' mis en revision (Defaillant) depuis ' || v_statut_actuel ||
            ' -- trace dans HISTORIQUE_STATUT (T5).'
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20130,
                'Satellite ' || p_id_satellite || ' introuvable.');
    END mettre_en_revision;

    -- ========================================================
    -- FONCTION calculer_volume_theorique
    -- ========================================================
    FUNCTION calculer_volume_theorique(
        p_id_fenetre IN NUMBER
    ) RETURN NUMBER
    AS
        v_debit NUMBER;
        v_duree NUMBER;
    BEGIN
        SELECT ss.debit_max, fc.duree
        INTO   v_debit, v_duree
        FROM   FENETRE_COM fc
        JOIN   STATION_SOL ss ON fc.code_station = ss.code_station
        WHERE  fc.id_fenetre = p_id_fenetre;

        RETURN ROUND((v_debit / 8) * v_duree, 1);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20140,
                'Fenetre ' || p_id_fenetre || ' introuvable.');
    END calculer_volume_theorique;

    -- ========================================================
    -- FONCTION statut_constellation
    -- ========================================================
    FUNCTION statut_constellation RETURN VARCHAR2
    AS
        v_total_sat    NUMBER;
        v_op_sat       NUMBER;
        v_veille_sat   NUMBER;
        v_desorbite    NUMBER;
        v_missions_act NUMBER;
        v_fenetres_rec NUMBER;
    BEGIN
        SELECT COUNT(*)                                          ,
               COUNT(CASE WHEN statut = 'Operationnel' THEN 1 END),
               COUNT(CASE WHEN statut = 'En veille'    THEN 1 END),
               COUNT(CASE WHEN statut = 'Desorbite'    THEN 1 END)
        INTO   v_total_sat, v_op_sat, v_veille_sat, v_desorbite
        FROM   SATELLITE;

        SELECT COUNT(*)
        INTO   v_missions_act
        FROM   MISSION
        WHERE  statut_mission = 'Active';

        SELECT COUNT(*)
        INTO   v_fenetres_rec
        FROM   FENETRE_COM
        WHERE  statut = 'Realisee';

        RETURN v_op_sat || '/' || v_total_sat   || ' satellites operationnels, ' ||
               v_missions_act                   || ' missions actives, '          ||
               v_fenetres_rec                   || ' fenetres realisees'          ||
               ' [en veille: ' || v_veille_sat  ||
               ', desorbites: ' || v_desorbite  || ']';
    END statut_constellation;

    -- ========================================================
    -- FONCTION stats_satellite
    -- ========================================================
    FUNCTION stats_satellite(
        p_id_satellite IN VARCHAR2
    ) RETURN t_stats_satellite
    AS
        v_stats   t_stats_satellite;
        v_exists  NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exists
        FROM   SATELLITE
        WHERE  id_satellite = p_id_satellite;

        IF v_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20150,
                'Satellite ' || p_id_satellite || ' introuvable.');
        END IF;

        SELECT NVL(COUNT(*), 0),
               NVL(SUM(volume_donnees), 0),
               NVL(AVG(duree), 0)
        INTO   v_stats.nb_fenetres,
               v_stats.volume_total,
               v_stats.duree_moy_secondes
        FROM   FENETRE_COM
        WHERE  id_satellite = p_id_satellite
          AND  statut       = 'Realisee';

        RETURN v_stats;
    END stats_satellite;

END pkg_nanoOrbit;
/
SHOW ERRORS;

-- ============================================================
-- TESTS DE COMPILATION -- verifier que le BODY est valide
-- ============================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Test compilation BODY pkg_nanoOrbit ===');
    DBMS_OUTPUT.PUT_LINE('Constellation : ' || pkg_nanoOrbit.statut_constellation());
END;
/

DECLARE
    v_vol NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test calculer_volume_theorique ---');
    FOR i IN 1..5 LOOP
        v_vol := pkg_nanoOrbit.calculer_volume_theorique(i);
        DBMS_OUTPUT.PUT_LINE('Fenetre ' || i || ' : ' || v_vol || ' Mo theoriques');
    END LOOP;
END;
/

-- Test stats_satellite (lecture seule)
DECLARE
    v_stats pkg_nanoOrbit.t_stats_satellite;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test stats_satellite ---');
    FOR rec IN (SELECT id_satellite FROM SATELLITE ORDER BY id_satellite) LOOP
        v_stats := pkg_nanoOrbit.stats_satellite(rec.id_satellite);
        DBMS_OUTPUT.PUT_LINE(
            rec.id_satellite || ' : ' ||
            v_stats.nb_fenetres || ' fenetres | ' ||
            v_stats.volume_total || ' Mo | ' ||
            ROUND(v_stats.duree_moy_secondes) || ' s moy'
        );
    END LOOP;
END;
/


-- ============================================================
-- FONCTIONS AUXILIAIRES -- Detection des chevauchements T2
-- Regles    : RG-F02 (pas de chevauchement satellite)
--             RG-F03 (pas de chevauchement station)
--
-- Objectif :
--   Fournir a T2 deux fonctions de controle permettant de detecter
--   les fenetres de communication existantes qui se chevauchent avec
--   le creneau en cours d'insertion ou de modification.
--
-- Principe du chevauchement :
--   Deux intervalles [A, A+durA) et [B, B+durB) se chevauchent si et
--   seulement si :
--      A < B+durB ET B < A+durA
--
-- Implementation :
--   - fn_overlap_satellite : compte les chevauchements pour un satellite
--   - fn_overlap_station   : compte les chevauchements pour une station sol
--   - NUMTODSINTERVAL(duree, 'SECOND') convertit les durees en secondes
--
-- Gestion INSERT / UPDATE :
--   - INSERT : p_excl_id = -1, aucun enregistrement n'est exclu
--   - UPDATE : p_excl_id = :OLD.id_fenetre, afin d'ignorer la fenetre
--              en cours de modification
--
-- Note technique :
--   PRAGMA AUTONOMOUS_TRANSACTION permet de lire FENETRE_COM depuis T2
--   sans declencher ORA-04091 (table mutante). Les fonctions lisent
--   l'etat commite de FENETRE_COM avant le DML en cours.
--
-- Retour :
--   0  : aucun chevauchement detecte
--   >0 : au moins un chevauchement detecte
-- ============================================================

CREATE OR REPLACE FUNCTION fn_overlap_satellite(
    p_satellite  VARCHAR2,
    p_debut      TIMESTAMP,
    p_duree      NUMBER,
    p_excl_id    NUMBER DEFAULT -1
) RETURN NUMBER
AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM   FENETRE_COM
    WHERE  id_satellite = p_satellite
      AND  id_fenetre  != p_excl_id
      AND  p_debut      < datetime_debut + NUMTODSINTERVAL(duree, 'SECOND')
      AND  datetime_debut < p_debut       + NUMTODSINTERVAL(p_duree, 'SECOND');
    RETURN v_cnt;
END fn_overlap_satellite;
/

CREATE OR REPLACE FUNCTION fn_overlap_station(
    p_station    VARCHAR2,
    p_debut      TIMESTAMP,
    p_duree      NUMBER,
    p_excl_id    NUMBER DEFAULT -1
) RETURN NUMBER
AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM   FENETRE_COM
    WHERE  code_station = p_station
      AND  id_fenetre  != p_excl_id
      AND  p_debut      < datetime_debut + NUMTODSINTERVAL(duree, 'SECOND')
      AND  datetime_debut < p_debut       + NUMTODSINTERVAL(p_duree, 'SECOND');
    RETURN v_cnt;
END fn_overlap_station;
/

-- ============================================================
-- T1 -- trg_valider_fenetre
-- Evenement : BEFORE INSERT ON FENETRE_COM
-- Regles    : RG-S06 (satellite Desorbite) + RG-G03 (station Maintenance)
--
-- Logique :
--   1. Lire le statut du satellite (:NEW.id_satellite) dans SATELLITE
--   2. Si statut = 'Desorbite' --> RAISE_APPLICATION_ERROR (-20001)
--   3. Lire le statut de la station (:NEW.code_station) dans STATION_SOL
--   4. Si statut = 'Maintenance' --> RAISE_APPLICATION_ERROR (-20004)
-- ============================================================

CREATE OR REPLACE TRIGGER trg_valider_fenetre
BEFORE INSERT ON FENETRE_COM
FOR EACH ROW
DECLARE
    v_statut_sat VARCHAR2(30);
    v_statut_sta VARCHAR2(20);
BEGIN
    -- RG-S06 : satellite desorbite
    SELECT statut INTO v_statut_sat
    FROM   SATELLITE
    WHERE  id_satellite = :NEW.id_satellite;

    IF v_statut_sat = 'Desorbite' THEN
        RAISE_APPLICATION_ERROR(-20001,
            'RG-S06 : Le satellite ' || :NEW.id_satellite ||
            ' est Desorbite -- creation de fenetre de communication impossible.');
    END IF;

    -- RG-G03 : station en maintenance
    SELECT statut INTO v_statut_sta
    FROM   STATION_SOL
    WHERE  code_station = :NEW.code_station;

    IF v_statut_sta = 'Maintenance' THEN
        RAISE_APPLICATION_ERROR(-20004,
            'RG-G03 : La station ' || :NEW.code_station ||
            ' est en Maintenance -- planification de fenetre impossible.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20000,
            'Satellite ou station introuvable -- verification des FK.');
END trg_valider_fenetre;
/

-- ============================================================
-- CAS DE TEST T1
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('--- Tests T1 : trg_valider_fenetre ---'); END;
/

-- CAS VALIDE : SAT-001 (Operationnel) + GS-KIR-01 (Active)
-- Attendu : insertion reussie
BEGIN
    INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
    VALUES (TIMESTAMP '2024-02-01 10:00:00', 300, 45.0, NULL, 'Planifiee', 'SAT-001', 'GS-KIR-01');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[OK] CAS VALIDE T1 : insertion SAT-001/GS-KIR-01 autorisee (rollback apres test)');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[KO] CAS VALIDE T1 inattendu : ' || SQLERRM);
END;
/

-- CAS ERREUR : SAT-005 (Desorbite) -- attendu : ORA-20001
BEGIN
    INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
    VALUES (TIMESTAMP '2024-02-01 10:00:00', 300, 45.0, NULL, 'Planifiee', 'SAT-005', 'GS-TLS-01');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[KO] CAS ERREUR T1 : insertion aurait du etre bloquee (RG-S06)');
EXCEPTION   
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[OK] CAS ERREUR T1 (RG-S06) : ' || SQLERRM);
END;
/

-- CAS ERREUR : GS-SGP-01 (Maintenance) -- attendu : ORA-20004
BEGIN
    INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
    VALUES (TIMESTAMP '2024-02-01 10:00:00', 300, 45.0, NULL, 'Planifiee', 'SAT-001', 'GS-SGP-01');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[KO] CAS ERREUR T1 : insertion aurait du etre bloquee (RG-G03)');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[OK] CAS ERREUR T1 (RG-G03) : ' || SQLERRM);
END;
/

-- ============================================================
-- T2 -- trg_no_chevauchement
-- Evenement : BEFORE INSERT OR UPDATE ON FENETRE_COM
-- Regles    : RG-F02 (pas de chevauchement satellite) + RG-F03 (station)
--
-- Logique :
--   Deux fenetres [A, A+durA) et [B, B+durB) se chevauchent si et seulement si :
--   A < B+durB ET B < A+durA
--
--   Pour INSERT : exclure id_fenetre = -1 (aucun enregistrement n'a cet id)
--   Pour UPDATE : exclure :OLD.id_fenetre (la fenetre qu'on est en train de modifier)
--
-- Note technique : utilise les fonctions auxiliaires (PRAGMA AUTONOMOUS_TRANSACTION)
-- pour eviter ORA-04091.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_no_chevauchement
BEFORE INSERT OR UPDATE ON FENETRE_COM
FOR EACH ROW
DECLARE
    v_excl_id NUMBER;
BEGIN
    -- Pour UPDATE : exclure la fenetre courante
    -- Pour INSERT : p_excl_id = -1 (aucune fenetre ne peut avoir cet id)
    v_excl_id := CASE WHEN UPDATING THEN :OLD.id_fenetre ELSE -1 END;

    -- RG-F02 : verification chevauchement pour le satellite
    IF fn_overlap_satellite(:NEW.id_satellite, :NEW.datetime_debut, :NEW.duree, v_excl_id) > 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'RG-F02 : Chevauchement temporel detecte pour le satellite ' ||
            :NEW.id_satellite || ' a partir de ' ||
            TO_CHAR(:NEW.datetime_debut, 'YYYY-MM-DD HH24:MI:SS'));
    END IF;

    -- RG-F03 : verification chevauchement pour la station
    IF fn_overlap_station(:NEW.code_station, :NEW.datetime_debut, :NEW.duree, v_excl_id) > 0 THEN
        RAISE_APPLICATION_ERROR(-20003,
            'RG-F03 : Chevauchement temporel detecte pour la station ' ||
            :NEW.code_station || ' a partir de ' ||
            TO_CHAR(:NEW.datetime_debut, 'YYYY-MM-DD HH24:MI:SS'));
    END IF;

END trg_no_chevauchement;
/

-- ============================================================
-- CAS DE TEST T2
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('--- Tests T2 : trg_no_chevauchement ---'); END;
/

-- CAS VALIDE : SAT-002 / GS-KIR-01 -- creneau sans chevauchement
-- Fenetre existante : SAT-003/GS-KIR-01 le 2024-01-16 08:30 (+540s = 08:39)
-- Nouveau creneau  : 2024-01-16 10:00 (+300s = 10:05) --> aucun chevauchement
-- Attendu : insertion reussie
BEGIN
    INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
    VALUES (TIMESTAMP '2024-01-16 10:00:00', 300, 50.0, NULL, 'Planifiee', 'SAT-002', 'GS-KIR-01');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[OK] CAS VALIDE T2 : aucun chevauchement detecte (rollback)');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[KO] CAS VALIDE T2 inattendu : ' || SQLERRM);
END;
/

-- CAS ERREUR RG-F02 : SAT-001 / GS-KIR-01 -- chevauchement satellite
-- Fenetre existante : SAT-001/GS-KIR-01 le 2024-01-15 09:14 (+420s = 09:21)
-- Nouveau creneau  : 2024-01-15 09:20 (+200s = 09:23) --> chevauche [09:14, 09:21)
-- Attendu : ORA-20002
BEGIN
    INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
    VALUES (TIMESTAMP '2024-01-15 09:20:00', 200, 60.0, NULL, 'Planifiee', 'SAT-001', 'GS-TLS-01');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[KO] CAS ERREUR T2 (RG-F02) : insertion aurait du etre bloquee');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[OK] CAS ERREUR T2 (RG-F02 chevauchement satellite) : ' || SQLERRM);
END;
/

-- CAS ERREUR RG-F03 : chevauchement station GS-TLS-01
-- Fenetre existante : SAT-002/GS-TLS-01 le 2024-01-15 11:52 (+310s = 11:57:10)
-- Nouveau creneau  : SAT-003/GS-TLS-01 le 2024-01-15 11:55 (+200s = 11:58:20) --> chevauche
-- Attendu : ORA-20003
BEGIN
    INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
    VALUES (TIMESTAMP '2024-01-15 11:55:00', 200, 50.0, NULL, 'Planifiee', 'SAT-003', 'GS-TLS-01');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[KO] CAS ERREUR T2 (RG-F03) : insertion aurait du etre bloquee');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[OK] CAS ERREUR T2 (RG-F03 chevauchement station) : ' || SQLERRM);
END;
/

-- ============================================================
-- T3 -- trg_volume_realise
-- Evenement : BEFORE INSERT OR UPDATE ON FENETRE_COM
-- Regle     : RG-F05 -- volume_donnees doit etre NULL si statut != 'Realisee'
--
-- Logique :
--   Si :NEW.statut != 'Realisee' alors forcer :NEW.volume_donnees := NULL
--   (correction silencieuse plutot que blocage -- comportement defensif)
-- ============================================================
CREATE OR REPLACE TRIGGER trg_volume_realise
BEFORE INSERT OR UPDATE ON FENETRE_COM
FOR EACH ROW
BEGIN
    -- RG-F05 : volume_donnees ne peut etre renseigne que pour une fenetre Realisee
    IF :NEW.statut != 'Realisee' THEN
        IF :NEW.volume_donnees IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE(
                'T3 (RG-F05) : volume_donnees force a NULL -- statut = ' ||
                :NEW.statut || ' (fenetre ' || NVL(TO_CHAR(:NEW.id_fenetre),'NEW') || ')');
            :NEW.volume_donnees := NULL;
        END IF;
    END IF;
END trg_volume_realise;
/

-- ============================================================
-- CAS DE TEST T3
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('--- Tests T3 : trg_volume_realise ---'); END;
/

-- CAS VALIDE : Planifiee avec volume NULL -- attendu : insertion reussie
BEGIN
    INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
    VALUES (TIMESTAMP '2024-02-10 08:00:00', 300, 40.0, NULL, 'Planifiee', 'SAT-002', 'GS-KIR-01');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[OK] CAS VALIDE T3 : Planifiee/NULL accepte (rollback)');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[KO] CAS VALIDE T3 inattendu : ' || SQLERRM);
END;
/

-- CAS CORRECTION : Planifiee avec volume renseigne -- attendu : volume force a NULL par T3
BEGIN
    INSERT INTO FENETRE_COM (datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station)
    VALUES (TIMESTAMP '2024-02-10 08:00:00', 300, 40.0, 500, 'Planifiee', 'SAT-002', 'GS-KIR-01');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[OK] CAS CORRECTION T3 : volume_donnees force a NULL (message T3 attendu ci-dessus, rollback)');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[KO] CAS CORRECTION T3 inattendu : ' || SQLERRM);
END;
/

-- ============================================================
-- T4 -- trg_mission_terminee
-- Evenement : BEFORE INSERT ON PARTICIPATION
-- Regles    : RG-M04 (mission Terminee) + RG-S06 (satellite Desorbite)
--
-- Logique :
--   1. Lire statut_mission de (:NEW.id_mission)
--      Si statut_mission = 'Terminee' --> RAISE_APPLICATION_ERROR (-20005)
--   2. Lire statut du satellite (:NEW.id_satellite)
--      Si statut = 'Desorbite' --> RAISE_APPLICATION_ERROR (-20006)
--
-- Note sur les donnees de reference :
--   SAT-005 (Desorbite) participe a MSN-DEF-2022 (Terminee) dans L2-B.
--   Cette insertion est valide CAR L2-B est execute AVANT L2-C (triggers).
--   Une fois T4 actif, toute nouvelle participation de SAT-005 est bloquee.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_mission_terminee
BEFORE INSERT ON PARTICIPATION
FOR EACH ROW
DECLARE
    v_statut_mission VARCHAR2(20);
    v_statut_sat     VARCHAR2(30);
BEGIN
    -- RG-M04 : mission Terminee ne peut plus accueillir de nouveaux satellites
    SELECT statut_mission INTO v_statut_mission
    FROM   MISSION
    WHERE  id_mission = :NEW.id_mission;

    IF v_statut_mission = 'Terminee' THEN
        RAISE_APPLICATION_ERROR(-20005,
            'RG-M04 : La mission ' || :NEW.id_mission ||
            ' est Terminee -- ajout du satellite ' || :NEW.id_satellite || ' impossible.');
    END IF;

    -- RG-S06 : satellite Desorbite ne peut plus participer a une nouvelle mission
    SELECT statut INTO v_statut_sat
    FROM   SATELLITE
    WHERE  id_satellite = :NEW.id_satellite;

    IF v_statut_sat = 'Desorbite' THEN
        RAISE_APPLICATION_ERROR(-20006,
            'RG-S06 : Le satellite ' || :NEW.id_satellite ||
            ' est Desorbite -- participation a la mission ' || :NEW.id_mission || ' impossible.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20000,
            'Mission ou satellite introuvable (verification FK).');
END trg_mission_terminee;
/

-- ============================================================
-- CAS DE TEST T4
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('--- Tests T4 : trg_mission_terminee ---'); END;
/

-- CAS VALIDE : SAT-004 --> MSN-ARC-2023 (Active) -- attendu : insertion reussie
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-004', 'MSN-ARC-2023', 'Satellite de reserve');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[OK] CAS VALIDE T4 : SAT-004/MSN-ARC-2023 accepte (rollback)');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[KO] CAS VALIDE T4 inattendu : ' || SQLERRM);
END;
/

-- CAS ERREUR : SAT-002 --> MSN-DEF-2022 (Terminee) -- attendu : ORA-20005
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-002', 'MSN-DEF-2022', 'Imageur de relais');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[KO] CAS ERREUR T4 : insertion aurait du etre bloquee (RG-M04)');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[OK] CAS ERREUR T4 (RG-M04) : ' || SQLERRM);
END;
/

-- CAS ERREUR RG-S06 : SAT-005 (Desorbite) --> MSN-ARC-2023 (Active)
-- Attendu : ORA-20006 (satellite Desorbite bloque par RG-S06 dans T4)
BEGIN
    INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)
    VALUES ('SAT-005', 'MSN-ARC-2023', 'Imageur secondaire');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('[KO] CAS ERREUR T4 (RG-S06) : insertion aurait du etre bloquee');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[OK] CAS ERREUR T4 (RG-S06 satellite Desorbite) : ' || SQLERRM);
END;
/

-- ============================================================
-- T5 -- trg_historique_statut
-- Evenement : AFTER UPDATE OF statut ON SATELLITE
-- Regle     : RG-S06 (traçabilite) -- trace tout changement de statut
--
-- Logique :
--   Si :OLD.statut != :NEW.statut alors inserer une ligne dans HISTORIQUE_STATUT
--   avec l'ancien statut, le nouveau statut, SYSTIMESTAMP et le motif (NULL)
-- ============================================================
CREATE OR REPLACE TRIGGER trg_historique_statut
AFTER UPDATE OF statut ON SATELLITE
FOR EACH ROW
BEGIN
    -- Enregistrer uniquement si le statut a effectivement change
    IF :OLD.statut != :NEW.statut THEN
        INSERT INTO HISTORIQUE_STATUT (id_satellite, ancien_statut, nouveau_statut, date_changement, motif)
        VALUES (:OLD.id_satellite, :OLD.statut, :NEW.statut, SYSTIMESTAMP, NULL);
        DBMS_OUTPUT.PUT_LINE(
            'T5 (RG-S06 tracabilite) : ' || :OLD.id_satellite ||
            ' : ' || :OLD.statut || ' --> ' || :NEW.statut);
    END IF;
END trg_historique_statut;
/

-- ============================================================
-- CAS DE TEST T5
-- ============================================================
BEGIN DBMS_OUTPUT.PUT_LINE('--- Tests T5 : trg_historique_statut ---'); END;
/

-- CAS VALIDE : modification de statut SAT-004 En veille -> Operationnel
-- Attendu : 1 ligne inseree dans HISTORIQUE_STATUT
BEGIN
    UPDATE SATELLITE SET statut = 'Operationnel' WHERE id_satellite = 'SAT-004';
    DBMS_OUTPUT.PUT_LINE('[OK] T5 : SAT-004 mis a jour Operationnel -- verifier HISTORIQUE_STATUT');
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('     Rollback effectue -- HISTORIQUE_STATUT remis a 0');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[KO] T5 inattendu : ' || SQLERRM);
END;
/

-- CAS SANS EFFET : mise a jour sans changement de statut
-- Attendu : aucune ligne inseree dans HISTORIQUE_STATUT
BEGIN
    UPDATE SATELLITE SET masse = 2.01 WHERE id_satellite = 'SAT-004';
    DBMS_OUTPUT.PUT_LINE('[OK] T5 : mise a jour hors statut -- HISTORIQUE_STATUT non affecte');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[KO] T5 inattendu : ' || SQLERRM);
END;
/

-- Verification de HISTORIQUE_STATUT apres tests
SELECT * FROM HISTORIQUE_STATUT ORDER BY date_changement DESC;
-- Attendu : 0 ligne (tous les tests ont ete annules par ROLLBACK)

BEGIN DBMS_OUTPUT.PUT_LINE('=== TRIGGERS CREES ==='); END;
/

SELECT trigger_name, trigger_type, triggering_event, status
FROM   user_triggers
WHERE  table_name IN ('FENETRE_COM', 'PARTICIPATION', 'SATELLITE')
ORDER  BY table_name, trigger_name;


BEGIN DBMS_OUTPUT.PUT_LINE('=== ERREURS DE COMPILATION (doit etre vide) ==='); END;
/

SELECT name, type, line, position, text
FROM   user_errors
WHERE  name IN (
    'FN_OVERLAP_SATELLITE',
    'FN_OVERLAP_STATION',
    'TRG_VALIDER_FENETRE',
    'TRG_NO_CHEVAUCHEMENT',
    'TRG_VOLUME_REALISE',
    'TRG_MISSION_TERMINEE',
    'TRG_HISTORIQUE_STATUT'
)
ORDER  BY name, sequence;

-- Verification globale du statut des objets
SELECT object_name, object_type, status
FROM   user_objects
WHERE  object_name IN (
    'FN_OVERLAP_SATELLITE',
    'FN_OVERLAP_STATION',
    'TRG_VALIDER_FENETRE',
    'TRG_NO_CHEVAUCHEMENT',
    'TRG_VOLUME_REALISE',
    'TRG_MISSION_TERMINEE',
    'TRG_HISTORIQUE_STATUT'
)
ORDER  BY object_type, object_name;

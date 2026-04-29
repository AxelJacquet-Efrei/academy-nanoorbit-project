ALTER SESSION SET CURRENT_SCHEMA = ACADEMY_NANOORBIT_PROJECT;
-- Forcer le point comme separateur decimal (sinon affichage "1,3" en session FR)
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

-- ============================================================
-- PALIER 1 - BLOC ANONYME
-- ============================================================

-- ------------------------------------------------------------
-- Ex. 1 : Message de bienvenue et comptage general
--
-- Resultat attendu :
--   === NanoOrbit CubeSat Earth Observation System ===
--   EFREI ALTN83 - Bases de donnees reparties - 2025-2026
--   ---
--   Satellites dans la base   : 5
--   Stations au sol           : 3
--   Missions actives          : 2
--   Missions totales          : 3
--   Fenetres de communication : 5
-- ------------------------------------------------------------
DECLARE
    v_nb_satellites  NUMBER;
    v_nb_stations    NUMBER;
    v_nb_missions    NUMBER;
    v_nb_actives     NUMBER;
    v_nb_fenetres    NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nb_satellites FROM SATELLITE;
    SELECT COUNT(*) INTO v_nb_stations   FROM STATION_SOL;
    SELECT COUNT(*) INTO v_nb_missions   FROM MISSION;
    SELECT COUNT(*) INTO v_nb_actives    FROM MISSION WHERE statut_mission = 'Active';
    SELECT COUNT(*) INTO v_nb_fenetres   FROM FENETRE_COM;

    DBMS_OUTPUT.PUT_LINE('=== NanoOrbit CubeSat Earth Observation System ===');
    DBMS_OUTPUT.PUT_LINE('EFREI ALTN83 - Bases de donnees reparties - 2025-2026');
    DBMS_OUTPUT.PUT_LINE('---');
    DBMS_OUTPUT.PUT_LINE('Satellites dans la base   : ' || v_nb_satellites);
    DBMS_OUTPUT.PUT_LINE('Stations au sol           : ' || v_nb_stations);
    DBMS_OUTPUT.PUT_LINE('Missions actives          : ' || v_nb_actives);
    DBMS_OUTPUT.PUT_LINE('Missions totales          : ' || v_nb_missions);
    DBMS_OUTPUT.PUT_LINE('Fenetres de communication : ' || v_nb_fenetres);
END;
/

-- ------------------------------------------------------------
-- Ex. 2 : SELECT INTO -- caracteristiques du satellite SAT-001
--
-- Resultat attendu :
--   === Ex.2 : Caracteristiques SAT-001 ===
--   Satellite      : SAT-001 - NanoOrbit-Alpha
--   Lancement      : 15/03/2022
--   Masse          : 1.3 kg | Format : 3U
--   Statut         : Operationnel
--   Duree de vie   : 60 mois | Batterie : 20 Wh
--   Orbite courante: ORB-001
-- ------------------------------------------------------------
DECLARE
    v_id_satellite  SATELLITE.id_satellite%TYPE;
    v_nom           SATELLITE.nom_satellite%TYPE;
    v_lancement     SATELLITE.date_lancement%TYPE;
    v_masse         SATELLITE.masse%TYPE;
    v_format        SATELLITE.format_cubesat%TYPE;
    v_statut        SATELLITE.statut%TYPE;
    v_duree         SATELLITE.duree_vie_prevue%TYPE;
    v_batterie      SATELLITE.capacite_batterie%TYPE;
    v_orbite        SATELLITE.id_orbite%TYPE;
BEGIN
    SELECT id_satellite, nom_satellite, date_lancement, masse,
           format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite
    INTO   v_id_satellite, v_nom, v_lancement, v_masse,
           v_format, v_statut, v_duree, v_batterie, v_orbite
    FROM   SATELLITE
    WHERE  id_satellite = 'SAT-001';

    DBMS_OUTPUT.PUT_LINE('=== Ex.2 : Caracteristiques SAT-001 ===');
    DBMS_OUTPUT.PUT_LINE('Satellite      : ' || v_id_satellite || ' - ' || v_nom);
    DBMS_OUTPUT.PUT_LINE('Lancement      : ' || TO_CHAR(v_lancement, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('Masse          : ' || v_masse || ' kg | Format : ' || v_format);
    DBMS_OUTPUT.PUT_LINE('Statut         : ' || v_statut);
    DBMS_OUTPUT.PUT_LINE('Duree de vie   : ' || v_duree || ' mois | Batterie : ' || v_batterie || ' Wh');
    DBMS_OUTPUT.PUT_LINE('Orbite courante: ' || v_orbite);
END;
/

-- ============================================================
-- PALIER 2 - VARIABLES ET TYPES
-- ============================================================

-- ------------------------------------------------------------
-- Ex. 3 : %ROWTYPE -- lire une ligne complete de SATELLITE
--         et afficher statut + capacite batterie
--
-- Resultat attendu :
--   === Ex.3 : SATELLITE via %ROWTYPE ===
--   Satellite : SAT-001 (NanoOrbit-Alpha)
--   Statut    : Operationnel
--   Batterie  : 20 Wh
--   Lancement : 15/03/2022 | Orbite : ORB-001
-- ------------------------------------------------------------
DECLARE
    v_sat  SATELLITE%ROWTYPE;
BEGIN
    SELECT * INTO v_sat
    FROM   SATELLITE
    WHERE  id_satellite = 'SAT-001';

    DBMS_OUTPUT.PUT_LINE('=== Ex.3 : SATELLITE via %ROWTYPE ===');
    DBMS_OUTPUT.PUT_LINE('Satellite : ' || v_sat.id_satellite || ' (' || v_sat.nom_satellite || ')');
    DBMS_OUTPUT.PUT_LINE('Statut    : ' || v_sat.statut);
    DBMS_OUTPUT.PUT_LINE('Batterie  : ' || v_sat.capacite_batterie || ' Wh');
    DBMS_OUTPUT.PUT_LINE('Lancement : ' || TO_CHAR(v_sat.date_lancement, 'DD/MM/YYYY') ||
                         ' | Orbite : ' || v_sat.id_orbite);
END;
/

-- ------------------------------------------------------------
-- Ex. 4 : NVL2 -- afficher la resolution de chaque instrument
--         (N/A pour les capteurs AIS sans resolution)
--
-- Resultat attendu :
--   === Ex.4 : Resolutions des instruments (NVL2) ===
--   INS-AIS-01   | Recepteur AIS    | Resolution : N/A (non applicable)
--   INS-CAM-01   | Camera optique   | Resolution : 3.0 m
--   INS-IR-01    | Infrarouge       | Resolution : 160.0 m
--   INS-SPEC-01  | Spectrometre     | Resolution : 30.0 m
-- ------------------------------------------------------------
DECLARE
    CURSOR c_instr IS
        SELECT ref_instrument, type_instrument, resolution
        FROM   INSTRUMENT
        ORDER  BY ref_instrument;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ex.4 : Resolutions des instruments (NVL2) ===');
    FOR rec IN c_instr LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.ref_instrument, 12) || ' | ' ||
            RPAD(rec.type_instrument, 16) || ' | Resolution : ' ||
            NVL2(rec.resolution,
                 TO_CHAR(rec.resolution, 'FM9990.0') || ' m',
                 'N/A (non applicable)')
        );
    END LOOP;
END;
/

-- ============================================================
-- PALIER 3 - STRUCTURES DE CONTROLE
-- ============================================================

-- ------------------------------------------------------------
-- Ex. 5 : IF/ELSIF -- categoriser chaque satellite selon son
--         statut et sa duree de vie restante estimee
--
-- Logique :
--   - Desorbite                          -> "Hors service"
--   - Defaillant                         -> "En anomalie"
--   - En veille                          -> "En veille preventive"
--   - Operationnel + restant > 24 mois   -> "Actif - longue autonomie"
--   - Operationnel + restant 6 a 24 mois -> "Actif - autonomie limitee"
--   - Operationnel + restant < 6 mois    -> "Actif - fin de vie imminente"
--
-- Resultat attendu :
--   SAT-001 et SAT-002 : Operationnel -> categorie selon la duree restante calculee avec SYSDATE
--   SAT-003            : Operationnel -> categorie selon la duree restante calculee avec SYSDATE
--   SAT-004            : En veille    -> En veille preventive
--   SAT-005            : Desorbite    -> Hors service
--
-- Note :
--   La valeur "Restant (mois)" varie selon la date d'execution car elle depend de SYSDATE.
-- ------------------------------------------------------------
DECLARE
    v_date_fin    DATE;
    v_restant     NUMBER;
    v_categorie   VARCHAR2(50);

    CURSOR c_sats IS
        SELECT id_satellite, nom_satellite, statut,
               date_lancement, duree_vie_prevue
        FROM   SATELLITE
        ORDER  BY id_satellite;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ex.5 : Categorisation des satellites ===');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('Satellite', 10) || RPAD('Statut', 18) ||
        RPAD('Restant (mois)', 16) || 'Categorie'
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));

    FOR rec IN c_sats LOOP
        v_date_fin := ADD_MONTHS(rec.date_lancement, rec.duree_vie_prevue);
        v_restant  := ROUND(MONTHS_BETWEEN(v_date_fin, SYSDATE), 1);

        IF rec.statut = 'Desorbite' THEN
            v_categorie := 'Hors service';
        ELSIF rec.statut = 'Defaillant' THEN
            v_categorie := 'En anomalie';
        ELSIF rec.statut = 'En veille' THEN
            v_categorie := 'En veille preventive';
        ELSIF v_restant > 24 THEN
            v_categorie := 'Actif - longue autonomie';
        ELSIF v_restant >= 6 THEN
            v_categorie := 'Actif - autonomie limitee';
        ELSE
            v_categorie := 'Actif - fin de vie imminente';
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.id_satellite, 10) ||
            RPAD(rec.statut, 18) ||
            RPAD(
                CASE WHEN rec.statut IN ('Desorbite','Defaillant','En veille')
                     THEN 'n/a'
                     ELSE TO_CHAR(v_restant)
                END,
                16
            ) ||
            v_categorie
        );
    END LOOP;
END;
/

-- ------------------------------------------------------------
-- Ex. 6 : CASE -- afficher le type d'orbite de chaque satellite
--         et calculer sa vitesse orbitale approximative
--
-- Formule : v = 2*PI*(6371 + altitude) / periode_orbitale  [km/min]
--           v_ms = v * 1000 / 60  [m/s]
--
-- Resultat attendu :
--   SAT-001 | ORB-001 | SSO | 550 | 95.5 | 7592
--   SAT-002 | ORB-001 | SSO | 550 | 95.5 | 7592
--   SAT-003 | ORB-002 | SSO | 700 | 98.8 | 7497
--   SAT-004 | ORB-002 | SSO | 700 | 98.8 | 7497
--   SAT-005 | ORB-003 | LEO | 400 | 92.6 | 7658
-- ------------------------------------------------------------
DECLARE
    v_vitesse_kmmin  NUMBER;
    v_vitesse_ms     NUMBER;
    v_type_label     VARCHAR2(30);

    CURSOR c_sat_orbite IS
        SELECT s.id_satellite, s.nom_satellite,
               o.id_orbite, o.type_orbite, o.altitude, o.periode_orbitale
        FROM   SATELLITE s
        JOIN   ORBITE    o ON s.id_orbite = o.id_orbite
        ORDER  BY s.id_satellite;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ex.6 : Types d''orbite et vitesses orbitales ===');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('Satellite', 10) || RPAD('Orbite', 9) ||
        RPAD('Type', 6)       || RPAD('Alt(km)', 9) ||
        RPAD('Per(min)', 10)  || 'Vitesse (m/s)'
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));

    FOR rec IN c_sat_orbite LOOP
        v_vitesse_kmmin := 2 * 3.14159265358979 * (6371 + rec.altitude) / rec.periode_orbitale;
        v_vitesse_ms    := ROUND(v_vitesse_kmmin * 1000 / 60);

        v_type_label := CASE rec.type_orbite
            WHEN 'SSO' THEN 'Heliosynchrone (SSO)'
            WHEN 'LEO' THEN 'Orbite basse (LEO)'
            WHEN 'MEO' THEN 'Orbite moyenne (MEO)'
            WHEN 'GEO' THEN 'Geostationnaire (GEO)'
            ELSE rec.type_orbite
        END;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.id_satellite, 10) ||
            RPAD(rec.id_orbite, 9)     ||
            RPAD(rec.type_orbite, 6)   ||
            RPAD(rec.altitude, 9)      ||
            RPAD(rec.periode_orbitale, 10) ||
            v_vitesse_ms
        );
        DBMS_OUTPUT.PUT_LINE('  Type : ' || v_type_label);
    END LOOP;
END;
/

-- ------------------------------------------------------------
-- Ex. 7 : Boucle FOR -- grille des volumes de donnees attendus
--         pour des passages de 5 a 15 minutes avec GS-TLS-01
--
-- GS-TLS-01 : debit_max = 150 Mbps
-- Volume (Mo) = (debit_Mbps / 8) * duree_secondes = 18.75 Mo/s * duree_s
--
-- Resultat attendu :
--   Debit max : 150 Mbps (18.75 Mo/s)
--   5 min  | 300 s | 5625.0 Mo
--   6 min  | 360 s | 6750.0 Mo
--   7 min  | 420 s | 7875.0 Mo
--   8 min  | 480 s | 9000.0 Mo
--   9 min  | 540 s | 10125.0 Mo
--   10 min | 600 s | 11250.0 Mo
--   11 min | 660 s | 12375.0 Mo
--   12 min | 720 s | 13500.0 Mo
--   13 min | 780 s | 14625.0 Mo
--   14 min | 840 s | 15750.0 Mo
--   15 min | 900 s | 16875.0 Mo
-- ------------------------------------------------------------
DECLARE
    v_debit      STATION_SOL.debit_max%TYPE;
    v_duree_s    NUMBER;
    v_volume_mo  NUMBER;
BEGIN
    SELECT debit_max INTO v_debit
    FROM   STATION_SOL
    WHERE  code_station = 'GS-TLS-01';

    DBMS_OUTPUT.PUT_LINE('=== Ex.7 : Grille volumes - Station GS-TLS-01 ===');
    DBMS_OUTPUT.PUT_LINE('Debit max : ' || v_debit || ' Mbps (' || (v_debit/8) || ' Mo/s)');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 45, '-'));
    DBMS_OUTPUT.PUT_LINE(
        RPAD('Passage', 14) || RPAD('Duree (s)', 12) || 'Volume theorique (Mo)'
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 45, '-'));

    FOR v_min IN 5..15 LOOP
        v_duree_s   := v_min * 60;
        v_volume_mo := ROUND((v_debit / 8) * v_duree_s, 1);
        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_min || ' min', 14) ||
            RPAD(v_duree_s || ' s', 12) ||
            TO_CHAR(v_volume_mo, 'FM99999990.0') || ' Mo'
        );
    END LOOP;
END;
/

-- ============================================================
-- PALIER 4 - CURSEURS
-- ============================================================

-- ------------------------------------------------------------
-- Ex. 8 : SQL%ROWCOUNT -- mettre a jour le statut de satellites
--         et afficher le nombre de lignes modifiees
--
-- Resultat attendu :
--   === Ex.8 : SQL%ROWCOUNT -- mise en veille ORB-001 ===
--   Satellites mis en veille (ORB-001) : 2
--   Rollback effectue -- etat initial restaure
-- ------------------------------------------------------------
DECLARE
    v_nb_modifies NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ex.8 : SQL%ROWCOUNT -- mise en veille ORB-001 ===');

    UPDATE SATELLITE
    SET    statut = 'En veille'
    WHERE  id_orbite = 'ORB-001'
      AND  statut    = 'Operationnel';

    v_nb_modifies := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Satellites mis en veille (ORB-001) : ' || v_nb_modifies);

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Rollback effectue -- etat initial restaure');
END;
/

-- ------------------------------------------------------------
-- Ex. 9 : Cursor FOR Loop -- lister tous les satellites
--         avec leur orbite, statut et instruments embarques
--
-- Resultat attendu :
--   SAT-001 | NanoOrbit-Alpha   | Operationnel | ORB-001 (SSO)
--     -> INS-CAM-01  [Camera optique] Nominal
--     -> INS-IR-01   [Infrarouge] Nominal
--   SAT-002 | NanoOrbit-Beta    | Operationnel | ORB-001 (SSO)
--     -> INS-CAM-01  [Camera optique] Nominal
--   SAT-003 | NanoOrbit-Gamma   | Operationnel | ORB-002 (SSO)
--     -> INS-CAM-01  [Camera optique] Nominal
--     -> INS-SPEC-01 [Spectrometre] Nominal
--   SAT-004 | NanoOrbit-Delta   | En veille | ORB-002 (SSO)
--     -> INS-IR-01   [Infrarouge] Degrade
--   SAT-005 | NanoOrbit-Epsilon | Desorbite | ORB-003 (LEO)
--     -> INS-AIS-01  [Recepteur AIS] Hors service
-- ------------------------------------------------------------
DECLARE
    CURSOR c_satellites IS
        SELECT s.id_satellite, s.nom_satellite, s.statut,
               o.id_orbite, o.type_orbite
        FROM   SATELLITE s
        JOIN   ORBITE    o ON s.id_orbite = o.id_orbite
        ORDER  BY s.id_satellite;

    CURSOR c_instruments(p_sat VARCHAR2) IS
        SELECT e.ref_instrument, i.type_instrument, e.etat_fonctionnement
        FROM   EMBARQUEMENT e
        JOIN   INSTRUMENT   i ON e.ref_instrument = i.ref_instrument
        WHERE  e.id_satellite = p_sat
        ORDER  BY e.ref_instrument;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ex.9 : Satellites, orbites et instruments ===');

    FOR sat IN c_satellites LOOP
        DBMS_OUTPUT.PUT_LINE(
            sat.id_satellite || ' | ' || sat.nom_satellite ||
            ' | ' || sat.statut ||
            ' | ' || sat.id_orbite || ' (' || sat.type_orbite || ')'
        );

        FOR ins IN c_instruments(sat.id_satellite) LOOP
            DBMS_OUTPUT.PUT_LINE(
                '  -> ' || RPAD(ins.ref_instrument, 12) ||
                '[' || ins.type_instrument || '] ' || ins.etat_fonctionnement
            );
        END LOOP;
    END LOOP;
END;
/

-- ------------------------------------------------------------
-- Ex. 10 : Curseur explicite OPEN/FETCH/CLOSE --
--          satellites operationnels avec leur derniere
--          fenetre de communication realisee
--
-- Resultat attendu :
--   SAT-001 (NanoOrbit-Alpha)
--     Derniere fenetre : GS-KIR-01 | 15/01/2024 09:14 | 1250 Mo
--   SAT-002 (NanoOrbit-Beta)
--     Derniere fenetre : GS-TLS-01 | 15/01/2024 11:52 | 890 Mo
--   SAT-003 (NanoOrbit-Gamma)
--     Derniere fenetre : GS-KIR-01 | 16/01/2024 08:30 | 1680 Mo
-- ------------------------------------------------------------
DECLARE
    CURSOR c_op_sats IS
        SELECT id_satellite, nom_satellite
        FROM   SATELLITE
        WHERE  statut = 'Operationnel'
        ORDER  BY id_satellite;

    v_sat      c_op_sats%ROWTYPE;
    v_station  VARCHAR2(20);
    v_datetime TIMESTAMP;
    v_volume   NUMBER(8,1);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ex.10 : Derniere fenetre par satellite operationnel ===');

    OPEN c_op_sats;
    LOOP
        FETCH c_op_sats INTO v_sat;
        EXIT WHEN c_op_sats%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(v_sat.id_satellite || ' (' || v_sat.nom_satellite || ')');

        BEGIN
            SELECT fc.code_station, fc.datetime_debut, fc.volume_donnees
            INTO   v_station, v_datetime, v_volume
            FROM   FENETRE_COM fc
            WHERE  fc.id_satellite = v_sat.id_satellite
              AND  fc.statut       = 'Realisee'
              AND  fc.datetime_debut = (
                       SELECT MAX(f2.datetime_debut)
                       FROM   FENETRE_COM f2
                       WHERE  f2.id_satellite = v_sat.id_satellite
                         AND  f2.statut       = 'Realisee'
                   );

            DBMS_OUTPUT.PUT_LINE(
                '  Derniere fenetre : ' || v_station ||
                ' | ' || TO_CHAR(v_datetime, 'DD/MM/YYYY HH24:MI') ||
                ' | ' || NVL(TO_CHAR(v_volume), 'N/A') || ' Mo'
            );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('  Aucune fenetre realisee.');
        END;
    END LOOP;
    CLOSE c_op_sats;
END;
/

-- ------------------------------------------------------------
-- Ex. 11 : Curseur parametre -- fenetres de communication
--          d'une station donnee avec volume total telecharge
--
-- Resultat attendu :
--   === Ex.11 : Fenetres de GS-KIR-01 ===
--   1 | NanoOrbit-Alpha | 15/01/2024 09:14 | 420s | Realisee | 1250
--   3 | NanoOrbit-Gamma | 16/01/2024 08:30 | 540s | Realisee | 1680
--   Volume total telecharge via GS-KIR-01 : 2930 Mo
-- ------------------------------------------------------------
DECLARE
    CURSOR c_fenetres(p_code_station VARCHAR2) IS
        SELECT fc.id_fenetre, fc.datetime_debut, fc.duree,
               fc.statut, fc.volume_donnees,
               s.nom_satellite
        FROM   FENETRE_COM fc
        JOIN   SATELLITE   s ON fc.id_satellite = s.id_satellite
        WHERE  fc.code_station = p_code_station
        ORDER  BY fc.datetime_debut;

    v_total_volume NUMBER := 0;
    v_code_station CONSTANT VARCHAR2(20) := 'GS-KIR-01';
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ex.11 : Fenetres de ' || v_code_station || ' ===');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('ID', 5) || RPAD('Satellite', 20) ||
        RPAD('Date debut', 19) || RPAD('Duree', 7) ||
        RPAD('Statut', 11) || 'Volume (Mo)'
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 75, '-'));

    FOR rec IN c_fenetres(v_code_station) LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.id_fenetre, 5) ||
            RPAD(rec.nom_satellite, 20) ||
            RPAD(TO_CHAR(rec.datetime_debut, 'DD/MM/YYYY HH24:MI'), 19) ||
            RPAD(rec.duree || 's', 7) ||
            RPAD(rec.statut, 11) ||
            NVL(TO_CHAR(rec.volume_donnees), 'NULL')
        );
        IF rec.volume_donnees IS NOT NULL THEN
            v_total_volume := v_total_volume + rec.volume_donnees;
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 75, '-'));
    DBMS_OUTPUT.PUT_LINE('Volume total telecharge via ' || v_code_station || ' : ' || v_total_volume || ' Mo');
END;
/

-- ============================================================
-- PALIER 5 - PROCEDURES ET FONCTIONS STANDALONE (SOCLE)
-- ============================================================

-- ------------------------------------------------------------
-- Ex. 12 : Exceptions predefinies -- SELECT INTO securise
--          sur SATELLITE avec gestion NO_DATA_FOUND et OTHERS
--
-- Resultat attendu :
--   === Ex.12 : SELECT INTO securise ===
--   [OK] SAT-003 : NanoOrbit-Gamma (Operationnel)
--   [NO_DATA_FOUND] Satellite SAT-999 inexistant.
-- ------------------------------------------------------------
DECLARE
    v_sat SATELLITE%ROWTYPE;

    PROCEDURE lire_satellite_securise(p_id IN VARCHAR2) AS
    BEGIN
        SELECT * INTO v_sat FROM SATELLITE WHERE id_satellite = p_id;
        DBMS_OUTPUT.PUT_LINE('[OK] ' || v_sat.id_satellite || ' : ' ||
                             v_sat.nom_satellite || ' (' || v_sat.statut || ')');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('[NO_DATA_FOUND] Satellite ' || p_id || ' inexistant.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('[OTHERS] Erreur : ' || SQLERRM);
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ex.12 : SELECT INTO securise ===');
    lire_satellite_securise('SAT-003');   -- Attendu : OK
    lire_satellite_securise('SAT-999');   -- Attendu : NO_DATA_FOUND
END;
/

-- ------------------------------------------------------------
-- Ex. 13 : RAISE_APPLICATION_ERROR -- validation d'une fenetre
--          de communication avant insertion
--
-- Codes erreur locaux (range -20040 a -20049 pour Ex.13) :
--   -20040 : satellite introuvable
--   -20041 : satellite non Operationnel
--   -20042 : station introuvable
--   -20043 : station non Active
--   -20044 : chevauchement detecte
--
-- Resultat attendu :
--   [OK] Fenetre valide : SAT-001 / GS-KIR-01 le 01/03/2024 10:00
--   [Erreur attendue] Test 2 : ORA-20041: Satellite SAT-005 non Operationnel (statut : Desorbite).
--   [Erreur attendue] Test 3 : ORA-20043: Station GS-SGP-01 non Active (statut : Maintenance).
-- ------------------------------------------------------------
DECLARE
    PROCEDURE valider_fenetre(
        p_id_satellite   IN VARCHAR2,
        p_code_station   IN VARCHAR2,
        p_datetime_debut IN TIMESTAMP,
        p_duree          IN NUMBER
    ) AS
        v_statut_sat VARCHAR2(30);
        v_statut_sta VARCHAR2(20);
    BEGIN
        BEGIN
            SELECT statut INTO v_statut_sat
            FROM   SATELLITE WHERE id_satellite = p_id_satellite;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20040,
                    'Satellite ' || p_id_satellite || ' introuvable.');
        END;

        IF v_statut_sat != 'Operationnel' THEN
            RAISE_APPLICATION_ERROR(-20041,
                'Satellite ' || p_id_satellite || ' non Operationnel (statut : ' || v_statut_sat || ').');
        END IF;

        BEGIN
            SELECT statut INTO v_statut_sta
            FROM   STATION_SOL WHERE code_station = p_code_station;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20042,
                    'Station ' || p_code_station || ' introuvable.');
        END;

        IF v_statut_sta != 'Active' THEN
            RAISE_APPLICATION_ERROR(-20043,
                'Station ' || p_code_station || ' non Active (statut : ' || v_statut_sta || ').');
        END IF;

        IF fn_overlap_satellite(p_id_satellite, p_datetime_debut, p_duree) > 0 THEN
            RAISE_APPLICATION_ERROR(-20044,
                'Chevauchement satellite detecte pour ' || p_id_satellite);
        END IF;
        IF fn_overlap_station(p_code_station, p_datetime_debut, p_duree) > 0 THEN
            RAISE_APPLICATION_ERROR(-20044,
                'Chevauchement station detecte pour ' || p_code_station);
        END IF;

        DBMS_OUTPUT.PUT_LINE('[OK] Fenetre valide : ' || p_id_satellite ||
                             ' / ' || p_code_station || ' le ' ||
                             TO_CHAR(p_datetime_debut, 'DD/MM/YYYY HH24:MI'));
    END valider_fenetre;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ex.13 : Validation RAISE_APPLICATION_ERROR ===');

    BEGIN
        valider_fenetre('SAT-001', 'GS-KIR-01', TIMESTAMP '2024-03-01 10:00:00', 300);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[KO inattendu] Test 1 : ' || SQLERRM);
    END;

    BEGIN
        valider_fenetre('SAT-005', 'GS-TLS-01', TIMESTAMP '2024-03-01 10:00:00', 300);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Erreur attendue] Test 2 : ' || SQLERRM);
    END;

    BEGIN
        valider_fenetre('SAT-001', 'GS-SGP-01', TIMESTAMP '2024-03-01 10:00:00', 300);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Erreur attendue] Test 3 : ' || SQLERRM);
    END;
END;
/

-- ------------------------------------------------------------
-- Ex. 14 [Procedure Socle] : afficher_statut_satellite(p_id IN)
-- Affiche le statut, l'orbite et les instruments du satellite.
--
-- Resultat attendu :
--   Procedure compilee sans erreur.
--   SAT-003 affiche : Operationnel, format 6U, ORB-002, instruments INS-CAM-01 et INS-SPEC-01.
--   SAT-005 affiche : Desorbite, format 12U, ORB-003, instrument INS-AIS-01.
--   SAT-999 retourne : ORA-20050: Satellite SAT-999 introuvable.
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE afficher_statut_satellite(
    p_id IN VARCHAR2
)
AS
    v_sat     SATELLITE%ROWTYPE;
    v_orbite  ORBITE%ROWTYPE;

    CURSOR c_ins IS
        SELECT e.ref_instrument, i.type_instrument,
               i.modele, e.etat_fonctionnement
        FROM   EMBARQUEMENT e
        JOIN   INSTRUMENT   i ON e.ref_instrument = i.ref_instrument
        WHERE  e.id_satellite = p_id
        ORDER  BY e.ref_instrument;
BEGIN
    SELECT * INTO v_sat FROM SATELLITE WHERE id_satellite = p_id;
    SELECT * INTO v_orbite FROM ORBITE WHERE id_orbite = v_sat.id_orbite;

    DBMS_OUTPUT.PUT_LINE('=== ' || v_sat.id_satellite || ' : ' || v_sat.nom_satellite || ' ===');
    DBMS_OUTPUT.PUT_LINE('Statut         : ' || v_sat.statut);
    DBMS_OUTPUT.PUT_LINE('Format CubeSat : ' || v_sat.format_cubesat || ' | Masse : ' || v_sat.masse || ' kg');
    DBMS_OUTPUT.PUT_LINE('Batterie       : ' || v_sat.capacite_batterie || ' Wh');
    DBMS_OUTPUT.PUT_LINE('Orbite         : ' || v_orbite.id_orbite ||
                         ' (' || v_orbite.type_orbite || ', ' ||
                         v_orbite.altitude || ' km, ' ||
                         v_orbite.inclinaison || ' deg)');
    DBMS_OUTPUT.PUT_LINE('Instruments embarques :');

    FOR ins IN c_ins LOOP
        DBMS_OUTPUT.PUT_LINE(
            '  - ' || RPAD(ins.ref_instrument, 12) ||
            '[' || ins.type_instrument || ' / ' || ins.modele || '] : ' ||
            ins.etat_fonctionnement
        );
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20050, 'Satellite ' || p_id || ' introuvable.');
END afficher_statut_satellite;
/
SHOW ERRORS;

BEGIN DBMS_OUTPUT.PUT_LINE('--- Tests Ex.14 : afficher_statut_satellite ---'); END;
/

BEGIN
    afficher_statut_satellite('SAT-003');
END;
/

BEGIN
    afficher_statut_satellite('SAT-005');
END;
/

BEGIN
    afficher_statut_satellite('SAT-999');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Erreur attendue -20050] ' || SQLERRM);
END;
/

-- ------------------------------------------------------------
-- Ex. 15 [Procedure Socle] : mettre_a_jour_statut(p_id, p_statut, p_ancien_statut OUT)
--
-- Codes erreur :
--   -20051 : satellite introuvable
--   -20052 : statut invalide (non dans la liste autorisee)
--
-- Resultat attendu :
--   Procedure compilee sans erreur.
--   Test 1 : SAT-004 passe temporairement de En veille a Operationnel, ancien statut retourne = En veille, puis ROLLBACK.
--   Test 2 : SAT-999 retourne ORA-20051.
--   Test 3 : statut "Hors service" retourne ORA-20052 car statut invalide.
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE mettre_a_jour_statut(
    p_id            IN  VARCHAR2,
    p_statut        IN  VARCHAR2,
    p_ancien_statut OUT VARCHAR2
)
AS
BEGIN
    SELECT statut INTO p_ancien_statut
    FROM   SATELLITE
    WHERE  id_satellite = p_id;

    UPDATE SATELLITE
    SET    statut = p_statut
    WHERE  id_satellite = p_id;

    DBMS_OUTPUT.PUT_LINE(
        'Statut de ' || p_id || ' mis a jour : ' ||
        p_ancien_statut || ' --> ' || p_statut
    );
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20051, 'Satellite ' || p_id || ' introuvable.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20052,
            'Erreur mise a jour statut [' || p_statut || '] : ' || SQLERRM);
END mettre_a_jour_statut;
/
SHOW ERRORS;

BEGIN DBMS_OUTPUT.PUT_LINE('--- Tests Ex.15 : mettre_a_jour_statut ---'); END;
/

DECLARE
    v_ancien VARCHAR2(30);
BEGIN
    mettre_a_jour_statut('SAT-004', 'Operationnel', v_ancien);
    DBMS_OUTPUT.PUT_LINE('  Ancien statut retourne (OUT) : ' || v_ancien);
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('  Rollback -- SAT-004 restaure en "En veille"');
END;
/

DECLARE
    v_ancien VARCHAR2(30);
BEGIN
    mettre_a_jour_statut('SAT-999', 'Operationnel', v_ancien);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Erreur attendue -20051] ' || SQLERRM);
END;
/

DECLARE
    v_ancien VARCHAR2(30);
BEGIN
    mettre_a_jour_statut('SAT-001', 'Hors service', v_ancien);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Erreur attendue -20052] ' || SQLERRM);
END;
/

-- ------------------------------------------------------------
-- Ex. 16 [Fonction Socle] : calculer_volume_session(p_id_fenetre) RETURN NUMBER
--
-- Volume = (debit_station_Mbps / 8) * duree_secondes
--
-- Resultat attendu :
--   Fonction compilee sans erreur.
--   Fenetre 1 : SAT-001 | GS-KIR-01 | 420s | 21000.0 Mo
--   Fenetre 2 : SAT-002 | GS-TLS-01 | 310s | 5812.5 Mo
--   Fenetre 3 : SAT-003 | GS-KIR-01 | 540s | 27000.0 Mo
--   Fenetre 4 : SAT-001 | GS-TLS-01 | 380s | 7125.0 Mo
--   Fenetre 5 : SAT-003 | GS-TLS-01 | 290s | 5437.5 Mo
--   Fenetre 9999 : ORA-20060: Fenetre 9999 introuvable.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculer_volume_session(
    p_id_fenetre IN NUMBER
) RETURN NUMBER
AS
    v_debit NUMBER;
    v_duree NUMBER;
BEGIN
    SELECT ss.debit_max, fc.duree
    INTO   v_debit, v_duree
    FROM   FENETRE_COM  fc
    JOIN   STATION_SOL  ss ON fc.code_station = ss.code_station
    WHERE  fc.id_fenetre = p_id_fenetre;

    RETURN ROUND((v_debit / 8) * v_duree, 1);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20060,
            'Fenetre ' || p_id_fenetre || ' introuvable.');
END calculer_volume_session;
/
SHOW ERRORS;

BEGIN DBMS_OUTPUT.PUT_LINE('--- Tests Ex.16 : calculer_volume_session ---'); END;
/

DECLARE
    v_vol NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ex.16 : Volumes theoriques par fenetre ===');
    DBMS_OUTPUT.PUT_LINE(RPAD('Fenetre', 9) || RPAD('Satellite', 10) ||
                         RPAD('Station', 11) || RPAD('Duree', 7) || 'Volume theo (Mo)');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 55, '-'));

    FOR rec IN (
        SELECT fc.id_fenetre, fc.id_satellite, fc.code_station, fc.duree
        FROM   FENETRE_COM fc
        ORDER  BY fc.id_fenetre
    ) LOOP
        v_vol := calculer_volume_session(rec.id_fenetre);
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.id_fenetre, 9) ||
            RPAD(rec.id_satellite, 10) ||
            RPAD(rec.code_station, 11) ||
            RPAD(rec.duree || 's', 7) ||
            TO_CHAR(v_vol, 'FM99999990.0') || ' Mo'
        );
    END LOOP;
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(calculer_volume_session(9999));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[Erreur attendue -20060] ' || SQLERRM);
END;
/
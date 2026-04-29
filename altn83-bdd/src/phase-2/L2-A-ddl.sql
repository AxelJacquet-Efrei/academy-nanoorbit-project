ALTER SESSION SET CURRENT_SCHEMA = ACADEMY_NANOORBIT_PROJECT;
DROP TABLE IF EXISTS PARTICIPATION       CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS FENETRE_COM         CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS MISSION             CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS AFFECTATION_STATION CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS STATION_SOL         CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS CENTRE_CONTROLE     CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS EMBARQUEMENT        CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS INSTRUMENT          CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS HISTORIQUE_STATUT   CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS SATELLITE           CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS ORBITE              CASCADE CONSTRAINTS;

-- ============================================================
-- 1. ORBITE -- Referentiel des plans orbitaux
--    Dependances : aucune FK sortante
--    RG-O01, RG-O02, RG-O03
-- ============================================================
CREATE TABLE ORBITE (
    id_orbite        VARCHAR2(20)   NOT NULL,
    type_orbite      VARCHAR2(10)   NOT NULL,
    altitude         NUMBER(5)      NOT NULL,
    inclinaison      NUMBER(5,2)    NOT NULL,
    periode_orbitale NUMBER(6,2)    NOT NULL,
    excentricite     NUMBER(6,4)    NOT NULL,
    zone_couverture  VARCHAR2(200)  NOT NULL,
    CONSTRAINT pk_orbite           PRIMARY KEY (id_orbite),
    CONSTRAINT ck_orbite_type      CHECK (type_orbite IN ('LEO','MEO','SSO','GEO')),
    CONSTRAINT uq_orbite_alt_incl  UNIQUE (altitude, inclinaison)
);

COMMENT ON TABLE  ORBITE              IS 'Referentiel des plans orbitaux -- RG-O01';
COMMENT ON COLUMN ORBITE.id_orbite        IS 'PK alphanumerique (ex : ORB-001) -- variante justifiee vs NUMBER AI du CDC';
COMMENT ON COLUMN ORBITE.altitude         IS 'Altitude nominale en km au-dessus du sol';
COMMENT ON COLUMN ORBITE.inclinaison      IS 'Angle du plan orbital par rapport a lequateur (degres)';
COMMENT ON COLUMN ORBITE.excentricite     IS '0 = orbite circulaire, 1 = elliptique extreme';
COMMENT ON COLUMN ORBITE.zone_couverture  IS 'Description geographique de la zone surveillee';

-- ============================================================
-- 2. SATELLITE -- Parc de CubeSats
--    Dependances : ORBITE
--    RG-S01, RG-S02, RG-S06
-- ============================================================
CREATE TABLE SATELLITE (
    id_satellite      VARCHAR2(20)   NOT NULL,
    nom_satellite     VARCHAR2(100)  NOT NULL,
    date_lancement    DATE           NOT NULL,
    masse             NUMBER(5,2)    NOT NULL,
    format_cubesat    VARCHAR2(5)    NOT NULL,
    statut            VARCHAR2(30)   NOT NULL,
    duree_vie_prevue  NUMBER(4)      NOT NULL,
    capacite_batterie NUMBER(6,1)    NOT NULL,
    id_orbite         VARCHAR2(20)   NOT NULL,
    CONSTRAINT pk_satellite        PRIMARY KEY (id_satellite),
    CONSTRAINT ck_sat_format       CHECK (format_cubesat IN ('1U','3U','6U','12U')),
    CONSTRAINT ck_sat_statut       CHECK (statut IN ('Operationnel','En veille','Defaillant','Desorbite')),
    CONSTRAINT fk_sat_orbite       FOREIGN KEY (id_orbite) REFERENCES ORBITE(id_orbite)
);

COMMENT ON TABLE  SATELLITE               IS 'Parc de CubeSats NanoOrbit (5 lignes initiales dont SAT-005 Desorbite)';
COMMENT ON COLUMN SATELLITE.id_satellite      IS 'PK immutable apres mise en orbite -- RG-S01';
COMMENT ON COLUMN SATELLITE.format_cubesat    IS 'Q4 : VARCHAR2(5) + CHECK car pas dENUM natif Oracle';
COMMENT ON COLUMN SATELLITE.statut            IS 'RG-S06 : Desorbite bloque pour nouvelles fenetres et missions (triggers T1, T4)';
COMMENT ON COLUMN SATELLITE.id_orbite         IS 'Orbite courante -- RG-S02 : on conserve uniquement lorbite courante';

-- ============================================================
-- 3. HISTORIQUE_STATUT -- Table d'audit des changements de statut
--    Dependances : SATELLITE
--    Creee apres SATELLITE, avant EMBARQUEMENT (specification CDC Phase 2 section 2.4)
--    Alimentee EXCLUSIVEMENT par le trigger T5 (trg_historique_statut)
--    Aucun INSERT manuel -- 0 ligne initiale
-- ============================================================
CREATE TABLE HISTORIQUE_STATUT (
    id_historique   NUMBER          GENERATED ALWAYS AS IDENTITY,
    id_satellite    VARCHAR2(20)    NOT NULL,
    ancien_statut   VARCHAR2(30)    NOT NULL,
    nouveau_statut  VARCHAR2(30)    NOT NULL,
    date_changement TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    motif           VARCHAR2(200),
    CONSTRAINT pk_historique       PRIMARY KEY (id_historique),
    CONSTRAINT fk_hist_satellite   FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite)
);

COMMENT ON TABLE  HISTORIQUE_STATUT           IS 'Audit des changements de statut satellite -- alimente par trigger T5 uniquement';
COMMENT ON COLUMN HISTORIQUE_STATUT.id_historique   IS 'PK auto-incrementee (GENERATED ALWAYS AS IDENTITY)';
COMMENT ON COLUMN HISTORIQUE_STATUT.date_changement IS 'DEFAULT SYSTIMESTAMP -- horodatage automatique';
COMMENT ON COLUMN HISTORIQUE_STATUT.motif           IS 'Raison du changement -- nullable';

-- ============================================================
-- 4. INSTRUMENT -- Catalogue des instruments embarques
--    Dependances : aucune FK sortante
--    RG-I01
-- ============================================================
CREATE TABLE INSTRUMENT (
    ref_instrument  VARCHAR2(20)   NOT NULL,
    type_instrument VARCHAR2(50)   NOT NULL,
    modele          VARCHAR2(100)  NOT NULL,
    resolution      NUMBER(6,1),             
    consommation    NUMBER(5,2)    NOT NULL,
    masse           NUMBER(5,3)    NOT NULL,
    CONSTRAINT pk_instrument       PRIMARY KEY (ref_instrument)
);

COMMENT ON TABLE  INSTRUMENT              IS 'Catalogue global des instruments embarques -- independant de leur affectation (RG-I01)';
COMMENT ON COLUMN INSTRUMENT.resolution       IS 'Nullable : NULL si non applicable (ex : recepteur AIS -- cf. INS-AIS-01)';

-- ============================================================
-- 5. EMBARQUEMENT -- Instruments montes sur satellites
--    Dependances : SATELLITE, INSTRUMENT
--    PK composite -- E6
--    Entite-association porteuse (RG-S04)
--    RG-S03, RG-S04, RG-I02, RG-I03
-- ============================================================
CREATE TABLE EMBARQUEMENT (
    id_satellite        VARCHAR2(20)  NOT NULL,
    ref_instrument      VARCHAR2(20)  NOT NULL,
    date_integration    DATE          NOT NULL,
    etat_fonctionnement VARCHAR2(20)  NOT NULL,
    CONSTRAINT pk_embarquement     PRIMARY KEY (id_satellite, ref_instrument),
    CONSTRAINT ck_emb_etat         CHECK (etat_fonctionnement IN ('Nominal','Degrade','Hors service')),
    CONSTRAINT fk_emb_satellite    FOREIGN KEY (id_satellite)   REFERENCES SATELLITE(id_satellite),
    CONSTRAINT fk_emb_instrument   FOREIGN KEY (ref_instrument) REFERENCES INSTRUMENT(ref_instrument)
);

COMMENT ON TABLE  EMBARQUEMENT                    IS 'Entite-association SATELLITE<->INSTRUMENT (RG-S03, RG-S04, RG-I02, RG-I03)';
COMMENT ON COLUMN EMBARQUEMENT.etat_fonctionnement    IS 'Attribut propre au couple (satellite, instrument) -- RG-S04';
COMMENT ON COLUMN EMBARQUEMENT.date_integration       IS 'Date de montage physique sur le satellite -- RG-S04';

-- ============================================================
-- 6. CENTRE_CONTROLE -- Centres d'operation NanoOrbit
--    Dependances : aucune FK sortante
--    2 lignes initiales (CTR-003 Singapour ajoute en Phase 4 -- MERGE INTO Ex.16)
-- ============================================================
CREATE TABLE CENTRE_CONTROLE (
    id_centre      VARCHAR2(20)   NOT NULL,
    nom_centre     VARCHAR2(100)  NOT NULL,
    ville          VARCHAR2(50)   NOT NULL,
    region_geo     VARCHAR2(50)   NOT NULL,
    fuseau_horaire VARCHAR2(50)   NOT NULL,
    statut         VARCHAR2(20)   NOT NULL,
    CONSTRAINT pk_centre           PRIMARY KEY (id_centre),
    CONSTRAINT ck_centre_statut    CHECK (statut IN ('Actif','Inactif'))
);

COMMENT ON TABLE  CENTRE_CONTROLE         IS 'Centres doperation NanoOrbit (2 lignes initiales, CTR-003 ajoute Phase 4)';
COMMENT ON COLUMN CENTRE_CONTROLE.id_centre   IS 'PK alphanumerique (ex : CTR-001) -- variante justifiee vs NUMBER AI du CDC';
COMMENT ON COLUMN CENTRE_CONTROLE.fuseau_horaire IS 'Identifiant IANA (ex : Europe/Paris)';

-- ============================================================
-- 7. STATION_SOL -- Stations d'antenne mondiales
--    Dependances : aucune FK sortante
--    RG-G01, RG-G02, RG-G03
-- ============================================================
CREATE TABLE STATION_SOL (
    code_station     VARCHAR2(20)   NOT NULL,
    nom_station      VARCHAR2(100)  NOT NULL,
    latitude         NUMBER(9,6)    NOT NULL,
    longitude        NUMBER(9,6)    NOT NULL,
    diametre_antenne NUMBER(4,1)    NOT NULL,
    bande_frequence  VARCHAR2(10)   NOT NULL,
    debit_max        NUMBER(6,1)    NOT NULL,
    statut           VARCHAR2(20)   NOT NULL,
    CONSTRAINT pk_station          PRIMARY KEY (code_station),
    CONSTRAINT ck_station_statut   CHECK (statut IN ('Active','Maintenance','Inactive'))
);

COMMENT ON TABLE  STATION_SOL             IS 'Stations dantenne mondiales -- RG-G01, RG-G02, RG-G03';
COMMENT ON COLUMN STATION_SOL.latitude        IS 'Coordonnee Nord/Sud -- NOT NULL : RG-G01';
COMMENT ON COLUMN STATION_SOL.longitude       IS 'Coordonnee Est/Ouest -- NOT NULL : RG-G01';
COMMENT ON COLUMN STATION_SOL.statut          IS 'RG-G03 : station Maintenance bloquee pour nouvelles fenetres (trigger T1)';

-- ============================================================
-- 8. AFFECTATION_STATION -- Rattachement station <-> centre
--    Dependances : CENTRE_CONTROLE, STATION_SOL
--    PK composite
--    RG-G04
-- ============================================================
CREATE TABLE AFFECTATION_STATION (
    id_centre        VARCHAR2(20)  NOT NULL,
    code_station     VARCHAR2(20)  NOT NULL,
    date_affectation DATE          NOT NULL,
    CONSTRAINT pk_affectation      PRIMARY KEY (id_centre, code_station),
    CONSTRAINT fk_aff_centre       FOREIGN KEY (id_centre)    REFERENCES CENTRE_CONTROLE(id_centre),
    CONSTRAINT fk_aff_station      FOREIGN KEY (code_station) REFERENCES STATION_SOL(code_station)
);

COMMENT ON TABLE AFFECTATION_STATION IS 'Rattachement Station<->Centre de controle -- RG-G04';

-- ============================================================
-- 9. MISSION -- Missions scientifiques
--    Dependances : aucune FK sortante
--    RG-M01, RG-M02, RG-M04
-- ============================================================
CREATE TABLE MISSION (
    id_mission     VARCHAR2(20)   NOT NULL,
    nom_mission    VARCHAR2(100)  NOT NULL,
    objectif       VARCHAR2(500)  NOT NULL,
    zone_geo_cible VARCHAR2(200)  NOT NULL,
    date_debut     DATE           NOT NULL,
    date_fin       DATE,
    statut_mission VARCHAR2(20)   NOT NULL,
    CONSTRAINT pk_mission          PRIMARY KEY (id_mission),
    CONSTRAINT ck_mission_statut   CHECK (statut_mission IN ('Active','Terminee'))
);

COMMENT ON TABLE  MISSION               IS 'Missions scientifiques NanoOrbit -- RG-M01, RG-M02';
COMMENT ON COLUMN MISSION.date_debut        IS 'NOT NULL obligatoire -- RG-M01';
COMMENT ON COLUMN MISSION.date_fin          IS 'Nullable : NULL si mission a duree indeterminee -- RG-M01 (E1)';
COMMENT ON COLUMN MISSION.statut_mission    IS 'RG-M04 : mission Terminee bloquee pour nouveaux satellites (trigger T4)';

-- ============================================================
-- 10. FENETRE_COM -- Creneaux de communication
--     Dependances : SATELLITE, STATION_SOL
--     PK propre (plusieurs fenetres par couple satellite+station)
--     RG-F01 a RG-F05
-- ============================================================
CREATE TABLE FENETRE_COM (
    id_fenetre     NUMBER         GENERATED ALWAYS AS IDENTITY,
    datetime_debut TIMESTAMP      NOT NULL,
    duree          NUMBER(4)      NOT NULL,
    elevation_max  NUMBER(5,2)    NOT NULL,
    volume_donnees NUMBER(8,1),              
    statut         VARCHAR2(20)   NOT NULL,
    id_satellite   VARCHAR2(20)   NOT NULL, 
    code_station   VARCHAR2(20)   NOT NULL,
    CONSTRAINT pk_fenetre          PRIMARY KEY (id_fenetre),
    CONSTRAINT ck_fenetre_duree    CHECK (duree BETWEEN 1 AND 900),
    CONSTRAINT ck_fenetre_statut   CHECK (statut IN ('Planifiee','Realisee')),
    CONSTRAINT fk_fen_satellite    FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite),
    CONSTRAINT fk_fen_station      FOREIGN KEY (code_station) REFERENCES STATION_SOL(code_station)
);

COMMENT ON TABLE  FENETRE_COM             IS 'Creneaux de communication satellite<->station -- RG-F01 a RG-F05';
COMMENT ON COLUMN FENETRE_COM.id_fenetre      IS 'PK auto-incrementee (GENERATED ALWAYS AS IDENTITY) -- plusieurs fenetres par couple sat/sta';
COMMENT ON COLUMN FENETRE_COM.duree           IS 'Duree en secondes -- CHECK BETWEEN 1 AND 900 (RG-F04, E4)';
COMMENT ON COLUMN FENETRE_COM.volume_donnees  IS 'Nullable : NULL si statut Planifiee (RG-F05) -- enforce par trigger T3';

-- ============================================================
-- 11. PARTICIPATION -- Roles des satellites dans les missions
--     Dependances : SATELLITE, MISSION
--     PK composite -- E6
--     Entite-association porteuse (RG-M03)
--     RG-M02, RG-M03, RG-M04
-- ============================================================
CREATE TABLE PARTICIPATION (
    id_satellite   VARCHAR2(20)   NOT NULL,
    id_mission     VARCHAR2(20)   NOT NULL,
    role_satellite VARCHAR2(100)  NOT NULL,
    CONSTRAINT pk_participation    PRIMARY KEY (id_satellite, id_mission),
    CONSTRAINT fk_part_satellite   FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite),
    CONSTRAINT fk_part_mission     FOREIGN KEY (id_mission)   REFERENCES MISSION(id_mission)
);

COMMENT ON TABLE  PARTICIPATION           IS 'Entite-association SATELLITE<->MISSION -- RG-M02, RG-M03, RG-M04';
COMMENT ON COLUMN PARTICIPATION.role_satellite IS 'Role du satellite dans la mission (ex : Imageur principal) -- RG-M03';


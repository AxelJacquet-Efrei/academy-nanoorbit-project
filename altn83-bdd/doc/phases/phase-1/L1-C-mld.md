# L1-C - Modèle Logique de Données (MLD) NanoOrbit

**Module** : ALTN83 - Bases de Données Réparties | **Phase** : 1 - Conception & Architecture distribuée

---

## Notation

- **PK** : clé primaire (soulignée)
- **#FK** : clé étrangère (préfixée #)
- **NOT NULL** : tous les attributs sauf mention contraire (exigence E1)
- Types Oracle 23ai conformes au CDC Phase 1 et à l'Annexe A

---

## Schéma relationnel - 11 tables (10 + HISTORIQUE_STATUT)

### Table 1 - ORBITE (3 lignes de référence)

```
ORBITE (
    id_orbite           VARCHAR2(20)    PK,
    type_orbite         VARCHAR2(10)    NOT NULL  CHECK IN ('LEO','MEO','SSO','GEO'),
    altitude            NUMBER(5)       NOT NULL,
    inclinaison         NUMBER(5,2)     NOT NULL,
    periode_orbitale    NUMBER(6,2)     NOT NULL,
    excentricite        NUMBER(6,4)     NOT NULL,
    zone_couverture     VARCHAR2(200)   NOT NULL,
    CONSTRAINT uq_orbite_alt_incl UNIQUE (altitude, inclinaison)    -- RG-O02
)
```

**Dépend de** : aucune | **Exemples** : ORB-001 (SSO 550km), ORB-002 (SSO 700km), ORB-003 (LEO 400km)

> Variante justifiee : le CDC section 2.2 mentionne NUMBER (AI) mais les donnees de reference (Annexe A) utilisent les codes ORB-001, ORB-002, ORB-003. VARCHAR2(20) est retenu pour coller au jeu de reference. Variante mineure acceptee selon le CDC.

---

### Table 2 - SATELLITE (5 lignes dont SAT-005 Désorbité)

```
SATELLITE (
    id_satellite        VARCHAR2(20)    PK,                                         -- RG-S01
    nom_satellite       VARCHAR2(100)   NOT NULL,
    date_lancement      DATE            NOT NULL,
    masse               NUMBER(5,2)     NOT NULL,
    format_cubesat      VARCHAR2(5)     NOT NULL  CHECK IN ('1U','3U','6U','12U'),  -- E2
    statut              VARCHAR2(30)    NOT NULL  CHECK IN ('Opérationnel','En veille','Défaillant','Désorbité'),
    duree_vie_prevue    NUMBER(4)       NOT NULL,
    capacite_batterie   NUMBER(6,1)     NOT NULL,
    #id_orbite          VARCHAR2(20)    NOT NULL  FK -> ORBITE(id_orbite)             -- RG-S02
)
```

**Dépend de** : ORBITE

---

### Table 3 - HISTORIQUE_STATUT (0 ligne initiale - trigger T5)

```
HISTORIQUE_STATUT (
    id_historique       NUMBER          PK  GENERATED ALWAYS AS IDENTITY,
    #id_satellite       VARCHAR2(20)    NOT NULL  FK -> SATELLITE(id_satellite),
    ancien_statut       VARCHAR2(30)    NOT NULL,
    nouveau_statut      VARCHAR2(30)    NOT NULL,
    date_changement     TIMESTAMP       NOT NULL  DEFAULT SYSTIMESTAMP,
    motif               VARCHAR2(200)                                                 -- nullable
)
```

**Dépend de** : SATELLITE | **Peuplée par** : trigger T5 (`trg_historique_statut`) uniquement

---

### Table 4 - INSTRUMENT (4 lignes dont INS-AIS-01 résolution NULL)

```
INSTRUMENT (
    ref_instrument      VARCHAR2(20)    PK,                                          -- RG-I01
    type_instrument     VARCHAR2(50)    NOT NULL,
    modele              VARCHAR2(100)   NOT NULL,
    resolution          NUMBER(6,1),                                                  -- nullable (AIS)
    consommation        NUMBER(5,2)     NOT NULL,
    masse               NUMBER(5,3)     NOT NULL
)
```

**Dépend de** : aucune

---

### Table 5 - EMBARQUEMENT (7 lignes, PK composite) - Entité-association

```
EMBARQUEMENT (
    #id_satellite       VARCHAR2(20)    PK  FK -> SATELLITE(id_satellite),            -- E6
    #ref_instrument     VARCHAR2(20)    PK  FK -> INSTRUMENT(ref_instrument),         -- E6
    date_integration    DATE            NOT NULL,
    etat_fonctionnement VARCHAR2(20)    NOT NULL  CHECK IN ('Nominal','Dégradé','Hors service')
)
```

**PK composite** : `(id_satellite, ref_instrument)` | **Dépend de** : SATELLITE, INSTRUMENT

---

### Table 6 - CENTRE_CONTROLE (2 lignes initiales, CTR-003 ajouté Phase 4)

```
CENTRE_CONTROLE (
    id_centre           VARCHAR2(20)    PK,
    nom_centre          VARCHAR2(100)   NOT NULL,
    ville               VARCHAR2(50)    NOT NULL,
    region_geo          VARCHAR2(50)    NOT NULL,
    fuseau_horaire      VARCHAR2(50)    NOT NULL,
    statut              VARCHAR2(20)    NOT NULL  CHECK IN ('Actif','Inactif')
)
```

**Dépend de** : aucune

> Variante justifiee : meme raisonnement que pour id_orbite -- le CDC dit NUMBER (AI) mais les donnees de reference utilisent CTR-001, CTR-002. VARCHAR2(20) retenu.

---

### Table 7 - STATION_SOL (3 lignes dont GS-SGP-01 Maintenance)

```
STATION_SOL (
    code_station        VARCHAR2(20)    PK,                                          -- RG-G01
    nom_station         VARCHAR2(100)   NOT NULL,
    latitude            NUMBER(9,6)     NOT NULL,                                    -- RG-G01
    longitude           NUMBER(9,6)     NOT NULL,                                    -- RG-G01
    diametre_antenne    NUMBER(4,1)     NOT NULL,
    bande_frequence     VARCHAR2(10)    NOT NULL,
    debit_max           NUMBER(6,1)     NOT NULL,
    statut              VARCHAR2(20)    NOT NULL  CHECK IN ('Active','Maintenance','Inactive')
)
```

**Dépend de** : aucune

---

### Table 8 - AFFECTATION_STATION (3 lignes, PK composite)

```
AFFECTATION_STATION (
    #id_centre          VARCHAR2(20)    PK  FK -> CENTRE_CONTROLE(id_centre),         -- RG-G04
    #code_station       VARCHAR2(20)    PK  FK -> STATION_SOL(code_station),          -- RG-G04
    date_affectation    DATE            NOT NULL
)
```

**PK composite** : `(id_centre, code_station)` | **Dépend de** : CENTRE_CONTROLE, STATION_SOL

---

### Table 9 - MISSION (3 lignes : 2 Active + 1 Terminée)

```
MISSION (
    id_mission          VARCHAR2(20)    PK,                                          -- RG-M01
    nom_mission         VARCHAR2(100)   NOT NULL,
    objectif            VARCHAR2(500)   NOT NULL,
    zone_geo_cible      VARCHAR2(200)   NOT NULL,
    date_debut          DATE            NOT NULL,                                    -- RG-M01
    date_fin            DATE,                                                         -- nullable (E1, RG-M01)
    statut_mission      VARCHAR2(20)    NOT NULL  CHECK IN ('Active','Terminée')
)
```

**Dépend de** : aucune

---

### Table 10 - FENETRE_COM (5 lignes : 3 Réalisée + 2 Planifiée)

```
FENETRE_COM (
    id_fenetre          NUMBER          PK  GENERATED ALWAYS AS IDENTITY,
    datetime_debut      TIMESTAMP       NOT NULL,
    duree               NUMBER(4)       NOT NULL  CHECK (duree BETWEEN 1 AND 900),   -- RG-F04, E4
    elevation_max       NUMBER(5,2)     NOT NULL,
    volume_donnees      NUMBER(8,1),                                                  -- nullable (E1, RG-F05)
    statut              VARCHAR2(20)    NOT NULL  CHECK IN ('Planifiée','Réalisée'),
    #id_satellite       VARCHAR2(20)    NOT NULL  FK -> SATELLITE(id_satellite),       -- RG-F01
    #code_station       VARCHAR2(20)    NOT NULL  FK -> STATION_SOL(code_station)      -- RG-F01
)
```

**Dépend de** : SATELLITE, STATION_SOL | **PK propre** car plusieurs fenêtres par couple (satellite, station)

---

### Table 11 - PARTICIPATION (7 lignes, PK composite) - Entité-association

```
PARTICIPATION (
    #id_satellite       VARCHAR2(20)    PK  FK -> SATELLITE(id_satellite),            -- E6
    #id_mission         VARCHAR2(20)    PK  FK -> MISSION(id_mission),               -- E6
    role_satellite      VARCHAR2(100)   NOT NULL                                     -- RG-M03
)
```

**PK composite** : `(id_satellite, id_mission)` | **Dépend de** : SATELLITE, MISSION

---

## Ordre de création DDL (respect des dépendances FK - Exigence E5)

| # | Table | Dépend de | Justification |
|---|---|---|---|
| 1 | ORBITE | - | Aucune FK, référentiel autonome |
| 2 | SATELLITE | ORBITE | FK `id_orbite` -> ORBITE |
| 3 | HISTORIQUE_STATUT | SATELLITE | FK `id_satellite` -> SATELLITE |
| 4 | INSTRUMENT | - | Aucune FK, catalogue autonome |
| 5 | EMBARQUEMENT | SATELLITE, INSTRUMENT | FK vers les deux |
| 6 | CENTRE_CONTROLE | - | Aucune FK |
| 7 | STATION_SOL | - | Aucune FK |
| 8 | AFFECTATION_STATION | CENTRE_CONTROLE, STATION_SOL | FK vers les deux |
| 9 | MISSION | - | Aucune FK |
| 10 | FENETRE_COM | SATELLITE, STATION_SOL | FK vers les deux |
| 11 | PARTICIPATION | SATELLITE, MISSION | FK vers les deux |

---

## Vérification 3NF (Troisième Forme Normale)

**1NF** : chaque attribut est atomique, aucun groupe répétitif. Les données multi-valeurs (instruments d'un satellite, missions d'un satellite) sont gérées par des tables associatives (EMBARQUEMENT, PARTICIPATION).

**2NF** : dans les tables à PK composite (EMBARQUEMENT, PARTICIPATION, AFFECTATION_STATION), tous les attributs non-clés dépendent de la **totalité** de la PK composite :
- EMBARQUEMENT : `date_integration` et `etat_fonctionnement` dépendent du couple (satellite, instrument)
- PARTICIPATION : `role_satellite` dépend du couple (satellite, mission)
- AFFECTATION_STATION : `date_affectation` dépend du couple (centre, station)

**3NF** : aucune dépendance transitive détectée :
- SATELLITE ne stocke pas `type_orbite` (accessible via FK -> ORBITE) ✓
- FENETRE_COM ne duplique pas `nom_station` ni `debit_max` (accessible via FK -> STATION_SOL) ✓
- PARTICIPATION ne duplique pas `nom_mission` ni `statut_mission` (accessible via FK -> MISSION) ✓

---

## Colonnes candidates à l'indexation

| Table | Colonne(s) | Type d'index | Justification |
|---|---|---|---|
| SATELLITE | `statut` | B-tree | Filtrage fréquent (Opérationnel, Désorbité…) |
| SATELLITE | `id_orbite` (FK) | B-tree | Jointure SATELLITE ↔ ORBITE |
| FENETRE_COM | `id_satellite` (FK) | B-tree | Jointure et recherche par satellite |
| FENETRE_COM | `code_station` (FK) | B-tree | Jointure et recherche par station |
| FENETRE_COM | `datetime_debut` | B-tree | Tri chronologique, détection chevauchements (T2) |
| FENETRE_COM | `statut` | B-tree | Filtrage Planifiée / Réalisée |
| PARTICIPATION | `id_mission` (FK) | B-tree | Recherche des satellites d'une mission |
| EMBARQUEMENT | `ref_instrument` (FK) | B-tree | Recherche des satellites portant un instrument |
| AFFECTATION_STATION | `code_station` (FK) | B-tree | Recherche du centre d'une station |

> Note : ces index seront créés en Phase 4 (Ex.17). Les PK et UNIQUE créent automatiquement des index.
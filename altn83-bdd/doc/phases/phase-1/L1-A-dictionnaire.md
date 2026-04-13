# L1-A - Dictionnaire des Données NanoOrbit

**Module** : ALTN83 - Bases de Données Réparties | **Phase** : 1 - Conception & Architecture distribuée

---

## 1. Dictionnaire des attributs par entité

### 1.1 ORBITE - Référentiel des plans orbitaux (3 lignes en référence)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `id_orbite` | VARCHAR2(20) | OUI | OUI (PK) | Code alphanumérique (ex : ORB-001) -- voir note (*) |
| `type_orbite` | VARCHAR2(10) | OUI | NON | CHECK IN ('LEO','MEO','SSO','GEO') |
| `altitude` | NUMBER(5) | OUI | NON | Altitude nominale en km |
| `inclinaison` | NUMBER(5,2) | OUI | NON | Angle plan orbital / équateur |
| `periode_orbitale` | NUMBER(6,2) | OUI | NON | Durée d'une révolution complète (min) |
| `excentricite` | NUMBER(6,4) | OUI | NON | 0 = circulaire, 1 = elliptique extrême |
| `zone_couverture` | VARCHAR2(200) | OUI | NON | Description géographique de la zone surveillée |

**Contrainte UNIQUE composite** : (`altitude`, `inclinaison`) - RG-O02

> (*) Le CDC section 2.2 indique le type NUMBER (AI) pour id_orbite, mais l'Annexe A utilise les valeurs ORB-001, ORB-002, ORB-003 qui sont des chaines alphanumeriques. Le type VARCHAR2(20) est retenu pour coller aux donnees de reference. Cette variante est documentee conformement a la note du CDC : "Les variantes mineures justifiees dans vos scripts restent acceptees."

---

### 1.2 SATELLITE - Parc de CubeSats (5 lignes dont 1 Désorbité)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `id_satellite` | VARCHAR2(20) | OUI | OUI (PK) | Code immuable (ex : SAT-001) - RG-S01 |
| `nom_satellite` | VARCHAR2(100) | OUI | NON | Nom commercial / opérationnel |
| `date_lancement` | DATE | OUI | NON | Date effective de mise en orbite |
| `masse` | NUMBER(5,2) | OUI | NON | Masse au lancement (kg) |
| `format_cubesat` | VARCHAR2(5) | OUI | NON | CHECK IN ('1U','3U','6U','12U') |
| `statut` | VARCHAR2(30) | OUI | NON | CHECK IN ('Opérationnel','En veille','Défaillant','Désorbité') |
| `duree_vie_prevue` | NUMBER(4) | OUI | NON | Durée nominale mission (mois) |
| `capacite_batterie` | NUMBER(6,1) | OUI | NON | Énergie stockable (Wh) |
| `#id_orbite` | VARCHAR2(20) | OUI | NON | FK -> ORBITE(id_orbite) - RG-S02 |

---

### 1.3 INSTRUMENT - Catalogue des instruments embarqués (4 lignes)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `ref_instrument` | VARCHAR2(20) | OUI | OUI (PK) | Référence constructeur (ex : INS-CAM-01) - RG-I01 |
| `type_instrument` | VARCHAR2(50) | OUI | NON | Caméra optique / Infrarouge / Récepteur AIS / Spectromètre |
| `modele` | VARCHAR2(100) | OUI | NON | Désignation commerciale |
| `resolution` | NUMBER(6,1) | **NON** | NON | NULL si non applicable (ex : AIS - RG-I01, Ex.4 Palier 2) |
| `consommation` | NUMBER(5,2) | OUI | NON | Puissance en fonctionnement (W) |
| `masse` | NUMBER(5,3) | OUI | NON | Masse de l'instrument (kg) |

---

### 1.4 EMBARQUEMENT - Instruments montés sur satellites (7 lignes, PK composite)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `#id_satellite` | VARCHAR2(20) | OUI | PK composite | FK -> SATELLITE(id_satellite) - RG-S04 |
| `#ref_instrument` | VARCHAR2(20) | OUI | PK composite | FK -> INSTRUMENT(ref_instrument) - RG-S04 |
| `date_integration` | DATE | OUI | NON | Date de montage physique sur le satellite |
| `etat_fonctionnement` | VARCHAR2(20) | OUI | NON | CHECK IN ('Nominal','Dégradé','Hors service') |

---

### 1.5 CENTRE_CONTROLE - Centres d'opération NanoOrbit (2 lignes initiales)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `id_centre` | VARCHAR2(20) | OUI | OUI (PK) | Code centre (ex : CTR-001) -- voir note (*) |
| `nom_centre` | VARCHAR2(100) | OUI | NON | Nom opérationnel |
| `ville` | VARCHAR2(50) | OUI | NON | Ville d'implantation |
| `region_geo` | VARCHAR2(50) | OUI | NON | Europe / Amériques / Asie-Pacifique |
| `fuseau_horaire` | VARCHAR2(50) | OUI | NON | Identifiant IANA (ex : Europe/Paris) |
| `statut` | VARCHAR2(20) | OUI | NON | CHECK IN ('Actif','Inactif') |

> Note : CTR-003 (Singapour) n'est pas dans le jeu initial -- il sera ajoute en Phase 4 (MERGE INTO Ex.16).
>
> (*) Le CDC section 2.7 indique NUMBER (AI) pour id_centre, mais l'Annexe A utilise CTR-001, CTR-002 qui sont des chaines alphanumeriques. Meme variante justifiee que pour id_orbite : VARCHAR2(20) retenu pour coller au jeu de reference.

---

### 1.6 STATION_SOL - Stations d'antenne mondiales (3 lignes dont 1 Maintenance)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `code_station` | VARCHAR2(20) | OUI | OUI (PK) | Format GS-XXX-NN - RG-G01 |
| `nom_station` | VARCHAR2(100) | OUI | NON | Nom opérationnel |
| `latitude` | NUMBER(9,6) | OUI | NON | Coordonnée Nord/Sud - RG-G01 |
| `longitude` | NUMBER(9,6) | OUI | NON | Coordonnée Est/Ouest - RG-G01 |
| `diametre_antenne` | NUMBER(4,1) | OUI | NON | Taille antenne principale (m) |
| `bande_frequence` | VARCHAR2(10) | OUI | NON | UHF / S / X / Ka |
| `debit_max` | NUMBER(6,1) | OUI | NON | Débit descendant maximal (Mbps) |
| `statut` | VARCHAR2(20) | OUI | NON | CHECK IN ('Active','Maintenance','Inactive') |

> Note : GS-SGP-01 en Maintenance - trigger T1 bloque les fenêtres vers cette station (RG-G03).

---

### 1.7 AFFECTATION_STATION - Rattachement station ↔ centre (3 lignes, PK composite)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `#id_centre` | VARCHAR2(20) | OUI | PK composite | FK -> CENTRE_CONTROLE(id_centre) - RG-G04 |
| `#code_station` | VARCHAR2(20) | OUI | PK composite | FK -> STATION_SOL(code_station) - RG-G04 |
| `date_affectation` | DATE | OUI | NON | Date de rattachement |

---

### 1.8 MISSION - Missions scientifiques (3 lignes : 2 Active + 1 Terminée)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `id_mission` | VARCHAR2(20) | OUI | OUI (PK) | Format MSN-XXX-AAAA - RG-M01 |
| `nom_mission` | VARCHAR2(100) | OUI | NON | Intitulé descriptif |
| `objectif` | VARCHAR2(500) | OUI | NON | Description objectif scientifique |
| `zone_geo_cible` | VARCHAR2(200) | OUI | NON | Région d'intérêt principal |
| `date_debut` | DATE | OUI | NON | Démarrage effectif - RG-M01 |
| `date_fin` | DATE | **NON** | NON | NULL si durée indéterminée - RG-M01 (E1) |
| `statut_mission` | VARCHAR2(20) | OUI | NON | CHECK IN ('Active','Terminée') |

> Note : MSN-DEF-2022 Terminée - trigger T4 interdit d'y ajouter de nouveaux satellites (RG-M04).

---

### 1.9 FENETRE_COM - Créneaux de communication (5 lignes : 3 Réalisée + 2 Planifiée)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `id_fenetre` | NUMBER | OUI | OUI (PK) | GENERATED ALWAYS AS IDENTITY |
| `datetime_debut` | TIMESTAMP | OUI | NON | Début du passage satellite |
| `duree` | NUMBER(4) | OUI | NON | CHECK BETWEEN 1 AND 900 - RG-F04 |
| `elevation_max` | NUMBER(5,2) | OUI | NON | Angle d'élévation maximal (°) |
| `volume_donnees` | NUMBER(8,1) | **NON** | NON | NULL si Planifiée - RG-F05 (E1) |
| `statut` | VARCHAR2(20) | OUI | NON | CHECK IN ('Planifiée','Réalisée') |
| `#id_satellite` | VARCHAR2(20) | OUI | NON | FK -> SATELLITE(id_satellite) - RG-F01 |
| `#code_station` | VARCHAR2(20) | OUI | NON | FK -> STATION_SOL(code_station) - RG-F01 |

---

### 1.10 PARTICIPATION - Rôles des satellites dans les missions (7 lignes, PK composite)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `#id_satellite` | VARCHAR2(20) | OUI | PK composite | FK -> SATELLITE(id_satellite) - RG-M02 |
| `#id_mission` | VARCHAR2(20) | OUI | PK composite | FK -> MISSION(id_mission) - RG-M02 |
| `role_satellite` | VARCHAR2(100) | OUI | NON | Ex : Imageur principal, Satellite de relais - RG-M03 |

---

### 1.11 HISTORIQUE_STATUT - Table d'audit (0 ligne initiale - alimentée par trigger T5)

| Attribut / Code | Type Oracle | Obligatoire | Unique | Contraintes / Remarques |
|---|---|---|---|---|
| `id_historique` | NUMBER | OUI | OUI (PK) | GENERATED ALWAYS AS IDENTITY |
| `#id_satellite` | VARCHAR2(20) | OUI | NON | FK -> SATELLITE(id_satellite) |
| `ancien_statut` | VARCHAR2(30) | OUI | NON | Valeur avant modification |
| `nouveau_statut` | VARCHAR2(30) | OUI | NON | Valeur après modification |
| `date_changement` | TIMESTAMP | OUI | NON | DEFAULT SYSTIMESTAMP |
| `motif` | VARCHAR2(200) | **NON** | NON | Raison du changement (optionnel) |

---

## 2. Classification des règles de gestion

### 2.1 Catégorie 1 - Structure relationnelle (PK, FK, UNIQUE)

| Code | Règle (résumé) | Mécanisme Oracle |
|---|---|---|
| RG-S01 | Identifiant satellite unique, immuable | PK `id_satellite` + immuabilité applicative |
| RG-S02 | Satellite sur une orbite courante (peut changer) | FK `id_orbite` -> ORBITE |
| RG-S03 | 1 à 4 instruments par satellite, modèle partageable entre satellites | Association N-N via EMBARQUEMENT (cardinalité 1,N côté SATELLITE) |
| RG-O01 | Orbite = entité indépendante, plusieurs satellites possibles | Entité ORBITE + FK depuis SATELLITE |
| RG-O02 | Unicité altitude + inclinaison | UNIQUE(`altitude`, `inclinaison`) |
| RG-O03 | Orbite peut exister sans satellite affecté | Cardinalité 0,N côté ORBITE dans PLACER |
| RG-I01 | Instrument référencé dans un catalogue global | PK `ref_instrument` |
| RG-I02 | Instrument partageable entre satellites | Association N-N via EMBARQUEMENT |
| RG-S04 | Attributs propres à l'embarquement (date, état) | Entité-association EMBARQUEMENT (PK composite) |
| RG-S05 | Satellite participe à ≥1 mission | Association N-N via PARTICIPATION |
| RG-G01 | Station identifiée, localisée (lat/long) | PK `code_station` + NOT NULL lat/lon |
| RG-G02 | Station communique avec plusieurs satellites | Association N-N via FENETRE_COM |
| RG-G04 | Station rattachée à un centre de contrôle | FK via AFFECTATION_STATION (PK composite) |
| RG-F01 | Fenêtre = 1 satellite + 1 station (obligatoire) | FK NOT NULL vers SATELLITE et STATION_SOL |
| RG-M01 | Mission : date début obligatoire, fin nullable | NOT NULL `date_debut`, nullable `date_fin` |
| RG-M02 | Mission ↔ Satellite N-N | Association via PARTICIPATION |
| RG-M03 | Rôle satellite par mission | Attribut `role_satellite` dans PARTICIPATION |

### 2.2 Catégorie 2 - Contrainte simple (CHECK, NOT NULL, domaine)

| Code | Règle (résumé) | Mécanisme Oracle |
|---|---|---|
| RG-F04 | Durée fenêtre entre 1 et 900 secondes | CHECK(`duree` BETWEEN 1 AND 900) |
| (E1) | Tous NOT NULL sauf `date_fin` et `volume_donnees` | NOT NULL sur tous les attributs sauf ces deux |
| (E2) | Statuts implémentés via CHECK | CHECK sur `statut`, `statut_mission`, `etat_fonctionnement` |

### 2.3 Catégorie 3 - Mécanisme procédural (Trigger / Procédure PL/SQL)

| Code | Règle (résumé) | Mécanisme Oracle | Phase |
|---|---|---|---|
| RG-S06 | Satellite désorbité -> plus de fenêtre ni de mission | Trigger T1 (`trg_valider_fenetre`) | Phase 2 |
| RG-G03 | Station en maintenance -> pas de nouvelle fenêtre | Trigger T1 (`trg_valider_fenetre`) | Phase 2 |
| RG-F02 | Pas de chevauchement temporel fenêtre / satellite | Trigger T2 (`trg_no_chevauchement`) | Phase 2 |
| RG-F03 | Pas de chevauchement temporel fenêtre / station | Trigger T2 (`trg_no_chevauchement`) | Phase 2 |
| RG-F05 | Volume NULL si statut ≠ Réalisée | Trigger T3 (`trg_volume_realise`) | Phase 2 |
| RG-M04 | Mission Terminée -> plus de nouveau satellite | Trigger T4 (`trg_mission_terminee`) | Phase 2 |
| RG-S06 | Traçabilité changement statut satellite | Trigger T5 (`trg_historique_statut`) | Phase 2 |
| RG-I03 | Instrument non simultanément sur 2 satellites | Contrainte applicative / Trigger | Phase 2 |
| RG-I04 | Instrument HS > 30 jours -> satellite à signaler | Procédure PL/SQL | Phase 3 |
# L1-B - Modèle Conceptuel de Données (MCD) NanoOrbit

**Module** : ALTN83 - Bases de Données Réparties | **Phase** : 1 - Conception & Architecture distribuée

---

## 1. Outil utilisé

Le MCD a été réalisé avec **MoCoDo 4.3.3** (outil open-source de modélisation MERISE).

**Fichiers fournis :**
- `L1-B-mcd.mocodo` - Source MoCoDo (importable sur mocodo.net ou en ligne de commande)
- `L1-B-MCD.png` - Rendu PNG du MCD

---

## 2. Légende du MCD

| Symbole | Signification |
|---|---|
| Rectangle | Entité |
| Rectangle arrondi | Association (losange MERISE aplati dans MoCoDo) |
| Attribut souligné | Identifiant (clé primaire) |
| `1,1` | Cardinalité minimale 1, maximale 1 |
| `1,N` | Cardinalité minimale 1, maximale N |
| `0,N` | Cardinalité minimale 0, maximale N |

---

## 3. Entités du MCD (6 entités)

| # | Entité | Identifiant | Nb attributs | Description |
|---|---|---|---|---|
| 1 | **ORBITE** | `id_orbite` | 7 | Plans orbitaux des satellites (SSO, LEO, MEO, GEO) |
| 2 | **SATELLITE** | `id_satellite` | 8 | CubeSats de la constellation NanoOrbit |
| 3 | **INSTRUMENT** | `ref_instrument` | 6 | Catalogue des instruments embarquables |
| 4 | **CENTRE_CONTROLE** | `id_centre` | 6 | Centres d'opération (Paris, Houston, Singapour) |
| 5 | **STATION_SOL** | `code_station` | 8 | Antennes au sol mondiales |
| 6 | **MISSION** | `id_mission` | 7 | Missions scientifiques d'observation |

> Note : la table HISTORIQUE_STATUT (Phase 2) n'est pas modélisée comme entité dans le MCD car c'est une table technique d'audit alimentée exclusivement par le trigger T5. Elle sera créée en Phase 2 après SATELLITE.

---

## 4. Associations du MCD (5 associations)

### 4.1 PLACER (ORBITE - SATELLITE)

| Côté | Entité | Cardinalité | Justification |
|---|---|---|---|
| Gauche | ORBITE | **0,N** | Une orbite peut accueillir 0 ou plusieurs satellites (RG-O01, RG-O03 : orbite pré-planifiée sans satellite) |
| Droite | SATELLITE | **1,1** | Un satellite est placé sur exactement une orbite courante (RG-S02) |

- **Attributs portés** : aucun
- **Passage MLD** : FK `id_orbite` NOT NULL dans SATELLITE

---

### 4.2 EMBARQUER (SATELLITE - INSTRUMENT) ★ Entité-association porteuse

| Côté | Entité | Cardinalité | Justification |
|---|---|---|---|
| Gauche | SATELLITE | **1,N** | Un satellite embarque au moins 1 instrument, max 4 (RG-S03) |
| Droite | INSTRUMENT | **0,N** | Un instrument peut être embarqué sur 0 ou plusieurs satellites (RG-I02) |

- **Attributs portés** : `date_integration` (DATE), `etat_fonctionnement` (VARCHAR2) - RG-S04
- **Passage MLD** : Table EMBARQUEMENT avec PK composite `(id_satellite, ref_instrument)`

> Justification entité-association : les attributs `date_integration` et `etat_fonctionnement` dépendent du **couple** (satellite, instrument), pas de l'une ou l'autre entité seule. Le même modèle INS-CAM-01 peut être Nominal sur SAT-001 et Dégradé sur SAT-004.

---

### 4.3 COMMUNIQUER (SATELLITE - STATION_SOL) -> FENETRE_COM

| Côté | Entité | Cardinalité | Justification |
|---|---|---|---|
| Gauche | STATION_SOL | **0,N** | Une station peut avoir 0 ou plusieurs fenêtres (RG-G02) |
| Droite | SATELLITE | **0,N** | Un satellite peut avoir 0 ou plusieurs fenêtres (RG-G02) |

- **Attributs portés** : `id_fenetre`, `datetime_debut`, `duree`, `elevation_max`, `volume_donnees`, `statut_fenetre`
- **Passage MLD** : Table FENETRE_COM avec **PK propre** `id_fenetre` (auto-incrémentée) et FK vers SATELLITE et STATION_SOL

> **Justification choix binaire vs ternaire** : la relation est **binaire** (SATELLITE × STATION_SOL) et non ternaire incluant CENTRE_CONTROLE. Trois raisons :
> 1. Le centre de contrôle supervise la **station**, pas la **fenêtre** directement. Le lien centre->station est structurel (AFFECTATION_STATION), pas événementiel.
> 2. Si une station change de centre de rattachement, les fenêtres historiques ne doivent pas être impactées.
> 3. Conforme au principe MERISE de dépendance fonctionnelle : la fenêtre dépend fonctionnellement du couple (satellite, station), pas du triplet (satellite, station, centre).

> **Justification PK propre** : contrairement à EMBARQUEMENT et PARTICIPATION, **plusieurs fenêtres peuvent exister pour le même couple (satellite, station)** à des dates différentes. Une PK composite `(id_satellite, code_station)` ne serait pas discriminante - d'où la PK technique `id_fenetre` auto-incrémentée.

---

### 4.4 PARTICIPER (SATELLITE - MISSION) Entité-association porteuse

| Côté | Entité | Cardinalité | Justification |
|---|---|---|---|
| Gauche | SATELLITE | **0,N** | Un satellite peut participer à 0 ou plusieurs missions (RG-M02). 0 car un satellite peut exister avant d'être affecté. |
| Droite | MISSION | **1,N** | Une mission mobilise au moins 1 satellite (RG-M02) |

- **Attributs portés** : `role_satellite` (VARCHAR2) - RG-M03
- **Passage MLD** : Table PARTICIPATION avec PK composite `(id_satellite, id_mission)`

> Note : RG-S05 dit « un satellite participe à au moins une mission » - en modélisation, on tolère la cardinalité 0,N côté SATELLITE car un satellite peut être créé dans le système avant sa première affectation à une mission. La contrainte « au moins une » est vérifiable par requête ou procédure.

---

### 4.5 AFFECTER (CENTRE_CONTROLE - STATION_SOL)

| Côté | Entité | Cardinalité | Justification |
|---|---|---|---|
| Gauche | CENTRE_CONTROLE | **1,N** | Un centre supervise au moins 1 station (RG-G04) |
| Droite | STATION_SOL | **1,N** | Chaque station est rattachée à au moins 1 centre (RG-G04) |

- **Attributs portés** : `date_affectation` (DATE)
- **Passage MLD** : Table AFFECTATION_STATION avec PK composite `(id_centre, code_station)`

---

## 5. Contraintes non exprimables dans le MCD

Ces contraintes sont **identifiées** mais **ne peuvent pas être modélisées dans le MCD MERISE**. Elles seront implémentées en Phase 2 (triggers) ou Phase 3 (PL/SQL) :

| # | Contrainte | Règle | Implémentation prévue |
|---|---|---|---|
| 1 | Satellite désorbité -> pas de nouvelle fenêtre ni mission | RG-S06 | Trigger T1 (`trg_valider_fenetre`) - Phase 2 |
| 2 | Station en maintenance -> pas de nouvelle fenêtre | RG-G03 | Trigger T1 (`trg_valider_fenetre`) - Phase 2 |
| 3 | Pas de chevauchement temporel fenêtre / satellite | RG-F02 | Trigger T2 (`trg_no_chevauchement`) - Phase 2 |
| 4 | Pas de chevauchement temporel fenêtre / station | RG-F03 | Trigger T2 (`trg_no_chevauchement`) - Phase 2 |
| 5 | Volume données NULL si statut ≠ Réalisée | RG-F05 | Trigger T3 (`trg_volume_realise`) - Phase 2 |
| 6 | Mission terminée -> plus de nouveau satellite | RG-M04 | Trigger T4 (`trg_mission_terminee`) - Phase 2 |
| 7 | Traçabilité des changements de statut satellite | RG-S06 | Trigger T5 (`trg_historique_statut`) - Phase 2 |
| 8 | Instrument non simultanément sur 2 satellites | RG-I03 | Contrainte applicative / Trigger - Phase 2 |
| 9 | Instrument HS > 30 jours -> satellite à signaler | RG-I04 | Procédure PL/SQL - Phase 3 |

---

## 6. Script MoCoDo - Référence complète

Le fichier `L1-B-mcd.mocodo` contient le code source suivant, directement importable dans MoCoDo :

```
ORBITE: id_orbite, type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture
PLACER, 0N ORBITE, 11 SATELLITE
SATELLITE: id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut_satellite, duree_vie_prevue, capacite_batterie
COMMUNIQUER, 0N STATION_SOL, 0N SATELLITE: id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut_fenetre
STATION_SOL: code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut_station
AFFECTER, 1N CENTRE_CONTROLE, 1N STATION_SOL: date_affectation

:
MISSION: id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission
PARTICIPER, 0N SATELLITE, 1N MISSION: role_satellite
EMBARQUER, 1N SATELLITE, 0N INSTRUMENT: date_integration, etat_fonctionnement
INSTRUMENT: ref_instrument, type_instrument, modele, resolution, consommation, masse_instrument
CENTRE_CONTROLE: id_centre, nom_centre, ville, region_geo, fuseau_horaire, statut_centre
```

**Commandes de génération :**
```bash
# Générer le PNG du MCD
mocodo --input L1-B-mcd.mocodo --output_dir . --colors ocean --scale 1.2

# Générer le MLD (passage MERISE automatique)
mocodo --input L1-B-mcd.mocodo --output_dir . --mld --select mld

# Générer le DDL SQL générique
mocodo --input L1-B-mcd.mocodo --output_dir . -t sql
```

---

## 7. Tableau de correspondance MCD -> MLD

| Élément MCD | Type | Passage MLD | Table résultante |
|---|---|---|---|
| ORBITE | Entité | Conservée | ORBITE |
| SATELLITE | Entité | Conservée + FK `id_orbite` (PLACER 1,1) | SATELLITE |
| INSTRUMENT | Entité | Conservée | INSTRUMENT |
| CENTRE_CONTROLE | Entité | Conservée | CENTRE_CONTROLE |
| STATION_SOL | Entité | Conservée | STATION_SOL |
| MISSION | Entité | Conservée | MISSION |
| PLACER (0,N - 1,1) | Association | FK absorbée côté 1,1 | -> FK dans SATELLITE |
| EMBARQUER (1,N - 0,N) | Assoc. porteuse | Table associative | EMBARQUEMENT |
| COMMUNIQUER (0,N - 0,N) | Assoc. porteuse | Table avec PK propre | FENETRE_COM |
| PARTICIPER (0,N - 1,N) | Assoc. porteuse | Table associative | PARTICIPATION |
| AFFECTER (1,N - 1,N) | Association | Table associative | AFFECTATION_STATION |
# Dictionnaire de Données Complet — NanoOrbit

Ce document répertorie l'intégralité des attributs, types techniques Oracle et contraintes d'intégrité du système NanoOrbit, conformément au cahier des charges Phase 1 et au jeu de données de référence.[file:67][file:66]

---

### 1. SEGMENT SPATIAL (Orbites & Satellites)
*Gestion de la constellation et des trajectoires orbitales.*

#### Table ORBITE
*Définit les paramètres physiques des trajectoires.*

| Attribut           | Type Oracle      | Propriétés      | Description / Contraintes |
| :-----------------| :--------------- | :-------------- | :------------------------ |
| **id_orbite**     | `NUMBER`         | **PK**, NUL      | Identifiant technique unique (auto‑incrémenté). |
| type_orbite       | `VARCHAR2(10)`   | NN              | Type d’orbite : `LEO`, `MEO`, `SSO`, `GEO`. |
| altitude_km       | `NUMBER(5)`      | NN, **U1**      | Altitude nominale en kilomètres au‑dessus du sol. |
| inclinaison_deg   | `NUMBER(5,2)`    | NN, **U1**      | Angle d'inclinaison (degrés) par rapport à l'équateur. |
| periode_min       | `NUMBER(6,2)`    | NN              | Durée d’une révolution complète (minutes). |
| excentricite      | `NUMBER(6,4)`    | NN              | Excentricité orbitale (`0` = circulaire, `1` = très elliptique). |
| zone_couverture   | `VARCHAR2(200)`  | NN              | Zone géographique couverte (ex. *Polaire globale — Europe / Arctique*). |

> **Note d'intégrité (U1)** : contrainte `UNIQUE(altitude_km, inclinaison_deg)` — RG‑O02.

#### Table SATELLITE
*Vecteurs actifs de la constellation.*

| Attribut           | Type Oracle      | Propriétés   | Description / Contraintes |
| :-----------------| :--------------- | :----------- | :------------------------ |
| **id_satellite**  | `VARCHAR2(20)`   | **PK**, NN   | Code alphanumérique unique (ex. `SAT-001`), immuable après mise en orbite (RG‑S01, immuabilité applicative). |
| nom_satellite     | `VARCHAR2(100)`  | NN           | Nom commercial / opérationnel du CubeSat. |
| date_lancement    | `DATE`           | NN           | Date effective de mise en orbite. |
| masse_kg          | `NUMBER(5,2)`    | NN           | Masse au lancement (kg). |
| format_cubesat    | `VARCHAR2(5)`    | NN           | Format : `1U`, `3U`, `6U`, `12U`. |
| statut_satellite  | `VARCHAR2(30)`   | NN           | `CHECK` : `Opérationnel`, `En veille`, `Défaillant`, `Désorbité`. |
| vie_prevue_mois   | `NUMBER(4)`      | NN           | Durée de vie nominale estimée (mois). |
| batt_capa_wh      | `NUMBER(6,1)`    | NN           | Capacité batterie totale (Wh). |
| **id_orbite**     | `NUMBER`         | **FK**, NN   | FK vers `ORBITE(id_orbite)` — orbite courante du satellite (RG‑S02, RG‑O01, RG‑O03). |

---

### 2. CHARGE UTILE (Instruments & Intégration)
*Capteurs scientifiques embarqués sur les satellites.*

#### Table INSTRUMENT

| Attribut           | Type Oracle      | Propriétés   | Description / Contraintes |
| :-----------------| :--------------- | :----------- | :------------------------ |
| **ref_instrument**| `VARCHAR2(20)`   | **PK**, NN   | Référence constructeur unique (catalogue global). |
| type_instrument   | `VARCHAR2(50)`   | NN           | `CHECK` : Caméra optique, Infrarouge, Récepteur AIS, Spectromètre. |
| modele            | `VARCHAR2(100)`  | NN           | Désignation commerciale / modèle. |
| resolution_m      | `NUMBER(6,1)`    | NULL         | Résolution au sol (m) — `NULL` si non applicable (ex. AIS). |
| consommation_w    | `NUMBER(5,2)`    | NN           | Puissance consommée en fonctionnement (W). |
| masse_kg          | `NUMBER(5,3)`    | NN           | Masse de l’instrument (kg). |

#### Table EMBARQUEMENT
*Association N:N entre Satellites et Instruments (RG‑S03, RG‑S04, RG‑I02).*

| Attribut           | Type Oracle      | Propriétés        | Description / Contraintes |
| :-----------------| :--------------- | :---------------- | :------------------------ |
| **id_satellite**  | `VARCHAR2(20)`   | **PK, FK**, NN    | FK vers `SATELLITE(id_satellite)`. |
| **ref_instrument**| `VARCHAR2(20)`   | **PK, FK**, NN    | FK vers `INSTRUMENT(ref_instrument)`. |
| date_integration  | `DATE`           | NN               | Date d’intégration sur le satellite. |
| etat_fonctionnement | `VARCHAR2(20)` | NN               | `CHECK` : `Nominal`, `Dégradé`, `Hors service`. |

> PK composite (`id_satellite`, `ref_instrument`) — exigence E6.

---

### 3. SEGMENT SOL (Stations & Communications)
*Infrastructure terrestre de réception et de contrôle.*

#### Table STATION_SOL

| Attribut           | Type Oracle      | Propriétés   | Description / Contraintes |
| :-----------------| :--------------- | :----------- | :------------------------ |
| **code_station**  | `VARCHAR2(20)`   | **PK**, NN   | Identifiant unique (ex. `GS-TLS-01`). |
| nom_station       | `VARCHAR2(100)`  | NN           | Nom opérationnel de la station. |
| latitude_deg      | `NUMBER(9,6)`    | NN           | Latitude en degrés décimaux. |
| longitude_deg     | `NUMBER(9,6)`    | NN           | Longitude en degrés décimaux. |
| diametre_antenne_m| `NUMBER(4,1)`    | NN           | Diamètre de l’antenne principale (m). |
| bande_frequence   | `VARCHAR2(10)`   | NN           | `CHECK` : `UHF`, `S`, `X`, `Ka`. |
| debit_max_mbps    | `NUMBER(6,1)`    | NN           | Débit descendant maximal (Mbps). |
| statut_station    | `VARCHAR2(20)`   | NN           | `CHECK` : `Active`, `Maintenance`, `Inactive`. |

#### Table FENETRE_COM

| Attribut             | Type Oracle      | Propriétés   | Description / Contraintes |
| :-------------------| :--------------- | :----------- | :------------------------ |
| **id_fenetre**      | `NUMBER`         | **PK**, NN   | Identifiant technique auto‑incrémenté. |
| datetime_debut      | `TIMESTAMP`      | NN           | Début du passage du satellite au‑dessus de la station. |
| duree_s             | `NUMBER(4)`      | NN           | Durée effective de la fenêtre (secondes), `CHECK 1–900` — RG‑F04. |
| elevation_max_deg   | `NUMBER(5,2)`    | NN           | Angle d’élévation maximal (qualité de signal). |
| volume_donnees_mo   | `NUMBER(8,1)`    | NULL         | Volume téléchargé (Mo) — `NULL` si fenêtre Planifiée (RG‑F05). |
| statut_fenetre      | `VARCHAR2(20)`   | NN           | `CHECK` : `Planifiée`, `Réalisée`. |
| **id_satellite**    | `VARCHAR2(20)`   | **FK**, NN   | FK vers `SATELLITE(id_satellite)` (RG‑F01). |
| **code_station**    | `VARCHAR2(20)`   | **FK**, NN   | FK vers `STATION_SOL(code_station)` (RG‑F01). |

> RG‑F02 / RG‑F03 (pas de chevauchement pour un même satellite / une même station) seront implémentées par triggers en Phase 2.

---

### 4. SEGMENT OPÉRATIONNEL (Missions & Organisation)

#### Table MISSION

| Attribut           | Type Oracle      | Propriétés   | Description / Contraintes |
| :-----------------| :--------------- | :----------- | :------------------------ |
| **id_mission**     | `VARCHAR2(20)`   | **PK**, NN   | Code unique (`MSN-XXX-AAAA`). |
| nom_mission        | `VARCHAR2(100)`  | NN           | Intitulé descriptif de la mission. |
| objectif           | `VARCHAR2(500)`  | NN           | Description de l’objectif scientifique. |
| zone_cible         | `VARCHAR2(200)`  | NN           | Zone géographique cible. |
| date_debut         | `DATE`           | NN           | Date de démarrage effectif (RG‑M01). |
| date_fin           | `DATE`           | NULL         | Fin nominale — `NULL` si mission à durée indéterminée (RG‑M01). |
| statut_mission     | `VARCHAR2(20)`   | NN           | `CHECK` : `Active`, `Terminée`. |

#### Table PARTICIPATION
*Association N:N entre SATELLITE et MISSION.*

| Attribut           | Type Oracle      | Propriétés        | Description / Contraintes |
| :-----------------| :--------------- | :---------------- | :------------------------ |
| **id_satellite**  | `VARCHAR2(20)`   | **PK, FK**, NN    | FK vers `SATELLITE(id_satellite)`. |
| **id_mission**    | `VARCHAR2(20)`   | **PK, FK**, NN    | FK vers `MISSION(id_mission)`. |
| role_satellite    | `VARCHAR2(50)`   | NN                | Rôle dans la mission (ex. `Imageur principal`, `Satellite de relais`, `Satellite de secours`). |

> PK composite (`id_satellite`, `id_mission`) — exigence E6. RG‑M02 / RG‑M03 sont modélisées par cette association + l’attribut `role_satellite`.

#### Table CENTRE_CONTROLE

| Attribut           | Type Oracle      | Propriétés   | Description / Contraintes |
| :-----------------| :--------------- | :----------- | :------------------------ |
| **id_centre**     | `NUMBER`         | **PK**, NN   | Identifiant technique (auto‑incrémenté). |
| nom_centre        | `VARCHAR2(100)`  | NN           | Nom opérationnel du centre. |
| ville             | `VARCHAR2(50)`   | NN           | Ville d’implantation. |
| region_geo        | `VARCHAR2(50)`   | NN           | Zone de responsabilité : `Europe`, `Amériques`, `Asie-Pacifique`. |
| fuseau_horaire    | `VARCHAR2(50)`   | NN           | Identifiant IANA (ex. `Europe/Paris`). |
| statut            | `VARCHAR2(20)`   | NN           | `CHECK` : `Actif`, `Inactif`. |

#### Table AFFECTATION_STATION
*Rattachement des stations au sol aux centres de contrôle (RG‑G04).*

| Attribut           | Type Oracle      | Propriétés        | Description / Contraintes |
| :-----------------| :--------------- | :---------------- | :------------------------ |
| **id_centre**     | `NUMBER`         | **PK, FK**, NN    | FK vers `CENTRE_CONTROLE(id_centre)`. |
| **code_station**  | `VARCHAR2(20)`   | **PK, FK**, NN    | FK vers `STATION_SOL(code_station)`. |
| date_affectation  | `DATE`           | NN                | Date de rattachement de la station à ce centre. |

> PK composite (`id_centre`, `code_station`). RG‑G04 : chaque station est rattachée à un centre ; un centre peut superviser plusieurs stations.[file:67]

---

[Phase 1](README.md) · [Règles de Gestion](03-classification-regles-gestion.md)
# L3-A - Script Paliers 1 a 5 (Exercices 1 a 16)

**Module** : ALTN83 - Bases de Donnees Reparties | **Phase** : 3 - PL/SQL & Package pkg_nanoOrbit

**Script** : [L3-A-paliers-1-5.sql](../../../src/phase-3/L3-A-paliers-1-5.sql)

---

## Objectif

Ecrire et tester les 16 exercices PL/SQL couvrant les paliers 1 a 5, du bloc anonyme simple
jusqu'aux procédures et fonctions standalone. Chaque exercice inclut les resultats attendus
en commentaire dans le script.

---

## Prerequis

- L2-A-ddl.sql execute (11 tables presentes)
- L2-B-dml.sql execute (39 lignes de reference inserees)
- L2-C-triggers.sql execute (triggers T1–T5 actifs, fonctions auxiliaires `fn_overlap_satellite`
  et `fn_overlap_station` disponibles)

> Activer la sortie console avant execution : `SET SERVEROUTPUT ON`

---

## Palier 1 -- Bloc anonyme (Ex. 1-2)

### Ex. 1 -- Message de bienvenue + comptage general

Affiche un en-tete NanoOrbit et le nombre de satellites, stations au sol, missions actives,
missions totales et fenetres de communication via des `SELECT COUNT(*)` et `DBMS_OUTPUT`.

**Resultats attendus** :
```
=== NanoOrbit CubeSat Earth Observation System ===
EFREI ALTN83 - Bases de donnees reparties - 2025-2026
---
Satellites dans la base   : 5
Stations au sol           : 3
Missions actives          : 2
Missions totales          : 3
Fenetres de communication : 5
```

### Ex. 2 -- SELECT INTO sur SAT-001

Utilise `SELECT INTO` avec des variables typees `%TYPE` pour recuperer et afficher toutes
les colonnes du satellite SAT-001 (NanoOrbit-Alpha).

**Resultats attendus** :
```
Satellite      : SAT-001 - NanoOrbit-Alpha
Lancement      : 15/03/2022
Masse          : 1.3 kg | Format : 3U
Statut         : Operationnel
Duree de vie   : 60 mois | Batterie : 20 Wh
Orbite courante: ORB-001
```

---

## Palier 2 -- Variables et types (Ex. 3-4)

### Ex. 3 -- %ROWTYPE sur SATELLITE

Lit une ligne complete de SATELLITE avec `SATELLITE%ROWTYPE` et affiche le statut et
la capacite batterie du satellite SAT-001.

**Resultats attendus** :
```
=== Ex.3 : SATELLITE via %ROWTYPE ===
Satellite : SAT-001 (NanoOrbit-Alpha)
Statut    : Operationnel
Batterie  : 20 Wh
Lancement : 15/03/2022 | Orbite : ORB-001
```

### Ex. 4 -- NVL sur la resolution des instruments

Parcourt tous les instruments avec un curseur et affiche la resolution en utilisant
`NVL(TO_CHAR(resolution,...), 'N/A (non applicable)')`. Exploite le cas `INS-AIS-01`
dont `resolution` est NULL (recepteur AIS sans image).

**Resultats attendus** :
```
=== Ex.4 : Resolutions des instruments (NVL) ===
INS-AIS-01   | Recepteur AIS    | Resolution : N/A (non applicable)
INS-CAM-01   | Camera optique   | Resolution :    3.0 m
INS-IR-01    | Infrarouge       | Resolution :  160.0 m
INS-SPEC-01  | Spectrometre     | Resolution :   30.0 m
```

---

## Palier 3 -- Structures de controle (Ex. 5-7)

### Ex. 5 -- IF/ELSIF : categorisation par statut et duree de vie

Parcourt tous les satellites et les categorise selon la logique :

| Condition | Categorie |
|-----------|-----------|
| Statut = 'Desorbite' | Hors service |
| Statut = 'Defaillant' | En anomalie |
| Statut = 'En veille' | En veille preventive |
| Operationnel + restant > 24 mois | Actif - longue autonomie |
| Operationnel + restant 6-24 mois | Actif - autonomie limitee |
| Operationnel + restant < 6 mois | Actif - fin de vie imminente |

La duree restante est calculee par `MONTHS_BETWEEN(ADD_MONTHS(date_lancement, duree_vie_prevue), SYSDATE)`.

**Resultats attendus** (a partir du 14/04/2026) :
```
SAT-001   Operationnel      ~11 mois        Actif - autonomie limitee
SAT-002   Operationnel      ~11 mois        Actif - autonomie limitee
SAT-003   Operationnel      ~50 mois        Actif - longue autonomie
SAT-004   En veille         n/a             En veille preventive
SAT-005   Desorbite         n/a             Hors service
```

### Ex. 6 -- CASE : type d'orbite et vitesse orbitale

Pour chaque satellite, affiche l'orbite associee et calcule la vitesse orbitale approximative :

```
v (km/min) = 2*PI * (6371 + altitude) / periode_orbitale
v (m/s)    = v * 1000 / 60
```

Un `CASE` traduit le code orbite en libelle complet (ex. `SSO` -> `Heliosynchrone (SSO)`).

**Resultats attendus** :
```
SAT-001  ORB-001 SSO   550      95.5      7592 m/s
SAT-003  ORB-002 SSO   700      98.8      7497 m/s
SAT-005  ORB-003 LEO   400      92.6      7658 m/s
```

### Ex. 7 -- Boucle FOR : grille de volumes GS-TLS-01 (5 a 15 min)

Lit le debit de GS-TLS-01 (150 Mbps) et calcule pour chaque duree de 5 a 15 minutes :

```
Volume (Mo) = (debit_Mbps / 8) * duree_secondes = 18.75 * duree_s
```

**Resultats attendus** :
```
5 min   (300 s)  ->   5625.0 Mo
6 min   (360 s)  ->   6750.0 Mo
...
15 min  (900 s)  ->  16875.0 Mo
```

---

## Palier 4 -- Curseurs (Ex. 8-11)

### Ex. 8 -- SQL%ROWCOUNT : mise en veille ORB-001

Met a jour en `En veille` tous les satellites Operationnels de ORB-001 (SAT-001 et SAT-002),
affiche `SQL%ROWCOUNT` (2 lignes), puis effectue un `ROLLBACK` pour preserver le jeu de donnees.

**Resultats attendus** :
```
Satellites mis en veille (ORB-001) : 2
Rollback effectue -- etat initial restaure
```

### Ex. 9 -- Cursor FOR Loop : satellites avec orbite et instruments

Double curseur imbrique : boucle externe sur SATELLITE x ORBITE, curseur interne parametre
par `p_sat` sur EMBARQUEMENT x INSTRUMENT. Affiche chaque satellite avec ses instruments.

**Extrait attendu** :
```
SAT-001 | NanoOrbit-Alpha | Operationnel | ORB-001 (SSO)
  -> INS-CAM-01    [Camera optique] Nominal
  -> INS-IR-01     [Infrarouge] Nominal
SAT-003 | NanoOrbit-Gamma | Operationnel | ORB-002 (SSO)
  -> INS-CAM-01    [Camera optique] Nominal
  -> INS-SPEC-01   [Spectrometre] Nominal
```

### Ex. 10 -- Curseur explicite OPEN/FETCH/CLOSE

Parcourt les satellites Operationnels avec `OPEN/FETCH/CLOSE`, puis recupere la fenetre
realisee la plus recente pour chacun via sous-requete corrolee sur `MAX(datetime_debut)`.

**Resultats attendus** :
```
SAT-001 (NanoOrbit-Alpha)
  Derniere fenetre : GS-KIR-01 | 15/01/2024 09:14 | 1250 Mo
SAT-002 (NanoOrbit-Beta)
  Derniere fenetre : GS-TLS-01 | 15/01/2024 11:52 | 890 Mo
SAT-003 (NanoOrbit-Gamma)
  Derniere fenetre : GS-KIR-01 | 16/01/2024 08:30 | 1680 Mo
```

### Ex. 11 -- Curseur parametre : fenetres de GS-KIR-01

Curseur parametre par `p_code_station` (valeur : `GS-KIR-01`). Affiche chaque fenetre
avec date, duree, statut et volume, puis totalise le volume telecharge.

**Resultats attendus** :
```
1    NanoOrbit-Alpha     15/01/2024 09:14  420s   Realisee   1250
3    NanoOrbit-Gamma     16/01/2024 08:30  540s   Realisee   1680
---
Volume total telecharge via GS-KIR-01 : 2930 Mo
```

---

## Palier 5 -- Procedures et fonctions standalone (Ex. 12-16)

### Ex. 12 -- Exceptions predefinies : SELECT INTO securise

Bloc anonyme avec procedure locale `lire_satellite_securise(p_id)` qui gere
`NO_DATA_FOUND` et `OTHERS`.

| Test | ID | Attendu |
|------|----|---------|
| Valide | SAT-003 | `[OK] SAT-003 : NanoOrbit-Gamma (Operationnel)` |
| Inexistant | SAT-999 | `[NO_DATA_FOUND] Satellite SAT-999 inexistant.` |

### Ex. 13 -- RAISE_APPLICATION_ERROR : validation fenetre

Bloc anonyme avec procedure locale `valider_fenetre(sat, sta, debut, duree)` qui verifie :
1. Satellite existe et est Operationnel
2. Station existe et est Active
3. Absence de chevauchement via `fn_overlap_satellite` / `fn_overlap_station` (Phase 2)

Codes erreur locaux : -20040 (sat introuvable), -20041 (sat non Operationnel),
-20042 (sta introuvable), -20043 (sta non Active), -20044 (chevauchement).

| Test | Scenario | Attendu |
|------|----------|---------|
| 1 | SAT-001 / GS-KIR-01 / 2024-03-01 10:00 / 300s | `[OK] Fenetre valide` |
| 2 | SAT-005 / GS-TLS-01 | `[Erreur attendue] ORA-20041: Satellite SAT-005 non Operationnel` |
| 3 | SAT-001 / GS-SGP-01 | `[Erreur attendue] ORA-20043: Station GS-SGP-01 non Active` |

### Ex. 14 [Procedure Socle] -- afficher_statut_satellite(p_id IN)

Procedure standalone `CREATE OR REPLACE`. Affiche le statut, l'orbite et tous les instruments
embarques du satellite. Leve `-20050` si satellite introuvable.

**Signature** :
```sql
PROCEDURE afficher_statut_satellite(p_id IN VARCHAR2)
```

**Cas de test** :
| Scenario | ID | Attendu |
|----------|----|---------|
| Valide | SAT-003 | Statut + ORB-002 + INS-CAM-01 + INS-SPEC-01 |
| Valide | SAT-005 | Statut Desorbite + ORB-003 + INS-AIS-01 |
| Erreur | SAT-999 | `ORA-20050: Satellite SAT-999 introuvable` |

### Ex. 15 [Procedure Socle] -- mettre_a_jour_statut(p_id, p_statut, p_ancien OUT)

Procedure standalone retournant l'ancien statut via parametre `OUT`. Le trigger T5
journalise automatiquement le changement dans `HISTORIQUE_STATUT`. Tests avec `ROLLBACK`.

**Signature** :
```sql
PROCEDURE mettre_a_jour_statut(
    p_id            IN  VARCHAR2,
    p_statut        IN  VARCHAR2,
    p_ancien_statut OUT VARCHAR2
)
```

**Codes erreur** : -20051 (satellite introuvable), -20052 (statut invalide / hors CHECK).

**Cas de test** :
| Scenario | Action | Attendu |
|----------|--------|---------|
| Valide + rollback | SAT-004 -> Operationnel | `En veille --> Operationnel` + rollback |
| Satellite inexistant | SAT-999 | ORA-20051 |
| Statut invalide | 'Hors service' | ORA-20052 (CHECK constraint) |

### Ex. 16 [Fonction Socle] -- calculer_volume_session(p_id_fenetre) RETURN NUMBER

Fonction standalone retournant le volume theorique en Mo :

```
volume = (debit_station_Mbps / 8) * duree_secondes
```

**Signature** :
```sql
FUNCTION calculer_volume_session(p_id_fenetre IN NUMBER) RETURN NUMBER
```

**Resultats attendus** :
| Fenetre | Satellite | Station | Duree | Volume theo |
|---------|-----------|---------|-------|-------------|
| 1 | SAT-001 | GS-KIR-01 | 420s | 21000.0 Mo |
| 2 | SAT-002 | GS-TLS-01 | 310s | 5812.5 Mo |
| 3 | SAT-003 | GS-KIR-01 | 540s | 27000.0 Mo |
| 4 | SAT-001 | GS-TLS-01 | 380s | 7125.0 Mo |
| 5 | SAT-003 | GS-TLS-01 | 290s | 5437.5 Mo |

Code erreur : -20060 (fenetre introuvable).

---

## Couverture CDC Phase 3

| Exercice | Palier | Livrable CDC | Statut |
|----------|--------|--------------|--------|
| Ex. 1-2 | Palier 1 - Bloc anonyme | L3-A | Couvert |
| Ex. 3-4 | Palier 2 - Variables & types | L3-A | Couvert |
| Ex. 5-7 | Palier 3 - Structures de controle | L3-A | Couvert |
| Ex. 8-11 | Palier 4 - Curseurs | L3-A | Couvert |
| Ex. 12-13 | Palier 5 - Exceptions | L3-A | Couvert |
| Ex. 14 | Palier 5 - Procedure `afficher_statut_satellite` | L3-A | Couvert |
| Ex. 15 | Palier 5 - Procedure `mettre_a_jour_statut` | L3-A | Couvert |
| Ex. 16 | Palier 5 - Fonction `calculer_volume_session` | L3-A | Couvert |

# L3-C - BODY du package pkg_nanoOrbit

**Module** : ALTN83 - Bases de Donnees Reparties | **Phase** : 3 - PL/SQL & Package pkg_nanoOrbit

**Script** : [L3-C-body-pkg.sql](../../../src/phase-3/L3-C-body-pkg.sql)

---

## Objectif

Implementer le corps (`PACKAGE BODY`) du package `pkg_nanoOrbit`. La SPEC (L3-B) doit
compiler sans erreur avant d'executer ce script.

---

## Prerequis

- L3-B-spec-pkg.sql execute et compile (`SHOW ERRORS = 0 erreur`)

---

## Detail des implementations

### planifier_fenetre

**Logique** :
1. Validation explicite de la duree ([-20100] si hors [1..900]) avant le DML, pour un message
   d'erreur plus lisible que la violation CHECK Oracle (`ORA-02290`).
2. `INSERT INTO FENETRE_COM ... RETURNING id_fenetre INTO v_new_id` -- les triggers T1, T2 et T3
   se declenchent a ce moment :
   - T1 verifie satellite Operationnel + station Active
   - T2 verifie l'absence de chevauchement
   - T3 force `volume_donnees = NULL` pour les insertions a statut `Planifiee`
3. Retourne `v_new_id` via le parametre `OUT p_id_fenetre`.

**Gestion des exceptions** : capture `SQLCODE = -2291` (violation FK) et releve [-20101].
Les autres erreurs (levees par les triggers) sont propagees avec `RAISE`.

---

### cloturer_fenetre

**Logique** :
1. `SELECT statut INTO v_statut_actuel` -- leve `NO_DATA_FOUND` si fenetre inexistante [-20110].
2. Verifie que le statut courant est `Planifiee` -- sinon [-20111].
3. Verifie que `p_volume_donnees > 0` -- sinon [-20112].
4. `UPDATE FENETRE_COM SET statut='Realisee', volume_donnees=p_volume_donnees`.

Note : le trigger T3 ne bloque pas ici car `statut = 'Realisee'` est autorise.

---

### affecter_satellite_mission

**Logique** :
1. `INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite)`.
   Les triggers T4 se declenchent et verifient :
   - Mission non Terminee (RG-M04 [-20005])
   - Satellite non Desorbite (RG-S06 [-20006])
2. Exception `DUP_VAL_ON_INDEX` (ORA-00001, PK composite) --> [-20120].
3. Autres erreurs propagees avec `RAISE` (triggers T4).

---

### mettre_en_revision

**Logique** :
1. `SELECT statut INTO v_statut_actuel` -- leve `NO_DATA_FOUND` si satellite inexistant [-20130].
2. Si statut deja `Defaillant` ou `Desorbite` --> [-20131] (transition non applicable).
3. `UPDATE SATELLITE SET statut = 'Defaillant'` -- le trigger T5 journalise dans
   `HISTORIQUE_STATUT` : `ancien_statut`, `nouveau_statut`, `SYSTIMESTAMP`.

**Note de conception** : le package utilise `'Defaillant'` car le domaine CHECK Oracle ne
contient pas de valeur `'En revision'`. Ce comportement est documente dans la SPEC.

---

### calculer_volume_theorique

```
volume = ROUND((debit_max / 8) * duree, 1)
```

Jointure `FENETRE_COM fc JOIN STATION_SOL ss ON fc.code_station = ss.code_station`.
Leve [-20140] si la fenetre est introuvable.

---

### statut_constellation

Calcule en un seul `SELECT` avec `COUNT(CASE WHEN ...)` :
- `v_total_sat` : nombre total de satellites
- `v_op_sat` : satellites Operationnels
- `v_veille_sat` : satellites En veille
- `v_desorbite` : satellites Desorbites

Puis deux `SELECT COUNT(*)` pour les missions actives et les fenetres realisees.

Format de retour :
```
"X/Y satellites operationnels, Z missions actives, W fenetres realisees [en veille: A, desorbites: B]"
```

---

### stats_satellite

**Logique** :
1. `SELECT COUNT(*) INTO v_exists` pour verifier l'existence du satellite [-20150].
2. `SELECT NVL(COUNT(*), 0), NVL(SUM(volume_donnees), 0), NVL(AVG(duree), 0)` sur
   `FENETRE_COM WHERE id_satellite = p_id AND statut = 'Realisee'`.
3. Retourne le record `t_stats_satellite` populate.

`NVL(..., 0)` garantit que le record contient des zeros meme si le satellite n'a aucune
fenetre realisee (cas SAT-004 et SAT-005).

---

## Tests de compilation inclus dans le script

Trois blocs de test en lecture seule sont executes apres `CREATE OR REPLACE PACKAGE BODY` :

| Test | Sous-programme | Attendu |
|------|---------------|---------|
| Statut constellation | `statut_constellation()` | Resume complet de la BD |
| Volumes theoriques | `calculer_volume_theorique(1..5)` | 21000, 5812.5, 27000, 7125, 5437.5 Mo |
| Stats par satellite | `stats_satellite('SAT-001'..'SAT-005')` | Indicateurs detailles |

---

## Interaction avec les triggers de Phase 2

| Sous-programme | Trigger declenche | Moment | Effet |
|---------------|------------------|--------|-------|
| planifier_fenetre | T1 | INSERT FENETRE_COM | Bloque si sat Desorbite ou sta Maintenance |
| planifier_fenetre | T2 | INSERT FENETRE_COM | Bloque si chevauchement temporel |
| planifier_fenetre | T3 | INSERT FENETRE_COM | Force volume_donnees = NULL |
| affecter_satellite_mission | T4 | INSERT PARTICIPATION | Bloque mission Terminee ou sat Desorbite |
| mettre_en_revision | T5 | UPDATE SATELLITE.statut | Journalise dans HISTORIQUE_STATUT |

---

## Lien avec les autres livrables

- SPEC : [L3-B-spec-pkg.md](L3-B-spec-pkg.md) / [L3-B-spec-pkg.sql](../../../src/phase-3/L3-B-spec-pkg.sql)
- Scenarios de test : [L3-D-validation.md](L3-D-validation.md)

# L3-D - Script de validation du package pkg_nanoOrbit

**Module** : ALTN83 - Bases de Donnees Reparties | **Phase** : 3 - PL/SQL & Package pkg_nanoOrbit

**Script** : [L3-D-validation.sql](../../../src/phase-3/L3-D-validation.sql)

---

## Objectif

Orchestrer un scenario metier complet en appelant les 7 sous-programmes publics du package
`pkg_nanoOrbit` dans un bloc PL/SQL unique. Un `ROLLBACK` final restaure le jeu de donnees
de reference.

---

## Prerequis

- L3-A, L3-B, L3-C executes
- `pkg_nanoOrbit` compile (SPEC + BODY sans erreur)

---

## Scenario de validation (7 etapes)

### Etape 1 : planifier_fenetre

**Parametres** : SAT-001 → GS-KIR-01, `2024-03-01 10:00:00`, 450 s

**Conditions** :
- SAT-001 est Operationnel (T1 valide)
- GS-KIR-01 est Active (T1 valide)
- 2024-03-01 10:00:00 ne chevauche aucune fenetre existante (T2 valide)
- statut = `Planifiee` => T3 force `volume_donnees = NULL`

**Attendu** :
```
[pkg] Fenetre planifiee : id=6 | SAT-001 -> GS-KIR-01 | 01/03/2024 10:00 | 450 s
id_fenetre retourne (OUT) : 6
```

---

### Etape 2 : cloturer_fenetre

**Parametres** : fenetre id=6, volume = 1500 Mo

**Attendu** :
```
[pkg] Fenetre 6 cloturee avec 1500 Mo.
```

---

### Etape 3 : affecter_satellite_mission

**Parametres** : SAT-004 → MSN-ARC-2023, role = `'Satellite de relais'`

**Conditions** :
- MSN-ARC-2023 est Active (T4 valide)
- SAT-004 n'est pas Desorbite (T4 valide)
- Couple (SAT-004, MSN-ARC-2023) n'existe pas encore dans PARTICIPATION

**Attendu** :
```
[pkg] Affectation : SAT-004 -> MSN-ARC-2023 (role : Satellite de relais)
```

---

### Etape 4 : stats_satellite (SAT-001)

Apres les etapes 1 et 2, SAT-001 possede deux fenetres realisees :
- Fenetre 1 : 1250 Mo, 420 s
- Fenetre 6 : 1500 Mo, 450 s

**Attendu** :
```
Nb fenetres realisees : 2
Volume total          : 2750 Mo
Duree moyenne         : 435 s
```

---

### Etape 5 : statut_constellation

A ce stade dans la transaction :
- SAT-001, SAT-002, SAT-003 : Operationnels (3)
- SAT-004 : En veille (1)
- SAT-005 : Desorbite (1)
- Missions actives : 2 (ARC-2023 + COAST-2024)
- Fenetres realisees : 4 (1, 2, 3, 6)

**Attendu** :
```
3/5 satellites operationnels, 2 missions actives, 4 fenetres realisees [en veille: 1, desorbites: 1]
```

---

### Etape 6 : calculer_volume_theorique (fenetre 6)

GS-KIR-01 : debit = 400 Mbps, duree fenetre = 450 s

```
Volume = (400 / 8) * 450 = 50 * 450 = 22500.0 Mo
```

**Attendu** :
```
Volume theorique fenetre 6 : 22500.0 Mo
```

---

### Etape 7 : mettre_en_revision (SAT-004)

SAT-004 passe de `En veille` a `Defaillant`. Le trigger T5 journalise dans `HISTORIQUE_STATUT`.

**Attendu** :
```
T5 (RG-S06 tracabilite) : SAT-004 : En veille --> Defaillant
[pkg] SAT-004 mis en revision (Defaillant) depuis En veille -- trace dans HISTORIQUE_STATUT (T5).
HISTORIQUE_STATUT : 1 ligne(s) pour SAT-004
```

---

### Rollback final

```sql
ROLLBACK;
```

Restaure le jeu de donnees de reference L2-B. Toutes les insertions et mises a jour
du scenario sont annulees.

**Verification post-rollback** :
```
Constellation post-rollback : 3/5 satellites operationnels, 2 missions actives, 3 fenetres realisees [...]
```

---

## Tests des cas d'erreur du package

Les cas d'erreur suivants sont testes hors du bloc principal :

| Test | Sous-programme | Scenario | Erreur attendue |
|------|---------------|----------|-----------------|
| 1 | planifier_fenetre | Duree = 1000 s (hors domaine) | ORA-20100 |
| 2 | planifier_fenetre | SAT-005 (Desorbite) | ORA-20001 (T1) |
| 3 | cloturer_fenetre | Fenetre 9999 (inexistante) | ORA-20110 |
| 4 | cloturer_fenetre | Fenetre 1 (deja Realisee) | ORA-20111 |
| 5 | affecter_satellite_mission | SAT-002 -> MSN-DEF-2022 (Terminee) | ORA-20005 (T4) |
| 6 | affecter_satellite_mission | SAT-001 -> MSN-ARC-2023 (participation deja existante) | ORA-20120 |
| 7 | mettre_en_revision | SAT-005 (Desorbite) | ORA-20131 |
| 8 | stats_satellite | SAT-999 (inexistant) | ORA-20150 |

---

## Verification de l'etat final

Une requete de controle verifie que tous les `ROLLBACK` ont restaure le jeu de donnees :

| Table | Lignes attendues | Statut |
|-------|-----------------|--------|
| ORBITE | 3 | [OK] |
| SATELLITE | 5 | [OK] |
| HISTORIQUE_STATUT | 0 | [OK] |
| INSTRUMENT | 4 | [OK] |
| EMBARQUEMENT | 7 | [OK] |
| CENTRE_CONTROLE | 2 | [OK] |
| STATION_SOL | 3 | [OK] |
| AFFECTATION_STATION | 3 | [OK] |
| MISSION | 3 | [OK] |
| FENETRE_COM | 5 | [OK] |
| PARTICIPATION | 7 | [OK] |


---

## Lien avec les autres livrables

- Paliers 1-5 : [L3-A-paliers-1-5.md](L3-A-paliers-1-5.md)
- SPEC : [L3-B-spec-pkg.md](L3-B-spec-pkg.md)
- BODY : [L3-C-body-pkg.md](L3-C-body-pkg.md)

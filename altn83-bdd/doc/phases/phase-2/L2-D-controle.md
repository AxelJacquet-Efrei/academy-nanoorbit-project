# L2-D - Script de controle du schema NanoOrbit

**Module** : ALTN83 - Bases de Donnees Reparties | **Phase** : 2 - Schema Oracle & Triggers

**Script** : [L2-D-controle.sql](../../../src/phase-2/L2-D-controle.sql)

---

## Objectif

Verifier que le schema NanoOrbit est correctement deploye apres execution des scripts L2-A, L2-B
et L2-C. Le script interroge les vues systeme Oracle et les tables metier pour valider la coherence
structurelle et fonctionnelle.

---

## Sections du script de controle

### 1. Tables (user_tables)

Verifie que les 11 tables attendues sont presentes dans le schema.

```sql
SELECT table_name FROM user_tables WHERE table_name IN (...) ORDER BY table_name;
```

**Attendu** : 11 lignes.

---

### 2. Contraintes (user_constraints)

Liste toutes les contraintes par table et par type :
- `P` = PRIMARY KEY
- `R` = FOREIGN KEY (Referential)
- `C` = CHECK (et NOT NULL)
- `U` = UNIQUE

**Attendu approximatif** :

| Type | Nombre | Detail |
|------|--------|--------|
| P | 11 | Une PK par table |
| R | ~10 | FK inter-tables |
| C | ~10 | CHECK statuts, format, duree |
| U | 1 | UNIQUE (altitude, inclinaison) sur ORBITE |

---

### 3. Cles etrangeres (user_constraints + user_cons_columns)

Join sur `user_constraints` et `user_cons_columns` pour afficher table_fille, colonne_fk,
table_parent, colonne_pk. Permet de verifier que toutes les FK pointent vers les bonnes tables.

---

### 4. Triggers (user_triggers)

Verifie la presence et le statut des 5 triggers metier.

```sql
SELECT trigger_name, table_name, trigger_type, triggering_event, status FROM user_triggers;
```

**Attendu** : 5 lignes avec `STATUS = ENABLED`.

---

### 5. Fonctions auxiliaires (user_objects)

Verifie que les deux fonctions `PRAGMA AUTONOMOUS_TRANSACTION` de T2 sont compilees.

```sql
SELECT object_name, status FROM user_objects WHERE object_type = 'FUNCTION';
```

**Attendu** : FN_OVERLAP_SATELLITE et FN_OVERLAP_STATION avec `STATUS = VALID`.

---

### 6. Comptages par table

Compte les lignes dans chaque table et compare avec le nombre attendu.

**Attendu** :

| Table | Attendu |
|-------|---------|
| ORBITE | 3 |
| SATELLITE | 5 |
| HISTORIQUE_STATUT | 0 |
| INSTRUMENT | 4 |
| EMBARQUEMENT | 7 |
| CENTRE_CONTROLE | 2 |
| STATION_SOL | 3 |
| AFFECTATION_STATION | 3 |
| MISSION | 3 |
| FENETRE_COM | 5 |
| PARTICIPATION | 7 |

---

### 7. Controles metier

Validations croisees sur les donnees :

| Controle | Requete | Attendu |
|----------|---------|---------|
| Satellites par statut | GROUP BY statut | Desorbite=1, En veille=1, Operationnel=3 |
| Fenetres par statut | GROUP BY statut | Planifiee=2, Realisee=3 |
| RG-F05 : volume non NULL sur Planifiee | COUNT(*) WHERE statut='Planifiee' AND volume IS NOT NULL | 0 |
| RG-F04 : duree hors [1,900] | COUNT(*) WHERE duree NOT BETWEEN 1 AND 900 | 0 |
| UNIQUE orbite | GROUP BY altitude, inclinaison HAVING COUNT > 1 | 0 ligne |
| Participations par mission | LEFT JOIN PARTICIPATION | MSN-ARC=3, MSN-DEF=2, MSN-COAST=2 |
| Instruments par satellite | LEFT JOIN EMBARQUEMENT | SAT-001=2, SAT-002=1, SAT-003=2, SAT-004=1, SAT-005=1 |

---

### 8. Index existants (user_indexes)

Liste les index crees automatiquement par Oracle pour les PK et contraintes UNIQUE. Les index
supplementaires (sur les FK, sur `statut`, sur `datetime_debut`) seront crees en Phase 4 (Ex. 17).

---

### 9. Commentaires (user_tab_comments)

Verifie que les commentaires descriptifs ont ete crees sur chaque table par les instructions
`COMMENT ON TABLE` du script L2-A.

---

## Interpretation des resultats

Un schema correctement deploye produira :
- Section 1 : 11 lignes
- Section 4 : 5 triggers `ENABLED`
- Section 5 : 2 fonctions `VALID`
- Section 7 : 0 violations pour RG-F04 et RG-F05

Si des ecarts apparaissent, verifier l'ordre d'execution des scripts (L2-A -> L2-B -> L2-C).

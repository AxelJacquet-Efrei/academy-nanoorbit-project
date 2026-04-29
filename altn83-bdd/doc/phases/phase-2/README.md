# Phase 2 -- Schema Oracle & Triggers

## Projet NanoOrbit -- CubeSat Earth Observation System
### Module ALTN83 -- Bases de Donnees Reparties | EFREI 2025-2026

---

## Vue d'ensemble

La Phase 2 traduit le MLD de Phase 1 en un schema Oracle 23ai operationnel. Elle comprend :

- La **creation des 11 tables** avec toutes les contraintes DDL (L2-A)
- L'**insertion du jeu de donnees de reference** Annexe A (L2-B)
- L'**implementation des 5 triggers metier** couvrant les regles non exprimables en DDL (L2-C)
- Les **requetes de verification** du schema et des donnees (L2-D)

---

## Arborescence

```
altn83-bdd/
├── src/
│   └── phase-2/
│       ├── L2-A-ddl.sql          <- DDL : 11 tables avec contraintes et commentaires
│       ├── L2-B-dml.sql          <- DML : 39 lignes dans 10 tables + COMMIT
│       ├── L2-C-triggers.sql     <- 5 triggers metier + cas de test
│       └── L2-D-controle.sql     <- Requetes de verification du schema
└── doc/
    └── phases/
        └── phase-2/
            ├── README.md         <- Ce fichier (sommaire Phase 2)
            ├── L2-A-ddl.md       <- Documentation DDL
            ├── L2-B-dml.md       <- Documentation DML
            ├── L2-C-triggers.md  <- Documentation triggers
            └── L2-D-controle.md  <- Documentation controle
```

---

## Correspondance avec les livrables attendus (CDC Phase 2 section 2.5)

| Ref. | Livrable demande | Fichier fourni |
|------|-----------------|----------------|
| L2-A | Script DDL complet | [L2-A-ddl.sql](../../../src/phase-2/L2-A-ddl.sql) |
| L2-B | Script DML | [L2-B-dml.sql](../../../src/phase-2/L2-B-dml.sql) |
| L2-C | Script Triggers | [L2-C-triggers.sql](../../../src/phase-2/L2-C-triggers.sql) |
| L2-D | Script de controle | [L2-D-controle.sql](../../../src/phase-2/L2-D-controle.sql) |

---

## Ordre d'execution

Les scripts doivent etre executes dans cet ordre strict :

```
1. L2-A-ddl.sql      -> Creer les 11 tables
2. L2-B-dml.sql      -> Inserer les 39 lignes de reference
3. L2-C-triggers.sql -> Creer les 5 triggers (apres les donnees)
4. L2-D-controle.sql -> Verifier le schema et les donnees
```

> **Important** : L2-B doit imperativement etre execute AVANT L2-C.
> Le trigger T4 bloquerait l'insertion de SAT-005 dans MSN-DEF-2022 (Terminee),
> et le trigger T1 bloquerait SAT-005 (Desorbite) dans FENETRE_COM.
> Ces donnees historiques sont valides et font partie du referentiel officiel.

---

## Resume des 11 tables

| # | Table | Lignes initiales | Dependances | Notes |
|---|-------|-----------------|-------------|-------|
| 1 | ORBITE | 3 | -- | RG-O01/O02/O03 |
| 2 | SATELLITE | 5 | ORBITE | dont SAT-005 Desorbite |
| 3 | HISTORIQUE_STATUT | 0 | SATELLITE | trigger T5 uniquement |
| 4 | INSTRUMENT | 4 | -- | INS-AIS-01 resolution NULL |
| 5 | EMBARQUEMENT | 7 | SAT + INS | PK composite |
| 6 | CENTRE_CONTROLE | 2 | -- | CTR-003 ajout Phase 4 |
| 7 | STATION_SOL | 3 | -- | GS-SGP-01 Maintenance |
| 8 | AFFECTATION_STATION | 3 | CTR + STA | PK composite |
| 9 | MISSION | 3 | -- | MSN-DEF-2022 Terminee |
| 10 | FENETRE_COM | 5 | SAT + STA | PK IDENTITY |
| 11 | PARTICIPATION | 7 | SAT + MIS | PK composite |

---

## Resume des 5 triggers metier

| ID | Nom | Niveau | Evenement | Regles |
|----|-----|--------|-----------|--------|
| T1 | trg_valider_fenetre | 1 | BEFORE INSERT ON FENETRE_COM | RG-S06, RG-G03 |
| T2 | trg_no_chevauchement | 1 | BEFORE INSERT OR UPDATE ON FENETRE_COM | RG-F02, RG-F03 |
| T3 | trg_volume_realise | 1 | BEFORE INSERT OR UPDATE ON FENETRE_COM | RG-F05 |
| T4 | trg_mission_terminee | 2 | BEFORE INSERT ON PARTICIPATION | RG-M04, RG-S06 |
| T5 | trg_historique_statut | 2 | AFTER UPDATE OF statut ON SATELLITE | RG-S06 (tracabilite) |

---

## Lien avec la Phase 1

- MLD source : [L1-C-mld.md](../phase-1/L1-C-mld.md)
- Dictionnaire de reference : [L1-A-dictionnaire.md](../phase-1/L1-A-dictionnaire.md)
- Note de modelisation : [L1-D-note-modelisation.md](../phase-1/L1-D-note-modelisation.md)

---

## Verifications effectuees

- 11 tables creees dans l'ordre respectant les dependances FK (E5)
- Toutes les regles de gestion DDL implementees (E1 a E6)
- 39 lignes de reference inserees conformement a l'Annexe A
- 5 triggers couvrant 7 regles de gestion non exprimables en DDL
- Cas de test valides et en erreur fournis pour chaque trigger
- Aucune fenetre planifiee ne comporte un volume de donnees renseigne
- Aucun chevauchement temporel dans les fenetres du jeu de reference

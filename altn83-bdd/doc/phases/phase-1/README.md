# Phase 1 -- Conception & Architecture Distribuee

## Projet NanoOrbit -- CubeSat Earth Observation System
### Module ALTN83 -- Bases de Donnees Reparties | EFREI 2025-2026

---

## Arborescence des fichiers (structure plate)

```
phase-1/
  README.md                   <- Ce fichier (sommaire et correspondance livrables)
  L1-A-dictionnaire.md        <- L1-A : Dictionnaire complet (11 tables)
                                         + Classification 26 regles de gestion
  L1-B-documentation-mcd.md  <- L1-B : Documentation MCD complete
                                         (legende, cardinalites, choix, contraintes)
  L1-B-mcd.mocodo             <- L1-B : Source MoCoDo (importable sur mocodo.net)
  L1-B-MCD.png                <- L1-B : Rendu PNG du MCD
  L1-C-mld.md                 <- L1-C : MLD complet Oracle 23ai
                                         (11 tables, PK/FK, types, CHECK,
                                          ordre DDL, 3NF, indexation)
  L1-D-note-modelisation.md   <- L1-D : Note de modelisation :
                                         Partie A : 3 choix delicats justifies
                                         Partie B : Q1-Q4 architecture distribuee
```

---

## Correspondance avec les livrables attendus (CDC Phase 1 section 1.6)

| Ref. | Livrable demande       | Fichier(s) fourni(s)                                              |
|------|------------------------|-------------------------------------------------------------------|
| L1-A | Dictionnaire des donnees | `L1-A-dictionnaire.md`                                          |
| L1-B | MCD MERISE             | `L1-B-MCD.png` + `L1-B-mcd.mocodo` + `L1-B-documentation-mcd.md` |
| L1-C | MLD Relationnel        | `L1-C-mld.md`                                                    |
| L1-D | Note de modelisation   | `L1-D-note-modelisation.md`                                      |

---

## Outil MoCoDo -- Commandes de generation

```bash
# Installer MoCoDo
pip install mocodo

# Generer le PNG du MCD (palette ocean, echelle 1.2)
mocodo --input L1-B-mcd.mocodo --output_dir . --colors ocean --scale 1.2

# Generer le MLD automatique (passage MERISE)
mocodo --input L1-B-mcd.mocodo --output_dir . --mld --select mld

# Generer le DDL SQL generique
mocodo --input L1-B-mcd.mocodo --output_dir . -t sql
```

---

## Verifications effectuees

- OK : 6 entites + 5 associations couvrent les 6 domaines fonctionnels
- OK : 26 regles de gestion (RG-S01 a RG-M04) toutes classifiees
- OK : Cardinalites verifiees -- ORBITE (0,N) dans PLACER car RG-O03
- OK : 3 choix delicats justifies (EMBARQUEMENT, FENETRE_COM binaire, PARTICIPATION)
- OK : 9 contraintes non-MCD identifiees pour Phase 2/3
- OK : Types Oracle conformes a l'Annexe A (CDC Phase 1 section 2)
- OK : 3NF verifiee sur les 11 tables
- OK : Architecture distribuee Q1-Q4 traitee avec schema de fragmentation
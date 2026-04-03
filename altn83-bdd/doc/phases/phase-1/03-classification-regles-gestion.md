## Classification des Règles de Gestion (RG)

Ce document récapitule les contraintes métier et leur implémentation technique sous Oracle, conformément au cahier des charges Phase 1 et à la checklist des règles de gestion.

### Catégories
* **Structure relationnelle** (PK, FK, UNIQUE, entités / associations)
* **Contrainte simple** (CHECK, NOT NULL)
* **Mécanisme procédural** (Trigger, PL/SQL)

---

| Code   | Résumé (synthétique)                                                   | Mécanisme Oracle attendu                                      | Catégorie de garantie                           |
|--------|------------------------------------------------------------------------|----------------------------------------------------------------|-------------------------------------------------|
| RG-S01 | Identifiant satellite unique, immuable                                 | PK sur id_satellite + immuabilité gérée en couche applicative | Structure relationnelle (PK, UNIQUE)            |
| RG-S02 | Satellite affecté à une orbite courante                               | FK depuis SATELLITE vers ORBITE                                | Structure relationnelle (FK)                    |
| RG-S03 | 1 à 4 instruments par satellite, modèle partageable                   | Association N‑N SATELLITE–INSTRUMENT + CHECK sur cardinalité   | Contrainte simple (CHECK)                       |
| RG-S04 | Attributs propres à l’embarquement (date, état)                       | Entité‑association EMBARQUEMENT avec attributs spécifiques     | Structure relationnelle (entité‑association)    |
| RG-S05 | Satellite participe à au moins une mission                            | Association N‑N via PARTICIPATION                              | Structure relationnelle (association N‑N)       |
| RG-S06 | Satellite désorbité : plus de mission ni de fenêtre                   | Trigger BEFORE INSERT sur PARTICIPATION et FENETRE_COM         | Mécanisme procédural (Trigger)                  |
| RG-O01 | Orbite entité indépendante, plusieurs satellites possibles            | Entité ORBITE + FK depuis SATELLITE                            | Structure relationnelle (entité + FK)          |
| RG-O02 | Unicité du couple (altitude, inclinaison)                             | Contrainte UNIQUE (altitude_km, inclinaison_deg) sur ORBITE    | Structure relationnelle (UNIQUE)               |
| RG-O03 | Orbite peut exister sans satellite associé                            | FK nullable côté SATELLITE                                     | Structure relationnelle (FK)                   |
| RG-I01 | Instrument référencé dans un catalogue global                         | Entité INSTRUMENT indépendante                                 | Structure relationnelle (entité)               |
| RG-I02 | Instrument partageable entre satellites                               | Association N‑N via EMBARQUEMENT                               | Structure relationnelle (association N‑N)       |
| RG-I03 | Instrument non simultanément sur deux satellites                      | Contrainte applicative ou Trigger de contrôle d’embarquement   | Mécanisme procédural (Trigger/applicatif)      |
| RG-I04 | Instrument HS > 30 j → satellite à signaler                           | Procédure PL/SQL en Phase 3                                    | Mécanisme procédural (Procédure)               |
| RG-G01 | Station identifiée, localisée (lat/long)                              | PK sur code_station + NOT NULL sur latitude/longitude          | Structure relationnelle + Contrainte simple     |
| RG-G02 | Station communique avec plusieurs satellites                          | Association N‑N via FENETRE_COM                                | Structure relationnelle (association N‑N)       |
| RG-G03 | Station en maintenance : pas de nouvelle fenêtre                      | Trigger BEFORE INSERT sur FENETRE_COM                          | Mécanisme procédural (Trigger)                  |
| RG-G04 | Chaque station rattachée à exactement un centre de contrôle          | FK vers CENTRE_CONTROLE + table AFFECTATION_STATION            | Structure relationnelle (FK + entité‑association) |
| RG-F01 | Fenêtre = 1 satellite + 1 station (obligatoires)                      | FKs NOT NULL vers SATELLITE et STATION_SOL dans FENETRE_COM    | Structure relationnelle + Contrainte simple     |
| RG-F02 | Pas de chevauchement de fenêtres pour un même satellite              | Trigger BEFORE INSERT/UPDATE sur FENETRE_COM                   | Mécanisme procédural (Trigger)                  |
| RG-F03 | Pas de chevauchement de fenêtres pour une même station               | Trigger BEFORE INSERT/UPDATE sur FENETRE_COM                   | Mécanisme procédural (Trigger)                  |
| RG-F04 | Durée fenêtre entre 1 et 900 secondes                                 | Contrainte CHECK (duree_s BETWEEN 1 AND 900)                   | Contrainte simple (CHECK)                      |
| RG-F05 | Volume de données renseigné uniquement si fenêtre « Réalisée »        | Trigger BEFORE INSERT/UPDATE sur FENETRE_COM + vérification du statut | Mécanisme procédural (Trigger)          |
| RG-M01 | Mission : date début obligatoire, date fin facultative (NULL)         | NOT NULL sur date_debut, date_fin nullable                     | Contrainte simple (NOT NULL / nullable)        |
| RG-M02 | Mission mobilise ≥ 1 satellite, satellite dans plusieurs missions     | Association N‑N via PARTICIPATION                              | Structure relationnelle (association N‑N)       |
| RG-M03 | Rôle du satellite dans chaque mission                                | Attribut role_satellite dans PARTICIPATION                     | Structure relationnelle (attribut d’association) |
| RG-M04 | Mission « Terminée » : plus de nouveaux satellites                    | Trigger BEFORE INSERT sur PARTICIPATION                        | Mécanisme procédural (Trigger)                 |

---

[Précédent](02-dictionnaire-complet.md) · [Phase 1](README.md) · [MLD Final](04-mld-final.md)
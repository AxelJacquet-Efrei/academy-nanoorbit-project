# L2-A - Script DDL NanoOrbit

**Module** : ALTN83 - Bases de Donnees Reparties | **Phase** : 2 - Schema Oracle & Triggers

**Script** : [L2-A-ddl.sql](../../../src/phase-2/L2-A-ddl.sql)

---

## Objectif

Creer les 11 tables du schema NanoOrbit dans l'ordre strict impose par les dependances de cles
etrangeres, avec toutes les contraintes Oracle (PK, FK, CHECK, UNIQUE, NOT NULL) et les commentaires
justificatifs.

---

## Ordre de creation et justification (Q1 implique)

| # | Table | Depend de | Justification |
|---|-------|-----------|---------------|
| 1 | ORBITE | -- | Aucune FK -- referentiel autonome |
| 2 | SATELLITE | ORBITE | FK `id_orbite` -> ORBITE -- RG-S02 |
| 3 | HISTORIQUE_STATUT | SATELLITE | FK `id_satellite` -> SATELLITE -- peuplee par T5 |
| 4 | INSTRUMENT | -- | Catalogue autonome -- RG-I01 |
| 5 | EMBARQUEMENT | SATELLITE, INSTRUMENT | FK vers les deux -- PK composite (E6) |
| 6 | CENTRE_CONTROLE | -- | Aucune FK |
| 7 | STATION_SOL | -- | Aucune FK -- independante de CENTRE (via AFFECTATION) |
| 8 | AFFECTATION_STATION | CENTRE_CONTROLE, STATION_SOL | FK vers les deux -- RG-G04 |
| 9 | MISSION | -- | Aucune FK |
| 10 | FENETRE_COM | SATELLITE, STATION_SOL | FK NOT NULL vers les deux -- RG-F01 |
| 11 | PARTICIPATION | SATELLITE, MISSION | FK vers les deux -- PK composite (E6) |

---

## Reponses aux questions de reflexion du CDC

### Q1 -- Pourquoi ne peut-on pas creer SATELLITE avant ORBITE ?

SATELLITE declare `id_orbite VARCHAR2(20) REFERENCES ORBITE(id_orbite)`. Oracle resout les FK au
moment du `CREATE TABLE` : si ORBITE n'existe pas encore, Oracle leve `ORA-00942 table or view does
not exist`. L'ordre est donc impose par la dependance referentielle, qui traduit la regle **RG-S02** :
tout satellite est place sur une orbite definie.

### Q2 -- La regle RG-S06 peut-elle etre verifiee au niveau DDL seul ?

Pour rappel RG-S06 : "Un satellite desorbite ne peut pas avoir de fenetre de communication planifiee ou realisee, ni de participation a une mission active".
La règle est un before insert.

Non. Un `CHECK` ne peut pas interroger d'autres tables (restriction Oracle DDL). Un CHECK comme
`CHECK (statut != 'Desorbite')` sur SATELLITE n'empeche pas d'inserer une ligne dans FENETRE_COM
ou PARTICIPATION pour un satellite deja desorbite. **Solution** : trigger T1
(`trg_valider_fenetre`) `BEFORE INSERT ON FENETRE_COM` qui interroge SATELLITE au moment de
l'insertion.

### Q3 -- Comment implementer RG-F02 (pas de chevauchement) ?

La regle RG-F02 impose que les fenetres de communication d'un meme satellite et d'une meme station ne se chevauchent pas. Par exemple, si une fenetre est planifiee de 10:00 a 10:15, aucune autre fenetre pour le meme satellite et la meme station ne peut etre planifiee ou realisee entre 10:00 et 10:15.

Impossible en CHECK (pas d'acces aux autres lignes). La seule approche DDL envisageable serait
une contrainte EXCLUDE (non disponible en Oracle). **Solution** : trigger T2
(`trg_no_chevauchement`) `BEFORE INSERT OR UPDATE ON FENETRE_COM`, qui calcule le chevauchement
par intersection d'intervalles temporels via des fonctions auxiliaires
(`PRAGMA AUTONOMOUS_TRANSACTION` pour eviter ORA-04091).

### Q4 -- Quel type Oracle pour format_cubesat ?

`VARCHAR2(5)` avec `CONSTRAINT CHECK (format_cubesat IN ('1U','3U','6U','12U'))`. Oracle ne
dispose pas d'un type ENUM natif (contrairement a PostgreSQL ou MySQL). En Oracle 23ai, la
fonctionnalite `CREATE DOMAIN` permet de definir un domaine reutilisable, mais un CHECK reste la
solution la plus portable et la plus lisible pour ce cas. `VARCHAR2(5)` couvre la valeur maximale
'12U' (3 caracteres).

---

## Exigences respectees (CDC Phase 2 section 2.2)

| Ref. | Exigence | Implementation |
|------|----------|----------------|
| E1 | Tous NOT NULL sauf `date_fin` (MISSION) et `volume_donnees` (FENETRE_COM) | Attribut `DATE` nullable dans MISSION, `NUMBER(8,1)` nullable dans FENETRE_COM |
| E2 | Statuts via CHECK | `ck_sat_statut`, `ck_sat_format`, `ck_emb_etat`, `ck_station_statut`, `ck_centre_statut`, `ck_mission_statut`, `ck_fenetre_statut` |
| E3 | UNIQUE (altitude, inclinaison) dans ORBITE | `CONSTRAINT uq_orbite_alt_incl UNIQUE (altitude, inclinaison)` -- RG-O02 |
| E4 | CHECK duree FENETRE_COM BETWEEN 1 AND 900 | `CONSTRAINT ck_fenetre_duree CHECK (duree BETWEEN 1 AND 900)` -- RG-F04 |
| E5 | Toutes FK ON DELETE RESTRICT | Comportement par defaut Oracle (pas de CASCADE) |
| E6 | PK composites dans EMBARQUEMENT et PARTICIPATION | `PRIMARY KEY (id_satellite, ref_instrument)` et `PRIMARY KEY (id_satellite, id_mission)` |

---

## Variantes justifiees par rapport au CDC

| Element | CDC (section 2.x) | Choix retenu | Justification |
|---------|-------------------|--------------|---------------|
| `id_orbite` | NUMBER (AI) | VARCHAR2(20) | Annexe A utilise 'ORB-001' : chaine alphanumerique |
| `id_centre` | NUMBER (AI) | VARCHAR2(20) | Annexe A utilise 'CTR-001' : chaine alphanumerique |
| Ordre HISTORIQUE_STATUT | Apres SATELLITE | Position 3 | Respect dependance FK + specification CDC Phase 2 section 2.4 |

---

## Idempotence

Le script commence par des blocs `BEGIN EXECUTE IMMEDIATE 'DROP TABLE ... CASCADE CONSTRAINTS' EXCEPTION WHEN OTHERS THEN NULL END` pour chaque table. Cela permet de relancer le script sans erreur sur un schema existant, en detruisant toutes les tables et leurs contraintes.

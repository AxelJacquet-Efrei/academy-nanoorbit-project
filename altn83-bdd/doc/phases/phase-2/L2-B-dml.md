# L2-B - Script DML NanoOrbit

**Module** : ALTN83 - Bases de Donnees Reparties | **Phase** : 2 - Schema Oracle & Triggers

**Script** : [L2-B-dml.sql](../../../src/phase-2/L2-B-dml.sql)

---

## Objectif

Inserer le jeu de donnees de reference NanoOrbit (Annexe A v1.0 2025-2026) dans les 10 tables du
schema, dans l'ordre strict des dependances FK, puis valider l'ensemble par un `COMMIT` final.

---

## Prerequis

Ce script doit etre execute **apres** L2-A-ddl.sql et **avant** L2-C-triggers.sql.

> Les triggers T1, T4 bloqueraient certaines insertions historiques du jeu de reference :
> - T1 bloquerait SAT-005 (Desorbite) dans FENETRE_COM
> - T4 bloquerait l'ajout de satellites dans MSN-DEF-2022 (Terminee)
> Ces donnees sont valides historiquement et font partie du referentiel officiel.

---

## Recapitulatif des insertions

| # | Table | Nb lignes | Notes |
|---|-------|-----------|-------|
| 1 | ORBITE | 3 | SSO x2, LEO x1 |
| 2 | SATELLITE | 5 | Operationnel x3, En veille x1, Desorbite x1 |
| 3 | HISTORIQUE_STATUT | 0 | Aucun INSERT manuel -- trigger T5 uniquement |
| 4 | INSTRUMENT | 4 | INS-AIS-01 resolution NULL |
| 5 | EMBARQUEMENT | 7 | Nominal x5, Degrade x1, Hors service x1 |
| 6 | CENTRE_CONTROLE | 2 | CTR-001 Paris, CTR-002 Houston |
| 7 | STATION_SOL | 3 | Active x2, Maintenance x1 (GS-SGP-01) |
| 8 | AFFECTATION_STATION | 3 | PK composite |
| 9 | MISSION | 3 | Active x2, Terminee x1 |
| 10 | FENETRE_COM | 5 | Realisee x3, Planifiee x2 |
| 11 | PARTICIPATION | 7 | Roles varies |
| **Total** | | **39 lignes** | |

---

## Points metier notables

### FENETRE_COM -- id_fenetre non specifie

`id_fenetre` est declare `GENERATED ALWAYS AS IDENTITY`. Il ne doit pas etre specifie dans les
`INSERT INTO`. Oracle genere automatiquement la sequence 1, 2, 3, 4, 5. Les identifiants generes
seront stables tant que la table n'est pas droppee et recrée.

### FENETRE_COM -- Verification des plages horaires (RG-F02, RG-F03)

Le jeu de reference ne comporte aucun chevauchement (condition necessaire pour que L2-B passe
apres activation de T2). Verification par satellite et par station :

| id_fenetre | Satellite | Station | Debut | Fin (approx.) |
|------------|-----------|---------|-------|---------------|
| 1 | SAT-001 | GS-KIR-01 | 2024-01-15 09:14 | 09:21:00 (+420s) |
| 2 | SAT-002 | GS-TLS-01 | 2024-01-15 11:52 | 11:57:10 (+310s) |
| 3 | SAT-003 | GS-KIR-01 | 2024-01-16 08:30 | 08:39:00 (+540s) |
| 4 | SAT-001 | GS-TLS-01 | 2024-01-20 14:22 | 14:28:20 (+380s) |
| 5 | SAT-003 | GS-TLS-01 | 2024-01-21 07:45 | 07:49:50 (+290s) |

Aucun chevauchement satellite (chaque satellite n'apparait qu'une fois par journee) ni station
(GS-KIR-01 : jours differents, GS-TLS-01 : jours differents).

### PARTICIPATION -- SAT-005 dans MSN-DEF-2022

SAT-005 (Desorbite) apparait dans PARTICIPATION avec la mission MSN-DEF-2022 (Terminee). Cette
combinaison est historiquement valide : SAT-005 etait Operationnel pendant la mission, et la mission
s'est terminee avant que le satellite ne soit Desorbite. C'est un cas de test cle pour le trigger T4 :
apres activation, on ne peut PLUS ajouter ce satellite a une autre mission.

### MISSION -- date_fin NULL pour les missions actives

Conforme a la regle RG-M01 (E1) : `date_fin` est nullable. Les missions Active ont `date_fin = NULL`.
La mission Terminee (MSN-DEF-2022) a `date_fin = DATE '2023-05-31'`.

### STATION_SOL -- GS-SGP-01 en Maintenance

GS-SGP-01 est deliberement inseree avec le statut `Maintenance` pour tester le trigger T1 (RG-G03).
Apres activation de T1, toute tentative d'insertion d'une fenetre vers cette station sera bloquee.

---

## Lien avec les donnees source

Jeu de reference complet : [Annexe B - Donnees Reference](../../../sujets/ALTN83_NanoOrbit_AnnexeB_Donnees_Reference.pdf)

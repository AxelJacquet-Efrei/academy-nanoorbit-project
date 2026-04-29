# L2-C - Triggers Metier NanoOrbit

**Module** : ALTN83 - Bases de Donnees Reparties | **Phase** : 2 - Schema Oracle & Triggers

**Script** : [L2-C-triggers.sql](../../../src/phase-2/L2-C-triggers.sql)

---

## Objectif

Implementer les 5 triggers metier qui couvrent les regles de gestion **non exprimables** par des
contraintes DDL statiques (NOT NULL, CHECK, UNIQUE, FK).

---

## Prerequis

- L2-A-ddl.sql execute (schema present)
- L2-B-dml.sql execute (donnees de reference inserees)

---

## Synthese des 5 triggers

| ID | Nom | Niveau | Evenement | Regles | Code erreur |
|----|-----|--------|-----------|--------|-------------|
| T1 | trg_valider_fenetre | 1 | BEFORE INSERT ON FENETRE_COM | RG-S06, RG-G03 | -20001, -20004 |
| T2 | trg_no_chevauchement | 1 | BEFORE INSERT OR UPDATE ON FENETRE_COM | RG-F02, RG-F03 | -20002, -20003 |
| T3 | trg_volume_realise | 1 | BEFORE INSERT OR UPDATE ON FENETRE_COM | RG-F05 | -- (correction silencieuse) |
| T4 | trg_mission_terminee | 2 | BEFORE INSERT ON PARTICIPATION | RG-M04, RG-S06 | -20005, -20006 |
| T5 | trg_historique_statut | 2 | AFTER UPDATE OF statut ON SATELLITE | RG-S06 tracabilite | -- (audit) |

---

## Detail par trigger

### T1 -- trg_valider_fenetre

**Regle** : RG-S06 + RG-G03

**Logique** :
1. Lire `statut` du satellite dans SATELLITE
2. Si `statut = 'Desorbite'` -> erreur ORA-20001
3. Lire `statut` de la station dans STATION_SOL
4. Si `statut = 'Maintenance'` -> erreur ORA-20004

**Cas de test** :
| Scenario | Satellite | Station | Attendu |
|----------|-----------|---------|---------|
| Valide | SAT-001 (Operationnel) | GS-KIR-01 (Active) | Insertion OK |
| Erreur RG-S06 | SAT-005 (Desorbite) | GS-TLS-01 | ORA-20001 |
| Erreur RG-G03 | SAT-001 | GS-SGP-01 (Maintenance) | ORA-20004 |

---

### T2 -- trg_no_chevauchement

**Regle** : RG-F02 (satellite) + RG-F03 (station)

**Principe du chevauchement** : deux intervalles [A, A+durA) et [B, B+durB) se chevauchent si et
seulement si : `A < B+durB ET B < A+durA`. Implementation via `NUMTODSINTERVAL(duree, 'SECOND')`.

**Probleme technique -- ORA-04091 (table mutante)** :
Un trigger `BEFORE INSERT FOR EACH ROW` sur FENETRE_COM ne peut pas interroger FENETRE_COM car
la table est en cours de modification. Oracle leve `ORA-04091: table FENETRE_COM is mutating`.

**Solution retenue** : deux fonctions auxiliaires avec `PRAGMA AUTONOMOUS_TRANSACTION` :
- `fn_overlap_satellite(p_satellite, p_debut, p_duree, p_excl_id)` -- RG-F02
- `fn_overlap_station(p_station, p_debut, p_duree, p_excl_id)` -- RG-F03

Ces fonctions ouvrent une transaction autonome et lisent l'etat **commite** de FENETRE_COM (avant le
DML en cours), ce qui est exactement l'etat reference pour detecter les chevauchements existants.

**Gestion UPDATE** : pour un UPDATE, il faut exclure la fenetre en cours de modification (`p_excl_id
= :OLD.id_fenetre`). Pour un INSERT, `p_excl_id = -1` (aucune fenetre n'a cet id).

**Cas de test** :
| Scenario | Satellite | Station | Debut | Duree | Attendu |
|----------|-----------|---------|-------|-------|---------|
| Valide | SAT-002 | GS-KIR-01 | 2024-01-16 10:00 | 300s | Insertion OK |
| Erreur RG-F02 | SAT-001 | GS-TLS-01 | 2024-01-15 09:20 | 200s | ORA-20002 (chevauche fenetre 1) |
| Erreur RG-F03 | SAT-003 | GS-TLS-01 | 2024-01-15 11:55 | 200s | ORA-20003 (chevauche fenetre 2) |

---

### T3 -- trg_volume_realise

**Regle** : RG-F05

**Logique** : si `:NEW.statut != 'Realisee'` et `:NEW.volume_donnees IS NOT NULL`, alors forcer
`:NEW.volume_donnees := NULL` (correction silencieuse avec message `DBMS_OUTPUT`). Ce comportement
defensif est preferable a un blocage car il permet de saisir `Planifiee` avec un volume sans echec,
tout en garantissant la coherence du modele.

**Cas de test** :
| Scenario | Statut | Volume | Attendu |
|----------|--------|--------|---------|
| Valide | Planifiee | NULL | Insertion OK, volume = NULL |
| Correction T3 | Planifiee | 500 | Insertion OK, volume force a NULL (message T3 affiche) |

---

### T4 -- trg_mission_terminee

**Regles** : RG-M04 + RG-S06

**Logique** :
1. Lire `statut_mission` dans MISSION. Si `statut_mission = 'Terminee'` → erreur ORA-20005
2. Lire `statut` du satellite dans SATELLITE. Si `statut = 'Desorbite'` → erreur ORA-20006

**Pourquoi RG-S06 est ici et pas seulement dans T1** : la regle RG-S06 stipule qu'un satellite
Désorbité ne peut plus "participer à une nouvelle mission **ni** générer de nouvelles fenêtres".
T1 couvre FENETRE_COM ; T4 couvre PARTICIPATION — les deux ensemble satisfont RG-S06 entièrement.

**Données de référence** : SAT-005 (Désorbité) participe à MSN-DEF-2022 dans L2-B.
Cette insertion est valide car L2-B s'exécute **avant** L2-C (triggers). Une fois T4 actif,
toute nouvelle participation de SAT-005 est bloquée (RG-S06), de même que tout ajout à
MSN-DEF-2022 (RG-M04).

**Cas de test** :
| Scenario | Satellite | Mission | Attendu |
|----------|-----------|---------|---------|
| Valide | SAT-004 | MSN-ARC-2023 (Active) | Insertion OK |
| Erreur RG-M04 | SAT-002 | MSN-DEF-2022 (Terminee) | ORA-20005 |
| Erreur RG-S06 | SAT-005 (Desorbite) | MSN-ARC-2023 (Active) | ORA-20006 |

---

### T5 -- trg_historique_statut

**Regle** : RG-S06 (traçabilite)

**Logique** : apres chaque `UPDATE` du champ `statut` sur SATELLITE, si `:OLD.statut != :NEW.statut`,
inserer une ligne dans HISTORIQUE_STATUT avec l'ancien statut, le nouveau statut et `SYSTIMESTAMP`.

**Type** : `AFTER UPDATE OF statut ON SATELLITE FOR EACH ROW`
- `AFTER` : permet d'inserer dans HISTORIQUE_STATUT apres validation de la modification
- `UPDATE OF statut` : ne se declenche que sur modification de la colonne `statut`

**Verification** : `SELECT * FROM HISTORIQUE_STATUT ORDER BY date_changement DESC;` apres chaque
UPDATE de statut satellite.

**Cas de test** :
| Scenario | Action | Attendu |
|----------|--------|---------|
| Changement de statut | `UPDATE SATELLITE SET statut='Operationnel' WHERE id_satellite='SAT-004'` | 1 ligne inseree dans HISTORIQUE_STATUT |
| Modification hors statut | `UPDATE SATELLITE SET masse=2.01 WHERE id_satellite='SAT-004'` | Aucune ligne dans HISTORIQUE_STATUT |

---

## Codes erreur ORA-20xxx utilises

| Code | Trigger | Regle | Message |
|------|---------|-------|---------|
| -20000 | T1, T4 | -- | Enregistrement introuvable (NO_DATA_FOUND) |
| -20001 | T1 | RG-S06 | Satellite Desorbite -- fenetre impossible |
| -20002 | T2 | RG-F02 | Chevauchement satellite |
| -20003 | T2 | RG-F03 | Chevauchement station |
| -20004 | T1 | RG-G03 | Station en Maintenance |
| -20005 | T4 | RG-M04 | Mission Terminee |
| -20006 | T4 | RG-S06 | Satellite Desorbite -- participation impossible |

---

## Regles non couvertes par les triggers (reportees en Phase 3)

| Code | Regle | Raison du report |
|------|-------|-----------------|
| RG-I03 | Instrument non simultanement sur deux satellites | Contrainte applicative complexe -- Phase 3 |
| RG-I04 | Instrument HS > 30 jours -> satellite a signaler | Procedure PL/SQL -- Phase 3 |


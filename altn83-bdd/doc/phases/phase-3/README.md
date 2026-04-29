# Phase 3 - PL/SQL & Package pkg_nanoOrbit

## Projet NanoOrbit -- CubeSat Earth Observation System
### Module ALTN83 -- Bases de Donnees Reparties | EFREI 2025-2026

**Statut** : Termine  
**Prerequis** : Phases 1 et 2 validees, triggers T1-T5 operationnels

---

## Vue d'ensemble

La Phase 3 implemente les 16 exercices PL/SQL progressifs (Paliers 1 a 5) et le package
`pkg_nanoOrbit` (Palier 6 - Niveau Excellence). Elle couvre :

- Les **blocs anonymes**, variables `%TYPE`/`%ROWTYPE`, structures de controle et curseurs (L3-A)
- Les **procédures et fonctions standalone** (Ex. 14-16, socle Palier 5)
- La **SPEC** du package `pkg_nanoOrbit` avec 7 sous-programmes publics (L3-B)
- Le **BODY** du package avec implementations completes et gestion des exceptions (L3-C)
- Le **scenario de validation** en 7 etapes avec tests des cas d'erreur (L3-D)

---

## Arborescence

```
altn83-bdd/
├── src/
│   └── phase-3/
│       ├── L3-A-paliers-1-5.sql   <- Ex. 1-16 + procedures/fonctions standalone
│       ├── L3-B-spec-pkg.sql      <- SPEC pkg_nanoOrbit (interface publique)
│       ├── L3-C-body-pkg.sql      <- BODY pkg_nanoOrbit (implementations)
│       └── L3-D-validation.sql    <- Scenario validation + cas d'erreur + ROLLBACK
└── doc/
    └── phases/
        └── phase-3/
            ├── README.md               <- Ce fichier (sommaire Phase 3)
            ├── L3-A-paliers-1-5.md     <- Documentation des 16 exercices
            ├── L3-B-spec-pkg.md        <- Documentation SPEC pkg_nanoOrbit
            ├── L3-C-body-pkg.md        <- Documentation BODY pkg_nanoOrbit
            └── L3-D-validation.md      <- Documentation scenario de validation
```

---

## Correspondance avec les livrables attendus (CDC Phase 3 section 3.5)

| Ref. | Livrable demande | Script fourni | Documentation |
|------|-----------------|---------------|---------------|
| L3-A | Script Paliers 1-5 (Ex. 1-16) | [L3-A-paliers-1-5.sql](../../../src/phase-3/L3-A-paliers-1-5.sql) | [L3-A-paliers-1-5.md](L3-A-paliers-1-5.md) |
| L3-B | Script SPEC pkg_nanoOrbit | [L3-B-spec-pkg.sql](../../../src/phase-3/L3-B-spec-pkg.sql) | [L3-B-spec-pkg.md](L3-B-spec-pkg.md) |
| L3-C | Script BODY pkg_nanoOrbit | [L3-C-body-pkg.sql](../../../src/phase-3/L3-C-body-pkg.sql) | [L3-C-body-pkg.md](L3-C-body-pkg.md) |
| L3-D | Script de validation | [L3-D-validation.sql](../../../src/phase-3/L3-D-validation.sql) | [L3-D-validation.md](L3-D-validation.md) |

---

## Ordre d'exécution

```
L2-A-ddl.sql   → L2-B-dml.sql   → L2-C-triggers.sql
     ↓
L3-A-paliers-1-5.sql   (Ex.1–16 + CREATE PROCEDURE/FUNCTION standalone)
     ↓
L3-B-spec-pkg.sql      (CREATE OR REPLACE PACKAGE pkg_nanoOrbit AS ...)
     ↓
L3-C-body-pkg.sql      (CREATE OR REPLACE PACKAGE BODY pkg_nanoOrbit AS ...)
     ↓
L3-D-validation.sql    (scénario + cas d'erreur + vérification état final)
```

> **Attention** : La SPEC (L3-B) doit compiler sans erreur avant d'exécuter le BODY (L3-C).  
> Vérifier avec `SHOW ERRORS` après chaque `CREATE OR REPLACE`.

---

## Détail des paliers

### Palier 1 -Bloc anonyme
| Ex. | Description | Résultat attendu |
|-----|-------------|-----------------|
| 1 | Message de bienvenue + COUNT satellites/stations/missions | 5 sats, 3 stations, 3 missions |
| 2 | `SELECT INTO` sur SAT-001 | Toutes les colonnes de NanoOrbit-Alpha |

### Palier 2 -Variables et types
| Ex. | Description | Résultat attendu |
|-----|-------------|-----------------|
| 3 | `%ROWTYPE` sur SATELLITE (SAT-001) | Statut + batterie affichés |
| 4 | `NVL` sur résolution instrument | `INS-AIS-01` → `N/A (non applicable)` |

### Palier 3 -Structures de contrôle
| Ex. | Description | Résultat attendu |
|-----|-------------|-----------------|
| 5 | `IF/ELSIF` -catégorisation par statut + durée de vie restante | SAT-001/SAT-002 → "Actif - autonomie limitée" (~11 mois) |
| 6 | `CASE` -type d'orbite + vitesse orbitale | ORB-001 SSO → ~7592 m/s |
| 7 | `FOR` loop -grille volumes GS-TLS-01 (5–15 min) | 5 min → 5625 Mo … 15 min → 16875 Mo |

### Palier 4 -Curseurs
| Ex. | Description | Résultat attendu |
|-----|-------------|-----------------|
| 8 | `SQL%ROWCOUNT` -mise en veille ORB-001 | 2 lignes modifiées + ROLLBACK |
| 9 | Cursor FOR Loop -satellites avec orbite et instruments | Listing complet SAT-001..SAT-005 |
| 10 | Curseur explicite `OPEN/FETCH/CLOSE` -dernière fenêtre par satellite opérationnel | 3 satellites, dernière fenêtre chacun |
| 11 | Curseur paramétré -fenêtres GS-KIR-01 + volume total | Fenetres 1 et 3, total 2930 Mo |

### Palier 5 -Procédures et fonctions standalone (Socle)
| Ex. | Nom | Description |
|-----|-----|-------------|
| 12 | Bloc anonyme | `SELECT INTO` sécurisé avec `NO_DATA_FOUND` + `OTHERS` |
| 13 | Bloc anonyme | `RAISE_APPLICATION_ERROR` -validation fenêtre avant insertion |
| 14 | `afficher_statut_satellite(p_id IN)` | Statut, orbite, instruments embarqués |
| 15 | `mettre_a_jour_statut(p_id, p_statut, p_ancien OUT)` | Mise à jour + retour ancien statut |
| 16 | `calculer_volume_session(p_id_fenetre) RETURN NUMBER` | Volume théorique = (débit/8) × durée |

---

## Package pkg_nanoOrbit

### Interface publique (SPEC)

```sql
TYPE t_stats_satellite IS RECORD (
    nb_fenetres        NUMBER,
    volume_total       NUMBER,
    duree_moy_secondes NUMBER
);

c_statut_min_fenetre  CONSTANT VARCHAR2(30) := 'Operationnel';
c_duree_max_fenetre   CONSTANT NUMBER       := 900;
c_seuil_revision      CONSTANT NUMBER       := 50;
```

| Sous-programme | Signature | Description |
|---|---|---|
| `planifier_fenetre` | `(sat, sta, debut, duree, id_out)` | INSERT FENETRE_COM -déclenche T1, T2, T3 |
| `cloturer_fenetre` | `(id_fen, volume)` | UPDATE statut=Realisee + volume |
| `affecter_satellite_mission` | `(sat, mission, role)` | INSERT PARTICIPATION -déclenche T4 |
| `mettre_en_revision` | `(sat)` | UPDATE statut=Defaillant -déclenche T5 |
| `calculer_volume_theorique` | `(id_fen) RETURN NUMBER` | (débit/8) × durée en Mo |
| `statut_constellation` | `RETURN VARCHAR2` | Résumé textuel de la constellation |
| `stats_satellite` | `(sat) RETURN t_stats_satellite` | Indicateurs fenêtres réalisées |

### Codes d'erreur du package

| Code | Procédure | Signification |
|------|-----------|---------------|
| -20100 | planifier_fenetre | Durée hors domaine [1..900] |
| -20101 | planifier_fenetre | Satellite ou station introuvable |
| -20110 | cloturer_fenetre | Fenêtre introuvable |
| -20111 | cloturer_fenetre | Fenêtre déjà cloturée |
| -20112 | cloturer_fenetre | Volume invalide (≤ 0) |
| -20120 | affecter_satellite_mission | Participation déjà existante |
| -20130 | mettre_en_revision | Satellite introuvable |
| -20131 | mettre_en_revision | Satellite déjà Défaillant/Désorbité |
| -20140 | calculer_volume_theorique | Fenêtre introuvable |
| -20150 | stats_satellite | Satellite introuvable |
| -20001…-20006 | *(triggers T1–T4)* | Héritage Phase 2 |

---

## Scénario de validation (L3-D)

Le script orchestre 7 étapes dans une seule transaction :

1. **planifier_fenetre** -SAT-001 → GS-KIR-01, 2024-03-01 10:00, 450 s → id=6
2. **cloturer_fenetre** -Fenêtre 6 → Réalisée, 1500 Mo
3. **affecter_satellite_mission** -SAT-004 → MSN-ARC-2023, "Satellite de relais"
4. **stats_satellite** -SAT-001 : 2 fenêtres | 2750 Mo | 435 s moy
5. **statut_constellation** -"3/5 satellites opérationnels, 2 missions actives, 4 fenêtres réalisées"
6. **calculer_volume_theorique** -Fenêtre 6 : (400/8) × 450 = 22500 Mo
7. **mettre_en_revision** -SAT-004 : "En veille" → "Défaillant" (T5 journalise)

**ROLLBACK final** pour restaurer le jeu de données de référence.

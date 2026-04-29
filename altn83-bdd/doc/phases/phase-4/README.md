# Phase 4 : Vues, Analytiques et Optimisation

## Objectif

Exploiter pleinement Oracle 23ai par la création de vues (simples, complexes, matérialisées), l'écriture de requêtes analytiques avancées (CTEs, fonctions de fenêtrage, MERGE INTO) et l'optimisation des accès par index stratégiques avec analyse des plans d'exécution.

---

## Statut

**Terminé**

---

## Prérequis

Les phases 1, 2 et 3 doivent être exécutées avant cette phase (`L2-A` -> `L2-B` -> `L2-C` -> `L3-A` -> `L3-B` -> `L3-C`).

---

## Scripts

| Fichier | Contenu | Exercices |
|---|---|---|
| [`L4-A-vues.sql`](../../../src/phase-4/L4-A-vues.sql) | Vues simples, complexe, agrégats, vue matérialisée | V1–V4 |
| [`L4-B-cte-sousrequetes.sql`](../../../src/phase-4/L4-B-cte-sousrequetes.sql) | CTEs simple/multiple/récursive, sous-requêtes scalaire/corrélée/EXISTS | Ex.5–10 |
| [`L4-C-analytiques-merge.sql`](../../../src/phase-4/L4-C-analytiques-merge.sql) | ROW_NUMBER/RANK/DENSE_RANK, LAG/LEAD, SUM cumulatif, MERGE INTO | Ex.11–16 |
| [`L4-D-index-explain.sql`](../../../src/phase-4/L4-D-index-explain.sql) | Index stratégiques, EXPLAIN PLAN avant/après, index invisible, rapport de pilotage | Ex.17–19 + Rapport |

---

## Contenu détaillé

### L4-A - Vues (V1–V4)

#### V1 - `v_satellites_operationnels` (vue simple filtrée)
Satellites en statut `Operationnel` avec leur orbite et le nombre d'instruments embarqués.
- Jointure : `SATELLITE` -> `ORBITE` + `LEFT JOIN EMBARQUEMENT`
- Filtre : `WHERE statut = 'Operationnel'`
- Résultat attendu : 3 lignes (SAT-001, SAT-002, SAT-003)

#### V2 - `v_fenetres_detail` (vue jointure dénormalisée)
Créneaux de communication avec noms complets satellite, station, centre et durée formatée (`MM min SS s`).
- 4 jointures : `FENETRE_COM` -> `SATELLITE` + `STATION_SOL` -> `AFFECTATION_STATION` -> `CENTRE_CONTROLE`
- Résultat attendu : 5 lignes (toutes via CTR-001 Paris - GS-SGP-01 en Maintenance)

#### V3 - `v_stats_missions` (vue avec agrégats)
Statistiques par mission : nb satellites, types d'orbites (`LISTAGG DISTINCT`), volume total téléchargé.
- `LISTAGG(DISTINCT o.type_orbite, ', ') WITHIN GROUP (ORDER BY o.type_orbite)`
- Résultat attendu : MSN-ARC-2023 = 3820 Mo, MSN-COAST-2024 = 1680 Mo, MSN-DEF-2022 = 1250 Mo

#### V4 - `mv_volumes_mensuels` (vue matérialisée REFRESH ON DEMAND)
Volumes téléchargés par mois, centre de contrôle et format CubeSat.
- `CREATE MATERIALIZED VIEW ... REFRESH ON DEMAND`
- Groupement sur `TRUNC(datetime_debut, 'MM')` + `format_cubesat`
- Rafraîchissement : `DBMS_MVIEW.REFRESH('MV_VOLUMES_MENSUELS', method => 'C')`
- Résultat attendu : 2 lignes (2024-01, CTR-001, 3U : 2140 Mo ; 6U : 1680 Mo)

---

### L4-B - CTEs et Sous-requêtes (Ex.5–10)

| Ex. | Type | Description | Résultat clé |
|---|---|---|---|
| 5 | CTE simple | Top 3 satellites par volume téléchargé | SAT-003 (1680), SAT-001 (1250), SAT-002 (890) |
| 6 | CTEs multiples | Classement stations par centre avec RANK | GS-KIR-01 top station CTR-001 |
| 7 | CTE récursive | Hiérarchie Centre -> Station -> Fenêtre (3 niveaux) | 6 nœuds, LPAD pour indentation |
| 8 | Sous-requête scalaire | Fenêtres au-dessus de la moyenne (1273.3 Mo) | Seule fenêtre 3 (1680 Mo, écart +406.7) |
| 9 | Sous-requête corrélée | Dernière fenêtre réalisée par satellite | SAT-004 et SAT-005 : NULL |
| 10 | EXISTS / NOT EXISTS | Satellites sans fenêtre + stations sans activité Q1 2024 | SAT-004, SAT-005 ; GS-SGP-01 |

---

### L4-C - Analytiques et MERGE INTO (Ex.11–16)

| Ex. | Fonction / Instruction | Description |
|---|---|---|
| 11 | `ROW_NUMBER`, `RANK`, `DENSE_RANK` | Classement satellites par volume global et par type d'orbite |
| 12 | `LAG`, `LEAD` | Évolution fenêtre précédente/suivante par station, calcul % évolution |
| 13 | `SUM OVER ... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | Volume cumulé par centre + moyenne mobile sur 3 fenêtres |
| 14 | Dashboard CTE + analytics | % volume par mois, rang, cumul, écart vs moyenne |
| 15 | `MERGE INTO SATELLITE` | Sync 3 lignes source : mise à jour SAT-001/SAT-004, insertion SAT-NEW-001 - ROLLBACK |
| 16 | `MERGE INTO AFFECTATION_STATION` | Création CTR-003 Singapour + sync 4 affectations stations - ROLLBACK |

---

### L4-D - Index et EXPLAIN PLAN (Ex.17–19 + Rapport)

#### Ex.17 - 11 index stratégiques créés

> ¹ **Note CDC** : le sujet demande un index composite `(statut, type_orbite)` sur SATELLITE, mais `type_orbite` est une colonne de `ORBITE`, pas de `SATELLITE` - un index ne peut couvrir que les colonnes de sa propre table. Deux index ont donc été créés en lieu et place : `idx_sat_statut_format` sur `SATELLITE(statut, format_cubesat)` (composite pertinent dans SATELLITE) et `idx_orb_type` sur `ORBITE(type_orbite)` (couvre l'intention analytique du CDC).

| Index | Table | Colonne(s) | Type | Justification |
|---|---|---|---|---|
| `idx_fc_satellite` | `FENETRE_COM` | `id_satellite` | B-Tree | FK non couverte par PK |
| `idx_fc_station` | `FENETRE_COM` | `code_station` | B-Tree | FK non couverte par PK |
| `idx_part_mission` | `PARTICIPATION` | `id_mission` | B-Tree | FK non couverte par PK |
| `idx_hist_satellite` | `HISTORIQUE_STATUT` | `id_satellite` | B-Tree | FK non couverte par PK |
| `idx_aff_station` | `AFFECTATION_STATION` | `code_station` | B-Tree | FK non couverte par PK |
| `idx_sat_statut` | `SATELLITE` | `statut` | B-Tree | Filtre `WHERE statut = 'Operationnel'` omniprésent |
| `idx_fc_statut` | `FENETRE_COM` | `statut` | B-Tree | Filtre `WHERE statut = 'Realisee'` omniprésent |
| `idx_fc_datetime` | `FENETRE_COM` | `datetime_debut` | B-Tree | Tri chronologique et filtres temporels |
| `idx_sat_statut_format` | `SATELLITE` | `statut, format_cubesat` | Composite | Requêtes filtrant ET groupant sur les deux colonnes (note CDC¹) |
| `idx_orb_type` | `ORBITE` | `type_orbite` | B-Tree | `PARTITION BY type_orbite` analytiques (Ex.11, Ex.14) - esprit CDC¹ |
| `idx_fc_mois` | `FENETRE_COM` | `TRUNC(datetime_debut, 'MM')` | Fonctionnel | Groupements mensuels (MView, rapport) |

#### Ex.18 - EXPLAIN PLAN avant/après `idx_fc_mois`
- **Avant** (index invisible) : `TABLE ACCESS FULL` sur `FENETRE_COM` pour le regroupement mensuel
- **Après** (index visible) : possibilité d'`INDEX RANGE SCAN` sur `idx_fc_mois` ; sur petit jeu de données Oracle peut conserver TABLE FULL (coût similaire)
- La comparaison des deux plans est stockée dans `PLAN_TABLE` (`PLAN_AVANT` / `PLAN_APRES`)

#### Ex.19 - Test index invisible sur `idx_sat_statut`
1. `ALTER INDEX idx_sat_statut INVISIBLE` -> plan : `TABLE ACCESS FULL`
2. `ALTER SESSION SET OPTIMIZER_USE_INVISIBLE_INDEXES = TRUE` -> plan session : `INDEX RANGE SCAN` (sans impacter les autres sessions)
3. `ALTER INDEX idx_sat_statut VISIBLE` -> rétablissement production

#### Rapport de pilotage intégral
Requête finale combinant CTE + analytiques + `mv_volumes_mensuels` :
- **Section A** : classement centres par volume avec `RANK`, `LAG`, % global
- **Section B** : activité par satellite - volume cumulé (`SUM OVER ROWS UNBOUNDED PRECEDING`), rang global, rang par orbite, % part, écart vs moyenne
- **Section C** : synthèse missions actives - satellites, volumes, `RANK`, % volume total
- **Section D** : vue mensuelle enrichie depuis `mv_volumes_mensuels` avec `RANK` et % par mois

---

## Règles de gestion couvertes

| Règle | Description | Couverture |
|---|---|---|
| RG-S06 | Seuls les satellites `Operationnel` sont inclus dans les vues opérationnelles | V1 |
| RG-F05 | Pas de `volume_donnees` pour une fenêtre `Planifiee` | V3, Ex.8, Ex.13 |
| RG-F04 | Durées dans [1, 900] secondes | V2 (`duree_formatee`) |
| RG-T01 | `GS-SGP-01` en Maintenance bloque toute insertion de fenêtre (trigger T1) | Commentaires Ex.10, V2 |

---

## Ordre d'exécution recommandé

```
L4-A-vues.sql
L4-B-cte-sousrequetes.sql
L4-C-analytiques-merge.sql  (se termine par ROLLBACK - pas d'effets persistants)
L4-D-index-explain.sql
```

---

## Liens

- [Scripts Phase 4](../../../src/phase-4/)
- [Phase 3 - PL/SQL](../phase-3/README.md)
- [Index des phases](../README.md)

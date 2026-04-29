# Index des Phases de Développement

Retrouvez ici le suivi détaillé de la conception de la base de données.

---

## Liste des phases

### [Phase 1 : Analyse et Modélisation](phase-1/README.md)
> **Objectif** : Définition du dictionnaire des données et établissement des règles de gestion (RG).
>
> *   **Statut** : Terminé
> *   **Contenu** : Dictionnaire complet (11 tables), MCD MERISE, MLD Oracle 23ai, note de modélisation

### [Phase 2 : Schéma Oracle & Triggers](phase-2/README.md)
> **Objectif** : Implémentation DDL/DML et triggers métier sur Oracle 23ai.
>
> *   **Statut** : Terminé
> *   **Contenu** : 11 tables (L2-A), 39 lignes de référence (L2-B), 5 triggers (L2-C), contrôle (L2-D)
> *   **Scripts** : [`src/phase-2/`](../../src/phase-2/)

### [Phase 3 : PL/SQL & Package pkg_nanoOrbit](phase-3/README.md)
> **Objectif** : Blocs anonymes, curseurs, procédures, fonctions et package Oracle.
>
> *   **Statut** : Terminé
> *   **Contenu** : 16 exercices paliers 1–5 (L3-A), SPEC (L3-B), BODY (L3-C), validation (L3-D)
> *   **Scripts** : [`src/phase-3/`](../../src/phase-3/)

### [Phase 4 : Vues, Analytiques et Optimisation](phase-4/README.md)
> **Objectif** : Vues simples/matérialisées, CTEs récursives, fonctions analytiques, MERGE INTO et optimisation par index.
>
> *   **Statut** : Terminé
> *   **Contenu** : 4 vues (L4-A), CTEs + sous-requêtes Ex.5–10 (L4-B), analytiques + MERGE Ex.11–16 (L4-C), 10 index + EXPLAIN PLAN + rapport de pilotage (L4-D)
> *   **Scripts** : [`src/phase-4/`](../../src/phase-4/)

---

## Liens Utiles

*   [Retour à l’accueil](../README.md)

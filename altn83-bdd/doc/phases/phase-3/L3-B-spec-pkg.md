# L3-B - SPEC du package pkg_nanoOrbit

**Module** : ALTN83 - Bases de Donnees Reparties | **Phase** : 3 - PL/SQL & Package pkg_nanoOrbit

**Script** : [L3-B-spec-pkg.sql](../../../src/phase-3/L3-B-spec-pkg.sql)

---

## Objectif

Creer la specification (interface publique) du package `pkg_nanoOrbit`. La SPEC doit compiler
sans erreur (`SHOW ERRORS = 0`) avant toute implementation du BODY.

La SPEC expose le contrat public du package : types, constantes et signatures des sous-programmes.
Elle ne contient aucune implementation.

---

## Prerequis

- L2-A, L2-B, L2-C executes (schema + donnees + triggers)
- L3-A execute (sous-programmes standalone `afficher_statut_satellite`, `mettre_a_jour_statut`,
  `calculer_volume_session` crees)

---

## Contenu public de la SPEC

### Type t_stats_satellite

Enregistrement retourne par la fonction `stats_satellite`. Contient trois indicateurs
de performance d'un satellite :

```sql
TYPE t_stats_satellite IS RECORD (
    nb_fenetres          NUMBER,   -- Nombre de fenetres realisees
    volume_total         NUMBER,   -- Volume total telecharge (Mo)
    duree_moy_secondes   NUMBER    -- Duree moyenne des fenetres (s)
);
```

### Constantes metier

| Constante | Valeur | Regle | Description |
|-----------|--------|-------|-------------|
| `c_statut_min_fenetre` | `'Operationnel'` | RG-S06 | Statut minimum pour planifier une fenetre |
| `c_duree_max_fenetre` | `900` | RG-F04 | Duree maximale d'une fenetre en secondes |
| `c_seuil_revision` | `50` | RG-I04 | Seuil de fenetres declenchant une revision preventive |

### Signatures des sous-programmes

#### PROCEDURE planifier_fenetre

```sql
PROCEDURE planifier_fenetre(
    p_id_satellite   IN  VARCHAR2,
    p_code_station   IN  VARCHAR2,
    p_datetime_debut IN  TIMESTAMP,
    p_duree          IN  NUMBER,
    p_id_fenetre     OUT NUMBER
);
```

Cree une nouvelle fenetre (statut `Planifiee`). Declenche T1, T2 et T3 via le `INSERT`.
Retourne l'identifiant auto-incremente via `RETURNING INTO`.

**Codes erreur** : -20100 (duree hors [1..900]), -20101 (FK violation).
Les triggers peuvent lever -20001 a -20004.

#### PROCEDURE cloturer_fenetre

```sql
PROCEDURE cloturer_fenetre(
    p_id_fenetre     IN NUMBER,
    p_volume_donnees IN NUMBER
);
```

Passe une fenetre `Planifiee` en `Realisee` et enregistre le volume telecharge.

**Codes erreur** : -20110 (fenetre introuvable), -20111 (non Planifiee), -20112 (volume <= 0).

#### PROCEDURE affecter_satellite_mission

```sql
PROCEDURE affecter_satellite_mission(
    p_id_satellite IN VARCHAR2,
    p_id_mission   IN VARCHAR2,
    p_role         IN VARCHAR2
);
```

Insere une participation satellite-mission. Declenche T4 (mission Terminee et satellite Desorbite).

**Codes erreur** : -20120 (participation deja existante).
Le trigger T4 peut lever -20005, -20006.

#### PROCEDURE mettre_en_revision

```sql
PROCEDURE mettre_en_revision(
    p_id_satellite IN VARCHAR2
);
```

Passe un satellite en statut `Defaillant`. Declenche T5 qui journalise dans `HISTORIQUE_STATUT`.
Note : Oracle ne dispose pas d'un statut `En revision` dans le domaine CHECK ; `Defaillant`
est le statut le plus proche (valeur DDL valide).

**Codes erreur** : -20130 (satellite introuvable), -20131 (deja Defaillant ou Desorbite).

#### FUNCTION calculer_volume_theorique

```sql
FUNCTION calculer_volume_theorique(p_id_fenetre IN NUMBER) RETURN NUMBER;
```

Equivalent du sous-programme standalone `calculer_volume_session` (Ex.16).
Retourne `(debit_station_Mbps / 8) * duree_secondes` en Mo.

**Code erreur** : -20140 (fenetre introuvable).

#### FUNCTION statut_constellation

```sql
FUNCTION statut_constellation RETURN VARCHAR2;
```

Resume textuel de l'etat de la constellation. Exemple :
`"3/5 satellites operationnels, 2 missions actives, 3 fenetres realisees [en veille: 1, desorbites: 1]"`

#### FUNCTION stats_satellite

```sql
FUNCTION stats_satellite(p_id_satellite IN VARCHAR2) RETURN t_stats_satellite;
```

Retourne les indicateurs de performance (`nb_fenetres`, `volume_total`, `duree_moy_secondes`)
calcules sur les fenetres `Realisees` uniquement.

**Code erreur** : -20150 (satellite introuvable).

---

## Verification de compilation

Apres `CREATE OR REPLACE PACKAGE pkg_nanoOrbit AS ... END pkg_nanoOrbit;` :

```sql
SHOW ERRORS;
-- Attendu : "No errors."
```

Le bloc de verification teste l'acces aux constantes publiques :

```sql
BEGIN
    DBMS_OUTPUT.PUT_LINE(pkg_nanoOrbit.c_statut_min_fenetre);  -- 'Operationnel'
    DBMS_OUTPUT.PUT_LINE(pkg_nanoOrbit.c_duree_max_fenetre);   -- 900
    DBMS_OUTPUT.PUT_LINE(pkg_nanoOrbit.c_seuil_revision);      -- 50
END;
```

---

## Tableaux des codes erreur complets

| Plage | Sous-programme | Description |
|-------|---------------|-------------|
| -20100 | planifier_fenetre | Duree hors domaine [1..900] |
| -20101 | planifier_fenetre | FK violation (sat/sta introuvable) |
| -20110 | cloturer_fenetre | Fenetre introuvable |
| -20111 | cloturer_fenetre | Fenetre deja cloturee (non Planifiee) |
| -20112 | cloturer_fenetre | Volume invalide (<= 0) |
| -20120 | affecter_satellite_mission | Participation deja existante |
| -20130 | mettre_en_revision | Satellite introuvable |
| -20131 | mettre_en_revision | Satellite deja Defaillant ou Desorbite |
| -20140 | calculer_volume_theorique | Fenetre introuvable |
| -20150 | stats_satellite | Satellite introuvable |
| -20001..-20006 | *(triggers T1-T4 Phase 2)* | Heritage Phase 2, propages par RAISE |

---

## Lien avec les autres livrables

- BODY : [L3-C-body-pkg.md](L3-C-body-pkg.md) / [L3-C-body-pkg.sql](../../../src/phase-3/L3-C-body-pkg.sql)
- Scenarios de test : [L3-D-validation.md](L3-D-validation.md)

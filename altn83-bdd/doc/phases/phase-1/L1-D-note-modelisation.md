# L1-D - Note de Modélisation NanoOrbit

**Module** : ALTN83 - Bases de Données Réparties | **Phase** : 1 - Conception & Architecture distribuée

---

## Partie A - Justification des 3 choix de modélisation délicats

### Choix 1 : EMBARQUEMENT comme entité-association porteuse (RG-S04)

L'association entre SATELLITE et INSTRUMENT porte deux attributs propres au couple :
- `date_integration` : date du montage physique de l'instrument sur ce satellite précis
- `etat_fonctionnement` : état courant (Nominal / Dégradé / Hors service) de cet instrument **sur ce satellite**

Ces attributs ne dépendent ni du satellite seul ni de l'instrument seul. Exemple concret tiré du jeu de référence : le modèle INS-IR-01 est en état « Nominal » sur SAT-001 mais « Dégradé » sur SAT-004 (anomalie thermique). Les dates d'intégration diffèrent aussi (2022-03-15 vs 2023-06-10).

Au passage MLD, cela produit la table EMBARQUEMENT avec PK composite `(id_satellite, ref_instrument)` - conforme à l'exigence E6.

### Choix 2 : FENETRE_COM - relation binaire avec PK propre (RG-F01)

**Question** : la relation impliquant FENETRE_COM est-elle binaire (SATELLITE × STATION_SOL) ou ternaire (incluant CENTRE_CONTROLE) ?

**Choix retenu : binaire** avec PK propre `id_fenetre` (auto-incrémentée).

Justifications :
1. **Le centre de contrôle n'est pas participant direct de la communication**. La fenêtre physique se joue entre l'antenne (STATION_SOL) et le satellite. Le centre supervise la station via la table structurelle AFFECTATION_STATION.
2. **Indépendance temporelle** : si une station change de centre de rattachement (ex : transfert GS-SGP-01 de Houston à Singapour lors de la création de CTR-003), les fenêtres historiques ne doivent pas être modifiées.
3. **Dépendance fonctionnelle MERISE** : la fenêtre dépend fonctionnellement du couple (satellite, station), pas du triplet (satellite, station, centre).
4. **PK propre nécessaire** : contrairement à EMBARQUEMENT et PARTICIPATION, **plusieurs fenêtres existent pour le même couple** (satellite, station) à des dates différentes. Exemples : SAT-001 a les fenêtres 1 (GS-KIR-01) et 4 (GS-TLS-01) ; SAT-003 a les fenêtres 3 (GS-KIR-01) et 5 (GS-TLS-01). Une PK composite `(id_satellite, code_station)` ne discriminerait pas ces enregistrements.

### Choix 3 : PARTICIPER comme entité-association porteuse (RG-M03)

L'association SATELLITE × MISSION porte l'attribut `role_satellite` (ex : « Imageur principal », « Satellite de relais », « Satellite de secours »). Ce rôle dépend du couple : SAT-001 est « Imageur principal » dans MSN-ARC-2023 et aussi « Imageur principal » (historique) dans MSN-DEF-2022.

La PK composite `(id_satellite, id_mission)` est suffisante car un satellite n'occupe qu'un seul rôle par mission (un satellite ne peut pas être à la fois « Imageur principal » et « Satellite de relais » dans la même mission).

**Cardinalité retenue** : SATELLITE (0,N) - MISSION (1,N). Le 0 côté SATELLITE s'explique par le fait qu'un satellite peut exister dans le système avant sa première affectation (RG-S05 mentionne « au moins une mission » mais cette contrainte de cardinalité minimale ne s'exprime pas au niveau MCD/MLD - elle relève de la vérification applicative).

---

## Partie B - Architecture distribuée (Questions Q1 à Q4)

### Q1 - Tables strictement locales à un centre de contrôle

| Table locale (fragment) | Justification |
|---|---|
| **STATION_SOL** | Chaque centre gère ses propres stations : Paris supervise GS-TLS-01 (Toulouse) et GS-KIR-01 (Kiruna), Houston supervise GS-SGP-01 (Singapour). Les caractéristiques techniques d'une station (diamètre antenne, débit max, bande) n'intéressent que le centre qui la pilote au quotidien. |
| **FENETRE_COM** | Les fenêtres sont planifiées et réalisées localement par le centre qui contrôle la station concernée. Paris planifie les passages sur GS-TLS-01 et GS-KIR-01, Houston planifie ceux sur GS-SGP-01. Un opérateur n'a pas besoin de planifier des fenêtres sur les stations d'un autre centre. |
| **AFFECTATION_STATION** | Le rattachement station ↔ centre est local et administratif : chaque centre ne connaît que ses propres affectations. |

**Pourquoi locales ?** Ces données sont **opérationnelles et quotidiennes**. Elles évoluent fréquemment (planification de fenêtres) et leur portée est géographiquement limitée au centre responsable. Les partager en temps réel avec les autres centres créerait un trafic réseau inutile et des risques de conflits.

### Q2 - Tables globales (partagées entre tous les centres)

| Table globale | Justification | Mécanisme de synchronisation proposé |
|---|---|---|
| **ORBITE** | Données de référence physiques communes à toute la constellation. Changent très rarement (manœuvre orbitale exceptionnelle). | **Réplication en lecture seule** depuis un site master (Paris). Rafraîchissement quotidien. |
| **SATELLITE** | Tout centre doit connaître l'état de chaque satellite pour planifier des fenêtres. Le statut peut changer (Opérationnel -> Défaillant). | **Réplication multi-maître** avec résolution de conflits par horodatage (dernière écriture gagne). Propagation quasi-synchrone. |
| **INSTRUMENT** | Catalogue de référence stable, commun à tous les centres. | **Réplication en lecture seule** depuis le site master (Paris). Rafraîchissement hebdomadaire. |
| **EMBARQUEMENT** | État des instruments sur chaque satellite - information de référence pour la planification. | **Réplication en lecture seule** (modifications rares : changement d'état lors d'anomalies). |
| **MISSION** | Missions transversales mobilisant des satellites visibles depuis plusieurs centres. Toute modification de statut (Active -> Terminée) doit être visible immédiatement. | **Réplication synchrone** - modification propagée en temps réel à tous les centres. |
| **PARTICIPATION** | Affectation des satellites aux missions - doit être cohérente globalement pour éviter des conflits d'affectation. | **Réplication synchrone** liée à MISSION. |

### Q3 - Continuité de service : Singapour face à l'indisponibilité du serveur central

**Architecture proposée : fragmentation horizontale + réplication partielle avec mode dégradé.**

**Étape 1 - Fragmentation horizontale de FENETRE_COM :**
Chaque centre stocke localement ses propres fenêtres, filtrées par la station au sol rattachée :
```
FENETRE_COM_PARIS     = σ(code_station IN ('GS-TLS-01', 'GS-KIR-01'))(FENETRE_COM)
FENETRE_COM_HOUSTON   = σ(code_station IN (stations rattachées à CTR-002))(FENETRE_COM)
FENETRE_COM_SINGAPOUR = σ(code_station IN ('GS-SGP-01'))(FENETRE_COM)
```
Cette fragmentation est complète (union = table globale) et disjointe (pas de recouvrement).

**Étape 2 - Réplique locale des tables de référence :**
Singapour maintient une copie locale en lecture des tables SATELLITE, ORBITE, INSTRUMENT et MISSION. Rafraîchissement toutes les 5 minutes en conditions normales.

**Étape 3 - Mode dégradé (serveur central indisponible) :**
- Singapour continue de planifier des fenêtres en **mode autonome** (INSERT dans FENETRE_COM local).
- Les données de référence utilisées sont celles de la **dernière réplique** disponible.
- Les nouvelles fenêtres sont marquées avec un flag `synchro_pending = TRUE` pour traçabilité.

**Étape 4 - Réconciliation au retour du serveur central :**
- Les fenêtres en attente sont propagées au serveur central.
- Un mécanisme de détection de conflits vérifie les chevauchements créés pendant la déconnexion (trigger T2 rejoué côté central).
- En cas de conflit, la fenêtre en attente est signalée pour arbitrage humain.

### Q4 - Risques de cohérence dans le système multi-sites

#### Scénario 1 : Mise à jour simultanée du statut d'un satellite depuis deux centres

**Situation** : SAT-003 est visible depuis Paris et Singapour. L'opérateur de Paris détecte une anomalie et passe SAT-003 en « Défaillant ». Simultanément, l'opérateur de Singapour, ignorant cette anomalie, planifie une nouvelle fenêtre de communication pour SAT-003 via GS-SGP-01.

**Risque** : la mise à jour du statut n'est pas encore propagée à Singapour. La réplique locale de SATELLITE indique encore « Opérationnel ». Le trigger T1 local ne bloque pas l'insertion - une fenêtre est créée pour un satellite défaillant.

**Solution** : réplication synchrone obligatoire pour les colonnes de statut de SATELLITE. Avant toute insertion de fenêtre, le centre vérifie un timestamp de version sur le satellite. Alternative : verrouillage optimiste avec compteur de version incrémenté à chaque modification de statut.

#### Scénario 2 : Double affectation contradictoire d'un satellite à des missions

**Situation** : Paris veut affecter SAT-004 (En veille) à MSN-ARC-2023 comme « Satellite de secours ». Au même moment, Houston tente de réactiver SAT-004 pour MSN-COAST-2024 comme « Imageur principal », nécessitant de passer son statut à « Opérationnel ».

**Risque** : les deux opérations s'exécutent localement sans conflit apparent. Après synchronisation, SAT-004 se retrouve avec deux rôles contradictoires dans deux missions actives et un conflit sur le statut final (quelle mise à jour du statut « gagne » ?).

**Solution** : les opérations d'affectation mission et de changement de statut doivent transiter par un **coordinateur central** (ou protocole 2PC - Two-Phase Commit). La table PARTICIPATION est répliquée en mode synchrone avec verrouillage pessimiste sur le satellite concerné pendant la durée de l'opération transactionnelle.

---

## Synthèse de l'architecture distribuée

```
┌────────────────────────────────────────────────────────────────────┐
│                 DONNÉES GLOBALES (répliquées)                      │
│  ORBITE · SATELLITE · INSTRUMENT · EMBARQUEMENT ·                 │
│  MISSION · PARTICIPATION                                           │
│  -> Réplication synchrone ou lecture seule selon la table            │
└────────────────────────────────────────────────────────────────────┘
        │                      │                      │
   ┌────┴─────┐          ┌────┴─────┐          ┌─────┴─────┐
   │  PARIS   │          │ HOUSTON  │          │ SINGAPOUR │
   │ CTR-001  │          │ CTR-002  │          │ CTR-003   │
   ├──────────┤          ├──────────┤          ├───────────┤
   │ Local :  │          │ Local :  │          │ Local :   │
   │GS-TLS-01│          │ (backup) │          │ GS-SGP-01│
   │GS-KIR-01│          │          │          │           │
   │Fenêtres │          │ Fenêtres │          │ Fenêtres  │
   │ locales  │          │ locales  │          │ locales   │
   │Affectat. │          │Affectat. │          │ Affectat. │
   └──────────┘          └──────────┘          └───────────┘

   DONNÉES LOCALES (fragmentées horizontalement par centre)
   STATION_SOL (fragment) · FENETRE_COM (fragment) · AFFECTATION_STATION (fragment)
```
# NanoOrbit Ground Control - Rendu Android ALTN82

Application Android native de supervision NanoOrbit realisee en Kotlin avec Jetpack Compose. Le projet consomme une API REST FastAPI exposee sur `http://10.0.2.2:8000/` depuis l'emulateur Android, persiste une partie des donnees avec Room et implemente le bonus de notifications locales pour les fenetres de communication.

## Stack technique

- Kotlin, Jetpack Compose, Material 3
- Architecture MVVM avec `ViewModel` et `StateFlow`
- Retrofit + Gson pour l'API REST
- Room pour le cache local `satellites` et `fenetres_com`
- Navigation Compose avec bottom navigation
- osmdroid pour la carte des stations sol
- WorkManager + notifications Android pour le bonus

## Lancement du projet

1. Demarrer l'API REST depuis le dossier `altn82-rest-api` :

```powershell
.\.venv\Scripts\uvicorn.exe app.main:app --reload --host 0.0.0.0 --port 8000
```

2. Verifier rapidement l'API :

```powershell
curl.exe http://localhost:8000/health
curl.exe http://localhost:8000/satellites
curl.exe http://localhost:8000/fenetres
curl.exe http://localhost:8000/stations
```

3. Ouvrir `altn82-android` dans Android Studio, puis lancer l'application sur emulateur ou telephone.

4. En ligne de commande, verifier la compilation :

```powershell
.\gradlew.bat :app:assembleDebug
.\gradlew.bat :app:testDebugUnitTest
```

## Fonctionnalites livrees

### Dashboard

- Liste des satellites via `LazyColumn`.
- Recherche temps reel par nom de satellite ou type d'orbite.
- Filtres par statut avec `FilterChip`.
- Compteur des satellites operationnels.
- Gestion visuelle des satellites desorbites avec carte grisee et clic desactive.
- Etats de chargement, erreur et mode hors-ligne.

### Detail satellite

- Navigation `detail/{satelliteId}` depuis une carte satellite.
- Top app bar avec retour.
- Affichage statut, format CubeSat, orbite, altitude, masse, batterie et duree de vie.
- Instruments embarques recuperes via `/satellites/{id}/instruments`.
- Missions actives et role du satellite.
- Dialog de signalement d'anomalie avec validation de champ obligatoire.

### Planning

- Liste chronologique des fenetres de communication.
- Filtrage par station sol.
- Synthese du temps total de contact et volume total planifie.
- Badges couleur par statut : planifiee, realisee, annulee.
- Validation client RG-F04 : duree entre 1 et 900 secondes.
- Validation client RG-S06 : interdiction de creer une nouvelle fenetre pour un satellite desorbite.

### Carte

- Carte OpenStreetMap avec osmdroid.
- Marqueurs des stations sol.
- Couleur des marqueurs selon l'etat de la station.
- Infobulle avec nom, bande de frequence, debit max et distance si la localisation est active.
- Bouton GPS pour centrer la carte sur la derniere position connue.

### Bonus notifications

- Worker periodique WorkManager nomme `nanoorbit-window-notifications`.
- Verification toutes les 15 minutes, minimum impose par Android pour `PeriodicWorkRequest`.
- Canal de notification `nanoorbit_passages` en priorite haute.
- Notification locale 15 minutes avant une fenetre planifiee eligible.
- Dedoublonnage par `idFenetre` avec `SharedPreferences`.
- Permission `POST_NOTIFICATIONS` geree dans l'ecran Planning.
- Bouton `Tester notification` pour la demonstration, utile car les donnees de reference contiennent des fenetres passees.
- En cas d'erreur API, le worker renvoie `Result.retry()` et ne fabrique aucune donnee.

## Architecture

```text
com.efrei.nanoorbit
|-- data
|   |-- api          Retrofit, DTO REST
|   |-- db           Room entities, DAO, database
|   |-- models       Data classes Kotlin miroir ALTN83
|   `-- repository   NanoOrbitRepository, cache et appels API
|-- notifications    WorkManager, canal notification, regles testables
|-- ui
|   |-- components   Cartes et badges reutilisables
|   |-- dashboard    Ecran principal et ViewModel
|   |-- detail       Fiche satellite
|   |-- planning     Planning et demo notifications
|   |-- map          Carte osmdroid
|   `-- navigation   Routes, NavHost, bottom navigation
`-- MainActivity.kt
```

Les composables ne font pas d'appel reseau direct. Ils observent les `StateFlow` du `NanoOrbitViewModel`, qui delegue les acces donnees au `NanoOrbitRepository`.

## API REST consommee

L'application consomme les endpoints suivants :

- `GET /satellites`
- `GET /satellites/{id}/instruments`
- `GET /fenetres`
- `GET /stations`
- `GET /orbites`
- `GET /missions`
- `GET /participations`

Il n'y a plus de donnees mockees dans l'application. Si l'API ou la base ne repond pas, l'erreur est remontee a l'interface au lieu de masquer le probleme avec un jeu de donnees local fictif.

## Synergie ALTN82 / ALTN83

### Modeles de donnees

Les data classes Android suivent le MLD ALTN83 :

- `Satellite` correspond a `SATELLITE` avec `idSatellite`, `nomSatellite`, `statut`, `formatCubesat`, `idOrbite`, `dateLancement`, `masse`, `capaciteBatterie`.
- `FenetreCom` correspond a `FENETRE_COM` avec `idFenetre`, `datetimeDebut`, `duree`, `statut`, `idSatellite`, `codeStation`, `volumeDonnees`.
- `StationSol`, `Instrument`, `Mission`, `Orbite` et `ParticipationMission` reprennent les entites de reference utiles a l'application mobile.

Le statut satellite est represente par une `enum class StatutSatellite`, ce qui evite les valeurs libres incompatibles avec les contraintes Oracle.

### Regle RG-F04

La duree d'une fenetre est validee cote Android avant toute action utilisateur :

```kotlin
if (duree !in 1..900) {
    return "Duree invalide : entre 1 et 900 secondes"
}
```

Cette validation miroir la contrainte Oracle qui borne la duree des fenetres de communication.

### Mode hors-ligne

Room conserve les derniers satellites et les dernieres fenetres chargees. La strategie est cache-first :

- lecture du cache si des donnees existent ;
- affichage d'une banniere `Mode hors-ligne` avec age du cache ;
- tentative de rafraichissement reseau ensuite ;
- affichage d'une erreur si aucune donnee exploitable n'est disponible.

Cette approche repond au besoin ALTN83 Q3 : continuer a consulter les donnees recentes si le serveur central est temporairement indisponible.

## Tests et verification

Commandes executees avec succes :

```powershell
.\gradlew.bat :app:assembleDebug
.\gradlew.bat :app:testDebugUnitTest
```

Tests couverts :

- test unitaire Android de base ;
- tests unitaires des regles de notification :
  - fenetre planifiee a +15 minutes : eligible ;
  - fenetre realisee : ignoree ;
  - fenetre deja notifiee : ignoree ;
  - fenetre passee : ignoree.

Pour la demonstration orale :

1. Lancer l'API sur le port `8000`.
2. Lancer l'application.
3. Ouvrir le Dashboard, filtrer/rechercher les satellites.
4. Ouvrir une fiche satellite.
5. Aller dans Planning et verifier RG-F04/RG-S06.
6. Autoriser les notifications puis utiliser `Tester notification`.
7. Aller dans Carte et tester le bouton GPS si l'emulateur fournit une position.

## Notes de rendu

- Le dossier `build/` ne doit pas etre inclus dans l'archive finale.
- Le dossier `altn83-bdd` n'est pas modifie par l'application Android.
- L'API doit etre disponible sur le port `8000` pour la demonstration sur emulateur Android.

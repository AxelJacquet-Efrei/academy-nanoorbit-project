package com.efrei.nanoorbit.data.repository

import android.content.Context
import com.efrei.nanoorbit.data.api.FenetreDto
import com.efrei.nanoorbit.data.api.InstrumentDto
import com.efrei.nanoorbit.data.api.MissionDto
import com.efrei.nanoorbit.data.api.OrbiteDto
import com.efrei.nanoorbit.data.api.ParticipationDto
import com.efrei.nanoorbit.data.api.RetrofitClient
import com.efrei.nanoorbit.data.api.SatelliteDto
import com.efrei.nanoorbit.data.api.StationDto
import com.efrei.nanoorbit.data.db.FenetreEntity
import com.efrei.nanoorbit.data.db.NanoOrbitDatabase
import com.efrei.nanoorbit.data.db.SatelliteEntity
import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.Instrument
import com.efrei.nanoorbit.data.models.Mission
import com.efrei.nanoorbit.data.models.Orbite
import com.efrei.nanoorbit.data.models.ParticipationMission
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.StationSol
import com.efrei.nanoorbit.data.models.StatutSatellite
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext

data class CachedResult<T>(
    val data: T,
    val fromCache: Boolean,
    val cacheAgeMillis: Long? = null
)

class NanoOrbitRepository(context: Context) {
    private val api = RetrofitClient.api
    private val dao = NanoOrbitDatabase.getInstance(context).dao()

    // Lien ALTN83 Q3 : la strategie cache-first permet de relire les dernieres donnees
    // connues. La mise a jour reseau reste obligatoire et ses erreurs remontent a l'UI.
    suspend fun getSatellitesCacheFirst(): CachedResult<List<Satellite>> {
        val cached = withContext(Dispatchers.IO) { dao.getSatellites() }
        if (cached.isNotEmpty()) {
            return CachedResult(
                data = cached.map { it.toSatellite() },
                fromCache = true,
                cacheAgeMillis = withContext(Dispatchers.IO) {
                    dao.getSatellitesUpdatedAt()
                }?.let { System.currentTimeMillis() - it }
            )
        }

        return refreshSatellites()
    }

    suspend fun refreshSatellites(): CachedResult<List<Satellite>> {
        delay(500)
        val satellites = api.getSatellites().map { it.toSatellite() }
        val now = System.currentTimeMillis()
        withContext(Dispatchers.IO) {
            dao.upsertSatellites(satellites.map { it.toEntity(now) })
        }
        return CachedResult(satellites, fromCache = false, cacheAgeMillis = 0)
    }

    suspend fun getFenetresCacheFirst(): CachedResult<List<FenetreCom>> {
        val cached = withContext(Dispatchers.IO) { dao.getFenetres() }
        if (cached.isNotEmpty()) {
            return CachedResult(
                data = cached.map { it.toFenetreCom() },
                fromCache = true,
                cacheAgeMillis = withContext(Dispatchers.IO) {
                    dao.getFenetresUpdatedAt()
                }?.let { System.currentTimeMillis() - it }
            )
        }

        return refreshFenetres()
    }

    suspend fun refreshFenetres(): CachedResult<List<FenetreCom>> {
        delay(500)
        val fenetres = api.getFenetres().map { it.toFenetreCom() }.sortedBy { it.datetimeDebut }
        val now = System.currentTimeMillis()
        withContext(Dispatchers.IO) {
            dao.upsertFenetres(fenetres.map { it.toEntity(now) })
        }
        return CachedResult(fenetres, fromCache = false, cacheAgeMillis = 0)
    }

    suspend fun getInstruments(id: String): List<Instrument> {
        delay(300)
        return api.getInstruments(id).map { it.toInstrument() }
    }

    suspend fun getStations(): List<StationSol> {
        delay(300)
        return api.getStations().map { it.toStationSol() }
    }

    suspend fun getOrbites(): List<Orbite> {
        delay(300)
        return api.getOrbites().map { it.toOrbite() }
    }

    suspend fun getMissions(): List<Mission> {
        delay(300)
        return api.getMissions().map { it.toMission() }
    }

    suspend fun getParticipations(): List<ParticipationMission> {
        delay(300)
        return api.getParticipations().map { it.toParticipationMission() }
    }

    fun validateFenetre(duree: Int, satellite: Satellite?): String? {
        if (duree !in 1..900) {
            return "Duree invalide : entre 1 et 900 secondes"
        }
        if (satellite?.statut == StatutSatellite.DESORBITE) {
            return "Satellite desorbite : nouvelle fenetre interdite"
        }
        return null
    }
}

private fun SatelliteDto.toSatellite(): Satellite = Satellite(
    idSatellite = idSatellite,
    nomSatellite = nomSatellite,
    statut = parseStatut(statut),
    formatCubesat = formatCubesat,
    idOrbite = idOrbite,
    typeOrbite = typeOrbite ?: "N/A",
    altitude = altitude,
    dateLancement = dateLancement,
    masse = masse,
    dureeViePrevue = dureeViePrevue,
    capaciteBatterie = capaciteBatterie
)

private fun InstrumentDto.toInstrument(): Instrument = Instrument(
    refInstrument = refInstrument,
    typeInstrument = typeInstrument,
    modele = modele,
    resolution = resolution,
    consommation = consommation
)

private fun FenetreDto.toFenetreCom(): FenetreCom = FenetreCom(
    idFenetre = idFenetre,
    datetimeDebut = datetimeDebut,
    duree = duree,
    statut = statut,
    idSatellite = idSatellite,
    codeStation = codeStation,
    volumeDonnees = volumeDonnees
)

private fun StationDto.toStationSol(): StationSol = StationSol(
    codeStation = codeStation,
    nomStation = nomStation,
    latitude = latitude,
    longitude = longitude,
    diametreAntenne = diametreAntenne,
    debitMax = debitMax,
    etat = etat ?: "Inconnu",
    bandeFrequence = bandeFrequence ?: "N/A"
)

private fun OrbiteDto.toOrbite(): Orbite = Orbite(
    idOrbite = idOrbite,
    typeOrbite = typeOrbite,
    altitude = altitude,
    inclinaison = inclinaison,
    zoneCouverture = zoneCouverture
)

private fun MissionDto.toMission(): Mission = Mission(
    idMission = idMission,
    nomMission = nomMission,
    objectif = objectif,
    dateDebut = dateDebut,
    statutMission = statutMission,
    dateFin = dateFin,
    zoneGeoCible = zoneGeoCible
)

private fun ParticipationDto.toParticipationMission(): ParticipationMission = ParticipationMission(
    idMission = idMission,
    idSatellite = idSatellite,
    role = role
)

private fun SatelliteEntity.toSatellite(): Satellite = Satellite(
    idSatellite = idSatellite,
    nomSatellite = nomSatellite,
    statut = parseStatut(statut),
    formatCubesat = formatCubesat,
    idOrbite = idOrbite,
    typeOrbite = typeOrbite,
    altitude = altitude,
    dateLancement = dateLancement,
    masse = masse,
    dureeViePrevue = dureeViePrevue,
    capaciteBatterie = capaciteBatterie
)

private fun Satellite.toEntity(updatedAt: Long): SatelliteEntity = SatelliteEntity(
    idSatellite,
    nomSatellite,
    statut.name,
    formatCubesat,
    idOrbite,
    typeOrbite,
    altitude,
    dateLancement,
    masse,
    dureeViePrevue,
    capaciteBatterie,
    updatedAt
)

private fun FenetreEntity.toFenetreCom(): FenetreCom = FenetreCom(
    idFenetre = idFenetre,
    datetimeDebut = datetimeDebut,
    duree = duree,
    statut = statut,
    idSatellite = idSatellite,
    codeStation = codeStation,
    volumeDonnees = volumeDonnees
)

private fun FenetreCom.toEntity(updatedAt: Long): FenetreEntity = FenetreEntity(
    idFenetre,
    datetimeDebut,
    duree,
    statut,
    idSatellite,
    codeStation,
    volumeDonnees,
    updatedAt
)

private fun parseStatut(value: String): StatutSatellite {
    val normalized = value
        .lowercase()
        .replace("é", "e")
        .replace("è", "e")
        .replace("ê", "e")
        .replace("_", " ")
        .trim()

    return when (normalized) {
        "operationnel" -> StatutSatellite.OPERATIONNEL
        "en veille" -> StatutSatellite.EN_VEILLE
        "defaillant" -> StatutSatellite.DEFAILLANT
        "desorbite" -> StatutSatellite.DESORBITE
        else -> error("Statut satellite inconnu: $value")
    }
}

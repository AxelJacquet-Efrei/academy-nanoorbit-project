package com.efrei.nanoorbit.data.repository

import android.content.Context
import com.efrei.nanoorbit.data.api.RetrofitClient
import com.efrei.nanoorbit.data.db.FenetreEntity
import com.efrei.nanoorbit.data.db.NanoOrbitDatabase
import com.efrei.nanoorbit.data.db.SatelliteEntity
import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.Instrument
import com.efrei.nanoorbit.data.models.Mission
import com.efrei.nanoorbit.data.models.MockData
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

    // Lien ALTN83 Q3 : la strategie cache-first permet a une station, par exemple Singapour,
    // de continuer a consulter et planifier avec les dernieres donnees connues si le serveur central tombe.
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
        val satellites = runCatching {
            api.getSatellites().map { dto ->
                val fallback = MockData.satellites.firstOrNull { it.idSatellite == dto.id }
                Satellite(
                    idSatellite = dto.id?.takeIf { it.isNotBlank() } ?: fallback?.idSatellite ?: "UNKNOWN",
                    nomSatellite = dto.name?.takeIf { it.isNotBlank() } ?: fallback?.nomSatellite ?: "Satellite inconnu",
                    statut = fallback?.statut ?: StatutSatellite.OPERATIONNEL,
                    formatCubesat = fallback?.formatCubesat ?: "N/A",
                    idOrbite = dto.orbitType.toOrbitId(),
                    typeOrbite = dto.orbitType?.takeIf { it.isNotBlank() } ?: fallback?.typeOrbite ?: "N/A",
                    dateLancement = fallback?.dateLancement,
                    masse = fallback?.masse
                )
            }.ifEmpty { MockData.satellites }
        }.getOrElse {
            MockData.satellites
        }

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
        val fenetres = runCatching {
            api.getFenetres().map { dto ->
                val id = dto.id?.toIntOrNull() ?: -1
                val fallback = MockData.fenetres.firstOrNull { it.idFenetre == id }
                FenetreCom(
                    idFenetre = id,
                    datetimeDebut = dto.startTime?.takeIf { it.isNotBlank() } ?: fallback?.datetimeDebut ?: "",
                    duree = dto.durationSeconds ?: fallback?.duree ?: 0,
                    statut = fallback?.statut ?: "Planifiee",
                    idSatellite = dto.satelliteId?.takeIf { it.isNotBlank() } ?: fallback?.idSatellite ?: "UNKNOWN",
                    codeStation = dto.station?.takeIf { it.isNotBlank() } ?: fallback?.codeStation ?: "",
                    volumeDonnees = fallback?.volumeDonnees
                )
            }.ifEmpty { MockData.fenetres }
        }.getOrElse {
            MockData.fenetres
        }

        val now = System.currentTimeMillis()
        withContext(Dispatchers.IO) {
            dao.upsertFenetres(fenetres.map { it.toEntity(now) })
        }
        return CachedResult(fenetres.sortedBy { it.datetimeDebut }, fromCache = false, cacheAgeMillis = 0)
    }

    suspend fun getInstruments(id: String): List<Instrument> {
        delay(300)
        return runCatching {
            api.getInstruments(id).map { dto ->
                Instrument(
                    refInstrument = dto.id?.toString()?.takeIf { it.isNotBlank() } ?: "UNKNOWN",
                    typeInstrument = dto.instrumentType?.takeIf { it.isNotBlank() } ?: "N/A",
                    modele = dto.name?.takeIf { it.isNotBlank() } ?: "Instrument inconnu",
                    resolution = null,
                    consommation = null
                )
            }.ifEmpty { MockData.instrumentsBySatellite[id].orEmpty() }
        }.getOrElse {
            MockData.instrumentsBySatellite[id].orEmpty()
        }
    }

    suspend fun getStations(): List<StationSol> {
        delay(300)
        return runCatching {
            api.getStations().map { dto ->
                StationSol(
                    codeStation = dto.codeStation ?: "UNKNOWN",
                    nomStation = dto.nomStation ?: "Station inconnue",
                    latitude = dto.latitude ?: 0.0,
                    longitude = dto.longitude ?: 0.0,
                    diametreAntenne = dto.diametreAntenne,
                    debitMax = dto.debitMax,
                    etat = dto.etat ?: "Operationnelle",
                    bandeFrequence = dto.bandeFrequence ?: "S"
                )
            }.ifEmpty { MockData.stations }
        }.getOrElse {
            MockData.stations
        }
    }

    fun getMissions(): List<Mission> = MockData.missions

    fun getParticipations(): List<ParticipationMission> = MockData.participations

    fun validateFenetre(duree: Int, satellite: Satellite?): String? {
        if (duree !in 1..900) {
            return "Duree invalide : entre 1 et 900 secondes"
        }
        if (satellite?.statut == StatutSatellite.DESORBITE) {
            return "Satellite desorbite : nouvelle fenetre interdite"
        }
        return null
    }

    private fun String?.toOrbitId(): Int {
        if (this.isNullOrBlank()) return -1
        val digits = this.filter { it.isDigit() }
        return digits.toIntOrNull() ?: MockData.orbites.firstOrNull { it.typeOrbite == this }?.idOrbite ?: -1
    }
}

private fun SatelliteEntity.toSatellite(): Satellite = Satellite(
    idSatellite = idSatellite,
    nomSatellite = nomSatellite,
    statut = runCatching { StatutSatellite.valueOf(statut) }.getOrDefault(StatutSatellite.DEFAILLANT),
    formatCubesat = formatCubesat,
    idOrbite = idOrbite,
    typeOrbite = typeOrbite,
    dateLancement = dateLancement,
    masse = masse
)

private fun Satellite.toEntity(updatedAt: Long): SatelliteEntity = SatelliteEntity(
    idSatellite,
    nomSatellite,
    statut.name,
    formatCubesat,
    idOrbite,
    typeOrbite,
    dateLancement,
    masse,
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

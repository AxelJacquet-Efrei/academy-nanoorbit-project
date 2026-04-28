package com.efrei.nanoorbit.data.repository

import com.efrei.nanoorbit.data.api.RetrofitClient
import com.efrei.nanoorbit.data.models.Instrument
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.StatutSatellite
import kotlinx.coroutines.delay

class NanoOrbitRepository {
    private val api = RetrofitClient.api

    suspend fun getSatellites(): List<Satellite> {
        delay(500)
        return api.getSatellites().map { dto ->
            Satellite(
                idSatellite = dto.id?.takeIf { it.isNotBlank() } ?: "UNKNOWN",
                nomSatellite = dto.name?.takeIf { it.isNotBlank() } ?: "Satellite inconnu",
                statut = StatutSatellite.OPERATIONNEL,
                formatCubesat = "N/A",
                idOrbite = dto.orbitType.toOrbitId(),
                typeOrbite = dto.orbitType?.takeIf { it.isNotBlank() } ?: "N/A"
            )
        }
    }

    private fun String?.toOrbitId(): Int {
        if (this.isNullOrBlank()) return -1
        val digits = this.filter { it.isDigit() }
        return digits.toIntOrNull() ?: -1
    }

    suspend fun getInstruments(id: String): List<Instrument> {
        delay(500)
        return api.getInstruments(id).map { dto ->
            Instrument(
                refInstrument = dto.id?.takeIf { it.isNotBlank() } ?: "UNKNOWN",
                typeInstrument = dto.instrumentType?.takeIf { it.isNotBlank() } ?: "N/A",
                modele = dto.name?.takeIf { it.isNotBlank() } ?: "Instrument inconnu",
                resolution = null,
                consommation = null
            )
        }
    }

    suspend fun getFenetres(): List<FenetreCom> {
        delay(500)
        return api.getFenetres().map { dto ->
            FenetreCom(
                idFenetre = dto.id?.toIntOrNull() ?: -1,
                datetimeDebut = dto.startTime?.takeIf { it.isNotBlank() } ?: "",
                duree = dto.durationSeconds ?: 0,
                statut = "PLANIFIEE",
                idSatellite = dto.satelliteId?.takeIf { it.isNotBlank() } ?: "UNKNOWN",
                codeStation = dto.station?.takeIf { it.isNotBlank() } ?: "",
                volumeDonnees = null
            )
        }
    }
}
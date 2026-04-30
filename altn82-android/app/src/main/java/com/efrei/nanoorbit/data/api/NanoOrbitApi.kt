package com.efrei.nanoorbit.data.api

import retrofit2.http.GET
import retrofit2.http.Path

interface NanoOrbitApi {
    @GET("satellites")
    suspend fun getSatellites(): List<SatelliteDto>

    @GET("satellites/{id}/instruments")
    suspend fun getInstruments(@Path("id") id: String): List<InstrumentDto>

    @GET("fenetres")
    suspend fun getFenetres(): List<FenetreDto>

    @GET("stations")
    suspend fun getStations(): List<StationDto>

    @GET("orbites")
    suspend fun getOrbites(): List<OrbiteDto>

    @GET("missions")
    suspend fun getMissions(): List<MissionDto>

    @GET("participations")
    suspend fun getParticipations(): List<ParticipationDto>
}

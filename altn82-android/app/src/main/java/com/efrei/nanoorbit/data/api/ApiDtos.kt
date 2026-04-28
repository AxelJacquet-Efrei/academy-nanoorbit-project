package com.efrei.nanoorbit.data.api

import com.google.gson.annotations.SerializedName

data class SatelliteDto(
    @SerializedName("id")
    val id: String? = null,
    @SerializedName("name")
    val name: String? = null,
    @SerializedName("orbit_type")
    val orbitType: String? = null
)

data class InstrumentDto(
    @SerializedName("id")
    val id: String? = null,
    @SerializedName("satellite_id")
    val satelliteId: String? = null,
    @SerializedName("name")
    val name: String? = null,
    @SerializedName("instrument_type")
    val instrumentType: String? = null
)

data class FenetreDto(
    @SerializedName("id")
    val id: String? = null,
    @SerializedName("satellite_id")
    val satelliteId: String? = null,
    @SerializedName("station")
    val station: String? = null,
    @SerializedName("start_time")
    val startTime: String? = null,
    @SerializedName("end_time")
    val endTime: String? = null,
    @SerializedName("duration_seconds")
    val durationSeconds: Int? = null
)


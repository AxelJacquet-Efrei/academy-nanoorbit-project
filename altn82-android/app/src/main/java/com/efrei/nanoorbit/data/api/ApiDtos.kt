package com.efrei.nanoorbit.data.api

import com.google.gson.annotations.SerializedName

data class SatelliteDto(
    @SerializedName("id_satellite")
    val idSatellite: String,
    @SerializedName("nom_satellite")
    val nomSatellite: String,
    @SerializedName("statut")
    val statut: String,
    @SerializedName("format_cubesat")
    val formatCubesat: String,
    @SerializedName("id_orbite")
    val idOrbite: String,
    @SerializedName("type_orbite")
    val typeOrbite: String? = null,
    @SerializedName("altitude")
    val altitude: Int? = null,
    @SerializedName("date_lancement")
    val dateLancement: String? = null,
    @SerializedName("masse")
    val masse: Double? = null,
    @SerializedName("duree_vie_prevue")
    val dureeViePrevue: Int? = null,
    @SerializedName("capacite_batterie")
    val capaciteBatterie: Double? = null
)

data class InstrumentDto(
    @SerializedName("ref_instrument")
    val refInstrument: String,
    @SerializedName("type_instrument")
    val typeInstrument: String,
    @SerializedName("modele")
    val modele: String,
    @SerializedName("resolution")
    val resolution: Double? = null,
    @SerializedName("consommation")
    val consommation: Double? = null,
    @SerializedName("etat_fonctionnement")
    val etatFonctionnement: String? = null
)

data class FenetreDto(
    @SerializedName("id_fenetre")
    val idFenetre: Int,
    @SerializedName("datetime_debut")
    val datetimeDebut: String,
    @SerializedName("duree")
    val duree: Int,
    @SerializedName("statut")
    val statut: String,
    @SerializedName("id_satellite")
    val idSatellite: String,
    @SerializedName("code_station")
    val codeStation: String,
    @SerializedName("volume_donnees")
    val volumeDonnees: Double? = null
)

data class StationDto(
    @SerializedName("code_station")
    val codeStation: String,
    @SerializedName("nom_station")
    val nomStation: String,
    @SerializedName("latitude")
    val latitude: Double,
    @SerializedName("longitude")
    val longitude: Double,
    @SerializedName("diametre_antenne")
    val diametreAntenne: Double? = null,
    @SerializedName("debit_max")
    val debitMax: Double? = null,
    @SerializedName("etat")
    val etat: String? = null,
    @SerializedName("bande_frequence")
    val bandeFrequence: String? = null
)

data class OrbiteDto(
    @SerializedName("id_orbite")
    val idOrbite: String,
    @SerializedName("type_orbite")
    val typeOrbite: String,
    @SerializedName("altitude")
    val altitude: Int,
    @SerializedName("inclinaison")
    val inclinaison: Double,
    @SerializedName("zone_couverture")
    val zoneCouverture: String? = null
)

data class MissionDto(
    @SerializedName("id_mission")
    val idMission: String,
    @SerializedName("nom_mission")
    val nomMission: String,
    @SerializedName("objectif")
    val objectif: String,
    @SerializedName("date_debut")
    val dateDebut: String,
    @SerializedName("statut_mission")
    val statutMission: String,
    @SerializedName("date_fin")
    val dateFin: String? = null,
    @SerializedName("zone_geo_cible")
    val zoneGeoCible: String? = null
)

data class ParticipationDto(
    @SerializedName("id_mission")
    val idMission: String,
    @SerializedName("id_satellite")
    val idSatellite: String,
    @SerializedName("role")
    val role: String
)

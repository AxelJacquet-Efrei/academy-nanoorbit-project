package com.efrei.nanoorbit.data.models

import com.google.gson.annotations.SerializedName

enum class StatutSatellite(val intitule: String) {
    @SerializedName(value = "Opérationnel", alternate = ["OPERATIONNEL", "Operationnel", "operationnel", "opérationnel"])
    OPERATIONNEL("Opérationnel"),
    @SerializedName(value = "En veille", alternate = ["EN_VEILLE", "En Veille", "en_veille", "en veille"])
    EN_VEILLE("En veille"),
    @SerializedName(value = "Défaillant", alternate = ["DEFAILLANT", "Defaillant", "defaillant", "défaillant"])
    DEFAILLANT("Défaillant"),
    @SerializedName(value = "Désorbité", alternate = ["DESORBITE", "Desorbite", "desorbite", "désorbité"])
    DESORBITE("Désorbité")
}

data class Satellite(
    val idSatellite: String,
    val nomSatellite: String,
    val statut: StatutSatellite,
    val formatCubesat: String,
    val idOrbite: Int,
    val typeOrbite: String,
    val dateLancement: String? = null,
    val masse: Double? = null
)

data class Orbite(
    val idOrbite: Int,
    val typeOrbite: String,
    val altitude: Int,
    val inclinaison: Double,
    val zoneCouverture: String? = null
)

data class Instrument(
    val refInstrument: String,
    val typeInstrument: String,
    val modele: String,
    val resolution: Double? = null,
    val consommation: Double? = null
)

data class FenetreCom(
    val idFenetre: Int,
    val datetimeDebut: String,
    val duree: Int,
    val statut: String,
    val idSatellite: String,
    val codeStation: String,
    val volumeDonnees: Double? = null
)

data class StationSol(
    val codeStation: String,
    val nomStation: String,
    val latitude: Double,
    val longitude: Double,
    val diametreAntenne: Double? = null,
    val debitMax: Double? = null
)

data class Mission(
    val idMission: String,
    val nomMission: String,
    val objectif: String,
    val dateDebut: String,
    val statutMission: String,
    val dateFin: String? = null,
    val zoneGeoCible: String? = null
)


package com.efrei.nanoorbit.data.models

enum class StatutSatellite(val intitule: String) {
    OPERATIONNEL("Opérationnel"),
    EN_VEILLE("En veille"),
    DEFAILLANT("Défaillant"),
    DESORBITE("Désorbité")
}

data class Satellite(
    val idSatellite: String,
    val nomSatellite: String,
    val statut: StatutSatellite,
    val formatCubesat: String,
    val idOrbite: Int,
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


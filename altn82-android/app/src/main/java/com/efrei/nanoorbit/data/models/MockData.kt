package com.efrei.nanoorbit.data.models

object MockData {
    val orbites = listOf(
        Orbite(1, "SSO", 500, 97.5, "Mondiale"),
        Orbite(2, "SSO", 550, 98.0, "Mondiale"),
        Orbite(3, "LEO", 400, 51.6, "Equatoriale")
    )

    val satellites = listOf(
        Satellite("SAT-001", "NanoObs-1", StatutSatellite.OPERATIONNEL, "3U", 1, "SSO", "2023-01-15", 4.5),
        Satellite("SAT-002", "NanoObs-2", StatutSatellite.OPERATIONNEL, "3U", 2, "SSO", "2023-06-20", 4.5),
        Satellite("SAT-003", "NanoIce-1", StatutSatellite.EN_VEILLE, "6U", 1, "SSO", "2023-11-05", 8.2),
        Satellite("SAT-004", "NanoAir-1", StatutSatellite.DEFAILLANT, "1U", 3, "LEO", "2024-02-10", 1.3),
        Satellite("SAT-005", "Legacy-1", StatutSatellite.DESORBITE, "3U", 2, "SSO", "2021-05-12", 4.0)
    )

    val instruments = listOf(
        Instrument("INST-01", "Camera Optique", "OptiCam-X", 0.5, 12.0),
        Instrument("INST-02", "Radar SAR", "SAR-Mini", 2.0, 25.0),
        Instrument("INST-03", "Spectrometre", "Spectro-Lite", null, 8.5),
        Instrument("INST-04", "Radiometre", "Rad-Temp", 5.0, 15.0)
    )

    val instrumentsBySatellite = mapOf(
        "SAT-001" to listOf(instruments[0], instruments[2]),
        "SAT-002" to listOf(instruments[1]),
        "SAT-003" to listOf(instruments[0], instruments[3]),
        "SAT-004" to listOf(instruments[2]),
        "SAT-005" to listOf(instruments[3])
    )

    val fenetres = listOf(
        FenetreCom(1, "2026-04-28T10:30:00", 600, "Realisee", "SAT-001", "ST-KOU", 150.5),
        FenetreCom(2, "2026-04-28T14:15:00", 450, "Realisee", "SAT-002", "ST-TLS", 98.0),
        FenetreCom(3, "2026-04-28T18:45:00", 800, "Realisee", "SAT-001", "ST-KOU", 188.2),
        FenetreCom(4, "2026-04-29T09:00:00", 500, "Planifiee", "SAT-003", "ST-KRU"),
        FenetreCom(5, "2026-04-29T11:30:00", 720, "Planifiee", "SAT-001", "ST-TLS")
    )

    val stations = listOf(
        StationSol("ST-KOU", "Kourou", 5.1597, -52.6503, 15.0, 1000.0, "Operationnelle", "X"),
        StationSol("ST-TLS", "Toulouse", 43.6047, 1.4442, 10.0, 500.0, "Operationnelle", "S"),
        StationSol("ST-KRU", "Kiruna", 67.8557, 20.2251, 13.0, 800.0, "Maintenance", "X")
    )

    val missions = listOf(
        Mission("MSN-AMZ-2024", "Amazon Watch", "Suivi deforestation", "2024-01-01", "Active", null, "Amazonie"),
        Mission("MSN-ICE-2024", "Ice Shield", "Mesure fonte glaciaire", "2024-02-10", "Active", null, "Arctique"),
        Mission("MSN-DEF-2022", "Legacy Defense", "Observation historique", "2022-03-12", "Terminee", "2023-11-30", "Europe")
    )

    val participations = listOf(
        ParticipationMission("MSN-AMZ-2024", "SAT-001", "Leader observation"),
        ParticipationMission("MSN-AMZ-2024", "SAT-002", "Relais donnees"),
        ParticipationMission("MSN-ICE-2024", "SAT-003", "Acquisition thermique"),
        ParticipationMission("MSN-ICE-2024", "SAT-004", "Backup"),
        ParticipationMission("MSN-DEF-2022", "SAT-005", "Archive")
    )
}

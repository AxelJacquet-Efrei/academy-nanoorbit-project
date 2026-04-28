package com.efrei.nanoorbit.data.models

object MockData {
    val orbites = listOf(
        Orbite(1, "SSO", 500, 97.5, "Mondiale"),
        Orbite(2, "SSO", 550, 98.0, "Mondiale"),
        Orbite(3, "LEO", 400, 51.6, "Equatoriale")
    )

    val satellites = listOf(
        Satellite("SAT-001", "NanoObs-1", StatutSatellite.OPERATIONNEL, "3U", 1, "ORB-001", "2023-01-15", 4.5),
        Satellite("SAT-002", "NanoObs-2", StatutSatellite.OPERATIONNEL, "3U", 2, "ORB-002", "2023-06-20", 4.5),
        Satellite("SAT-003", "NanoIce-1", StatutSatellite.EN_VEILLE, "6U", 1, "ORB-001", "2023-11-05", 8.2),
        Satellite("SAT-004", "NanoAir-1", StatutSatellite.DEFAILLANT, "1U", 3, "ORB-003", "2024-02-10", 1.3),
        Satellite("SAT-005", "Legacy-1", StatutSatellite.DESORBITE, "3U", 2, "ORB-002", "2021-05-12", 4.0)
    )

    val instruments = listOf(
        Instrument("INST-01", "Camera Optique", "OptiCam-X", 0.5, 12.0),
        Instrument("INST-02", "Radar SAR", "SAR-Mini", 2.0, 25.0),
        Instrument("INST-03", "Spectrometre", "Spectro-Lite", null, 8.5),
        Instrument("INST-04", "Radiometre", "Rad-Temp", 5.0, 15.0)
    )

    val fenetres = listOf(
        FenetreCom(1, "2024-05-20T10:30:00", 600, "Réalisée", "SAT-001", "ST-KOU"),
        FenetreCom(2, "2024-05-20T14:15:00", 450, "Réalisée", "SAT-002", "ST-TLS"),
        FenetreCom(3, "2024-05-20T18:45:00", 800, "Réalisée", "SAT-001", "ST-KOU"),
        FenetreCom(4, "2024-05-21T09:00:00", 500, "Planifiée", "SAT-003", "ST-KRU"),
        FenetreCom(5, "2024-05-21T11:30:00", 720, "Planifiée", "SAT-001", "ST-TLS")
    )

    val stations = listOf(
        StationSol("ST-KOU", "Kourou", 5.1597, -52.6503, 15.0, 1000.0),
        StationSol("ST-TLS", "Toulouse", 43.6047, 1.4442, 10.0, 500.0),
        StationSol("ST-KRU", "Kiruna", 67.8557, 20.2251, 13.0, 800.0)
    )
}


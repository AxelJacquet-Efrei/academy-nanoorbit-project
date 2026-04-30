package com.efrei.nanoorbit.data.db;

import androidx.annotation.NonNull;
import androidx.room.Entity;
import androidx.room.PrimaryKey;

@Entity(tableName = "satellites")
public class SatelliteEntity {
    @PrimaryKey
    @NonNull
    public String idSatellite;
    public String nomSatellite;
    public String statut;
    public String formatCubesat;
    public String idOrbite;
    public String typeOrbite;
    public Integer altitude;
    public String dateLancement;
    public Double masse;
    public Integer dureeViePrevue;
    public Double capaciteBatterie;
    public long updatedAt;

    public SatelliteEntity(
            @NonNull String idSatellite,
            String nomSatellite,
            String statut,
            String formatCubesat,
            String idOrbite,
            String typeOrbite,
            Integer altitude,
            String dateLancement,
            Double masse,
            Integer dureeViePrevue,
            Double capaciteBatterie,
            long updatedAt
    ) {
        this.idSatellite = idSatellite;
        this.nomSatellite = nomSatellite;
        this.statut = statut;
        this.formatCubesat = formatCubesat;
        this.idOrbite = idOrbite;
        this.typeOrbite = typeOrbite;
        this.altitude = altitude;
        this.dateLancement = dateLancement;
        this.masse = masse;
        this.dureeViePrevue = dureeViePrevue;
        this.capaciteBatterie = capaciteBatterie;
        this.updatedAt = updatedAt;
    }
}

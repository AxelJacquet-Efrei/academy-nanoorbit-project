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
    public int idOrbite;
    public String typeOrbite;
    public String dateLancement;
    public Double masse;
    public long updatedAt;

    public SatelliteEntity(
            @NonNull String idSatellite,
            String nomSatellite,
            String statut,
            String formatCubesat,
            int idOrbite,
            String typeOrbite,
            String dateLancement,
            Double masse,
            long updatedAt
    ) {
        this.idSatellite = idSatellite;
        this.nomSatellite = nomSatellite;
        this.statut = statut;
        this.formatCubesat = formatCubesat;
        this.idOrbite = idOrbite;
        this.typeOrbite = typeOrbite;
        this.dateLancement = dateLancement;
        this.masse = masse;
        this.updatedAt = updatedAt;
    }
}

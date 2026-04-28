package com.efrei.nanoorbit.data.db;

import androidx.room.Entity;
import androidx.room.PrimaryKey;

@Entity(tableName = "fenetres_com")
public class FenetreEntity {
    @PrimaryKey
    public int idFenetre;
    public String datetimeDebut;
    public int duree;
    public String statut;
    public String idSatellite;
    public String codeStation;
    public Double volumeDonnees;
    public long updatedAt;

    public FenetreEntity(
            int idFenetre,
            String datetimeDebut,
            int duree,
            String statut,
            String idSatellite,
            String codeStation,
            Double volumeDonnees,
            long updatedAt
    ) {
        this.idFenetre = idFenetre;
        this.datetimeDebut = datetimeDebut;
        this.duree = duree;
        this.statut = statut;
        this.idSatellite = idSatellite;
        this.codeStation = codeStation;
        this.volumeDonnees = volumeDonnees;
        this.updatedAt = updatedAt;
    }
}

package com.efrei.nanoorbit.data.db;

import androidx.room.Dao;
import androidx.room.Query;
import androidx.room.Upsert;

import java.util.List;

@Dao
public interface NanoOrbitDao {
    @Query("SELECT * FROM satellites ORDER BY idSatellite")
    List<SatelliteEntity> getSatellites();

    @Query("SELECT MAX(updatedAt) FROM satellites")
    Long getSatellitesUpdatedAt();

    @Upsert
    void upsertSatellites(List<SatelliteEntity> satellites);

    @Query("SELECT * FROM fenetres_com ORDER BY datetimeDebut")
    List<FenetreEntity> getFenetres();

    @Query("SELECT MAX(updatedAt) FROM fenetres_com")
    Long getFenetresUpdatedAt();

    @Upsert
    void upsertFenetres(List<FenetreEntity> fenetres);
}

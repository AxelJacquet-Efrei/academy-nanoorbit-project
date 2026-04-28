package com.efrei.nanoorbit.data.db;

import android.content.Context;

import androidx.room.Database;
import androidx.room.Room;
import androidx.room.RoomDatabase;

@Database(
        entities = {SatelliteEntity.class, FenetreEntity.class},
        version = 1,
        exportSchema = false
)
public abstract class NanoOrbitDatabase extends RoomDatabase {
    public abstract NanoOrbitDao dao();

    private static volatile NanoOrbitDatabase instance;

    public static NanoOrbitDatabase getInstance(Context context) {
        if (instance == null) {
            synchronized (NanoOrbitDatabase.class) {
                if (instance == null) {
                    instance = Room.databaseBuilder(
                            context.getApplicationContext(),
                            NanoOrbitDatabase.class,
                            "nanoorbit.db"
                    ).build();
                }
            }
        }
        return instance;
    }
}

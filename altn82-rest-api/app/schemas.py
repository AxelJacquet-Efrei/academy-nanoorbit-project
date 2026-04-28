from datetime import datetime

from pydantic import BaseModel, ConfigDict


class SatelliteOut(BaseModel):
    id: str
    name: str
    orbit_type: str | None = None

    model_config = ConfigDict(from_attributes=True)


class InstrumentOut(BaseModel):
    id: str | int
    satellite_id: str
    name: str
    instrument_type: str | None = None

    model_config = ConfigDict(from_attributes=True)


class FenetreOut(BaseModel):
    id: str
    satellite_id: str | None = None
    station: str | None = None
    start_time: datetime
    end_time: datetime
    duration_seconds: int

    model_config = ConfigDict(from_attributes=True)


class StationOut(BaseModel):
    code_station: str
    nom_station: str
    latitude: float
    longitude: float
    diametre_antenne: float | None = None
    debit_max: float | None = None
    etat: str | None = None
    bande_frequence: str | None = None

    model_config = ConfigDict(from_attributes=True)

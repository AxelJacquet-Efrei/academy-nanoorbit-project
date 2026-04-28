from datetime import date, datetime

from pydantic import BaseModel


class SatelliteOut(BaseModel):
    id_satellite: str
    nom_satellite: str
    statut: str
    format_cubesat: str
    id_orbite: str
    type_orbite: str | None = None
    altitude: int | None = None
    date_lancement: date | None = None
    masse: float | None = None
    duree_vie_prevue: int | None = None
    capacite_batterie: float | None = None


class InstrumentOut(BaseModel):
    ref_instrument: str
    type_instrument: str
    modele: str
    resolution: float | None = None
    consommation: float | None = None
    etat_fonctionnement: str | None = None


class FenetreOut(BaseModel):
    id_fenetre: int
    datetime_debut: datetime
    duree: int
    statut: str
    id_satellite: str
    code_station: str
    volume_donnees: float | None = None


class StationOut(BaseModel):
    code_station: str
    nom_station: str
    latitude: float
    longitude: float
    diametre_antenne: float | None = None
    debit_max: float | None = None
    etat: str | None = None
    bande_frequence: str | None = None


class OrbiteOut(BaseModel):
    id_orbite: str
    type_orbite: str
    altitude: int
    inclinaison: float
    zone_couverture: str | None = None


class MissionOut(BaseModel):
    id_mission: str
    nom_mission: str
    objectif: str
    date_debut: date
    statut_mission: str
    date_fin: date | None = None
    zone_geo_cible: str | None = None


class ParticipationOut(BaseModel):
    id_mission: str
    id_satellite: str
    role: str

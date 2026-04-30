from datetime import date, datetime

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Orbite(Base):
    __tablename__ = "ORBITE"

    id_orbite: Mapped[str] = mapped_column("ID_ORBITE", String(50), primary_key=True)
    type_orbite: Mapped[str] = mapped_column("TYPE_ORBITE", String(20), nullable=False)
    altitude: Mapped[int] = mapped_column("ALTITUDE", Integer, nullable=False)
    inclinaison: Mapped[float] = mapped_column("INCLINAISON", Float, nullable=False)
    zone_couverture: Mapped[str | None] = mapped_column("ZONE_COUVERTURE", String(255), nullable=True)

    satellites: Mapped[list["Satellite"]] = relationship(back_populates="orbite")


class Satellite(Base):
    __tablename__ = "SATELLITE"

    id_satellite: Mapped[str] = mapped_column("ID_SATELLITE", String(20), primary_key=True)
    nom_satellite: Mapped[str] = mapped_column("NOM_SATELLITE", String(100), nullable=False)
    date_lancement: Mapped[date | None] = mapped_column("DATE_LANCEMENT", Date, nullable=True)
    masse: Mapped[float | None] = mapped_column("MASSE", Float, nullable=True)
    format_cubesat: Mapped[str] = mapped_column("FORMAT_CUBESAT", String(5), nullable=False)
    statut: Mapped[str] = mapped_column("STATUT", String(30), nullable=False)
    duree_vie_prevue: Mapped[int | None] = mapped_column("DUREE_VIE_PREVUE", Integer, nullable=True)
    capacite_batterie: Mapped[float | None] = mapped_column("CAPACITE_BATTERIE", Float, nullable=True)
    id_orbite: Mapped[str] = mapped_column("ID_ORBITE", ForeignKey("ORBITE.ID_ORBITE"), nullable=False)

    orbite: Mapped[Orbite] = relationship(back_populates="satellites")


class Instrument(Base):
    __tablename__ = "INSTRUMENT"

    ref_instrument: Mapped[str] = mapped_column("REF_INSTRUMENT", String(50), primary_key=True)
    type_instrument: Mapped[str] = mapped_column("TYPE_INSTRUMENT", String(100), nullable=False)
    modele: Mapped[str] = mapped_column("MODELE", String(100), nullable=False)
    resolution: Mapped[float | None] = mapped_column("RESOLUTION", Float, nullable=True)
    consommation: Mapped[float | None] = mapped_column("CONSOMMATION", Float, nullable=True)


class Embarquement(Base):
    __tablename__ = "EMBARQUEMENT"

    id_satellite: Mapped[str] = mapped_column(
        "ID_SATELLITE",
        ForeignKey("SATELLITE.ID_SATELLITE"),
        primary_key=True,
    )
    ref_instrument: Mapped[str] = mapped_column(
        "REF_INSTRUMENT",
        ForeignKey("INSTRUMENT.REF_INSTRUMENT"),
        primary_key=True,
    )
    date_integration: Mapped[date | None] = mapped_column("DATE_INTEGRATION", Date, nullable=True)
    etat_fonctionnement: Mapped[str | None] = mapped_column("ETAT_FONCTIONNEMENT", String(50), nullable=True)


class FenetreCommunication(Base):
    __tablename__ = "FENETRE_COM"

    id_fenetre: Mapped[int] = mapped_column("ID_FENETRE", Integer, primary_key=True)
    datetime_debut: Mapped[datetime] = mapped_column("DATETIME_DEBUT", DateTime, nullable=False)
    duree: Mapped[int] = mapped_column("DUREE", Integer, nullable=False)
    volume_donnees: Mapped[float | None] = mapped_column("VOLUME_DONNEES", Float, nullable=True)
    statut: Mapped[str] = mapped_column("STATUT", String(30), nullable=False)
    id_satellite: Mapped[str] = mapped_column(
        "ID_SATELLITE",
        ForeignKey("SATELLITE.ID_SATELLITE"),
        nullable=False,
        index=True,
    )
    code_station: Mapped[str] = mapped_column("CODE_STATION", ForeignKey("STATION_SOL.CODE_STATION"), nullable=False)


class StationSol(Base):
    __tablename__ = "STATION_SOL"

    code_station: Mapped[str] = mapped_column("CODE_STATION", String(50), primary_key=True)
    nom_station: Mapped[str] = mapped_column("NOM_STATION", String(100), nullable=False)
    latitude: Mapped[float] = mapped_column("LATITUDE", Float, nullable=False)
    longitude: Mapped[float] = mapped_column("LONGITUDE", Float, nullable=False)
    diametre_antenne: Mapped[float | None] = mapped_column("DIAMETRE_ANTENNE", Float, nullable=True)
    bande_frequence: Mapped[str | None] = mapped_column("BANDE_FREQUENCE", String(20), nullable=True)
    debit_max: Mapped[float | None] = mapped_column("DEBIT_MAX", Float, nullable=True)
    statut: Mapped[str | None] = mapped_column("STATUT", String(50), nullable=True)


class Mission(Base):
    __tablename__ = "MISSION"

    id_mission: Mapped[str] = mapped_column("ID_MISSION", String(50), primary_key=True)
    nom_mission: Mapped[str] = mapped_column("NOM_MISSION", String(100), nullable=False)
    objectif: Mapped[str] = mapped_column("OBJECTIF", String(500), nullable=False)
    zone_geo_cible: Mapped[str | None] = mapped_column("ZONE_GEO_CIBLE", String(255), nullable=True)
    date_debut: Mapped[date] = mapped_column("DATE_DEBUT", Date, nullable=False)
    date_fin: Mapped[date | None] = mapped_column("DATE_FIN", Date, nullable=True)
    statut_mission: Mapped[str] = mapped_column("STATUT_MISSION", String(30), nullable=False)


class Participation(Base):
    __tablename__ = "PARTICIPATION"

    id_satellite: Mapped[str] = mapped_column(
        "ID_SATELLITE",
        ForeignKey("SATELLITE.ID_SATELLITE"),
        primary_key=True,
    )
    id_mission: Mapped[str] = mapped_column(
        "ID_MISSION",
        ForeignKey("MISSION.ID_MISSION"),
        primary_key=True,
    )
    role_satellite: Mapped[str] = mapped_column("ROLE_SATELLITE", String(100), nullable=False)

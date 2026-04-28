from sqlalchemy import DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Satellite(Base):
    __tablename__ = "SATELLITE"

    id: Mapped[str] = mapped_column("ID_SATELLITE", String(50), primary_key=True)
    name: Mapped[str] = mapped_column("NOM_SATELLITE", String(100), nullable=False, unique=True)
    orbit_type: Mapped[str | None] = mapped_column("ID_ORBITE", String(50), nullable=True)

    instruments: Mapped[list["Instrument"]] = relationship(back_populates="satellite")


class Instrument(Base):
    __tablename__ = "EMBARQUEMENT"

    id: Mapped[int] = mapped_column("ID_EMBARQUEMENT", primary_key=True, autoincrement=True)
    satellite_id: Mapped[str] = mapped_column("ID_SATELLITE", ForeignKey("SATELLITE.ID_SATELLITE"), index=True)
    name: Mapped[str] = mapped_column("REF_INSTRUMENT", String(100), ForeignKey("INSTRUMENT.REF_INSTRUMENT"), nullable=False)
    instrument_type: Mapped[str | None] = mapped_column("STATUT", String(50), nullable=True)

    satellite: Mapped[Satellite] = relationship(back_populates="instruments")


class FenetreCommunication(Base):
    __tablename__ = "FENETRE_COM"

    id: Mapped[str] = mapped_column("ID_FENETRE", String(50), primary_key=True)
    satellite_id: Mapped[str | None] = mapped_column(
        "ID_SATELLITE", ForeignKey("SATELLITE.ID_SATELLITE"), nullable=True, index=True
    )
    station: Mapped[str | None] = mapped_column("CODE_STATION", String(100), nullable=True)
    start_time: Mapped[DateTime] = mapped_column("DATETIME_DEBUT", DateTime, nullable=False)
    duration_seconds: Mapped[int] = mapped_column("DUREE", Integer, nullable=False)

    @property
    def end_time(self):
        import datetime
        if self.start_time and self.duration_seconds is not None:
            return self.start_time + datetime.timedelta(seconds=self.duration_seconds)
        return self.start_time


class StationSol(Base):
    __tablename__ = "STATION_SOL"

    code_station: Mapped[str] = mapped_column("CODE_STATION", String(50), primary_key=True)
    nom_station: Mapped[str] = mapped_column("NOM_STATION", String(100), nullable=False)
    latitude: Mapped[float] = mapped_column("LATITUDE", Float, nullable=False)
    longitude: Mapped[float] = mapped_column("LONGITUDE", Float, nullable=False)
    diametre_antenne: Mapped[float | None] = mapped_column("DIAMETRE_ANTENNE", Float, nullable=True)
    bande_frequence: Mapped[str | None] = mapped_column("BANDE_FREQUENCE", String(20), nullable=True)
    debit_max: Mapped[float | None] = mapped_column("DEBIT_MAX", Float, nullable=True)
    etat: Mapped[str | None] = mapped_column("STATUT", String(50), nullable=True)

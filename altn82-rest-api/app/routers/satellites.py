from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db

router = APIRouter(tags=["satellites"])


@router.get("/satellites", response_model=list[schemas.SatelliteOut])
def list_satellites(db: Session = Depends(get_db)):
    rows = (
        db.query(models.Satellite, models.Orbite)
        .join(models.Orbite, models.Satellite.id_orbite == models.Orbite.id_orbite)
        .order_by(models.Satellite.id_satellite)
        .all()
    )

    return [
        {
            "id_satellite": satellite.id_satellite,
            "nom_satellite": satellite.nom_satellite,
            "statut": satellite.statut,
            "format_cubesat": satellite.format_cubesat,
            "id_orbite": satellite.id_orbite,
            "type_orbite": orbite.type_orbite,
            "altitude": orbite.altitude,
            "date_lancement": satellite.date_lancement,
            "masse": satellite.masse,
            "duree_vie_prevue": satellite.duree_vie_prevue,
            "capacite_batterie": satellite.capacite_batterie,
        }
        for satellite, orbite in rows
    ]


@router.get(
    "/satellites/{satellite_id}/instruments",
    response_model=list[schemas.InstrumentOut],
)
def list_satellite_instruments(satellite_id: str, db: Session = Depends(get_db)):
    exists = db.query(models.Satellite.id_satellite).filter(models.Satellite.id_satellite == satellite_id).first()
    if not exists:
        raise HTTPException(status_code=404, detail="Satellite not found")

    rows = (
        db.query(models.Instrument, models.Embarquement)
        .join(models.Embarquement, models.Instrument.ref_instrument == models.Embarquement.ref_instrument)
        .filter(models.Embarquement.id_satellite == satellite_id)
        .order_by(models.Instrument.ref_instrument)
        .all()
    )

    return [
        {
            "ref_instrument": instrument.ref_instrument,
            "type_instrument": instrument.type_instrument,
            "modele": instrument.modele,
            "resolution": instrument.resolution,
            "consommation": instrument.consommation,
            "etat_fonctionnement": embarquement.etat_fonctionnement,
        }
        for instrument, embarquement in rows
    ]


@router.get("/orbites", response_model=list[schemas.OrbiteOut])
def list_orbites(db: Session = Depends(get_db)):
    rows = db.query(models.Orbite).order_by(models.Orbite.id_orbite).all()
    return [
        {
            "id_orbite": row.id_orbite,
            "type_orbite": row.type_orbite,
            "altitude": row.altitude,
            "inclinaison": row.inclinaison,
            "zone_couverture": row.zone_couverture,
        }
        for row in rows
    ]


@router.get("/missions", response_model=list[schemas.MissionOut])
def list_missions(db: Session = Depends(get_db)):
    return db.query(models.Mission).order_by(models.Mission.id_mission).all()


@router.get("/participations", response_model=list[schemas.ParticipationOut])
def list_participations(db: Session = Depends(get_db)):
    rows = db.query(models.Participation).order_by(models.Participation.id_satellite).all()
    return [
        {
            "id_mission": row.id_mission,
            "id_satellite": row.id_satellite,
            "role": row.role_satellite,
        }
        for row in rows
    ]

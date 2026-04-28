from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db

router = APIRouter(tags=["satellites"])


@router.get("/satellites", response_model=list[schemas.SatelliteOut])
def list_satellites(db: Session = Depends(get_db)):
    return db.query(models.Satellite).order_by(models.Satellite.id).all()


@router.get(
    "/satellites/{satellite_id}/instruments",
    response_model=list[schemas.InstrumentOut],
)
def list_satellite_instruments(satellite_id: str, db: Session = Depends(get_db)):
    satellite = db.query(models.Satellite).filter(models.Satellite.id == satellite_id).first()
    if not satellite:
        raise HTTPException(status_code=404, detail="Satellite not found")

    return (
        db.query(models.Instrument)
        .filter(models.Instrument.satellite_id == satellite_id)
        .order_by(models.Instrument.id)
        .all()
    )

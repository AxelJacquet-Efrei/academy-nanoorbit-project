from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db

router = APIRouter(tags=["stations"])


@router.get("/stations", response_model=list[schemas.StationOut])
def list_stations(db: Session = Depends(get_db)):
    rows = db.query(models.StationSol).order_by(models.StationSol.code_station).all()
    return [
        {
            "code_station": station.code_station,
            "nom_station": station.nom_station,
            "latitude": station.latitude,
            "longitude": station.longitude,
            "diametre_antenne": station.diametre_antenne,
            "debit_max": station.debit_max,
            "etat": station.statut,
            "bande_frequence": station.bande_frequence,
        }
        for station in rows
    ]

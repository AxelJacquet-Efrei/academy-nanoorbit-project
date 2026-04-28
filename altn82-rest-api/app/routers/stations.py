from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db

router = APIRouter(tags=["stations"])


@router.get("/stations", response_model=list[schemas.StationOut])
def list_stations(db: Session = Depends(get_db)):
    return db.query(models.StationSol).order_by(models.StationSol.code_station).all()

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db

router = APIRouter(tags=["fenetres"])


@router.get("/fenetres", response_model=list[schemas.FenetreOut])
def list_fenetres(db: Session = Depends(get_db)):
    return (
        db.query(models.FenetreCommunication)
        .order_by(models.FenetreCommunication.datetime_debut)
        .all()
    )

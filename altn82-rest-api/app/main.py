from fastapi import FastAPI

from app.database import Base, engine
from app.routers.fenetres import router as fenetres_router
from app.routers.satellites import router as satellites_router
from app.routers.stations import router as stations_router

app = FastAPI(
    title="ALTN82 REST API",
    description="Phase 2 API built with FastAPI",
    version="2.0.0",
)


@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)


@app.get("/health", tags=["health"])
def health_check():
    return {"status": "ok"}


app.include_router(satellites_router)
app.include_router(fenetres_router)
app.include_router(stations_router)
app.include_router(satellites_router, prefix="/api/v1")
app.include_router(fenetres_router, prefix="/api/v1")
app.include_router(stations_router, prefix="/api/v1")

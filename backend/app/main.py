import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.db.session import engine, SessionLocal
from app.core.db.base import Base
from app.core.db.init_db import seed_demo_data
import app.models # Ensure all models are registered

# Import endpoint routers
from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.communities import router as communities_router
from app.api.v1.endpoints.announcements import router as announcements_router
from app.api.v1.endpoints.maintenance import router as maintenance_router
from app.api.v1.endpoints.meetings import router as meetings_router
from app.api.v1.endpoints.polls import router as polls_router
from app.api.v1.endpoints.dues import router as dues_router
from app.api.v1.endpoints.messages import router as messages_router
from app.api.v1.endpoints.dashboard import router as dashboard_router
from app.api.v1.endpoints.notifications import router as notifications_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("rezidanspro")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database tables
    logger.info("Initializing RezidansPro Database tables...")
    Base.metadata.create_all(bind=engine)
    
    # Auto-seed demo data if dev environment
    if settings.APP_ENV == "development":
        db = SessionLocal()
        try:
            seed_demo_data(db)
        finally:
            db.close()
    yield

app = FastAPI(
    title="RezidansPro API",
    version="1.0.0",
    description="RezidansPro — Apartman, Site ve Rezidans Yönetim Sistemi Backend API",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global unhandled exception handler (Master Prompt Sec 62)
# User receives user-friendly message while backend logs the full trace.
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled Exception on {request.method} {request.url}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Bir sorun oluştu. Lütfen tekrar deneyin."}
    )

# Register API v1 routers
app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(communities_router, prefix=settings.API_V1_STR)
app.include_router(announcements_router, prefix=settings.API_V1_STR)
app.include_router(maintenance_router, prefix=settings.API_V1_STR)
app.include_router(meetings_router, prefix=settings.API_V1_STR)
app.include_router(polls_router, prefix=settings.API_V1_STR)
app.include_router(dues_router, prefix=settings.API_V1_STR)
app.include_router(messages_router, prefix=settings.API_V1_STR)
app.include_router(dashboard_router, prefix=settings.API_V1_STR)
app.include_router(notifications_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {
        "app": "RezidansPro API",
        "tagline": "Binanızın iletişim merkezi.",
        "version": "1.0.0",
        "status": "online",
        "docs_url": "/docs"
    }

@app.get("/health")
def health():
    return {"status": "healthy"}

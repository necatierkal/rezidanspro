import os
from typing import List, Union
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator

class Settings(BaseSettings):
    PROJECT_NAME: str = "RezidansPro"
    API_V1_STR: str = "/api/v1"
    APP_ENV: str = "development"
    
    # Database
    DATABASE_URL: str = "sqlite:///./rezidanspro.db"
    
    # JWT & Auth
    JWT_SECRET: str = "rezidanspro_jwt_secret_dev_37e6215c1f964c27bea299cf2a420552"
    JWT_REFRESH_SECRET: str = "rezidanspro_jwt_refresh_secret_dev_982k9_production_ready"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 120
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    
    # Push Notifications (FCM)
    FCM_PROJECT_ID: str = "rezidanspro-app"
    
    # Storage
    STORAGE_BUCKET: str = "rezidanspro-uploads"
    LOCAL_STORAGE_DIR: str = "./uploads"
    
    # CORS
    CORS_ORIGINS: List[str] = ["*"]

    @field_validator("CORS_ORIGINS", mode="before")
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, list):
            return v
        return ["*"]

    model_config = SettingsConfigDict(env_file=".env", extra="allow")

settings = Settings()

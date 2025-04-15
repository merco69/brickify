import os
from typing import Optional
from pydantic import BaseModel
from dotenv import load_dotenv

# Chargement des variables d'environnement
load_dotenv()

class Settings(BaseModel):
    """Configuration de l'application"""
    
    # Version et environnement
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"
    
    # Configuration des logs
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Configuration de la base de données
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./brickify.db")
    
    # JWT
    SECRET_KEY: str = os.getenv("JWT_SECRET", "votre_secret_jwt_super_secret")
    ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

# Instance de configuration
settings = Settings()

def validate_settings():
    """Valide que toutes les variables d'environnement requises sont définies"""
    required_vars = [
        "LUMI_API_KEY",
        "BRICKLINK_CONSUMER_KEY",
        "BRICKLINK_CONSUMER_SECRET",
        "BRICKLINK_TOKEN",
        "BRICKLINK_TOKEN_SECRET"
    ]
    
    missing_vars = [var for var in required_vars if not getattr(settings, var)]
    
    if missing_vars:
        raise ValueError(
            f"Variables d'environnement manquantes : {', '.join(missing_vars)}"
        ) 
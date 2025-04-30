from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from typing import Dict
import logging
from ..services.mobile_service import MobileService
from ..config.mobile_config import (
    MAX_FILE_SIZE,
    ALLOWED_EXTENSIONS,
    API_TITLE,
    API_VERSION,
    API_DESCRIPTION
)

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialisation de l'API
app = FastAPI(
    title=API_TITLE,
    version=API_VERSION,
    description=API_DESCRIPTION
)

# Initialisation du service
mobile_service = MobileService()

@app.post("/analyze")
async def analyze_image(file: UploadFile = File(...)) -> Dict:
    """
    Analyse une image et retourne les prédictions du modèle.
    """
    try:
        # Vérification de l'extension du fichier
        file_extension = "." + file.filename.split(".")[-1].lower()
        if file_extension not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=400,
                detail=f"Format de fichier non supporté. Formats acceptés: {', '.join(ALLOWED_EXTENSIONS)}"
            )

        # Vérification de la taille du fichier
        file_size = 0
        chunk_size = 1024
        while chunk := await file.read(chunk_size):
            file_size += len(chunk)
            if file_size > MAX_FILE_SIZE:
                raise HTTPException(
                    status_code=400,
                    detail=f"Fichier trop volumineux. Taille maximale: {MAX_FILE_SIZE/1024/1024}MB"
                )
        
        # Réinitialisation du curseur du fichier
        await file.seek(0)
        
        # Traitement de l'image
        result = await mobile_service.process_image(file)
        return result

    except Exception as e:
        logger.error(f"Erreur lors de l'analyse de l'image: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/model-info")
async def get_model_info() -> Dict:
    """
    Retourne les informations sur le modèle chargé.
    """
    try:
        return mobile_service.get_model_info()
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des informations du modèle: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 
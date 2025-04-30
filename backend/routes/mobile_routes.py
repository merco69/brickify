from fastapi import APIRouter, UploadFile, HTTPException, File
from fastapi.responses import JSONResponse
from typing import Dict, Any
import logging

from ..services.mobile_service import MobileService
from ..config.mobile_config import ALLOWED_EXTENSIONS, MAX_FILE_SIZE

router = APIRouter(prefix="/mobile", tags=["mobile"])
mobile_service = MobileService()
logger = logging.getLogger(__name__)

@router.post("/predict")
async def predict_image(file: UploadFile = File(...)) -> Dict[str, Any]:
    """
    Traite une image téléchargée et retourne les prédictions.
    
    Args:
        file (UploadFile): Le fichier image à analyser
        
    Returns:
        Dict[str, Any]: Les prédictions du modèle
    """
    try:
        # Vérification de l'extension
        file_ext = "." + file.filename.split(".")[-1].lower()
        if file_ext not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=400,
                detail=f"Extension de fichier non supportée. Extensions autorisées: {ALLOWED_EXTENSIONS}"
            )
            
        # Vérification de la taille
        contents = await file.read()
        if len(contents) > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=400,
                detail=f"Fichier trop volumineux. Taille maximum: {MAX_FILE_SIZE/1024/1024}MB"
            )
            
        # Traitement de l'image
        predictions = await mobile_service.process_image(contents)
        return JSONResponse(content=predictions)
        
    except Exception as e:
        logger.error(f"Erreur lors du traitement de l'image: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/model-info")
async def get_model_info() -> Dict[str, Any]:
    """
    Retourne les informations sur le modèle chargé.
    
    Returns:
        Dict[str, Any]: Informations sur le modèle
    """
    try:
        return mobile_service.get_model_info()
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des informations du modèle: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 
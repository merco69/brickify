from fastapi import APIRouter, UploadFile, HTTPException
from PIL import Image
import io
import torch
import logging
from typing import Dict, Any
from config.mobile_config import (
    IMAGE_SIZE,
    SUPPORTED_FORMATS,
    DEVICE,
    API_PREFIX,
    API_TAG,
    NORMALIZE_MEAN,
    NORMALIZE_STD
)

# Configuration du logger
logger = logging.getLogger(__name__)

router = APIRouter(
    prefix=API_PREFIX,
    tags=[API_TAG]
)

@router.post("/analyze")
async def analyze_image(file: UploadFile) -> Dict[str, Any]:
    """
    Endpoint pour analyser une image.
    """
    try:
        # Vérification du format
        if file.content_type not in SUPPORTED_FORMATS:
            raise HTTPException(
                status_code=400,
                detail=f"Format non supporté. Formats acceptés: {', '.join(SUPPORTED_FORMATS)}"
            )

        # Lecture et redimensionnement de l'image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        image = image.resize(IMAGE_SIZE)
        
        # TODO: Ajouter le traitement du modèle ici
        
        return {
            "status": "success",
            "message": "Image analysée avec succès",
            "predictions": []  # À remplacer par les prédictions réelles
        }

    except Exception as e:
        logger.error(f"Erreur lors de l'analyse de l'image: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Erreur lors du traitement de l'image"
        )

@router.get("/health")
async def health_check() -> Dict[str, Any]:
    """
    Endpoint pour vérifier l'état de l'API.
    """
    return {
        "status": "healthy",
        "device": {
            "type": DEVICE,
            "cuda_available": torch.cuda.is_available(),
            "cuda_version": torch.version.cuda if torch.cuda.is_available() else None
        }
    } 
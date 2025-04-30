import logging
import os
from pathlib import Path
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
import torch
import uvicorn
import sys
import numpy as np

# Ajout du répertoire parent au PYTHONPATH
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from ai_service.config import PORT, LOG_LEVEL, MODEL_CONFIG
from ai_service.services.blocky_service import BlockyService
from ai_service.services.blocky_resource_manager import BlockyResourceManager
from ai_service.services.blocky_optimizer import BlockyOptimizer
from ai_service.services.cache_service import CacheService
from ai_service.services.lego_learner import LegoModelLearner

# Configuration des logs
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL.upper()),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Création de l'application
app = FastAPI(
    title="Brickify AI Service",
    description="Service d'IA pour l'optimisation et l'apprentissage des modèles LEGO",
    version="1.0.0"
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware de compression
app.add_middleware(GZipMiddleware)

# Initialisation des services
resource_manager = BlockyResourceManager(
    base_dir=Path(os.getenv("STORAGE_PATH", "storage")),
    max_memory_mb=int(os.getenv("MAX_MEMORY_MB", "4096")),
    max_storage_gb=int(os.getenv("MAX_STORAGE_GB", "10")),
    cleanup_interval_mins=int(os.getenv("CLEANUP_INTERVAL_MINS", "30")),
    max_temp_files=int(os.getenv("MAX_TEMP_FILES", "100")),
    max_file_age_hours=int(os.getenv("MAX_FILE_AGE_HOURS", "24"))
)

cache_service = CacheService(
    cache_dir=Path(os.getenv("CACHE_DIR", "cache")),
    max_age_days=int(os.getenv("CACHE_MAX_AGE_DAYS", "30"))
)

optimizer = BlockyOptimizer(config=MODEL_CONFIG["optimizer"])
lego_learner = LegoModelLearner(config=MODEL_CONFIG["training"])

blocky_service = BlockyService(
    resource_manager=resource_manager,
    optimizer=optimizer,
    cache_service=cache_service
)

@app.post("/optimize")
async def optimize_model(model_data: dict):
    """Optimise un modèle 3D en briques LEGO."""
    try:
        voxels = np.array(model_data.get("voxels", []))
        colors = np.array(model_data.get("colors", [])) if "colors" in model_data else None
        model_id = model_data.get("model_id")
        
        result = await optimizer.optimize_mesh(voxels, colors, model_id)
        return result
    except Exception as e:
        logger.error(f"Erreur lors de l'optimisation: {str(e)}")
        raise

@app.post("/learn")
async def learn_from_model(model_data: dict):
    """Apprend à partir d'un modèle LEGO existant."""
    try:
        result = await lego_learner.learn_from_model(model_data)
        return result
    except Exception as e:
        logger.error(f"Erreur lors de l'apprentissage: {str(e)}")
        raise

@app.get("/health")
async def health_check():
    """Point de terminaison pour vérifier la santé du service."""
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=PORT,
        reload=True,
        workers=MODEL_CONFIG["inference"]["num_workers"]
    ) 
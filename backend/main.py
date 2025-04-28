import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
import time
from config import settings
from services.blocky_service import BlockyService
from services.blocky_resource_manager import BlockyResourceManager
from services.blocky_optimizer import BlockyOptimizer

# Configuration des logs
logging.basicConfig(
    level=settings.LOG_LEVEL,
    format=settings.LOG_FORMAT
)
logger = logging.getLogger(__name__)

# Création de l'application
app = FastAPI(
    title="Brickify API",
    description="API pour l'application Brickify",
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
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Middleware de monitoring
@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    # Enregistrement des métriques
    logger.info(f"Request: {request.method} {request.url.path} - Status: {response.status_code} - Duration: {duration:.2f}s")
    
    return response

@app.get("/")
async def root():
    """Route de base pour vérifier que l'API fonctionne"""
    return {"message": "Bienvenue sur l'API Brickify !"}

@app.get("/health")
async def health_check():
    """Route de health check pour Render"""
    return {"status": "healthy"}

# Initialisation des services Blocky
blocky_resource_manager = BlockyResourceManager(
    base_dir=settings.BLOCKY_STORAGE_PATH,
    max_memory_gb=settings.BLOCKY_MAX_MEMORY_GB,
    max_storage_gb=settings.BLOCKY_MAX_STORAGE_GB,
    cleanup_interval_hours=settings.BLOCKY_CLEANUP_INTERVAL_HOURS,
    max_temp_files=settings.BLOCKY_MAX_TEMP_FILES,
    max_age_days=settings.BLOCKY_MAX_AGE_DAYS
)

blocky_optimizer = BlockyOptimizer(
    device=settings.BLOCKY_DEVICE,
    num_workers=settings.BLOCKY_NUM_WORKERS,
    batch_size=settings.BLOCKY_BATCH_SIZE,
    precision=settings.BLOCKY_PRECISION
)

blocky_service = BlockyService(
    resource_manager=blocky_resource_manager,
    optimizer=blocky_optimizer
)

@app.on_event("startup")
async def startup_event():
    """Événement de démarrage de l'application"""
    logger.info("Démarrage de l'application...")
    logger.info(f"Blocky initialisé avec GPU: {settings.BLOCKY_DEVICE}")

@app.on_event("shutdown")
async def shutdown_event():
    """Événement d'arrêt de l'application"""
    logger.info("Arrêt de l'application...")

if __name__ == "__main__":
    import uvicorn
    port = int(settings.PORT)
    uvicorn.run(app, host="0.0.0.0", port=port) 
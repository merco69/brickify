import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
import time
from config import settings

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

@app.on_event("startup")
async def startup_event():
    """Événement de démarrage de l'application"""
    logger.info("Démarrage de l'application...")

@app.on_event("shutdown")
async def shutdown_event():
    """Événement d'arrêt de l'application"""
    logger.info("Arrêt de l'application...")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080) 
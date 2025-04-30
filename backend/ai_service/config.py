import os
from pathlib import Path

# Chemins
STORAGE_PATH = Path(os.getenv("STORAGE_PATH", "/app/storage"))
CACHE_PATH = Path(os.getenv("CACHE_PATH", "/app/cache"))
MODELS_PATH = Path(os.getenv("MODELS_PATH", "/app/models"))

# Configuration du serveur
PORT = int(os.getenv("PORT", 8001))
NUM_WORKERS = int(os.getenv("NUM_WORKERS", 4))
LOG_LEVEL = os.getenv("LOG_LEVEL", "info")

# Configuration de l'IA
DEVICE = os.getenv("DEVICE", "cuda")
BATCH_SIZE = int(os.getenv("BATCH_SIZE", 32))
PRECISION = os.getenv("PRECISION", "float32")

# Configuration Redis
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

# Configuration Bricklink
BRICKLINK_API_URL = os.getenv("BRICKLINK_API_URL", "https://api.bricklink.com/api/v2")
BRICKLINK_API_KEY = os.getenv("BRICKLINK_API_KEY")
BRICKLINK_API_SECRET = os.getenv("BRICKLINK_API_SECRET")

# Configuration LEGO
LEGO_API_URL = os.getenv("LEGO_API_URL", "https://api.lego.com/v1")
LEGO_API_KEY = os.getenv("LEGO_API_KEY")

# Création des répertoires nécessaires
for path in [STORAGE_PATH, CACHE_PATH, MODELS_PATH]:
    path.mkdir(parents=True, exist_ok=True)

# Configuration des modèles
MODEL_CONFIG = {
    "optimizer": {
        "learning_rate": 0.001,
        "weight_decay": 0.0001,
        "scheduler": {
            "type": "cosine",
            "T_max": 100,
            "eta_min": 1e-6
        }
    },
    "training": {
        "epochs": 100,
        "batch_size": BATCH_SIZE,
        "validation_split": 0.2,
        "early_stopping": {
            "patience": 10,
            "min_delta": 0.001
        }
    },
    "inference": {
        "batch_size": BATCH_SIZE,
        "num_workers": NUM_WORKERS,
        "device": DEVICE,
        "precision": PRECISION
    }
} 
import os
import torch
from pathlib import Path

# Chemins
BASE_DIR = Path(__file__).parent.parent
MODEL_PATH = Path("models/mobile_model.pt")

# Configuration du dispositif
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Configuration du prétraitement des images
IMAGE_SIZE = (224, 224)  # Taille standard pour de nombreux modèles
NORMALIZE_MEAN = [0.485, 0.456, 0.406]  # Moyennes ImageNet
NORMALIZE_STD = [0.229, 0.224, 0.225]   # Écart-types ImageNet

# Configuration de l'API
API_TITLE = "Brickify Mobile API"
API_VERSION = "1.0.0"
API_DESCRIPTION = "API pour l'analyse d'images avec PyTorch"

# Limites de l'API
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MB
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png"}

# Configuration du logging
LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
LOG_LEVEL = "INFO" 
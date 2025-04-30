import torch
import torchvision.transforms as transforms
from PIL import Image
import io
import logging
from typing import Dict, Optional
from pathlib import Path

from ..config.mobile_config import (
    MODEL_PATH,
    DEVICE,
    IMAGE_SIZE,
    NORMALIZE_MEAN,
    NORMALIZE_STD
)

logger = logging.getLogger(__name__)

class MobileService:
    def __init__(self):
        self.device = DEVICE
        self.model = None
        self.model_loaded = False
        self.transform = transforms.Compose([
            transforms.Resize(IMAGE_SIZE),
            transforms.ToTensor(),
            transforms.Normalize(mean=NORMALIZE_MEAN, std=NORMALIZE_STD)
        ])
        self._load_model()

    def _load_model(self) -> None:
        """
        Charge le modèle PyTorch depuis le chemin spécifié.
        """
        try:
            if not Path(MODEL_PATH).exists():
                logger.error(f"Le modèle n'existe pas à l'emplacement: {MODEL_PATH}")
                return

            self.model = torch.load(MODEL_PATH, map_location=self.device)
            self.model.eval()
            self.model_loaded = True
            logger.info(f"Modèle chargé avec succès sur {self.device}")
        except Exception as e:
            logger.error(f"Erreur lors du chargement du modèle: {str(e)}")
            self.model_loaded = False

    async def process_image(self, file) -> Dict:
        """
        Traite une image et retourne les prédictions.
        """
        if not self.model_loaded:
            raise RuntimeError("Le modèle n'est pas chargé")

        try:
            # Lecture de l'image
            contents = await file.read()
            image = Image.open(io.BytesIO(contents)).convert('RGB')
            
            # Prétraitement de l'image
            input_tensor = self.transform(image).unsqueeze(0).to(self.device)
            
            # Inférence
            with torch.no_grad():
                predictions = self.model(input_tensor)
            
            # Post-traitement des prédictions
            results = self._process_predictions(predictions)
            
            return {
                "success": True,
                "predictions": results
            }
            
        except Exception as e:
            logger.error(f"Erreur lors du traitement de l'image: {str(e)}")
            raise

    def _process_predictions(self, predictions: torch.Tensor) -> Dict:
        """
        Traite les prédictions du modèle pour les rendre exploitables.
        """
        # À adapter selon la structure de sortie de votre modèle
        probabilities = torch.softmax(predictions, dim=1)
        top_probs, top_indices = torch.topk(probabilities, k=5)
        
        return {
            "top_classes": top_indices[0].tolist(),
            "probabilities": top_probs[0].tolist()
        }

    def get_model_info(self) -> Dict:
        """
        Retourne les informations sur le modèle chargé.
        """
        return {
            "device": str(self.device),
            "model_loaded": self.model_loaded,
            "model_path": str(MODEL_PATH),
            "input_size": IMAGE_SIZE,
            "normalization": {
                "mean": NORMALIZE_MEAN,
                "std": NORMALIZE_STD
            }
        } 
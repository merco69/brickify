import logging
from typing import Dict, List, Optional, Tuple
import os
from pathlib import Path
import json
import torch
import torch.nn as nn
import torch.optim as optim
from datetime import datetime

from ..services.storage_service import StorageService
from ..services.db_service import DatabaseService

logger = logging.getLogger(__name__)

class BlockyService:
    def __init__(
        self,
        db_service: DatabaseService,
        storage_service: StorageService,
        models_dir: str = "models/blocky"
    ):
        """
        Initialise le service Blocky.
        
        Args:
            db_service: Service de base de données
            storage_service: Service de stockage
            models_dir: Dossier des modèles
        """
        self.db = db_service
        self.storage = storage_service
        self.models_dir = Path(models_dir)
        self.models_dir.mkdir(parents=True, exist_ok=True)
        
        # Charger ou initialiser les modèles
        self.models = self._load_models()
        
    def _load_models(self) -> Dict:
        """
        Charge les modèles depuis le stockage.
        
        Returns:
            Dict contenant les modèles
        """
        try:
            model_files = list(self.models_dir.glob("*.pt"))
            models = {}
            
            for model_file in model_files:
                model_name = model_file.stem
                model_path = str(model_file)
                
                # Charger le modèle
                model = torch.load(model_path)
                models[model_name] = model
                
            return models
            
        except Exception as e:
            logger.error(f"Erreur lors du chargement des modèles: {str(e)}")
            return {}
            
    async def convert_to_lego(
        self,
        model_path: str,
        user_id: str,
        settings: Dict
    ) -> Tuple[bool, str]:
        """
        Convertit un modèle 3D en LEGO.
        
        Args:
            model_path: Chemin du modèle 3D
            user_id: ID de l'utilisateur
            settings: Paramètres de conversion
            
        Returns:
            Tuple (succès, message)
        """
        try:
            # Vérifier que le fichier existe
            if not os.path.exists(model_path):
                return False, "Le fichier modèle n'existe pas"
                
            # Vérifier les permissions
            if not await self._check_permissions(user_id):
                return False, "Vous n'avez pas les permissions nécessaires"
                
            # Créer un dossier temporaire
            temp_dir = Path("temp") / f"conversion_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            temp_dir.mkdir(parents=True, exist_ok=True)
            
            try:
                # Copier le modèle dans le dossier temporaire
                model_name = os.path.basename(model_path)
                temp_model_path = temp_dir / model_name
                with open(model_path, 'rb') as src, open(temp_model_path, 'wb') as dst:
                    dst.write(src.read())
                    
                # Convertir le modèle
                success = await self._convert_model(temp_model_path, settings)
                
                if success:
                    # Sauvegarder le résultat
                    result_path = await self._save_result(temp_dir, user_id)
                    return True, f"Conversion réussie: {result_path}"
                else:
                    return False, "Erreur lors de la conversion"
                    
            finally:
                # Nettoyer le dossier temporaire
                import shutil
                shutil.rmtree(temp_dir)
                
        except Exception as e:
            logger.error(f"Erreur lors de la conversion: {str(e)}")
            return False, f"Erreur: {str(e)}"
            
    async def _check_permissions(self, user_id: str) -> bool:
        """
        Vérifie les permissions de l'utilisateur.
        
        Args:
            user_id: ID de l'utilisateur
            
        Returns:
            True si l'utilisateur a les permissions
        """
        try:
            user = await self.db.get_user(user_id)
            if not user:
                return False
                
            # Vérifier l'abonnement
            return user.get("subscription_type") in ["medium", "premium"]
            
        except Exception as e:
            logger.error(f"Erreur lors de la vérification des permissions: {str(e)}")
            return False
            
    async def _convert_model(self, model_path: Path, settings: Dict) -> bool:
        """
        Convertit le modèle en LEGO.
        
        Args:
            model_path: Chemin du modèle
            settings: Paramètres de conversion
            
        Returns:
            True si la conversion a réussi
        """
        try:
            # TODO: Implémenter la conversion avec les modèles d'IA
            return True
            
        except Exception as e:
            logger.error(f"Erreur lors de la conversion du modèle: {str(e)}")
            return False
            
    async def _save_result(self, temp_dir: Path, user_id: str) -> str:
        """
        Sauvegarde le résultat de la conversion.
        
        Args:
            temp_dir: Dossier temporaire
            user_id: ID de l'utilisateur
            
        Returns:
            Chemin du résultat sauvegardé
        """
        try:
            # Créer un dossier pour l'utilisateur
            user_dir = self.storage.get_user_dir(user_id)
            result_dir = user_dir / "lego_models"
            result_dir.mkdir(parents=True, exist_ok=True)
            
            # Copier les fichiers
            result_path = result_dir / f"model_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            import shutil
            shutil.copytree(temp_dir, result_path)
            
            return str(result_path)
            
        except Exception as e:
            logger.error(f"Erreur lors de la sauvegarde du résultat: {str(e)}")
            return ""
            
    async def get_model_info(self, model_id: str) -> Optional[Dict]:
        """
        Récupère les informations d'un modèle.
        
        Args:
            model_id: ID du modèle
            
        Returns:
            Informations du modèle ou None
        """
        try:
            return await self.db.get_lego_model(model_id)
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des informations du modèle: {str(e)}")
            return None
            
    async def delete_model(self, model_id: str, user_id: str) -> bool:
        """
        Supprime un modèle.
        
        Args:
            model_id: ID du modèle
            user_id: ID de l'utilisateur
            
        Returns:
            True si la suppression a réussi
        """
        try:
            # Vérifier les permissions
            model = await self.db.get_lego_model(model_id)
            if not model or model["user_id"] != user_id:
                return False
                
            # Supprimer le modèle
            await self.db.delete_lego_model(model_id)
            
            # Supprimer les fichiers
            model_path = Path(model["file_path"])
            if model_path.exists():
                import shutil
                shutil.rmtree(model_path)
                
            return True
            
        except Exception as e:
            logger.error(f"Erreur lors de la suppression du modèle: {str(e)}")
            return False 
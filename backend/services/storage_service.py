import os
import json
from typing import List, Dict, Optional, Any
from firebase_admin import storage, credentials, initialize_app, get_app
from datetime import datetime, timedelta
import logging
from ..cache import url_cache
from ..config import settings
from ..metrics import track_storage_operation
import uuid

logger = logging.getLogger(__name__)

class StorageService:
    """Service de stockage pour les fichiers"""
    
    def __init__(self, bucket_name: str = settings.FIREBASE_STORAGE_BUCKET):
        """
        Initialise le service de stockage
        
        Args:
            bucket_name: Nom du bucket Firebase Storage
        """
        try:
            app = get_app()
        except ValueError:
            cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
            if not cred_path:
                raise ValueError("FIREBASE_CREDENTIALS_PATH n'est pas défini")
            
            try:
                # Essayer de charger comme un JSON
                cred_dict = json.loads(cred_path)
                cred = credentials.Certificate(cred_dict)
            except json.JSONDecodeError:
                # Si ce n'est pas un JSON valide, traiter comme un chemin de fichier
                cred = credentials.Certificate(cred_path)
            
            initialize_app(cred, {'storageBucket': bucket_name})
        
        self.bucket = storage.bucket(bucket_name)
        logger.info(f"StorageService initialisé avec le bucket {bucket_name}")

    @track_storage_operation("upload")
    async def upload_model(self, file_content: bytes, user_id: Optional[str] = None) -> str:
        """
        Upload un modèle 3D
        
        Args:
            file_content: Contenu du fichier
            user_id: ID de l'utilisateur (optionnel)
            
        Returns:
            Chemin du fichier uploadé
        """
        try:
            # Création du chemin de destination
            filename = f"{user_id}/{uuid.uuid4()}.glb" if user_id else f"public/{uuid.uuid4()}.glb"
            blob = self.bucket.blob(filename)
            
            # Upload du fichier
            blob.upload_from_string(file_content)
            logger.info(f"Fichier uploadé avec succès: {filename}")
            
            return filename
            
        except Exception as e:
            logger.error(f"Erreur lors de l'upload du fichier: {str(e)}")
            raise

    @track_storage_operation("delete")
    async def delete_model(self, path: str) -> bool:
        """
        Supprime un modèle
        
        Args:
            path: Chemin du fichier
            
        Returns:
            True si supprimé, False sinon
        """
        try:
            blob = self.bucket.blob(path)
            blob.delete()
            
            # Suppression du cache
            url_cache.delete(path)
            
            logger.info(f"Fichier supprimé avec succès: {path}")
            return True
            
        except Exception as e:
            logger.error(f"Erreur lors de la suppression du fichier: {str(e)}")
            return False

    @track_storage_operation("get_url")
    async def get_model_url(self, path: str, expiration: int = 3600) -> str:
        """
        Récupère l'URL signée d'un modèle
        
        Args:
            path: Chemin du fichier
            expiration: Durée de validité de l'URL en secondes
            
        Returns:
            URL signée
        """
        try:
            # Vérification du cache
            cached_url = url_cache.get(path)
            if cached_url:
                return cached_url
            
            # Génération de l'URL signée
            blob = self.bucket.blob(path)
            url = blob.generate_signed_url(expiration=expiration)
            
            # Mise en cache
            url_cache.set(path, url, expiration)
            
            return url
            
        except Exception as e:
            logger.error(f"Erreur lors de la génération de l'URL: {str(e)}")
            raise

    @track_storage_operation("list")
    async def list_user_models(self, user_id: str) -> List[Dict[str, Any]]:
        """
        Liste les modèles d'un utilisateur
        
        Args:
            user_id: ID de l'utilisateur
            
        Returns:
            Liste des modèles avec leurs URLs
        """
        try:
            # Liste des blobs
            blobs = self.bucket.list_blobs(prefix=f"{user_id}/")
            
            # Récupération des URLs
            models = []
            for blob in blobs:
                url = await self.get_model_url(blob.name)
                models.append({
                    "path": blob.name,
                    "url": url,
                    "size": blob.size,
                    "created": blob.time_created
                })
            
            return models
            
        except Exception as e:
            logger.error(f"Erreur lors de la liste des modèles: {str(e)}")
            raise 
import logging
import os
import shutil
import psutil
import gc
import threading
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import torch
import numpy as np
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

class BlockyResourceManager:
    def __init__(
        self,
        base_dir: str = "/data/blocky",
        max_memory_gb: float = 8.0,
        max_storage_gb: float = 50.0,
        cleanup_interval_hours: int = 24,
        max_temp_files: int = 100,
        max_age_days: int = 7
    ):
        """
        Initialise le gestionnaire de ressources pour Blocky.
        
        Args:
            base_dir: Dossier de base pour le stockage
            max_memory_gb: Mémoire maximale en GB
            max_storage_gb: Stockage maximal en GB
            cleanup_interval_hours: Intervalle de nettoyage en heures
            max_temp_files: Nombre maximal de fichiers temporaires
            max_age_days: Âge maximal des fichiers en jours
        """
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)
        
        # Dossiers de stockage
        self.models_dir = self.base_dir / "models"
        self.temp_dir = self.base_dir / "temp"
        self.cache_dir = self.base_dir / "cache"
        self.results_dir = self.base_dir / "results"
        
        for dir_path in [self.models_dir, self.temp_dir, self.cache_dir, self.results_dir]:
            dir_path.mkdir(exist_ok=True)
            
        # Paramètres de ressources
        self.max_memory_bytes = max_memory_gb * 1024 * 1024 * 1024
        self.max_storage_bytes = max_storage_gb * 1024 * 1024 * 1024
        self.cleanup_interval = cleanup_interval_hours * 3600
        self.max_temp_files = max_temp_files
        self.max_age = timedelta(days=max_age_days)
        
        # Verrou pour les opérations concurrentes
        self.lock = threading.Lock()
        
        # Démarrer le thread de nettoyage
        self.cleanup_thread = threading.Thread(
            target=self._cleanup_loop,
            daemon=True
        )
        self.cleanup_thread.start()
        
        logger.info(f"BlockyResourceManager initialisé avec {max_memory_gb}GB de mémoire et {max_storage_gb}GB de stockage")
        
    def get_temp_dir(self, prefix: str = "temp") -> Path:
        """
        Crée et retourne un dossier temporaire.
        
        Args:
            prefix: Préfixe pour le nom du dossier
            
        Returns:
            Chemin du dossier temporaire
        """
        with self.lock:
            # Vérifier l'espace disponible
            self._check_storage_space()
            
            # Créer un dossier temporaire unique
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            temp_dir = self.temp_dir / f"{prefix}_{timestamp}"
            temp_dir.mkdir(exist_ok=True)
            
            return temp_dir
            
    def get_cache_path(self, key: str, extension: str = "") -> Path:
        """
        Retourne le chemin d'un fichier en cache.
        
        Args:
            key: Clé unique pour le cache
            extension: Extension du fichier
            
        Returns:
            Chemin du fichier en cache
        """
        # Créer un nom de fichier basé sur la clé
        filename = f"{key}{extension}"
        return self.cache_dir / filename
        
    def get_result_path(self, user_id: str, model_name: str) -> Path:
        """
        Retourne le chemin pour sauvegarder un résultat.
        
        Args:
            user_id: ID de l'utilisateur
            model_name: Nom du modèle
            
        Returns:
            Chemin pour le résultat
        """
        # Créer un dossier pour l'utilisateur
        user_dir = self.results_dir / user_id
        user_dir.mkdir(exist_ok=True)
        
        # Créer un nom de fichier unique
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        return user_dir / f"{model_name}_{timestamp}"
        
    def cleanup_temp_files(self) -> int:
        """
        Nettoie les fichiers temporaires.
        
        Returns:
            Nombre de fichiers supprimés
        """
        with self.lock:
            count = 0
            now = datetime.now()
            
            # Lister tous les fichiers temporaires
            temp_files = list(self.temp_dir.glob("*"))
            
            # Trier par date de modification
            temp_files.sort(key=lambda x: x.stat().st_mtime)
            
            # Supprimer les fichiers trop anciens
            for file_path in temp_files:
                file_age = datetime.fromtimestamp(file_path.stat().st_mtime)
                if now - file_age > self.max_age:
                    try:
                        if file_path.is_file():
                            file_path.unlink()
                        else:
                            shutil.rmtree(file_path)
                        count += 1
                    except Exception as e:
                        logger.error(f"Erreur lors de la suppression de {file_path}: {str(e)}")
                        
            # Si trop de fichiers, supprimer les plus anciens
            if len(temp_files) > self.max_temp_files:
                for file_path in temp_files[:len(temp_files) - self.max_temp_files]:
                    try:
                        if file_path.is_file():
                            file_path.unlink()
                        else:
                            shutil.rmtree(file_path)
                        count += 1
                    except Exception as e:
                        logger.error(f"Erreur lors de la suppression de {file_path}: {str(e)}")
                        
            return count
            
    def _check_storage_space(self):
        """
        Vérifie l'espace de stockage disponible.
        """
        # Obtenir l'espace utilisé
        total_size = sum(f.stat().st_size for f in self.base_dir.rglob('*') if f.is_file())
        
        # Si l'espace est presque plein, nettoyer
        if total_size > self.max_storage_bytes * 0.9:
            logger.warning(f"Espace de stockage presque plein ({total_size / (1024**3):.2f}GB). Nettoyage...")
            self.cleanup_temp_files()
            
    def _check_memory_usage(self):
        """
        Vérifie l'utilisation de la mémoire.
        """
        # Obtenir l'utilisation de la mémoire
        memory = psutil.Process().memory_info().rss
        
        # Si la mémoire est presque pleine, forcer le garbage collector
        if memory > self.max_memory_bytes * 0.8:
            logger.warning(f"Mémoire presque pleine ({memory / (1024**3):.2f}GB). Nettoyage...")
            gc.collect()
            torch.cuda.empty_cache() if torch.cuda.is_available() else None
            
    def _cleanup_loop(self):
        """
        Boucle de nettoyage périodique.
        """
        while True:
            try:
                # Attendre l'intervalle de nettoyage
                time.sleep(self.cleanup_interval)
                
                # Nettoyer les fichiers temporaires
                count = self.cleanup_temp_files()
                if count > 0:
                    logger.info(f"Nettoyage automatique: {count} fichiers supprimés")
                    
                # Vérifier l'utilisation de la mémoire
                self._check_memory_usage()
                
            except Exception as e:
                logger.error(f"Erreur dans la boucle de nettoyage: {str(e)}")
                
    def get_resource_stats(self) -> Dict:
        """
        Récupère les statistiques d'utilisation des ressources.
        
        Returns:
            Statistiques d'utilisation
        """
        # Obtenir l'espace utilisé
        total_size = sum(f.stat().st_size for f in self.base_dir.rglob('*') if f.is_file())
        
        # Obtenir l'utilisation de la mémoire
        memory = psutil.Process().memory_info().rss
        
        # Compter les fichiers
        temp_count = len(list(self.temp_dir.glob("*")))
        cache_count = len(list(self.cache_dir.glob("*")))
        results_count = len(list(self.results_dir.glob("*")))
        
        return {
            "storage": {
                "total": self.max_storage_bytes,
                "used": total_size,
                "available": self.max_storage_bytes - total_size,
                "percent": (total_size / self.max_storage_bytes) * 100
            },
            "memory": {
                "total": self.max_memory_bytes,
                "used": memory,
                "available": self.max_memory_bytes - memory,
                "percent": (memory / self.max_memory_bytes) * 100
            },
            "files": {
                "temp": temp_count,
                "cache": cache_count,
                "results": results_count
            }
        } 
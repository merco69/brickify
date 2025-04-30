import torch
import torch.nn as nn
import torch.optim as optim
from typing import Dict, List, Optional
import logging
from pathlib import Path
import numpy as np
from torch.utils.data import DataLoader, random_split
from sklearn.model_selection import KFold

logger = logging.getLogger(__name__)

class LegoModelLearner:
    def __init__(self, config: Dict):
        """
        Initialise le service d'apprentissage des modèles LEGO.
        
        Args:
            config: Configuration du modèle et de l'entraînement
        """
        self.config = config
        self.device = torch.device(config.get("device", "cuda" if torch.cuda.is_available() else "cpu"))
        self.model = self._build_model()
        self.optimizer = optim.Adam(
            self.model.parameters(),
            lr=config.get("learning_rate", 0.001)
        )
        self.criterion = nn.MSELoss()
        self.best_loss = float('inf')
        self.patience_counter = 0
        self.early_stopping_patience = config.get("early_stopping_patience", 10)
        
    def _build_model(self) -> nn.Module:
        """Construit l'architecture du modèle."""
        model = nn.Sequential(
            nn.Conv3d(1, 32, kernel_size=3, padding=1),
            nn.BatchNorm3d(32),
            nn.ReLU(),
            nn.MaxPool3d(2),
            nn.Dropout3d(0.2),
            
            nn.Conv3d(32, 64, kernel_size=3, padding=1),
            nn.BatchNorm3d(64),
            nn.ReLU(),
            nn.MaxPool3d(2),
            nn.Dropout3d(0.2),
            
            nn.Conv3d(64, 128, kernel_size=3, padding=1),
            nn.BatchNorm3d(128),
            nn.ReLU(),
            nn.ConvTranspose3d(128, 64, kernel_size=2, stride=2),
            nn.BatchNorm3d(64),
            nn.ReLU(),
            nn.Dropout3d(0.2),
            
            nn.ConvTranspose3d(64, 32, kernel_size=2, stride=2),
            nn.BatchNorm3d(32),
            nn.ReLU(),
            nn.Conv3d(32, 1, kernel_size=1),
            nn.Sigmoid()
        )
        return model.to(self.device)
    
    async def learn_from_model(self, model_data: Dict) -> Dict:
        """
        Apprend à partir d'un modèle LEGO existant avec validation croisée.
        
        Args:
            model_data: Données du modèle à partir desquelles apprendre
            
        Returns:
            Dict contenant les résultats de l'apprentissage
        """
        try:
            # Préparation des données
            input_tensor = self._preprocess_model_data(model_data)
            
            # Validation croisée
            k_folds = 5
            kfold = KFold(n_splits=k_folds, shuffle=True)
            fold_results = []
            
            for fold, (train_idx, val_idx) in enumerate(kfold.split(input_tensor)):
                train_data = input_tensor[train_idx]
                val_data = input_tensor[val_idx]
                
                # Entraînement
                self.model.train()
                self.optimizer.zero_grad()
                
                output = self.model(train_data)
                loss = self.criterion(output, train_data)
                
                loss.backward()
                self.optimizer.step()
                
                # Évaluation sur la validation
                self.model.eval()
                with torch.no_grad():
                    val_output = self.model(val_data)
                    val_loss = self.criterion(val_output, val_data)
                    metrics = self._evaluate_model(val_output, val_data)
                    
                fold_results.append({
                    "fold": fold + 1,
                    "train_loss": loss.item(),
                    "val_loss": val_loss.item(),
                    "metrics": metrics
                })
                
                # Early stopping
                if val_loss < self.best_loss:
                    self.best_loss = val_loss
                    self.patience_counter = 0
                    self.save_model(Path("best_model.pt"))
                else:
                    self.patience_counter += 1
                    if self.patience_counter >= self.early_stopping_patience:
                        logger.info("Early stopping triggered")
                        break
            
            return {
                "status": "success",
                "fold_results": fold_results,
                "best_loss": self.best_loss
            }
            
        except Exception as e:
            logger.error(f"Erreur lors de l'apprentissage: {str(e)}")
            raise
    
    def _preprocess_model_data(self, model_data: Dict) -> torch.Tensor:
        """Prétraite les données du modèle pour l'entraînement avec augmentation."""
        voxel_data = np.array(model_data["voxels"])
        
        # Augmentation des données
        augmented_data = []
        for _ in range(self.config.get("augmentation_samples", 5)):
            # Rotation aléatoire
            angle = np.random.uniform(-15, 15)
            rotated = self._rotate_voxels(voxel_data, angle)
            
            # Mise à l'échelle aléatoire
            scale = np.random.uniform(0.9, 1.1)
            scaled = self._scale_voxels(rotated, scale)
            
            augmented_data.append(scaled)
        
        # Conversion en tensor
        tensor_data = torch.FloatTensor(np.array(augmented_data)).unsqueeze(1)
        return tensor_data.to(self.device)
    
    def _rotate_voxels(self, voxels: np.ndarray, angle: float) -> np.ndarray:
        """Applique une rotation 3D aux voxels."""
        # Implémentation de la rotation 3D
        return voxels  # À implémenter selon les besoins
    
    def _scale_voxels(self, voxels: np.ndarray, scale: float) -> np.ndarray:
        """Applique une mise à l'échelle aux voxels."""
        return voxels * scale
    
    def _evaluate_model(self, output: torch.Tensor, target: torch.Tensor) -> Dict:
        """Évalue les performances du modèle avec des métriques supplémentaires."""
        mse = self.criterion(output, target).item()
        accuracy = (torch.abs(output - target) < 0.1).float().mean().item()
        
        # Calcul de la précision par voxel
        voxel_accuracy = (output > 0.5).float() == (target > 0.5).float()
        voxel_precision = voxel_accuracy.float().mean().item()
        
        return {
            "mse": mse,
            "accuracy": accuracy,
            "voxel_precision": voxel_precision
        }
    
    def save_model(self, path: Path):
        """Sauvegarde le modèle entraîné avec métadonnées."""
        torch.save({
            "model_state": self.model.state_dict(),
            "optimizer_state": self.optimizer.state_dict(),
            "config": self.config,
            "best_loss": self.best_loss,
            "patience_counter": self.patience_counter
        }, path)
    
    def load_model(self, path: Path):
        """Charge un modèle sauvegardé avec métadonnées."""
        checkpoint = torch.load(path)
        self.model.load_state_dict(checkpoint["model_state"])
        self.optimizer.load_state_dict(checkpoint["optimizer_state"])
        self.config = checkpoint["config"]
        self.best_loss = checkpoint["best_loss"]
        self.patience_counter = checkpoint["patience_counter"] 
import logging
import torch
import numpy as np
from typing import List, Tuple, Optional, Dict
from .blocky_service import Brick
from dataclasses import dataclass
import json
import os
import requests
from datetime import datetime

logger = logging.getLogger(__name__)

class BlockyOptimizer:
    def __init__(self, device=None, num_workers=0, batch_size=1, precision="float32"):
        self.device = device or torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.num_workers = num_workers
        self.batch_size = batch_size
        self.precision = precision
        logger.info(f"Initialized BlockyOptimizer with device={self.device}")
        
        # Paramètres d'optimisation
        self.MIN_BRICK_VOLUME = 0.5
        self.MAX_OVERHANG = 0.5
        self.MIN_SUPPORT = 0.3
        self.MERGE_THRESHOLD = 0.8
        
        # Paramètres d'apprentissage
        self.LEARNING_RATE = 0.01
        self.MODEL_DB_PATH = "models/lego_models.json"
        self.BRICKLINK_DB_PATH = "models/bricklink_models.json"
        self.LEGO_DB_PATH = "models/lego_official_models.json"
        self.BRICKLINK_COLORS_PATH = "models/bricklink_colors.json"
        self.LEGO_COLORS_PATH = "models/lego_colors.json"
        self.BRICKLINK_PARTS_PATH = "models/bricklink_parts.json"
        self.LEGO_PARTS_PATH = "models/lego_parts.json"
        
        # Chargement des bases de données
        self.successful_models = self._load_successful_models()
        self.bricklink_models = self._load_bricklink_models()
        self.lego_models = self._load_lego_models()
        self.bricklink_colors = self._load_bricklink_colors()
        self.lego_colors = self._load_lego_colors()
        self.bricklink_parts = self._load_bricklink_parts()
        self.lego_parts = self._load_lego_parts()
        
        # Paramètres API
        self.BRICKLINK_API_URL = "https://api.bricklink.com/api/v2"
        self.LEGO_API_URL = "https://api.lego.com/v1"
        self.UPDATE_INTERVAL = 86400  # 24 heures en secondes
        self.last_update = self._load_last_update_time()
        
        # Formats de briques supportés
        self.brick_formats = {
            'standard': ['1x1', '1x2', '1x3', '1x4', '1x6', '1x8', '2x2', '2x3', '2x4', '2x6', '2x8'],
            'technic': ['1x1', '1x2', '1x3', '1x4', '1x6', '1x8', '2x2', '2x3', '2x4', '2x6', '2x8'],
            'plate': ['1x1', '1x2', '1x3', '1x4', '1x6', '1x8', '2x2', '2x3', '2x4', '2x6', '2x8'],
            'slope': ['1x1', '1x2', '1x3', '1x4', '2x2', '2x3', '2x4'],
            'special': ['round', 'curved', 'arch', 'window', 'door']
        }

    def _load_lego_models(self) -> Dict:
        """Charge les modèles officiels LEGO."""
        if os.path.exists(self.LEGO_DB_PATH):
            with open(self.LEGO_DB_PATH, 'r') as f:
                return json.load(f)
        return {}

    def _load_lego_colors(self) -> Dict:
        """Charge les couleurs officielles LEGO."""
        if os.path.exists(self.LEGO_COLORS_PATH):
            with open(self.LEGO_COLORS_PATH, 'r') as f:
                return json.load(f)
        return {}

    def _load_lego_parts(self) -> Dict:
        """Charge les pièces officielles LEGO."""
        if os.path.exists(self.LEGO_PARTS_PATH):
            with open(self.LEGO_PARTS_PATH, 'r') as f:
                return json.load(f)
        return {}

    def _update_catalogs(self):
        """Met à jour les catalogues LEGO et Bricklink."""
        try:
            current_time = datetime.now().timestamp()
            if current_time - self.last_update < self.UPDATE_INTERVAL:
                return

            # Mise à jour Bricklink
            self._update_bricklink_catalog()
            
            # Mise à jour LEGO
            self._update_lego_catalog()
            
            self._save_last_update_time()
            self.last_update = current_time
                
        except Exception as e:
            logger.error(f"Erreur lors de la mise à jour des catalogues: {str(e)}")

    def _update_lego_catalog(self):
        """Met à jour le catalogue officiel LEGO."""
        try:
            # Récupère les couleurs LEGO
            colors_response = requests.get(f"{self.LEGO_API_URL}/colors")
            if colors_response.status_code == 200:
                self.lego_colors = colors_response.json()
                with open(self.LEGO_COLORS_PATH, 'w') as f:
                    json.dump(self.lego_colors, f)

            # Récupère les pièces LEGO
            parts_response = requests.get(f"{self.LEGO_API_URL}/parts")
            if parts_response.status_code == 200:
                self.lego_parts = parts_response.json()
                with open(self.LEGO_PARTS_PATH, 'w') as f:
                    json.dump(self.lego_parts, f)

            # Récupère les sets LEGO
            sets_response = requests.get(f"{self.LEGO_API_URL}/sets")
            if sets_response.status_code == 200:
                all_sets = sets_response.json()
                
                for set_info in all_sets:
                    set_id = set_info['set_id']
                    if set_id not in self.lego_models:
                        set_details = requests.get(f"{self.LEGO_API_URL}/sets/{set_id}/parts")
                        if set_details.status_code == 200:
                            self.lego_models[set_id] = {
                                'parts': set_details.json(),
                                'year': set_info.get('year', 0),
                                'theme': set_info.get('theme', ''),
                                'last_updated': datetime.now().timestamp()
                            }
                
                with open(self.LEGO_DB_PATH, 'w') as f:
                    json.dump(self.lego_models, f)
                    
        except Exception as e:
            logger.error(f"Erreur lors de la mise à jour du catalogue LEGO: {str(e)}")

    def _update_brick_scores(self, bricks: List[Brick]):
        """Met à jour les scores des briques en tenant compte de LEGO et Bricklink."""
        self._update_catalogs()
        
        for brick in bricks:
            # Cherche des briques similaires dans les deux sources
            similar_parts = []
            
            # Vérifie chaque format de brique
            for format_name, sizes in self.brick_formats.items():
                for size in sizes:
                    if self._matches_brick_size(brick.size, size):
                        # Cherche dans les sets LEGO
                        for set_id, set_data in self.lego_models.items():
                            for part in set_data['parts']:
                                if (part['size'] == size and 
                                    part['format'] == format_name and
                                    abs(part['stability_score'] - brick.stability_score) < 0.1):
                                    similar_parts.append({
                                        'part': part,
                                        'format': format_name,
                                        'theme': set_data['theme'],
                                        'year': set_data['year'],
                                        'manufacturer': 'lego'
                                    })
                        
                        # Cherche dans les sets Bricklink
                        for set_id, set_data in self.bricklink_models.items():
                            for part in set_data['parts']:
                                if (part['size'] == size and 
                                    part['format'] == format_name and
                                    abs(part['stability_score'] - brick.stability_score) < 0.1):
                                    similar_parts.append({
                                        'part': part,
                                        'format': format_name,
                                        'theme': set_data['theme'],
                                        'year': set_data['year'],
                                        'manufacturer': 'bricklink'
                                    })
            
            if similar_parts:
                # Calcule les scores séparément pour LEGO et Bricklink
                lego_score = 0
                bricklink_score = 0
                lego_count = 0
                bricklink_count = 0
                
                current_year = datetime.now().year
                
                for part in similar_parts:
                    # Score de base
                    base_score = 1.0
                    
                    # Bonus pour les formats techniques
                    if part['format'] == 'technic':
                        base_score *= 1.2
                    
                    # Bonus pour les thèmes populaires
                    if part['theme'] in ['City', 'Star Wars', 'Architecture']:
                        base_score *= 1.1
                    
                    # Bonus pour les pièces récentes
                    age_factor = 1.0 - (current_year - part['year']) / 100
                    base_score *= max(0.5, age_factor)
                    
                    # Ajoute au score approprié
                    if part['manufacturer'] == 'lego':
                        lego_score += base_score
                        lego_count += 1
                    else:
                        bricklink_score += base_score
                        bricklink_count += 1
                
                # Calcule les scores moyens
                if lego_count > 0:
                    brick.lego_score = lego_score / lego_count
                if bricklink_count > 0:
                    brick.bricklink_score = bricklink_score / bricklink_count
                
                # Détermine le fabricant final
                if brick.lego_score > brick.bricklink_score:
                    brick.manufacturer = 'lego'
                else:
                    brick.manufacturer = 'bricklink'
                
                brick.brick_format = similar_parts[0]['format']

    def _assign_colors(self, bricks: List[Brick], colors: torch.Tensor) -> List[Brick]:
        """Assigne les couleurs les plus proches aux briques en utilisant les deux catalogues."""
        for brick in bricks:
            x, y, z = brick.position
            w, h, d = brick.size
            
            # Calcule la couleur moyenne de la région
            region_colors = colors[x:x+w, y:y+h, z:z+d]
            avg_color = torch.mean(region_colors, dim=(0,1,2))
            
            # Cherche la meilleure couleur dans les deux catalogues
            best_color = None
            min_distance = float('inf')
            
            # Vérifie les couleurs LEGO
            for color_id, color_info in self.lego_colors.items():
                color_rgb = color_info['rgb']
                distance = torch.sum((torch.tensor(color_rgb) - avg_color) ** 2)
                if distance < min_distance:
                    min_distance = distance
                    best_color = color_rgb
            
            # Vérifie les couleurs Bricklink
            for color_id, color_info in self.bricklink_colors.items():
                color_rgb = color_info['rgb']
                distance = torch.sum((torch.tensor(color_rgb) - avg_color) ** 2)
                if distance < min_distance:
                    min_distance = distance
                    best_color = color_rgb
                    
            brick.color = best_color
            
        return bricks

    def optimize_mesh(self, voxels: np.ndarray, colors: Optional[np.ndarray] = None, model_id: Optional[str] = None) -> List[Brick]:
        """Optimise un maillage voxelisé en briques LEGO avec apprentissage."""
        self.logger.info("Début de l'optimisation du maillage avec apprentissage")
        
        # Convertit en tenseur PyTorch
        voxel_tensor = torch.from_numpy(voxels).to(self.device)
        if colors is not None:
            color_tensor = torch.from_numpy(colors).to(self.device)
        
        # Identifie les régions critiques
        critical_regions = self._identify_critical_regions(voxel_tensor)
        
        # Génère la disposition initiale
        bricks = self._generate_initial_layout(voxels)
        
        # Met à jour les scores d'apprentissage
        if model_id:
            self._update_learning_scores(bricks, model_id)
        
        # Met à jour les scores LEGO et Bricklink
        self._update_brick_scores(bricks)
        
        # Optimise la stabilité en tenant compte des scores d'apprentissage
        bricks = self._optimize_stability(bricks, critical_regions)
        
        # Optimise les connexions
        bricks = self._optimize_connections(bricks)
        
        # Assigne les couleurs si disponibles
        if colors is not None:
            bricks = self._assign_colors(bricks, color_tensor)
        
        # Sauvegarde le modèle si les métriques sont satisfaisantes
        if model_id and self._evaluate_model_quality(bricks):
            metrics = self._calculate_model_metrics(bricks)
            self._save_successful_model(model_id, bricks, metrics)
        
        self.logger.info(f"Optimisation terminée : {len(bricks)} briques générées")
        return bricks

    def _evaluate_model_quality(self, bricks: List[Brick]) -> bool:
        """Évalue la qualité globale du modèle."""
        if not bricks:
            return False
            
        # Calcule les métriques de qualité
        avg_stability = sum(b.stability_score for b in bricks) / len(bricks)
        avg_connection = sum(b.connection_score for b in bricks) / len(bricks)
        avg_learning = sum(b.learning_score for b in bricks) / len(bricks)
        avg_lego = sum(b.lego_score for b in bricks) / len(bricks)
        avg_bricklink = sum(b.bricklink_score for b in bricks) / len(bricks)
        
        # Définit les seuils de qualité
        return (avg_stability > 0.7 and 
                avg_connection > 0.6 and 
                avg_learning > 0.5 and
                (avg_lego > 0.4 or avg_bricklink > 0.4))

    def _calculate_model_metrics(self, bricks: List[Brick]) -> Dict:
        """Calcule les métriques détaillées du modèle."""
        return {
            'total_bricks': len(bricks),
            'avg_stability': sum(b.stability_score for b in bricks) / len(bricks),
            'avg_connection': sum(b.connection_score for b in bricks) / len(bricks),
            'avg_learning': sum(b.learning_score for b in bricks) / len(bricks),
            'avg_lego': sum(b.lego_score for b in bricks) / len(bricks),
            'avg_bricklink': sum(b.bricklink_score for b in bricks) / len(bricks),
            'size_distribution': self._calculate_size_distribution(bricks),
            'manufacturer_distribution': self._calculate_manufacturer_distribution(bricks)
        }

    def _calculate_manufacturer_distribution(self, bricks: List[Brick]) -> Dict:
        """Calcule la distribution des fabricants."""
        distribution = {'lego': 0, 'bricklink': 0}
        for brick in bricks:
            distribution[brick.manufacturer] += 1
        return distribution

    def _load_successful_models(self) -> Dict:
        """Charge les modèles réussis depuis la base de données."""
        if os.path.exists(self.MODEL_DB_PATH):
            with open(self.MODEL_DB_PATH, 'r') as f:
                return json.load(f)
        return {}

    def _save_successful_model(self, model_id: str, bricks: List[Brick], metrics: Dict):
        """Sauvegarde un modèle réussi dans la base de données."""
        model_data = {
            'bricks': [
                {
                    'position': b.position,
                    'size': b.size,
                    'stability_score': b.stability_score,
                    'connection_score': b.connection_score,
                    'learning_score': b.learning_score,
                    'bricklink_score': b.bricklink_score,
                    'brick_format': b.brick_format
                }
                for b in bricks
            ],
            'metrics': metrics
        }
        
        self.successful_models[model_id] = model_data
        
        os.makedirs(os.path.dirname(self.MODEL_DB_PATH), exist_ok=True)
        with open(self.MODEL_DB_PATH, 'w') as f:
            json.dump(self.successful_models, f)

    def _load_bricklink_models(self) -> Dict:
        """Charge les modèles Bricklink depuis la base de données."""
        if os.path.exists(self.BRICKLINK_DB_PATH):
            with open(self.BRICKLINK_DB_PATH, 'r') as f:
                return json.load(f)
        return {}

    def _load_bricklink_colors(self) -> Dict:
        """Charge toutes les couleurs disponibles sur Bricklink."""
        if os.path.exists(self.BRICKLINK_COLORS_PATH):
            with open(self.BRICKLINK_COLORS_PATH, 'r') as f:
                return json.load(f)
        return {}

    def _load_bricklink_parts(self) -> Dict:
        """Charge tous les types de pièces disponibles sur Bricklink."""
        if os.path.exists(self.BRICKLINK_PARTS_PATH):
            with open(self.BRICKLINK_PARTS_PATH, 'r') as f:
                return json.load(f)
        return {}

    def _load_last_update_time(self) -> float:
        """Charge la dernière mise à jour de Bricklink."""
        try:
            with open("models/bricklink_last_update.txt", 'r') as f:
                return float(f.read().strip())
        except:
            return 0.0

    def _save_last_update_time(self):
        """Sauvegarde le temps de dernière mise à jour de Bricklink."""
        os.makedirs(os.path.dirname(self.BRICKLINK_DB_PATH), exist_ok=True)
        with open("models/bricklink_last_update.txt", 'w') as f:
            f.write(str(datetime.now().timestamp()))

    def _update_bricklink_catalog(self):
        """Met à jour le catalogue complet de Bricklink."""
        try:
            # Récupère toutes les couleurs
            colors_response = requests.get(f"{self.BRICKLINK_API_URL}/colors")
            if colors_response.status_code == 200:
                self.bricklink_colors = colors_response.json()
                with open(self.BRICKLINK_COLORS_PATH, 'w') as f:
                    json.dump(self.bricklink_colors, f)

            # Récupère tous les types de pièces
            parts_response = requests.get(f"{self.BRICKLINK_API_URL}/parts")
            if parts_response.status_code == 200:
                self.bricklink_parts = parts_response.json()
                with open(self.BRICKLINK_PARTS_PATH, 'w') as f:
                    json.dump(self.bricklink_parts, f)

            # Récupère tous les sets (pas seulement les populaires)
            sets_response = requests.get(f"{self.BRICKLINK_API_URL}/sets")
            if sets_response.status_code == 200:
                all_sets = sets_response.json()
                
                for set_info in all_sets:
                    set_id = set_info['set_id']
                    if set_id not in self.bricklink_models:
                        # Récupère les détails du set
                        set_details = requests.get(f"{self.BRICKLINK_API_URL}/sets/{set_id}/parts")
                        if set_details.status_code == 200:
                            self.bricklink_models[set_id] = {
                                'parts': set_details.json(),
                                'year': set_info.get('year', 0),
                                'theme': set_info.get('theme', ''),
                                'last_updated': datetime.now().timestamp()
                            }
                
                # Sauvegarde les modèles mis à jour
                with open(self.BRICKLINK_DB_PATH, 'w') as f:
                    json.dump(self.bricklink_models, f)
                
                self._save_last_update_time()
                
        except Exception as e:
            logger.error(f"Erreur lors de la mise à jour du catalogue Bricklink: {str(e)}")

    def _update_learning_scores(self, bricks: List[Brick], model_id: str):
        """Met à jour les scores d'apprentissage basés sur les modèles réussis."""
        if model_id in self.successful_models:
            successful_bricks = self.successful_models[model_id]['bricks']
            
            for brick in bricks:
                # Trouve les briques similaires dans les modèles réussis
                similar_bricks = [
                    sb for sb in successful_bricks
                    if sb['size'] == brick.size and
                    abs(sb['stability_score'] - brick.stability_score) < 0.1
                ]
                
                if similar_bricks:
                    # Calcule le score d'apprentissage moyen
                    avg_score = sum(sb['learning_score'] for sb in similar_bricks) / len(similar_bricks)
                    brick.learning_score = (brick.learning_score + avg_score) / 2

    def _identify_critical_regions(self, voxels: torch.Tensor) -> torch.Tensor:
        """Identifie les régions nécessitant une attention particulière pour la stabilité."""
        critical = torch.zeros_like(voxels, dtype=bool)
        
        # Marque les surplombs
        padded = torch.nn.functional.pad(voxels, (0,0,0,0,1,0))
        overhangs = voxels & ~padded[:-1,:,:]
        critical |= overhangs
        
        # Marque les zones de transition
        gradients = torch.gradient(voxels.float())
        for grad in gradients:
            critical |= (grad != 0)
            
        return critical

    def _generate_initial_layout(self, voxels: np.ndarray, brick_sizes: List[Tuple[int, int, int]]) -> List[Brick]:
        """Génère une disposition initiale des briques."""
        bricks = []
        visited = np.zeros_like(voxels, dtype=bool)
        
        # Trie les tailles de briques par volume décroissant
        sorted_sizes = sorted(brick_sizes, key=lambda s: s[0] * s[1] * s[2], reverse=True)
        
        # Parcours chaque couche
        for z in range(voxels.shape[0]):
            layer = voxels[z]
            layer_visited = visited[z]
            
            # Parcours chaque position dans la couche
            for y in range(layer.shape[0]):
                for x in range(layer.shape[1]):
                    if layer[y, x] and not layer_visited[y, x]:
                        # Trouve la meilleure brique pour cette position
                        brick = self._find_best_brick_fit(voxels, visited, x, y, z, sorted_sizes)
                        if brick:
                            bricks.append(brick)
                            self._mark_brick_space(visited, brick)
        
        return bricks

    def _find_best_brick_fit(self, voxels: np.ndarray, visited: np.ndarray, 
                            x: int, y: int, z: int, sizes: List[Tuple[int, int, int]]) -> Brick:
        """Trouve la meilleure brique qui s'adapte à une position donnée."""
        best_brick = None
        max_score = -1
        
        for size in sizes:
            if self._can_place_brick(voxels, visited, x, y, z, size):
                # Calcule un score basé sur le volume et la stabilité
                volume_score = size[0] * size[1] * size[2]
                stability_score = self._calculate_preliminary_stability(voxels, x, y, z, size)
                total_score = volume_score * stability_score
                
                if total_score > max_score:
                    max_score = total_score
                    best_brick = Brick(
                        position=(x, y, z),
                        size=size,
                        stability_score=stability_score
                    )
        
        return best_brick

    def _can_place_brick(self, voxels: np.ndarray, visited: np.ndarray, 
                        x: int, y: int, z: int, size: Tuple[int, int, int]) -> bool:
        """Vérifie si une brique peut être placée à une position donnée."""
        w, l, h = size
        
        # Vérifie les limites
        if (x + w > voxels.shape[2] or y + l > voxels.shape[1] or 
            z + h > voxels.shape[0]):
            return False
        
        # Vérifie que l'espace est disponible et rempli de voxels
        for dz in range(h):
            for dy in range(l):
                for dx in range(w):
                    if (not voxels[z + dz, y + dy, x + dx] or 
                        visited[z + dz, y + dy, x + dx]):
                        return False
        
        return True

    def _calculate_preliminary_stability(self, voxels: np.ndarray, 
                                      x: int, y: int, z: int, 
                                      size: Tuple[int, int, int]) -> float:
        """Calcule un score de stabilité préliminaire pour une brique."""
        w, l, h = size
        if z == 0:  # Brique au sol
            return 1.0
        
        # Vérifie le support en dessous
        support_count = 0
        total_area = w * l
        
        for dy in range(l):
            for dx in range(w):
                if z > 0 and voxels[z - 1, y + dy, x + dx]:
                    support_count += 1
        
        return support_count / total_area

    def _mark_brick_space(self, visited: np.ndarray, brick: Brick):
        """Marque l'espace occupé par une brique comme visité."""
        x, y, z = brick.position
        w, l, h = brick.size
        
        visited[z:z+h, y:y+l, x:x+w] = True

    def _optimize_stability(self, bricks: List[Brick], critical_regions: torch.Tensor) -> List[Brick]:
        """Optimise la stabilité de la structure."""
        optimized = []
        
        # Trie les briques par hauteur croissante
        sorted_bricks = sorted(bricks, key=lambda b: b.position[2])
        
        for brick in sorted_bricks:
            # Vérifie si la brique est dans une région critique
            if self._is_in_critical_region(brick, critical_regions):
                # Ajoute des supports supplémentaires si nécessaire
                reinforced_brick = self._reinforce_brick(brick, optimized)
                optimized.append(reinforced_brick)
            else:
                optimized.append(brick)
        
        return optimized

    def _is_in_critical_region(self, brick: Brick, critical_regions: torch.Tensor) -> bool:
        """Vérifie si une brique est dans une région critique."""
        x, y, z = brick.position
        w, l, h = brick.size
        
        # Vérifie si une partie de la brique est dans une région critique
        region = critical_regions[z:z+h, y:y+l, x:x+w]
        return region.any().item()

    def _reinforce_brick(self, brick: Brick, existing_bricks: List[Brick]) -> Brick:
        """Renforce une brique si nécessaire."""
        # Calcule le support actuel
        support_score = self._calculate_support_score(brick, existing_bricks)
        
        if support_score < self.MIN_SUPPORT:
            # Ajuste la taille de la brique pour améliorer la stabilité
            new_size = list(brick.size)
            
            # Si possible, augmente la surface de contact
            if brick.size[0] == 1 and brick.size[1] > 2:
                new_size[0] = 2
                new_size[1] = max(2, brick.size[1] - 1)
            
            brick.size = tuple(new_size)
            brick.stability_score = max(support_score, self.MIN_SUPPORT)
        
        return brick

    def _calculate_support_score(self, brick: Brick, supporting_bricks: List[Brick]) -> float:
        """Calcule le score de support pour une brique."""
        if brick.position[2] == 0:  # Brique au sol
            return 1.0
            
        x, y, z = brick.position
        w, l, _ = brick.size
        total_area = w * l
        supported_area = 0
        
        for support in supporting_bricks:
            if support.position[2] + support.size[2] == z:  # Brique juste en dessous
                # Calcule la zone de chevauchement
                sx, sy, _ = support.position
                sw, sl, _ = support.size
                
                overlap_x = max(0, min(x + w, sx + sw) - max(x, sx))
                overlap_y = max(0, min(y + l, sy + sl) - max(y, sy))
                supported_area += overlap_x * overlap_y
        
        return supported_area / total_area

    def _optimize_connections(self, bricks: List[Brick]) -> List[Brick]:
        """Optimise les connexions entre les briques."""
        optimized = []
        current_layer = []
        current_height = 0
        
        # Trie les briques par hauteur
        sorted_bricks = sorted(bricks, key=lambda b: b.position[2])
        
        for brick in sorted_bricks:
            if brick.position[2] != current_height:
                # Optimise la couche courante
                if current_layer:
                    optimized.extend(self._optimize_layer_connections(current_layer))
                current_layer = []
                current_height = brick.position[2]
            current_layer.append(brick)
            
        # Traite la dernière couche
        if current_layer:
            optimized.extend(self._optimize_layer_connections(current_layer))
            
        return optimized

    def _optimize_layer_connections(self, layer: List[Brick]) -> List[Brick]:
        """Optimise les connexions dans une couche spécifique."""
        optimized = []
        while layer:
            best_pair = None
            best_score = -1
            
            # Cherche la meilleure paire de briques à fusionner
            for i, brick1 in enumerate(layer):
                for j, brick2 in enumerate(layer[i+1:], i+1):
                    if self._can_merge(brick1, brick2):
                        score = self._calculate_connection_score(brick1, brick2)
                        if score > best_score:
                            best_score = score
                            best_pair = (i, j)
                            
            if best_pair is not None:
                i, j = best_pair
                merged = self._merge_bricks(layer[i], layer[j])
                layer.pop(j)
                layer.pop(i)
                layer.append(merged)
            else:
                # Plus de fusion possible, ajoute la brique restante
                optimized.append(layer.pop(0))
                
        return optimized

    def _calculate_connection_score(self, brick1: Brick, brick2: Brick) -> float:
        """Calcule un score de connexion entre deux briques."""
        overlap = self._calculate_overlap(brick1, brick2)
        
        # Pénalise les connexions instables
        if overlap < self.MIN_OVERLAP:
            return 0.0
            
        # Favorise les connexions qui créent des briques plus grandes
        size_score = min(brick1.size[0] + brick2.size[0], 
                        brick1.size[1] + brick2.size[1]) / 8.0
                        
        return overlap * size_score

    def _can_merge(self, brick1: Brick, brick2: Brick) -> bool:
        """Vérifie si deux briques peuvent être fusionnées."""
        x1, y1, z1 = brick1.position
        x2, y2, z2 = brick2.position
        w1, h1, d1 = brick1.size
        w2, h2, d2 = brick2.size
        
        # Vérifie si les briques sont sur le même niveau
        if z1 != z2 or d1 != d2:
            return False
            
        # Vérifie si les briques sont adjacentes
        touching_x = (x1 + w1 == x2) or (x2 + w2 == x1)
        touching_y = (y1 + h1 == y2) or (y2 + h2 == y1)
        
        return touching_x or touching_y

    def _calculate_overlap(self, brick1: Brick, brick2: Brick) -> float:
        """Calcule le chevauchement entre deux briques."""
        x1, y1, z1 = brick1.position
        x2, y2, z2 = brick2.position
        w1, h1, d1 = brick1.size
        w2, h2, d2 = brick2.size
        
        x_overlap = max(0, min(x1 + w1, x2 + w2) - max(x1, x2))
        y_overlap = max(0, min(y1 + h1, y2 + h2) - max(y1, y2))
        
        overlap_area = x_overlap * y_overlap
        min_area = min(w1 * h1, w2 * h2)
        
        return overlap_area / min_area if min_area > 0 else 0.0

    def _merge_bricks(self, brick1: Brick, brick2: Brick) -> Brick:
        """Fusionne deux briques en une seule."""
        x = min(brick1.position[0], brick2.position[0])
        y = min(brick1.position[1], brick2.position[1])
        z = brick1.position[2]  # Même hauteur
        
        # Calcule la nouvelle taille
        if brick1.position[0] == brick2.position[0]:  # Fusion verticale
            width = brick1.size[0]
            length = brick1.size[1] + brick2.size[1]
        else:  # Fusion horizontale
            width = brick1.size[0] + brick2.size[0]
            length = brick1.size[1]
        
        height = brick1.size[2]  # Même hauteur
        
        # Moyenne pondérée des scores de stabilité
        area1 = brick1.size[0] * brick1.size[1]
        area2 = brick2.size[0] * brick2.size[1]
        total_area = area1 + area2
        stability = (brick1.stability_score * area1 + brick2.stability_score * area2) / total_area
        
        return Brick(
            position=(x, y, z),
            size=(width, length, height),
            stability_score=stability
        )

    def _calculate_size_distribution(self, bricks: List[Brick]) -> Dict:
        """Calcule la distribution des tailles de briques."""
        distribution = {}
        for brick in bricks:
            size_str = str(brick.size)
            distribution[size_str] = distribution.get(size_str, 0) + 1
        return distribution 
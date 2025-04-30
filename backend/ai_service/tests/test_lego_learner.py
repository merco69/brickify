import unittest
import numpy as np
import torch
import yaml
from pathlib import Path
from services.lego_learner import LegoModelLearner

class TestLegoModelLearner(unittest.TestCase):
    def setUp(self):
        """Initialise le test avec un modèle d'apprentissage et des données de test."""
        # Charge la configuration
        config_path = Path(__file__).parent.parent / "config" / "learner_config.yaml"
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)
            
        self.learner = LegoModelLearner(self.config)
        
        # Crée des données de test
        self.test_voxel_size = 32
        self.test_data = {
            "voxels": np.random.rand(self.test_voxel_size, self.test_voxel_size, self.test_voxel_size) > 0.5,
            "metadata": {
                "name": "test_model",
                "complexity": "medium",
                "brick_count": 100
            }
        }
        
    def test_model_initialization(self):
        """Teste l'initialisation correcte du modèle."""
        self.assertIsNotNone(self.learner.model)
        self.assertIsNotNone(self.learner.optimizer)
        self.assertIsNotNone(self.learner.criterion)
        
    def test_preprocess_model_data(self):
        """Teste le prétraitement des données du modèle."""
        processed_data = self.learner._preprocess_model_data(self.test_data)
        
        # Vérifie la forme et le type des données prétraitées
        self.assertIsInstance(processed_data, torch.Tensor)
        self.assertEqual(len(processed_data.shape), 5)  # [batch, channels, depth, height, width]
        self.assertEqual(processed_data.shape[1], 1)  # Un canal pour les voxels
        
    def test_model_forward_pass(self):
        """Teste le passage avant du modèle."""
        input_tensor = self.learner._preprocess_model_data(self.test_data)
        output = self.learner.model(input_tensor)
        
        # Vérifie la forme de la sortie
        self.assertEqual(output.shape, input_tensor.shape)
        # Vérifie que les valeurs sont entre 0 et 1 (sigmoid)
        self.assertTrue(torch.all(output >= 0) and torch.all(output <= 1))
        
    def test_model_evaluation(self):
        """Teste l'évaluation du modèle."""
        input_tensor = self.learner._preprocess_model_data(self.test_data)
        output = self.learner.model(input_tensor)
        metrics = self.learner._evaluate_model(output, input_tensor)
        
        # Vérifie les métriques d'évaluation
        self.assertIn('mse', metrics)
        self.assertIn('accuracy', metrics)
        self.assertIsInstance(metrics['mse'], float)
        self.assertIsInstance(metrics['accuracy'], float)
        
    def test_model_save_load(self):
        """Teste la sauvegarde et le chargement du modèle."""
        # Sauvegarde le modèle
        save_path = Path("test_model.pt")
        self.learner.save_model(save_path)
        
        # Crée un nouveau learner et charge le modèle
        new_learner = LegoModelLearner(self.config)
        new_learner.load_model(save_path)
        
        # Vérifie que les états sont identiques
        for p1, p2 in zip(self.learner.model.parameters(), new_learner.model.parameters()):
            self.assertTrue(torch.equal(p1, p2))
            
        # Nettoie le fichier de test
        save_path.unlink()
        
    def test_learn_from_model(self):
        """Teste l'apprentissage à partir d'un modèle."""
        result = self.learner.learn_from_model(self.test_data)
        
        # Vérifie le résultat de l'apprentissage
        self.assertIn('status', result)
        self.assertIn('loss', result)
        self.assertIn('metrics', result)
        self.assertEqual(result['status'], 'success')
        self.assertIsInstance(result['loss'], float)
        
    def test_model_architecture(self):
        """Teste l'architecture du modèle."""
        # Vérifie la structure du modèle
        self.assertTrue(isinstance(self.learner.model[0], torch.nn.Conv3d))
        self.assertTrue(isinstance(self.learner.model[-1], torch.nn.Sigmoid))
        
        # Vérifie les dimensions des couches
        input_shape = (1, 1, self.test_voxel_size, self.test_voxel_size, self.test_voxel_size)
        output = self.learner.model(torch.randn(input_shape))
        self.assertEqual(output.shape, input_shape)
        
    def test_optimizer_configuration(self):
        """Teste la configuration de l'optimiseur."""
        self.assertIsInstance(self.learner.optimizer, torch.optim.Adam)
        self.assertEqual(
            self.learner.optimizer.param_groups[0]['lr'],
            self.config['training']['learning_rate']
        )

if __name__ == '__main__':
    unittest.main() 
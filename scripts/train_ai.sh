#!/bin/bash

# Configuration
LOG_DIR="/var/log/brickify/ai_training"
MODEL_DIR="/models"
DATA_DIR="/data/training"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/training_$TIMESTAMP.log"

# Créer les répertoires nécessaires
mkdir -p $LOG_DIR $MODEL_DIR $DATA_DIR

echo "Début de l'entraînement des modèles d'IA..."

# 1. Entraînement du modèle de détection LEGO
echo "Entraînement du modèle de détection LEGO..."
python backend/ai/train_detection_model.py \
    --data_dir $DATA_DIR/lego_detection \
    --model_dir $MODEL_DIR/detection \
    --epochs 100 \
    --batch_size 32 \
    --learning_rate 0.001 \
    >> $LOG_FILE 2>&1

# 2. Entraînement du modèle de classification des briques
echo "Entraînement du modèle de classification des briques..."
python backend/ai/train_classification_model.py \
    --data_dir $DATA_DIR/brick_classification \
    --model_dir $MODEL_DIR/classification \
    --epochs 50 \
    --batch_size 64 \
    --learning_rate 0.0005 \
    >> $LOG_FILE 2>&1

# 3. Entraînement du modèle de reconstruction 3D
echo "Entraînement du modèle de reconstruction 3D..."
python backend/ai/train_reconstruction_model.py \
    --data_dir $DATA_DIR/3d_reconstruction \
    --model_dir $MODEL_DIR/reconstruction \
    --epochs 200 \
    --batch_size 16 \
    --learning_rate 0.0001 \
    >> $LOG_FILE 2>&1

# 4. Évaluation des modèles
echo "Évaluation des modèles..."
python backend/ai/evaluate_models.py \
    --model_dir $MODEL_DIR \
    --test_data $DATA_DIR/test \
    >> $LOG_FILE 2>&1

# 5. Sauvegarde des modèles entraînés
echo "Sauvegarde des modèles..."
BACKUP_DIR="/backups/models"
mkdir -p $BACKUP_DIR
tar -czf "$BACKUP_DIR/models_$TIMESTAMP.tar.gz" $MODEL_DIR

# 6. Génération du rapport d'entraînement
REPORT_FILE="$LOG_DIR/training_report_$TIMESTAMP.txt"
{
    echo "Rapport d'entraînement des modèles d'IA - $TIMESTAMP"
    echo "============================================="
    echo "Modèles entraînés :"
    echo "- Détection LEGO"
    echo "- Classification des briques"
    echo "- Reconstruction 3D"
    echo ""
    echo "Métriques d'évaluation :"
    grep "Accuracy\|Loss\|F1-score" $LOG_FILE
    echo ""
    echo "Temps d'entraînement :"
    grep "Training time" $LOG_FILE
} > $REPORT_FILE

# 7. Nettoyage des anciens modèles (plus de 30 jours)
echo "Nettoyage des anciens modèles..."
find $MODEL_DIR -name "model_*" -mtime +30 -delete

# Vérifier si tout s'est bien passé
if [ $? -eq 0 ]; then
    echo "Entraînement terminé avec succès !"
    echo "Logs : $LOG_FILE"
    echo "Rapport : $REPORT_FILE"
    echo "Modèles sauvegardés : $BACKUP_DIR/models_$TIMESTAMP.tar.gz"
else
    echo "Erreur lors de l'entraînement !"
    exit 1
fi 
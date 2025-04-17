#!/bin/bash

# Configuration
MODEL_DIR="./models"
TRAINING_DATA_DIR="./data/training"
LOG_DIR="./logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/training_$TIMESTAMP.log"

# Création des répertoires nécessaires
mkdir -p $MODEL_DIR $TRAINING_DATA_DIR $LOG_DIR

# Vérification de l'existence des données d'entraînement
if [ ! -d "$TRAINING_DATA_DIR" ] || [ -z "$(ls -A $TRAINING_DATA_DIR)" ]; then
    echo "Aucune donnée d'entraînement trouvée dans $TRAINING_DATA_DIR"
    exit 1
fi

# Démarrage de l'entraînement
echo "Début de l'entraînement du modèle..."
docker exec brickifyapp-backend-1 python -m training.train_model \
    --data_dir $TRAINING_DATA_DIR \
    --model_dir $MODEL_DIR \
    --epochs 50 \
    --batch_size 32 \
    --learning_rate 0.001 \
    > $LOG_FILE 2>&1

# Vérification du succès de l'entraînement
if [ $? -eq 0 ]; then
    echo "Entraînement terminé avec succès !"
    echo "Logs disponibles dans : $LOG_FILE"
else
    echo "Erreur lors de l'entraînement. Consultez les logs : $LOG_FILE"
    exit 1
fi 
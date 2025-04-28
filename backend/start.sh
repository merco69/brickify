#!/bin/bash

# Activer l'environnement Python
source /opt/render/project/src/.venv/bin/activate

# Ajouter le dossier backend au PYTHONPATH
export PYTHONPATH=/opt/render/project/src:$PYTHONPATH

# Installer le package backend en mode développement
cd /opt/render/project/src
pip install -e .

# Vérifier la disponibilité du GPU
nvidia-smi

# Créer les répertoires nécessaires
mkdir -p /data/storage/temp
mkdir -p /data/storage/cache
mkdir -p /data/storage/results

# Définir les permissions
chmod -R 755 /data/storage

# Démarrer l'application
cd /opt/render/project/src/backend
uvicorn main:app --host 0.0.0.0 --port $PORT --workers 4 --log-level info 
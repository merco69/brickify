#!/bin/bash

# Activer l'environnement Python
source /opt/render/project/src/.venv/bin/activate

# Mettre à jour pip
python -m pip install --upgrade pip

# Installer le package backend en mode développement
cd /opt/render/project/src
pip install -e .

# Créer les répertoires nécessaires
mkdir -p /data/storage
mkdir -p /data/cache
mkdir -p /data/models

# Définir les permissions
chmod -R 755 /data

# Démarrer l'application
cd /opt/render/project/src/backend
export PYTHONPATH=/opt/render/project/src/backend:$PYTHONPATH
uvicorn ai_service:app --host 0.0.0.0 --port $PORT --workers 2 --log-level info 
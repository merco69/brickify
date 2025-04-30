#!/bin/bash

# Activation de l'environnement virtuel
echo "Activation de l'environnement virtuel..."
VENV_PATH="/opt/render/project/src/.venv"
source $VENV_PATH/bin/activate

# Mise à jour de pip dans l'environnement virtuel
echo "Mise à jour de pip..."
$VENV_PATH/bin/python3.9 -m pip install --upgrade pip
$VENV_PATH/bin/pip --version

# Installation des dépendances
echo "Installation des dépendances..."
$VENV_PATH/bin/pip install -r requirements.txt

# Configuration du PYTHONPATH
echo "Configuration du PYTHONPATH..."
cd /opt/render/project/src
export PYTHONPATH="/opt/render/project/src:${PYTHONPATH}"

# Démarrage de l'application
echo "Démarrage de l'application..."
$VENV_PATH/bin/python3.9 -m backend.main 
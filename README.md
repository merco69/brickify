# Brickify

Application mobile pour l'analyse et l'identification de pièces LEGO.

## Description

Brickify est une application mobile qui permet aux utilisateurs d'analyser des images de pièces LEGO pour identifier les pièces, leurs couleurs et leurs quantités. L'application utilise l'intelligence artificielle pour reconnaître les pièces LEGO dans les images.

## Fonctionnalités

- Analyse d'images de pièces LEGO
- Identification des pièces et de leurs couleurs
- Calcul des quantités nécessaires
- Estimation des prix
- Historique des analyses
- Partage des résultats

## Technologies utilisées

- Backend: FastAPI, Python
- Frontend: React Native
- Base de données: PostgreSQL
- IA: TensorFlow, OpenCV

## Installation

### Backend

```bash
cd backend
pip install -r requirements.txt
python -m uvicorn main:app --reload
```

### Frontend

```bash
cd frontend
npm install
npm start
```

## Licence

Tous droits réservés © 2023 Brickify 
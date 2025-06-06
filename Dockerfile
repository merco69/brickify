FROM python:3.11-slim

WORKDIR /app

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copie des fichiers de configuration
COPY requirements.txt .
COPY ai_service ./ai_service

# Installation des dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Création des répertoires nécessaires
RUN mkdir -p /app/storage /app/cache /app/models

# Exposition du port
EXPOSE 8001

# Commande de démarrage
CMD ["uvicorn", "ai_service.main:app", "--host", "0.0.0.0", "--port", "8001"] 
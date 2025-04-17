#!/bin/bash

# Configuration
DOMAIN="localhost"
BACKUP_DIR="./backups"
LOG_DIR="./logs"
DOCKER_COMPOSE_FILE="docker-compose.yml"

# Fonction pour afficher les messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Fonction pour vérifier les erreurs
check_error() {
    if [ $? -ne 0 ]; then
        log "ERREUR: $1"
        exit 1
    fi
}

# Début du déploiement
log "Début du déploiement local de Brickify..."

# 1. Vérification de Docker
log "Vérification de Docker..."
if ! command -v docker &> /dev/null; then
    log "Docker n'est pas installé. Veuillez installer Docker Desktop pour Windows"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    log "Docker Compose n'est pas installé. Veuillez l'installer avec Docker Desktop"
    exit 1
fi

# 2. Configuration des répertoires
log "Configuration des répertoires..."
mkdir -p $BACKUP_DIR $LOG_DIR
check_error "Échec de la création des répertoires"

# 3. Configuration des variables d'environnement
log "Configuration des variables d'environnement..."
if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env
    log "Veuillez configurer les variables d'environnement dans backend/.env"
    notepad backend/.env
fi

# 4. Construction et démarrage des conteneurs Docker
log "Démarrage des conteneurs Docker..."
docker-compose down
docker-compose build --no-cache
check_error "Échec de la construction des conteneurs"
docker-compose up -d
check_error "Échec du démarrage des conteneurs"

# 5. Configuration des sauvegardes
log "Configuration des sauvegardes..."
chmod +x scripts/*.sh
./scripts/schedule_backup.sh
check_error "Échec de la configuration des sauvegardes"

# 6. Configuration de l'entraînement IA
log "Configuration de l'entraînement IA..."
./scripts/schedule_training.sh
check_error "Échec de la configuration de l'entraînement IA"

# 7. Vérification du déploiement
log "Vérification du déploiement..."
sleep 30  # Attendre que les services démarrent

# Vérifier l'API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health)
if [ "$API_STATUS" != "200" ]; then
    log "ERREUR: L'API n'est pas accessible"
    docker-compose logs backend
    exit 1
fi

# Vérifier le frontend
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
if [ "$FRONTEND_STATUS" != "200" ]; then
    log "ERREUR: Le frontend n'est pas accessible"
    docker-compose logs frontend
    exit 1
fi

# 8. Configuration du monitoring
log "Configuration du monitoring..."
if [ ! -f "prometheus.yml" ]; then
    cp prometheus.yml.example prometheus.yml
fi

# 9. Génération du rapport de déploiement
log "Génération du rapport de déploiement..."
REPORT_FILE="$LOG_DIR/deploy_report_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "Rapport de déploiement local Brickify - $(date)"
    echo "============================================="
    echo "Services déployés :"
    docker-compose ps
    echo ""
    echo "Logs des services :"
    docker-compose logs --tail=50
} > $REPORT_FILE

# Fin du déploiement
log "Déploiement local terminé avec succès !"
log "Rapport de déploiement : $REPORT_FILE"
log "Vérifiez les logs pour plus de détails : $LOG_DIR"

# Afficher les informations importantes
echo "
=============================================
Déploiement local Brickify terminé !
=============================================
Frontend: http://localhost:3000
API: http://localhost:8000/api
Monitoring: http://localhost:3001
Backups: $BACKUP_DIR
Logs: $LOG_DIR
=============================================
" 
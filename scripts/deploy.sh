#!/bin/bash

# Configuration
DOMAIN="brickify.app"
EMAIL="admin@brickify.app"
BACKUP_DIR="/backups"
LOG_DIR="/var/log/brickify"
DOCKER_COMPOSE_FILE="docker-compose.yml"
NGINX_CONF="/etc/nginx/sites-available/brickify.conf"

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
log "Début du déploiement de Brickify..."

# 1. Mise à jour du système
log "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y
check_error "Échec de la mise à jour du système"

# 2. Installation des dépendances
log "Installation des dépendances..."
sudo apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx
check_error "Échec de l'installation des dépendances"

# 3. Configuration de Docker
log "Configuration de Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
check_error "Échec de la configuration de Docker"

# 4. Configuration des répertoires
log "Configuration des répertoires..."
sudo mkdir -p $BACKUP_DIR $LOG_DIR
sudo chown -R $USER:$USER $BACKUP_DIR $LOG_DIR
check_error "Échec de la création des répertoires"

# 5. Configuration SSL
log "Configuration SSL..."
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email $EMAIL
    check_error "Échec de la configuration SSL"
fi

# 6. Configuration de Nginx
log "Configuration de Nginx..."
sudo cp nginx.conf $NGINX_CONF
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
sudo nginx -t
check_error "Échec de la configuration de Nginx"
sudo systemctl restart nginx

# 7. Configuration des variables d'environnement
log "Configuration des variables d'environnement..."
if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env
    log "Veuillez configurer les variables d'environnement dans backend/.env"
    nano backend/.env
fi

# 8. Construction et démarrage des conteneurs Docker
log "Démarrage des conteneurs Docker..."
docker-compose down
docker-compose build --no-cache
check_error "Échec de la construction des conteneurs"
docker-compose up -d
check_error "Échec du démarrage des conteneurs"

# 9. Configuration des sauvegardes
log "Configuration des sauvegardes..."
chmod +x scripts/*.sh
./scripts/schedule_backup.sh
check_error "Échec de la configuration des sauvegardes"

# 10. Configuration de l'entraînement IA
log "Configuration de l'entraînement IA..."
./scripts/schedule_training.sh
check_error "Échec de la configuration de l'entraînement IA"

# 11. Vérification du déploiement
log "Vérification du déploiement..."
sleep 30  # Attendre que les services démarrent

# Vérifier l'API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/api/health)
if [ "$API_STATUS" != "200" ]; then
    log "ERREUR: L'API n'est pas accessible"
    docker-compose logs backend
    exit 1
fi

# Vérifier le frontend
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
if [ "$FRONTEND_STATUS" != "200" ]; then
    log "ERREUR: Le frontend n'est pas accessible"
    docker-compose logs frontend
    exit 1
fi

# 12. Configuration du monitoring
log "Configuration du monitoring..."
if [ ! -f "prometheus.yml" ]; then
    cp prometheus.yml.example prometheus.yml
fi

# 13. Génération du rapport de déploiement
log "Génération du rapport de déploiement..."
REPORT_FILE="$LOG_DIR/deploy_report_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "Rapport de déploiement Brickify - $(date)"
    echo "============================================="
    echo "Services déployés :"
    docker-compose ps
    echo ""
    echo "Configuration SSL :"
    sudo certbot certificates
    echo ""
    echo "Logs des services :"
    docker-compose logs --tail=50
} > $REPORT_FILE

# Fin du déploiement
log "Déploiement terminé avec succès !"
log "Rapport de déploiement : $REPORT_FILE"
log "Vérifiez les logs pour plus de détails : $LOG_DIR"

# Afficher les informations importantes
echo "
=============================================
Déploiement Brickify terminé !
=============================================
URL: https://$DOMAIN
API: https://$DOMAIN/api
Monitoring: https://$DOMAIN:3001
Backups: $BACKUP_DIR
Logs: $LOG_DIR
=============================================
" 
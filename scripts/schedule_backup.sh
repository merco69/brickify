#!/bin/bash

# Configuration
BACKUP_DIR="./backups"
DB_CONTAINER="brickifyapp-db-1"
DB_USER="brickify"
DB_NAME="brickify"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"

# Création du répertoire de backup s'il n'existe pas
mkdir -p $BACKUP_DIR

# Sauvegarde de la base de données
echo "Début de la sauvegarde de la base de données..."
docker exec $DB_CONTAINER pg_dump -U $DB_USER $DB_NAME > $BACKUP_FILE

# Compression de la sauvegarde
gzip $BACKUP_FILE

# Suppression des sauvegardes de plus de 7 jours
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete

echo "Sauvegarde terminée : $BACKUP_FILE.gz" 
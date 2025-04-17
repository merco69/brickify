#!/bin/bash

# Configuration
BACKUP_DIR="/backups"
DB_NAME="brickify"
DB_USER="brickify"
DB_HOST="postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"

# Créer le répertoire de backup s'il n'existe pas
mkdir -p $BACKUP_DIR

# Créer le backup
echo "Creating backup..."
PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME > $BACKUP_FILE

# Compresser le backup
echo "Compressing backup..."
gzip $BACKUP_FILE

# Supprimer les backups plus vieux que 7 jours
echo "Cleaning old backups..."
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete

# Vérifier si le backup a réussi
if [ $? -eq 0 ]; then
    echo "Backup completed successfully: ${BACKUP_FILE}.gz"
else
    echo "Backup failed!"
    exit 1
fi 
#!/bin/bash

# Configuration
BACKUP_DIR="/backups/project"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PROJECT_BACKUP="$BACKUP_DIR/brickify_project_$TIMESTAMP.tar.gz"
DB_BACKUP="$BACKUP_DIR/brickify_db_$TIMESTAMP.sql.gz"

# Créer les répertoires de backup
mkdir -p $BACKUP_DIR

echo "Début de la sauvegarde du projet Brickify..."

# 1. Sauvegarder le code source
echo "Sauvegarde du code source..."
tar -czf $PROJECT_BACKUP \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.git' \
    --exclude='.env' \
    --exclude='backups' \
    .

# 2. Sauvegarder la base de données
echo "Sauvegarde de la base de données..."
PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME | gzip > $DB_BACKUP

# 3. Sauvegarder les fichiers uploadés
echo "Sauvegarde des fichiers uploadés..."
UPLOADS_BACKUP="$BACKUP_DIR/uploads_$TIMESTAMP.tar.gz"
tar -czf $UPLOADS_BACKUP ./uploads

# 4. Sauvegarder les configurations
echo "Sauvegarde des configurations..."
CONFIG_BACKUP="$BACKUP_DIR/config_$TIMESTAMP.tar.gz"
tar -czf $CONFIG_BACKUP \
    .env.example \
    nginx.conf \
    docker-compose.yml \
    prometheus.yml \
    backend/config.py

# 5. Créer un fichier de manifeste
echo "Création du manifeste..."
MANIFEST="$BACKUP_DIR/manifest_$TIMESTAMP.txt"
echo "Sauvegarde Brickify - $TIMESTAMP" > $MANIFEST
echo "Fichiers sauvegardés :" >> $MANIFEST
echo "- Code source : $PROJECT_BACKUP" >> $MANIFEST
echo "- Base de données : $DB_BACKUP" >> $MANIFEST
echo "- Fichiers uploadés : $UPLOADS_BACKUP" >> $MANIFEST
echo "- Configurations : $CONFIG_BACKUP" >> $MANIFEST

# 6. Nettoyer les anciennes sauvegardes (plus de 30 jours)
echo "Nettoyage des anciennes sauvegardes..."
find $BACKUP_DIR -name "brickify_*" -mtime +30 -delete

# Vérifier si tout s'est bien passé
if [ $? -eq 0 ]; then
    echo "Sauvegarde terminée avec succès !"
    echo "Fichiers sauvegardés dans : $BACKUP_DIR"
    echo "Manifeste : $MANIFEST"
else
    echo "Erreur lors de la sauvegarde !"
    exit 1
fi

# 7. Créer un script de restauration
RESTORE_SCRIPT="$BACKUP_DIR/restore_$TIMESTAMP.sh"
cat > $RESTORE_SCRIPT << 'EOF'
#!/bin/bash

# Script de restauration pour la sauvegarde du $TIMESTAMP

# Restaurer le code source
echo "Restauration du code source..."
tar -xzf brickify_project_$TIMESTAMP.tar.gz

# Restaurer la base de données
echo "Restauration de la base de données..."
gunzip -c brickify_db_$TIMESTAMP.sql.gz | PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME

# Restaurer les fichiers uploadés
echo "Restauration des fichiers uploadés..."
tar -xzf uploads_$TIMESTAMP.tar.gz

# Restaurer les configurations
echo "Restauration des configurations..."
tar -xzf config_$TIMESTAMP.tar.gz

echo "Restauration terminée !"
EOF

chmod +x $RESTORE_SCRIPT
echo "Script de restauration créé : $RESTORE_SCRIPT" 
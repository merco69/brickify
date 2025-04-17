#!/bin/bash

# Configuration
BACKUP_DIR="/backups/project"
LOG_FILE="/var/log/brickify/backup_verify.log"

# Fonction pour vérifier l'intégrité d'une archive
verify_archive() {
    local archive=$1
    echo "Vérification de l'archive : $archive"
    
    # Vérifier si l'archive existe
    if [ ! -f "$archive" ]; then
        echo "ERREUR : L'archive $archive n'existe pas"
        return 1
    }
    
    # Vérifier l'intégrité de l'archive
    if [[ $archive == *.tar.gz ]]; then
        tar -tzf "$archive" > /dev/null 2>&1
    elif [[ $archive == *.sql.gz ]]; then
        gunzip -t "$archive" > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        echo "OK : L'archive $archive est valide"
        return 0
    else
        echo "ERREUR : L'archive $archive est corrompue"
        return 1
    fi
}

# Vérifier les sauvegardes récentes (dernières 24h)
echo "Vérification des sauvegardes récentes..."
find $BACKUP_DIR -name "brickify_*" -mtime -1 | while read backup; do
    verify_archive "$backup"
done

# Vérifier l'espace disque
echo "Vérification de l'espace disque..."
DISK_USAGE=$(df -h $BACKUP_DIR | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "ATTENTION : L'espace disque est presque plein ($DISK_USAGE%)"
    # Envoyer une notification
    echo "ALERTE : Espace disque critique pour les sauvegardes" | mail -s "Alerte Sauvegarde Brickify" admin@brickify.app
fi

# Vérifier les logs de sauvegarde
echo "Vérification des logs de sauvegarde..."
if [ -f "$LOG_FILE" ]; then
    LAST_ERROR=$(grep "ERROR\|FAILED" $LOG_FILE | tail -n 1)
    if [ ! -z "$LAST_ERROR" ]; then
        echo "ATTENTION : Dernière erreur dans les logs : $LAST_ERROR"
    fi
fi

# Générer un rapport
REPORT_FILE="$BACKUP_DIR/backup_report_$(date +%Y%m%d).txt"
{
    echo "Rapport de vérification des sauvegardes - $(date)"
    echo "============================================="
    echo "Sauvegardes vérifiées :"
    find $BACKUP_DIR -name "brickify_*" -mtime -1 -ls
    echo ""
    echo "Espace disque utilisé : $DISK_USAGE%"
    echo ""
    echo "Dernières erreurs :"
    grep "ERROR\|FAILED" $LOG_FILE | tail -n 5
} > $REPORT_FILE

echo "Rapport généré : $REPORT_FILE" 
# Configuration
$DOMAIN = "localhost"
$BACKUP_DIR = ".\backups"
$LOG_DIR = ".\logs"
$DOCKER_COMPOSE_FILE = "docker-compose.yml"

# Fonction pour afficher les messages
function Write-Log {
    param($Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

# Fonction pour vérifier les erreurs
function Check-Error {
    param($Message)
    if ($LASTEXITCODE -ne 0) {
        Write-Log "ERREUR: $Message"
        exit 1
    }
}

# Début du déploiement
Write-Log "Début du déploiement local de Brickify..."

# 1. Vérification de Docker
Write-Log "Vérification de Docker..."
try {
    $dockerVersion = docker --version
    Write-Log "Docker installé: $dockerVersion"
} catch {
    Write-Log "Docker n'est pas installé. Veuillez installer Docker Desktop pour Windows"
    exit 1
}

try {
    $dockerComposeVersion = docker-compose --version
    Write-Log "Docker Compose installé: $dockerComposeVersion"
} catch {
    Write-Log "Docker Compose n'est pas installé. Veuillez l'installer avec Docker Desktop"
    exit 1
}

# 2. Configuration des répertoires
Write-Log "Configuration des répertoires..."
try {
    if (-not (Test-Path $BACKUP_DIR)) {
        New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
        Write-Log "Répertoire de backup créé: $BACKUP_DIR"
    }
    if (-not (Test-Path $LOG_DIR)) {
        New-Item -ItemType Directory -Path $LOG_DIR | Out-Null
        Write-Log "Répertoire de logs créé: $LOG_DIR"
    }
} catch {
    Write-Log "ERREUR: Impossible de créer les répertoires: $_"
    exit 1
}

# 3. Configuration des variables d'environnement
Write-Log "Configuration des variables d'environnement..."
if (-not (Test-Path "backend\.env")) {
    try {
        Copy-Item "backend\.env.example" "backend\.env"
        Write-Log "Fichier .env créé à partir du modèle"
        Write-Log "Veuillez configurer les variables d'environnement dans backend\.env"
        notepad "backend\.env"
    } catch {
        Write-Log "ERREUR: Impossible de créer le fichier .env: $_"
        exit 1
    }
}

# 4. Construction et démarrage des conteneurs Docker
Write-Log "Démarrage des conteneurs Docker..."
try {
    Write-Log "Arrêt des conteneurs existants..."
    docker-compose down
    Write-Log "Construction des images..."
    docker-compose build --no-cache
    Write-Log "Démarrage des conteneurs..."
    docker-compose up -d
    Write-Log "Conteneurs démarrés avec succès"
} catch {
    Write-Log "ERREUR: Problème avec Docker Compose: $_"
    exit 1
}

# 5. Configuration des sauvegardes
Write-Log "Configuration des sauvegardes..."
if (Test-Path "scripts/schedule_backup.sh") {
    try {
        bash "scripts/schedule_backup.sh"
        Write-Log "Configuration des sauvegardes terminée"
    } catch {
        Write-Log "ERREUR: Impossible de configurer les sauvegardes: $_"
    }
}

# 6. Configuration de l'entraînement IA
Write-Log "Configuration de l'entraînement IA..."
if (Test-Path "scripts/schedule_training.sh") {
    try {
        bash "scripts/schedule_training.sh"
        Write-Log "Configuration de l'entraînement IA terminée"
    } catch {
        Write-Log "ERREUR: Impossible de configurer l'entraînement IA: $_"
    }
}

# 7. Vérification du déploiement
Write-Log "Vérification du déploiement..."
Write-Log "Attente du démarrage des services (30 secondes)..."
Start-Sleep -Seconds 30

# Vérifier l'API
Write-Log "Vérification de l'API..."
try {
    $API_STATUS = Invoke-WebRequest -Uri "http://localhost:8000/api/health" -UseBasicParsing
    if ($API_STATUS.StatusCode -eq 200) {
        Write-Log "API accessible avec succès"
    } else {
        Write-Log "ERREUR: L'API n'est pas accessible (Status: $($API_STATUS.StatusCode))"
        docker-compose logs backend
        exit 1
    }
} catch {
    Write-Log "ERREUR: L'API n'est pas accessible: $_"
    docker-compose logs backend
    exit 1
}

# Vérifier le frontend
Write-Log "Vérification du frontend..."
try {
    $FRONTEND_STATUS = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing
    if ($FRONTEND_STATUS.StatusCode -eq 200) {
        Write-Log "Frontend accessible avec succès"
    } else {
        Write-Log "ERREUR: Le frontend n'est pas accessible (Status: $($FRONTEND_STATUS.StatusCode))"
        docker-compose logs frontend
        exit 1
    }
} catch {
    Write-Log "ERREUR: Le frontend n'est pas accessible: $_"
    docker-compose logs frontend
    exit 1
}

# 8. Configuration du monitoring
Write-Log "Configuration du monitoring..."
if (-not (Test-Path "prometheus.yml")) {
    try {
        Copy-Item "prometheus.yml.example" "prometheus.yml"
        Write-Log "Configuration Prometheus créée"
    } catch {
        Write-Log "ERREUR: Impossible de créer la configuration Prometheus: $_"
    }
}

# 9. Génération du rapport de déploiement
Write-Log "Génération du rapport de déploiement..."
$REPORT_FILE = "$LOG_DIR\deploy_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
try {
    @"
Rapport de déploiement local Brickify - $(Get-Date)
=============================================
Services déployés :
$(docker-compose ps)

Logs des services :
$(docker-compose logs --tail=50)
"@ | Out-File -FilePath $REPORT_FILE -Encoding UTF8
    Write-Log "Rapport de déploiement généré: $REPORT_FILE"
} catch {
    Write-Log "ERREUR: Impossible de générer le rapport: $_"
}

# Fin du déploiement
Write-Log "Déploiement local terminé avec succès !"
Write-Log "Rapport de déploiement : $REPORT_FILE"
Write-Log "Vérifiez les logs pour plus de détails : $LOG_DIR"

# Afficher les informations importantes
Write-Host @"
=============================================
Déploiement local Brickify terminé !
=============================================
Frontend: http://localhost:3000
API: http://localhost:8000/api
Monitoring: http://localhost:3001
Backups: $BACKUP_DIR
Logs: $LOG_DIR
=============================================
"@ 
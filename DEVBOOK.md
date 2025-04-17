# Documentation du Développeur Brickify

## Définition des Tiers d'Abonnement

### Structure des Tiers
```json
{
  "FREE": {
    "monthly_analysis_limit": 2,
    "has_instructions": false,
    "has_ads": true,
    "features": [
      "Analyse basique",
      "Liste des briques",
      "Prix estimé"
    ]
  },
  "BASIC": {
    "monthly_analysis_limit": 10,
    "has_instructions": true,
    "has_ads": false,
    "features": [
      "Toutes les fonctionnalités FREE",
      "Instructions de montage",
      "Sans publicités",
      "Historique des analyses"
    ]
  },
  "PREMIUM": {
    "monthly_analysis_limit": 100,
    "has_instructions": true,
    "has_ads": false,
    "features": [
      "Toutes les fonctionnalités BASIC",
      "Analyses illimitées",
      "Support prioritaire",
      "Export des données"
    ]
  },
  "ENTERPRISE": {
    "monthly_analysis_limit": "infinity",
    "has_instructions": true,
    "has_ads": false,
    "features": [
      "Toutes les fonctionnalités PREMIUM",
      "API dédiée",
      "Support personnalisé",
      "Intégration sur mesure"
    ]
  }
}
```

### Champs JSON Attendus Côté Frontend

#### Requête d'Analyse
```json
{
  "file": "File (multipart/form-data)",
  "user_id": "string (UUID)",
  "options": {
    "include_instructions": "boolean",
    "preferred_format": "string (optional)"
  }
}
```

#### Réponse d'Analyse
```json
{
  "id": "string (UUID)",
  "status": "string (pending|processing|completed|failed)",
  "created_at": "string (ISO datetime)",
  "completed_at": "string (ISO datetime)",
  "image_url": "string (URL)",
  "bricks": [
    {
      "id": "string",
      "name": "string",
      "color": "string",
      "quantity": "integer",
      "price": "number",
      "image_url": "string (URL)"
    }
  ],
  "total_price": "number",
  "can_download_instructions": "boolean",
  "ads_enabled": "boolean",
  "instructions": {
    "steps": [
      {
        "step_number": "integer",
        "description": "string",
        "image_url": "string (URL)",
        "parts_needed": [
          {
            "id": "string",
            "quantity": "integer"
          }
        ]
      }
    ],
    "total_steps": "integer",
    "estimated_time": "string"
  }
}
```

### Règles de Gestion pour les Quotas

1. **Réinitialisation Mensuelle**
   - Le compteur `month_upload_count` est réinitialisé le 1er de chaque mois
   - La date de réinitialisation est stockée dans `reset_date`
   - Les analyses en cours ne sont pas affectées par la réinitialisation

2. **Vérification des Limites**
   - Avant chaque analyse :
     ```python
     if user.month_upload_count >= subscription_limit:
         raise HTTPException(403, "Quota mensuel atteint")
     ```
   - Après chaque analyse réussie :
     ```python
     user.month_upload_count += 1
     ```

3. **Gestion des Erreurs**
   - Les analyses échouées ne sont pas comptabilisées dans le quota
   - Les analyses en cours sont conservées même après dépassement du quota

4. **Passage de Niveau**
   - Le changement de niveau d'abonnement est immédiat
   - Les quotas sont mis à jour instantanément
   - Les analyses en cours sont conservées

5. **Règles Spéciales**
   - Les utilisateurs ENTERPRISE n'ont pas de limite
   - Les analyses en cours ne sont pas bloquées par le changement de quota
   - Les instructions sont masquées pour les utilisateurs FREE

6. **Publicités**
   - Activées par défaut pour FREE
   - Désactivées pour BASIC et supérieur
   - Configuration modifiable via `ads_enabled`

7. **Instructions de Montage**
   - Accessibles uniquement pour BASIC et supérieur
   - Contrôlées par `can_download_instructions`
   - Format JSON standardisé pour le frontend 

## Fonctionnalités Sociales

### Commentaires

Les utilisateurs peuvent commenter les analyses LEGO. Les commentaires sont limités à 1000 caractères et sont modérés automatiquement.

#### Structure des Données
```json
{
  "id": "uuid",
  "analysis_id": "uuid",
  "user_id": "uuid",
  "content": "string",
  "created_at": "datetime"
}
```

#### Endpoints
- `POST /api/social/comments` : Ajouter un commentaire
- `GET /api/social/comments/{analysis_id}` : Obtenir les commentaires d'une analyse

### Notes et Évaluations

Les utilisateurs peuvent noter les analyses de 1 à 5 étoiles. Chaque utilisateur ne peut noter une analyse qu'une seule fois.

#### Structure des Données
```json
{
  "id": "uuid",
  "analysis_id": "uuid",
  "user_id": "uuid",
  "value": "integer (1-5)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

#### Statistiques de Notation
```json
{
  "analysis_id": "uuid",
  "average_rating": "float",
  "total_ratings": "integer",
  "distribution": {
    "1": "integer",
    "2": "integer",
    "3": "integer",
    "4": "integer",
    "5": "integer"
  }
}
```

#### Endpoints
- `POST /api/social/ratings` : Ajouter ou mettre à jour une note
- `GET /api/social/ratings/{analysis_id}` : Obtenir les statistiques de notation

### Partage d'Analyses

Les utilisateurs peuvent partager leurs analyses sur différentes plateformes sociales.

#### Structure des Données
```json
{
  "id": "uuid",
  "analysis_id": "uuid",
  "user_id": "uuid",
  "platform": "string",
  "message": "string",
  "created_at": "datetime"
}
```

#### Plateformes Supportées
- Twitter
- Facebook
- LinkedIn
- WhatsApp
- Email

#### Endpoints
- `POST /api/social/shares` : Partager une analyse
- `GET /api/social/shares/{analysis_id}` : Obtenir les partages d'une analyse

### Profils Utilisateurs

Les profils publics des utilisateurs affichent leurs statistiques et informations de base.

#### Structure des Données
```json
{
  "user_id": "uuid",
  "display_name": "string",
  "bio": "string",
  "analyses_count": "integer",
  "comments_count": "integer",
  "shares_count": "integer"
}
```

#### Endpoints
- `GET /api/social/profile/{user_id}` : Obtenir le profil public d'un utilisateur

### Règles de Modération

1. **Commentaires**
   - Contenu interdit : spam, publicité, contenu offensant
   - Limite de 1000 caractères
   - Modération automatique des mots-clés interdits

2. **Notes**
   - Une seule note par utilisateur par analyse
   - Notes de 1 à 5 étoiles uniquement
   - Détection des votes abusifs

3. **Partages**
   - Vérification de l'existence de l'analyse
   - Limitation du nombre de partages par jour
   - Messages personnalisés limités à 280 caractères

4. **Profils**
   - Informations publiques limitées
   - Pas d'informations personnelles sensibles
   - Statistiques mises à jour en temps réel

### Intégration Frontend

Pour intégrer les fonctionnalités sociales dans le frontend :

1. **Commentaires**
   ```javascript
   // Ajouter un commentaire
   const addComment = async (analysisId, content) => {
     const response = await api.post('/social/comments', {
       analysis_id: analysisId,
       content: content
     });
     return response.data;
   };

   // Obtenir les commentaires
   const getComments = async (analysisId) => {
     const response = await api.get(`/social/comments/${analysisId}`);
     return response.data;
   };
   ```

2. **Notes**
   ```javascript
   // Ajouter une note
   const addRating = async (analysisId, value) => {
     const response = await api.post('/social/ratings', {
       analysis_id: analysisId,
       value: value
     });
     return response.data;
   };

   // Obtenir les statistiques
   const getRatingStats = async (analysisId) => {
     const response = await api.get(`/social/ratings/${analysisId}`);
     return response.data;
   };
   ```

3. **Partages**
   ```javascript
   // Partager une analyse
   const shareAnalysis = async (analysisId, platform, message) => {
     const response = await api.post('/social/shares', {
       analysis_id: analysisId,
       platform: platform,
       message: message
     });
     return response.data;
   };
   ```

4. **Profils**
   ```javascript
   // Obtenir un profil
   const getUserProfile = async (userId) => {
     const response = await api.get(`/social/profile/${userId}`);
     return response.data;
   };
   ```

### Bonnes Pratiques

1. **Performance**
   - Mise en cache des commentaires et notes
   - Pagination des résultats
   - Optimisation des requêtes

2. **Sécurité**
   - Validation des entrées
   - Protection contre les attaques XSS
   - Limitation des requêtes

3. **UX**
   - Feedback immédiat
   - Messages d'erreur clairs
   - États de chargement

4. **Maintenance**
   - Logging des actions
   - Monitoring des performances
   - Backups réguliers 
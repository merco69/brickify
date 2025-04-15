from enum import Enum
from pydantic import BaseModel, Field, EmailStr
from typing import Optional, Dict
from datetime import datetime

class SubscriptionTier(str, Enum):
    FREE = "free"
    BASIC = "basic"
    PREMIUM = "premium"
    ENTERPRISE = "enterprise"

class User(BaseModel):
    id: str
    email: EmailStr
    username: str
    created_at: datetime
    last_login: Optional[datetime] = None
    subscription_tier: SubscriptionTier = SubscriptionTier.FREE
    month_upload_count: int = 0
    reset_date: datetime
    ads_enabled: bool = True
    can_download_instructions: bool = False

class UserStats(BaseModel):
    total_analyses: int = 0
    successful_analyses: int = 0
    failed_analyses: int = 0
    total_bricks: int = 0
    average_confidence: float = 0.0
    monthly_counts: Dict[str, int] = {}
    last_analysis_date: Optional[datetime] = None

class UserCreate(BaseModel):
    email: EmailStr
    username: str
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    password: Optional[str] = None
    subscription_tier: Optional[SubscriptionTier] = None
    ads_enabled: Optional[bool] = None
    can_download_instructions: Optional[bool] = None

# Constantes pour les limites d'abonnement
SUBSCRIPTION_LIMITS = {
    SubscriptionTier.FREE: {
        "monthly_analysis_limit": 2,
        "has_instructions": False,
        "has_ads": True
    },
    SubscriptionTier.BASIC: {
        "monthly_analysis_limit": 10,
        "has_instructions": True,
        "has_ads": False
    },
    SubscriptionTier.PREMIUM: {
        "monthly_analysis_limit": float('inf'),  # Illimité
        "has_instructions": True,
        "has_ads": False
    },
    SubscriptionTier.ENTERPRISE: {
        "monthly_analysis_limit": float('inf'),  # Illimité
        "has_instructions": True,
        "has_ads": False
    }
} 
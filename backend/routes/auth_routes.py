from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status
from fastapi.security import OAuth2PasswordRequestForm
from typing import Dict, Optional
from pydantic import BaseModel, EmailStr
from ..services.auth_service import AuthService, get_current_user
from ..services.database_service import DatabaseService
from ..services.email_service import EmailService
from ..config import settings
from models.user_models import User, UserCreate, UserUpdate, Token

router = APIRouter(
    prefix="/api/auth",
    tags=["auth"],
    responses={404: {"description": "Not found"}},
)

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordReset(BaseModel):
    token: str
    new_password: str

class AccountRecoveryRequest(BaseModel):
    email: EmailStr

async def get_auth_service(db: DatabaseService = Depends(get_db_service)) -> AuthService:
    return AuthService(db)

async def get_email_service() -> EmailService:
    return EmailService()

@router.post("/register", response_model=User)
async def register(user_data: UserCreate) -> User:
    """
    Créer un nouveau compte utilisateur
    """
    try:
        user = await AuthService.register_user(user_data)
        return user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()) -> Dict[str, str]:
    """
    Authentifier un utilisateur et retourner un token JWT
    """
    try:
        token = await AuthService.authenticate_user(form_data.username, form_data.password)
        return token
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )

@router.get("/me", response_model=User)
async def get_current_user_info(current_user: User = Depends(get_current_user)) -> User:
    """
    Retourner les informations de l'utilisateur connecté
    """
    return current_user

@router.put("/me", response_model=User)
async def update_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Mettre à jour les informations de l'utilisateur connecté
    """
    try:
        updated_user = await AuthService.update_user(current_user.id, user_update)
        return updated_user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/password-reset/request")
async def request_password_reset(
    request: PasswordResetRequest,
    background_tasks: BackgroundTasks,
    auth_service: AuthService = Depends(get_auth_service),
    email_service: EmailService = Depends(get_email_service)
):
    """Demande une réinitialisation de mot de passe."""
    token = await auth_service.generate_reset_token(request.email)
    if not token:
        # Pour des raisons de sécurité, on renvoie toujours un succès
        return {"message": "Si l'email existe, un lien de réinitialisation a été envoyé"}

    reset_url = f"{settings.FRONTEND_URL}/reset-password?token={token}"
    
    # Envoyer l'email en arrière-plan
    background_tasks.add_task(
        email_service.send_password_reset_email,
        request.email,
        reset_url
    )

    return {"message": "Si l'email existe, un lien de réinitialisation a été envoyé"}

@router.post("/password-reset")
async def reset_password(
    reset_data: PasswordReset,
    auth_service: AuthService = Depends(get_auth_service)
):
    """Réinitialise le mot de passe avec un token valide."""
    success = await auth_service.reset_password(reset_data.token, reset_data.new_password)
    if not success:
        raise HTTPException(
            status_code=400,
            detail="Token invalide ou expiré"
        )
    return {"message": "Mot de passe réinitialisé avec succès"}

@router.post("/account-recovery/request")
async def request_account_recovery(
    request: AccountRecoveryRequest,
    background_tasks: BackgroundTasks,
    auth_service: AuthService = Depends(get_auth_service),
    email_service: EmailService = Depends(get_email_service)
):
    """Demande une récupération de compte."""
    token = await auth_service.generate_account_recovery_token(request.email)
    if not token:
        # Pour des raisons de sécurité, on renvoie toujours un succès
        return {"message": "Si l'email existe, un lien de récupération a été envoyé"}

    recovery_url = f"{settings.FRONTEND_URL}/recover-account?token={token}"
    
    # Envoyer l'email en arrière-plan
    background_tasks.add_task(
        email_service.send_account_recovery_email,
        request.email,
        recovery_url
    )

    return {"message": "Si l'email existe, un lien de récupération a été envoyé"}

@router.get("/account-recovery/{token}")
async def recover_account(
    token: str,
    auth_service: AuthService = Depends(get_auth_service)
):
    """Récupère les informations du compte avec un token valide."""
    account_info = await auth_service.recover_account(token)
    if not account_info:
        raise HTTPException(
            status_code=400,
            detail="Token invalide ou expiré"
        )
    return account_info 
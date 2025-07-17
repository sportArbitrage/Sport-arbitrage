from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import Any

from app.core.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, Token, User as UserSchema
from app.auth.jwt import (
    create_access_token,
    get_password_hash,
    verify_password,
)
from app.core.firebase import verify_firebase_token
from app.core.config import settings

router = APIRouter()

@router.post("/auth/register", response_model=UserSchema)
async def register(user_in: UserCreate, db: Session = Depends(get_db)) -> Any:
    """
    Register a new user.
    """
    # Check if user already exists
    user = db.query(User).filter(User.email == user_in.email).first()
    if user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists",
        )
    
    # Create new user
    user_data = user_in.dict()
    hashed_password = get_password_hash(user_data.pop("password"))
    
    db_user = User(
        **user_data,
        hashed_password=hashed_password,
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user

@router.post("/auth/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get the JWT for a user with data from OAuth2 request form body.
    """
    user = db.query(User).filter(User.email == form_data.username).first()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user",
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires,
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

@router.post("/auth/firebase-login", response_model=Token)
async def firebase_login(
    db: Session = Depends(get_db),
    firebase_user: dict = Depends(verify_firebase_token),
) -> Any:
    """
    Firebase authentication - login or register if not exists
    """
    email = firebase_user.get("email")
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Firebase token does not contain email",
        )
    
    user = db.query(User).filter(User.email == email).first()
    
    # If user doesn't exist, create one
    if not user:
        firebase_uid = firebase_user.get("uid")
        user = User(
            email=email,
            firebase_uid=firebase_uid,
            is_active=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires,
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    } 
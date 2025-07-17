from datetime import datetime, timedelta
from typing import Optional
from jose import jwt, JWTError
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models.user import User
from app.core.database import get_db

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login", auto_error=False)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

# Get development mode user for testing without authentication
def get_dev_user(db: Session):
    # Try to get an existing dev user
    dev_user = db.query(User).filter(User.email == "dev@example.com").first()
    
    # If dev user doesn't exist, create one
    if not dev_user:
        dev_user = User(
            email="dev@example.com",
            hashed_password=get_password_hash("devpassword"),
            is_active=True,
            is_admin=True,
            firebase_uid="dev-firebase-uid",
            selected_bookmakers=["Bet9ja", "1xBet", "BetKing"],
            min_profit_percentage=2.0,
            total_stake_amount=10000.0,
            notification_preferences={
                "email": True,
                "push": True,
                "min_profit_threshold": 3.0
            }
        )
        db.add(dev_user)
        db.commit()
        db.refresh(dev_user)
    
    return dev_user

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    # Check if dev mode is enabled
    if settings.DEV_MODE:
        return get_dev_user(db)
        
    # Normal authentication flow
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception
    
    return user

async def get_current_active_user(current_user: User = Depends(get_current_user)):
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

async def get_admin_user(current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized for admin access"
        )
    return current_user 
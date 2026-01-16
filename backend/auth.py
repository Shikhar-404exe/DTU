
from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel, EmailStr, Field, validator
from sqlalchemy.orm import Session
from passlib.context import CryptContext
import secrets
import logging
from typing import Optional
from datetime import datetime, timedelta
import os

from database import get_db, User as DBUser, Session as DBSession
from logging_config import security_logger

logger = logging.getLogger(__name__)

router = APIRouter()

SESSION_EXPIRY_HOURS = int(os.getenv("SESSION_EXPIRY_HOURS", "24"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class User(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=100)

    @validator('password')
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError('Password must be at least 6 characters long')
        if len(v) > 100:
            raise ValueError('Password too long')

        weak_passwords = ['123456', 'password', '123456789', 'qwerty', 'abc123']
        if v.lower() in weak_passwords:
            raise ValueError('Password is too weak. Use a stronger password')
        return v

class UserResponse(BaseModel):
    email: str
    message: str
    token: Optional[str] = None

def hash_password(password: str) -> str:
    """Hash password using bcrypt"""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against bcrypt hash"""
    return pwd_context.verify(plain_password, hashed_password)

def generate_token(db: Session, user_id: int, email: str) -> str:
    """Generate a secure session token with database storage"""
    token = secrets.token_urlsafe(32)
    expiry = datetime.utcnow() + timedelta(hours=SESSION_EXPIRY_HOURS)

    db_session = DBSession(
        token=token,
        user_id=user_id,
        email=email,
        expires_at=expiry,
        is_active=True
    )
    db.add(db_session)
    db.commit()

    return token

def validate_token(db: Session, token: str) -> Optional[dict]:
    """Validate token from database"""
    session = db.query(DBSession).filter(
        DBSession.token == token,
        DBSession.is_active == True
    ).first()

    if not session:
        return None

    if datetime.utcnow() > session.expires_at:
        session.is_active = False
        db.commit()
        return None

    return {"user_id": session.user_id, "email": session.email}

def cleanup_expired_sessions(db: Session):
    """Clean up expired sessions from database"""
    db.query(DBSession).filter(
        DBSession.expires_at < datetime.utcnow()
    ).update({"is_active": False})
    db.commit()

@router.post("/register", response_model=UserResponse)
async def register(user: User, request: Request, db: Session = Depends(get_db)):
    """Register a new user account with database storage"""
    try:

        existing_user = db.query(DBUser).filter(DBUser.email == user.email).first()
        if existing_user:
            security_logger.log_event("registration_duplicate", {
                "ip": request.client.host,
                "email": user.email
            })
            raise HTTPException(
                status_code=400,
                detail="User with this email already exists"
            )

        hashed_password = hash_password(user.password)

        db_user = DBUser(
            email=user.email,
            hashed_password=hashed_password,
            is_active=True,
            is_verified=False
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        logger.info(f"✓ New user registered: {user.email}")
        security_logger.log_event("registration_success", {
            "ip": request.client.host,
            "user": user.email
        })

        return UserResponse(
            email=user.email,
            message="User registered successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Registration error: {e}")
        security_logger.log_event("registration_error", {
            "ip": request.client.host,
            "error": str(e)
        })
        raise HTTPException(
            status_code=500,
            detail="Registration failed. Please try again."
        )

@router.post("/login", response_model=UserResponse)
async def login(user: User, request: Request, db: Session = Depends(get_db)):
    """Authenticate user and create session with database"""
    try:

        db_user = db.query(DBUser).filter(DBUser.email == user.email).first()

        if not db_user or not db_user.is_active:
            security_logger.log_event("login_failed_user_not_found", {
                "ip": request.client.host,
                "email": user.email
            })
            raise HTTPException(
                status_code=401,
                detail="Invalid email or password"
            )

        if not verify_password(user.password, db_user.hashed_password):
            security_logger.log_event("login_failed_invalid_password", {
                "ip": request.client.host,
                "user": user.email
            })
            raise HTTPException(
                status_code=401,
                detail="Invalid email or password"
            )

        cleanup_expired_sessions(db)

        token = generate_token(db, db_user.id, db_user.email)

        logger.info(f"✓ User logged in: {user.email}")
        security_logger.log_event("login_success", {
            "ip": request.client.host,
            "user": user.email
        })

        return UserResponse(
            email=user.email,
            message="Login successful",
            token=token
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login error: {e}")
        security_logger.log_event("login_error", {
            "ip": request.client.host,
            "error": str(e)
        })
        raise HTTPException(
            status_code=500,
            detail="Login failed. Please try again."
        )

@router.post("/logout")
async def logout(token: str, request: Request, db: Session = Depends(get_db)):
    """End user session by invalidating token"""
    try:
        session = db.query(DBSession).filter(DBSession.token == token).first()

        if not session:
            raise HTTPException(
                status_code=401,
                detail="Invalid session token"
            )

        session.is_active = False
        db.commit()

        logger.info(f"✓ User logged out: {session.email}")
        security_logger.log_event("logout_success", {
            "ip": request.client.host,
            "user": session.email
        })

        return {"message": "Logout successful"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Logout error: {e}")
        raise HTTPException(
            status_code=500,
            detail="Logout failed. Please try again."
        )

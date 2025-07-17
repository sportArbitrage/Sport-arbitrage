import os
import firebase_admin
from firebase_admin import credentials, auth, messaging
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import json

from app.core.config import settings

# Initialize Firebase if credentials file exists
firebase_app = None
if os.path.exists(settings.FIREBASE_CREDENTIALS):
    try:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS)
        firebase_app = firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"Failed to initialize Firebase: {e}")
else:
    print(f"Firebase credentials file not found: {settings.FIREBASE_CREDENTIALS}")

# Security scheme for token authentication
security = HTTPBearer()

async def verify_firebase_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """
    Verify Firebase ID token and extract user information
    """
    if not firebase_app:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Firebase authentication not configured"
        )
    
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication credentials: {str(e)}"
        )

def send_push_notification(token, title, body, data=None):
    """
    Send a push notification via Firebase Cloud Messaging
    """
    if not firebase_app:
        print("Firebase not initialized. Can't send push notification.")
        return False
    
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        token=token,
        data=data
    )
    
    try:
        response = messaging.send(message)
        print(f"Successfully sent push notification: {response}")
        return True
    except Exception as e:
        print(f"Failed to send push notification: {e}")
        return False

def send_multicast_notification(tokens, title, body, data=None):
    """
    Send a push notification to multiple devices
    """
    if not firebase_app:
        print("Firebase not initialized. Can't send multicast notification.")
        return False
    
    if not tokens:
        print("No tokens provided for multicast notification.")
        return False
    
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        tokens=tokens,
        data=data
    )
    
    try:
        response = messaging.send_multicast(message)
        print(f"Successfully sent {response.success_count} notifications.")
        print(f"Failed to send {response.failure_count} notifications.")
        return response.success_count > 0
    except Exception as e:
        print(f"Failed to send multicast notification: {e}")
        return False 
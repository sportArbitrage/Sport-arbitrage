import os
from typing import List, Union, Dict, Any, Optional
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Sports Arbitrage App"
    API_V1_STR: str = "/api"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-here")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    # Development mode - set to False in production
    DEV_MODE: bool = os.getenv("DEV_MODE", "True").lower() in ("true", "1", "t")
    
    # CORS
    CORS_ORIGINS: List[AnyHttpUrl] = []

    @field_validator("CORS_ORIGINS", mode="before")
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> Union[List[str], str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)

    # Database
    POSTGRES_SERVER: str = os.getenv("POSTGRES_SERVER", "localhost")
    POSTGRES_USER: str = os.getenv("POSTGRES_USER", "postgres")
    POSTGRES_PASSWORD: str = os.getenv("POSTGRES_PASSWORD", "postgres")
    POSTGRES_DB: str = os.getenv("POSTGRES_DB", "sportsarbitrage")
    SQLALCHEMY_DATABASE_URI: Optional[str] = None

    @field_validator("SQLALCHEMY_DATABASE_URI", mode="before")
    def assemble_db_connection(cls, v: Optional[str], values: Dict[str, Any]) -> Any:
        if isinstance(v, str):
            return v
        return f"postgresql://{values.get('POSTGRES_USER')}:{values.get('POSTGRES_PASSWORD')}@{values.get('POSTGRES_SERVER')}/{values.get('POSTGRES_DB')}"

    # Firebase
    FIREBASE_CREDENTIALS: str = os.getenv("FIREBASE_CREDENTIALS", "firebase-credentials.json")
    USE_FIREBASE_AUTH: bool = os.getenv("USE_FIREBASE_AUTH", "True").lower() in ("true", "1", "t")
    USE_FIREBASE_DB: bool = os.getenv("USE_FIREBASE_DB", "False").lower() in ("true", "1", "t")
    
    # Bookmakers
    BOOKMAKERS: List[str] = ["Bet9ja", "1xBet", "BetKing", "SportyBet", "Betano"]
    
    # Scraping settings
    SCRAPING_INTERVAL: int = int(os.getenv("SCRAPING_INTERVAL", "300"))  # 5 minutes by default
    
    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings() 
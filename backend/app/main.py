from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.routes import auth, users, arbitrage, bookmakers, admin
from app.core.config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Sports Arbitrage API for Nigerian Bookmakers",
    version="1.0.0"
)

# Set up CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(arbitrage.router, prefix="/api/arbitrage", tags=["Arbitrage"])
app.include_router(bookmakers.router, prefix="/api/bookmakers", tags=["Bookmakers"])
app.include_router(admin.router, prefix="/api/admin", tags=["Admin"])

@app.get("/", tags=["Root"])
async def root():
    return {"message": "Welcome to Sports Arbitrage API"}

@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy"} 
import sys
for stream in (sys.stdout, sys.stderr):
    if hasattr(stream, 'reconfigure'):
        try:
            stream.reconfigure(encoding='utf-8', errors='replace')
        except Exception:
            pass

from fastapi import FastAPI, File, UploadFile, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import BaseModel
from typing import List, Optional
import os
import traceback
from dotenv import load_dotenv

from routes.upload import router as upload_router
from routes.chat import router as chat_router

load_dotenv()

app = FastAPI(title="Smart Campus RAG API")

# Global exception handler to prevent server crashes
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle all unhandled exceptions"""
    error_detail = str(exc)
    error_traceback = traceback.format_exc()
    print(f"ERROR: Unhandled exception in {request.url.path}")
    print(error_traceback)
    
    # Don't expose internal errors in production
    return JSONResponse(
        status_code=500,
        content={
            "detail": f"Internal server error: {error_detail}",
            "path": str(request.url.path)
        }
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors"""
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors(), "body": exc.body}
    )

# CORS middleware - Configure to allow all origins for testing
# Get allowed origins from environment or use wildcard
allowed_origins_env = os.getenv("ALLOWED_ORIGINS", "*").strip()

if allowed_origins_env == "*" or allowed_origins_env == "":
    # Allow all origins - use wildcard only (can't mix with specific origins)
    allowed_origins = ["*"]
    allow_creds = False
    print("=" * 60)
    print("CORS: Allowing ALL origins (allow_credentials=False)")
    print("=" * 60)
else:
    # Use specific origins - can use credentials
    allowed_origins = [origin.strip() for origin in allowed_origins_env.split(",") if origin.strip()]
    # Always add localhost variants for local testing
    localhost_variants = [
        "http://localhost",
        "http://localhost:8080",
        "http://127.0.0.1",
        "http://127.0.0.1:8080",
    ]
    for variant in localhost_variants:
        if variant not in allowed_origins:
            allowed_origins.append(variant)
    allow_creds = True
    print("=" * 60)
    print(f"CORS: Allowing specific origins: {allowed_origins}")
    print("=" * 60)

# CORS middleware must be added BEFORE routers
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=allow_creds,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"],  # Include HEAD
    allow_headers=["*"],   # Allow all headers
    expose_headers=["*"],  # Expose all headers
    max_age=3600,  # Cache preflight requests for 1 hour
)

# Include routers
app.include_router(upload_router, prefix="/api/upload", tags=["upload"])
app.include_router(chat_router, prefix="/api/chat", tags=["chat"])

@app.get("/api/health")
async def health_check():
    return {"status": "ok", "message": "Server is running"}

@app.get("/api/cors-test")
async def cors_test():
    """Test endpoint to verify CORS is working"""
    return {
        "status": "ok",
        "message": "CORS is working!",
        "cors_enabled": True,
        "allowed_origins": os.getenv("ALLOWED_ORIGINS", "*")
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    uvicorn.run(app, host=host, port=port)


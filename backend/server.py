
"""
Production-ready server startup script with SSL support
"""
import uvicorn
import os
import sys
from dotenv import load_dotenv

load_dotenv()

HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "8000"))
WORKERS = int(os.getenv("WORKERS", "4"))
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
SSL_ENABLED = os.getenv("SSL_ENABLED", "false").lower() == "true"

ssl_config = {}
if SSL_ENABLED:
    ssl_certfile = os.getenv("SSL_CERTFILE")
    ssl_keyfile = os.getenv("SSL_KEYFILE")

    if not ssl_certfile or not ssl_keyfile:
        print("ERROR: SSL_ENABLED=true but SSL_CERTFILE or SSL_KEYFILE not set")
        sys.exit(1)

    if not os.path.exists(ssl_certfile):
        print(f"ERROR: SSL certificate file not found: {ssl_certfile}")
        sys.exit(1)

    if not os.path.exists(ssl_keyfile):
        print(f"ERROR: SSL key file not found: {ssl_keyfile}")
        sys.exit(1)

    ssl_config = {
        "ssl_certfile": ssl_certfile,
        "ssl_keyfile": ssl_keyfile,
    }
    print(f"✓ SSL enabled with certificate: {ssl_certfile}")

print("=" * 50)
print("🚀 Starting Vidyarthi Backend Server")
print("=" * 50)
print(f"Environment: {ENVIRONMENT}")
print(f"Host: {HOST}")
print(f"Port: {PORT}")
print(f"Workers: {WORKERS}")
print(f"SSL: {'Enabled' if SSL_ENABLED else 'Disabled'}")
print("=" * 50)

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=HOST,
        port=PORT,
        workers=WORKERS if ENVIRONMENT == "production" else 1,
        reload=ENVIRONMENT != "production",
        log_level="info",
        **ssl_config
    )

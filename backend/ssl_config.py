"""
SSL/HTTPS Configuration for Production
"""
import ssl
import os
from dotenv import load_dotenv

load_dotenv()

def get_ssl_context():
    """
    Create SSL context for HTTPS
    """
    ssl_enabled = os.getenv("SSL_ENABLED", "false").lower() == "true"

    if not ssl_enabled:
        return None

    ssl_certfile = os.getenv("SSL_CERTFILE")
    ssl_keyfile = os.getenv("SSL_KEYFILE")

    if not ssl_certfile or not ssl_keyfile:
        raise ValueError("SSL_CERTFILE and SSL_KEYFILE must be set when SSL_ENABLED=true")

    if not os.path.exists(ssl_certfile):
        raise FileNotFoundError(f"SSL certificate file not found: {ssl_certfile}")
    if not os.path.exists(ssl_keyfile):
        raise FileNotFoundError(f"SSL key file not found: {ssl_keyfile}")

    ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    ssl_context.load_cert_chain(ssl_certfile, ssl_keyfile)

    return ssl_context

def get_uvicorn_ssl_config():
    """
    Get SSL configuration for uvicorn
    """
    ssl_enabled = os.getenv("SSL_ENABLED", "false").lower() == "true"

    if not ssl_enabled:
        return {}

    ssl_certfile = os.getenv("SSL_CERTFILE")
    ssl_keyfile = os.getenv("SSL_KEYFILE")

    return {
        "ssl_certfile": ssl_certfile,
        "ssl_keyfile": ssl_keyfile,
    }

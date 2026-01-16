"""
Rate limiting middleware for FastAPI
"""
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import os
from dotenv import load_dotenv

load_dotenv()

RATE_LIMIT_PER_MINUTE = os.getenv("RATE_LIMIT_PER_MINUTE", "30")
RATE_LIMIT_BURST = os.getenv("RATE_LIMIT_BURST", "10")

limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[f"{RATE_LIMIT_PER_MINUTE}/minute"],
    storage_uri="memory://",
    strategy="fixed-window"
)

class RateLimits:
    """Rate limit configurations"""

    DEFAULT = f"{RATE_LIMIT_PER_MINUTE}/minute"

    AUTH_LOGIN = f"{RATE_LIMIT_BURST}/minute"
    AUTH_REGISTER = f"{RATE_LIMIT_BURST}/minute"

    GENERATE_NOTE = f"{RATE_LIMIT_PER_MINUTE}/minute"

    GENERAL = f"{int(RATE_LIMIT_PER_MINUTE) * 2}/minute"

    HEALTH = "100/minute"

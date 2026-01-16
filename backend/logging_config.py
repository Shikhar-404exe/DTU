"""
Logging configuration with Sentry integration
"""
import logging
from logging.handlers import RotatingFileHandler
from pythonjsonlogger import jsonlogger
import os
from dotenv import load_dotenv
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

load_dotenv()

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
SENTRY_DSN = os.getenv("SENTRY_DSN")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

def setup_logging():
    """Configure application logging"""

    logger = logging.getLogger()
    logger.setLevel(getattr(logging, LOG_LEVEL))

    for handler in logger.handlers[:]:
        logger.removeHandler(handler)

    console_handler = logging.StreamHandler()
    console_formatter = jsonlogger.JsonFormatter(
        '%(asctime)s %(name)s %(levelname)s %(message)s %(pathname)s %(lineno)d'
    )
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)

    log_dir = os.path.join(os.path.dirname(__file__), 'logs')
    os.makedirs(log_dir, exist_ok=True)

    file_handler = RotatingFileHandler(
        os.path.join(log_dir, 'app.log'),
        maxBytes=10 * 1024 * 1024,
        backupCount=5
    )
    file_handler.setFormatter(console_formatter)
    logger.addHandler(file_handler)

    error_handler = RotatingFileHandler(
        os.path.join(log_dir, 'error.log'),
        maxBytes=10 * 1024 * 1024,
        backupCount=5
    )
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(console_formatter)
    logger.addHandler(error_handler)

    return logger

def setup_sentry():
    """Configure Sentry error tracking"""
    if SENTRY_DSN:
        try:
            sentry_sdk.init(
                dsn=SENTRY_DSN,
                environment=ENVIRONMENT,
                integrations=[
                    FastApiIntegration(transaction_style="endpoint"),
                    SqlalchemyIntegration(),
                ],

                traces_sample_rate=0.1 if ENVIRONMENT == "production" else 1.0,

                profiles_sample_rate=0.1 if ENVIRONMENT == "production" else 1.0,

                send_default_pii=False,
            )
            logging.info(f"✓ Sentry initialized for {ENVIRONMENT} environment")
            return True
        except Exception as e:
            logging.error(f"✗ Failed to initialize Sentry: {e}")
            return False
    else:
        logging.warning("⚠ Sentry DSN not configured, error tracking disabled")
        return False

class SecurityLogger:
    """Dedicated logger for security events"""

    def __init__(self):
        self.logger = logging.getLogger('security')
        self.logger.setLevel(logging.WARNING)

        log_dir = os.path.join(os.path.dirname(__file__), 'logs')
        os.makedirs(log_dir, exist_ok=True)

        handler = RotatingFileHandler(
            os.path.join(log_dir, 'security.log'),
            maxBytes=10 * 1024 * 1024,
            backupCount=10
        )
        formatter = jsonlogger.JsonFormatter(
            '%(asctime)s %(levelname)s %(message)s %(ip)s %(user)s %(action)s'
        )
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)

    def log_event(self, event_type: str, details: dict):
        """Log a security event"""
        self.logger.warning(
            f"Security Event: {event_type}",
            extra={
                'action': event_type,
                'ip': details.get('ip', 'unknown'),
                'user': details.get('user', 'anonymous'),
                **details
            }
        )

security_logger = SecurityLogger()

"""Logging setup for the chatbot.

Every logger from get_logger() writes to logs/chatbot.log only (rotated at 5 MB, 5 backups);
nothing is printed to the console. Log level comes from LOG_LEVEL in .env (default INFO).

Usage:

    from chat_logger import get_logger
    logger = get_logger(__name__)
    logger.info("message: %s", payload)
"""

import logging
import os
from logging.handlers import RotatingFileHandler

from dotenv import load_dotenv

load_dotenv(override=True)

LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
LOG_FILE = os.path.join(LOG_DIR, "chatbot.log")
LOG_FORMAT = "%(asctime)s | %(levelname)-7s | %(name)s | %(message)s"
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()

_root = logging.getLogger("chatbot")
_configured = False


def _configure() -> None:
    global _configured
    if _configured:
        return
    os.makedirs(LOG_DIR, exist_ok=True)
    formatter = logging.Formatter(LOG_FORMAT)

    file_handler = RotatingFileHandler(LOG_FILE, maxBytes=5 * 1024 * 1024, backupCount=5,
                                       encoding="utf-8")
    file_handler.setFormatter(formatter)

    _root.setLevel(LOG_LEVEL)
    _root.addHandler(file_handler)
    # keep records out of the root logger so they are not printed twice
    _root.propagate = False
    _configured = True


def get_logger(name: str) -> logging.Logger:
    """Return a logger under the 'chatbot' namespace, configuring handlers once."""
    _configure()
    return logging.getLogger(f"chatbot.{name}")

import os

class Config:
    # App
    APP_COLOR = os.getenv("APP_COLOR", "blue")
    APP_VERSION = os.getenv("APP_VERSION", "v1")
    APP_FAIL_MODE = os.getenv("APP_FAIL_MODE", "false").lower() == "true"

    # Database
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASS = os.getenv("DB_PASS", "postgres")
    DB_NAME = os.getenv("DB_NAME", "bgapp")
    
    # O "+psycopg2" garante que o SQLAlchemy use o pacote correto
    SQLALCHEMY_DATABASE_URI = f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    SQLALCHEMY_TRACK_MODIFICATIONS = False
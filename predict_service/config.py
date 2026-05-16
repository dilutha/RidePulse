# ============================================================
# predict_service/config.py
# All configuration loaded from environment variables.
# OOP Encapsulation: single place for all external config.
# ============================================================
import os
from dotenv import load_dotenv

load_dotenv()

# PostgreSQL — same DB as Spring Boot
DB_HOST     = os.getenv("DB_HOST",     "localhost")
DB_PORT     = int(os.getenv("DB_PORT", "5432"))
DB_NAME     = os.getenv("DB_NAME",     "ridepulse_db")
DB_USER     = os.getenv("DB_USER",     "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "Chanith123")

DATABASE_URL = (
    f"postgresql://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# Model
MODEL_PATH    = os.getenv("MODEL_PATH",    "LSTM/lstm_crowd_model.h5")
MODEL_VERSION = os.getenv("MODEL_VERSION", "lstm_v1.0")
SERVICE_PORT  = int(os.getenv("PORT", "8000"))

# Prediction thresholds (% capacity)
THRESHOLD_LOW    = float(os.getenv("THRESHOLD_LOW",    "30.0"))
THRESHOLD_MEDIUM = float(os.getenv("THRESHOLD_MEDIUM", "70.0"))

# Time slots to generate predictions for (every 30 min, 5am–11pm)
PREDICTION_HOURS = list(range(5, 23))    # 05:00 to 22:30

# Peak hours definition
PEAK_MORNING_START = 7
PEAK_MORNING_END   = 9
PEAK_EVENING_START = 17
PEAK_EVENING_END   = 19

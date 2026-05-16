# ============================================================
# Dockerfile — RidePulse LSTM Prediction Service
# ============================================================
FROM python:3.11-slim

WORKDIR /app

# Install dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy service code
COPY config.py       .
COPY model_loader.py .
COPY feature_builder.py .
COPY app.py          .

# Copy trained model — place lstm_crowd_model.h5 in same dir as Dockerfile
COPY LSTM/lstm_crowd_model.h5 .

ENV MODEL_PATH=/app/lstm_crowd_model.h5
ENV MODEL_VERSION=lstm_v1.0


EXPOSE 8000

CMD ["sh", "-c", "uvicorn app:app --host 0.0.0.0 --port ${PORT:-8000}"]

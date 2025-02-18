# Use a specific Python version for stability
FROM python:3.11-slim-bullseye

# Add non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /usr/src/app

# Install system dependencies and clean up in the same layer
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install lxml_html_clean

# Create NLTK data directory and download data before switching user
RUN mkdir -p /usr/share/nltk_data && \
    python -c "import nltk; nltk.download('punkt', download_dir='/usr/share/nltk_data'); nltk.download('punkt_tab', download_dir='/usr/share/nltk_data')"

# Copy application code
COPY . .

# Set proper permissions
RUN chown -R appuser:appuser /usr/src/app && \
    chown -R appuser:appuser /usr/share/nltk_data

# Set NLTK_DATA environment variable
ENV NLTK_DATA=/usr/share/nltk_data

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 5000

# Use gunicorn for server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]

FROM python:3.10-slim 

# Install dependencies and check espeak location
RUN apt-get update && apt-get install -y \
    espeak-ng \
    espeak-ng-data \
    git \
    libsndfile1 \
    curl \
    ffmpeg \
    g++ \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \
&& mkdir -p /usr/share/espeak-ng-data \
&& ln -s /usr/lib/*/espeak-ng-data/* /usr/share/espeak-ng-data/

# Install UV using the installer script
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/ && \
    mv /root/.local/bin/uvx /usr/local/bin/

# Create non-root user and set up directories and permissions
RUN useradd -m -u 1000 appuser && \
    mkdir -p /app/api/src/models/v1_0 && \
    chown -R appuser:appuser /app

WORKDIR /app

# Copy dependency files
COPY pyproject.toml ./pyproject.toml

# Install Rust (required to build sudachipy and pyopenjtalk-plus) as root
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# Install dependencies as root
RUN --mount=type=cache,target=/root/.cache/uv \
    uv venv --python 3.10 && \
    uv sync --extra cpu

# Copy project files and scripts
COPY api ./api
COPY web ./web
COPY docker/scripts/ ./

# Download model as root before switching to appuser
ENV DOWNLOAD_MODEL=true
RUN if [ "$DOWNLOAD_MODEL" = "true" ]; then \
    python download_model.py --output api/src/models/v1_0; \
    fi

# Fix permissions after download and switch to appuser
RUN chown -R appuser:appuser /app && \
    chmod +x ./entrypoint.sh

USER appuser

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app:/app/api \
    PATH="/app/.venv/bin:$PATH" \
    UV_LINK_MODE=copy \
    USE_GPU=false \
    PHONEMIZER_ESPEAK_PATH=/usr/bin \
    PHONEMIZER_ESPEAK_DATA=/usr/share/espeak-ng-data \
    ESPEAK_DATA_PATH=/usr/share/espeak-ng-data

ENV DEVICE="cpu"
# Run FastAPI server through entrypoint.sh
CMD ["./entrypoint.sh"]

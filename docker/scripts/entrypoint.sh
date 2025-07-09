#!/bin/bash
set -e

if [ "$DOWNLOAD_MODEL" = "true" ]; then
    # Ensure we can write to api/src/models directory
    mkdir -p api/src/models/v1_0
    python download_model.py --output api/src/models/v1_0
fi

exec uv run --extra $DEVICE --no-sync python -m uvicorn api.src.main:app --host 0.0.0.0 --port 8880 --log-level debug
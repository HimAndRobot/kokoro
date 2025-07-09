#!/bin/bash
set -e

# Ensure we're in the right directory and PYTHONPATH is set
cd /app
export PYTHONPATH="/app:/app/api:$PYTHONPATH"

exec uv run --extra $DEVICE --no-sync python -m uvicorn api.src.main:app --host 0.0.0.0 --port 8880 --log-level debug
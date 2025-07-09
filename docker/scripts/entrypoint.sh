#!/bin/bash
set -e

echo "=== DEBUG: Checking permissions before download ==="
ls -la api/
echo "--- api/src permissions ---"
ls -la api/src/
echo "--- Current user ---"
whoami
echo "--- Can we write to api/src? ---"
test -w api/src && echo "YES" || echo "NO"
echo "=== END DEBUG ==="

if [ "$DOWNLOAD_MODEL" = "true" ]; then
    # Try to fix permissions before download
    echo "Attempting to fix permissions..."
    chmod -R 755 api/src/ || echo "chmod failed"
    chown -R $(whoami) api/src/ || echo "chown failed" 
    
    echo "After permission fix:"
    test -w api/src && echo "Can write: YES" || echo "Can write: NO"
    
    python download_model.py --output api/src/models/v1_0
fi

exec uv run --extra $DEVICE --no-sync python -m uvicorn api.src.main:app --host 0.0.0.0 --port 8880 --log-level debug
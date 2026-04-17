#!/usr/bin/env bash
# bundle-llm-model.sh — Download SmolLM3-3B GGUF model for offline/air-gapped LLM inference.
# Must be run on a machine with internet access.
set -euo pipefail

##############################################################################
# Paths
##############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DESKTOP_DIR="$PROJECT_ROOT/blackbox-desktop"
RESOURCES_DIR="$DESKTOP_DIR/resources"
MODELS_DIR="$RESOURCES_DIR/models"
LLM_DIR="$MODELS_DIR/llm"

MODEL_REPO="ggml-org/SmolLM3-3B-GGUF"
MODEL_FILE="SmolLM3-3B-Q4_K_M.gguf"
MODEL_OUTPUT="$LLM_DIR/$MODEL_FILE"

# Use bundled Python if available, otherwise system Python
PYTHON_RUNTIME="$RESOURCES_DIR/runtime/python"
if [ -f "$PYTHON_RUNTIME/bin/python" ]; then
  PYTHON="$PYTHON_RUNTIME/bin/python"
elif [ -f "$PYTHON_RUNTIME/python.exe" ]; then
  PYTHON="$PYTHON_RUNTIME/python.exe"
else
  PYTHON="python3"
fi

##############################################################################
# Pre-flight checks
##############################################################################
echo "=== LLM Model Bundler ==="
echo "Project root : $PROJECT_ROOT"
echo "LLM model dir: $LLM_DIR"
echo "Model        : $MODEL_REPO / $MODEL_FILE"
echo "Python       : $PYTHON"
echo ""

##############################################################################
# Step 1 — Check if model already exists (idempotent)
##############################################################################
if [ -f "$MODEL_OUTPUT" ]; then
  EXISTING_SIZE=$(stat -f%z "$MODEL_OUTPUT" 2>/dev/null || stat -c%s "$MODEL_OUTPUT" 2>/dev/null || echo "0")
  # Q4_K_M 3B model is ~2GB — skip if file is over 1GB (likely complete)
  if [ "$EXISTING_SIZE" -gt 1073741824 ]; then
    echo "Model already exists: $MODEL_OUTPUT"
    echo "Size: $(du -sh "$MODEL_OUTPUT" | cut -f1)"
    echo "Skipping download (delete file to re-download)."
    exit 0
  else
    echo "Existing file seems incomplete ($EXISTING_SIZE bytes). Re-downloading..."
    rm -f "$MODEL_OUTPUT"
  fi
fi

##############################################################################
# Step 2 — Download GGUF model from HuggingFace
##############################################################################
echo ">>> Downloading $MODEL_FILE from $MODEL_REPO..."
mkdir -p "$LLM_DIR"

# Try huggingface-cli first, fall back to Python API
if command -v huggingface-cli >/dev/null 2>&1; then
  huggingface-cli download "$MODEL_REPO" "$MODEL_FILE" --local-dir "$LLM_DIR"
else
  $PYTHON -c "
import sys
try:
    from huggingface_hub import hf_hub_download
    hf_hub_download(
        repo_id='$MODEL_REPO',
        filename='$MODEL_FILE',
        local_dir='$LLM_DIR',
        local_dir_use_symlinks=False,
    )
    print('    Download complete.')
except ImportError:
    print('ERROR: huggingface_hub not installed. Install it first:')
    print('  pip install huggingface_hub')
    sys.exit(1)
except Exception as e:
    print(f'ERROR downloading LLM model: {e}')
    sys.exit(1)
"
fi

##############################################################################
# Step 3 — Verify download
##############################################################################
echo ""
if [ -f "$MODEL_OUTPUT" ]; then
  MODEL_SIZE=$(du -sh "$MODEL_OUTPUT" | cut -f1)
  echo "=== LLM Model Bundle Summary ==="
  echo "  Model file : $MODEL_OUTPUT"
  echo "  Size       : $MODEL_SIZE"
  echo ""
  echo "At runtime, processManager.js sets:"
  echo "  LLM_MODEL_PATH = resources/models/llm/$MODEL_FILE"
  echo ""
  echo "Done."
else
  echo "ERROR: Model file not found after download: $MODEL_OUTPUT"
  echo "Check the download output above for errors."
  exit 1
fi

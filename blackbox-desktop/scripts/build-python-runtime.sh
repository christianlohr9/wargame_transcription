#!/usr/bin/env bash
# build-python-runtime.sh — Build a portable Python environment via conda-pack.
# Must be run from the repo root (parent of blackbox/ and blackbox-desktop/).
set -euo pipefail

##############################################################################
# Paths
##############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DESKTOP_DIR="$PROJECT_ROOT/blackbox-desktop"
RESOURCES_DIR="$DESKTOP_DIR/resources"
PYTHON_OUTPUT="$RESOURCES_DIR/runtime/python"
APP_DIR="$RESOURCES_DIR/app"

ENV_NAME="blackbox-portable"
PACK_FILE="/tmp/${ENV_NAME}.tar.gz"

DIARIZATION_DIR="$PROJECT_ROOT/speaker-diarization-service"
CHAT_DIR="$PROJECT_ROOT/ask-chat-service"

##############################################################################
# Pre-flight checks
##############################################################################
echo "=== Portable Python Build (conda-pack) ==="
echo "Project root : $PROJECT_ROOT"
echo "Desktop dir  : $DESKTOP_DIR"
echo ""

command -v conda >/dev/null 2>&1 || { echo "ERROR: conda not found — install Miniconda or Anaconda"; exit 1; }

echo "Conda version: $(conda --version)"
echo ""

##############################################################################
# Step 1 — Create conda environment
##############################################################################
echo ">>> Step 1: Creating conda environment '$ENV_NAME' with Python 3.12..."

# Remove existing env if present
if conda env list | grep -q "^${ENV_NAME} "; then
  echo "    Removing existing environment..."
  conda env remove -n "$ENV_NAME" -y -q
fi

conda create -n "$ENV_NAME" python=3.12 -y -q
echo "    Environment created."

##############################################################################
# Step 2 — Install CPU-only PyTorch
##############################################################################
echo ""
echo ">>> Step 2: Installing CPU-only PyTorch..."
conda run -n "$ENV_NAME" pip install torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/cpu -q
echo "    PyTorch (CPU) installed."

##############################################################################
# Step 3 — Install service requirements
##############################################################################
echo ""
echo ">>> Step 3: Installing service requirements..."

if [ -f "$DIARIZATION_DIR/requirements.txt" ]; then
  echo "    Installing speaker-diarization-service requirements..."
  conda run -n "$ENV_NAME" pip install -r "$DIARIZATION_DIR/requirements.txt" -q
else
  echo "    WARNING: $DIARIZATION_DIR/requirements.txt not found — skipping"
fi

if [ -f "$CHAT_DIR/requirements.txt" ]; then
  echo "    Installing ask-chat-service requirements..."
  conda run -n "$ENV_NAME" pip install -r "$CHAT_DIR/requirements.txt" -q
else
  echo "    WARNING: $CHAT_DIR/requirements.txt not found — skipping"
fi

# Ensure uvicorn is installed (needed to run both services)
conda run -n "$ENV_NAME" pip install uvicorn -q

# Install llama-cpp-python for local LLM inference (CPU-only, no CUDA)
echo "    Installing llama-cpp-python (CPU-only)..."
conda run -n "$ENV_NAME" env CMAKE_ARGS="-DGGML_CUDA=OFF" pip install llama-cpp-python -q
echo "    llama-cpp-python installed."

echo "    All requirements installed."

##############################################################################
# Step 4 — Install conda-pack and pack the environment
##############################################################################
echo ""
echo ">>> Step 4: Packing environment with conda-pack..."
conda install -n "$ENV_NAME" conda-pack -y -q

if [ -f "$PACK_FILE" ]; then
  rm -f "$PACK_FILE"
fi

conda run -n "$ENV_NAME" conda-pack -n "$ENV_NAME" -o "$PACK_FILE" --force
echo "    Packed to $PACK_FILE"

##############################################################################
# Step 5 — Extract to resources/runtime/python/
##############################################################################
echo ""
echo ">>> Step 5: Extracting to $PYTHON_OUTPUT..."

if [ -d "$PYTHON_OUTPUT" ] && [ "$(ls -A "$PYTHON_OUTPUT" 2>/dev/null)" ]; then
  echo "    Removing previous Python runtime..."
  rm -rf "$PYTHON_OUTPUT"
  mkdir -p "$PYTHON_OUTPUT"
fi

mkdir -p "$PYTHON_OUTPUT"
tar -xzf "$PACK_FILE" -C "$PYTHON_OUTPUT"
echo "    Extracted."

##############################################################################
# Step 6 — Run conda-unpack to fix path prefixes
##############################################################################
echo ""
echo ">>> Step 6: Running conda-unpack to fix path prefixes..."
if [ -f "$PYTHON_OUTPUT/bin/conda-unpack" ]; then
  bash "$PYTHON_OUTPUT/bin/conda-unpack"
elif [ -f "$PYTHON_OUTPUT/Scripts/conda-unpack.exe" ]; then
  "$PYTHON_OUTPUT/Scripts/conda-unpack.exe"
else
  echo "    WARNING: conda-unpack not found — paths may need manual fixing"
fi
echo "    conda-unpack complete."

##############################################################################
# Step 6b — Verify llama-cpp-python in packed environment
##############################################################################
echo ""
echo ">>> Step 6b: Verifying llama-cpp-python in packed environment..."
if [ -f "$PYTHON_OUTPUT/bin/python" ]; then
  PACKED_PYTHON="$PYTHON_OUTPUT/bin/python"
elif [ -f "$PYTHON_OUTPUT/python.exe" ]; then
  PACKED_PYTHON="$PYTHON_OUTPUT/python.exe"
else
  echo "    WARNING: Could not find Python binary in packed runtime"
  PACKED_PYTHON=""
fi

if [ -n "$PACKED_PYTHON" ]; then
  if "$PACKED_PYTHON" -c "from llama_cpp import Llama; print('    llama_cpp OK')" 2>/dev/null; then
    echo "    llama-cpp-python verified in packed environment."
  else
    echo "    WARNING: llama-cpp-python import failed in packed environment."
    echo "    Fallback: may need to bundle llama-server binary separately."
    echo "    See build-python-runtime.md for details."
  fi
fi

##############################################################################
# Step 7 — Copy Python service source code
##############################################################################
echo ""
echo ">>> Step 7: Copying Python service source code..."

# Diarization service
DIARIZATION_DEST="$APP_DIR/diarization"
if [ -d "$DIARIZATION_DIR/src" ]; then
  mkdir -p "$DIARIZATION_DEST"
  cp -r "$DIARIZATION_DIR/src" "$DIARIZATION_DEST/"
  # Copy any config files needed at runtime
  for f in "$DIARIZATION_DIR"/*.py "$DIARIZATION_DIR"/*.toml "$DIARIZATION_DIR"/*.cfg "$DIARIZATION_DIR"/.env.example; do
    [ -f "$f" ] && cp "$f" "$DIARIZATION_DEST/"
  done
  echo "    Copied diarization service to $DIARIZATION_DEST"
else
  echo "    WARNING: $DIARIZATION_DIR/src not found — skipping"
fi

# Chat service
CHAT_DEST="$APP_DIR/chat"
if [ -d "$CHAT_DIR/src" ]; then
  mkdir -p "$CHAT_DEST"
  cp -r "$CHAT_DIR/src" "$CHAT_DEST/"
  for f in "$CHAT_DIR"/*.py "$CHAT_DIR"/*.toml "$CHAT_DIR"/*.cfg "$CHAT_DIR"/.env.example; do
    [ -f "$f" ] && cp "$f" "$CHAT_DEST/"
  done
  echo "    Copied chat service to $CHAT_DEST"
else
  echo "    WARNING: $CHAT_DIR/src not found — skipping"
fi

##############################################################################
# Cleanup
##############################################################################
echo ""
echo ">>> Cleaning up..."
rm -f "$PACK_FILE"
echo "    Removed $PACK_FILE"

##############################################################################
# Summary
##############################################################################
echo ""
echo "=== Build Summary ==="
PYTHON_SIZE=$(du -sh "$PYTHON_OUTPUT" 2>/dev/null | cut -f1)
DIARIZATION_SIZE=$(du -sh "$DIARIZATION_DEST" 2>/dev/null | cut -f1 || echo "N/A")
CHAT_SIZE=$(du -sh "$CHAT_DEST" 2>/dev/null | cut -f1 || echo "N/A")
echo "  Python runtime : $PYTHON_SIZE"
echo "  Diarization src: $DIARIZATION_SIZE"
echo "  Chat src       : $CHAT_SIZE"
echo "  Python location: $PYTHON_OUTPUT"
echo "  App location   : $APP_DIR"
echo ""
echo "NOTE: This Python environment is platform-specific."
echo "  - macOS build   -> macOS env (dev/testing only)"
echo "  - Windows build -> Windows env (production target)"
echo ""
echo "Done."

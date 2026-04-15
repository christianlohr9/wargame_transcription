#!/usr/bin/env bash
# bundle-models.sh — Download and bundle ML models for offline/air-gapped use.
# Must be run on a machine with internet access and HF_TOKEN set.
set -euo pipefail

##############################################################################
# Paths
##############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DESKTOP_DIR="$PROJECT_ROOT/blackbox-desktop"
RESOURCES_DIR="$DESKTOP_DIR/resources"
MODELS_DIR="$RESOURCES_DIR/models"
WHISPER_DIR="$MODELS_DIR/whisper"
HF_DIR="$MODELS_DIR/huggingface"

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
echo "=== Model Bundler ==="
echo "Project root : $PROJECT_ROOT"
echo "Models dir   : $MODELS_DIR"
echo "Python       : $PYTHON"
echo ""

if [ -z "${HF_TOKEN:-}" ]; then
  echo "WARNING: HF_TOKEN is not set."
  echo "  Pyannote models require a Hugging Face token with accepted terms."
  echo "  Set HF_TOKEN=hf_... and re-run if you need diarization models."
  echo "  Whisper models will still be downloaded (no token required)."
  echo ""
fi

##############################################################################
# Step 1 — Download faster-whisper large-v3-turbo
##############################################################################
echo ">>> Step 1: Downloading faster-whisper large-v3-turbo model..."
mkdir -p "$WHISPER_DIR"

# Use huggingface_hub to download the model via Python
$PYTHON -c "
import os, sys
os.environ['HF_HOME'] = '$HF_DIR'
try:
    from huggingface_hub import snapshot_download
    snapshot_download(
        repo_id='Systran/faster-whisper-large-v3-turbo',
        local_dir='$WHISPER_DIR/faster-whisper-large-v3-turbo',
        local_dir_use_symlinks=False,
    )
    print('    faster-whisper large-v3-turbo downloaded.')
except ImportError:
    print('ERROR: huggingface_hub not installed. Install it first:')
    print('  pip install huggingface_hub')
    sys.exit(1)
except Exception as e:
    print(f'ERROR downloading whisper model: {e}')
    sys.exit(1)
"
echo "    Whisper model location: $WHISPER_DIR/faster-whisper-large-v3-turbo"

##############################################################################
# Step 2 — Download pyannote models (requires HF_TOKEN)
##############################################################################
echo ""
echo ">>> Step 2: Downloading pyannote diarization models..."

if [ -z "${HF_TOKEN:-}" ]; then
  echo "    SKIPPED — HF_TOKEN not set."
  echo "    To download pyannote models, set HF_TOKEN and re-run."
else
  mkdir -p "$HF_DIR"

  $PYTHON -c "
import os, sys
os.environ['HF_HOME'] = '$HF_DIR'
os.environ['HF_TOKEN'] = '$HF_TOKEN'
try:
    from huggingface_hub import snapshot_download

    # pyannote/segmentation-3.0
    print('    Downloading pyannote/segmentation-3.0...')
    snapshot_download(
        repo_id='pyannote/segmentation-3.0',
        local_dir='$HF_DIR/hub/pyannote--segmentation-3.0',
        local_dir_use_symlinks=False,
        token='$HF_TOKEN',
    )

    # pyannote/speaker-diarization-3.1
    print('    Downloading pyannote/speaker-diarization-3.1...')
    snapshot_download(
        repo_id='pyannote/speaker-diarization-3.1',
        local_dir='$HF_DIR/hub/pyannote--speaker-diarization-3.1',
        local_dir_use_symlinks=False,
        token='$HF_TOKEN',
    )

    # pyannote/wespeaker-voxceleb-resnet34-LM (speaker embedding)
    print('    Downloading pyannote/wespeaker-voxceleb-resnet34-LM...')
    snapshot_download(
        repo_id='pyannote/wespeaker-voxceleb-resnet34-LM',
        local_dir='$HF_DIR/hub/pyannote--wespeaker-voxceleb-resnet34-LM',
        local_dir_use_symlinks=False,
        token='$HF_TOKEN',
    )

    print('    Pyannote models downloaded.')
except ImportError:
    print('ERROR: huggingface_hub not installed.')
    sys.exit(1)
except Exception as e:
    print(f'ERROR downloading pyannote models: {e}')
    sys.exit(1)
"
  echo "    Pyannote models location: $HF_DIR/hub/"
fi

##############################################################################
# Summary
##############################################################################
echo ""
echo "=== Model Bundle Summary ==="
TOTAL_SIZE=$(du -sh "$MODELS_DIR" 2>/dev/null | cut -f1)
echo "  Total models size: $TOTAL_SIZE"
echo "  Models location  : $MODELS_DIR"
echo ""
echo "Contents:"
ls -1d "$MODELS_DIR"/*/ 2>/dev/null || echo "  (no subdirectories)"
echo ""
echo "At runtime, processManager.js sets these env vars:"
echo "  HF_HOME       = resources/models/huggingface"
echo "  WHISPER_CACHE  = resources/models/whisper"
echo ""
echo "Done."

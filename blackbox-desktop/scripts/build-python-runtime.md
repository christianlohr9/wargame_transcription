# Build Python Runtime (conda-pack) & Bundle Models

Creates a portable, self-contained Python environment so users don't need Python installed.

## Prerequisites

- **Miniconda or Anaconda** — provides `conda` command
- **Internet access** — to download packages and models
- **HF_TOKEN** (optional) — Hugging Face token for pyannote model download

## Scripts

### build-python-runtime.sh

Builds the portable Python environment.

```bash
# From the repository root
./blackbox-desktop/scripts/build-python-runtime.sh
```

**What it does:**

1. Creates a conda environment `blackbox-portable` with Python 3.12
2. Installs CPU-only PyTorch (no CUDA — target is CPU-only HP EliteBook)
3. Installs requirements from `speaker-diarization-service/requirements.txt` and `ask-chat-service/requirements.txt`
4. Packs the environment with `conda-pack`
5. Extracts to `blackbox-desktop/resources/runtime/python/`
6. Runs `conda-unpack` to fix hardcoded path prefixes
7. Copies Python service source code to `resources/app/diarization/` and `resources/app/chat/`

### bundle-models.sh

Downloads ML models for offline/air-gapped deployment.

```bash
# From the repository root (set HF_TOKEN for pyannote models)
export HF_TOKEN=hf_your_token_here
./blackbox-desktop/scripts/bundle-models.sh
```

**What it does:**

1. Downloads `Systran/faster-whisper-large-v3-turbo` (~1.5 GB)
2. Downloads pyannote models (segmentation-3.0, speaker-diarization-3.1, wespeaker-voxceleb-resnet34-LM) — requires HF_TOKEN with accepted terms
3. Stores everything under `blackbox-desktop/resources/models/`

## Output Structure

```
blackbox-desktop/
  resources/
    runtime/
      python/              # Portable Python (~2-3 GB with PyTorch CPU)
        bin/python         # (or python.exe on Windows)
        lib/
        ...
    app/
      diarization/         # Speaker diarization service source
        src/
      chat/                # Chat service source
        src/
    models/
      whisper/             # faster-whisper models (~1.5 GB)
        faster-whisper-large-v3-turbo/
      huggingface/         # pyannote/HF models (~500 MB)
        hub/
```

## Platform Notes

- **The packed environment is platform-specific.** A macOS pack only works on macOS.
- For production (Windows HP EliteBook), run these scripts on a Windows machine with Miniconda installed.
- The macOS build is only useful for local development and testing.
- CPU-only PyTorch is installed to keep the package size manageable (~800 MB vs ~2.5 GB with CUDA).

## Expected Sizes

| Component | Approximate Size |
|-----------|-----------------|
| Python runtime (CPU PyTorch) | 2-3 GB |
| faster-whisper large-v3-turbo | 1.5 GB |
| pyannote models | 500 MB |
| Service source code | ~10 MB |
| **Total** | **~4-5 GB** |

## Model Access Requirements

### faster-whisper (no auth required)
The `Systran/faster-whisper-large-v3-turbo` model is public and requires no authentication.

### pyannote (HF_TOKEN required)
Pyannote models require:
1. A Hugging Face account
2. Accepted terms for each model on the HF website
3. `HF_TOKEN` environment variable set to a valid token

Without HF_TOKEN, `bundle-models.sh` will skip pyannote models and only download the whisper model. Diarization will not work without pyannote models.

## Troubleshooting

### conda-pack fails

Ensure all packages are from conda-forge or pip. Packages installed with `--editable` mode cannot be packed. If a package causes issues, try installing it from conda-forge instead of pip.

### "No module named X" at runtime

The packed environment may be missing a package. Add it to the relevant `requirements.txt` and rebuild.

### Models not found at runtime

The `processManager.js` sets `HF_HOME` and `WHISPER_CACHE` environment variables pointing to `resources/models/`. The diarization service must be configured to look for models in these locations. Check that the model directory structure matches what the service expects.

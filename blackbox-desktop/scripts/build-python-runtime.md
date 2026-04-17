# Build Python Runtime (conda-pack) & Bundle Models

Creates a portable, self-contained Python environment so users don't need Python installed.

## Prerequisites

- **Miniconda or Anaconda** — provides `conda` command
- **C++ compiler** — required for building llama-cpp-python native extension (cmake + gcc on Linux, Xcode CLT on macOS, MSVC/Build Tools on Windows)
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
4. Installs `llama-cpp-python` with CPU-only build (`CMAKE_ARGS="-DGGML_CUDA=OFF"`)
5. Packs the environment with `conda-pack`
6. Extracts to `blackbox-desktop/resources/runtime/python/`
7. Runs `conda-unpack` to fix hardcoded path prefixes
8. Verifies `llama-cpp-python` imports correctly from the packed environment
9. Copies Python service source code to `resources/app/diarization/` and `resources/app/chat/`

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
| Python runtime (CPU PyTorch + llama-cpp-python) | 2-3 GB |
| faster-whisper large-v3-turbo | 1.5 GB |
| pyannote models | 500 MB |
| SmolLM3-3B GGUF (via bundle-llm-model.sh) | ~2 GB |
| Service source code | ~10 MB |
| **Total** | **~6-7 GB** |

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

### llama-cpp-python build fails

The `llama-cpp-python` package compiles a native C++ extension during install. It requires:
- **cmake** and a C++ compiler (gcc, clang, or MSVC)
- On Windows: Install "Build Tools for Visual Studio" or use `conda install cmake`
- On macOS: `xcode-select --install`
- The build uses `CMAKE_ARGS="-DGGML_CUDA=OFF"` to skip CUDA (saves ~2GB, CPU-only target).

### llama-cpp-python fails in packed environment

If the verification step reports that `from llama_cpp import Llama` fails after conda-pack, the native extension may not relocate correctly. Fallback options:
1. Bundle the `llama-server` binary separately (download from llama.cpp releases)
2. Use `llamafile` as a standalone executable
3. Install llama-cpp-python directly in the extracted environment post-unpack

### "No module named X" at runtime

The packed environment may be missing a package. Add it to the relevant `requirements.txt` and rebuild.

### Models not found at runtime

The `processManager.js` sets `HF_HOME` and `WHISPER_CACHE` environment variables pointing to `resources/models/`. The diarization service must be configured to look for models in these locations. Check that the model directory structure matches what the service expects.

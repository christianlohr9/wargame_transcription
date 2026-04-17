# Bundle LLM Model

Downloads the SmolLM3-3B GGUF model for offline/air-gapped LLM inference in the Blackbox Desktop app.

## Prerequisites

- **Python with huggingface_hub** — either the bundled runtime or system Python with `pip install huggingface_hub`
- **Internet access** — one-time download only; the model is bundled into the installer for air-gapped deployment
- **No HF token required** — the GGUF model repo is public

## Usage

```bash
# From the repository root
./blackbox-desktop/scripts/bundle-llm-model.sh
```

## What It Does

1. Checks if the model already exists (idempotent — skips download if file is present and >1GB)
2. Downloads `SmolLM3-3B-Q4_K_M.gguf` from `ggml-org/SmolLM3-3B-GGUF` on HuggingFace
3. Stores the file at `blackbox-desktop/resources/models/llm/SmolLM3-3B-Q4_K_M.gguf`
4. Verifies the download completed successfully

## Output

```
blackbox-desktop/
  resources/
    models/
      llm/
        SmolLM3-3B-Q4_K_M.gguf   # ~2 GB (Q4_K_M quantization)
```

## Model Details

| Property | Value |
|----------|-------|
| Model | SmolLM3-3B |
| Quantization | Q4_K_M |
| Format | GGUF (llama.cpp compatible) |
| HuggingFace repo | ggml-org/SmolLM3-3B-GGUF |
| Approximate size | ~2 GB |
| Auth required | No |

## Runtime Integration

At runtime, `processManager.js` sets the `LLM_MODEL_PATH` environment variable pointing to the bundled GGUF file. The ask-chat-service uses `llama-cpp-python` to load and run inference on this model locally.

## Re-downloading

To force a fresh download, delete the existing model file:

```bash
rm blackbox-desktop/resources/models/llm/SmolLM3-3B-Q4_K_M.gguf
./blackbox-desktop/scripts/bundle-llm-model.sh
```

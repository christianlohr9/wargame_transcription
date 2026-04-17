# Phase 14: Guppy LLM Integration - Research

**Researched:** 2026-04-17
**Domain:** CPU-only LLM inference for wargame transcript summarization
**Confidence:** HIGH

<research_summary>
## Summary

Researched the feasibility of GuppyLM and alternatives for CPU-only LLM summarization bundled in an air-gapped Electron desktop app.

**Critical finding: GuppyLM is NOT viable for this use case.** GuppyLM is a 9M parameter educational toy model that role-plays as a fish named Guppy. It has a 128-token context window, a 4,096-token vocabulary, and its "personality" (fish behavior) is baked into the model weights — it cannot follow instructions, summarize text, or perform any useful NLP task. It was built to demonstrate that training an LLM is accessible, not to serve as a production inference engine.

The correct approach is to integrate **llama-cpp-python** as a third backend in the existing ask-chat-service (alongside Ollama and OpenAI), using a quantized **SmolLM3-3B** or **Qwen 2.5 1.5B** GGUF model for CPU inference. This fits the existing architecture perfectly — the ask-chat-service already supports backend switching via environment variable, and the conda-pack Python environment can bundle the native llama.cpp binaries and model file.

**Primary recommendation:** Add a `llamacpp` backend to ask-chat-service using llama-cpp-python with a Q4_K_M quantized SmolLM3-3B GGUF model (~2GB). This gives German-language summarization on CPU with zero architecture changes to the backend or Electron shell.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| llama-cpp-python | 0.3.x | Python bindings for llama.cpp | Standard CPU LLM inference, mature, handles GGUF models |
| SmolLM3-3B (Q4_K_M GGUF) | 3B params | LLM model for summarization | Best-in-class 3B model, explicit German support, 128k context, outperforms Llama-3.2-3B and Qwen2.5-3B |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Qwen 2.5 1.5B Instruct (Q4_K_M) | 1.5B params | Smaller alternative model | If RAM is too constrained for 3B (~2GB vs ~1.5GB for model) |
| huggingface-hub | latest | Model downloading | Only for dev/setup — production bundles model in installer |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| llama-cpp-python | node-llama-cpp (in Electron) | node-llama-cpp requires unpacking from asar, ties LLM lifecycle to Electron UI process, requires prebuilt binaries. Python approach reuses existing ask-chat-service architecture |
| llama-cpp-python | llama-server binary | Would work but adds another binary to manage. Python integration is simpler since ask-chat-service is already Python/FastAPI |
| SmolLM3-3B | Qwen 2.5 1.5B | Qwen is smaller/faster but less capable. SmolLM3 has explicit German support and 128k context |
| SmolLM3-3B | Llama 3.2 3B | SmolLM3 outperforms Llama 3.2 3B on benchmarks and has better multilingual support |
| SmolLM3-3B | Gemma 3 1B | Gemma is smaller but SmolLM3 at 3B offers much better summarization quality |

### GuppyLM — Why It Was Rejected

| Property | GuppyLM | Requirement |
|----------|---------|-------------|
| Parameters | 9M | Need 1B+ for coherent summarization |
| Context window | 128 tokens | Need 4K+ for transcripts |
| Vocabulary | 4,096 BPE | Need 32K+ for multilingual |
| Instruction following | None (personality baked in) | Need system prompt + instruction following |
| Languages | English fish-speak only | Need German |
| Use case | Educational demo / novelty | Production summarization |

**Installation:**
```bash
# In ask-chat-service conda environment
pip install llama-cpp-python
# Model file bundled in installer, not downloaded at runtime
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Integration: Third Backend in ask-chat-service

The existing ask-chat-service already has a clean backend abstraction:
- `ChatService` abstract base class
- `OllamaChatService` implementation (Ollama client)
- `OpenAIChatService` implementation (Azure OpenAI)
- Backend selected via `CHAT_SERVICE` env var

**Add:** `LlamaCppChatService` as a third implementation.

### Current Architecture (unchanged)
```
Electron ProcessManager
  ├── backend (Spring Boot, port 8081) ← calls ask-chat-service
  ├── diarization (Python/FastAPI, port 8082)
  └── chat (Python/FastAPI, port 8083) ← ADD llamacpp backend here
```

### Pattern 1: LlamaCpp Backend Implementation
**What:** New ChatService implementation using llama-cpp-python
**When to use:** CPU-only machines without access to Ollama server
**Example:**
```python
# ask-chat-service/src/services/llamacpp_chat_service.py
from llama_cpp import Llama

class LlamaCppChatService(ChatService):
    def __init__(self):
        model_path = os.environ.get("LLAMACPP_MODEL_PATH", "./models/smollm3-3b-q4_k_m.gguf")
        self.llm = Llama(
            model_path=model_path,
            n_ctx=4096,        # Context window for summarization
            n_threads=4,       # CPU threads (tune for HP EliteBook)
            n_batch=512,       # Batch size for prompt processing
            verbose=False
        )

    async def chat(self, history: ChatHistoryModel) -> str:
        messages = [{"role": m.role, "content": m.content} for m in history.messages]
        response = self.llm.create_chat_completion(
            messages=messages,
            temperature=0.7,
            max_tokens=2048
        )
        return response["choices"][0]["message"]["content"]
```

### Pattern 2: Backend Selection with Hardware Detection
**What:** First-run setup recommends backend based on available hardware
**When to use:** Initial app configuration
**Example:**
```python
# Backend selection logic (in Electron or backend)
def recommend_backend():
    """Suggest LLM backend based on environment."""
    # Check if Ollama is reachable (GPU path)
    if check_ollama_health():
        return "ollama"
    # Fall back to local CPU inference
    return "llamacpp"
```

### Pattern 3: Background Summary Generation with Progress
**What:** Non-blocking summary generation with status updates
**When to use:** After transcription completes
**Architecture:**
- Spring Boot `@Async` method calls chat service
- AnalysisService already does this via `executePrompts()`
- Frontend polls `/pipeline/status` for progress (already exists)
- Add toast notification when summary completes

### Anti-Patterns to Avoid
- **Loading model per-request:** Load once at service startup, reuse for all requests. Model loading takes 5-30 seconds.
- **Running LLM in Electron main process:** Keep inference in separate Python service. Electron UI must stay responsive.
- **Using full-precision models on CPU:** Always use Q4_K_M quantized GGUF. Full precision would need 6GB+ RAM for 3B model.
- **Streaming to Spring Boot:** The backend collects full responses anyway. No need for streaming complexity.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LLM inference engine | Custom PyTorch inference | llama-cpp-python with GGUF | llama.cpp has years of CPU optimization (SIMD, quantization), 3-8x faster than Python |
| Tokenization | Custom tokenizer | Built into GGUF model file | GGUF bundles tokenizer with model weights |
| Model quantization | Manual weight compression | Pre-quantized GGUF from HuggingFace | Quantization is a specialized process, use community GGUF builds |
| Chat template formatting | String concatenation | llama-cpp-python `create_chat_completion()` | Handles chat templates, special tokens, role formatting per-model |
| Backend abstraction | New service architecture | Extend existing ask-chat-service | Already has ChatService base class and backend switching |
| Health monitoring | New health check system | Existing HealthChecker in Electron | Already monitors port 8083, no changes needed |
| Progress tracking | Custom progress system | Existing pipeline status endpoint | `/pipeline/status` already reports mode and service health |

**Key insight:** The existing architecture already solves 80% of this phase. The ask-chat-service has a clean backend abstraction. The Electron shell has process management and health monitoring. The backend has async prompt execution. The only new code needed is a ~50-line `LlamaCppChatService` class and bundling a GGUF model file.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Model Loading Time Blocking Service Startup
**What goes wrong:** ask-chat-service reports "healthy" before model is loaded, backend sends requests that fail
**Why it happens:** llama-cpp-python model loading takes 5-30 seconds depending on model size and disk speed
**How to avoid:** Load model in service startup (before health endpoint returns OK), or add a "model_loaded" flag to health check response
**Warning signs:** First chat request after service start fails with timeout or error

### Pitfall 2: RAM Exhaustion with Multiple Services Running
**What goes wrong:** System runs out of memory when diarization + LLM + backend all run simultaneously
**Why it happens:** On 16GB machine: OS ~3GB, Spring Boot ~1GB, diarization (pyannote+whisper) ~4-6GB, LLM model ~2GB = 10-12GB. Tight but feasible, unless model or context is too large.
**How to avoid:** Use Q4_K_M quantization (~2GB for 3B model). Set n_ctx to 4096 not 128k. Profile on target hardware. Consider sequential rather than parallel diarization + summarization.
**Warning signs:** System swap usage increasing, inference extremely slow, OOM kills

### Pitfall 3: German Language Quality with Small Models
**What goes wrong:** Summaries are incoherent or switch to English mid-response
**Why it happens:** Small models have weaker multilingual capabilities. German training data is less abundant.
**How to avoid:** Use SmolLM3-3B which explicitly trains on German. Include "Antworte auf Deutsch" in system prompt. Test with actual German wargame transcripts.
**Warning signs:** Code-switching (mixing German/English), garbled grammar, summaries that miss key points

### Pitfall 4: Context Window Too Small for Transcripts
**What goes wrong:** Transcript fragments get truncated, summaries miss information
**Why it happens:** Setting n_ctx too low to save RAM, or model's effective context is shorter than advertised
**How to avoid:** SmolLM3-3B supports up to 128k context, but 4096 should suffice since the backend already chunks by round. Monitor token counts in requests.
**Warning signs:** Summaries that only cover beginning of transcript, "incomplete" feeling outputs

### Pitfall 5: Conda-pack Compatibility with Native Extensions
**What goes wrong:** llama-cpp-python's native C++ binary doesn't work after conda-pack
**Why it happens:** conda-pack relocates paths, native extensions may have hardcoded paths or missing shared libraries
**How to avoid:** Test conda-pack with llama-cpp-python on Windows specifically. Use CPU-only build (no CUDA). May need to include llama.cpp shared library explicitly.
**Warning signs:** ImportError or OSError when loading llama_cpp module from packed environment
</common_pitfalls>

<code_examples>
## Code Examples

### LlamaCpp Chat Service Implementation
```python
# Source: llama-cpp-python docs + existing OllamaChatService pattern
import os
from llama_cpp import Llama
from src.services.chat_service import ChatService
from src.models.chat_history_model import ChatHistoryModel

class LlamaCppChatService(ChatService):
    def __init__(self):
        model_path = os.environ.get(
            "LLAMACPP_MODEL_PATH",
            os.path.join(os.path.dirname(__file__), "../../models/smollm3-3b-q4_k_m.gguf")
        )
        n_threads = int(os.environ.get("LLAMACPP_THREADS", "4"))
        n_ctx = int(os.environ.get("LLAMACPP_CTX_SIZE", "4096"))

        self.llm = Llama(
            model_path=model_path,
            n_ctx=n_ctx,
            n_threads=n_threads,
            n_batch=512,
            verbose=False
        )

    async def chat(self, history: ChatHistoryModel) -> str:
        messages = [
            {"role": msg.role, "content": msg.content}
            for msg in history.messages
        ]
        response = self.llm.create_chat_completion(
            messages=messages,
            temperature=0.7,
            max_tokens=2048,
            response_format=(
                {"type": "json_object", "schema": history.response_schema}
                if history.response_schema else None
            )
        )
        return response["choices"][0]["message"]["content"]
```

### Backend Selection Factory (Updated)
```python
# Source: existing ask-chat-service/src/services/__init__.py pattern
import os
from src.services.chat_service import ChatService

def get_chat_service() -> ChatService:
    service_type = os.environ.get("CHAT_SERVICE", "ollama")

    if service_type == "ollama":
        from src.services.ollama_chat_service import OllamaChatService
        return OllamaChatService()
    elif service_type == "openai":
        from src.services.openai_chat_service import OpenAIChatService
        return OpenAIChatService()
    elif service_type == "llamacpp":
        from src.services.llamacpp_chat_service import LlamaCppChatService
        return LlamaCppChatService()
    else:
        raise ValueError(f"Unknown chat service: {service_type}")
```

### Electron ProcessManager Chat Config (Updated)
```javascript
// Source: existing blackbox-desktop/electron/processManager.js pattern
const chatService = {
    command: resolveRuntimePaths().python,
    args: ['-m', 'uvicorn', 'src.main:app', '--port', '8083'],
    port: 8083,
    required: false,
    env: {
        CHAT_SERVICE: store.get('llmBackend', 'llamacpp'),  // User setting
        LLAMACPP_MODEL_PATH: path.join(resourcesPath, 'models', 'smollm3-3b-q4_k_m.gguf'),
        LLAMACPP_THREADS: '4',
        LLAMACPP_CTX_SIZE: '4096'
    }
};
```

### Settings UI Backend Toggle
```javascript
// Vue/Quasar settings component concept
const llmBackendOptions = [
    { label: 'Local CPU (SmolLM3)', value: 'llamacpp', description: 'Runs on this machine, no GPU needed' },
    { label: 'Ollama Server', value: 'ollama', description: 'Requires GPU-equipped Ollama server' }
];
```
</code_examples>

<sota_updates>
## State of the Art (2025-2026)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom Python inference | llama.cpp / llama-cpp-python | 2023-2024 | 3-8x faster CPU inference via C++ and SIMD |
| 7B models minimum | 1.5B-3B models viable | 2025-2026 | SmolLM3-3B matches older 7B quality |
| Full precision models | Q4_K_M quantization standard | 2024 | 75% size reduction, minimal quality loss |
| Ollama only for local | llama-cpp-python for embedded | 2024-2025 | No separate server process needed |
| English-focused small models | Multilingual 3B models | 2025-2026 | SmolLM3 supports 6 European languages including German |
| Single-mode LLM backend | Backend abstraction pattern | Standard | Multiple backends behind common interface |

**New tools/patterns to consider:**
- **SmolLM3-3B:** HuggingFace's latest 3B model (2025), beats Llama 3.2 3B and Qwen 2.5 3B. German support. 128k context. GGUF available.
- **llamafile:** Single-file executable with model embedded. Could be an alternative to llama-cpp-python if conda-pack causes issues — bundle a llamafile binary instead.
- **node-llama-cpp:** Direct Electron integration. Reserve as backup if Python path proves problematic.

**Deprecated/outdated:**
- **GuppyLM:** Educational 9M parameter toy, not a production LLM
- **cannon.js-style custom inference:** Python-native transformers inference is 3-8x slower than llama.cpp on CPU
- **Unquantized models on CPU:** Always use GGUF Q4_K_M for CPU deployment
</sota_updates>

<open_questions>
## Open Questions

1. **conda-pack + llama-cpp-python native extension on Windows**
   - What we know: conda-pack works for faster-whisper and pyannote native extensions
   - What's unclear: Whether llama-cpp-python's native .dll/.so relocates cleanly in conda-pack
   - Recommendation: Test early in implementation. Fallback: bundle llama-server binary and call via HTTP, or use llamafile

2. **SmolLM3-3B GGUF quantized model availability**
   - What we know: HuggingFace has official GGUF builds (ggml-org/SmolLM3-3B-GGUF)
   - What's unclear: Exact file size of Q4_K_M variant, whether it fits comfortably in NSIS installer
   - Recommendation: Download and verify size during planning. Expect ~2GB for Q4_K_M 3B model.

3. **RAM headroom on 16GB target machine**
   - What we know: OS ~3GB, Spring Boot ~1GB, diarization ~4-6GB, LLM model ~2GB = 10-12GB
   - What's unclear: Whether full pipeline (diarization + summarization concurrent) is feasible
   - Recommendation: Profile on target hardware. Consider running diarization and summarization sequentially (diarize all, then summarize), not concurrently. Pipeline orchestration already runs steps sequentially.

4. **German summarization quality at 3B scale**
   - What we know: SmolLM3-3B explicitly supports German in training data and benchmarks
   - What's unclear: Quality of German wargame transcript summarization specifically
   - Recommendation: Test with real transcripts early. Include "Antworte auf Deutsch" in system prompts. Compare with Qwen 2.5 1.5B as fallback.

5. **First-run backend selection UX**
   - What we know: User wants Electron to detect hardware and recommend a backend
   - What's unclear: How to detect Ollama availability (it's on a remote server, not local)
   - Recommendation: Default to llamacpp (always available). Check Ollama endpoint on configured URL. Show recommendation in first-run wizard or settings.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- [GuppyLM GitHub](https://github.com/arman-bd/guppylm) — Full architecture review: 9M params, 128 token context, fish persona, educational only
- [llama.cpp GitHub](https://github.com/ggml-org/llama.cpp) — Server API docs, CLI flags, OpenAI-compatible endpoints
- [SmolLM3 HuggingFace Blog](https://huggingface.co/blog/smollm3) — Model specs, German support, benchmarks vs 3B competitors
- [SmolLM3-3B-GGUF](https://huggingface.co/ggml-org/SmolLM3-3B-GGUF) — Official GGUF quantized builds
- [llama-cpp-python docs](https://llama-cpp-python.readthedocs.io/) — Python bindings API, FastAPI server mode
- [node-llama-cpp docs](https://node-llama-cpp.withcat.ai/) — Electron integration, prebuilt binaries, asar limitations

### Secondary (MEDIUM confidence)
- [Best Sub-3B GGUF Models Guide](https://ggufloader.github.io/2025-07-07-top-10-gguf-models-i5-16gb.html) — RAM usage benchmarks, Q4_K_M recommendations for 16GB
- [Local LLM Inference 2026 Guide](https://blog.starmorph.com/blog/local-llm-inference-tools-guide) — Ecosystem overview, tool comparisons
- [Best Small AI Models 2026](https://localaimaster.com/blog/small-language-models-guide-2026) — Model comparisons, multilingual capabilities
- [llamafile Mozilla](https://github.com/mozilla-ai/llamafile) — Single-file LLM executable, fallback option

### Tertiary (LOW confidence - needs validation)
- RAM estimates for concurrent services — based on general guidance, needs profiling on actual HP EliteBook
- conda-pack + llama-cpp-python compatibility — untested combination, based on analogy with other native extensions
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: llama-cpp-python for CPU LLM inference
- Ecosystem: GGUF models, SmolLM3-3B, Qwen 2.5 1.5B, llamafile
- Patterns: Backend abstraction, existing ask-chat-service extension
- Pitfalls: RAM, model loading, German quality, conda-pack native extensions

**Confidence breakdown:**
- Standard stack: HIGH — llama-cpp-python is the standard Python binding for llama.cpp, widely used
- Architecture: HIGH — extends existing proven architecture, minimal changes needed
- Pitfalls: MEDIUM — RAM estimates and conda-pack compatibility need validation on target hardware
- Code examples: HIGH — based on llama-cpp-python docs and existing codebase patterns
- GuppyLM rejection: HIGH — verified directly from GitHub repo, architecture is fundamentally incompatible

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 (30 days — llama.cpp ecosystem evolving but core stable)
</metadata>

---

*Phase: 14-guppy-llm-integration*
*Research completed: 2026-04-17*
*Ready for planning: yes*

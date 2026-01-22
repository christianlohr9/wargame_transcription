# Phase 3: Diarization Rewrite - Research

**Researched:** 2026-01-22
**Domain:** WhisperX + pyannote.audio for local speaker diarization (CPU-only)
**Confidence:** HIGH

<research_summary>
## Summary

Researched replacing AssemblyAI with WhisperX + pyannote.audio for fully local speaker diarization. WhisperX is the established solution for this exact use case - it wraps faster-whisper for transcription, wav2vec2 for word-level alignment, and pyannote.audio for speaker diarization into a single pipeline.

Key finding: WhisperX handles the entire pipeline (transcription + alignment + diarization + speaker assignment) in one integrated workflow. Don't hand-roll the integration between Whisper and pyannote - WhisperX solves this already. CPU-only inference is supported but significantly slower than GPU. For batch processing of wargame recordings (overnight jobs acceptable per PROJECT.md), this is acceptable.

Critical version consideration: pyannote/speaker-diarization-3.1 is ~2.5x SLOWER than 3.0 on CPU (but faster on GPU). For CPU-only deployment, consider using 3.0 with onnxruntime or accepting the slower 3.1 performance.

**Primary recommendation:** Use WhisperX as the primary library - it integrates faster-whisper + pyannote seamlessly. Use `small` or `medium` model for CPU with `int8` compute type. Expect ~10x real-time for CPU processing (1-hour audio takes ~10 hours).
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| whisperx | latest (pip) | Complete pipeline: transcription + alignment + diarization | Integrates all components, battle-tested |
| faster-whisper | (via whisperx) | Fast transcription with CTranslate2 | 4x faster than OpenAI Whisper, lower memory |
| pyannote.audio | 3.1.x or 3.0.x | Speaker diarization neural models | State-of-the-art diarization, actively maintained |
| torch | 2.x | Deep learning framework | Required for pyannote models |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ffmpeg | system | Audio decoding | Required for all audio formats |
| huggingface_hub | latest | Model downloads | Required for pyannote model access |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| WhisperX | Manual Whisper + pyannote | WhisperX already integrates them; manual integration is complex |
| pyannote 3.1 | pyannote 3.0 | 3.0 is 2.5x faster on CPU; 3.1 is faster on GPU only |
| faster-whisper | openai-whisper | Original Whisper is 4x slower and uses more memory |
| CPU | GPU | GPU is 10-20x faster but not available on target hardware |

**Installation:**
```bash
# CPU-only installation
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install whisperx

# ffmpeg (system dependency)
brew install ffmpeg  # macOS
sudo apt install ffmpeg  # Linux
```

**Environment Variables:**
```bash
HF_TOKEN=your_huggingface_token  # Required for pyannote models
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Project Structure
```
speaker-diarization-service/
├── src/
│   ├── services/
│   │   ├── diarization_service.py          # ABC (existing)
│   │   ├── assemblyai_diarization_service.py  # Keep for reference
│   │   └── whisperx_diarization_service.py    # NEW: WhisperX implementation
│   ├── models/
│   │   └── diarization_model.py            # Existing - matches output format
│   └── ...
```

### Pattern 1: WhisperX Full Pipeline
**What:** Use WhisperX's integrated pipeline for transcription + alignment + diarization
**When to use:** Always - this is the recommended approach
**Example:**
```python
# Source: Context7 /m-bain/whisperx
import whisperx

device = "cpu"
audio_file = "audio.mp3"
HF_TOKEN = os.getenv("HF_TOKEN")

# Step 1: Load audio
audio = whisperx.load_audio(audio_file)

# Step 2: Transcribe with faster-whisper
model = whisperx.load_model("small", device, compute_type="int8")
result = model.transcribe(audio, batch_size=4)

# Step 3: Align for word-level timestamps
model_a, metadata = whisperx.load_align_model(
    language_code=result["language"],
    device=device
)
result = whisperx.align(result["segments"], model_a, metadata, audio, device)

# Step 4: Diarize (identify speakers)
diarize_model = whisperx.DiarizationPipeline(
    use_auth_token=HF_TOKEN,
    device=device
)
diarize_segments = diarize_model(audio)

# Step 5: Assign speakers to words/segments
result = whisperx.assign_word_speakers(diarize_segments, result)

# Result structure:
# result["segments"] = [
#   {"text": "...", "start": 0.0, "end": 2.5, "speaker": "SPEAKER_00", "words": [...]},
#   ...
# ]
```

### Pattern 2: Output Mapping to Existing Interface
**What:** Map WhisperX output to existing DiarizationModel format
**When to use:** To maintain compatibility with existing codebase
**Example:**
```python
# Existing interface requires:
# - audio_duration: int (milliseconds)
# - available_speakers: list[str]
# - fragments: list[DiarizationFragmentModel]
#   - speaker: str
#   - transcription: str
#   - start_time: int (milliseconds)
#   - end_time: int (milliseconds)

def map_to_diarization_model(whisperx_result: dict, audio_duration_sec: float) -> DiarizationModel:
    fragments = []
    speakers = set()

    for segment in whisperx_result["segments"]:
        speaker = segment.get("speaker", "SPEAKER_00")
        speakers.add(f"Speaker {speaker.replace('SPEAKER_', '')}")

        fragments.append(DiarizationFragmentModel(
            speaker=f"Speaker {speaker.replace('SPEAKER_', '')}",
            transcription=segment["text"],
            start_time=int(segment["start"] * 1000),  # seconds to ms
            end_time=int(segment["end"] * 1000)
        ))

    return DiarizationModel(
        audio_duration=int(audio_duration_sec * 1000),
        available_speakers=list(speakers),
        fragments=fragments
    )
```

### Pattern 3: Model Caching
**What:** Load models once at service startup, reuse for all requests
**When to use:** Always - model loading is expensive (30-60 seconds)
**Example:**
```python
class WhisperXDiarizationService(DiarizationService):
    def __init__(self):
        self.device = "cpu"
        self.compute_type = "int8"
        self.hf_token = os.getenv("HF_TOKEN")

        # Load models ONCE at startup
        self.whisper_model = whisperx.load_model("small", self.device, compute_type=self.compute_type)
        self.diarize_model = whisperx.DiarizationPipeline(
            use_auth_token=self.hf_token,
            device=self.device
        )
        # Alignment model loaded per-language during diarize()
```

### Anti-Patterns to Avoid
- **Loading models per-request:** Model loading takes 30-60 seconds. Load once at startup.
- **Using float16 on CPU:** CPU doesn't benefit from float16; use int8 for speed.
- **Large batch sizes on CPU:** batch_size=16 is for GPU; use batch_size=4 or lower on CPU.
- **Rolling your own Whisper+pyannote integration:** WhisperX already handles the complex alignment between transcription and speaker segments.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Transcription + diarization integration | Custom alignment code | WhisperX | Aligning word timestamps with speaker segments is complex; WhisperX handles it |
| Word-level timestamps | Custom VAD + alignment | whisperx.align() | wav2vec2 alignment is state-of-the-art; custom solutions are worse |
| Speaker embedding extraction | Custom neural net | pyannote.audio | Pretrained embeddings are much better than custom |
| Speaker clustering | K-means or similar | pyannote diarization pipeline | Handles overlapping speech, variable speakers |
| Audio preprocessing | Manual resampling/mono conversion | whisperx.load_audio() | Handles all formats via ffmpeg |

**Key insight:** Speaker diarization is a solved problem with mature libraries. WhisperX integrates faster-whisper (transcription) + wav2vec2 (alignment) + pyannote (diarization) into one coherent pipeline. Any custom integration will be worse and take longer to build.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Pyannote 3.1 CPU Performance
**What goes wrong:** Diarization is 2.5x slower than expected on CPU
**Why it happens:** pyannote 3.1 removed ONNX runtime (which was CPU-optimized) for pure PyTorch
**How to avoid:** Either accept slower 3.1 performance OR use 3.0 with onnxruntime
**Warning signs:** Embeddings step taking 35+ minutes for 45-minute audio

### Pitfall 2: Missing Hugging Face Token
**What goes wrong:** Diarization fails with authentication error
**Why it happens:** pyannote models are gated and require HF token
**How to avoid:** Set HF_TOKEN environment variable; accept model license on HuggingFace
**Warning signs:** "Authentication required" or "Access denied" errors

### Pitfall 3: Model Loading on Every Request
**What goes wrong:** Each diarization takes 30-60 seconds longer than expected
**Why it happens:** Loading Whisper + alignment + diarization models is slow
**How to avoid:** Load models once at service startup, reuse for all requests
**Warning signs:** First request slow, all subsequent requests equally slow

### Pitfall 4: Wrong Compute Type for CPU
**What goes wrong:** Errors or no speedup from int8
**Why it happens:** Using float16 on CPU (only benefits GPU)
**How to avoid:** Use `compute_type="int8"` for CPU
**Warning signs:** No performance improvement or CUDA-related errors

### Pitfall 5: Large Batch Size on CPU
**What goes wrong:** Out of memory or very slow processing
**Why it happens:** batch_size=16 is tuned for GPU VRAM, not CPU RAM
**How to avoid:** Use `batch_size=4` or lower on CPU
**Warning signs:** Memory usage spikes, system slowdown

### Pitfall 6: Expecting Real-Time Performance on CPU
**What goes wrong:** Processing takes much longer than audio duration
**Why it happens:** CPU inference is ~10x slower than GPU
**How to avoid:** Set expectations correctly; batch processing overnight is the solution
**Warning signs:** 1-hour audio taking 10+ hours to process
</common_pitfalls>

<code_examples>
## Code Examples

Verified patterns from official sources:

### Complete WhisperX CPU Pipeline
```python
# Source: Context7 /m-bain/whisperx - CPU-only inference example
import whisperx
import os

def diarize_audio(audio_file: str, language: str | None = None) -> dict:
    device = "cpu"
    compute_type = "int8"  # Required for CPU efficiency
    batch_size = 4  # Lower for CPU (GPU uses 16)
    hf_token = os.getenv("HF_TOKEN")

    # Load audio
    audio = whisperx.load_audio(audio_file)

    # Transcribe
    model = whisperx.load_model("small", device, compute_type=compute_type)
    result = model.transcribe(audio, batch_size=batch_size, language=language)

    # Align for word timestamps
    model_a, metadata = whisperx.load_align_model(
        language_code=result["language"],
        device=device
    )
    result = whisperx.align(
        result["segments"],
        model_a,
        metadata,
        audio,
        device,
        return_char_alignments=False
    )

    # Diarize
    diarize_model = whisperx.DiarizationPipeline(
        use_auth_token=hf_token,
        device=device
    )
    diarize_segments = diarize_model(audio)

    # Assign speakers
    result = whisperx.assign_word_speakers(diarize_segments, result)

    return result
```

### Service Implementation Pattern
```python
# Pattern for integrating with existing codebase
from models.diarization_model import DiarizationFragmentModel, DiarizationModel
from services.diarization_service import DiarizationService
import whisperx
import os

class WhisperXDiarizationService(DiarizationService):
    def __init__(self):
        self.device = "cpu"
        self.compute_type = "int8"
        self.batch_size = 4
        self.hf_token = self._get_hf_token()

        # Load models once at startup
        self.whisper_model = whisperx.load_model(
            "small",
            self.device,
            compute_type=self.compute_type
        )
        self.diarize_pipeline = whisperx.DiarizationPipeline(
            use_auth_token=self.hf_token,
            device=self.device
        )

    def diarize(self, audio_file: str, language: str | None = None) -> DiarizationModel:
        audio = whisperx.load_audio(audio_file)

        # Transcribe
        result = self.whisper_model.transcribe(
            audio,
            batch_size=self.batch_size,
            language=language
        )

        # Align
        model_a, metadata = whisperx.load_align_model(
            language_code=result["language"],
            device=self.device
        )
        result = whisperx.align(
            result["segments"],
            model_a,
            metadata,
            audio,
            self.device
        )

        # Diarize and assign speakers
        diarize_segments = self.diarize_pipeline(audio)
        result = whisperx.assign_word_speakers(diarize_segments, result)

        return self._map_to_model(result, len(audio) / 16000)  # audio is 16kHz

    def _map_to_model(self, result: dict, duration_sec: float) -> DiarizationModel:
        fragments = []
        speakers = set()

        for segment in result["segments"]:
            speaker_raw = segment.get("speaker", "SPEAKER_00")
            speaker = f"Speaker {speaker_raw.replace('SPEAKER_', '')}"
            speakers.add(speaker)

            fragments.append(DiarizationFragmentModel(
                speaker=speaker,
                transcription=segment["text"].strip(),
                start_time=int(segment["start"] * 1000),
                end_time=int(segment["end"] * 1000)
            ))

        return DiarizationModel(
            audio_duration=int(duration_sec * 1000),
            available_speakers=sorted(list(speakers)),
            fragments=fragments
        )

    @staticmethod
    def _get_hf_token() -> str:
        token = os.getenv("HF_TOKEN")
        if not token:
            raise ValueError("HF_TOKEN environment variable is not set")
        return token
```

### CLI Usage for Testing
```bash
# Source: Context7 /m-bain/whisperx - CLI examples

# Basic CPU transcription with diarization
whisperx audio.wav \
  --compute_type int8 \
  --device cpu \
  --model small \
  --batch_size 4 \
  --diarize \
  --hf_token $HF_TOKEN \
  --output_format json

# With known speaker count (improves accuracy)
whisperx meeting.wav \
  --compute_type int8 \
  --device cpu \
  --model small \
  --batch_size 4 \
  --diarize \
  --min_speakers 2 \
  --max_speakers 6 \
  --hf_token $HF_TOKEN \
  --output_format json
```
</code_examples>

<sota_updates>
## State of the Art (2024-2026)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| openai-whisper | faster-whisper (via WhisperX) | 2023 | 4x faster, lower memory |
| Manual Whisper+pyannote integration | WhisperX integrated pipeline | 2023 | Much simpler, handles alignment |
| pyannote 2.1 | pyannote 3.0/3.1 | 2023-2024 | Better accuracy, but CPU perf varies |
| onnxruntime in pyannote | Pure PyTorch (3.1) | 2024 | Easier deployment but slower on CPU |

**New tools/patterns to consider:**
- **speaker-diarization-3.1:** Pure PyTorch, no ONNX dependencies. Faster on GPU, slower on CPU.
- **Whisper model variants:** "small" (244M params) good balance for CPU; "medium" if higher accuracy needed.
- **Batched inference pipeline:** faster-whisper's BatchedInferencePipeline for even faster processing.

**Deprecated/outdated:**
- **openai-whisper:** Use faster-whisper instead (via WhisperX)
- **pyannote 2.x:** Use 3.x for better accuracy
- **Manual Whisper+pyannote integration:** Use WhisperX
</sota_updates>

<open_questions>
## Open Questions

1. **Optimal model size for 16GB RAM**
   - What we know: "small" model uses ~2GB VRAM; CPU RAM usage higher
   - What's unclear: Exact RAM usage on CPU with int8 quantization
   - Recommendation: Start with "small" model; test "medium" if accuracy insufficient

2. **pyannote 3.0 vs 3.1 on CPU**
   - What we know: 3.1 is 2.5x slower on CPU; 3.0 requires onnxruntime
   - What's unclear: Whether WhisperX defaults to 3.0 or 3.1
   - Recommendation: Test both; accept 3.1 slowness for simpler dependencies

3. **Alignment model language support**
   - What we know: Alignment requires language-specific wav2vec2 models
   - What's unclear: Which languages are supported for alignment
   - Recommendation: Test with English first; check wav2vec2 model availability for other languages
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- [Context7 /m-bain/whisperx](https://context7.com/m-bain/whisperx/llms.txt) - Full pipeline examples, CPU inference
- [Context7 /pyannote/pyannote-audio](https://context7.com/pyannote/pyannote-audio/llms.txt) - Diarization pipeline usage
- [Context7 /systran/faster-whisper](https://context7.com/systran/faster-whisper/llms.txt) - Batched inference, word timestamps

### Secondary (MEDIUM confidence)
- [Hugging Face pyannote/speaker-diarization-3.1](https://huggingface.co/pyannote/speaker-diarization-3.1) - Model card, requirements
- [GitHub WhisperX](https://github.com/m-bain/whisperX) - README, CLI options
- [GitHub Issue #1621](https://github.com/pyannote/pyannote-audio/issues/1621) - 3.1 vs 3.0 CPU performance

### Tertiary (LOW confidence - needs validation)
- WebSearch results on batch processing patterns - verified against Context7
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: WhisperX (integrates faster-whisper + wav2vec2 + pyannote)
- Ecosystem: pyannote.audio 3.x, faster-whisper, torch
- Patterns: Integrated pipeline, model caching, output mapping
- Pitfalls: CPU performance, model loading, HF authentication

**Confidence breakdown:**
- Standard stack: HIGH - verified with Context7, official repos
- Architecture: HIGH - code examples from Context7
- Pitfalls: HIGH - documented in GitHub issues, verified
- Code examples: HIGH - from Context7 official sources

**Research date:** 2026-01-22
**Valid until:** 2026-02-22 (30 days - WhisperX ecosystem relatively stable)
</metadata>

---

*Phase: 03-diarization-rewrite*
*Research completed: 2026-01-22*
*Ready for planning: yes*

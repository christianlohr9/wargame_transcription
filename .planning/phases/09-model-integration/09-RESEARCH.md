# Phase 9: Model Integration - Research

**Researched:** 2026-04-13
**Domain:** Speech model integration — Voxtral evaluation + faster-whisper/pyannote hybrid pipeline
**Confidence:** HIGH

<research_summary>
## Summary

Researched Voxtral as a potential all-in-one transcription+diarization solution, and the hybrid pipeline (faster-whisper + pyannote + WhisperX alignment) as the fallback. The Voxtral evaluation is conclusive: the all-in-one dream is not viable for self-hosted CPU-only deployment.

**Voxtral's built-in diarization (Mini Transcribe V2) is API-only** — Mistral has not released open weights for it. The open-weights models (Voxtral Realtime 4B, Voxtral Mini 3B) do transcription only, with no speaker diarization. Furthermore, even pure transcription with Voxtral on 16GB CPU is marginal: peak memory approaches 18-19GB and CPU inference is ~28x slower than GPU.

The hybrid pipeline from Phase 8 recommendations stands as the clear winner: faster-whisper distil-large-v3 (int8) for transcription + pyannote 3.1 for diarization + WhisperX alignment for word-level timestamps and speaker assignment. The integration is straightforward — a segment format adapter and model swap in the existing service.

**Primary recommendation:** Skip Voxtral, implement the hybrid pipeline. The integration requires swapping the transcription model and adding a ~10-line segment format adapter. Everything else stays unchanged.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| faster-whisper | 1.2.1 (via whisperx) | Transcription engine | CTranslate2-based, 4x faster than vanilla Whisper, int8 CPU support |
| whisperx | 3.7.4 | Alignment + diarization orchestration | Provides wav2vec2 alignment and pyannote speaker assignment |
| pyannote.audio | 3.1 (via whisperx) | Speaker diarization | Only tested diarizer with correct speaker counts; gated HF model |
| torch | 2.8.0 (CPU) | ML framework | Required by all models; CPU-only build to save space |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| wav2vec2 alignment model | (via whisperx) | Word-level timestamp alignment | Always — bridges transcription segments to word timestamps |
| psutil | (installed) | Memory monitoring | Benchmarking and health checks |
| CTranslate2 | (via faster-whisper) | Optimized inference | Provides int8 quantization for CPU efficiency |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| faster-whisper distil-large-v3 | Voxtral Realtime 4B | Voxtral: 4B params, ~19GB peak RAM, ~28x slower on CPU, no diarization |
| faster-whisper distil-large-v3 | distil-large-v3.5 | v3.5 exists (trained on 98k hours, improved quality), but not yet benchmarked on our hardware. Future upgrade candidate. |
| pyannote | diarize library | 5x faster but detects 8 speakers on 3-speaker audio — unusable accuracy |
| WhisperX alignment | faster-whisper word_timestamps | faster-whisper word timestamps available, but WhisperX wav2vec2 alignment is more accurate and already integrated |

**No new dependencies needed:**
```bash
# Everything is already installed via whisperx
pip install whisperx  # pulls faster-whisper, pyannote.audio, wav2vec2
```

The distil-large-v3 model auto-downloads from HuggingFace on first use (~750MB download, 525MB runtime).
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Current vs Hybrid Architecture

**Current (unified WhisperX):**
```
audio --> whisperx.load_model("small") --> transcribe --> align --> diarize --> assign_speakers
```

**Target (hybrid pipeline):**
```
audio --> faster_whisper.WhisperModel("distil-large-v3") --> transcribe
      \-> pyannote DiarizationPipeline --> diarize
          segments + diarize_segments --> whisperx.align() --> whisperx.assign_word_speakers()
```

### Pattern 1: Segment Format Adapter
**What:** Convert faster-whisper Segment objects to WhisperX dict format
**When to use:** Whenever feeding faster-whisper output into WhisperX alignment
**Example:**
```python
from faster_whisper import WhisperModel

# faster-whisper returns generator of Segment namedtuples
model = WhisperModel("distil-large-v3", device="cpu", compute_type="int8")
segments_gen, info = model.transcribe(audio, beam_size=5)

# Convert to WhisperX expected format: list of dicts
segments_list = [
    {"start": seg.start, "end": seg.end, "text": seg.text}
    for seg in segments_gen
]

# Now usable with whisperx.align()
result = {"segments": segments_list, "language": info.language}
```

### Pattern 2: Shared Audio Loading
**What:** Load audio once, reuse for both transcription and diarization
**When to use:** Hybrid pipeline where multiple models consume the same audio
**Example:**
```python
import whisperx

# Load audio once (16kHz mono float32 numpy array)
audio = whisperx.load_audio(audio_file)

# faster-whisper accepts numpy ndarray directly
segments_gen, info = self.whisper_model.transcribe(audio, beam_size=5)

# Same audio array used for alignment and diarization
diarize_segments = self.diarize_pipeline(audio)
result = whisperx.align(result["segments"], model_a, metadata, audio, device)
```

### Pattern 3: Model Loading at Startup
**What:** Load all models once in `__init__`, reuse across requests
**When to use:** Always — model loading takes 1-30 seconds
**Example:**
```python
class HybridDiarizationService(DiarizationService):
    def __init__(self):
        from faster_whisper import WhisperModel

        # Transcription model (1s load, 525MB)
        self.whisper_model = WhisperModel(
            "distil-large-v3", device="cpu", compute_type="int8"
        )

        # Diarization model (4s load, 504MB)
        self.diarize_pipeline = DiarizationPipeline(
            use_auth_token=self.hf_token, device="cpu"
        )

        # Alignment model loaded per-language on first use
        self._align_model = None
        self._align_metadata = None
        self._align_language = None
```

### Anti-Patterns to Avoid
- **Loading WhisperX model just for alignment:** WhisperX's `load_model()` loads the full Whisper model. For hybrid pipeline, only use faster-whisper for transcription and whisperx for alignment/diarization functions.
- **Converting segments after consuming generator:** faster-whisper `transcribe()` returns a generator. Must consume it into a list before reuse. Don't iterate twice.
- **Reloading alignment model per request:** The wav2vec2 alignment model can be cached if the language doesn't change between requests.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Word-level timestamps | Custom timestamp interpolation | `whisperx.align()` with wav2vec2 | Phoneme-based alignment is far more accurate than simple interpolation |
| Speaker-to-word assignment | Custom temporal overlap matching | `whisperx.assign_word_speakers()` | Handles edge cases (overlapping speech, partial segments) correctly |
| Audio loading/resampling | Custom ffmpeg calls | `whisperx.load_audio()` | Handles format detection, resampling to 16kHz, mono conversion |
| Speaker diarization | Custom clustering | pyannote 3.1 pipeline | Years of research; custom approaches over-segment or miss speakers |
| Segment format conversion | Complex schema mapping | Simple list comprehension | Only 3 fields needed: start, end, text — keep it trivial |

**Key insight:** The integration work is deliberately minimal. The hard problems (transcription, diarization, alignment, speaker assignment) are all solved by existing libraries. The only custom code needed is a ~10-line segment format adapter.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: PyTorch 2.6+ weights_only Breakage
**What goes wrong:** pyannote model loading fails with `UnpicklingError` on PyTorch 2.6+
**Why it happens:** PyTorch 2.6 changed `torch.load` default to `weights_only=True`, but pyannote checkpoints use classes not in the safe list
**How to avoid:** Apply the monkeypatch from `src/patches.py` BEFORE any torch imports. Already implemented in the current codebase.
**Warning signs:** `_pickle.UnpicklingError: Weights only load failed` at startup

### Pitfall 2: Generator Consumption
**What goes wrong:** faster-whisper segments are empty on second iteration
**Why it happens:** `model.transcribe()` returns a generator, not a list. Once consumed, it's empty.
**How to avoid:** Immediately convert to list: `segments = list(segments_gen)` or use a list comprehension
**Warning signs:** Empty transcription with no errors

### Pitfall 3: Audio Format Mismatch
**What goes wrong:** Garbled transcription or silence detection
**Why it happens:** faster-whisper expects 16kHz float32 mono numpy array. Wrong sample rate or dtype produces garbage.
**How to avoid:** Use `whisperx.load_audio()` which guarantees correct format, then pass the numpy array to both faster-whisper and alignment
**Warning signs:** Very high WER, "hallucinated" transcription text, or empty segments

### Pitfall 4: Memory Accumulation
**What goes wrong:** RSS grows with each request, eventually OOM
**Why it happens:** Alignment model, intermediate tensors, or audio arrays not freed
**How to avoid:** After alignment, delete alignment model and call `gc.collect()`. Or cache alignment model if language is consistent (German wargame audio).
**Warning signs:** Gradual RSS increase visible in health checks

### Pitfall 5: Language Detection Mismatch
**What goes wrong:** Alignment model loaded for wrong language
**Why it happens:** faster-whisper and WhisperX may detect different languages, or the user-specified language isn't passed consistently
**How to avoid:** Use the language from faster-whisper's `info.language` for alignment model loading, or accept user-specified language and pass to both
**Warning signs:** Alignment fails silently (words get `None` timestamps), degraded speaker assignment
</common_pitfalls>

<code_examples>
## Code Examples

Verified patterns from official sources and existing codebase:

### Hybrid Pipeline — Full Integration
```python
# Source: Adapted from current whisperx_diarization_service.py + Phase 8 benchmarks
from faster_whisper import WhisperModel
import whisperx
from whisperx.diarize import DiarizationPipeline

class HybridDiarizationService:
    def __init__(self):
        self.device = "cpu"
        self.hf_token = os.getenv("HF_TOKEN")

        # NEW: faster-whisper for transcription (replaces whisperx.load_model)
        self.whisper_model = WhisperModel(
            "distil-large-v3", device="cpu", compute_type="int8"
        )

        # UNCHANGED: pyannote for diarization
        self.diarize_pipeline = DiarizationPipeline(
            use_auth_token=self.hf_token, device="cpu"
        )

    def diarize(self, audio_file, language=None):
        # Load audio once (16kHz float32 mono)
        audio = whisperx.load_audio(audio_file)
        duration_sec = len(audio) / 16000

        # NEW: Transcribe with faster-whisper
        segments_gen, info = self.whisper_model.transcribe(
            audio, beam_size=5, language=language
        )

        # NEW: Convert faster-whisper segments to WhisperX format
        segments = [
            {"start": seg.start, "end": seg.end, "text": seg.text}
            for seg in segments_gen
        ]
        detected_language = language or info.language

        # UNCHANGED: Align for word timestamps
        model_a, metadata = whisperx.load_align_model(
            language_code=detected_language, device=self.device
        )
        result = whisperx.align(
            segments, model_a, metadata, audio,
            self.device, return_char_alignments=False
        )

        # UNCHANGED: Diarize and assign speakers
        diarize_segments = self.diarize_pipeline(audio)
        result = whisperx.assign_word_speakers(diarize_segments, result)

        return self._map_to_model(result, duration_sec)
```

### faster-whisper Segment Object Structure
```python
# Source: faster-whisper docs / Context7
# faster-whisper transcribe() returns (generator[Segment], TranscriptionInfo)

# Segment namedtuple fields:
#   .id        int     - segment index
#   .start     float   - start time in seconds
#   .end       float   - end time in seconds
#   .text      str     - transcribed text
#   .tokens    list    - token IDs
#   .words     list    - word-level data (if word_timestamps=True)
#   .avg_logprob float - average log probability

# TranscriptionInfo fields:
#   .language             str   - detected language code
#   .language_probability float - detection confidence
#   .duration             float - audio duration in seconds
```

### WhisperX Segment Format (Expected by align())
```python
# Source: WhisperX Context7 docs
# whisperx.align() expects segments as list of dicts:
segments = [
    {"start": 0.0, "end": 2.5, "text": "Hello, how are you?"},
    {"start": 2.8, "end": 5.1, "text": "I'm doing well, thanks."},
]

# After alignment, segments gain word-level timestamps:
# result["segments"][0]["words"] = [
#   {"start": 0.0, "end": 0.3, "word": "Hello,", "score": 0.95},
#   {"start": 0.4, "end": 0.6, "word": "how", "score": 0.92},
#   ...
# ]
```
</code_examples>

<sota_updates>
## State of the Art (2025-2026)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| WhisperX small (int8) unified | faster-whisper distil-large-v3 (int8) hybrid | Phase 8 (2026-04) | Better punctuation, smaller model (525MB vs 1244MB), stable RTF |
| cannon-es / diarize library | pyannote 3.1 retained | Phase 8 (2026-04) | Only accurate diarizer tested; diarize lib over-segments |
| Voxtral as all-in-one dream | Hybrid pipeline | This research | Voxtral diarization is API-only; open-weights models lack it |

**New tools/patterns to consider:**
- **distil-large-v3.5:** Released 2025, trained on 98k hours (4x more data than v3), 1.5x faster than large-v3-turbo. Available in faster-whisper format via CTranslate2 conversion. Future upgrade candidate after Phase 9 ships.
- **Voxtral Realtime (4B):** Apache 2.0 open-weights transcription-only model. Not viable for 16GB CPU today, but worth monitoring for future GPU deployments.
- **voxtral.c:** Pure C inference of Voxtral — community project for edge deployment. CPU performance still ~28x slower than GPU.

**Deprecated/outdated:**
- **Voxtral all-in-one dream:** The diarization capability (Mini Transcribe V2) is API-only. Open-weights models do transcription only.
- **WhisperX small model:** Superseded by distil-large-v3 on every metric except raw RTF (0.20 vs 0.30, but small lacks punctuation).
</sota_updates>

<open_questions>
## Open Questions

1. **distil-large-v3.5 performance on our hardware**
   - What we know: v3.5 trained on 4x more data, 1.5x faster than large-v3-turbo, available in CTranslate2 format
   - What's unclear: CPU int8 performance, memory footprint, and quality on wargame audio specifically
   - Recommendation: Benchmark v3.5 as a follow-up after Phase 9 ships with v3. Low risk to defer — v3 is proven.

2. **Alignment model caching strategy**
   - What we know: wav2vec2 alignment model is language-specific. Wargame audio is likely always German.
   - What's unclear: Whether caching the alignment model across requests causes memory issues or stale state
   - Recommendation: Start with per-request loading (current pattern), optimize to cached if profiling shows it matters

3. **faster-whisper numpy array input compatibility**
   - What we know: faster-whisper docs say `transcribe()` accepts numpy ndarray (1D float32 16kHz)
   - What's unclear: Whether whisperx.load_audio() output format is exactly what faster-whisper expects (sample rate, dtype)
   - Recommendation: Verify in Phase 9 implementation. If format mismatch, pass file path to faster-whisper instead (already works per benchmarks).
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- Context7 /guillaumekln/faster-whisper — transcribe API, segment format, word timestamps, model initialization
- Context7 /m-bain/whisperx — align() API, assign_word_speakers(), segment format, full pipeline example
- Existing codebase: `speaker-diarization-service/src/services/whisperx_diarization_service.py` — current implementation
- Existing benchmarks: `speaker-diarization-service/benchmarks/bench_transcription.py` — faster-whisper usage patterns
- Phase 8 recommendation: `.planning/phases/08-model-research/08-RECOMMENDATION.md` — benchmarked results

### Secondary (MEDIUM confidence)
- [Mistral AI Voxtral Transcribe 2 announcement](https://mistral.ai/news/voxtral-transcribe-2) — confirmed Mini Transcribe V2 is API-only, Realtime is open-weights
- [HuggingFace Voxtral-Mini-3B GGUF](https://huggingface.co/bartowski/mistralai_Voxtral-Mini-3B-2507-GGUF) — model sizes: Q4_K_M 2.47GB, BF16 8.04GB
- [GitHub antirez/voxtral.c](https://github.com/antirez/voxtral.c) — CPU performance ~28x slower than GPU, peak memory ~18-19GB
- [HuggingFace distil-large-v3.5](https://huggingface.co/distil-whisper/distil-large-v3.5) — v3.5 exists, trained on 98k hours
- [SYSTRAN/faster-whisper GitHub](https://github.com/SYSTRAN/faster-whisper) — transcribe() accepts str, BinaryIO, or ndarray

### Tertiary (LOW confidence — needs validation)
- [MarkTechPost Voxtral Transcribe 2](https://www.marktechpost.com/2026/02/04/mistral-ai-launches-voxtral-transcribe-2-pairing-batch-diarization-and-open-realtime-asr-for-multilingual-production-workloads-at-scale/) — verified against Mistral announcement
- [Northflank STT benchmarks 2026](https://northflank.com/blog/best-open-source-speech-to-text-stt-model-in-2026-benchmarks) — external benchmark context
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: Voxtral model family evaluation, faster-whisper + WhisperX hybrid pipeline
- Ecosystem: faster-whisper, whisperx, pyannote.audio, CTranslate2, Voxtral (Mistral)
- Patterns: Hybrid pipeline architecture, segment format adapter, model loading
- Pitfalls: PyTorch compatibility, generator consumption, audio format, memory management

**Confidence breakdown:**
- Voxtral assessment: HIGH — verified across official announcement, HuggingFace, and community implementations
- Standard stack: HIGH — already benchmarked in Phase 8, confirmed with Context7 docs
- Architecture: HIGH — patterns verified against existing codebase and official docs
- Pitfalls: HIGH — PyTorch patch already in production; others from official docs
- Code examples: HIGH — adapted from verified Context7 sources and existing service code

**Research date:** 2026-04-13
**Valid until:** 2026-05-13 (30 days — faster-whisper ecosystem stable, Voxtral still evolving)
</metadata>

---

*Phase: 09-model-integration*
*Research completed: 2026-04-13*
*Ready for planning: yes*

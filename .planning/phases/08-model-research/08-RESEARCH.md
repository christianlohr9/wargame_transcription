# Phase 8: Model Research - Research

**Researched:** 2026-04-13
**Domain:** CPU-only speech transcription and speaker diarization on 16GB RAM
**Confidence:** HIGH

<research_summary>
## Summary

Researched the current landscape of speech-to-text and speaker diarization models for CPU-only deployment on a 16GB RAM HP EliteBook (macOS). The goal was to find better/lighter alternatives to the existing WhisperX + pyannote stack, with special attention to Voxtral's all-in-one potential.

**Key finding:** Voxtral is NOT viable for this hardware. Voxtral Small (24B) — the only variant with diarization — requires ~55GB VRAM. Voxtral Mini (4B) does transcription only (no diarization) and requires ~10GB GPU RAM in BF16. Even with GGUF quantization, Voxtral Mini's CPU inference is slow (~8s to encode 3.6s of audio on M3 Max) and it still lacks diarization. The all-in-one dream doesn't work here.

The real opportunity is in the **diarization side**: a new library called `diarize` (Apache 2.0) achieves 7x faster CPU performance than pyannote with comparable accuracy (~10.8% DER vs ~11.2%). For transcription, the current faster-whisper (via WhisperX) with `distil-large-v3` and INT8 quantization is already near-optimal for CPU. The best path is: keep faster-whisper for transcription, benchmark `diarize` vs pyannote for diarization.

**Primary recommendation:** Benchmark faster-whisper with distil-large-v3 (INT8) for transcription and `diarize` library for diarization against the current WhisperX + pyannote baseline. Voxtral can be tested as a bonus but should not be the primary candidate.
</research_summary>

<standard_stack>
## Standard Stack

### Transcription Candidates

| Model/Library | Parameters | CPU RAM | Speed (CPU) | WER | License |
|---------------|-----------|---------|-------------|-----|---------|
| faster-whisper (distil-large-v3, INT8) | 756M | ~3-4GB | ~4-6x faster than openai/whisper | Within 1% of large-v3 | MIT |
| faster-whisper (large-v3, INT8) | 1.55B | ~5-6GB | ~4x faster than openai/whisper | ~7.4% (FLEURS) | MIT |
| faster-whisper (large-v3-turbo, INT8) | 809M | ~3-4GB | Faster than large-v3 | ~7.75% | MIT |
| whisper.cpp (large-v3, q5_0) | 1.55B | ~4GB | Fast with CoreML on Apple Silicon | ~7.4% | MIT |
| whisper.cpp (large-v3-turbo, q5_0) | 809M | ~3GB | Very fast with ANE | ~7.75% | MIT |
| Voxtral Mini 4B (GGUF Q4) | 4B | ~2.5GB (disk) + ~2GB KV | Very slow on CPU (~2.2x slower than realtime) | ~4% (FLEURS) | Apache 2.0 |

### Diarization Candidates

| Library | DER | CPU Speed (RTF) | RAM | Max Speakers | License |
|---------|-----|-----------------|-----|-------------|---------|
| pyannote 3.1 (current) | ~11.2% | 1.74 (slower than realtime) | ~1.5GB | Unlimited | MIT (community model) |
| **diarize** | ~10.8% | 0.12 (8x faster than realtime) | Low (ONNX) | Best ≤5, degrades 8+ | Apache 2.0 |
| Falcon (Picovoice) | Comparable to pyannote | ~100x faster than pyannote | 0.1GB | Unknown | **Proprietary** (not open source) |
| NeMo MSDD | ~9% DER (2-speaker) | GPU-optimized | Heavy | Best ≤5 | Apache 2.0 |
| SpeechBrain ECAPA-TDNN | Comparable | 6.7x faster than pyannote | Moderate | Moderate | Apache 2.0 |

### Recommended Stack for Benchmarking

**Transcription tier:**
1. **faster-whisper + distil-large-v3 (INT8)** — Best speed/accuracy tradeoff for CPU
2. **whisper.cpp + large-v3-turbo (q5_0)** — Alternative if CoreML/ANE acceleration available
3. **Voxtral Mini 4B (GGUF Q4)** — Bonus test only, expect slow CPU performance

**Diarization tier:**
1. **diarize** — 7x faster than pyannote on CPU, comparable accuracy, dead simple API
2. **pyannote 3.1** (baseline) — Current stack, known quantity
3. **SpeechBrain ECAPA-TDNN + MeanShift** — If diarize doesn't meet accuracy needs

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| faster-whisper | whisper.cpp | whisper.cpp better on Apple Silicon with CoreML; faster-whisper better in Python ecosystem |
| diarize | Falcon (Picovoice) | Falcon is faster but **proprietary/commercial** — not open source |
| diarize | NeMo MSDD | NeMo is more accurate for 2-speaker but heavier, GPU-focused |
| Voxtral Small 24B | — | Only Voxtral variant with diarization, requires ~55GB VRAM — impossible on 16GB |

### Installation (for benchmarking)

```bash
# Transcription candidates
pip install faster-whisper  # already installed via WhisperX

# Diarization candidate
pip install diarize

# whisper.cpp (if testing)
brew install whisper-cpp  # or build from source with CoreML
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Current Pipeline (Baseline)
```
Audio → WhisperX (faster-whisper + pyannote) → Diarized Transcript
         ├── faster-whisper: transcription
         ├── pyannote: speaker embedding + diarization
         └── WhisperX: alignment + merging
```

### Proposed Test Architecture
```
Audio ──┬── Transcription Path ──── Timed Segments
        └── Diarization Path ────── Speaker Labels
                                         │
                              Merge: assign speakers to segments
```

### Pattern 1: Separate Transcription + Diarization
**What:** Run transcription and diarization independently, merge results
**When to use:** When best-of-breed models differ per task
**Example:**
```python
from faster_whisper import WhisperModel
from diarize import diarize

# Transcription
model = WhisperModel("distil-large-v3", device="cpu", compute_type="int8")
segments, info = model.transcribe("audio.wav", beam_size=5)

# Diarization
diar_result = diarize("audio.wav")

# Merge: assign speaker labels to transcript segments by time overlap
```

### Pattern 2: Integrated Pipeline (Current WhisperX)
**What:** WhisperX handles both transcription and diarization in one pipeline
**When to use:** Convenience, but ties you to WhisperX's pyannote integration
**Example:**
```python
import whisperx

model = whisperx.load_model("large-v3", device="cpu", compute_type="int8")
result = model.transcribe("audio.wav")
result = whisperx.align(result["segments"], ...)
diarize_model = whisperx.DiarizationPipeline(device="cpu")
diarize_segments = diarize_model("audio.wav")
result = whisperx.assign_word_speakers(diarize_segments, result)
```

### Anti-Patterns to Avoid
- **Testing only on benchmark audio:** Must test on real wargame recordings — they have unique acoustic properties (radio chatter, background noise, overlapping speech)
- **Optimizing for a single metric:** Speed, accuracy, AND memory all matter equally on 16GB hardware
- **Ignoring model loading time:** Some models take 30+ seconds to load — matters for user experience even if inference is fast
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Speaker embedding extraction | Custom neural network | diarize (WeSpeaker ONNX) or pyannote | Embedding quality is critical, pretrained models are far superior |
| Speaker clustering | Custom k-means | diarize (spectral clustering) or pyannote | Speaker count estimation is the hard part — these libraries handle it |
| VAD (Voice Activity Detection) | Energy-based thresholding | Silero VAD (used by diarize) | Neural VAD dramatically outperforms energy-based on noisy audio |
| Benchmark harness | Ad-hoc timing scripts | Structured benchmark with standardized metrics (WER, DER, RTF, peak RAM) | Reproducible comparisons require consistent methodology |
| Audio preprocessing | Custom resampling/normalization | librosa or soundfile | Edge cases in audio format handling are numerous |

**Key insight:** The entire speech processing pipeline is mature. Every component (VAD, embedding, clustering, transcription) has battle-tested open-source implementations. The research phase is about CHOOSING between them, not building any of them.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Benchmarking on Clean Audio Only
**What goes wrong:** Model performs great on LibriSpeech but fails on noisy wargame recordings
**Why it happens:** Standard benchmarks use studio-quality audio; wargame audio has radio effects, background noise, overlapping speakers
**How to avoid:** Always include real wargame recordings in benchmark suite alongside standard benchmarks
**Warning signs:** Model WER/DER looks suspiciously good vs published benchmarks

### Pitfall 2: Memory Spikes During Model Loading
**What goes wrong:** Model fits in 4GB at inference but spikes to 12GB during loading, OOM-killing other services
**Why it happens:** Model loading often requires 2-3x the final memory footprint temporarily
**How to avoid:** Monitor peak RSS during load AND inference separately; test with other services running
**Warning signs:** Benchmarks pass in isolation but fail when Docker infrastructure is running (~2.4GB already used)

### Pitfall 3: Voxtral CPU Performance Expectations
**What goes wrong:** Expecting Voxtral Mini 4B to perform well on CPU because "it's only 4B parameters"
**Why it happens:** Voxtral is a transformer LM architecture, not a CTC/RNN-T model — it autoregressively generates tokens, making CPU inference fundamentally slower than encoder-only models like Whisper
**How to avoid:** Set realistic expectations: voxtral.c on M3 Max takes ~8s to encode 3.6s of audio on CPU (BLAS). On an HP EliteBook it will be significantly slower
**Warning signs:** Realtime factor >2.0 (slower than realtime)

### Pitfall 4: Ignoring the Diarization ↔ Transcription Alignment Step
**What goes wrong:** Great transcription + great diarization but poor merged output
**Why it happens:** Timestamp alignment between separate models isn't trivial — segment boundaries don't perfectly align
**How to avoid:** Budget time for the merge/alignment step; WhisperX's approach (word-level alignment + speaker assignment) is proven
**Warning signs:** Speaker labels assigned to wrong segments, especially at speaker transitions

### Pitfall 5: Quantization Accuracy Degradation
**What goes wrong:** INT8/Q4 quantized model has noticeably worse accuracy than FP16/FP32
**Why it happens:** Aggressive quantization can degrade quality, especially for edge cases
**How to avoid:** Always benchmark quantized model against full-precision baseline; compare WER not just "does it produce text"
**Warning signs:** More hallucinations, repeated phrases, or garbled text in quantized output
</common_pitfalls>

<code_examples>
## Code Examples

### Benchmark: faster-whisper with distil-large-v3 on CPU
```python
# Source: faster-whisper README + Context7 docs
import time
import psutil
from faster_whisper import WhisperModel

# Load model with INT8 quantization for CPU
model = WhisperModel("distil-large-v3", device="cpu", compute_type="int8")

# Track memory
process = psutil.Process()
mem_before = process.memory_info().rss / 1024 / 1024  # MB

start = time.time()
segments, info = model.transcribe("test_audio.wav", beam_size=5)
segments = list(segments)  # Force evaluation (segments are lazy)
elapsed = time.time() - start

mem_after = process.memory_info().rss / 1024 / 1024
audio_duration = info.duration  # seconds

print(f"Language: {info.language} (prob: {info.language_probability:.2f})")
print(f"Transcription time: {elapsed:.1f}s for {audio_duration:.1f}s audio")
print(f"Real-time factor: {elapsed / audio_duration:.2f}x")
print(f"Memory: {mem_before:.0f}MB → {mem_after:.0f}MB (peak delta: {mem_after - mem_before:.0f}MB)")

for seg in segments:
    print(f"[{seg.start:.2f}s → {seg.end:.2f}s] {seg.text}")
```

### Benchmark: diarize library
```python
# Source: github.com/FoxNoseTech/diarize README
import time
from diarize import diarize

start = time.time()
result = diarize("test_audio.wav")
elapsed = time.time() - start

print(f"Found {result.num_speakers} speakers in {elapsed:.1f}s")
for seg in result.segments:
    print(f"[{seg.start:.1f}s - {seg.end:.1f}s] Speaker {seg.speaker}")

# Export for comparison with reference RTTM
result.to_rttm("output.rttm")
```

### Benchmark: whisper.cpp CLI
```bash
# Source: whisper.cpp README
# Download model
whisper-cpp-download-ggml-model large-v3-turbo

# Benchmark transcription
time whisper-cpp \
  --model ggml-large-v3-turbo.bin \
  --file test_audio.wav \
  --output-txt \
  --threads 8
```
</code_examples>

<sota_updates>
## State of the Art (2025-2026)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| pyannote 3.0 | pyannote 4.0 (community-1) | 2025 | New open-source community model, but still GPU-heavy |
| pyannote only | `diarize` library | 2026 | 7x faster on CPU, comparable DER, Apache 2.0 |
| Whisper large-v2 | distil-large-v3 via faster-whisper | 2024 | 6x faster, 49% smaller, within 1% WER |
| OpenAI whisper | faster-whisper + CTranslate2 | 2023+ | 4x faster same accuracy, INT8 quantization |
| No all-in-one option | Voxtral (transcription + understanding) | 2025-2026 | Promising but requires GPU; not viable for CPU-only 16GB |

**New tools/patterns to consider:**
- **Voxtral Mini 3B (July 2025):** Newer, smaller variant — check if CPU-viable with GGUF quantization
- **diarize library:** Brand new (2026), purpose-built for CPU diarization
- **whisper.cpp CoreML:** 3x speedup on Apple Silicon via ANE (Neural Engine)
- **Canary Qwen 2.5B:** Lowest WER (5.63%) in 2026 benchmarks, but untested for CPU deployment

**Deprecated/outdated:**
- **cannon.js OpenAI whisper:** Use faster-whisper instead (4x faster)
- **pyannote on CPU without alternatives:** diarize library is now the CPU-first option
- **Voxtral Small 24B for local use:** Requires ~55GB VRAM, not viable for local deployment
</sota_updates>

<open_questions>
## Open Questions

1. **diarize library maturity**
   - What we know: ~10.8% DER on VoxConverse, 8x faster than realtime on CPU, Apache 2.0
   - What's unclear: How it handles wargame-specific audio (radio chatter, overlapping speakers, varying audio quality). Library is very new (2026) — production stability unknown
   - Recommendation: Include in benchmark but verify on real wargame audio; have pyannote as fallback

2. **faster-whisper distil-large-v3 CPU real-time factor on HP EliteBook**
   - What we know: 6x faster than large-v3, INT8 quantization available, compatible with faster-whisper
   - What's unclear: Exact RTF on the specific HP EliteBook hardware (16GB RAM, Intel CPU)
   - Recommendation: Benchmark directly — this is the primary purpose of Phase 8

3. **whisper.cpp CoreML acceleration on macOS**
   - What we know: 3x speedup via Apple Neural Engine on Apple Silicon
   - What's unclear: Whether HP EliteBook has Apple Silicon or Intel (PROJECT.md says macOS but doesn't specify chip)
   - Recommendation: Check hardware; if Intel, CoreML/ANE not available — stick with faster-whisper

4. **diarize + faster-whisper alignment/merging**
   - What we know: Both produce timed segments independently
   - What's unclear: Best approach to merge speaker labels with transcript segments when using separate models
   - Recommendation: WhisperX's alignment approach is proven — may need to replicate or keep WhisperX for alignment even if swapping diarization model

5. **Voxtral Mini 4B CPU viability with GGUF quantization**
   - What we know: GGUF Q4 is ~2.5GB, voxtral.c exists for pure C inference, Q4 decode 4.2x faster than BF16
   - What's unclear: Actual CPU real-time factor on HP EliteBook; whether it's even close to usable
   - Recommendation: Low-priority test — interesting data point but unlikely to be competitive with faster-whisper on CPU
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- [faster-whisper GitHub](https://github.com/SYSTRAN/faster-whisper) — CPU setup, INT8 quantization, distil-whisper compatibility
- [diarize GitHub](https://github.com/FoxNoseTech/diarize) — CPU diarization library, benchmarks, API
- [Voxtral Transcribe 2 announcement](https://mistral.ai/news/voxtral-transcribe-2) — Model capabilities, diarization availability
- [Voxtral Mini 4B HuggingFace](https://huggingface.co/mistralai/Voxtral-Mini-4B-Realtime-2602) — Architecture, memory requirements, no diarization
- [voxtral.c GitHub](https://github.com/antirez/voxtral.c) — CPU inference benchmarks, memory requirements
- Context7: /systran/faster-whisper — API docs, model initialization, quantization options

### Secondary (MEDIUM confidence)
- [Northflank STT Benchmark 2026](https://northflank.com/blog/best-open-source-speech-to-text-stt-model-in-2026-benchmarks) — Cross-model WER comparisons
- [diarize Medium article](https://alexander-lukashov.medium.com/i-built-a-speaker-diarization-library-thats-7x-faster-than-pyannote-on-cpu-here-s-how-a0ca007ff33c) — Architecture details, benchmark methodology
- [Picovoice Falcon diarization](https://picovoice.ai/blog/speaker-diarization/) — Falcon benchmarks (proprietary, for comparison)
- [PyAnnote vs NeMo comparison](https://lajavaness.medium.com/comparing-state-of-the-art-speaker-diarization-frameworks-pyannote-vs-nemo-31a191c6300) — NeMo performance data

### Tertiary (LOW confidence - needs validation)
- Voxtral Mini CPU inference speed extrapolations — voxtral.c benchmarks are on M3 Max, HP EliteBook will differ significantly
- diarize library stability claims — library is very new, limited production reports
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: Speech-to-text (Whisper variants) + speaker diarization
- Ecosystem: faster-whisper, whisper.cpp, Voxtral, diarize, pyannote, NeMo
- Patterns: Separate transcription + diarization, integrated pipeline
- Pitfalls: Memory spikes, CPU performance expectations, alignment

**Confidence breakdown:**
- Standard stack: HIGH — verified with Context7, GitHub repos, official docs
- Architecture: HIGH — existing WhisperX pattern is proven baseline
- Pitfalls: HIGH — documented across multiple sources
- Code examples: HIGH — from official repos and Context7
- Voxtral viability: HIGH — confirmed NOT viable for CPU-only 16GB (too large/slow)
- diarize library: MEDIUM — promising but very new, needs real-world validation

**Research date:** 2026-04-13
**Valid until:** 2026-05-13 (30 days — speech model ecosystem moving fast)
</metadata>

---

*Phase: 08-model-research*
*Research completed: 2026-04-13*
*Ready for planning: yes*

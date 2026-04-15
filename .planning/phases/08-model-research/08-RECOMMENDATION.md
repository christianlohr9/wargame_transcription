# Phase 8: Model Research — Recommendations

**Date:** 2026-04-13
**Hardware:** HP EliteBook, 16GB RAM (36GB virtual), CPU-only
**Baseline:** WhisperX (small model, int8) + pyannote 3.1
**Test audio:** pyannote_sample.wav (30s, multi-speaker telephone conversation)

## Executive Summary

We recommend **faster-whisper distil-large-v3 (int8)** for transcription and **pyannote 3.1 (via WhisperX)** for diarization. This combination replaces the WhisperX small baseline with a higher-quality transcription model while keeping the proven diarization pipeline intact. The architecture shifts from a fully-unified WhisperX pipeline to a hybrid approach: separate transcription (faster-whisper) + existing diarization (pyannote), joined by WhisperX's alignment and speaker-assignment steps.

## Transcription Recommendation

**Winner:** faster-whisper-distil-large-v3-int8
**Why:** 525MB model footprint (vs 1244MB baseline), 1s cold start (vs 4s), proper punctuation output, and stable RTF with near-zero variance. The 0.10 RTF penalty over baseline is acceptable given the quality and memory gains.

| Candidate | RTF | RTF-std | Peak RSS (MB) | Model Mem (MB) | Load (s) | WER | Verdict |
|-----------|-----|---------|---------------|----------------|----------|-----|---------|
| whisperx-small-int8 (baseline) | 0.20 | 0.05 | 1948.5 | 1243.5 | 4.07 | N/A | Fastest RTF but high variance, no punctuation, large footprint |
| **faster-whisper-distil-large-v3-int8** | **0.30** | **0.00** | **2557.0** | **525.5** | **1.06** | **N/A** | **Winner: smallest model, fastest load, proper punctuation, stable** |
| faster-whisper-large-v3-turbo-int8 | 0.45 | 0.00 | 3003.9 | 1453.5 | 1.18 | N/A | Largest footprint, slowest RTF, no clear quality advantage |

**Decision:** Use faster-whisper distil-large-v3 (int8) for Phase 9 integration. It offers the best balance of speed, memory, and output quality.

### Key observations
- distil-large-v3 produces properly punctuated, capitalized output ("Hello? Oh, hello? Oh, hello. I didn't know you were there.")
- Baseline (small) produces unpunctuated output on some segments
- large-v3-turbo produces entirely lowercase, unpunctuated output ("hello hello oh hello i didn't know you were there")
- RTF variance of 0.00 for both faster-whisper candidates indicates highly deterministic inference

## Diarization Recommendation

**Winner:** pyannote 3.1 (via WhisperX DiarizationPipeline)
**Why:** Detects 3 speakers consistently across all iterations, which matches the expected speaker count for the test audio (a telephone conversation between 2-3 people). The `diarize` library over-segments dramatically (8 speakers), making it unsuitable without significant tuning.

| Candidate | RTF | RTF-std | Peak RSS (MB) | Model Mem (MB) | Load (s) | Speakers | Verdict |
|-----------|-----|---------|---------------|----------------|----------|----------|---------|
| **pyannote-whisperx (baseline)** | **0.44** | **0.00** | **3621.9** | **503.5** | **3.90** | **3** | **Winner: accurate speaker count, stable, proven** |
| diarize-lib (silero+wespeaker) | 0.09 | 0.00 | 3100.8 | ~84* | 0.00** | 8 | 5x faster but detects 8 speakers on 3-speaker audio |

*diarize-lib memory could not be isolated because it ran after pyannote (shared PyTorch runtime). Its standalone footprint is approximately 84MB (25MB WeSpeaker ONNX model + Silero VAD + overhead).
**diarize-lib uses lazy loading; the 0.00s load time is misleading. First-run RTF was 0.97 (includes model download/load), subsequent runs were 0.08-0.09.

**Decision:** Retain pyannote 3.1 for Phase 9 integration. The `diarize` library is not ready for production use — its speaker count estimation (GMM BIC) significantly over-segments short audio. While it is 5x faster, accuracy is the primary requirement for wargame analysis where correct speaker attribution matters.

### Key observations
- pyannote detected 3 speakers consistently across all 3 iterations
- diarize-lib detected 8 speakers consistently across all 3 iterations (wrong)
- diarize-lib segments overlap temporally, suggesting clustering issues on this audio type
- pyannote's 0.44 RTF is acceptable for batch processing (Phase 3 baseline was 0.68 RTF)
- diarize-lib has no HuggingFace token requirement (uses WeSpeaker ONNX models directly)
- diarize-lib sklearn warnings (divide by zero in matmul) suggest numerical instability in its spectral clustering step

## Pipeline Architecture Recommendation

**Decision: Hybrid pipeline — separate transcription + existing diarization with WhisperX alignment**

The analysis reveals a clear tradeoff:
- **Unified WhisperX pipeline** (current): Simple, all-in-one, but locked to WhisperX's bundled small model for transcription
- **Fully separate pipeline** (faster-whisper + diarize): Maximum flexibility, but diarize is not production-ready
- **Hybrid approach** (recommended): Use faster-whisper for transcription, pyannote for diarization, WhisperX for alignment and speaker assignment

### Why hybrid wins

1. **Transcription quality**: faster-whisper distil-large-v3 significantly outperforms WhisperX's bundled small model (punctuation, capitalization, lower memory)
2. **Diarization accuracy**: pyannote is the only tested diarizer that produces correct speaker counts
3. **Pipeline simplicity**: WhisperX's `load_align_model()` and `assign_word_speakers()` functions handle the hard problem of merging transcription + diarization outputs — we keep those
4. **Minimal disruption**: The existing `whisperx_diarization_service.py` already uses this architecture; we just swap the transcription model

### Alignment/merging approach

The recommended pipeline flow:
```
audio --> faster-whisper (transcribe) --> segments with timestamps
audio --> pyannote (diarize) --> speaker segments
segments + speaker segments --> whisperx.align() + whisperx.assign_word_speakers() --> final output
```

This leverages WhisperX's wav2vec2-based alignment to produce word-level timestamps, then assigns speakers from pyannote's output. This is the same merge strategy currently used in production.

## Phase 9 Integration Guidance

### Models to install/configure
- **faster-whisper distil-large-v3**: Auto-downloads from HuggingFace on first use (~750MB download, 525MB runtime)
- **pyannote 3.1**: Already installed, requires HF_TOKEN for gated model access
- **wav2vec2 alignment model**: Already used by WhisperX, no changes needed

### What to change
1. Replace `whisperx.load_model("small", ...)` with `faster_whisper.WhisperModel("distil-large-v3", device="cpu", compute_type="int8")`
2. Adapt transcription call from WhisperX API to faster-whisper API (different return format)
3. Keep `DiarizationPipeline` and `assign_word_speakers` from WhisperX unchanged
4. Update `whisperx_diarization_service.py` accordingly

### What to remove
- No packages need to be removed; WhisperX is still needed for alignment and diarization
- The small model cache can be cleared after migration (~1.2GB disk savings)

### Key risks and mitigations
| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| faster-whisper segment format incompatible with WhisperX align | Medium | Write adapter to convert faster-whisper segments to WhisperX format |
| Combined memory (faster-whisper + pyannote) exceeds 16GB | Low | Benchmarked at ~3.6GB peak for both together; well within budget |
| PyTorch 2.6+ weights_only breakage | Known | Monkeypatch already in place (bench_transcription.py pattern) |
| distil-large-v3 quality degrades on wargame-specific audio | Low | Test with real wargame recordings in Phase 9 UAT |

### Estimated complexity
- **Effort:** 1-2 days
- **Files to modify:** Primarily `whisperx_diarization_service.py`, possibly `lifecycle.py` for model loading
- **Testing:** Run existing diarization API tests + new benchmark on wargame audio

## Raw Data

- Transcription benchmarks: `speaker-diarization-service/benchmarks/results/transcription_results.json`
- Diarization benchmarks: `speaker-diarization-service/benchmarks/results/diarization_results.json`
- Benchmark scripts: `speaker-diarization-service/benchmarks/bench_transcription.py`, `bench_diarization.py`
- Test audio: `speaker-diarization-service/benchmarks/test_audio/pyannote_sample.wav` (30s)

---
phase: 08-model-research
plan: 01
subsystem: diarization
tags: [faster-whisper, whisperx, benchmark, cpu, int8, transcription]

# Dependency graph
requires:
  - phase: 03-diarization-rewrite
    provides: WhisperX integrated pipeline with faster-whisper backend, int8 compute
provides:
  - Benchmark harness for model evaluation (WER, RTF, memory, load time)
  - Transcription benchmark results for 3 CPU candidates
  - Baseline performance numbers for WhisperX small vs faster-whisper variants
affects: [08-model-research plan 02, 09-model-integration]

# Tech tracking
tech-stack:
  added: [psutil, jiwer]
  patterns: [benchmark harness with run_benchmark() callable interface, JSON result aggregation]

key-files:
  created:
    - speaker-diarization-service/benchmarks/benchmark_harness.py
    - speaker-diarization-service/benchmarks/bench_transcription.py
    - speaker-diarization-service/benchmarks/results/transcription_results.json
    - speaker-diarization-service/benchmarks/README.md
  modified: []

key-decisions:
  - "Used pyannote sample audio (30s speech) — no reference text available for WER"
  - "Monkeypatched lightning_fabric for PyTorch 2.6+ weights_only compat with WhisperX"
  - "distil-large-v3 emerged as best candidate: smallest model footprint (525MB), 1s load, acceptable RTF 0.30"

patterns-established:
  - "Benchmark harness: run_benchmark(name, load_fn, transcribe_fn, audio_path) pattern"
  - "JSON results in benchmarks/results/ for cross-plan aggregation"

issues-created: []

# Metrics
duration: 25min
completed: 2026-04-13
---

# Phase 8, Plan 01: Transcription Benchmarks Summary

**Benchmark harness + 3 transcription candidates evaluated: distil-large-v3 leads with 525MB footprint and 0.30 RTF on CPU**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-04-13
- **Completed:** 2026-04-13
- **Tasks:** 2 (+ 1 checkpoint)
- **Files created:** 6

## Accomplishments
- Created reusable benchmark harness measuring WER, RTF, peak RSS, model load time
- Benchmarked 3 transcription candidates on CPU with standardized metrics
- Identified distil-large-v3 as leading candidate (smallest memory, fast load, good quality output)

## Benchmark Results

| Model | Load(s) | RTF | RTF-std | Peak RSS(MB) | Model Mem(MB) | WER |
|-------|---------|-----|---------|-------------|---------------|-----|
| whisperx-small-int8 (baseline) | 4.07 | 0.20 | 0.05 | 1948.5 | 1243.5 | N/A |
| faster-whisper-distil-large-v3-int8 | 1.06 | 0.30 | 0.00 | 2557.0 | 525.5 | N/A |
| faster-whisper-large-v3-turbo-int8 | 1.18 | 0.45 | 0.00 | 3003.9 | 1453.5 | N/A |

**Key findings:**
- Baseline (whisperx-small) fastest RTF but 4s load, high variance, 1.2GB model memory
- distil-large-v3: best memory efficiency (525MB), 1s load, proper punctuation/capitalization
- large-v3-turbo: slowest, most memory, lowercase output without punctuation
- All candidates well within 12GB memory budget

## Task Commits

Each task was committed atomically:

1. **Task 1: Create benchmark harness and test environment** - `a6e2155` (feat)
2. **Task 2: Run transcription benchmarks** - `325b580` (feat)

## Files Created/Modified
- `speaker-diarization-service/benchmarks/benchmark_harness.py` - Reusable harness with run_benchmark() interface
- `speaker-diarization-service/benchmarks/bench_transcription.py` - Transcription benchmark runner for 3 candidates
- `speaker-diarization-service/benchmarks/results/transcription_results.json` - Raw benchmark results
- `speaker-diarization-service/benchmarks/README.md` - Benchmark documentation
- `speaker-diarization-service/benchmarks/test_audio/pyannote_sample.wav` - 30s test audio
- `speaker-diarization-service/benchmarks/test_audio/librispeech_sample.wav` - 15s synthetic fallback

## Decisions Made
- Used pyannote sample audio (30s conversational speech) as benchmark input — no reference text available so WER is N/A for all candidates
- Monkeypatched `lightning_fabric.utilities.cloud_io._load` to work around PyTorch 2.6+ `weights_only=True` breaking WhisperX/pyannote model loading
- Voxtral deferred to later plan per plan spec (different model class, needs separate tooling)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] PyTorch 2.6+ weights_only compatibility**
- **Found during:** Task 2 (WhisperX baseline benchmark)
- **Issue:** PyTorch 2.6+ defaults to `weights_only=True` which breaks pyannote/omegaconf checkpoint loading used by WhisperX VAD
- **Fix:** Monkeypatched `lightning_fabric.utilities.cloud_io._load` in bench_transcription.py to use `weights_only=False`
- **Files modified:** speaker-diarization-service/benchmarks/bench_transcription.py
- **Verification:** WhisperX baseline benchmark completed successfully
- **Committed in:** 325b580

---

**Total deviations:** 1 auto-fixed (blocking), 0 deferred
**Impact on plan:** Fix required for WhisperX to run at all on current PyTorch. Production Dockerfile may need same workaround if upgrading PyTorch.

## Issues Encountered
- Could not download LibriSpeech sample for WER reference text — used pyannote sample without reference instead. WER comparison deferred to future plan with proper reference audio.

## Next Phase Readiness
- Benchmark harness ready for reuse in plan 02 (diarization benchmarks, Voxtral evaluation)
- distil-large-v3 identified as leading transcription candidate for Phase 9 integration
- Need reference audio with ground-truth text if WER comparison is desired

---
*Phase: 08-model-research*
*Completed: 2026-04-13*

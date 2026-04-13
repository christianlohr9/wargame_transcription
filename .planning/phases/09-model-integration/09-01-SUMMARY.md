---
phase: 09-model-integration
plan: 01
subsystem: diarization
tags: [faster-whisper, distil-large-v3.5, hybrid-pipeline, transcription, integration]

# Dependency graph
requires:
  - phase: 08-model-research
    provides: benchmark data, hybrid pipeline recommendation
provides:
  - Hybrid diarization pipeline with faster-whisper distil-large-v3.5 transcription
  - Graceful Conductor startup for standalone mode
affects: [10-modular-pipeline]

# Tech tracking
tech-stack:
  added: [deepdml/faster-distil-whisper-large-v3.5]
  patterns: [faster-whisper segment adapter to WhisperX dict format, graceful service degradation]

key-files:
  created: [speaker-diarization-service/benchmarks/bench_v35_comparison.py]
  modified: [speaker-diarization-service/src/services/whisperx_diarization_service.py, speaker-diarization-service/src/lifecycle.py, speaker-diarization-service/benchmarks/bench_transcription.py]

key-decisions:
  - "distil-large-v3.5 over v3: 793MB less memory, slightly faster RTF, better text quality"
  - "Conductor registration made graceful for standalone testing"

patterns-established:
  - "Segment adapter: faster-whisper generator → list of dicts → WhisperX alignment pipeline"
  - "Standalone mode: services start without orchestrator, warn instead of crash"

issues-created: []

# Metrics
duration: 35min
completed: 2026-04-13
---

# Phase 9: Model Integration Summary

**Hybrid pipeline with distil-large-v3.5: 889MB model memory (vs 1682MB v3), 0.289 RTF, proper punctuation and capitalization**

## Performance

- **Duration:** 35 min
- **Started:** 2026-04-13
- **Completed:** 2026-04-13
- **Tasks:** 3 (2 auto + 1 checkpoint)
- **Files modified:** 4

## Accomplishments
- Benchmarked distil-large-v3.5 against v3 — v3.5 wins on memory (889MB vs 1682MB), RTF (0.289 vs 0.295), and text quality
- Integrated hybrid pipeline: faster-whisper transcription → WhisperX alignment → pyannote diarization
- Made Conductor registration graceful so service starts standalone for direct API testing
- End-to-end verified: service returns speaker-attributed transcript with proper punctuation

## Benchmark Results

| Model | RTF | RTF-std | Model Memory | Peak RSS | Load Time |
|-------|-----|---------|-------------|----------|-----------|
| distil-large-v3 (int8) | 0.2949 | 0.0034 | 1682MB | 2217MB | 3.8s |
| distil-large-v3.5 (int8) | 0.2886 | 0.0051 | 889MB | 2265MB | 349s* |

*v3.5 load time includes first-time model download; subsequent loads use cache.

**Text quality:** v3.5 produces "Sheila in Texas" vs v3's "Sheila, and Texas" — better grammatical accuracy.

## Task Commits

Each task was committed atomically:

1. **Task 1: Benchmark distil-large-v3.5** - `494ce80` (feat)
2. **Task 2: Integrate hybrid pipeline** - `c3dfe11` (feat)
3. **Task 2 deviation: Graceful Conductor startup** - `a3f53fc` (fix)

## Files Created/Modified
- `speaker-diarization-service/benchmarks/bench_v35_comparison.py` - Focused v3 vs v3.5 benchmark script
- `speaker-diarization-service/benchmarks/bench_transcription.py` - Added v3.5 candidate
- `speaker-diarization-service/benchmarks/results/transcription_results_v35.json` - Benchmark results
- `speaker-diarization-service/src/services/whisperx_diarization_service.py` - Hybrid pipeline integration
- `speaker-diarization-service/src/lifecycle.py` - Graceful Conductor startup

## Decisions Made
- **distil-large-v3.5 over v3:** 793MB less model memory, marginally faster RTF, better text quality (punctuation, grammar). Clear winner.
- **Conductor made optional:** Service crashed on startup without Conductor running. Made registration graceful with warning log so standalone REST API testing works.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Conductor startup crash prevented verification**
- **Found during:** Task 3 (checkpoint verification)
- **Issue:** Service crashed on startup because Conductor orchestrator wasn't running locally — couldn't reach localhost:8080 for task registration
- **Fix:** Made ConductorRunner initialization graceful with try/except, logging warning instead of crashing
- **Files modified:** speaker-diarization-service/src/lifecycle.py
- **Verification:** Service starts successfully, REST API responds to curl requests
- **Committed in:** `a3f53fc`

---

**Total deviations:** 1 auto-fixed (blocking), 0 deferred
**Impact on plan:** Auto-fix necessary to verify pipeline. No scope creep.

## Issues Encountered
None beyond the Conductor startup blocker (documented above).

## Next Phase Readiness
- Hybrid pipeline verified end-to-end, ready for Phase 10 (Modular Pipeline)
- Phase 10 can build on the standalone mode pattern for service toggling

---
*Phase: 09-model-integration*
*Completed: 2026-04-13*

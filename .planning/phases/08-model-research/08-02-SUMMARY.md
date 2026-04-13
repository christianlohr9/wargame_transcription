---
phase: 08-model-research
plan: 02
subsystem: diarization
tags: [pyannote, diarize, whisperx, benchmark, cpu, diarization, recommendation]

# Dependency graph
requires:
  - phase: 08-model-research
    provides: Transcription benchmark results (Plan 01), benchmark harness, test audio
  - phase: 03-diarization-rewrite
    provides: WhisperX integrated pipeline with pyannote diarization baseline
provides:
  - Diarization benchmark results for 2 CPU candidates
  - Model recommendation report (08-RECOMMENDATION.md) with clear winners
  - Pipeline architecture recommendation for Phase 9
affects: [09-model-integration]

# Tech tracking
tech-stack:
  added: [diarize]
  patterns: [diarization benchmark adapted from transcription harness pattern]

key-files:
  created:
    - speaker-diarization-service/benchmarks/bench_diarization.py
    - speaker-diarization-service/benchmarks/results/diarization_results.json
    - .planning/phases/08-model-research/08-RECOMMENDATION.md
  modified: []

key-decisions:
  - "pyannote retained for diarization — diarize library over-segments (8 speakers on 3-speaker audio)"
  - "distil-large-v3 recommended for transcription (525MB, 1s load, proper punctuation)"
  - "Hybrid pipeline: faster-whisper transcription + pyannote diarization + WhisperX alignment"

patterns-established:
  - "Diarization benchmark: measure RTF, peak RSS, load time, speaker count consistency"
  - "Recommendation report: data-backed decisions with raw benchmark references"

issues-created: []

# Metrics
duration: 8min
completed: 2026-04-13
---

# Phase 8, Plan 02: Diarization Benchmarks & Recommendations Summary

**Diarize library 5x faster but over-segments badly; pyannote retained — hybrid pipeline recommended with distil-large-v3 for transcription**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-04-13
- **Completed:** 2026-04-13
- **Tasks:** 2 (+ 1 checkpoint)
- **Files created:** 3

## Accomplishments
- Benchmarked 2 diarization candidates (pyannote via WhisperX vs diarize library) on CPU
- Discovered diarize library over-segments dramatically (8 speakers on 3-speaker audio)
- Produced comprehensive recommendation report synthesizing all Phase 8 benchmark data
- Clear Phase 9 integration path: swap transcription model, keep diarization stack

## Benchmark Results — Diarization

| Candidate | RTF | Peak RSS (MB) | Load (s) | Speakers | Verdict |
|-----------|-----|---------------|----------|----------|---------|
| pyannote-whisperx (baseline) | 0.44 | 3621.9 | 3.90 | 3 (correct) | Winner — accurate, stable |
| diarize-lib (silero+wespeaker) | 0.09 | 3100.8 | 0.00* | 8 (wrong) | 5x faster but unusable accuracy |

*diarize-lib uses lazy loading; first run includes model download.

**Key findings:**
- pyannote detected 3 speakers consistently across all 3 iterations
- diarize-lib detected 8 speakers consistently — spectral clustering produces sklearn numerical warnings
- diarize-lib segments overlap temporally, suggesting clustering instability on short/telephone audio
- pyannote's 0.44 RTF is an improvement over Phase 3 baseline (0.68 RTF)

## Task Commits

Each task was committed atomically:

1. **Task 1: Run diarization benchmarks** - `298012c` (feat) [speaker-diarization-service repo]
2. **Task 2: Write recommendation report** - `5658846` (docs) [main repo]

## Files Created/Modified
- `speaker-diarization-service/benchmarks/bench_diarization.py` - Diarization benchmark runner for 2 candidates
- `speaker-diarization-service/benchmarks/results/diarization_results.json` - Raw benchmark results
- `.planning/phases/08-model-research/08-RECOMMENDATION.md` - Full recommendation report with Phase 9 guidance

## Decisions Made
- **pyannote retained:** Only candidate with correct speaker count detection; diarize library not production-ready
- **Hybrid pipeline recommended:** faster-whisper for transcription + pyannote for diarization + WhisperX for alignment/speaker-assignment
- **distil-large-v3 confirmed:** Combined with Plan 01 data, the transcription winner is clear (525MB, proper punctuation, stable RTF)

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
- diarize library's spectral clustering produces sklearn divide-by-zero warnings and over-segments on telephone audio. This is a library limitation, not a configuration error — documented in recommendation report.

## Next Phase Readiness
- Phase 8: Model Research is **COMPLETE**
- 08-RECOMMENDATION.md provides clear Phase 9 integration guidance
- Key change: swap `whisperx.load_model("small")` → `WhisperModel("distil-large-v3")` in diarization service
- pyannote + WhisperX alignment layer stays unchanged
- Ready for Phase 9: Model Integration

---
*Phase: 08-model-research*
*Completed: 2026-04-13*

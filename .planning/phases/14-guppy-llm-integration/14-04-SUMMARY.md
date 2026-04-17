---
phase: 14-guppy-llm-integration
plan: 04
subsystem: infra
tags: [llama-cpp-python, gguf, smollm3, conda-pack, huggingface-hub]

# Dependency graph
requires:
  - phase: 13-one-click-services
    provides: conda-pack build pipeline, bundle-models.sh pattern
provides:
  - bundle-llm-model.sh script for SmolLM3-3B GGUF download
  - llama-cpp-python in portable Python runtime
  - Post-pack verification for native extension relocation
affects: [14-05 end-to-end wiring]

# Tech tracking
tech-stack:
  added: [llama-cpp-python]
  patterns: [CPU-only native extension build with CMAKE_ARGS, post-pack import verification]

key-files:
  created: [blackbox-desktop/scripts/bundle-llm-model.sh, blackbox-desktop/scripts/bundle-llm-model.md]
  modified: [blackbox-desktop/scripts/build-python-runtime.sh, blackbox-desktop/scripts/build-python-runtime.md]

key-decisions:
  - "Use hf_hub_download for single GGUF file instead of snapshot_download"
  - "Store LLM model in resources/models/llm/ subdirectory (separate from whisper/huggingface)"
  - "Post-pack verification warns but doesn't fail build — fallback to llama-server documented"

issues-created: []

# Metrics
duration: 2min
completed: 2026-04-17
---

# Phase 14 Plan 04: LLM Model Bundling & Runtime Build Summary

**SmolLM3-3B Q4_K_M GGUF download script and llama-cpp-python added to conda-pack portable Python runtime with CPU-only build flags**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-17T13:47:59Z
- **Completed:** 2026-04-17T13:49:49Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Created idempotent bundle-llm-model.sh following existing bundle-models.sh pattern
- Added llama-cpp-python with CPU-only CMAKE_ARGS to build-python-runtime.sh
- Added post-pack verification step to catch native extension relocation failures
- Documented fallback options (llama-server binary, llamafile) if conda-pack doesn't relocate correctly

## Task Commits

Each task was committed atomically:

1. **Task 1: Create bundle-llm-model.sh** - `3701937` (feat)
2. **Task 2: Update build-python-runtime.sh** - `2357b2f` (feat)

## Files Created/Modified
- `blackbox-desktop/scripts/bundle-llm-model.sh` - Downloads SmolLM3-3B Q4_K_M GGUF from HuggingFace
- `blackbox-desktop/scripts/bundle-llm-model.md` - Documentation for LLM model bundling
- `blackbox-desktop/scripts/build-python-runtime.sh` - Added llama-cpp-python install + post-pack verification
- `blackbox-desktop/scripts/build-python-runtime.md` - Updated with C++ compiler prereq, fallback docs, size estimates

## Decisions Made
- Used `hf_hub_download` for single file download (more efficient than `snapshot_download` for a single GGUF)
- Stored LLM model in `resources/models/llm/` subdirectory to keep it separate from whisper and pyannote models
- Post-pack verification is a warning, not a hard failure — documented fallback to bundling llama-server binary if native extension doesn't survive conda-pack relocation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## Next Phase Readiness
- Model download script ready for use on build machine
- llama-cpp-python included in runtime build pipeline
- Ready for 14-05-PLAN.md (end-to-end wiring / final integration)

---
*Phase: 14-guppy-llm-integration*
*Completed: 2026-04-17*

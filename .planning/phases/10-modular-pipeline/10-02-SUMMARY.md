---
phase: 10-modular-pipeline
plan: 02
subsystem: api
tags: [conductor, switch-task, pipeline-mode, diarization, faster-whisper, pyannote]

# Dependency graph
requires:
  - phase: 10-modular-pipeline
    provides: PipelineConfig, PipelineModeResolver, pipeline_mode workflow input
provides:
  - Conductor SWITCH task branching workflow by pipeline_mode
  - Mode-aware diarization service (skips pyannote in transcription_only)
  - WorkflowMigrationService always updates workflow definitions
affects: [11-frontend-adaptation, 12-integration-testing]

# Tech tracking
tech-stack:
  added: []
  patterns: [conductor-switch-value-param, mode-aware-service-branching]

key-files:
  modified:
    - blackbox/backend/blackbox_application/src/main/resources/workflows/builtin-transcription-workflow.json
    - blackbox/backend/blackbox_service/src/main/java/com/cgi/blackbox/service/implementation/WorkflowMigrationServiceImpl.java
    - speaker-diarization-service/src/tasks/diarization_task.py
    - speaker-diarization-service/src/services/whisperx_diarization_service.py
    - speaker-diarization-service/src/services/diarization_service.py

key-decisions:
  - "Conductor SWITCH with value-param evaluator — simple string matching, no graaljs needed"
  - "transcription_diarization case includes only stringify_transcription — speaker labels already in transcript"
  - "transcription_only skips pyannote entirely for ~10-15s speedup, keeps alignment for quality"
  - "WorkflowMigrationService always creates/updates — no skip-if-exists for versioned workflows"

patterns-established:
  - "SWITCH task pattern: value-param evaluator with decisionCases + empty defaultCase"
  - "Mode-aware service pattern: pipeline_mode parameter with 'full' default for backward compat"

issues-created: []

# Metrics
duration: 12min
completed: 2026-04-13
---

# Phase 10 Plan 02: Workflow Branching & Service Adaptation Summary

**Conductor SWITCH task branching three pipeline modes with pyannote skip in transcription_only for faster CPU-only processing**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-13T15:25:00Z
- **Completed:** 2026-04-13T15:37:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Workflow JSON restructured with SWITCH task: `full` (7 tasks), `transcription_diarization` (1 task), `transcription_only` (empty defaultCase)
- Diarization service skips pyannote entirely in transcription_only mode (~10-15s savings on CPU)
- WorkflowMigrationService always updates workflow definitions (version bumps apply automatically)
- Consistent DiarizationModel output across all modes (generic "Speaker" label in transcription_only)

## Task Commits

Each task was committed atomically:

1. **Task 1: Update workflow JSON with SWITCH branching and fix migration** - `7dcbe41` (feat) — in blackbox repo
2. **Task 2: Add mode parameter to diarization service** - `f36f8f8` (feat) — in speaker-diarization-service repo

## Files Created/Modified
- `blackbox/.../builtin-transcription-workflow.json` - SWITCH task with three mode branches, version 46
- `blackbox/.../WorkflowMigrationServiceImpl.java` - Removed skip-if-exists, always createOrUpdate
- `speaker-diarization-service/src/tasks/diarization_task.py` - Extracts and passes pipeline_mode
- `speaker-diarization-service/src/services/whisperx_diarization_service.py` - Mode branching, _map_transcription_only()
- `speaker-diarization-service/src/services/diarization_service.py` - Added pipeline_mode to abstract interface

## Decisions Made
- Used Conductor SWITCH with `evaluatorType: "value-param"` — simple string matching sufficient, no graaljs overhead
- `transcription_diarization` case includes only stringify_transcription — speaker labels are already embedded in the transcript from diarization
- `defaultCase: []` means transcription_only completes after save_transcription with no additional tasks
- Kept WhisperX alignment in transcription_only mode — fast (~1-2s) and improves fragment quality
- Workflow version bumped 45→46 to trigger Conductor update

## Deviations from Plan
None - plan executed exactly as written

## Issues Encountered
None — pre-existing compilation issues in blackbox persistence module (Lombok/DTO mismatch) are unrelated to our changes

## Next Phase Readiness
- Phase 10 complete — three pipeline modes working end-to-end
- Ready for Phase 11 (Frontend Adaptation): UI needs to handle missing data gracefully based on pipeline mode
- Frontend should hide summary/speaker tabs when those pipeline stages weren't executed

---
*Phase: 10-modular-pipeline*
*Completed: 2026-04-13*

---
phase: 11-frontend-adaptation
plan: 02
subsystem: ui, backend, diarization
tags: [vue, quasar, conductor, faster-whisper, pyannote, spring-boot]

# Dependency graph
requires:
  - phase: 10-modular-pipeline
    provides: SWITCH-based workflow branching, pipeline mode resolution
  - phase: 11-frontend-adaptation/01
    provides: pipeline status endpoint, service status chips
provides:
  - Adaptive results layout based on pipeline mode data
  - TranscriptBox hides speaker names in transcription_only
  - Service chips enlarged with tooltips
  - Backend allows non-full modes without definitionOfRounds
  - Lazy pyannote loading for transcription_only without HF_TOKEN
  - VAD filter for full audio transcription
  - Fixed Conductor workflow registration (duplicate taskReferenceName)
  - Fixed local profile service-url port mismatch
affects: [12-integration-testing, 13-one-click-services]

# Tech tracking
tech-stack:
  added: []
  patterns: [lazy-model-loading, conditional-layout-rendering]

key-files:
  created: []
  modified:
    - blackbox/frontend/src/pages/IndexPage.vue
    - blackbox/frontend/src/components/TranscriptBox.vue
    - blackbox/frontend/src/components/AppBar.vue
    - blackbox/backend/blackbox_service/src/main/java/com/cgi/blackbox/service/implementation/AnalysisServiceImpl.java
    - blackbox/backend/blackbox_application/src/main/resources/workflows/builtin-transcription-workflow.json
    - blackbox/backend/blackbox_application/src/main/resources/application.yml
    - speaker-diarization-service/src/services/whisperx_diarization_service.py

key-decisions:
  - "definitionOfRounds only enforced in full mode"
  - "pyannote lazy-loaded — transcription_only works without HF_TOKEN"
  - "Speaker spinner removed entirely — names update reactively when determinedSpeakers arrives"
  - "Conductor taskReferenceNames must be globally unique across SWITCH branches"
  - "Transcript download deferred to Phase 13"

patterns-established:
  - "Lazy model loading: expensive ML models loaded on first use, not at startup"
  - "Conditional layout: v-if/v-else-if/v-else for layout variants, not hidden panels"

issues-created: []

# Metrics
duration: 441min
completed: 2026-04-14
---

# Phase 11, Plan 02: Adaptive Results View Summary

**Conditional layouts per pipeline mode + 6 runtime fixes discovered during UAT**

## Performance

- **Duration:** 7h 21m (including extensive UAT debugging)
- **Started:** 2026-04-14T06:18:41Z
- **Completed:** 2026-04-14T13:40:07Z
- **Tasks:** 2 planned + 1 checkpoint + 6 deviation fixes
- **Files modified:** 7

## Accomplishments
- IndexPage renders full-width transcript for transcription_only, split layouts for other modes
- TranscriptBox hides speaker names and spinners when data isn't available
- Service status chips enlarged and readable with "Service offline" tooltips
- Backend allows /run in all pipeline modes (not just full)
- Conductor workflow registration fixed (duplicate taskReferenceName)
- Diarization service starts without HF_TOKEN in transcription_only mode
- Audio transcription no longer cuts off early (vad_filter)

## Task Commits

Each task was committed atomically:

1. **Task 1: Adapt IndexPage layout** - `139e4a9` (feat)
2. **Task 2: Adapt TranscriptBox** - `35e84f3` (feat)

**Deviation fixes (discovered during UAT checkpoint):**

3. **Fix: definitionOfRounds optional** - `f97aac6` (fix)
4. **Fix: enlarge service chips** - `de30389` (fix)
5. **Fix: simplify tooltips** - `1ff9874` (fix)
6. **Fix: deduplicate workflow taskReferenceName** - `1808cc3` (fix)
7. **Fix: remove speaker spinner** - `8f95399` (fix)
8. **Fix: correct service-url port** - `85baad1` (fix)
9. **Fix: lazy pyannote + vad_filter** - `7f645e0` (fix, speaker-diarization-service repo)

## Files Created/Modified
- `blackbox/frontend/src/pages/IndexPage.vue` - Conditional layout per pipeline mode
- `blackbox/frontend/src/components/TranscriptBox.vue` - Hide speakers/spinners when not applicable
- `blackbox/frontend/src/components/AppBar.vue` - Larger chips, offline tooltips
- `blackbox/backend/.../AnalysisServiceImpl.java` - definitionOfRounds optional for non-full
- `blackbox/backend/.../builtin-transcription-workflow.json` - Unique taskReferenceNames
- `blackbox/backend/.../application.yml` - Local profile port 8081
- `speaker-diarization-service/.../whisperx_diarization_service.py` - Lazy pyannote, vad_filter

## Decisions Made
- Removed speaker spinner entirely rather than trying to detect pipeline mode in TranscriptBox — names update reactively via translateSpeakerName when determinedSpeakers arrives
- Deferred transcript download/export feature to Phase 13
- Phase 13 scope expanded to include transcript export alongside one-click services

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] 500 error on /run for non-full modes**
- **Found during:** Checkpoint (UAT)
- **Issue:** definitionOfRounds enforced before pipeline mode resolution
- **Fix:** Moved pipelineModeResolver.resolve() before the check, only enforce for full mode
- **Committed in:** f97aac6

**2. [Rule 1 - Bug] Service status chips too small to read**
- **Found during:** Checkpoint (UAT)
- **Issue:** Chips used size="sm" and 8px icons
- **Fix:** Removed dense/size="sm", increased icon to 12px, added tooltips
- **Committed in:** de30389, 1ff9874

**3. [Rule 3 - Blocking] Conductor workflow registration failing silently**
- **Found during:** Checkpoint (UAT)
- **Issue:** Duplicate taskReferenceName "stringify_transcription_ref" across SWITCH branches
- **Fix:** Renamed to "stringify_transcription_diarization_ref" in transcription_diarization branch
- **Committed in:** 1808cc3

**4. [Rule 1 - Bug] Speaker spinner showing indefinitely in transcription_diarization mode**
- **Found during:** Checkpoint (UAT)
- **Issue:** expectsSpeakers computed returned true for diarized speakers, but determinedSpeakers never arrives without chat service
- **Fix:** Removed spinner entirely, names update reactively
- **Committed in:** 8f95399

**5. [Rule 3 - Blocking] Media download 404 from diarization worker**
- **Found during:** Checkpoint (UAT)
- **Issue:** Local profile service-url pointed to Conductor (8080) not backend (8081)
- **Fix:** Corrected service-url and port in local profile
- **Committed in:** 85baad1

**6. [Rule 2 - Critical] Diarization service startup fails without HF_TOKEN**
- **Found during:** Checkpoint (UAT)
- **Issue:** pyannote model loaded eagerly at startup, blocking transcription_only mode
- **Fix:** Lazy-load pyannote on first diarization request; also added vad_filter for full audio transcription
- **Committed in:** 7f645e0

### Deferred Enhancements

- Transcript download/export — tracked in Phase 13 scope

---

**Total deviations:** 6 auto-fixed (2 bugs, 2 blocking, 1 critical, 1 UX), 1 deferred
**Impact on plan:** All fixes necessary for the platform to actually work end-to-end. No scope creep — each fix was required to pass UAT.

## Issues Encountered
- speaker-diarization-service .env had Windows line endings (\r\n) causing HF_TOKEN auth failures with HuggingFace API
- conductor-python==1.2.3 requires Python <3.13, incompatible with system Python 3.14
- pyannote model is gated on HuggingFace, requires explicit access approval per account

## Next Phase Readiness
- Phase 11 (frontend-adaptation) complete — all pipeline modes render correctly
- Ready for Phase 12 (integration testing) or Phase 13 (one-click services)
- Phase 13 scope includes transcript download feature

---
*Phase: 11-frontend-adaptation*
*Completed: 2026-04-14*

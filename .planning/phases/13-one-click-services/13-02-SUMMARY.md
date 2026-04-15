---
phase: 13-one-click-services
plan: 02
subsystem: api
tags: [python, fastapi, conductor, rest, spring-boot, docker-compose]

# Dependency graph
requires:
  - phase: 13-01
    provides: PipelineOrchestrationService with HTTP calls to Python services
provides:
  - Conductor-free Python services (pure FastAPI REST)
  - pipeline_mode parameter on diarization REST endpoint
  - 4 infra services removed from docker-compose (Conductor, Redis, ES, RabbitMQ)
  - Configured HTTP timeouts for ML inference (600s diarization, 30s connect)
affects: [13-03, 13-05, 13-06]

# Tech tracking
tech-stack:
  added: []
  removed: [conductor-python]
  patterns: [standalone FastAPI REST services, RestTemplateBuilder timeout config]

key-files:
  modified:
    - speaker-diarization-service/src/lifecycle.py
    - speaker-diarization-service/src/main.py
    - speaker-diarization-service/src/api/diarization_api.py
    - speaker-diarization-service/requirements.txt
    - ask-chat-service/src/lifecycle.py
    - ask-chat-service/src/main.py
    - ask-chat-service/requirements.txt
    - blackbox/backend/blackbox_service/src/main/java/com/cgi/blackbox/service/implementation/PipelineOrchestrationService.java
    - blackbox/docker-compose.yml
  deleted:
    - speaker-diarization-service/src/tasks/ (directory)
    - ask-chat-service/src/tasks/ (directory)

key-decisions:
  - "Added pipeline_mode Form parameter to /transcriptions endpoint — Conductor task passed it but REST endpoint didn't"
  - "600s read timeout on RestTemplate for diarization — ML inference on long audio can take minutes"
  - "Removed esdata volume from docker-compose alongside Elasticsearch service"

patterns-established:
  - "Python services are standalone FastAPI apps — no external orchestration dependency"

issues-created: []

# Metrics
duration: ~10min
completed: 2026-04-15
---

# Phase 13: One-Click Services — Plan 02 Summary

**Removed conductor-python from both Python services, added pipeline_mode to REST endpoint, removed 4 Docker infra services**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-04-15
- **Completed:** 2026-04-15
- **Tasks:** 2
- **Files modified:** 9 modified, 4 deleted (2 dirs with 2 files each)

## Accomplishments
- Both Python services (speaker-diarization, ask-chat) are now pure FastAPI REST apps with zero Conductor dependency
- Diarization REST endpoint now accepts pipeline_mode parameter (was only available via Conductor task)
- Spring Boot PipelineOrchestrationService now passes pipeline_mode to diarization and has 600s timeout
- docker-compose.yml reduced from 7 services to 3 (mongodb, minio, tika)

## Task Commits

Each task was committed atomically (in sub-repos and parent):

1. **Task 1: Convert Python services from Conductor workers to REST-only**
   - Speaker diarization: `c5d93bf` (refactor)
   - Ask chat: `146dee5` (refactor)
   - Parent: `2b1f86f` (refactor)

2. **Task 2: Wire Spring Boot orchestration to call Python REST endpoints**
   - Blackbox: `bee8fa0` (feat)
   - Parent: `f32ae08` (feat)

**Plan metadata:** (pending)

## Files Created/Modified
- `speaker-diarization-service/src/lifecycle.py` - Simplified to no-op lifespan (removed ConductorRunner)
- `speaker-diarization-service/src/main.py` - Removed lifecycle import, plain FastAPI()
- `speaker-diarization-service/src/api/diarization_api.py` - Added pipeline_mode Form parameter
- `speaker-diarization-service/requirements.txt` - Removed conductor-python
- `speaker-diarization-service/.env.template` - Removed CONDUCTOR_URL
- `ask-chat-service/src/lifecycle.py` - Simplified to no-op lifespan
- `ask-chat-service/src/main.py` - Removed lifecycle import, plain FastAPI()
- `ask-chat-service/requirements.txt` - Removed conductor-python
- `ask-chat-service/.env.template` - Removed CONDUCTOR_URL
- `PipelineOrchestrationService.java` - Pass pipeline_mode, 600s timeout via RestTemplateBuilder
- `blackbox/docker-compose.yml` - Removed conductor-server, redis, elasticsearch, rabbitmq + esdata volume

## Files Deleted
- `speaker-diarization-service/src/tasks/` - DiarizationTask Conductor worker
- `ask-chat-service/src/tasks/` - AskChatTask Conductor worker

## Decisions Made
- Added pipeline_mode to diarization REST endpoint: the Conductor task passed pipeline_mode but the existing REST endpoint didn't accept it, which would have caused transcription_only/transcription_diarization modes to always run full diarization
- 600s read timeout via RestTemplateBuilder: replaces the default infinite timeout, appropriate for long-running ML inference on multi-hour audio files
- Cleaned .env.template files alongside source changes for consistency

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added pipeline_mode to diarization REST endpoint**
- **Found during:** Task 1 (diarization API review)
- **Issue:** Existing /transcriptions endpoint lacked pipeline_mode parameter. The Conductor task passed it, but the REST endpoint didn't. Without this, all modes would run full diarization.
- **Fix:** Added pipeline_mode as Form parameter with default "full", passed to diarization_service.diarize()
- **Verification:** Endpoint signature matches Conductor task's input contract
- **Committed in:** c5d93bf (Task 1 commit)

**2. [Rule 2 - Missing Critical] Cleaned .env.template files**
- **Found during:** Task 1 (post-removal grep verification)
- **Issue:** CONDUCTOR_URL remained in .env.template files after removing from source
- **Fix:** Removed CONDUCTOR_URL lines from both .env.template files
- **Verification:** grep -ri conductor returns no results in either service
- **Committed in:** c5d93bf, 146dee5 (Task 1 commits)

---

**Total deviations:** 2 auto-fixed (both missing critical), 0 deferred
**Impact on plan:** Both fixes necessary for correct functionality. No scope creep.

## Issues Encountered
None.

## Next Phase Readiness
- All Conductor references eliminated from entire codebase
- Both Python services run as standalone REST apps
- Spring Boot backend calls them directly via HTTP
- docker-compose.yml has 3 remaining services (mongodb, minio, tika) — to be replaced in Plan 03
- Ready for Plan 03: Replace MongoDB with H2 + filesystem, embed Tika

---
*Phase: 13-one-click-services*
*Completed: 2026-04-15*

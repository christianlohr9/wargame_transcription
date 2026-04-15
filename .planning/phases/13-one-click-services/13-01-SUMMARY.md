---
phase: 13-one-click-services
plan: 01
subsystem: api
tags: [spring-boot, conductor, orchestration, async, sse]

# Dependency graph
requires:
  - phase: 10-modular-pipeline
    provides: PipelineModeResolver, PipelineConfig, SWITCH branching logic
  - phase: 12-integration-testing
    provides: Validated pipeline modes, Docker-readiness analysis
provides:
  - PipelineOrchestrationService replacing Conductor workflow
  - Conductor-free Java backend (no Redis, ES, RabbitMQ, Conductor server needed)
  - Direct HTTP orchestration of Python services
affects: [13-02, 13-03, 13-05]

# Tech tracking
tech-stack:
  added: [@EnableAsync, Spring TaskExecutor]
  patterns: [direct service orchestration, HTTP retry with backoff, inline task logic]

key-files:
  created: [blackbox/backend/blackbox_service/src/main/java/com/cgi/blackbox/service/implementation/PipelineOrchestrationService.java]
  modified: [blackbox/backend/blackbox_service/src/main/java/com/cgi/blackbox/service/implementation/AnalysisServiceImpl.java, blackbox/backend/blackbox_application/src/main/java/com/cgi/blackbox/Application.java]

key-decisions:
  - "Direct Java if/else replaces Conductor SWITCH — no workflow engine needed"
  - "HTTP retry (3 retries, 2s backoff) replaces Conductor's transparent retry"
  - "Also removed AbstractTask, task DTOs, WorkflowMigrationService/Listener (plan didn't list but required for clean compile)"

patterns-established:
  - "Direct orchestration: PipelineOrchestrationService as central coordination point"
  - "@Async fire-and-forget: REST returns immediately, orchestration runs on TaskExecutor thread"

issues-created: []

# Metrics
duration: ~8min
completed: 2026-04-15
---

# Phase 13: One-Click Services — Plan 01 Summary

**Replaced Conductor workflow with PipelineOrchestrationService — eliminates 4 infrastructure dependencies (Redis, ES, RabbitMQ, Conductor server)**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-04-15
- **Completed:** 2026-04-15
- **Tasks:** 2
- **Files modified:** 3 created/modified, 20 deleted

## Accomplishments
- PipelineOrchestrationService with async fire-and-forget orchestration, pipeline mode branching, SSE broadcasting
- All 4 Java task workers inlined (SaveTranscription, SaveDeterminedSpeakers, SaveDeterminedRounds, ExecutePrompts)
- 2 inline JavaScript tasks reimplemented as Java methods (stringify transcription, combine with round definition)
- Complete Conductor removal: Maven dependency, config, env vars, 20 files deleted
- Build succeeds cleanly without Conductor

## Task Commits

Each task was committed atomically:

1. **Task 1: Create PipelineOrchestrationService** - `f4fdd2e` (feat)
2. **Task 2: Remove Conductor dependency and clean up** - `abb1e6c` (chore)

## Files Created/Modified
- `PipelineOrchestrationService.java` - Direct orchestration replacing Conductor workflow
- `AnalysisServiceImpl.java` - Now calls PipelineOrchestrationService instead of ConductorWorkflowClient
- `Application.java` - Added @EnableAsync annotation

## Files Deleted (20)
- `ConductorWorkerListener.java` - Task worker registration
- `WorkflowMigrationListener.java`, `WorkflowMigrationService.java`, `WorkflowMigrationServiceImpl.java` - Workflow JSON loading
- `ConductorWorkflowClient.java`, `ConductorWorkflowClientImpl.java` - Conductor client
- `AbstractTask.java` - Base task class
- `SaveTranscriptionTask.java`, `SaveDeterminedSpeakersTask.java`, `SaveDeterminedRoundsTask.java`, `ExecutePromptsTask.java` - Task workers
- 4 task DTO files
- `builtin-transcription-workflow.json` - Workflow definition

## Decisions Made
- Direct Java if/else replaces Conductor SWITCH — simple enough, no workflow engine needed
- HTTP retry logic (3 retries, 2s backoff) added to replace Conductor's transparent retry
- Also removed AbstractTask, task DTOs, WorkflowMigrationService/Listener not listed in plan but required for clean compilation

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed unlisted Conductor-dependent files**
- **Found during:** Task 2 (Conductor removal)
- **Issue:** WorkflowMigrationListener, WorkflowMigrationService interface, AbstractTask, and 4 task DTOs depended on Conductor but weren't listed in plan
- **Fix:** Deleted all files that depended on Conductor classes
- **Verification:** Build succeeds, no Conductor imports remain
- **Committed in:** abb1e6c (Task 2 commit)

**2. [Rule 3 - Blocking] Cleaned .env.template alongside .env**
- **Found during:** Task 2 (env cleanup)
- **Issue:** .env.template also contained BACKEND_CONDUCTOR_BASE_URL
- **Fix:** Removed from both .env and .env.template
- **Verification:** Grep confirms no remaining references
- **Committed in:** abb1e6c (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both blocking), 0 deferred
**Impact on plan:** Both auto-fixes necessary for clean compilation. No scope creep.

## Issues Encountered
- Conductor references remain in docker-compose.yml (conductor-server container) — this is Docker infrastructure, out of scope for this Java backend plan. Will be addressed in later plans.
- Commits were made in the nested `blackbox/` git repo (separate from parent `wargaming_local/` planning repo).

## Next Phase Readiness
- Backend is now Conductor-free and self-contained
- Ready for Plan 02: Convert Python services to REST-only (remove their Conductor dependency)
- docker-compose.yml still references conductor-server — needs cleanup in a later plan

---
*Phase: 13-one-click-services*
*Completed: 2026-04-15*

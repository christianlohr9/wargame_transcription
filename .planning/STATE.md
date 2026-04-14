# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-25)

**Core value:** Get all services running locally so the platform is usable end-to-end
**Current focus:** v2.0 Modular CPU-Only Platform — selective services, lighter models

## Current Position

Phase: 11 of 12 (frontend-adaptation) — IN PROGRESS
Plan: 01 complete (pipeline status endpoint & service status UI)
Status: Plan 11-01 complete, ready for Plan 11-02 (adaptive results view)
Last activity: 2026-04-14 — Pipeline status API + AppBar service status chips

Progress: ███████████████░░░░░ 92% (v2.0 Phase 11, Plan 01 complete)

## Performance Metrics

**Velocity (v1.0):**
- Total plans completed: 10
- Average duration: 33 min
- Total execution time: 5.4 hours

**By Phase (v1.0):**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-infrastructure | 2 | 11 min | 5.5 min |
| 02-backend-setup | 1 | 10 min | 10 min |
| 03-diarization-rewrite | 3 | 32 min | 10.7 min |
| 04-chat-service | 1 | 9 min | 9 min |
| 05-frontend-setup | 1 | 1 min | 1 min |
| 06-integration-testing | 1 | 165 min | 165 min |
| 07-diarization-service | 1 | 97 min | 97 min |

## Accumulated Context

### Decisions

All v1.0 decisions logged in PROJECT.md Key Decisions table with outcomes marked.

**v2.0 decisions:**
- [Phase 08, Plan 01]: distil-large-v3 identified as leading transcription candidate (525MB model, 0.30 RTF, proper punctuation)
- [Phase 08, Plan 01]: PyTorch 2.6+ requires weights_only monkeypatch for WhisperX/pyannote — may affect production Dockerfile
- [Phase 08, Plan 02]: pyannote retained for diarization — diarize library over-segments (8 speakers on 3-speaker audio)
- [Phase 08, Plan 02]: Hybrid pipeline recommended: faster-whisper transcription + pyannote diarization + WhisperX alignment
- [Phase 08, Plan 02]: Full recommendations in 08-RECOMMENDATION.md
- [Phase 09, Plan 01]: distil-large-v3.5 chosen over v3 — 889MB vs 1682MB memory, 0.289 vs 0.295 RTF, better text quality
- [Phase 09, Plan 01]: Conductor registration made graceful — services start standalone when orchestrator unavailable
- [Phase 10, Plan 01]: Health checks at trigger time, not startup — diarization loads ML models slowly
- [Phase 10, Plan 01]: Graceful degradation — requested mode downgrades if services unavailable
- [Phase 10, Plan 02]: Conductor SWITCH with value-param evaluator for pipeline mode branching
- [Phase 10, Plan 02]: transcription_only skips pyannote entirely (~10-15s CPU savings), keeps alignment
- [Phase 10, Plan 02]: WorkflowMigrationService always updates workflows — no skip-if-exists for versioned definitions, warns and proceeds
- [Phase 11, Plan 01]: getServiceHealth() added to PipelineModeResolver — centralized health check exposure for status endpoint
- [Phase 11, Plan 01]: Maven CLI requires JDK 21 (JAVA_HOME=/opt/homebrew/opt/openjdk@21/...) — JDK 25 breaks Lombok annotation processing

### Deferred Issues

None.

### Blockers/Concerns

None.

### Roadmap Evolution

- v1.0 shipped 2026-01-25: Full local wargame analysis platform, 7 phases
- v2.0 created 2026-04-13: Modular CPU-only platform, 5 phases (Phase 8-12) — selective services, model research (Voxtral etc.), lighter pipeline modes

## Session Continuity

Last session: 2026-04-14
Stopped at: Phase 11, Plan 01 complete — ready for Plan 11-02 (adaptive results view)
Resume file: .planning/phases/11-frontend-adaptation/11-01-SUMMARY.md

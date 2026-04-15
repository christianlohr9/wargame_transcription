# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-25)

**Core value:** Get all services running locally so the platform is usable end-to-end
**Current focus:** v2.0 Modular CPU-Only Platform — selective services, lighter models

## Current Position

Phase: 13 of 13 (one-click-services) — IN PROGRESS
Plan: 03 complete (H2 embedded DB + filesystem storage + embedded Tika)
Status: Plan 03 done, ready for Plan 04 (Frontend transcript export)
Last activity: 2026-04-15 — MongoDB replaced with H2, GridFS with filesystem, Tika embedded, docker-compose deleted

Progress: █████████████████░░░ 90% (v2.0 Phase 13: 3/7 plans complete)

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

**v2.0 decisions (Phase 13):**
- [Phase 13, Plan 01]: Direct Java if/else replaces Conductor SWITCH — no workflow engine library needed
- [Phase 13, Plan 01]: HTTP retry (3 retries, 2s backoff) replaces Conductor's transparent retry for Python service calls
- [Phase 13, Plan 02]: pipeline_mode added to /transcriptions REST endpoint — was only available via Conductor task
- [Phase 13, Plan 02]: 600s read timeout on RestTemplate for diarization ML inference
- [Phase 13, Plan 02]: docker-compose reduced from 7 to 3 services (mongodb, minio, tika remain)
- [Phase 13, Plan 03]: JSON CLOB columns via @Convert for nested DOs — simpler than @ElementCollection for 3+ nesting levels
- [Phase 13, Plan 03]: File-based H2 (jdbc:h2:file:./data/blackbox-db) for persistent data across restarts
- [Phase 13, Plan 03]: FileStorageService pattern: {base}/{subdir}/{id}/{filename} + metadata.json sidecar
- [Phase 13, Plan 03]: Package renamed persistance.mongodb -> persistance.jpa for clarity
- [Phase 13, Plan 03]: docker-compose.yml deleted — all 7 infrastructure services eliminated

**v2.0 decisions (Phase 12):**
- [Phase 12, Plan 01]: large-v3-turbo replaces distil-large-v3.5 — all distil-whisper models are English-only
- [Phase 12, Plan 01]: language="de" hardcoded in AnalysisServiceImpl — multilingual UI selector deferred
- [Phase 12, Plan 01]: Analytics panel requires speakerStats.length > 1, not determinedSpeakers — works without LLM
- [Phase 12, Plan 01]: Maven multi-module requires `mvn clean install` from root POM to rebuild dependency modules
- [Phase 12, Plan 02]: Full pipeline LLM validation deferred — Ollama server unavailable during testing
- [Phase 12, Plan 02]: Graceful degradation when Ollama unreachable is open question for Phase 13

**v2.0 decisions (Phases 8-11):**
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
- [Phase 11, Plan 02]: definitionOfRounds only required for full mode — non-full modes skip the check
- [Phase 11, Plan 02]: pyannote diarization pipeline lazy-loaded — allows transcription_only without HF_TOKEN
- [Phase 11, Plan 02]: vad_filter=True on faster-whisper to prevent early transcription cutoff
- [Phase 11, Plan 02]: Conductor SWITCH branches require globally unique taskReferenceNames — even across branches
- [Phase 11, Plan 02]: Local profile service-url must match actual server port (8081), not Conductor (8080)
- [Phase 11, Plan 02]: speaker-diarization-service .env had Windows line endings (\r\n) causing HF_TOKEN auth failures

### Deferred Issues

None.

### Blockers/Concerns

None.

### Roadmap Evolution

- v1.0 shipped 2026-01-25: Full local wargame analysis platform, 7 phases
- v2.0 created 2026-04-13: Modular CPU-only platform, 6 phases (Phase 8-13) — selective services, model research (Voxtral etc.), lighter pipeline modes
- Phase 13 added 2026-04-14: One-Click Services — containerize all app services in docker-compose, UI toggle for non-technical users

## Session Continuity

Last session: 2026-04-15
Stopped at: Phase 13, Plan 03 complete — ready for Plan 04
Resume file: .planning/phases/13-one-click-services/13-03-SUMMARY.md

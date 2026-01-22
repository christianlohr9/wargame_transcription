# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-22)

**Core value:** Get all services running locally so the platform is usable end-to-end: frontend talks to backend, backend orchestrates workflows, AI services process audio and chat — all without relying on cloud APIs.
**Current focus:** Phase 3 — Diarization Rewrite

## Current Position

Phase: 3 of 6 (Diarization Rewrite)
Plan: 3 of 3 in current phase
Status: Phase complete
Last activity: 2026-01-22 — Completed 03-03-PLAN.md

Progress: ██████░░░░ 60%

## Performance Metrics

**Velocity:**
- Total plans completed: 6
- Average duration: 9 min
- Total execution time: 0.88 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-infrastructure | 2 | 11 min | 5.5 min |
| 02-backend-setup | 1 | 10 min | 10 min |
| 03-diarization-rewrite | 3 | 32 min | 10.7 min |

**Recent Trend:**
- Last 5 plans: 02-01 (10 min), 03-01 (2 min), 03-02 (27 min), 03-03 (3 min)
- Trend: —

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Remote Ollama for chat (offloads RAM, allows larger models)
- WhisperX + pyannote for diarization (no API dependency, CPU-only acceptable)
- Batch diarization processing (CPU-only is slow, overnight jobs acceptable)
- Conductor UI on port 5001 (macOS AirPlay conflict on port 5000)
- Backend on port 8081 (avoid Conductor API conflict on 8080)
- Java 21 via Homebrew openjdk@21 (system Java not configured)
- Diarization service on port 8082 (avoid Conductor 8080, backend 8081)
- PyTorch weights_only patch via monkey-patch (PyTorch 2.6+ compat for pyannote)

### Deferred Issues

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-01-22T13:35:04Z
Stopped at: Completed 03-03-PLAN.md (Phase 3 complete)
Resume file: None

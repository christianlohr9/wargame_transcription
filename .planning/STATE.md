# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-22)

**Core value:** Get all services running locally so the platform is usable end-to-end: frontend talks to backend, backend orchestrates workflows, AI services process audio and chat — all without relying on cloud APIs.
**Current focus:** Phase 4 — Chat Service

## Current Position

Phase: 4 of 6 (Chat Service)
Plan: 1 of 1 in current phase
Status: Phase complete
Last activity: 2026-01-22 — Completed 04-01-PLAN.md

Progress: ███████░░░ 70%

## Performance Metrics

**Velocity:**
- Total plans completed: 7
- Average duration: 9 min
- Total execution time: 1.03 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-infrastructure | 2 | 11 min | 5.5 min |
| 02-backend-setup | 1 | 10 min | 10 min |
| 03-diarization-rewrite | 3 | 32 min | 10.7 min |
| 04-chat-service | 1 | 9 min | 9 min |

**Recent Trend:**
- Last 5 plans: 03-01 (2 min), 03-02 (27 min), 03-03 (3 min), 04-01 (9 min)
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
- Chat service on port 8083 (avoid Conductor 8080, backend 8081, diarization 8082)
- Remote Ollama: ollama.island.a-p.team:11434 with mistral:7b model
- Python 3.12 for chat service (required for 3.10+ union type syntax)

### Deferred Issues

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-01-22T13:54:21Z
Stopped at: Completed 04-01-PLAN.md (Phase 4 complete)
Resume file: None

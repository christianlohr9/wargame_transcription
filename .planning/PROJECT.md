# Blackbox AI Local Setup

## What This Is

Local development environment for the Blackbox AI wargaming platform — a fully local stack running all services on an HP EliteBook (16GB RAM) with remote Ollama for LLM inference. Processes wargame audio recordings to produce speaker-attributed transcripts with AI-generated analysis (speaker identification, round detection, summaries).

## Core Value

Get all services running locally so the platform is usable end-to-end: frontend talks to backend, backend orchestrates workflows, AI services process audio and chat — all without relying on cloud APIs.

## Requirements

### Validated

- ✓ Vue 3 + Quasar frontend — v1.0
- ✓ Spring Boot backend with MongoDB persistence — v1.0
- ✓ Speaker diarization service (WhisperX + pyannote) — v1.0
- ✓ Chat service with remote Ollama support — v1.0
- ✓ Netflix Conductor workflow orchestration — v1.0
- ✓ Docker Compose for infrastructure (7 services) — v1.0
- ✓ End-to-end workflow (upload → diarization → analysis) — v1.0

### Active

(None — v1.0 complete)

### Out of Scope

- Kubernetes deployment — focusing on local Docker/native setup
- Production configuration — this is for local development only
- CI/CD pipelines — already exist, not modifying
- Cloud API dependencies — replaced with local/self-hosted alternatives
- Real-time diarization performance — batch/overnight processing acceptable
- GPU acceleration — CPU-only is sufficient for demo purposes

## Context

Shipped v1.0 with full local stack running:
- **Infrastructure**: 7 Docker services (~2.4GB RAM)
- **Backend**: Spring Boot on port 8081 (~4,100 LOC Java)
- **AI Services**: Python FastAPI services (~236 LOC Python)
  - Diarization: WhisperX + pyannote on port 8082
  - Chat: Remote Ollama on port 8083
- **Frontend**: Vue 3 + Quasar on port 9003

Tech stack: Spring Boot, Vue 3, Quasar, FastAPI, WhisperX, pyannote, Ollama, MongoDB, Netflix Conductor, MinIO, RabbitMQ.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Remote Ollama for chat | Offloads RAM, allows larger models | ✓ Good |
| WhisperX + pyannote for diarization | No API dependency, CPU-only acceptable | ✓ Good |
| Docker for infrastructure only | Simpler debugging with native app services | ✓ Good |
| Batch diarization processing | CPU-only is slow, overnight jobs acceptable | ✓ Good |
| Conductor UI on port 5001 | macOS AirPlay conflict on port 5000 | ✓ Good |
| Backend on port 8081 | Avoid Conductor API conflict on 8080 | ✓ Good |
| Jackson ObjectMapper for INLINE tasks | JSON.stringify fails on Java Maps in Nashorn | ✓ Good |
| Python 3.12 for chat service | Required for 3.10+ union type syntax | ✓ Good |

## Constraints

- **Platform**: HP EliteBook, 16GB RAM (macOS)
- **Memory budget**: ~2.4GB for infrastructure + apps for OS
- **Ports**: 5001 (Conductor UI), 8080 (Conductor API), 8081 (backend), 8082 (diarization), 8083 (chat), 9003 (frontend)
- **Dependencies**: Docker Desktop required for infrastructure services
- **No external APIs**: All AI processing local or self-hosted (except remote Ollama)
- **Diarization**: CPU-based WhisperX + pyannote, ~0.68x realtime

---
*Last updated: 2026-01-25 after v1.0 milestone*

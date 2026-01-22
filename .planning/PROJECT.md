# Blackbox AI Local Setup

## What This Is

Local development environment setup for the Blackbox AI wargaming platform — a hackathon project that was originally deployed on Kubernetes. The goal is to run the full stack locally on an HP EliteBook (16GB RAM) without external API dependencies, using a remote Ollama server for LLM inference.

## Core Value

Get all services running locally so the platform is usable end-to-end: frontend talks to backend, backend orchestrates workflows, AI services process audio and chat — all without relying on cloud APIs.

## Requirements

### Validated

- ✓ Vue 3 + Quasar frontend — existing (`blackbox/frontend/`)
- ✓ Spring Boot backend with MongoDB persistence — existing (`blackbox/backend/`)
- ✓ Speaker diarization service — existing (`speaker-diarization-service/`), needs modification
- ✓ Chat service with Ollama/OpenAI support — existing (`ask-chat-service/`)
- ✓ Netflix Conductor workflow orchestration — existing (client code)
- ✓ Docker Compose for infrastructure — partial (`blackbox/docker-compose.yml`)

### Active

- [ ] Complete docker-compose with all infrastructure (Conductor, Tika)
- [ ] Replace AssemblyAI with WhisperX + pyannote in diarization service
- [ ] Configure chat service for remote Ollama server
- [ ] Fix frontend API URL to point to localhost
- [ ] Create .env files from templates with local values
- [ ] Configure port mappings to avoid conflicts
- [ ] Document local startup procedure
- [ ] Verify end-to-end workflow (upload audio → diarization → analysis)

### Out of Scope

- Kubernetes deployment — focusing on local Docker/native setup
- Production configuration — this is for local development only
- CI/CD pipelines — already exist, not modifying
- Cloud API dependencies — replacing with local/self-hosted alternatives
- Real-time diarization performance — batch/overnight processing acceptable

## Context

This is a hackathon project from a team that built a wargaming analysis platform. Key components:
- **Frontend**: Vue 3 + Quasar SPA for workspace management and analysis visualization
- **Backend**: Spring Boot Java service handling workspaces, wargame setups, and workflow orchestration
- **Microservices**: Two Python FastAPI services for AI capabilities (chat, diarization)
- **Infrastructure**: MongoDB, RabbitMQ, MinIO, Conductor, Tika

The team deployed on Kubernetes in a VM environment. User wants to run everything locally on HP EliteBook with 16GB RAM.

**Architecture:**
- **Local (HP EliteBook)**: All infrastructure, backend, frontend, AI services
- **Remote server**: Ollama for LLM inference (offloads ~4-8GB RAM requirement)

User has:
- Docker Desktop installed
- Remote server available for Ollama
- No external API keys needed

## Constraints

- **Platform**: HP EliteBook, 16GB RAM (Windows or Linux assumed)
- **Memory budget**: ~6-8GB for local services, remainder for OS
- **Ports**: Need to avoid conflicts between services (backend, conductor, tika, python services, frontend dev server)
- **Dependencies**: Docker Desktop required for infrastructure services
- **No external APIs**: All AI processing local or self-hosted
- **Diarization**: CPU-based WhisperX + pyannote, batch processing acceptable

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Remote Ollama for chat | Offloads RAM, allows larger models | — Pending |
| WhisperX + pyannote for diarization | No API dependency, CPU-only acceptable | — Pending |
| Docker for infrastructure only | Simpler debugging with native app services | — Pending |
| Keep frontend in dev mode | Hot reload for any needed tweaks | — Pending |
| Batch diarization processing | CPU-only is slow, overnight jobs acceptable | — Pending |

---
*Last updated: 2026-01-22 — scope revised for 16GB RAM, no external APIs*

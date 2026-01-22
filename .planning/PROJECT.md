# Blackbox AI Local Setup

## What This Is

Local development environment setup for the Blackbox AI wargaming platform — a hackathon project that was originally deployed on Kubernetes. The goal is to run the full stack locally on a MacBook for development and exploration.

## Core Value

Get all services running locally so the platform is usable end-to-end: frontend talks to backend, backend orchestrates workflows, AI services process audio and chat.

## Requirements

### Validated

- ✓ Vue 3 + Quasar frontend — existing (`blackbox/frontend/`)
- ✓ Spring Boot backend with MongoDB persistence — existing (`blackbox/backend/`)
- ✓ Speaker diarization service with AssemblyAI — existing (`speaker-diarization-service/`)
- ✓ Chat service with Ollama/OpenAI support — existing (`ask-chat-service/`)
- ✓ Netflix Conductor workflow orchestration — existing (client code)
- ✓ Docker Compose for infrastructure — partial (`blackbox/docker-compose.yml`)

### Active

- [ ] Complete docker-compose with all infrastructure (Conductor, Tika)
- [ ] Fix frontend API URL to point to localhost
- [ ] Create .env files from templates with local values
- [ ] Configure port mappings to avoid conflicts
- [ ] Document local startup procedure
- [ ] Verify end-to-end workflow (upload audio → diarization → analysis)

### Out of Scope

- Kubernetes deployment — focusing on local Docker/native setup
- Production configuration — this is for local development only
- CI/CD pipelines — already exist, not modifying
- New features — just getting existing code running

## Context

This is a hackathon project from a team that built a wargaming analysis platform. Key components:
- **Frontend**: Vue 3 + Quasar SPA for workspace management and analysis visualization
- **Backend**: Spring Boot Java service handling workspaces, wargame setups, and workflow orchestration
- **Microservices**: Two Python FastAPI services for AI capabilities (chat, diarization)
- **Infrastructure**: MongoDB, RabbitMQ, MinIO, Conductor, Tika

The team deployed on Kubernetes in a VM environment. User wants to run everything locally on MacBook.

User has:
- Docker Desktop installed
- AssemblyAI API key
- Wants to use Ollama for local LLM (no OpenAI key needed)

## Constraints

- **Platform**: macOS (MacBook)
- **Ports**: Need to avoid conflicts between services (backend, conductor, tika, python services, frontend dev server)
- **Dependencies**: Docker Desktop required for infrastructure services
- **Local LLM**: Using Ollama instead of Azure OpenAI

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use Ollama for chat | Free, runs locally, no API key needed | — Pending |
| Docker for infrastructure only | Simpler debugging with native app services | — Pending |
| Keep frontend in dev mode | Hot reload for any needed tweaks | — Pending |

---
*Last updated: 2026-01-22 after initialization*

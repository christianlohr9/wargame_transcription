# Blackbox AI Local Setup

## What This Is

Self-contained desktop application for wargame audio analysis — transcribes recordings, identifies speakers, detects rounds, and generates AI analysis reports. Runs entirely offline on a standard Windows laptop (16GB RAM) with no admin rights, no Docker, and no cloud dependencies. Packaged as a one-click NSIS installer with bundled Java, Python, and ML models.

## Core Value

One-click wargame analysis for non-technical users: install, open, upload audio, get results — no infrastructure setup, no terminal, no external services.

## Requirements

### Validated

- Vue 3 + Quasar frontend — v1.0
- Spring Boot backend with persistence — v1.0, evolved v2.0 (MongoDB → H2)
- Speaker diarization service (faster-whisper + pyannote) — v1.0, evolved v2.0
- Chat service with remote Ollama support — v1.0
- End-to-end workflow (upload → diarization → analysis) — v1.0
- CPU-optimized ML models (large-v3-turbo, pyannote) — v2.0
- Three pipeline modes with graceful degradation — v2.0
- Zero-infrastructure deployment (H2, filesystem, embedded Tika) — v2.0
- Adaptive UI with service status and conditional layouts — v2.0
- Transcript export (PDF, DOCX, TXT) — v2.0
- Electron desktop shell with process management — v2.0
- Portable runtime bundling (jlink JRE, conda-pack Python) — v2.0
- NSIS per-user installer for Windows — v2.0

### Active

(None — v2.0 complete)

### Out of Scope

- Kubernetes deployment — replaced with desktop app
- Cloud API dependencies — fully local/self-hosted
- GPU acceleration — CPU-only is sufficient
- Code signing — requires organization certificate
- Auto-update — out of scope for initial deployment
- Mobile app — desktop-first approach

## Context

Shipped v2.0 as self-contained Electron desktop app:
- **Backend**: Spring Boot with H2 + filesystem (no Docker infrastructure)
- **AI Services**: Python FastAPI services with portable conda-pack runtime
  - Diarization: faster-whisper large-v3-turbo + pyannote on port 8082
  - Chat: Remote Ollama on port 8083
- **Frontend**: Vue 3 + Quasar SPA served via Electron app:// protocol
- **Desktop**: Electron shell with ProcessManager, health polling, service toggles
- **Packaging**: electron-builder with NSIS per-user installer, jlink JRE, conda-pack Python

Tech stack: Spring Boot, H2, Vue 3, Quasar, Electron, FastAPI, faster-whisper, pyannote, Ollama, pdfmake, docx.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Remote Ollama for chat | Offloads RAM, allows larger models | Good |
| WhisperX → faster-whisper + pyannote | CPU-optimized, better accuracy | Good |
| Docker for infrastructure only | v1.0 approach, replaced in v2.0 | Superseded |
| Conductor → direct Spring Boot | Eliminates Conductor + 4 infra services | Good |
| MongoDB → H2 + filesystem | Zero-dependency persistence | Good |
| large-v3-turbo for German | distil-whisper models are English-only | Good |
| JSON CLOB columns via @Convert | Simpler than @ElementCollection for nesting | Good |
| Custom app:// protocol | file:// breaks absolute asset paths | Good |
| jlink + conda-pack | Portable runtimes, no system install needed | Good |
| NSIS per-user installer | No admin rights required | Good |
| @Lazy for circular dependency | AnalysisService only used in @Async method | Good |

## Constraints

- **Platform**: Windows HP EliteBook, 16GB RAM, no admin rights
- **Air-gapped**: Must work fully offline after installation
- **Ports**: 8081 (backend), 8082 (diarization), 8083 (chat)
- **No Docker**: Not available on restricted Windows machines
- **No external APIs**: All processing local (except optional remote Ollama)

---
*Last updated: 2026-04-15 after v2.0 milestone*

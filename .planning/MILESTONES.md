# Project Milestones: Blackbox AI Local Setup

## v2.0 Modular CPU-Only Platform (Shipped: 2026-04-15)

**Delivered:** Self-contained Electron desktop app with zero-infrastructure deployment — embedded H2 database, filesystem storage, portable JRE/Python runtimes, three pipeline modes with graceful degradation, and NSIS per-user installer for air-gapped Windows machines.

**Phases completed:** 8-13 (16 plans total)

**Key accomplishments:**
- Hybrid AI pipeline with CPU-optimized models (faster-whisper large-v3-turbo + pyannote diarization)
- Zero-infrastructure deployment — eliminated all 7 Docker services (Conductor, MongoDB, Redis, ES, RabbitMQ, MinIO, Tika)
- Modular pipeline with 3 runtime modes (transcription_only, transcription_diarization, full) and automatic detection
- Electron desktop shell with process supervisor, health-check polling, and service toggle UI
- Portable runtime bundling (jlink JRE, conda-pack Python, ML model download scripts)
- Transcript export (PDF, DOCX, TXT) with speaker name resolution

**Stats:**
- ~80 files created/modified
- 6 phases, 16 plans
- Timeline: 2026-01-22 → 2026-04-15

**Git range:** `162ffbc` → `e3128d8`

**What's next:** Deploy and test on target Windows machine. Plan v3.0 if needed.

---

## v1.0 Local Wargame Analysis (Shipped: 2026-01-25)

**Delivered:** Local running of a wargaming transcript service with remote usage of Ollama for LLM inference

**Phases completed:** 1-7 (10 plans total)

**Key accomplishments:**
- Docker Compose infrastructure with 7 services (MongoDB, RabbitMQ, MinIO, Elasticsearch, Redis, Conductor, Tika) running at ~2.4GB RAM
- Spring Boot backend configured for local environment with port mappings to avoid conflicts
- WhisperX + pyannote diarization replacing AssemblyAI — fully local, CPU-only at 0.68x realtime
- Remote Ollama chat service integration (mistral:7b) for speaker extraction, round detection, and summaries
- End-to-end workflow: audio upload → diarization → speaker names → round detection → summaries
- Fixed Conductor INLINE JavaScript task serialization using Jackson ObjectMapper for Java Maps

**Stats:**
- 26 files created/modified
- ~4,100 lines of Java + 236 lines of Python
- 7 phases, 10 plans
- 4 days from start to ship (5.4 hours execution time)

**Git range:** `cdd6a85` → `f021b32`

**What's next:** TBD — Platform ready for local wargame analysis

---

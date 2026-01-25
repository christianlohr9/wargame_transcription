# Roadmap: Blackbox AI Local Setup

## Overview

Transform the Kubernetes-deployed Blackbox AI wargaming platform into a fully local stack running on an HP EliteBook (16GB RAM) without external API dependencies. The major work is replacing AssemblyAI with WhisperX + pyannote for speaker diarization, and configuring chat to use a remote Ollama server.

## Domain Expertise

None

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Infrastructure** - Docker Compose for all infrastructure services (Complete)
- [x] **Phase 2: Backend Setup** - Configure Spring Boot for local environment (Complete)
- [x] **Phase 3: Diarization Rewrite** - Replace AssemblyAI with WhisperX + pyannote (Complete)
- [x] **Phase 4: Chat Service** - Configure for remote Ollama server (Complete)
- [x] **Phase 5: Frontend Setup** - Configure Vue/Quasar to point to localhost (Complete)
- [x] **Phase 6: Integration Testing** - Verify end-to-end workflow (Complete)

## Phase Details

### Phase 1: Infrastructure
**Goal**: Get all infrastructure services running via Docker Compose — MongoDB, RabbitMQ, MinIO, Netflix Conductor, Apache Tika
**Depends on**: Nothing (first phase)
**Research**: Likely (Netflix Conductor Docker setup)
**Research topics**: Conductor server Docker image, Elasticsearch requirements, Tika server configuration
**Plans**: TBD

Plans:
- [x] 01-01: Set up Docker Compose with all infrastructure services
- [x] 01-02: Verify services are accessible and healthy

### Phase 2: Backend Setup
**Goal**: Configure and run Spring Boot backend with local environment variables pointing to Docker services
**Depends on**: Phase 1
**Research**: Unlikely (existing Spring Boot app, just configuration)
**Plans**: 1

Plans:
- [x] 02-01: Create .env, build and run backend, verify connectivity

### Phase 3: Diarization Rewrite
**Goal**: Replace AssemblyAI API with WhisperX + pyannote for fully local speaker diarization (CPU-based, batch processing)
**Depends on**: Phase 1 (for testing with infrastructure)
**Research**: Likely (major code change)
**Research topics**: WhisperX API and model loading, pyannote.audio speaker diarization API, aligning transcription with speaker segments, output format matching existing DiarizationModel
**Plans**: TBD

Plans:
- [x] 03-01: Implement WhisperXDiarizationService class
- [x] 03-02: Service setup and verification with PyTorch 2.8 compat
- [x] 03-03: Test diarization with sample audio files

### Phase 4: Chat Service
**Goal**: Configure chat service to use remote Ollama server instead of local/Azure OpenAI
**Depends on**: Phase 1 (for testing with infrastructure)
**Research**: Unlikely (just configuration change)
**Plans**: TBD

Plans:
- [x] 04-01: Configure OLLAMA_BASE_URL for remote server and verify connectivity

### Phase 5: Frontend Setup
**Goal**: Configure Vue/Quasar frontend to point to localhost backend and run dev server
**Depends on**: Phase 2
**Research**: Unlikely (existing app, just config change)
**Plans**: TBD

Plans:
- [x] 05-01: Update API base URL and start dev server

### Phase 6: Integration Testing
**Goal**: Verify complete end-to-end workflow: upload audio → diarization → analysis → chat
**Depends on**: Phases 2, 3, 4, 5
**Research**: Unlikely (verification only)
**Plans**: TBD

Plans:
- [x] 06-01: Test complete workflow with sample wargame audio

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6
(Phases 3 and 4 can potentially run in parallel after Phase 1)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Infrastructure | 2/2 | Complete | 2026-01-22 |
| 2. Backend Setup | 1/1 | Complete | 2026-01-22 |
| 3. Diarization Rewrite | 3/3 | Complete | 2026-01-22 |
| 4. Chat Service | 1/1 | Complete | 2026-01-22 |
| 5. Frontend Setup | 1/1 | Complete | 2026-01-22 |
| 6. Integration Testing | 1/1 | Complete | 2026-01-25 |

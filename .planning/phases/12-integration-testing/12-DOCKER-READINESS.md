# Phase 12: Docker-Readiness Summary for Phase 13 (Containerization)

**Created:** 2026-04-15
**Source:** Phase 12 integration testing (Plans 01 and 02)

---

## 1. Service Inventory

| Service | Runtime | Internal Port | External Port (local) | Health Endpoint | Startup Order |
|---|---|---|---|---|---|
| **MongoDB** | mongo (Docker image) | 27017 | 27017 | `mongosh db.adminCommand('ping')` | 1 - infrastructure |
| **RabbitMQ** | rabbitmq:management | 5672, 15672 | 5672, 15672 | `rabbitmq-diagnostics -q ping` | 1 - infrastructure |
| **MinIO** | minio/minio | 9000, 9001 | 9000, 9001 | `GET /minio/health/live` | 1 - infrastructure |
| **Redis** | redis:7-alpine | 6379 | 6379 | `redis-cli ping` | 1 - infrastructure |
| **Elasticsearch** | elasticsearch:7.17.11 | 9200 | 9200 | `GET /_cluster/health` (green/yellow) | 1 - infrastructure |
| **Conductor** | conductoross/conductor-standalone:3.15.0 | 8080, 5000 | 8080, 5001 | `GET /health` | 2 - depends on ES + Redis |
| **Tika** | apache/tika:latest | 9998 | 9998 | `GET /tika` | 1 - infrastructure |
| **speaker-diarization-service** | Python 3.12 (FastAPI + uvicorn) | 8080 | 8082 (mapped) | `GET /health` | 3 - depends on Conductor |
| **ask-chat-service** | Python 3.12 (FastAPI + uvicorn) | 8080 | 8083 (mapped) | `GET /health` | 3 - depends on Conductor, Ollama |
| **blackbox backend** | JDK 21 (Spring Boot) | 8081 | 8081 | Spring Boot actuator or custom | 4 - depends on all above |
| **blackbox frontend** | Node.js (Quasar/Vue) | 9000 (dev) | 9000 | N/A (static SPA) | 5 - depends on backend |
| **Ollama** (external) | Remote at `ollama.island.a-p.team:11434` | 11434 | N/A | `GET /api/tags` | External - not containerized |

### Key notes on ports

- Both Python services (speaker-diarization-service and ask-chat-service) listen internally on **port 8080** in their Dockerfiles. In the current `docker-compose.yml`, these are not yet defined, but they must be mapped to **8082** and **8083** respectively to match what the backend expects.
- The backend runs on **8081** and its `server.service-url` must match (used for Conductor callback URLs).
- Conductor occupies port 8080 externally, which is why the Python services need different external mappings.

### Dependencies per service

- **blackbox backend**: MongoDB, Conductor, Tika, speaker-diarization-service (optional), ask-chat-service (optional)
- **speaker-diarization-service**: Conductor (worker registration), HF_TOKEN (for pyannote model download), Ollama (for LLM tasks in full mode)
- **ask-chat-service**: Conductor (worker registration), Ollama (for chat functionality)
- **Conductor**: Elasticsearch, Redis

---

## 2. Environment Configuration

### blackbox backend (`blackbox/.env`)

| Variable | Local Value | Docker Value | Notes |
|---|---|---|---|
| `SPRING_PROFILES_ACTIVE` | `local` | `docker` or custom profile | Profile controls MongoDB URL and service-url |
| `SERVER_PORT` | `8081` | `8081` | Keep consistent |
| `SERVER_SERVICE_URL` | `http://localhost:8081` | `http://blackbox-backend:8081` | Must match actual reachable address from Conductor |
| `BACKEND_TIKA_BASE_URL` | `http://localhost:9998` | `http://tika:9998` | Container name |
| `BACKEND_CONDUCTOR_BASE_URL` | `http://localhost:8080/api` | `http://conductor-server:8080/api` | Container name |
| `BACKEND_ASK_CHAT_BASE_URL` | `http://localhost:8083` | `http://ask-chat-service:8083` | Container name + mapped port |
| `BACKEND_DIARIZATION_BASE_URL` | `http://localhost:8082` | `http://speaker-diarization-service:8082` | Container name + mapped port |
| `PIPELINE_MODE` | `auto` | `auto` | No change needed |

### speaker-diarization-service (`speaker-diarization-service/.env`)

| Variable | Local Value | Docker Value | Notes |
|---|---|---|---|
| `HF_TOKEN` | `hf_usYOfZ...` | **Mount as secret** | Required for pyannote model download. Do NOT bake into image. |
| `CONDUCTOR_URL` | `http://localhost:8080` | `http://conductor-server:8080` | Container name |
| `HTTP_FILE_SERVICE_INSECURE` | `false` | `false` | |
| `HTTP_FILE_SERVICE_TIMEOUT` | `30` | `30` | May need increase for large files over container network |
| `OLLAMA_API_ENDPOINT` | `http://ollama.island.a-p.team:11434` | `http://ollama.island.a-p.team:11434` | Remote - unchanged. Container network must allow egress. |
| `OLLAMA_MODEL_NAME` | `mistral:7b` | `mistral:7b` | |

### ask-chat-service (`ask-chat-service/.env`)

| Variable | Local Value | Docker Value | Notes |
|---|---|---|---|
| `CONDUCTOR_URL` | `http://localhost:8080` | `http://conductor-server:8080` | Container name |
| `OLLAMA_API_ENDPOINT` | `http://ollama.island.a-p.team:11434` | `http://ollama.island.a-p.team:11434` | Remote - unchanged |
| `OLLAMA_MODEL_NAME` | `mistral:7b` | `mistral:7b` | |
| `CHAT_SERVICE` | `ollama` | `ollama` | |
| `PYTHONPATH` | `src` | Already set in Dockerfile (`/app/src`) | Dockerfile handles this |

### Secrets handling

- **HF_TOKEN** is the only secret. It must be provided via Docker secrets, environment file mount, or runtime injection -- never baked into the image or committed to docker-compose.yml.
- The current `.env` file contains a real HF_TOKEN. The `.env` files should be `.gitignore`d and a `.env.example` provided instead.

### localhost-to-container-name mapping summary

| Local address | Docker container name |
|---|---|
| `localhost:8080` (Conductor) | `conductor-server:8080` |
| `localhost:8081` (Backend) | `blackbox-backend:8081` |
| `localhost:8082` (Diarization) | `speaker-diarization-service:8082` |
| `localhost:8083` (Ask-chat) | `ask-chat-service:8083` |
| `localhost:9998` (Tika) | `tika:9998` |
| `localhost:27017` (MongoDB) | `mongodb:27017` |

---

## 3. Known Quirks

### JDK version sensitivity
- **JDK 21 required.** JDK 25 breaks Lombok annotation processing. The backend Docker image must use a JDK 21 base image (e.g., `eclipse-temurin:21-jre`). Do not use `latest` tags for JDK.

### Python version constraint
- **Python < 3.13 required.** The `conductor-python` SDK is incompatible with Python 3.13+. Both Dockerfiles already use `python:3.12-slim`, which is correct. Pin this version explicitly.

### pyannote model gating
- The pyannote speaker-diarization-3.1 model is gated on Hugging Face. Users must:
  1. Accept the license at `https://huggingface.co/pyannote/speaker-diarization-3.1`
  2. Provide a valid `HF_TOKEN` with access
- Without a valid token, the diarization pipeline will fail to load. However, transcription-only mode does not require HF_TOKEN at all because pyannote is lazy-loaded.

### Lazy-loaded ML models
- The pyannote diarization pipeline is **lazy-loaded** on first use, not at startup. This means:
  - The `/health` endpoint will return healthy before the model is actually loaded
  - First diarization request will be slow (model download + initialization)
  - In Docker, consider a volume mount for `~/.cache/huggingface` to persist downloaded models across container restarts
  - The large-v3-turbo whisper model (~1.5 GB) also downloads on first use and should be cached via volume

### Windows line endings in .env files
- The `speaker-diarization-service/.env` previously had Windows (CRLF) line endings, which caused `HF_TOKEN` to include a trailing `\r`. This broke Hugging Face authentication silently. Ensure `.env` files use Unix (LF) line endings. In Docker, this is handled if files are generated or mounted from Linux, but watch out if copying from Windows hosts.

### Remote Ollama dependency
- Ollama runs at `ollama.island.a-p.team:11434` -- this is an external service, not containerized locally. The Docker network must allow outbound HTTP to this host. If Ollama is unreachable, full pipeline mode degrades gracefully (see Section 6).

### Maven multi-module build
- The backend is a Maven multi-module project. Building requires `mvn clean install` from the root POM (`blackbox/backend/`). Using `-pl` to build a single module will miss cross-module dependency changes. The Docker build should always build from root.

### Conductor internal port collision
- Both Python services listen on port 8080 internally (matching Conductor's port). This is fine in Docker (each container has its own network namespace) but the `docker-compose.yml` must map them to different external ports (8082, 8083).

---

## 4. Issues Found During Testing

### Fixed in Plan 01

| Issue | Severity | Fix Applied |
|---|---|---|
| Language not passed through Conductor pipeline | Blocker | Added `language` to workflow inputParameters and transcribe task mapping; hardcoded `"de"` in `AnalysisServiceImpl.java` |
| English-only whisper model (distil-large-v3.5) used for German audio | Bug | Switched to `deepdml/faster-whisper-large-v3-turbo-ct2` (multilingual, 90+ languages) |
| Analytics panel missing in transcription_diarization mode | Bug | Changed `hasAnalyticsData` check from requiring `determinedSpeakers` to `speakerStats.length > 1` |
| Maven `-pl` build missing cross-module changes | Workflow | Documented: always use `mvn clean install` from root POM |

### Found in Plan 02

| Issue | Severity | Status |
|---|---|---|
| Ollama remote service unavailable during testing | External | **Open** -- full pipeline could not be validated end-to-end. Degradation behavior works (mode downgrades), but LLM tasks (speaker naming, analysis, chat) remain untested in integration. |

### Open items for Phase 13

1. **Ollama availability**: Full pipeline mode depends on Ollama. If the remote instance is unreliable, Phase 13 should consider adding a local Ollama container as a fallback option in docker-compose.yml.
2. **Model caching volumes**: Both faster-whisper (~1.5 GB) and pyannote models need persistent cache volumes to avoid re-downloading on every container restart.
3. **Backend service-url**: The `SERVER_SERVICE_URL` must be reachable from Conductor inside the Docker network. This is the callback URL Conductor uses to report task completion. Getting this wrong causes silent workflow hangs.

---

## 5. Startup Sequence

### Required order

```
Phase 1 (parallel):  MongoDB, RabbitMQ, MinIO, Redis, Elasticsearch, Tika
                      (all infrastructure, no inter-dependencies)
    |
Phase 2:             Conductor
                      (requires Elasticsearch + Redis healthy)
                      start_period: 60s -- Conductor is slow to initialize
    |
Phase 3 (parallel):  speaker-diarization-service, ask-chat-service
                      (both register Conductor workers on startup)
    |
Phase 4:             blackbox backend (Spring Boot)
                      (registers workflows with Conductor, checks health of Python services)
    |
Phase 5:             blackbox frontend
                      (serves static SPA, needs backend API available)
```

### Health check timing

- **Health checks fire at trigger time, not startup** (Phase 10 decision). The backend checks service availability when a user submits an analysis, not when the backend boots. This means the backend can start before the Python services are fully ready.
- **Diarization loads ML models slowly.** The pyannote pipeline and whisper model are lazy-loaded. The `/health` endpoint returns OK immediately (service is up), but the first request will be slow. This is by design -- checking model readiness at startup would add 30-60s to boot time.
- **Conductor start_period: 60s** in the existing docker-compose.yml. This is appropriate -- Conductor takes significant time to initialize with Elasticsearch.

### Docker healthcheck recommendations

```yaml
# Python services -- check HTTP readiness, not model loading
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 15s

# Backend -- Spring Boot startup can be slow
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8081/actuator/health"]
  interval: 15s
  timeout: 10s
  retries: 10
  start_period: 30s
```

---

## 6. Pipeline Mode Behavior

### Three modes

| Mode | Services Required | What It Does |
|---|---|---|
| `transcription_only` | Conductor, speaker-diarization-service | Transcribes audio only. Skips pyannote entirely (~10-15s CPU savings). No HF_TOKEN needed. |
| `transcription_diarization` | Conductor, speaker-diarization-service (+ HF_TOKEN) | Transcribes + identifies speakers. No LLM analysis. |
| `full` | Conductor, speaker-diarization-service, ask-chat-service, Ollama | Full pipeline: transcription, diarization, LLM speaker naming, round analysis, chat. Requires `definitionOfRounds` input. |

### Auto-detection logic

When `PIPELINE_MODE=auto` (default), the backend's `PipelineModeResolver` checks service health at the time a user submits an analysis:

1. Check ask-chat-service `/health` -- if UP and Ollama reachable, full mode available
2. Check speaker-diarization-service `/health` -- if UP, transcription_diarization available
3. Fallback: transcription_only (always available if Conductor is up)

### Graceful degradation

- If the user requests `full` mode but ask-chat-service or Ollama is down, the system **downgrades** to the best available mode and notifies the user why.
- If the user requests `transcription_diarization` but the diarization service is down, it downgrades to `transcription_only`.
- The frontend displays the resolved mode and the reason for any downgrade.

### Conductor workflow structure

- The workflow uses **SWITCH** tasks that branch by `pipeline_mode` (full, transcription_diarization, transcription_only).
- **taskReferenceNames must be globally unique** across all SWITCH branches. Duplicate names cause Conductor to silently route to the wrong branch.
- The `local` Spring profile sets `server.service-url` to `http://localhost:8081`. In Docker, this must be overridden to the container-resolvable address, or Conductor callbacks will fail silently.

### Frontend behavior

- The frontend polls the pipeline status endpoint and updates mode chips (transcription_only / transcription_diarization / full) dynamically.
- Analytics panel (speaker stats, timeline) appears when `speakerStats.length > 1` -- works for both `transcription_diarization` and `full` modes.
- The `definitionOfRounds` field is only required and shown when full mode is selected/resolved.

### What happens when services stop mid-operation

- If a Python service goes down after the workflow has started, Conductor will retry the failed task according to its retry policy. If retries exhaust, the workflow fails and the backend reports the error to the frontend.
- If Ollama becomes unreachable mid-pipeline, LLM tasks (speaker naming, analysis) will timeout and fail. The transcription and diarization results up to that point are preserved in the workflow output.

---

*Phase: 12-integration-testing*
*Document: Docker-readiness summary for Phase 13*
*Created: 2026-04-15*

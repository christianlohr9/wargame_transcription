# External Integrations

**Analysis Date:** 2026-01-22

## APIs & External Services

**Speech-to-Text (AssemblyAI):**
- Service: AssemblyAI - Speech transcription with speaker diarization
- SDK/Client: `assemblyai==0.46.0` (`speaker-diarization-service/requirements.txt`)
- Implementation: `speaker-diarization-service/src/services/assemblyai_diarization_service.py`
- Auth: `ASSEMBLYAI_API_KEY` environment variable
- Features: Language detection, speaker labels, transcription

**LLM Chat (OpenAI/Azure):**
- Service: Azure OpenAI - Chat completion API
- SDK/Client: `openai==2.8.1` (`ask-chat-service/requirements.txt`)
- Implementation: `ask-chat-service/src/services/openai_chat_service.py`
- Auth: `OPENAI_API_KEY`, `OPENAI_API_ENDPOINT` (Azure endpoint)
- Config: `OPENAI_MODEL_NAME`, `OPENAI_API_VERSION`
- Features: Chat completions with JSON schema responses

**LLM Chat (Ollama):**
- Service: Ollama - Local LLM inference
- SDK/Client: `ollama==0.6.1` (`ask-chat-service/requirements.txt`)
- Implementation: `ask-chat-service/src/services/ollama_chat_service.py`
- Auth: None (local service)
- Config: `OLLAMA_API_ENDPOINT`, `OLLAMA_MODEL_NAME`
- Features: Chat completions with format schemas

**Text Extraction (Apache Tika):**
- Service: Apache Tika - Document text extraction
- Client: `blackbox/backend/blackbox_application/src/main/java/com/cgi/blackbox/clients/TikaTextExtractionClientImpl.java`
- Interface: `blackbox/backend/blackbox_service/src/main/java/com/cgi/blackbox/service/clients/TextExtractionClient.java`
- Config: `BACKEND_TIKA_BASE_URL`
- Supports: PDF, DOCX, and other document formats

## Workflow Orchestration

**Netflix Conductor:**
- Service: Netflix Conductor - Workflow and task orchestration
- SDK/Client (Java): `conductor-client==4.0.20` (`blackbox/backend/blackbox_service/pom.xml`)
- SDK/Client (Python): `conductor-python==1.2.3` (`ask-chat-service/requirements.txt`)
- Java Client: `blackbox/backend/blackbox_application/src/main/java/com/cgi/blackbox/clients/ConductorWorkflowClientImpl.java`
- Python Lifecycle: `ask-chat-service/src/lifecycle.py`, `speaker-diarization-service/src/lifecycle.py`
- Config: `CONDUCTOR_URL` / `BACKEND_CONDUCTOR_BASE_URL`
- Purpose: Orchestrates diarization, chat, and analysis workflows

## Data Storage

**Databases:**
- MongoDB - Primary data store
- Connection: `BACKEND_MONGODB_CONNECTION_STRING` environment variable
- Config: `BACKEND_MONGODB_DATABASE_NAME`
- Client: Spring Data MongoDB (`blackbox/backend/blackbox_persistance/pom.xml`)
- Configuration: `blackbox/backend/blackbox_application/src/main/resources/application.yml`

**File Storage:**
- Local file system for temporary files
- HTTP file service for remote files: `speaker-diarization-service/src/services/http_file_service.py`
- Config: `HTTP_FILE_SERVICE_INSECURE`, `HTTP_FILE_SERVICE_TIMEOUT`

**Caching:**
- None configured

## Authentication & Identity

**Auth Provider:**
- Not implemented (development mode)
- No authentication middleware

**OAuth Integrations:**
- None

## Monitoring & Observability

**Error Tracking:**
- None configured
- Console logging only

**Analytics:**
- None configured

**Logs:**
- stdout/stderr (Docker logs)
- Spring Boot default logging
- No centralized log aggregation

## CI/CD & Deployment

**Hosting:**
- Docker containers (Dockerfile in each service)
- Docker Compose for local development (`blackbox/docker-compose.yml`)

**CI Pipeline:**
- Azure Pipelines (`azure-pipelines.yml` in each service)
- Build, test, and container image creation

## Environment Configuration

**Development:**
- Required env vars: See `.env.template` files in each service
- Key variables:
  - `ASSEMBLYAI_API_KEY` - AssemblyAI authentication
  - `OPENAI_API_*` - Azure OpenAI configuration
  - `OLLAMA_*` - Local Ollama configuration
  - `CONDUCTOR_URL` - Conductor server
  - `BACKEND_MONGODB_*` - MongoDB connection
  - `BACKEND_TIKA_BASE_URL` - Tika service
  - `SPRING_PROFILES_ACTIVE` - Spring Boot profile
  - `CHAT_SERVICE` - Chat provider selection (ollama/openai)

**Template Files:**
- `blackbox/.env.template`
- `ask-chat-service/.env.template`
- `speaker-diarization-service/.env.template`

**Production:**
- Docker container environment variables
- No secrets management service configured

## HTTP Communication

**Frontend API Client:**
- Axios v1.2.1 (`blackbox/frontend/src/boot/axios.ts`)
- Base URL: `http://blackbox.dev.bwi.com/` (hardcoded)
- Used in: `AppBar.vue`, `TranscriptBox.vue`, `IndexPage.vue`

**Backend Service Clients:**
- Ask-Chat Client: `blackbox/backend/blackbox_application/src/main/java/com/cgi/blackbox/clients/AskChatClient.java`
- Spring RestTemplate for inter-service calls
- Config: `${clients.ask-chat.base-url}`

**Server-Sent Events:**
- SSE API: `blackbox/backend/blackbox_application/src/main/java/com/cgi/blackbox/sse/SSERestAPI.java`
- Frontend client: `blackbox/frontend/src/boot/serverSentEvents.ts`
- Purpose: Real-time updates to frontend

## Webhooks & Callbacks

**Incoming:**
- Conductor task callbacks (async workflow updates)
- No HTTP webhooks configured

**Outgoing:**
- Conductor workflow triggers
- No external webhook integrations

---

*Integration audit: 2026-01-22*
*Update when adding/removing external services*

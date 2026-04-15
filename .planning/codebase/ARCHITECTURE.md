# Architecture

**Analysis Date:** 2026-01-22

## Pattern Overview

**Overall:** Distributed Microservices with Workflow Orchestration

**Key Characteristics:**
- Event-driven microservices with centralized Conductor orchestration
- REST API-based inter-service communication
- Layered architecture within each service (API → Service → Data)
- Strategy pattern for pluggable AI backends (OpenAI, Ollama, AssemblyAI)

## Layers

**API Layer:**
- Purpose: REST endpoints exposed by each service
- Contains: Controllers, routers, request/response handling
- Blackbox: `blackbox/backend/blackbox_application/src/main/java/com/cgi/blackbox/rest/`
- Ask Chat: `ask-chat-service/src/api/ask_chat_api.py`
- Diarization: `speaker-diarization-service/src/api/diarization_api.py`
- Depends on: Service layer
- Used by: Frontend, external clients

**Service Layer:**
- Purpose: Business logic and orchestration
- Contains: Service interfaces and implementations
- Blackbox: `blackbox/backend/blackbox_service/src/main/java/com/cgi/blackbox/service/implementation/`
- Ask Chat: `ask-chat-service/src/services/`
- Diarization: `speaker-diarization-service/src/services/`
- Depends on: Data layer, external clients
- Used by: API layer, Conductor tasks

**Data Layer:**
- Purpose: Persistence and data access
- Contains: Repositories, data objects, MongoDB access
- Location: `blackbox/backend/blackbox_persistance/src/main/java/com/cgi/blackbox/persistance/mongodb/`
- Depends on: MongoDB
- Used by: Service layer

**Model/DTO Layer:**
- Purpose: Data transfer objects and domain models
- Blackbox: `blackbox/backend/blackbox_commons/src/main/java/com/cgi/blackbox/commons/models/`
- Python: `*/src/models/`, `*/src/dtos/`
- Depends on: Nothing (pure data structures)
- Used by: All layers

## Data Flow

**Workspace Management (CRUD):**
1. Frontend (Vue) → Axios API call
2. REST endpoint (WorkspaceAPI) receives request
3. WorkspaceServiceImpl processes business logic
4. WorkspaceAccess/WorkspaceRepository queries MongoDB
5. Response flows back through layers to frontend

**Chat Processing:**
1. Frontend → POST /chat to Ask Chat Service
2. `ask_chat_api.py` routes to ChatService
3. Concrete implementation (OllamaChatService or OpenAIChatService) calls LLM
4. Response (string or JSON) returned to frontend

**Audio Diarization:**
1. Frontend → POST /transcriptions with multipart audio
2. `diarization_api.py` routes to DiarizationService
3. AssemblyAIDiarizationService calls AssemblyAI API
4. DiarizationModel response returned to frontend

**Async Workflow (Conductor):**
1. Lifecycle manager starts ConductorRunner on service startup
2. TaskHandler registers tasks (AskChatTask, DiarizationTask)
3. Conductor orchestrates async workflows across services
4. Tasks execute and report back to Conductor

**State Management:**
- MongoDB for persistent data
- Pinia stores for frontend reactive state
- Server-Sent Events for real-time updates

## Key Abstractions

**Service Pattern (Strategy):**
- Purpose: Pluggable backend implementations
- Examples: `ChatService` → OllamaChatService, OpenAIChatService
- Examples: `DiarizationService` → AssemblyAIDiarizationService
- Pattern: Abstract base class with concrete implementations

**Repository Pattern:**
- Purpose: Data access abstraction
- Examples: `WorkspaceRepository`, `WargameSetupRepository`
- Pattern: Spring Data MongoDB interfaces
- Location: `blackbox/backend/blackbox_persistance/src/main/java/com/cgi/blackbox/persistance/mongodb/repository/`

**DTO/Model Separation:**
- Purpose: Decouple API contracts from domain models
- DTOs: `ChatHistoryDto`, `DiarizationDto`
- Models: `ChatHistoryModel`, `DiarizationModel`
- Translator: `ReflectiveTranslator` for conversions

**Conductor Tasks:**
- Purpose: Async workflow task definitions
- Examples: `AskChatTask`, `DiarizationTask`
- Pattern: Worker tasks registered with Conductor
- Location: `*/src/tasks/`

## Entry Points

**Blackbox Backend:**
- Location: `blackbox/backend/blackbox_application/src/main/java/com/cgi/blackbox/Application.java`
- Triggers: Spring Boot startup
- Responsibilities: Initialize Spring context, start HTTP server

**Ask Chat Service:**
- Location: `ask-chat-service/src/main.py`
- Triggers: Uvicorn ASGI server
- Responsibilities: Initialize FastAPI, start Conductor lifecycle

**Speaker Diarization Service:**
- Location: `speaker-diarization-service/src/main.py`
- Triggers: Uvicorn ASGI server
- Responsibilities: Initialize FastAPI, start Conductor lifecycle

**Frontend:**
- Location: `blackbox/frontend/src/App.vue`
- Triggers: Browser navigation
- Responsibilities: Initialize Vue app, router, Pinia stores

## Error Handling

**Strategy:** Exceptions at service layer, HTTP status codes at API layer

**Patterns:**
- Java: Custom exceptions (WorkspaceNotFoundException, ServiceException)
- Python: Broad exception catch in tasks, JSON error responses
- Frontend: Console logging, limited user feedback

## Cross-Cutting Concerns

**Logging:**
- Spring Boot default logging (Blackbox)
- Console/stdout (Python services)
- Browser console (Frontend)

**Validation:**
- Pydantic models for Python API validation
- Spring validation annotations (Java)
- Limited frontend validation

**Authentication:**
- Not implemented (development mode)

**Real-time Updates:**
- Server-Sent Events via `SSERestAPI.java`
- Frontend SSE client in `blackbox/frontend/src/boot/serverSentEvents.ts`

---

*Architecture analysis: 2026-01-22*
*Update when major patterns change*

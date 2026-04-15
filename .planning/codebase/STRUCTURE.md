# Codebase Structure

**Analysis Date:** 2026-01-22

## Directory Layout

```
wargaming_cgi/
├── blackbox/                           # Main integrated platform
│   ├── backend/
│   │   ├── blackbox_application/       # Spring Boot entry point, REST APIs
│   │   ├── blackbox_service/           # Business logic layer
│   │   ├── blackbox_persistance/       # Data access layer
│   │   └── blackbox_commons/           # Shared models and utilities
│   ├── frontend/                       # Vue 3 + Quasar SPA
│   ├── pom.xml                         # Maven parent POM
│   ├── docker-compose.yml              # Local development orchestration
│   └── azure-pipelines.yml             # CI/CD pipeline
│
├── ask-chat-service/                   # Python FastAPI chat microservice
│   ├── src/
│   │   ├── api/                        # REST endpoints
│   │   ├── services/                   # Business logic
│   │   ├── models/                     # Pydantic models
│   │   ├── dtos/                       # Data transfer objects
│   │   ├── tasks/                      # Conductor tasks
│   │   ├── main.py                     # Entry point
│   │   └── lifecycle.py                # Conductor lifecycle
│   ├── requirements.txt                # Python dependencies
│   └── Dockerfile                      # Container build
│
└── speaker-diarization-service/        # Python FastAPI diarization microservice
    ├── src/
    │   ├── api/                        # REST endpoints
    │   ├── services/                   # Business logic
    │   ├── models/                     # Pydantic models
    │   ├── dtos/                       # Data transfer objects
    │   ├── tasks/                      # Conductor tasks
    │   ├── utils/                      # Utility functions
    │   ├── main.py                     # Entry point
    │   └── lifecycle.py                # Conductor lifecycle
    ├── requirements.txt                # Python dependencies
    └── Dockerfile                      # Container build
```

## Directory Purposes

**blackbox/backend/blackbox_application/**
- Purpose: Spring Boot application entry point and REST controllers
- Contains: `Application.java`, REST controllers, SSE handlers
- Key files: `src/main/java/com/cgi/blackbox/Application.java`, `rest/*.java`
- Subdirectories: `rest/` (controllers), `sse/` (Server-Sent Events), `clients/` (external service clients)

**blackbox/backend/blackbox_service/**
- Purpose: Business logic and service implementations
- Contains: Service interfaces, implementations, exception classes
- Key files: `WorkspaceServiceImpl.java`, `WargameSetupServiceImpl.java`, `AnalysisServiceImpl.java`
- Subdirectories: `implementation/` (services), `clients/` (client interfaces), `exceptions/`

**blackbox/backend/blackbox_persistance/**
- Purpose: MongoDB data access layer
- Contains: Repositories, data objects, MongoDB configuration
- Key files: `WorkspaceRepository.java`, `WorkspaceDO.java`, `MongoConfiguration.java`
- Subdirectories: `mongodb/repository/`, `mongodb/dataobject/`, `mongodb/implementation/`

**blackbox/backend/blackbox_commons/**
- Purpose: Shared domain models and utilities
- Contains: Model classes, translators, base abstractions
- Key files: `WorkspaceModel.java`, `WargameSetupModel.java`, `ReflectiveTranslator.java`
- Subdirectories: `models/`

**blackbox/frontend/**
- Purpose: Vue 3 + Quasar single-page application
- Contains: Vue components, pages, stores, utilities
- Key files: `App.vue`, `quasar.config.ts`, `package.json`
- Subdirectories: `src/pages/`, `src/components/`, `src/boot/`, `src/stores/`, `src/utils/`

**ask-chat-service/src/**
- Purpose: AI chat microservice with LLM integrations
- Contains: FastAPI endpoints, chat services, Conductor tasks
- Key files: `main.py`, `chat_service.py`, `ollama_chat_service.py`, `openai_chat_service.py`
- Subdirectories: `api/`, `services/`, `models/`, `dtos/`, `tasks/`

**speaker-diarization-service/src/**
- Purpose: Audio transcription with speaker diarization
- Contains: FastAPI endpoints, AssemblyAI integration, Conductor tasks
- Key files: `main.py`, `assemblyai_diarization_service.py`, `diarization_task.py`
- Subdirectories: `api/`, `services/`, `models/`, `dtos/`, `tasks/`, `utils/`

## Key File Locations

**Entry Points:**
- `blackbox/backend/blackbox_application/src/main/java/com/cgi/blackbox/Application.java` - Java backend
- `ask-chat-service/src/main.py` - Chat service
- `speaker-diarization-service/src/main.py` - Diarization service
- `blackbox/frontend/src/App.vue` - Frontend

**Configuration:**
- `blackbox/pom.xml` - Maven parent configuration
- `blackbox/frontend/quasar.config.ts` - Frontend build config
- `blackbox/backend/blackbox_application/src/main/resources/application.yml` - Spring Boot config
- `*/.env.template` - Environment variable templates

**Core Logic:**
- `blackbox/backend/blackbox_service/src/main/java/com/cgi/blackbox/service/implementation/` - Java services
- `ask-chat-service/src/services/` - Chat service implementations
- `speaker-diarization-service/src/services/` - Diarization implementations

**Testing:**
- `blackbox/backend/*/src/test/java/com/cgi/blackbox/` - Java tests
- No Python or frontend tests configured

**Documentation:**
- `*/README.md` - Service documentation
- `blackbox/frontend/README.md` - Frontend setup

## Naming Conventions

**Files:**
- Java: PascalCase.java (e.g., `WorkspaceService.java`, `WorkspaceServiceImpl.java`)
- Python: snake_case.py (e.g., `chat_service.py`, `diarization_api.py`)
- Vue: PascalCase.vue (e.g., `TranscriptBox.vue`, `AnalIntelligence.vue`)
- TypeScript: kebab-case.ts (e.g., `example-store.ts`, `tfidf.ts`)

**Directories:**
- Java packages: lowercase (e.g., `rest`, `implementation`, `mongodb`)
- Python modules: snake_case (e.g., `services`, `models`, `dtos`)
- Vue/TS: lowercase (e.g., `components`, `pages`, `stores`)

**Special Patterns:**
- `*Impl.java` - Service implementation classes
- `*DO.java` - Data objects (persistence)
- `*Model.java` - Domain models
- `*_api.py` - FastAPI routers
- `*_service.py` - Service classes
- `*_task.py` - Conductor task definitions

## Where to Add New Code

**New REST Endpoint (Java):**
- Controller: `blackbox/backend/blackbox_application/src/main/java/com/cgi/blackbox/rest/`
- Service interface: `blackbox/backend/blackbox_service/src/main/java/com/cgi/blackbox/service/implementation/`
- Tests: `blackbox/backend/blackbox_application/src/test/java/com/cgi/blackbox/`

**New REST Endpoint (Python):**
- Router: `*/src/api/{name}_api.py`
- Service: `*/src/services/{name}_service.py`
- Model: `*/src/models/{name}_model.py`
- DTO: `*/src/dtos/{name}_dto.py`

**New Vue Component:**
- Component: `blackbox/frontend/src/components/{Name}.vue`
- Page: `blackbox/frontend/src/pages/{Name}Page.vue`
- Store: `blackbox/frontend/src/stores/{name}-store.ts`

**New Conductor Task:**
- Task: `*/src/tasks/{name}_task.py`
- Register in: `*/src/lifecycle.py`

**New Domain Model:**
- Java: `blackbox/backend/blackbox_commons/src/main/java/com/cgi/blackbox/commons/models/`
- Python: `*/src/models/`

## Special Directories

**blackbox/frontend/dist/**
- Purpose: Built frontend assets
- Source: Generated by `quasar build`
- Committed: Yes (for deployment)

**blackbox/frontend/node_modules/**
- Purpose: npm dependencies
- Source: `npm install`
- Committed: No (in .gitignore)

---

*Structure analysis: 2026-01-22*
*Update when directory structure changes*

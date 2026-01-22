# Technology Stack

**Analysis Date:** 2026-01-22

## Languages

**Primary:**
- TypeScript 5.9.2 - Frontend application code (`blackbox/frontend/package.json`)
- Java 21 - Backend services (`blackbox/backend/blackbox_service/pom.xml`)
- Python 3 - Microservices (`speaker-diarization-service/requirements.txt`, `ask-chat-service/requirements.txt`)

**Secondary:**
- JavaScript - Vue 3 templates, build scripts
- YAML - Configuration files, CI/CD pipelines

## Runtime

**Environment:**
- Node.js v20+ - Frontend build and development (`blackbox/frontend/package.json` engines field)
- JVM 21 - Spring Boot backend (`blackbox/pom.xml`)
- Python 3.x - FastAPI microservices

**Package Managers:**
- npm - Frontend (`blackbox/frontend/package.json`)
- Maven - Java backend (`blackbox/backend/*/pom.xml`)
- pip - Python services (`requirements.txt`)

## Frameworks

**Core:**
- Vue 3 v3.5.22 - Frontend UI framework (`blackbox/frontend/package.json`)
- Quasar v2.16.0 - Vue component library (`blackbox/frontend/package.json`)
- Spring Boot 3.4.4 - Java backend framework (`blackbox/pom.xml`)
- FastAPI v0.121.3 - Python microservices (`ask-chat-service/requirements.txt`)

**Testing:**
- Spring Boot Test - Java integration testing (`blackbox/backend/blackbox_application/pom.xml`)
- TestContainers - MongoDB test containers (`blackbox/backend/blackbox_application/pom.xml`)
- WireMock v3.12.1 - HTTP mocking (`blackbox/backend/blackbox_service/pom.xml`)
- No frontend or Python test frameworks configured

**Build/Dev:**
- Vite - Frontend bundling via @quasar/app-vite (`blackbox/frontend/package.json`)
- Maven - Java build system (`blackbox/pom.xml`)
- ESLint v9.14.0 - Frontend linting (`blackbox/frontend/package.json`)
- Prettier v3.3.3 - Code formatting (`blackbox/frontend/package.json`)

## Key Dependencies

**Critical:**
- Netflix Conductor v4.0.20 - Workflow orchestration (`blackbox/backend/blackbox_service/pom.xml`)
- conductor-python v1.2.3 - Python Conductor client (`ask-chat-service/requirements.txt`)
- Spring Data MongoDB - Database access (`blackbox/backend/blackbox_persistance/pom.xml`)
- Pinia v3.0.1 - Vue state management (`blackbox/frontend/package.json`)
- Axios v1.2.1 - HTTP client (`blackbox/frontend/package.json`)

**AI/ML:**
- AssemblyAI v0.46.0 - Speech-to-text with diarization (`speaker-diarization-service/requirements.txt`)
- OpenAI v2.8.1 - Chat completion API (`ask-chat-service/requirements.txt`)
- Ollama v0.6.1 - Local LLM inference (`ask-chat-service/requirements.txt`)

**Infrastructure:**
- Project Reactor - Reactive streams (`blackbox/backend/blackbox_service/pom.xml`)
- Lombok - Java boilerplate reduction (`blackbox/backend/blackbox_service/pom.xml`)
- SpringDoc OpenAPI v2.3.0 - API documentation (`blackbox/backend/blackbox_application/pom.xml`)
- Uvicorn - ASGI server for FastAPI (`ask-chat-service/requirements.txt`)

## Configuration

**Environment:**
- `.env.template` files in each service root
- Key variables: `ASSEMBLYAI_API_KEY`, `OPENAI_API_*`, `OLLAMA_*`, `CONDUCTOR_URL`, `BACKEND_MONGODB_*`
- Spring profiles via `SPRING_PROFILES_ACTIVE` (local/dev/prod)

**Build:**
- `blackbox/frontend/quasar.config.ts` - Quasar/Vite build configuration
- `blackbox/frontend/tsconfig.json` - TypeScript configuration
- `blackbox/backend/blackbox_application/src/main/resources/application.yml` - Spring Boot config
- `blackbox/pom.xml` - Maven parent POM

## Platform Requirements

**Development:**
- Any platform with Node.js 20+, JDK 21, Python 3
- Docker for local services (MongoDB, Conductor)
- IDE support for Vue, Java, Python

**Production:**
- Docker containers (`Dockerfile` in each service)
- Azure Pipelines CI/CD (`azure-pipelines.yml`)
- MongoDB database
- Conductor workflow server

---

*Stack analysis: 2026-01-22*
*Update after major dependency changes*

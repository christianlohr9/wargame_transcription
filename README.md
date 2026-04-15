# Wargame Audio Intelligence (WAI) — Op4C Session Analyzer

A desktop application that transcribes wargame audio recordings, identifies speakers, detects rounds, and generates AI-powered analysis reports. Runs fully offline on standard hardware — no cloud APIs, no Docker, no admin rights.

## Repository Structure

```
blackbox/                     # Java backend + Vue/Quasar frontend
  backend/                    # Spring Boot (H2, filesystem, embedded Tika)
  frontend/                   # Vue 3 + Quasar SPA
speaker-diarization-service/  # Python — faster-whisper + pyannote
ask-chat-service/             # Python — Ollama LLM integration
blackbox-desktop/             # Electron shell + packaging
  scripts/                    # Build scripts (jlink, conda-pack, models)
  electron/                   # Main process, ProcessManager
BWI Hackathon 2025/           # Original documentation (German) + K8s manifests
.planning/                    # Project planning artifacts
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Java 21, Spring Boot 3.4, H2 (embedded), filesystem storage |
| Frontend | Vue 3, Quasar, TypeScript, pdfmake, docx |
| AI — Transcription | faster-whisper (large-v3-turbo), WhisperX alignment |
| AI — Diarization | pyannote (speaker-diarization-3.1) |
| AI — Analysis | Ollama (remote, configurable model) |
| Desktop | Electron 33, electron-builder, NSIS installer |
| Runtimes | jlink (portable JRE), conda-pack (portable Python) |

## Quick Start (Development)

### Prerequisites

- JDK 21 (Temurin recommended)
- Maven 3.9+
- Node.js 18+
- Python 3.12 with venv

### 1. Backend

```bash
cd blackbox
JAVA_HOME=/path/to/jdk-21 mvn clean install -DskipTests
SPRING_PROFILES_ACTIVE=local java -jar backend/blackbox_application/target/*.jar
```

Backend starts on port 8081 with embedded H2 database.

### 2. Frontend

```bash
cd blackbox/frontend
npm install
npx quasar dev
```

Frontend starts on port 9003.

### 3. Speaker Diarization (optional)

```bash
cd speaker-diarization-service
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python -m uvicorn src.main:app --port 8082
```

Requires a Hugging Face token (`HF_TOKEN`) for pyannote models.

### 4. Chat Service (optional)

```bash
cd ask-chat-service
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python -m uvicorn src.main:app --port 8083
```

Requires a running Ollama instance.

### 5. Electron App (dev mode)

```bash
cd blackbox/frontend && npx quasar build
cp -r dist/spa ../../blackbox-desktop/dist
cd ../../blackbox-desktop
npm install && npm start
```

## Pipeline Modes

The app supports three modes depending on available services:

| Mode | Requires | Output |
|------|----------|--------|
| Transcription only | Backend | Raw transcript |
| Transcription + Diarization | Backend + Diarization service | Transcript with speaker names |
| Full analysis | Backend + Diarization + Chat | Transcript + speakers + rounds + AI analysis |

The backend detects available services at runtime and adapts automatically.

## Deployment (Windows Installer)

For building and distributing the Windows installer, see **[`blackbox-desktop/DEPLOYMENT.md`](blackbox-desktop/DEPLOYMENT.md)**.

## Documentation

Detailed documentation (in German) is available in [`BWI Hackathon 2025/`](BWI%20Hackathon%202025/00-README.md):

- Architecture overview
- API reference
- User guide
- Security & compliance considerations

## Key Ports

| Service | Port |
|---------|------|
| Backend | 8081 |
| Diarization | 8082 |
| Chat | 8083 |
| Frontend (dev) | 9003 |

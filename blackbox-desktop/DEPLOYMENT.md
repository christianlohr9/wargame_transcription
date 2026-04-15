# Blackbox Wargaming — Deployment Guide

This guide explains how to get the Blackbox Wargaming app onto a colleague's Windows computer.

## How it works

The app is a desktop program (like Word or Outlook) that runs entirely on the local machine — no internet required after setup. It records and analyzes wargame sessions: transcribing audio, identifying speakers, and generating analysis reports.

There are two roles in this process:

- **Developer:** Builds the installer on the target machine
- **Colleague:** Runs the installer and uses the app

---

## What the colleague gets

A single Windows installer (`Blackbox Wargaming Setup.exe`) that installs to their user folder — **no admin rights needed**. After installation, they double-click the desktop icon and the app handles everything.

---

## Prerequisites

### On the target Windows machine

The build must happen **on the target Windows machine** (or one with the same architecture). The runtimes are platform-specific — you cannot build them on your Mac.

> **DEVELOPER ASSISTANCE REQUIRED**
>
> You need physical or remote access to the colleague's Windows machine to perform the build. Estimated time: 30-60 minutes (mostly waiting for downloads).

The following must be installed on the Windows machine **before** you start:

| Tool | Why | Install |
|------|-----|---------|
| Git + Git Bash | Clone repo, run build scripts | https://git-scm.com/download/win |
| JDK 21 | Build Java backend + portable JRE | https://adoptium.net (Temurin 21 LTS) |
| Node.js 18+ | Build frontend + Electron app | https://nodejs.org (LTS version) |
| Miniconda | Build portable Python runtime | https://docs.conda.io/en/latest/miniconda.html |

> **DEVELOPER ASSISTANCE REQUIRED**
>
> Install all four tools above. Each is a standard Windows installer (next, next, finish). Make sure to check "Add to PATH" when prompted during each installation.

**Optional (only for full analysis mode with LLM summaries):**

| Tool | Why | Install |
|------|-----|---------|
| Ollama | LLM for round analysis & prompts | https://ollama.com/download |

---

## Build Steps

All commands below are run in **Git Bash** (installed with Git).

### Step 1: Clone the repository

```bash
git clone <repo-url> blackbox-wargaming
cd blackbox-wargaming
```

> **DEVELOPER ASSISTANCE REQUIRED**
>
> You need to provide the repo URL or copy the source code to the machine via USB stick if there's no network access.

### Step 2: Run the build script

```bash
cd blackbox-desktop
bash scripts/build-windows-package.sh
```

This single script does everything:
1. Builds the Java backend
2. Builds the web frontend
3. Creates a portable Java runtime (so the colleague doesn't need Java installed)
4. Creates a portable Python runtime (so the colleague doesn't need Python installed)
5. Packages everything into a Windows installer

> **DEVELOPER ASSISTANCE REQUIRED**
>
> Run this script and monitor for errors. It takes 15-30 minutes depending on internet speed (Python packages and ML models are downloaded). If conda prompts for confirmation, type `y`.

### Step 3: (Optional) Bundle ML models for offline use

If the colleague's machine will be air-gapped (no internet) after setup:

```bash
# Set Hugging Face token (required for speaker diarization models)
export HF_TOKEN=hf_your_token_here

# Run model bundler
BUNDLE_MODELS=true bash scripts/bundle-models.sh
```

Then rebuild the installer:

```bash
npx electron-builder --win
```

> **DEVELOPER ASSISTANCE REQUIRED**
>
> You need a Hugging Face account with accepted terms for pyannote models. Get a token at https://huggingface.co/settings/tokens. The Whisper model downloads without a token.

### Step 4: Hand over the installer

The installer is at:

```
blackbox-desktop/dist-electron/Blackbox Wargaming Setup *.exe
```

Copy this `.exe` file to the colleague (USB stick, file share, etc.).

---

## Colleague's Instructions

Share this section with your colleague:

---

### Installing Blackbox Wargaming

1. Double-click `Blackbox Wargaming Setup.exe`
2. Choose where to install (the default is fine)
3. Click "Install"
4. Click "Finish"

No admin rights are needed. The app installs to your personal user folder.

### Using the app

1. Open **Blackbox Wargaming** from the Start Menu or desktop shortcut
2. The app starts automatically — wait a few seconds for the green status indicators
3. Create a new workspace, upload your audio file, configure your wargame setup
4. Click "Start Analysis" and wait for processing

### What the status lights mean

| Light | Meaning |
|-------|---------|
| Green "Backend" | Core system running (always needed) |
| Green "Diarization" | Speaker identification available |
| Green "Chat" | LLM analysis available (needs Ollama) |

The app works in reduced mode if not all services are green:
- **Only Backend green:** Transcription only (no speaker names, no analysis)
- **Backend + Diarization green:** Transcription with speaker names
- **All green:** Full analysis with round detection and prompt responses

### Exporting results

In any workspace with transcript data, click the export button to download:
- **PDF** — formatted report
- **DOCX** — editable Word document
- **TXT** — plain text

### Troubleshooting

| Problem | Solution |
|---------|----------|
| App won't open | Right-click the shortcut, "Run as administrator" is NOT needed. Just double-click. |
| "Backend" stays red | Close and reopen the app. Check if another program uses port 8081. |
| "Diarization" stays red | This is normal if Python services weren't bundled. Transcription still works. |
| Audio processing is slow | Expected on CPU — a 1-hour audio file takes roughly 15-30 minutes. |

> If something doesn't work, contact the developer who set up the app.

---

## Architecture (for developers)

```
Blackbox Wargaming Setup.exe
  └── installs to: C:\Users\<name>\AppData\Local\Programs\blackbox-wargaming\
        ├── Blackbox Wargaming.exe    (Electron shell)
        ├── resources/
        │   ├── runtime/java/         (portable JRE from jlink)
        │   ├── runtime/python/       (portable Python from conda-pack)
        │   ├── models/               (ML models, if bundled)
        │   │   ├── whisper/          (faster-whisper-large-v3-turbo)
        │   │   └── huggingface/      (pyannote diarization models)
        │   └── app/
        │       ├── blackbox.jar      (Spring Boot backend)
        │       ├── diarization/      (Python diarization service source)
        │       └── chat/             (Python chat service source)
        └── dist/                     (Vue/Quasar frontend SPA)
```

All services are managed by Electron's ProcessManager — the user never interacts with Java, Python, or command lines.

## Summary of assistance points

| Step | What | Who | Time |
|------|------|-----|------|
| Install tools | JDK, Node, Git, Conda on Windows | Developer on colleague's machine | 15 min |
| Clone repo | Get source code onto machine | Developer | 5 min |
| Run build | Execute build-windows-package.sh | Developer on colleague's machine | 15-30 min |
| Bundle models | Optional, for air-gapped use | Developer (needs HF token) | 10 min |
| Hand over installer | Copy .exe to colleague | Developer | 1 min |
| Install app | Run the .exe | Colleague (no help needed) | 2 min |

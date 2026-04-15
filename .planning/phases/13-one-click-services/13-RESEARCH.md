# Phase 13: One-Click Services - Research

**Researched:** 2026-04-15
**Domain:** Desktop app packaging for multi-service platform (Electron + portable runtimes + process management)
**Confidence:** HIGH

<research_summary>
## Summary

Researched how to deliver the Blackbox wargaming platform as a zero-terminal, one-click desktop application for non-technical users on a locked-down Windows HP EliteBook (16GB RAM, no admin rights, air-gapped for VS-NfD classified material).

**Critical finding: Docker is NOT viable.** Docker Desktop, Podman, and WSL2 all require admin privileges to install on Windows. The entire docker-compose approach from the original phase description must be replaced with an Electron desktop shell that manages portable embedded runtimes (jlink JRE + conda-packed Python) as child processes.

**Second critical finding: Infrastructure services are the elephant in the room.** The current architecture requires 7 middleware services (MongoDB, Redis, Elasticsearch, RabbitMQ, Conductor, MinIO, Tika). For a truly portable single-exe deployment, these must be either replaced with embedded alternatives or significantly simplified. This is the hardest engineering challenge in this phase.

**Primary recommendation:** Build an Electron app that bundles portable JRE (jlink), portable Python (conda-pack), and pre-downloaded ML models. Electron main process acts as process supervisor — spawns, monitors, and gracefully shuts down all services. Frontend-only transcript export using pdfmake (PDF) + docx (DOCX). Infrastructure simplification is a prerequisite sub-phase.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Electron | 34.x | Desktop app shell + process manager | Proven pattern for multi-service desktop apps (Ostara case study). Manages child processes, bundles runtimes, portable exe output |
| electron-builder | 26.x | Packaging + distribution | Portable exe target, extraResources for bundled runtimes, per-user NSIS installer (no admin) |
| jlink (JDK 21) | 21 | Custom portable JRE | Strips unused modules, ~50-80MB vs ~335MB full JDK. Ships as folder with `bin/java.exe` |
| conda-pack | 0.8.x | Portable Python environment | Packs entire conda env (Python + PyTorch CPU + faster-whisper + pyannote) into relocatable archive |
| pdfmake | 0.3.7 | PDF transcript export | Declarative JSON API, works client-side, MIT license, handles pagination/tables/styles |
| docx | 9.6.1 | DOCX transcript export | Full TypeScript API, browser-side via Packer.toBlob(), MIT license |
| file-saver | 2.0.5 | Download trigger | Triggers browser downloads from Blob objects |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| electron-log | 5.x | Logging from main + renderer | Structured logging for process lifecycle events |
| electron-store | 10.x | Persistent settings | User preferences (selected services, port overrides) |
| tree-kill | 1.x | Process tree cleanup | Kill child process trees on shutdown (prevents orphans) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Electron | Tauri | Tauri is lighter (~3MB vs ~150MB, ~30MB RAM vs ~300MB) but requires Rust knowledge and has less precedent for bundling JRE+Python. Bundle size savings negligible when models are 1-3GB. |
| Electron | Plain .bat launcher | No UI for process management, no crash recovery, no service toggle. Not viable for non-technical users. |
| conda-pack | PyInstaller | PyInstaller produces single exe but AV false positives are extremely common, startup is slow (extracts to temp), and PyTorch bundles are 2GB+. |
| conda-pack | python-build-standalone | More control but requires manual wheel vendoring. conda-pack is simpler for complex ML stacks. |
| jlink | GraalVM Native Image | Single exe, sub-100ms startup, but build needs Visual Studio Build Tools, debugging is harder, and Spring Boot reflection/proxy patterns need careful metadata. Higher risk for this project. |
| pdfmake | Backend (OpenPDF) | Works but requires backend to be running for export. Frontend approach works offline and avoids round-trips. |

### Installation (Build Machine)
```bash
# Electron app
npm install electron electron-builder
npm install pdfmake docx file-saver tree-kill electron-log electron-store

# Java custom JRE (on build machine with JDK 21)
jdeps --ignore-missing-deps --multi-release 21 -s blackbox_application-0.1.0-SNAPSHOT.jar
jlink --add-modules <required-modules> --compress=2 --output runtime/java

# Python portable env (on Windows x64 build machine)
conda create -n whisperx python=3.12 pytorch-cpu faster-whisper pyannote.audio
conda pack -n whisperx -o python-env.tar.gz
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Application Structure
```
blackbox-desktop/
├── electron/
│   ├── main.js                    # Electron main process (supervisor)
│   ├── preload.js                 # Bridge to renderer
│   ├── processManager.js          # Spawn/monitor/kill child processes
│   ├── healthChecker.js           # HTTP polling for service health
│   └── portFinder.js              # Find available localhost ports
├── src/                           # Vue.js/Quasar frontend (existing)
│   ├── components/
│   │   ├── ServiceStatus.vue      # Service toggle UI
│   │   └── TranscriptExport.vue   # PDF/DOCX/TXT download
│   └── ...
├── resources/
│   ├── runtime/
│   │   ├── java/                  # jlink custom JRE (~50-80 MB)
│   │   └── python/                # conda-pack extracted env (~1.5-2 GB)
│   ├── models/
│   │   ├── whisper/               # Pre-downloaded whisper model
│   │   └── pyannote/              # Pre-downloaded diarization model
│   └── app/
│       ├── blackbox.jar           # Spring Boot fat JAR
│       └── diarization/           # Python diarization service source
├── package.json
└── electron-builder.yml
```

### Pattern 1: Electron Process Supervisor
**What:** Electron main process spawns, monitors, and manages all backend services as child processes.
**When to use:** Any multi-service desktop app.
**Source:** Ostara project (Spring Boot + Electron, production-proven)

```javascript
// processManager.js - Electron main process
const { spawn } = require('child_process');
const path = require('path');
const treeKill = require('tree-kill');

class ProcessManager {
  constructor() {
    this.processes = new Map();
  }

  startService(name, command, args, options = {}) {
    const child = spawn(command, args, {
      cwd: options.cwd,
      env: { ...process.env, ...options.env },
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true  // Critical: hide console windows
    });

    child.on('exit', (code) => {
      this.processes.delete(name);
      if (code !== 0 && options.autoRestart) {
        setTimeout(() => this.startService(name, command, args, options), 3000);
      }
    });

    this.processes.set(name, { child, name, healthUrl: options.healthUrl });
    return child;
  }

  async stopAll() {
    for (const [name, proc] of this.processes) {
      await new Promise((resolve) => {
        treeKill(proc.child.pid, 'SIGTERM', () => resolve());
      });
    }
  }
}
```

### Pattern 2: Health-Check Based Service Status
**What:** Poll each service's health endpoint from Electron main process, expose status to renderer via IPC.
**When to use:** Always — users need to see what's running.

```javascript
// healthChecker.js
const http = require('http');

class HealthChecker {
  constructor(services) {
    this.services = services; // { name, healthUrl, interval }
    this.status = {};
  }

  start() {
    for (const svc of this.services) {
      this.status[svc.name] = 'starting';
      setInterval(() => this.check(svc), svc.interval || 3000);
    }
  }

  check(svc) {
    http.get(svc.healthUrl, (res) => {
      this.status[svc.name] = res.statusCode === 200 ? 'healthy' : 'unhealthy';
    }).on('error', () => {
      this.status[svc.name] = 'unreachable';
    });
  }
}
```

### Pattern 3: Frontend-Only Transcript Export
**What:** Generate PDF/DOCX/TXT entirely in the browser from already-loaded transcript data.
**When to use:** Desktop app where data is already in frontend memory.

```javascript
// TranscriptExport — pdfmake for PDF
import pdfMake from 'pdfmake/build/pdfmake';
import pdfFonts from 'pdfmake/build/vfs_fonts';
pdfMake.vfs = pdfFonts.vfs;

function exportPdf(transcript) {
  const docDefinition = {
    content: transcript.segments.map(seg => ({
      columns: [
        { text: seg.timestamp, width: 80, style: 'timestamp' },
        { text: seg.speaker, width: 100, style: 'speaker' },
        { text: seg.text, style: 'content' }
      ],
      margin: [0, 2]
    })),
    styles: {
      timestamp: { fontSize: 8, color: '#666' },
      speaker: { fontSize: 9, bold: true },
      content: { fontSize: 10 }
    }
  };
  pdfMake.createPdf(docDefinition).download('transcript.pdf');
}
```

```javascript
// TranscriptExport — docx for DOCX
import { Document, Paragraph, TextRun, Packer } from 'docx';
import { saveAs } from 'file-saver';

async function exportDocx(transcript) {
  const doc = new Document({
    sections: [{
      children: transcript.segments.map(seg =>
        new Paragraph({
          children: [
            new TextRun({ text: `[${seg.timestamp}] `, color: '666666', size: 16 }),
            new TextRun({ text: `${seg.speaker}: `, bold: true, size: 18 }),
            new TextRun({ text: seg.text, size: 20 })
          ]
        })
      )
    }]
  });
  const blob = await Packer.toBlob(doc);
  saveAs(blob, 'transcript.docx');
}
```

### Anti-Patterns to Avoid
- **Using Docker for distribution on restricted Windows:** Docker Desktop requires admin rights. Period. Don't try to work around this — it won't work in an enterprise locked-down environment.
- **PyInstaller for complex ML stacks:** AV false positives, massive exe size, slow startup. Use conda-pack instead.
- **Spawning services without `windowsHide: true`:** Console windows will flash on screen, terrifying non-technical users.
- **Hardcoded ports:** Another app might use 8080. Use dynamic port discovery and pass ports via environment variables.
- **Relying on `utilityProcess` for Java/Python:** Electron's `utilityProcess` only works for Node.js child processes. Use `child_process.spawn()` for external runtimes.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PDF generation | Custom PDF byte writing | pdfmake (frontend) | PDF spec is complex, fonts/encoding/pagination are hard. pdfmake handles all of it. |
| DOCX generation | Manual XML construction | docx npm package | OOXML is a 6000-page spec. The library handles it correctly. |
| Process tree kill | `process.kill()` | tree-kill npm package | On Windows, killing a parent doesn't kill children. tree-kill handles the process tree. |
| Port discovery | Random port assignment | portfinder or detect-port | Handles race conditions, checks actual availability. |
| Electron packaging | Manual zip/installer | electron-builder | Handles code signing, auto-update, portable exe, NSIS installer, extraResources. |
| JRE stripping | Manual file deletion | jlink | Knows module dependencies, produces valid minimal JRE. |
| Python env portability | Manual file copy | conda-pack | Fixes hardcoded paths, handles shared libraries, produces relocatable env. |
| Service health monitoring | Custom TCP probes | HTTP health endpoints (already exist in Spring Boot Actuator) | Actuator /health is already implemented. Just poll it. |

**Key insight:** The hard part of this phase is NOT the individual components — it's the orchestration. Electron + established libraries handle process management, health checks, and document export. The real engineering challenge is simplifying the 7-service infrastructure into something a portable app can manage.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Orphan Processes on Crash
**What goes wrong:** If Electron crashes hard (or user force-kills it via Task Manager), Java and Python child processes keep running in the background, consuming RAM and locking ports.
**Why it happens:** `child_process.spawn()` doesn't auto-kill children when the parent dies on Windows.
**How to avoid:** (1) Use `tree-kill` in `app.on('before-quit')`. (2) Have child processes monitor parent PID and self-terminate if parent disappears. (3) On startup, check if previous instances are still running and kill them.
**Warning signs:** "Port already in use" errors on second launch.

### Pitfall 2: Windows Defender / AV False Positives
**What goes wrong:** Unsigned executables get quarantined or blocked by Windows Defender SmartScreen. Users see scary "Windows protected your PC" warnings.
**Why it happens:** Large unsigned executables with embedded binaries (especially Python) trigger heuristic AV detection.
**How to avoid:** (1) Code-sign the Electron exe with the organization's Authenticode certificate. (2) For internal deployment, have IT whitelist the application folder. (3) Avoid PyInstaller (worst offender for false positives).
**Warning signs:** App works on dev machine but fails on target machine. Users report "blocked" or "virus detected."

### Pitfall 3: Console Windows Flashing
**What goes wrong:** When spawning Java/Python processes, black console windows briefly appear or persist.
**Why it happens:** Default `child_process.spawn()` on Windows shows console windows for child processes.
**How to avoid:** Always use `windowsHide: true` in spawn options. For Java, consider `javaw.exe` instead of `java.exe` (no console window).
**Warning signs:** Users see terminal windows and panic.

### Pitfall 4: Portable Exe Extraction Time
**What goes wrong:** Using electron-builder's `portable` target, the entire ~2-3GB app extracts to `%TEMP%` on EVERY launch. First launch takes minutes.
**Why it happens:** The portable format is a self-extracting archive that unpacks each time.
**How to avoid:** Use per-user NSIS installer (`perMachine: false`) instead. Installs to `%LOCALAPPDATA%` without admin rights, only extracts once.
**Warning signs:** "Loading..." spinner for 2-5 minutes on every app start.

### Pitfall 5: Infrastructure Service Complexity
**What goes wrong:** Trying to bundle MongoDB, Redis, Elasticsearch, RabbitMQ, Conductor, MinIO, and Tika as portable services creates a 5GB+ bundle that needs 12GB+ RAM.
**Why it happens:** The current architecture was designed for Kubernetes, not single-machine portable deployment.
**How to avoid:** Simplify infrastructure BEFORE building the Electron shell. Replace MongoDB with H2/SQLite, remove Conductor (direct HTTP orchestration), replace MinIO with local filesystem, evaluate if Redis/Elasticsearch/RabbitMQ can be eliminated or replaced with in-process alternatives.
**Warning signs:** Total RAM usage exceeds 12GB, leaving insufficient headroom for the OS on 16GB machine.

### Pitfall 6: Python conda-pack Path Issues on Windows
**What goes wrong:** After extracting conda-pack archive, Python fails to import packages due to hardcoded path prefixes from the build machine.
**Why it happens:** Some packages store absolute paths during installation.
**How to avoid:** Always run `conda-unpack` (included script) after extraction. Build the env on a Windows x64 machine (not Linux/Mac). Test on a clean Windows machine before shipping.
**Warning signs:** `ImportError` or `ModuleNotFoundError` despite packages being present in site-packages.

### Pitfall 7: Long Windows Path Names
**What goes wrong:** Python packages with deep directory structures hit the 260-character Windows path limit.
**Why it happens:** Default Windows path limit + deep `site-packages` nesting.
**How to avoid:** Extract to a short path like `C:\blackbox\` rather than `C:\Users\username\Desktop\My Application\...`. Pre-compile `.pyc` files to reduce import overhead.
**Warning signs:** FileNotFoundError on packages with long names.
</common_pitfalls>

<code_examples>
## Code Examples

Verified patterns from official sources:

### Electron Main Process — Service Lifecycle
```javascript
// Source: Electron docs + Ostara case study pattern
const { app, BrowserWindow, ipcMain } = require('electron');
const { ProcessManager } = require('./processManager');
const path = require('path');

const pm = new ProcessManager();

app.whenReady().then(async () => {
  const resourcesPath = process.resourcesPath || path.join(__dirname, '..', 'resources');
  const javaPath = path.join(resourcesPath, 'runtime', 'java', 'bin', 'javaw.exe');
  const pythonPath = path.join(resourcesPath, 'runtime', 'python', 'python.exe');
  const jarPath = path.join(resourcesPath, 'app', 'blackbox.jar');

  // Start Spring Boot backend
  pm.startService('backend', javaPath, ['-jar', jarPath], {
    healthUrl: 'http://localhost:8081/actuator/health',
    autoRestart: true,
    env: { SERVER_PORT: '8081' }
  });

  // Start diarization service (optional, user-togglable)
  // pm.startService('diarization', pythonPath, ['-m', 'uvicorn', 'src.main:app', '--port', '8082'], { ... });

  const win = new BrowserWindow({ /* ... */ });
  win.loadFile('dist/index.html');
});

app.on('before-quit', async () => {
  await pm.stopAll();
});

// IPC: Frontend requests service toggle
ipcMain.handle('toggle-service', async (event, serviceName, enabled) => {
  if (enabled) {
    pm.startService(serviceName, /* ... */);
  } else {
    await pm.stopService(serviceName);
  }
});

// IPC: Frontend requests service status
ipcMain.handle('get-service-status', () => {
  return pm.getStatus(); // { backend: 'healthy', diarization: 'stopped', chat: 'stopped' }
});
```

### electron-builder Configuration
```yaml
# electron-builder.yml
# Source: electron-builder docs
appId: com.blackbox.wargaming
productName: Blackbox Wargaming
directories:
  output: dist-electron

win:
  target:
    - target: nsis
      arch: [x64]
  icon: build/icon.ico

nsis:
  oneClick: false
  perMachine: false          # Install to user's AppData, NO admin needed
  allowToChangeInstallationDirectory: true

extraResources:
  - from: resources/runtime/java
    to: runtime/java
    filter: ["**/*"]
  - from: resources/runtime/python
    to: runtime/python
    filter: ["**/*"]
  - from: resources/models
    to: models
    filter: ["**/*"]
  - from: resources/app
    to: app
    filter: ["**/*"]

asar: true
asarUnpack:
  - "**/*.node"              # Native modules must be outside asar
```

### TXT Export (trivial, no library needed)
```javascript
function exportTxt(transcript) {
  const lines = transcript.segments.map(seg =>
    `[${seg.timestamp}] ${seg.speaker}: ${seg.text}`
  );
  const blob = new Blob([lines.join('\n')], { type: 'text/plain;charset=utf-8' });
  saveAs(blob, 'transcript.txt');
}
```
</code_examples>

<sota_updates>
## State of the Art (2025-2026)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Docker Compose for local dev | Electron + portable runtimes for desktop apps | 2023+ | Docker requires admin on Windows; portable runtimes don't |
| PyInstaller for Python desktop | conda-pack for ML-heavy Python apps | 2024+ | Avoids AV false positives, handles complex dependency graphs |
| iText for Java PDF | OpenPDF (LGPL fork) or frontend pdfmake | 2024+ | iText AGPL licensing too restrictive; OpenPDF is business-friendly; frontend is simpler |
| Electron only choice for desktop | Tauri 2.0 as lighter alternative | 2024 | Tauri has sidecar support but requires Rust; Electron still better for multi-runtime orchestration |
| Full JDK bundling | jlink custom JRE | JDK 9+ | Reduces JRE from 335MB to 50-80MB |

**New tools/patterns to consider:**
- **Tauri 2.0 sidecar API:** First-class external binary management. Worth revisiting if Rust expertise is available.
- **python-build-standalone (Astral/indygreg):** Pre-built portable CPython for embedding. Alternative to conda-pack if finer control is needed.
- **Electron 34 utilityProcess improvements:** Better crash detection for Node.js child processes (but still doesn't help with Java/Python spawned processes).

**Deprecated/outdated:**
- **Docker Desktop for restricted Windows deployment:** Requires admin, WSL2, Hyper-V. Not viable for locked-down enterprise machines.
- **Podman as Docker Desktop replacement on restricted Windows:** Also requires admin for `podman machine init` and Hyper-V.
- **PyInstaller for large ML apps:** AV false positive rate makes it impractical for distribution to non-technical users.
- **cannon.js / custom physics:** Not relevant to this phase, but noting for completeness.
</sota_updates>

<infrastructure_analysis>
## Infrastructure Simplification Analysis

**This is the critical prerequisite for Phase 13.**

The current architecture requires 7 middleware services designed for Kubernetes deployment:

| Service | Current | RAM Usage | Portable Alternative | Effort |
|---------|---------|-----------|---------------------|--------|
| MongoDB | docker: mongo:latest | ~300-500MB | H2 Database (embedded, zero-config) or SQLite | HIGH — requires persistence layer rewrite |
| Redis | docker: redis:7-alpine | ~50-100MB | Caffeine (in-process Java cache) or remove | MEDIUM — Conductor dependency |
| Elasticsearch | docker: elasticsearch:7.17.11 | ~512MB+ | Remove (Conductor can use in-memory) | LOW-MEDIUM — Conductor config change |
| RabbitMQ | docker: rabbitmq:management | ~150-200MB | Remove if Conductor removed, or use in-memory queue | MEDIUM |
| Conductor | docker: conductor-standalone:3.15.0 | ~300-500MB | Replace with direct HTTP orchestration in Spring Boot | HIGH — workflow logic rewrite |
| MinIO | docker: minio/minio:latest | ~100-200MB | Local filesystem (already on local machine) | LOW — change storage config |
| Tika | docker: apache/tika:latest | ~200-300MB | Embedded Tika (tika-core Maven dependency) | LOW — add Maven dependency |

**Current total middleware RAM: ~1.6-2.3 GB**
**After simplification target: ~0 GB** (all embedded/in-process)

### Recommended Simplification Path

**Must simplify (RAM/complexity too high for portable):**
1. **Remove Conductor** → Implement pipeline orchestration directly in Spring Boot (sequential service calls). The workflow logic (SWITCH branching by mode) can be a simple service class.
2. **Replace MongoDB** → H2 embedded database. Spring Data JPA + H2 requires minimal code changes if repositories use Spring Data abstractions.
3. **Replace MinIO** → Local filesystem. Store files in a `data/` directory within the app bundle.
4. **Embed Tika** → Add `tika-core` Maven dependency instead of running as separate service.

**Can likely remove (no longer needed without Conductor):**
5. **Remove Redis** → Without Conductor, no external cache needed. Use Caffeine for any caching.
6. **Remove Elasticsearch** → Without Conductor, no search index needed.
7. **Remove RabbitMQ** → Without Conductor, no message broker needed.

### Impact Assessment
- Removing Conductor is the highest-impact change — it eliminates 5 of 7 infrastructure dependencies (Conductor + Redis + ES + RabbitMQ + their RAM)
- MongoDB → H2 is the second biggest change — requires repository/persistence layer adaptation
- MinIO → filesystem and Tika embedding are straightforward

### Open Question
How deeply is Conductor woven into the pipeline orchestration? If the SWITCH/branching logic is simple (which Phase 10-12 work suggests), replacing it with a Spring service class is feasible. If workflows are complex with retries, compensation, and long-running tasks, a lightweight embedded alternative (like a state machine) may be needed.
</infrastructure_analysis>

<open_questions>
## Open Questions

Things that couldn't be fully resolved:

1. **Can the organization's IT department code-sign the Electron exe?**
   - What we know: Unsigned executables trigger Windows SmartScreen warnings. Enterprise machines may have AppLocker/WDAC policies blocking unsigned apps.
   - What's unclear: Whether a BWI Authenticode certificate is available for signing.
   - Recommendation: Ask the user. If no signing is possible, IT must whitelist the installation folder. This is a deployment prerequisite, not a code issue.

2. **How deeply is Conductor embedded in the pipeline logic?**
   - What we know: Phases 10-12 built SWITCH-based workflow branching in Conductor. The PipelineModeResolver selects modes, and Conductor orchestrates the pipeline.
   - What's unclear: How many Conductor-specific features (retries, compensation, error handling) are relied upon.
   - Recommendation: Audit the Conductor workflow definitions and Spring Boot Conductor client code during planning. If it's primarily sequential calls with a SWITCH, direct Spring Boot orchestration is straightforward.

3. **Is the target Windows machine 64-bit with sufficient disk space?**
   - What we know: HP EliteBook 16GB RAM, enterprise Windows.
   - What's unclear: Available disk space (bundle will be ~2-4 GB), exact Windows version, whether enterprise policies restrict `%LOCALAPPDATA%` writes.
   - Recommendation: Verify during planning. The per-user NSIS installer writes to `%LOCALAPPDATA%\Programs\` which is almost always permitted.

4. **Should Ollama be bundled or remain external?**
   - What we know: Ollama is optional (chat/summarization). In classified mode, it's not used. When on secure network, user currently runs it separately.
   - What's unclear: Whether bundling Ollama (~1-4GB depending on model) is worth it or if it should remain a "connect if available" feature.
   - Recommendation: Keep Ollama external. The core experience (transcription + diarization) works without it. Bundling it would double the app size for an optional feature.

5. **MongoDB → H2: How much persistence layer rewrite is needed?**
   - What we know: The backend uses Spring Data with MongoDB. Spring Data JPA + H2 has a different API surface than Spring Data MongoDB.
   - What's unclear: How many MongoDB-specific features (document nesting, flexible schema) are used.
   - Recommendation: Audit repository interfaces and document models during planning. If they use basic CRUD with `MongoRepository`, migration is moderate. If they use aggregation pipelines or deeply nested documents, it's harder.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- Electron official docs — process model, utilityProcess API, app lifecycle, child_process
- electron-builder docs — Windows targets (portable, NSIS), extraResources, code signing
- Docker official docs — Windows permission requirements (confirms admin needed)
- Podman GitHub issues #22994, #25723 — confirms admin required for Windows
- Microsoft WSL docs — confirms admin required for WSL2 enablement
- Ostara project (dev.to/krud) — production Spring Boot + Electron case study with JDK bundling
- pdfmake npm docs — declarative PDF generation API (Context7 verified)
- docx npm docs — DOCX generation API (Context7 verified)
- conda-pack documentation — portable Python environment packaging

### Secondary (MEDIUM confidence)
- Tauri 2.0 sidecar docs — verified child process management API
- jlink/jdeps documentation — verified custom JRE creation for Spring Boot
- python-build-standalone (indygreg/astral-sh) — portable Python distributions
- OpenPDF GitHub — Java PDF generation (LGPL license verified)
- Apache POI docs — Java DOCX generation (Apache 2.0 license verified)
- ComfyUI Portable Windows — real-world example of portable Python + PyTorch on Windows

### Tertiary (LOW confidence - needs validation)
- Enterprise AppLocker/WDAC behavior with unsigned Electron apps — policy-dependent, needs testing on target machine
- MongoDB → H2 migration effort — depends on how MongoDB-specific the persistence layer is (needs code audit)
- Total RAM usage estimate — theoretical, needs measurement on target hardware
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: Electron for desktop app packaging + process management
- Ecosystem: jlink (portable JRE), conda-pack (portable Python), pdfmake/docx (export)
- Patterns: Process supervisor, health-check polling, frontend-only export
- Pitfalls: Admin rights, AV false positives, orphan processes, infrastructure complexity
- Infrastructure: Analysis of 7 middleware services and simplification path

**Confidence breakdown:**
- Standard stack: HIGH — Electron + electron-builder well-proven, Ostara case study validates pattern
- Architecture: HIGH — process supervisor pattern well-documented
- Infrastructure simplification: MEDIUM — path is clear but effort depends on code audit
- Pitfalls: HIGH — confirmed by multiple sources and Windows-specific documentation
- Code examples: MEDIUM-HIGH — patterns from docs and case studies, not yet tested in this project
- Export libraries: HIGH — pdfmake and docx verified via Context7 and npm

**Research date:** 2026-04-15
**Valid until:** 2026-05-15 (30 days — Electron/tooling ecosystem is stable)
</metadata>

---

*Phase: 13-one-click-services*
*Research completed: 2026-04-15*
*Ready for planning: yes*

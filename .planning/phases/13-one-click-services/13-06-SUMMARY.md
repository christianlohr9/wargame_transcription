---
phase: 13-one-click-services
plan: 06
subsystem: infra
tags: [jlink, conda-pack, portable-runtime, model-bundling, air-gapped]

requires:
  - phase: 13-one-click-services
    provides: Electron desktop shell with process supervisor and health polling
provides:
  - jlink custom JRE build script for portable Java runtime
  - conda-pack Python environment build script with CPU-only PyTorch
  - ML model bundling script for air-gapped deployment
  - ProcessManager runtime path resolution (bundled vs system)
affects: [13-07-packaging]

tech-stack:
  added: [jlink, conda-pack, huggingface-hub]
  patterns: [portable-runtime, model-bundling, runtime-path-resolution]

key-files:
  created:
    - blackbox-desktop/scripts/build-java-runtime.sh
    - blackbox-desktop/scripts/build-java-runtime.md
    - blackbox-desktop/scripts/build-python-runtime.sh
    - blackbox-desktop/scripts/build-python-runtime.md
    - blackbox-desktop/scripts/bundle-models.sh
    - blackbox-desktop/resources/runtime/java/.gitkeep
    - blackbox-desktop/resources/runtime/python/.gitkeep
    - blackbox-desktop/resources/app/.gitkeep
    - blackbox-desktop/resources/models/.gitkeep
  modified:
    - blackbox-desktop/electron/processManager.js

key-decisions:
  - "resolveRuntimePaths() fallback pattern — check fs.existsSync for bundled paths, fall back to system PATH"
  - "HF_HOME and WHISPER_CACHE env vars injected by processManager when bundled models exist"
  - "Known Spring Boot module set as jdeps fallback — fat JARs often break jdeps analysis"
  - "CPU-only PyTorch in conda-pack to keep package ~2-3GB vs ~5GB with CUDA"
  - "huggingface_hub snapshot_download with local_dir_use_symlinks=False for portable model copies"

patterns-established:
  - "Runtime path resolution: bundled runtime preferred, system fallback for dev mode"
  - "Per-service env injection: processManager sets env vars per service type"
  - "Platform-specific build scripts: must run on target OS (macOS for dev, Windows for prod)"

issues-created: []

duration: 15min
completed: 2026-04-15
---

# Phase 13, Plan 06: Portable Runtimes Summary

**Build scripts for jlink JRE, conda-pack Python, and ML model bundling enabling zero-install air-gapped deployment**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-15
- **Completed:** 2026-04-15
- **Tasks:** 2 auto
- **Files created:** 9
- **Files modified:** 1

## Accomplishments
- `build-java-runtime.sh`: Builds Spring Boot fat JAR via Maven, detects modules with jdeps (fallback to known Spring Boot set), generates minimal JRE via jlink, copies JAR to resources/app/
- `build-python-runtime.sh`: Creates conda env with Python 3.12, installs CPU-only PyTorch + all service dependencies, packs via conda-pack, extracts and runs conda-unpack, copies service source to resources/app/
- `bundle-models.sh`: Downloads faster-whisper large-v3-turbo and pyannote diarization models via huggingface_hub for offline use
- `resolveRuntimePaths()` in processManager.js: Detects bundled runtimes at startup, resolves command/cwd/env per service
- Service-specific env vars (HF_HOME, WHISPER_CACHE) injected when bundled models directory exists
- Resources directory structure with .gitkeep for git tracking

## Task Commits

Each task was committed atomically:

1. **Task 1: jlink JRE build script + processManager update** — `dd873d7` (feat)
2. **Task 2: conda-pack Python runtime + model bundling scripts** — `d7bcf93` (feat)

## Files Created/Modified
- `blackbox-desktop/scripts/build-java-runtime.sh` — jlink JRE build script (executable)
- `blackbox-desktop/scripts/build-java-runtime.md` — Java runtime build documentation
- `blackbox-desktop/scripts/build-python-runtime.sh` — conda-pack Python build script (executable)
- `blackbox-desktop/scripts/build-python-runtime.md` — Python runtime + model build documentation
- `blackbox-desktop/scripts/bundle-models.sh` — ML model download/bundling script (executable)
- `blackbox-desktop/resources/{runtime/java,runtime/python,app,models}/.gitkeep` — Directory placeholders
- `blackbox-desktop/electron/processManager.js` — Added resolveRuntimePaths(), per-service command/cwd/env resolution

## Decisions Made
- `resolveRuntimePaths()` checks `fs.existsSync` for bundled paths and falls back to system PATH — enables both dev (system tools) and prod (bundled) modes without config changes
- Known Spring Boot module set as jdeps fallback — fat JARs with nested classloader confuse jdeps
- CPU-only PyTorch keeps conda-pack output ~2-3GB instead of ~5GB with CUDA
- Model download uses `huggingface_hub.snapshot_download` with `local_dir_use_symlinks=False` for true file copies (no symlinks that break on Windows)
- HF_HOME and WHISPER_CACHE env vars set by processManager only when bundled models directory exists

## Deviations from Plan
None. Both tasks completed as specified.

## Next Phase Readiness
- All build scripts ready; must be run on Windows for production JRE/Python
- Plan 07 (packaging) will use electron-builder to create NSIS installer
- Resources directory structure matches RESEARCH.md architecture pattern
- processManager seamlessly uses bundled or system runtimes

---
*Phase: 13-one-click-services*
*Completed: 2026-04-15*

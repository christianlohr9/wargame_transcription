# Phase 13: One-Click Services - Context

**Gathered:** 2026-04-15
**Status:** Ready for research

<vision>
## How This Should Work

The user receives the repo and can start the entire platform with a single action — ideally a double-click on an .exe/.app file or launching an Electron-style desktop app. No terminal, no command line, no technical setup.

Once started, everything lives in the frontend. The user sees which services are running, can toggle optional services (diarization, chat) on and off, and gets clear feedback when something goes wrong — including actionable tips ("Restart the app" rather than stack traces).

The platform must work fully offline. The primary use case involves VS-NfD (classified) wargame recordings that cannot leave the device. All models, services, and dependencies must be bundled and run locally on the HP EliteBook. LLM summarization (Ollama) is optional — in offline/classified mode, transcription + diarization is the core experience.

Transcript export is available in multiple formats (PDF, TXT, DOCX etc.) directly from the UI.

The target user is minimally technical — can unzip a folder and double-click a file, but doesn't use terminals or know what Docker is.

</vision>

<essential>
## What Must Be Nailed

- **Zero-terminal experience** — The user never sees a terminal, console, or command line. Everything happens through the UI.
- **One-click start** — A single action (double-click or app launch) boots the entire platform.
- **Service control in UI** — Frontend shows which services are running with the ability to toggle diarization/chat on and off.
- **Actionable error messages** — When something fails, the user gets a clear, non-technical message with a concrete next step.
- **Full offline capability** — Must work without any network connection for VS-NfD classified material.
- **Multi-format transcript export** — Download transcripts as PDF, TXT, DOCX etc.

</essential>

<boundaries>
## What's Out of Scope

- Multi-user / authentication — this is a local single-user tool
- Auto-updates — new versions are delivered manually
- Cloud deployment — runs only locally on the user's device
- Cross-platform support — optimized specifically for the HP EliteBook (16GB RAM, Windows)
- LLM requirement in offline mode — Ollama/chat is optional, transcription + diarization is the core offline experience

</boundaries>

<specifics>
## Specific Ideas

- Electron-style desktop app preferred if IT department approves it (needs to be checked)
- Fallback: portable .exe/.bat that starts everything without admin rights
- Enterprise environment with VPN — no admin rights available for installation
- Docker Desktop may require admin rights — needs research during planning
- No specific UI/UX references — should be simple and clear, whatever works best

</specifics>

<notes>
## Additional Context

The primary use case is analyzing VS-NfD (Verschlusssache - Nur fuer den Dienstgebrauch) classified wargame recordings. This has major implications:
- All data must stay on the device — no network calls, no telemetry, no external dependencies at runtime
- Models must be pre-bundled (Whisper, pyannote) so nothing is downloaded at first launch
- The Ollama/LLM feature is a nice-to-have when the user is on the secure network, but the core experience (transcription + diarization) must work fully air-gapped
- The user works in a German military/defense context with strict IT policies

The user will hand this tool to colleagues who are minimally technical. The "product" is the repo/package itself — it needs to feel like a finished application, not a development project.

</notes>

---

*Phase: 13-one-click-services*
*Context gathered: 2026-04-15*

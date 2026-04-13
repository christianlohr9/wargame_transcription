# Phase 10: Modular Pipeline - Context

**Gathered:** 2026-04-13
**Status:** Ready for research

<vision>
## How This Should Work

The system should be smart about what it can do. At startup, it checks the machine's available RAM and recommends a pipeline mode — transcription-only for constrained machines, full pipeline when resources allow. Then health checks confirm what services actually started successfully, and the pipeline adapts to what's really available.

Config sets the intent (with auto-detect as the default), but you can override to force a specific mode. If you configure full pipeline but diarization isn't running, the system warns you and proceeds with what's available — transcription still works, you just don't get speaker labels.

When running transcription-only, the experience should feel streamlined and fast — skip unnecessary steps, get results quicker. It shouldn't feel like the full pipeline with pieces missing; it should feel like a lighter, purpose-built mode.

Two layers of awareness: RAM-based recommendations at startup tell you what mode makes sense for your hardware, then service health checks confirm what's actually running and build the workflow from that reality.

</vision>

<essential>
## What Must Be Nailed

- **Transcription works standalone** — This is the core use case for 16GB machines. Transcription must work perfectly on its own without diarization or chat services running. No dependencies on optional services.
- **Auto-detect with override** — The system auto-detects resources and available services to pick the best mode, but allows manual override via config when you want to force a specific mode.
- **Warn and proceed** — When configured services aren't available, warn the user clearly but continue with what's running. Never silently drop capabilities, never block on missing optional services.

</essential>

<boundaries>
## What's Out of Scope

- UI changes — that's Phase 11 (Frontend Adaptation)
- New pipeline modes beyond the three (transcription-only, transcription+diarization, full pipeline) — stick to these three
- Runtime hot-swapping is not excluded — config can be set however makes sense
- Performance tuning is not excluded — if streamlining naturally improves performance, that's fine

</boundaries>

<specifics>
## Specific Ideas

- RAM-based mode recommendations at startup (e.g., under 8GB = transcription-only suggestion)
- Service health checks as second layer confirming what's actually running
- Transcription-only mode should feel lighter and faster, not just "full pipeline minus features"
- Conductor workflow adapts automatically based on detected mode
- Warnings when configured services are unavailable (not silent failures, not blocking errors)

</specifics>

<notes>
## Additional Context

The user envisions the platform as self-aware about its environment. The ideal is a system that "just works" on whatever hardware it's on — detects what's possible, recommends the right mode, and adapts gracefully. Manual config is a safety valve, not the primary interface.

This directly serves the v2.0 goal of making the platform usable on resource-constrained machines. The 16GB EliteBook should get a great transcription-only experience without needing to know or care about diarization and chat services.

</notes>

---

*Phase: 10-modular-pipeline*
*Context gathered: 2026-04-13*

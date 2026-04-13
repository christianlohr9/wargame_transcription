# Phase 11: Frontend Adaptation - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<vision>
## How This Should Work

The frontend should adapt cleanly to whatever pipeline mode was used. If a file was processed with transcription-only, the user sees a transcript — no empty tabs, no broken sections, no hint that something is "missing." It should feel like a complete, intentional experience regardless of mode.

Results views hide sections that don't have data. No speaker labels tab without diarization, no summary tab without LLM. The UI only renders what's actually there — clean and minimal.

Separately from the results view, there should be a subtle way for the user to see what services are running and what capabilities the platform currently has. This isn't in-your-face — it's a status area or settings-adjacent view that lets the user feel in control of their platform. They should know what's possible, not just what happened.

</vision>

<essential>
## What Must Be Nailed

- **Service visibility** — The user should feel in control and know what their platform can do right now. Knowing what's running/available is the core of this phase.
- **No broken UI** — Nothing should look broken, empty, or confused when services are off. Every mode should feel like a complete, intentional experience.
- **Clean adaptation** — Results views show only what's available, with no ghost tabs or greyed-out placeholders.

</essential>

<boundaries>
## What's Out of Scope

- Mobile/responsive design — desktop only for this phase
- No other explicit exclusions — service toggling and re-processing from the UI are fair game if they fit naturally

</boundaries>

<specifics>
## Specific Ideas

- Results view: hide sections entirely when data isn't available (not greyed out, not disabled — gone)
- Service status: subtle nudge somewhere outside the results view (settings area, status indicator) — open to whatever fits the current UI
- Each result doesn't need mode badges or labels — the absence of sections speaks for itself

</specifics>

<notes>
## Additional Context

The backend (Phase 10) already supports three pipeline modes: transcription-only, transcription+diarization, and full pipeline. The frontend needs to understand which mode produced a given result and render accordingly.

User wants the platform to feel personal and in-control — service visibility is about empowerment, not monitoring.

</notes>

---

*Phase: 11-frontend-adaptation*
*Context gathered: 2026-04-13*

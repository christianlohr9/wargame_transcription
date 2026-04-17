# Phase 14: Guppy LLM Integration - Context

**Gathered:** 2026-04-17
**Status:** Ready for research

<vision>
## How This Should Work

The app supports two LLM backends: Ollama (for GPU-equipped machines) and Guppy (https://github.com/arman-bd/guppylm) for CPU-only environments. On first launch, the user picks which backend to use — the app can suggest a default based on what it detects, but the user confirms. After that, the choice lives in settings where it can be changed anytime.

When a transcription completes, summary generation kicks off automatically in the background. The user sees their transcript immediately and can work with it while summaries generate. A persistent progress indicator keeps the user informed of what's happening — they should never wonder "what's going on now?" When the summary is ready, a toast notification lets them know it's available.

Guppy ships bundled inside the Electron installer so it works on fully air-gapped machines with zero downloads. The full pipeline (transcribe -> diarize -> summarize) finally works end-to-end offline.

Both backends are always available. The app recommends one based on hardware detection, but the user can override in settings at any time.

</vision>

<essential>
## What Must Be Nailed

- **Full pipeline works offline** — The core win is that transcribe -> diarize -> summarize works end-to-end on an air-gapped CPU-only machine with no external server
- **User always knows what's happening** — Persistent progress visibility during summary generation, toast when complete. The user should never ask themselves "what's going on?"
- **Bundled in installer** — Guppy model files ship inside the NSIS installer for true zero-config air-gapped deployment

</essential>

<boundaries>
## What's Out of Scope

- Fine-tuning or custom models — use Guppy as-is for summarization
- Interactive chat/conversation UI with the LLM — just automated summary generation
- GPU optimization work — Guppy is the CPU path, Ollama handles GPU
- Multiple model sizes — ship one good model

</boundaries>

<specifics>
## Specific Ideas

- First-run setup asks user to pick LLM backend (Ollama or Guppy), with auto-detected recommendation
- Settings toggle to switch between Ollama and Guppy at any time
- Background summary generation — user views transcript immediately, summaries appear when ready
- Persistent progress indicator during generation (not just a spinner — show real progress/state)
- Toast notification when summary is complete
- Same summary output format regardless of which backend generates it

</specifics>

<notes>
## Additional Context

User has a strong UX principle: the user should always be aware of what's happening in the app at all times. Every background process should have visible status. This applies broadly, not just to LLM summaries.

Guppy is a lightweight LLM designed for CPU environments. Performance expectations are relaxed — background processing means users aren't blocked waiting. Something is better than nothing on CPU-only machines.

The existing chat service was built for Ollama but never fully validated (Ollama was unavailable during v2.0 testing). This phase adds Guppy as a second backend and validates both paths.

</notes>

---

*Phase: 14-guppy-llm-integration*
*Context gathered: 2026-04-17*

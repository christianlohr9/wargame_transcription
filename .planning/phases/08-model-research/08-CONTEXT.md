# Phase 8: Model Research - Context

**Gathered:** 2026-04-13
**Status:** Ready for research

<vision>
## How This Should Work

A systematic benchmark shootout — test each model candidate on the EliteBook hardware and walk away with clear winners. The big question is whether Voxtral can handle both transcription AND diarization in one model, which would simplify the entire pipeline.

The approach: run real benchmarks, measure speed, accuracy, and memory usage, and produce a recommendation report with clear reasoning for why one model beats another for this specific use case.

Testing should use both standard benchmarks (LibriSpeech etc.) for comparable numbers AND real wargame recordings to verify models work on actual platform audio.

</vision>

<essential>
## What Must Be Nailed

- **Clear winner per task** — End this phase with a definitive "use THIS for transcription, use THAT for diarization" (or "use THIS for both"). No ambiguity going into Phase 9.
- **Balanced evaluation** — Speed, accuracy, and memory efficiency all matter equally. No single metric dominates — find the best overall tradeoff for 16GB CPU-only hardware.
- **Simplicity vs specialization tradeoff** — If Voxtral (or another all-in-one model) is close in quality to specialized models, the simpler pipeline wins. Only keep separate models if one is *significantly* better at its job.

</essential>

<boundaries>
## What's Out of Scope

- No integration into the codebase — research and benchmarks only, model swaps happen in Phase 9
- No cloud/API models — everything must run fully local, no external dependencies
- GPU paths not prioritized — this platform is CPU-only on 16GB RAM (GPU results are bonus info, not decision drivers)

</boundaries>

<specifics>
## Specific Ideas

- **Voxtral is the headline candidate** — particularly interesting for its all-in-one potential (transcription + diarization in a single model), which could dramatically simplify the pipeline
- Whisper variants to test: distil-whisper, whisper.cpp, faster-whisper
- CPU-optimized diarization alternatives to pyannote
- Nothing ruled out — open to testing anything that runs locally on CPU
- Deliverable should be a recommendation report with reasoning, not just raw numbers

</specifics>

<notes>
## Additional Context

The user wants thoroughness — don't rush to conclusions, make sure the landscape is properly surveyed. The current stack is WhisperX + pyannote, so that's the baseline to beat.

The key decision framework: prefer pipeline simplicity (fewer models/services) unless a specialized model is significantly better at one task. "Slightly better" doesn't justify two models when one can do both.

</notes>

---

*Phase: 08-model-research*
*Context gathered: 2026-04-13*

# Phase 9: Model Integration - Context

**Gathered:** 2026-04-13
**Status:** Ready for research

<vision>
## How This Should Work

Before committing to the hybrid pipeline (faster-whisper + pyannote + WhisperX alignment), evaluate Voxtral as a potential all-in-one solution. The dream is a single model that handles both transcription AND speaker diarization in one pass — eliminating the complexity of stitching together three separate tools.

The phase has two halves: first, research Voxtral thoroughly (full benchmarks including diarization capability), then integrate whichever approach wins into the existing pipeline. Both halves matter equally — good research prevents rework, but research without shipping is wasted effort.

If Voxtral can't run on 16GB CPU, try quantized variants (GGUF etc.) before giving up. If it still doesn't work or doesn't beat distil-large-v3, pivot to the proven hybrid pipeline without lingering.

</vision>

<essential>
## What Must Be Nailed

- **Voxtral evaluation before any integration work** — answer the open question from Phase 8 before building on assumptions
- **Full benchmark with diarization test** — same rigor as Phase 8 benchmarks, plus test whether Voxtral handles speaker separation natively
- **Clear decision, then ship it** — research and integration are both essential. Pick the winning approach, then actually swap it into the running pipeline

</essential>

<boundaries>
## What's Out of Scope

- No pipeline toggling or service configuration — making services optional is Phase 10
- No frontend changes — UI adaptation is Phase 11
- Phase 9 is purely model research + backend integration

</boundaries>

<specifics>
## Specific Ideas

- The main draw of Voxtral is all-in-one: if it can transcribe AND diarize in a single pass, the hybrid pipeline complexity disappears entirely
- If Voxtral can't do diarization natively, it must beat distil-large-v3 on transcription to be worth adopting — otherwise stick with the hybrid
- CPU feasibility is a real concern — Mistral-family models are typically LLM-sized (7B+), which could be brutal on 16GB CPU-only
- If full Voxtral is too heavy, try quantized versions before dismissing it
- Fallback is the already-proven hybrid pipeline: faster-whisper distil-large-v3 (int8) + pyannote 3.1 + WhisperX alignment

</specifics>

<notes>
## Additional Context

Phase 8 deferred Voxtral evaluation because it's a different model class needing separate tooling. The user wants that gap closed before building. The hybrid pipeline recommendation from Phase 8 remains the proven fallback — it's benchmarked and ready to implement if Voxtral doesn't pan out.

Priority ordering: Voxtral all-in-one > Voxtral transcription-only (if it beats distil-large-v3) > hybrid pipeline fallback.

</notes>

---

*Phase: 09-model-integration*
*Context gathered: 2026-04-13*

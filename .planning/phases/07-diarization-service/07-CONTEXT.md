# Phase 7: Diarization Service - Context

**Gathered:** 2026-01-25
**Status:** Ready for research

<vision>
## How This Should Work

The local diarization service should behave exactly like the cloud version did with AssemblyAI — just using WhisperX + pyannote under the hood instead. When a user uploads audio, the full pipeline should run: diarization produces speaker-labeled transcript, which feeds into summarization, which generates insights, and all of this displays in the frontend.

Right now transcription works but speakers aren't named and summarization doesn't appear. The data pipeline is incomplete somewhere between diarization output and frontend display.

</vision>

<essential>
## What Must Be Nailed

- **Full analysis view in frontend** — Transcript with named speakers, summary, AND AI-generated insights all displaying correctly
- **Output format parity** — WhisperX/pyannote output must match what the rest of the pipeline expects (same format as AssemblyAI produced)
- **End-to-end flow** — Can't ship partial. All pieces need to work together.

</essential>

<boundaries>
## What's Out of Scope

- Performance optimization — if it works but is slow, that's acceptable for now
- Speaker naming UI — users manually renaming "Speaker 1" to "John" is a future feature
- New features beyond what the cloud version had

</boundaries>

<specifics>
## Specific Ideas

- Systematic trace approach: start from diarization output, follow data through each layer (backend processing, API responses, frontend components) to identify where the chain breaks
- First step is verification: check MongoDB/API responses to confirm whether data exists before assuming it's a frontend display issue
- Goal is drop-in compatibility with AssemblyAI's output format so existing downstream processing just works

</specifics>

<notes>
## Additional Context

User suspects the issue is in frontend display (data might be there but not rendering), but hasn't verified this yet. The diagnosis phase should confirm where data actually stops flowing before fixing.

This phase is about completing/debugging existing functionality, not building new architecture.

</notes>

---

*Phase: 07-diarization-service*
*Context gathered: 2026-01-25*

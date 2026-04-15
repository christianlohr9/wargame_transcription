# Phase 12: Integration Testing - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<vision>
## How This Should Work

This is a fix-as-you-go validation phase. Start the services, run real audio through each pipeline mode, and fix whatever breaks. The testing IS the debugging.

The approach is incremental — start with transcription-only (fewest dependencies), then add diarization, then full pipeline. Build confidence layer by layer, validating each service addition before moving to the next.

The goal isn't just "it works" — it's "it's solid enough to containerize." Everything discovered and fixed here should mean Phase 13 (Docker) goes smoothly with no hidden env quirks or fragile paths.

</vision>

<essential>
## What Must Be Nailed

- **Graceful mode transitions** — The pipeline correctly detects what's available and degrades gracefully. No crashes when a service is missing, no silent failures.
- **Clear user messaging about WHY** — The user must always understand why they're getting a particular mode. Not just "transcription only" but "No GPU detected — using transcription only" or "Diarization service not running — speaker labels unavailable." The reason matters as much as the state.
- **Upfront notification** — Before processing starts, the user sees what's available and why, and can choose to proceed or wait.

</essential>

<boundaries>
## What's Out of Scope

- Performance optimization — not tuning for speed or memory, just verifying correctness
- Automated test suites — no JUnit/pytest automation, this is manual validation and fixing
- New audio samples — using existing files from v1.0 testing
- New features — purely validation and bug fixes

</boundaries>

<specifics>
## Specific Ideas

- User-facing messages should explain the cause, not just the state (e.g., "No GPU detected" not just "GPU unavailable")
- Test in order: transcription-only -> transcription+diarization -> full pipeline
- Validate that Phase 11's status UI accurately reflects service availability
- Ensure the system is Docker-ready — no hardcoded paths, env-dependent behavior is documented

</specifics>

<notes>
## Additional Context

This is the last validation gate before containerization in Phase 13. The bar is "confident enough that Docker won't surface surprises." Previous phases introduced several runtime quirks (Windows line endings in .env, JDK version sensitivity, lazy-loaded models) — this phase should verify those are all resolved.

The user's core concern is transparency: the platform should never leave users wondering why they got a particular pipeline mode.

</notes>

---

*Phase: 12-integration-testing*
*Context gathered: 2026-04-14*

# Roadmap: Blackbox AI Local Setup

## Overview

Transform the Kubernetes-deployed Blackbox AI wargaming platform into a fully local stack running on an HP EliteBook (16GB RAM) without external API dependencies. The major work is replacing AssemblyAI with WhisperX + pyannote for speaker diarization, and configuring chat to use a remote Ollama server.

## Milestones

- ✅ **v1.0 Local Wargame Analysis** — Phases 1-7 (shipped 2026-01-25)
- 🚧 **v2.0 Modular CPU-Only Platform** — Phases 8-12 (in progress)

## Completed Milestones

- ✅ [v1.0 Local Wargame Analysis](milestones/v1.0-ROADMAP.md) (Phases 1-7) — SHIPPED 2026-01-25

<details>
<summary>✅ v1.0 Local Wargame Analysis (Phases 1-7) — SHIPPED 2026-01-25</summary>

- [x] Phase 1: Infrastructure (2/2 plans) — completed 2026-01-22
- [x] Phase 2: Backend Setup (1/1 plan) — completed 2026-01-22
- [x] Phase 3: Diarization Rewrite (3/3 plans) — completed 2026-01-22
- [x] Phase 4: Chat Service (1/1 plan) — completed 2026-01-22
- [x] Phase 5: Frontend Setup (1/1 plan) — completed 2026-01-22
- [x] Phase 6: Integration Testing (1/1 plan) — completed 2026-01-25
- [x] Phase 7: Diarization Service (1/1 plan) — completed 2026-01-25

</details>

### 🚧 v2.0 Modular CPU-Only Platform (In Progress)

**Milestone Goal:** Make the platform modular — transcription works standalone on 16GB CPU, with diarization and LLM summaries as optional add-ons. Research and integrate better/lighter models for CPU-only use.

#### Phase 8: Model Research

**Goal**: Research Voxtral, lighter Whisper variants (distil-whisper, whisper.cpp, faster-whisper), and CPU-optimized diarization alternatives. Evaluate CPU performance, accuracy, and local deployment feasibility.
**Depends on**: v1.0 complete
**Research**: Likely (new models, fast-moving ecosystem)
**Research topics**: Voxtral capabilities and local deployment, Whisper model variants for CPU, faster-whisper vs WhisperX, CPU-optimized diarization options
**Plans**: TBD

Plans:
- [x] 08-01: Transcription benchmarks (3 candidates evaluated)
- [x] 08-02: Diarization benchmarks & recommendations (pyannote retained, hybrid pipeline recommended)

#### Phase 9: Model Integration

**Goal**: Swap in better models identified during research — replace or add alternatives to current WhisperX + pyannote setup based on findings.
**Depends on**: Phase 8
**Research**: Likely (integrating new libraries/models)
**Research topics**: Integration patterns for chosen models, dependency management, configuration for model selection
**Plans**: TBD

Plans:
- [x] 09-01: Hybrid pipeline integration (distil-large-v3.5 + pyannote + WhisperX alignment)

#### Phase 10: Modular Pipeline

**Goal**: Backend config to toggle diarization and chat services on/off. Conductor workflow adapts automatically — supports transcription-only, transcription+diarization, or full pipeline modes. Health checks detect what's running.
**Depends on**: Phase 9
**Research**: Unlikely (existing Conductor and Spring Boot patterns)
**Plans**: TBD

Plans:
- [ ] 10-01: TBD (run /gsd:plan-phase 10 to break down)

#### Phase 11: Frontend Adaptation

**Goal**: UI gracefully handles missing data — no summary tab without LLM, no speaker labels without diarization. Service status visible to user.
**Depends on**: Phase 10
**Research**: Unlikely (existing Vue/Quasar patterns)
**Plans**: TBD

Plans:
- [ ] 11-01: TBD (run /gsd:plan-phase 11 to break down)

#### Phase 12: Integration Testing

**Goal**: End-to-end validation of all three pipeline modes (transcription-only, transcription+diarization, full) on 16GB CPU-only hardware.
**Depends on**: Phase 11
**Research**: Unlikely (established testing patterns)
**Plans**: TBD

Plans:
- [ ] 12-01: TBD (run /gsd:plan-phase 12 to break down)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Infrastructure | v1.0 | 2/2 | Complete | 2026-01-22 |
| 2. Backend Setup | v1.0 | 1/1 | Complete | 2026-01-22 |
| 3. Diarization Rewrite | v1.0 | 3/3 | Complete | 2026-01-22 |
| 4. Chat Service | v1.0 | 1/1 | Complete | 2026-01-22 |
| 5. Frontend Setup | v1.0 | 1/1 | Complete | 2026-01-22 |
| 6. Integration Testing | v1.0 | 1/1 | Complete | 2026-01-25 |
| 7. Diarization Service | v1.0 | 1/1 | Complete | 2026-01-25 |
| 8. Model Research | v2.0 | 2/2 | Complete | 2026-04-13 |
| 9. Model Integration | v2.0 | 1/1 | Complete | 2026-04-13 |
| 10. Modular Pipeline | v2.0 | 0/? | Not started | - |
| 11. Frontend Adaptation | v2.0 | 0/? | Not started | - |
| 12. Integration Testing | v2.0 | 0/? | Not started | - |

**Total: 12 phases, 10 complete + 5 new**

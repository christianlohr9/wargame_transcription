# Codebase Concerns

**Analysis Date:** 2026-01-22

## Tech Debt

**Process Management Inefficiency:**
- Issue: Conductor TaskHandler creates new process per task
- Files: `ask-chat-service/src/lifecycle.py:39`, `speaker-diarization-service/src/lifecycle.py:39`
- Why: Quick implementation using default TaskHandler
- Impact: Resource-intensive, slower task execution
- Fix approach: Implement custom handler that reuses processes (TODO already in code)

**Hardcoded API Endpoint:**
- Issue: Frontend API base URL hardcoded instead of using environment variable
- File: `blackbox/frontend/src/boot/axios.ts:12` - `http://blackbox.dev.bwi.com/`
- Why: Quick development setup
- Impact: Cannot easily switch environments, deployment inflexibility
- Fix approach: Use `process.env` or Quasar env variables

**Large Complex Components:**
- Issue: Vue components exceeding single responsibility
- Files: `blackbox/frontend/src/components/TranscriptBox.vue` (456 lines), `blackbox/frontend/src/components/AnalIntelligence.vue` (325 lines)
- Why: Feature accumulation without refactoring
- Impact: Hard to maintain, test, and modify
- Fix approach: Extract sub-components, separate concerns

## Known Bugs

**No Critical Bugs Identified**
- Codebase appears to be in early/active development
- Functional issues likely exist but not explicitly documented

## Security Considerations

**SSL Verification Bypass:**
- Risk: HTTP requests can disable SSL verification
- File: `speaker-diarization-service/src/services/http_file_service.py:18` - `verify=not _get_insecure_setting()`
- Current mitigation: Controlled via `HTTP_FILE_SERVICE_INSECURE` env var
- Recommendations: Remove bypass option, enforce SSL in production

**Missing Input Validation:**
- Risk: File uploads not fully validated
- Files: `speaker-diarization-service/src/api/diarization_api.py:25`, `blackbox/frontend/src/components/WargameSetupDialog.vue:45`
- Current mitigation: MIME type check for audio only
- Recommendations: Add file size limits, virus scanning, type validation

**Unvalidated Response Schema:**
- Risk: Arbitrary response_schema dict accepted without validation
- File: `ask-chat-service/src/tasks/ask_chat_task.py:49`
- Current mitigation: None
- Recommendations: Validate schema structure before LLM call

## Performance Bottlenecks

**Synchronous NLP Processing:**
- Problem: TF-IDF and POS tagging computed in main thread during render
- File: `blackbox/frontend/src/components/TranscriptBox.vue:347-420`
- Measurement: Not profiled, potential UI blocking
- Cause: Complex computation in Vue component
- Improvement path: Move to Web Worker or compute on backend

**SSE Connection Management:**
- Problem: No connection pooling, reconnection every 5 seconds on error
- File: `blackbox/frontend/src/boot/serverSentEvents.ts:13-18`
- Measurement: Not profiled
- Cause: Simple reconnection logic
- Improvement path: Implement exponential backoff, connection pooling

**No Pagination:**
- Problem: Loads all wargame setups on mount without pagination
- File: `blackbox/frontend/src/components/WargameSetupDialog.vue:141-148`
- Measurement: Not profiled
- Cause: Initial implementation
- Improvement path: Add pagination or virtual scrolling

## Fragile Areas

**JSON Parsing Without Error Handling:**
- Why fragile: `JSON.parse()` on SSE data without try/catch
- File: `blackbox/frontend/src/boot/serverSentEvents.ts:20-25`
- Common failures: Malformed SSE data crashes handler
- Safe modification: Wrap in try/catch, validate before parsing
- Test coverage: None

**Silent Error Handling in Chat Services:**
- Why fragile: JSON decode errors silently ignored, returns raw string
- Files: `ask-chat-service/src/services/openai_chat_service.py:56-59`, `ask-chat-service/src/services/ollama_chat_service.py:36-40`
- Common failures: Caller receives unexpected format
- Safe modification: Propagate parsing errors or use Result type
- Test coverage: None

**Broad Exception Catching:**
- Why fragile: Tasks catch all exceptions, truncate to 512 chars
- Files: `ask-chat-service/src/tasks/ask_chat_task.py:29-31`, `speaker-diarization-service/src/tasks/diarization_task.py:28-33`
- Common failures: Important error context lost
- Safe modification: Log full error, return meaningful error info
- Test coverage: None

## Missing Error Handling

**API Endpoints Without Try/Catch:**
- Files:
  - `speaker-diarization-service/src/api/diarization_api.py:30`
  - `ask-chat-service/src/api/ask_chat_api.py:20-22`
- Risk: Unhandled exceptions return 500 without useful info
- Recommendations: Add try/catch, return structured error responses

**File Upload Error Handling:**
- File: `blackbox/frontend/src/components/TranscriptBox.vue:296-304`
- Risk: Uses `.then().finally()` with only console.error
- Recommendations: Show user feedback, implement retry logic

**File Processing Without Timeout:**
- File: `blackbox/frontend/src/components/TranscriptBox.vue:273-278`
- Risk: No timeout or cancellation mechanism
- Recommendations: Add timeout, allow user cancellation

## Test Coverage Gaps

**Frontend Testing:**
- What's not tested: Entire frontend codebase
- Risk: UI regressions, component interactions
- Priority: High
- Difficulty: Need to set up Vitest + Vue Test Utils

**Python Service Testing:**
- What's not tested: All Python services
- Risk: API contract violations, service logic errors
- Priority: High
- Difficulty: Need to add pytest, mock external services

**Integration Testing:**
- What's not tested: End-to-end workflows (upload → diarization → analysis)
- Risk: Service integration failures
- Priority: Medium
- Difficulty: Requires test environment with all services

## Dependencies at Risk

**Unpinned Versions:**
- Risk: `^` version ranges in `package.json` can introduce breaking changes
- File: `blackbox/frontend/package.json`
- Impact: Build failures, runtime errors
- Migration plan: Pin exact versions, use lockfile

**No Hash Verification:**
- Risk: Python dependencies not hash-verified
- Files: `ask-chat-service/requirements.txt`, `speaker-diarization-service/requirements.txt`
- Impact: Supply chain attacks possible
- Migration plan: Add hashes via pip-compile

## Missing Critical Features

**No Authentication:**
- Problem: No auth system implemented
- Current workaround: Development mode, open access
- Blocks: Production deployment, multi-user support
- Implementation complexity: Medium (add Spring Security, JWT)

**No Centralized Logging:**
- Problem: Logs scattered across services
- Current workaround: Docker logs
- Blocks: Production debugging, monitoring
- Implementation complexity: Low (add log aggregation)

---

*Concerns audit: 2026-01-22*
*Update as issues are fixed or new ones discovered*

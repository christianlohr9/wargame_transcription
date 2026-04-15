# Phase 10: Modular Pipeline - Research

**Researched:** 2026-04-13
**Domain:** Netflix Conductor conditional workflows + Spring Boot service configuration
**Confidence:** HIGH

<research_summary>
## Summary

Researched how to make the existing Conductor workflow adaptive based on available services and system resources. The current workflow is a flat 9-task sequence — all tasks required, no branching. Phase 10 needs three pipeline modes: transcription-only, transcription+diarization, and full pipeline.

**Key finding:** Conductor natively supports SWITCH tasks for conditional branching and `optional: true` on task definitions for graceful failure handling. The recommended approach is a single workflow with a SWITCH task that branches based on a `pipeline_mode` input parameter, rather than maintaining three separate workflow definitions. The mode is determined at workflow trigger time by a startup-time health check + config resolution in the Spring Boot backend.

**Primary recommendation:** Add a `pipeline_mode` workflow input parameter. Use a SWITCH task after transcription to branch into mode-specific task sequences. Backend determines mode at startup via config + service health checks, passes it when triggering the workflow.
</research_summary>

<standard_stack>
## Standard Stack

No new libraries needed. This phase uses existing infrastructure:

### Core (Already in Project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| conductor-oss | 3.15.0 | Workflow orchestration | Already deployed, has SWITCH/conditional support |
| Spring Boot | 3.x | Backend framework | Already the backend, has Actuator for health |
| conductor-client | 4.0.20 | Java Conductor SDK | Already used for workflow/task management |
| conductor-python | 1.2.3 | Python Conductor SDK | Already used in diarization service |

### Supporting (May Need to Add)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| spring-boot-actuator | (matches Spring Boot) | Health endpoints, system info | For structured health checks of backend itself |
| psutil | 7.x | Python system resource detection | RAM detection in diarization service startup |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Single workflow + SWITCH | Three separate workflows | Separate workflows are simpler but harder to maintain, version, and evolve |
| SWITCH branching | `optional: true` on all LLM tasks | Optional tasks still execute and fail — SWITCH skips entirely, cleaner |
| Config-based mode | Runtime dynamic detection only | Pure dynamic is fragile; config with auto-detect fallback is more predictable |

**Installation:**
```bash
# Spring Boot Actuator (if not already present)
# Add to build.gradle or pom.xml:
# implementation 'org.springframework.boot:spring-boot-starter-actuator'

# Python psutil (for RAM detection in diarization service)
pip install psutil
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Architecture: Two-Layer Mode Detection

```
Layer 1: Startup Config Resolution
├── Read PIPELINE_MODE env var (auto/transcription-only/transcription-diarization/full)
├── If "auto": check system RAM → recommend mode
├── Log recommended mode
└── Store resolved mode in app config

Layer 2: Runtime Service Health
├── Before triggering workflow, check service health endpoints
├── /health on diarization service (port 8082)
├── /health on ask-chat service (port 8083)
├── If configured services unavailable: warn + downgrade mode
└── Pass final mode as workflow input parameter
```

### Pattern 1: SWITCH Task for Pipeline Branching
**What:** Use Conductor's native SWITCH task to branch after transcription based on pipeline mode
**When to use:** When the workflow needs different task sequences based on a runtime condition
**Example:**
```json
{
  "name": "pipeline_mode_switch",
  "taskReferenceName": "pipeline_mode_switch_ref",
  "type": "SWITCH",
  "inputParameters": {
    "switchCaseValue": "${workflow.input.pipeline_mode}"
  },
  "evaluatorType": "value-param",
  "expression": "switchCaseValue",
  "decisionCases": {
    "full": [
      {"name": "stringify_transcription", "...": "..."},
      {"name": "ask_chat", "taskReferenceName": "determine_speakers_ref", "...": "..."},
      {"name": "save_determined_speakers", "...": "..."},
      {"name": "combine_transcription_with_round_definition", "...": "..."},
      {"name": "ask_chat", "taskReferenceName": "determine_rounds_ref", "...": "..."},
      {"name": "save_determined_rounds", "...": "..."},
      {"name": "execute_prompts", "...": "..."}
    ],
    "transcription_diarization": [
      {"name": "stringify_transcription", "...": "..."}
    ]
  },
  "defaultCase": []
}
```
**Note:** `defaultCase: []` (empty) means transcription-only mode does nothing after save_transcription — workflow completes.

### Pattern 2: Health Check Before Workflow Trigger
**What:** Backend checks service availability before starting a workflow, resolves actual mode
**When to use:** Every time a workflow is triggered
**Example:**
```java
// In AnalysisServiceImpl, before triggering workflow
String resolvedMode = pipelineModeResolver.resolve();
// resolve() checks config, then verifies services are up

workflowClient.triggerWorkflow(WORKFLOW_NAME, Map.of(
    "workspace_id", workspaceId,
    "round_definition", definitionOfRounds,
    "file_urls", fileUrls,
    "pipeline_mode", resolvedMode  // NEW: pass mode to workflow
));
```

### Pattern 3: RAM-Based Mode Recommendation
**What:** At startup, detect system RAM and log a recommended pipeline mode
**When to use:** Application startup, informational — doesn't override explicit config
**Example (Java):**
```java
import com.sun.management.OperatingSystemMXBean;
import java.lang.management.ManagementFactory;

OperatingSystemMXBean osBean = (OperatingSystemMXBean) ManagementFactory.getOperatingSystemMXBean();
long totalRamGB = osBean.getTotalMemorySize() / (1024 * 1024 * 1024);

if (totalRamGB < 8) {
    log.warn("System has {}GB RAM — transcription-only mode recommended", totalRamGB);
} else if (totalRamGB < 16) {
    log.info("System has {}GB RAM — transcription+diarization mode recommended", totalRamGB);
} else {
    log.info("System has {}GB RAM — full pipeline mode supported", totalRamGB);
}
```

### Workflow Structure (Before → After)

**Before (flat sequence):**
```
transcribe → save_transcription → stringify → determine_speakers → save_speakers →
combine_with_rounds → determine_rounds → save_rounds → execute_prompts
```

**After (branching):**
```
transcribe → save_transcription → SWITCH(pipeline_mode)
  ├── "full":                    stringify → speakers → save_speakers → combine → rounds → save_rounds → prompts
  ├── "transcription_diarization": stringify (transcription already includes speaker labels)
  └── default (transcription_only): (empty — workflow completes)
```

### Anti-Patterns to Avoid
- **Three separate workflow JSON files:** Maintenance nightmare, version drift between modes
- **`optional: true` on LLM tasks:** Tasks still get scheduled and fail — pollutes logs, wastes time waiting for timeouts
- **Checking service health inside Conductor tasks:** Health checks belong in the backend before triggering, not inside the workflow
- **Hot-swapping mode mid-workflow:** Once a workflow starts, its mode is fixed. Restart a new workflow for a different mode.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Conditional workflow branching | Custom task that calls next tasks dynamically | Conductor SWITCH task | Native operator, tested, handles edge cases |
| Service health checking | Custom HTTP polling loop | Spring Boot Actuator + RestTemplate/WebClient health calls | Actuator provides structured health responses |
| System RAM detection (Java) | Parsing /proc/meminfo or shell commands | `OperatingSystemMXBean.getTotalMemorySize()` | JDK built-in, cross-platform |
| System RAM detection (Python) | Parsing /proc/meminfo | `psutil.virtual_memory().total` | Cross-platform, well-maintained |
| Configuration with defaults | Custom config file parsing | Spring Boot `@ConfigurationProperties` + env vars | Standard Spring pattern, profiles, validation |

**Key insight:** The entire modular pipeline feature is orchestration and configuration — domains where Spring Boot and Conductor have mature, built-in solutions. No custom orchestration logic needed.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Workflow Version Mismatch
**What goes wrong:** Old workflow version (without SWITCH) still registered in Conductor, new workflows use old definition
**Why it happens:** Conductor caches workflow definitions. `WorkflowMigrationService` must explicitly update the version.
**How to avoid:** Bump workflow version number when changing the definition. The existing `WorkflowMigrationService` handles this — just increment the version in the JSON.
**Warning signs:** Workflows running without the SWITCH task despite code changes

### Pitfall 2: Health Check Timing
**What goes wrong:** Backend checks diarization service health at startup, service isn't up yet, permanently marks it unavailable
**Why it happens:** Services start at different speeds; diarization service loads ML models (slow startup)
**How to avoid:** Check health at workflow trigger time, not just at startup. Startup check sets the *recommendation*; trigger-time check confirms *reality*.
**Warning signs:** Diarization always showing as unavailable despite being running

### Pitfall 3: SWITCH Expression Evaluation
**What goes wrong:** SWITCH task doesn't match any case, falls through to defaultCase unexpectedly
**Why it happens:** Case names are strings — typos, wrong casing, or null values cause mismatches
**How to avoid:** Use `evaluatorType: "value-param"` (simple string match) not `graaljs` (overkill here). Validate `pipeline_mode` before passing to workflow. Use enum values.
**Warning signs:** All workflows falling into defaultCase (transcription-only) regardless of config

### Pitfall 4: Transcription Output Differs by Mode
**What goes wrong:** Transcription-only mode returns data expecting diarization fields (speaker labels), UI breaks
**Why it happens:** The `transcribe` task currently always does diarization. In transcription-only mode, output structure may differ.
**How to avoid:** The diarization service already has the hybrid pipeline that separates transcription from diarization. Ensure the `transcribe` task output contract is consistent across modes — always return `fragments` with `speaker` field (even if it's a single "Speaker" for non-diarized).
**Warning signs:** Frontend errors when displaying transcription-only results

### Pitfall 5: Silently Degrading Without User Awareness
**What goes wrong:** System downgrades from "full" to "transcription-only" without telling the user
**Why it happens:** Graceful degradation done too silently
**How to avoid:** Return the resolved pipeline mode in the workflow output and/or API response. Log warnings clearly. The CONTEXT.md explicitly states: "Never silently drop capabilities."
**Warning signs:** Users confused about why summaries or speaker labels are missing
</common_pitfalls>

<code_examples>
## Code Examples

### Conductor SWITCH Task Definition (Complete)
```json
// Source: Conductor OSS docs — SWITCH task type
{
  "name": "pipeline_mode_switch",
  "taskReferenceName": "pipeline_mode_switch_ref",
  "type": "SWITCH",
  "inputParameters": {
    "switchCaseValue": "${workflow.input.pipeline_mode}"
  },
  "evaluatorType": "value-param",
  "expression": "switchCaseValue",
  "decisionCases": {
    "full": [
      // ... all 7 post-transcription tasks
    ],
    "transcription_diarization": [
      // ... stringify only (speaker labels already in transcription)
    ]
  },
  "defaultCase": [],
  "startDelay": 0,
  "optional": false,
  "asyncComplete": false
}
```

### Pipeline Mode Configuration (Spring Boot)
```yaml
# application.yml
pipeline:
  mode: ${PIPELINE_MODE:auto}  # auto | transcription_only | transcription_diarization | full
  health-check:
    diarization-url: ${BACKEND_DIARIZATION_BASE_URL:http://localhost:8082}/health
    ask-chat-url: ${BACKEND_ASK_CHAT_BASE_URL:http://localhost:8083}/health
    timeout-ms: 3000
```

### Pipeline Mode Resolver (Java)
```java
// Source: Standard Spring Boot pattern
@Component
public class PipelineModeResolver {
    
    @Value("${pipeline.mode:auto}")
    private String configuredMode;
    
    private final RestTemplate restTemplate;
    
    public String resolve() {
        if (!"auto".equals(configuredMode)) {
            // Explicit mode — verify services are available, warn if not
            return verifyAndWarn(configuredMode);
        }
        // Auto-detect: check which services are healthy
        boolean diarizationUp = checkHealth(diarizationUrl);
        boolean chatUp = checkHealth(chatUrl);
        
        if (diarizationUp && chatUp) return "full";
        if (diarizationUp) return "transcription_diarization";
        return "transcription_only";
    }
    
    private boolean checkHealth(String url) {
        try {
            ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            return false;
        }
    }
}
```

### RAM Detection (Java — Physical Memory)
```java
// Source: JDK OperatingSystemMXBean (com.sun.management)
import com.sun.management.OperatingSystemMXBean;
import java.lang.management.ManagementFactory;

OperatingSystemMXBean osBean = (OperatingSystemMXBean) ManagementFactory.getOperatingSystemMXBean();
long totalRamBytes = osBean.getTotalMemorySize();
long totalRamGB = totalRamBytes / (1024L * 1024L * 1024L);
// Note: This is physical RAM, not JVM heap
```

### RAM Detection (Python — for diarization service)
```python
# Source: psutil docs
import psutil

mem = psutil.virtual_memory()
total_ram_gb = mem.total / (1024 ** 3)
available_ram_gb = mem.available / (1024 ** 3)
```
</code_examples>

<sota_updates>
## State of the Art (2025-2026)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate workflow per mode | Single workflow with SWITCH | Conductor SWITCH stable since 2.x | One workflow to maintain |
| Manual health polling | Spring Boot Actuator health groups | Spring Boot 2.3+ | Structured health aggregation |
| Netflix Conductor (archived) | Conductor OSS (community fork) | 2023 | Same API, active maintenance |

**New tools/patterns to consider:**
- **Conductor OSS 4.x:** Improved SWITCH task with GraalJS evaluator — allows complex expressions, but `value-param` is sufficient here
- **Spring Boot health groups:** Can group health indicators (e.g., "pipeline" group checks diarization + chat) — useful for a `/health/pipeline` endpoint

**Deprecated/outdated:**
- **Netflix/conductor GitHub repo:** Archived. Use conductor-oss/conductor instead (already in use)
- **Conductor 2.x health endpoint `/api/health`:** Changed to `/health` in 3.x (already using 3.15.0)
</sota_updates>

<open_questions>
## Open Questions

1. **Diarization service mode awareness**
   - What we know: The hybrid pipeline (Phase 9) already separates transcription from diarization internally. The `transcribe` Conductor task currently always runs the full hybrid pipeline.
   - What's unclear: Does the diarization service need a new "transcription-only" endpoint/mode, or should the backend simply not start the diarization service in transcription-only mode?
   - Recommendation: Add a `mode` parameter to the `transcribe` task input. The diarization service skips pyannote diarization when `mode=transcription_only`, returning fragments with a generic "Speaker" label. This keeps the output contract consistent.

2. **Workflow version migration**
   - What we know: `WorkflowMigrationService` loads JSON from classpath and updates Conductor
   - What's unclear: Does updating a workflow definition affect in-flight workflows?
   - Recommendation: Conductor runs in-flight workflows on their original version. New executions use the latest. Safe to update.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- Conductor OSS docs — SWITCH task: conditional branching, evaluatorType, decisionCases
- Conductor OSS docs — Task configuration: `optional` parameter, task skip API
- Orkes Conductor docs — SWITCH reference: nested switch, GraalJS evaluator
- Existing codebase — workflow JSON, ConductorWorkerListener, lifecycle.py patterns

### Secondary (MEDIUM confidence)
- Spring Boot Actuator docs — health endpoints, health groups
- JDK OperatingSystemMXBean — `getTotalMemorySize()` for physical RAM detection
- psutil docs — `virtual_memory()` for Python RAM detection

### Tertiary (LOW confidence - needs validation)
- RAM thresholds (8GB/16GB boundaries) — need validation during implementation against actual service memory usage
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: Netflix Conductor SWITCH tasks for conditional workflows
- Ecosystem: Spring Boot configuration/health, JDK/psutil for RAM detection
- Patterns: Two-layer mode detection (config + health), single workflow with branching
- Pitfalls: Version mismatch, health timing, SWITCH expression matching, silent degradation

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries, all existing infrastructure
- Architecture: HIGH — Conductor SWITCH is well-documented, Spring Boot config is commodity
- Pitfalls: HIGH — derived from codebase analysis and Conductor docs
- Code examples: HIGH — patterns from official docs applied to existing codebase structure

**Research date:** 2026-04-13
**Valid until:** 2026-05-13 (30 days — stable technologies, no fast-moving ecosystem)
</metadata>

---

*Phase: 10-modular-pipeline*
*Research completed: 2026-04-13*
*Ready for planning: yes*

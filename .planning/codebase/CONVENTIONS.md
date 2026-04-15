# Coding Conventions

**Analysis Date:** 2026-01-22

## Naming Patterns

**Files:**
- Java: PascalCase (`WorkspaceService.java`, `WorkspaceServiceImpl.java`, `WorkspaceDO.java`)
- Python: snake_case (`chat_service.py`, `diarization_api.py`, `chat_history_model.py`)
- Vue: PascalCase (`TranscriptBox.vue`, `AnalIntelligence.vue`, `WargameSetupDialog.vue`)
- TypeScript: kebab-case (`example-store.ts`, `tfidf.ts`, `pos.ts`)

**Functions:**
- Java: camelCase (`createWorkspace()`, `getWargameSetup()`)
- Python: snake_case (`ask_chat()`, `_execute_unsafe()`, `_create_diarization_task()`)
- TypeScript/Vue: camelCase (`triggerProcessing()`, `useCounterStore()`)

**Variables:**
- Java: camelCase for variables, `UPPER_SNAKE_CASE` for constants
- Python: snake_case for variables, `UPPER_SNAKE_CASE` for constants (e.g., `_FILE_PATH_INPUT_KEY`)
- TypeScript: camelCase for variables

**Types:**
- Java: PascalCase, suffix conventions (`*Service`, `*ServiceImpl`, `*DO`, `*Model`, `*API`)
- Python: PascalCase for classes (`ChatService`, `DiarizationModel`, `ChatHistoryDto`)
- TypeScript: PascalCase for interfaces and types

## Code Style

**Formatting:**
- Frontend: Prettier with `.prettierrc.json` (`blackbox/frontend/.prettierrc.json`)
- Print width: 100 characters
- Single quotes for strings
- EditorConfig: `.editorconfig` enforces UTF-8, LF line endings, trailing whitespace trimming

**Indentation:**
- Frontend (TypeScript/Vue): 2 spaces
- Java: 4 spaces (Maven/Java standard)
- Python: 4 spaces (PEP 8)

**Linting:**
- Frontend: ESLint v9.14.0 with Vue/TypeScript plugins (`blackbox/frontend/eslint.config.js`)
- Rules: Type imports, consistent type imports, debugger restrictions
- Plugins: `eslint-plugin-vue`, `@vue/eslint-config-typescript`, `@vue/eslint-config-prettier`
- Run: `npm run lint`

**Formatting Commands:**
```bash
# Frontend
npm run lint                    # ESLint check
npm run format                  # Prettier format
```

## Import Organization

**Java:**
- Standard Java import order
- Spring framework imports
- Project imports by package

**Python:**
- Standard library first
- Third-party packages (fastapi, pydantic, etc.)
- Local imports (relative)

**TypeScript/Vue:**
- External packages (vue, quasar, axios)
- Internal modules (@/)
- Relative imports

**Path Aliases:**
- Vue: No explicit aliases, relative imports used

## Error Handling

**Patterns:**
- Java: Custom exceptions extending base classes, thrown from services
- Python: Broad `Exception` catch in tasks, error truncation to 512 chars
- Frontend: try/catch with console.error, limited user feedback

**Error Types (Java):**
- `ServiceException` - Generic service errors
- `WorkspaceNotFoundException` - Workspace not found
- `WargameSetupNotFoundException` - Wargame setup not found
- Location: `blackbox/backend/blackbox_service/src/main/java/com/cgi/blackbox/service/exceptions/`

**Error Types (Python):**
- JSONResponse with error field for API errors
- Conductor task failure for workflow errors

## Logging

**Framework:**
- Java: Spring Boot default logging
- Python: Print/console (no structured logging configured)
- Frontend: `console.error()`, `console.log()`

**Patterns:**
- Minimal structured logging
- Error logging at service boundaries
- No centralized logging service

## Comments

**When to Comment:**
- Module-level docstrings in Python
- Class-level documentation for services
- Complex algorithm explanations (TF-IDF, POS tagging)

**JSDoc/TSDoc:**
- Vue: Component interface extensions documented
- TypeScript: Type declarations for API responses

**Python Docstrings:**
```python
"""
Lifecycle management for FastAPI application with Conductor integration.
"""

class ConductorRunner:
    """
    Manages the Conductor task handler lifecycle.
    """
```

**TODO Comments:**
- Format: `TODO: description`
- Found in: `ask-chat-service/src/lifecycle.py`, `speaker-diarization-service/src/lifecycle.py`

## Function Design

**Size:**
- Java: Services can be large (100-200 lines)
- Python: Kept relatively small
- Vue: Components can be large (300-450 lines) - concern noted

**Parameters:**
- Java: Constructor injection for dependencies
- Python: Pydantic models for complex inputs
- TypeScript: Destructured objects for component props

**Return Values:**
- Java: Domain models from services
- Python: Pydantic models or JSONResponse
- Async: Promises/Futures where appropriate

## Module Design

**Exports (Java):**
- Service interfaces for dependency injection
- Model classes for data transfer

**Exports (Python):**
- `__init__.py` re-exports module contents
- Service classes and models exported

**Exports (TypeScript):**
- Named exports for stores and utilities
- Default exports for Vue components

**Patterns:**
- Interface-driven service design (Java)
- Abstract base classes with concrete implementations (Python)
- Pinia stores for state management (Vue)

---

*Convention analysis: 2026-01-22*
*Update when patterns change*

---
phase: 13-one-click-services
plan: 03
subsystem: database, infra
tags: [h2, jpa, hibernate, tika, filesystem, docker-compose]

# Dependency graph
requires:
  - phase: 13-one-click-services
    provides: Direct Spring Boot orchestration (plan 01), REST-only Python services (plan 02)
provides:
  - H2 embedded database replacing MongoDB
  - Filesystem storage replacing GridFS
  - Embedded Tika replacing external Tika service
  - Zero Docker infrastructure dependencies
affects: [13-04, 13-05, 13-06, 13-07]

# Tech tracking
tech-stack:
  added: [spring-data-jpa, h2, tika-core, tika-parsers-standard-package]
  patterns: [JSON CLOB columns via JPA @Convert for nested data, FileStorageService for binary files]

key-files:
  created:
    - backend/blackbox_persistance/src/main/java/com/cgi/blackbox/persistance/jpa/ (full package)
    - backend/blackbox_persistance/src/main/java/com/cgi/blackbox/persistance/jpa/implementation/FileStorageService.java
  modified:
    - backend/blackbox_persistance/pom.xml
    - backend/blackbox_application/pom.xml
    - backend/blackbox_application/src/main/resources/application.yml
    - backend/blackbox_application/src/main/java/com/cgi/blackbox/clients/TikaTextExtractionClientImpl.java

key-decisions:
  - "JSON CLOB columns via @Convert for nested DOs instead of @ElementCollection — simpler for 3+ levels of nesting"
  - "Removed search() method from AbstractGenericAccess — zero usages found in codebase"
  - "File-based H2 (jdbc:h2:file:./data/blackbox-db) for data persistence across restarts"
  - "FileStorageService with JSON sidecar metadata files for binary file storage"
  - "Package renamed from mongodb to jpa for clarity"

patterns-established:
  - "JPA @Convert with Jackson for nested object storage as JSON CLOBs"
  - "FileStorageService pattern: {base}/{subdir}/{id}/{filename} + metadata.json"

issues-created: []

# Metrics
duration: 9min
completed: 2026-04-15
---

# Phase 13, Plan 03: Replace MongoDB/GridFS/Tika Summary

**H2 embedded DB, filesystem storage, and embedded Tika replace all 7 Docker infrastructure services**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-15T13:22:00Z
- **Completed:** 2026-04-15T13:35:50Z
- **Tasks:** 3
- **Files modified:** ~30 (created 15 new, modified 12, deleted 12)

## Accomplishments
- MongoDB fully replaced with H2 embedded database (file-based, persistent)
- GridFS replaced with FileStorageService using local filesystem + JSON metadata
- Tika embedded as library — no HTTP calls to external service
- docker-compose.yml deleted — zero Docker infrastructure dependencies remain
- Package renamed from `persistance.mongodb` to `persistance.jpa` across all modules

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace Spring Data MongoDB with JPA + H2** - `18d63c5` (feat)
2. **Task 2: Replace GridFS with filesystem storage** - `24d8f86` (feat)
3. **Task 3: Embed Tika and remove docker-compose** - `08272bf` (feat)

## Files Created/Modified

**Created (new jpa package):**
- `persistance/jpa/JpaConfiguration.java` - JPA repository configuration
- `persistance/jpa/dataobject/AbstractDO.java` - Base entity with UUID generation
- `persistance/jpa/dataobject/JsonAttributeConverter.java` - Base JSON CLOB converter
- `persistance/jpa/dataobject/WorkspaceDO.java` - Workspace entity with JSON nested fields
- `persistance/jpa/dataobject/WargameSetupDO.java` - Wargame setup entity
- `persistance/jpa/dataobject/WargameSetupRulebookDO.java` - Rulebook entity
- `persistance/jpa/repository/IBaseRepository.java` - JpaRepository base interface
- `persistance/jpa/repository/WorkspaceRepository.java` - Workspace JPA repository
- `persistance/jpa/repository/WargameSetupRepository.java` - Wargame setup JPA repository
- `persistance/jpa/implementation/AbstractAccess.java` - Base access layer
- `persistance/jpa/implementation/AbstractGenericAccess.java` - Generic CRUD access
- `persistance/jpa/implementation/WorkspaceAccess.java` - Workspace data access
- `persistance/jpa/implementation/WargameSetupAccess.java` - Wargame setup data access
- `persistance/jpa/implementation/WorkspaceMediaAccess.java` - Filesystem media access
- `persistance/jpa/implementation/WargameSetupRulebookAccess.java` - Filesystem rulebook access
- `persistance/jpa/implementation/FileStorageService.java` - Local filesystem storage service

**Modified:**
- `blackbox_persistance/pom.xml` - MongoDB deps -> JPA + H2
- `blackbox_application/pom.xml` - Added Tika, removed testcontainers:mongodb
- `blackbox_service/pom.xml` - Removed testcontainers:mongodb
- `application.yml` - H2 config, storage config, removed MongoDB/Tika URL
- `TikaTextExtractionClientImpl.java` - Embedded Tika replaces HTTP client
- 4 service implementation files - Import path mongodb -> jpa
- 4 test application.yml files - H2 in-memory config

**Deleted:**
- Entire `persistance/mongodb/` package (11 files)
- `docker-compose.yml`

## Decisions Made
- JSON CLOB columns via `@Convert` for nested DOs (TranscriptionDO, DeterminedRoundDO, etc.) — @ElementCollection would require complex table mappings for 3+ nesting levels
- Removed `search(Query)` method from AbstractGenericAccess — confirmed zero usages via grep
- Removed unused `GridFsOperations` constructor parameter from WargameSetupAccess
- Package renamed `mongodb` -> `jpa` for clarity (plan suggested this as preferred option)
- tika-parsers-standard-package 2.9.2 used (full parser suite) since app parses PDFs for rulebook text extraction

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] testcontainers:mongodb in blackbox_service pom.xml**
- **Found during:** Task 1
- **Issue:** Plan only mentioned removing testcontainers from persistance and application POMs, but service module also had it
- **Fix:** Removed testcontainers:mongodb dependency from blackbox_service/pom.xml
- **Verification:** Build succeeds across all modules
- **Committed in:** 18d63c5

**2. [Rule 3 - Blocking] Test application.yml files with MongoDB config**
- **Found during:** Task 1
- **Issue:** Multiple test resource application.yml files referenced MongoDB configuration
- **Fix:** Updated all test application.yml files to use H2 in-memory config
- **Verification:** Build succeeds with -DskipTests (test configs present for future test runs)
- **Committed in:** 18d63c5

---

**Total deviations:** 2 auto-fixed (2 blocking), 0 deferred
**Impact on plan:** Both fixes necessary for successful compilation. No scope creep.

## Issues Encountered
None.

## Next Phase Readiness
- Backend is fully self-contained: H2 DB + filesystem + embedded Tika
- Zero Docker infrastructure dependencies — runs as standalone Spring Boot JAR
- Data persists in `./data/` directory (H2 files + uploaded files)
- Ready for Plan 04 (frontend transcript export) and Plan 05 (Electron shell)

---
*Phase: 13-one-click-services*
*Completed: 2026-04-15*

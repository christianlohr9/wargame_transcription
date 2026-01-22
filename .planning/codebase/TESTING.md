# Testing Patterns

**Analysis Date:** 2026-01-22

## Test Framework

**Java Backend:**
- Framework: Spring Boot Test (JUnit 5)
- Config: Maven surefire plugin
- Dependencies: `spring-boot-starter-test`, TestContainers, WireMock v3.12.1

**Frontend:**
- Status: **No test framework configured**
- Script: `"test": "echo \"No test specified\" && exit 0"` (`blackbox/frontend/package.json`)
- Recommendation: Add Vitest with Vue Test Utils

**Python Services:**
- Status: **No test framework configured**
- No pytest or unittest in requirements.txt
- Recommendation: Add pytest with pytest-cov

**Run Commands:**
```bash
# Java (Maven)
mvn test                                    # Run all tests
mvn test -pl blackbox_application           # Single module

# Frontend (not configured)
npm test                                    # Currently no-op

# Python (not configured)
# pytest would be: pytest src/
```

## Test File Organization

**Java:**
- Pattern: Mirrored source structure
- Location: `blackbox/backend/*/src/test/java/com/cgi/blackbox/`
- Example: `blackbox/backend/blackbox_service/src/test/java/com/cgi/blackbox/TestApplicationConfiguration.java`

**Frontend:**
- Pattern: Not established
- Recommendation: Co-located `*.test.ts` or `*.spec.ts`

**Python:**
- Pattern: Not established
- Recommendation: `tests/` directory or co-located `test_*.py`

**Structure:**
```
blackbox/backend/
├── blackbox_application/
│   └── src/test/java/com/cgi/blackbox/
├── blackbox_service/
│   └── src/test/java/com/cgi/blackbox/
│       ├── TestApplicationConfiguration.java
│       └── TestYMLConfigLoader.java
├── blackbox_persistance/
│   └── src/test/java/com/cgi/blackbox/
└── blackbox_commons/
    └── src/test/java/com/cgi/blackbox/
```

## Test Structure

**Java Suite Organization:**
```java
// TestApplicationConfiguration.java
@Configuration
public class TestApplicationConfiguration {
    // Spring test configuration
}

// TestYMLConfigLoader.java
// YAML configuration loading for tests
```

**Patterns:**
- Spring Boot test configuration for integration testing
- Test configuration classes for shared setup
- No explicit unit test examples found

## Mocking

**Java Framework:**
- WireMock v3.12.1 for HTTP mocking (`blackbox/backend/blackbox_service/pom.xml`)
- Spring MockMvc (implicit via spring-boot-starter-test)

**TestContainers:**
- MongoDB TestContainers for integration tests (`blackbox/backend/blackbox_application/pom.xml`)

**Patterns:**
```java
// WireMock usage (expected pattern)
WireMockServer wireMockServer = new WireMockServer(options);
wireMockServer.stubFor(get(urlEqualTo("/api/..."))
    .willReturn(aResponse().withBody("...")));
```

**What to Mock:**
- External HTTP services (Conductor, Tika, AI services)
- Database (TestContainers for MongoDB)

**What NOT to Mock:**
- Internal service layer (test integration)
- Domain models

## Fixtures and Factories

**Test Data:**
- YAML configuration loader: `TestYMLConfigLoader.java`
- No explicit factory patterns identified

**Location:**
- Test resources: `src/test/resources/`
- Configuration: Test-specific `application.yml`

## Coverage

**Requirements:**
- No explicit coverage targets
- No JaCoCo or similar tools configured

**Configuration:**
- Coverage not enforced in CI
- Recommendation: Add coverage reporting

**View Coverage:**
```bash
# Not currently configured
# Would be: mvn jacoco:report
```

## Test Types

**Integration Tests (Java):**
- Spring Boot test context
- TestContainers for MongoDB
- WireMock for external services
- Location: `blackbox/backend/blackbox_application/src/test/`

**Unit Tests:**
- Minimal - mostly configuration tests found
- Service layer tests not comprehensive

**E2E Tests:**
- Not implemented
- Recommendation: Playwright or Cypress for frontend

## Common Patterns

**Async Testing:**
- Project Reactor test utilities (implicit)
- Conductor task testing not established

**Error Testing:**
- Not established
- Recommendation: Test exception handling paths

**Database Testing:**
```java
// MongoDB TestContainers (expected pattern)
@Container
static MongoDBContainer mongoDBContainer = new MongoDBContainer("mongo:6.0");
```

## Quality Tools

**Frontend:**
- ESLint v9.14.0 - Code linting
- Prettier v3.3.3 - Code formatting
- TypeScript v5.9.2 - Type checking

**Java:**
- Maven compiler strict checking
- Lombok for boilerplate reduction
- No static analysis tools (SpotBugs, etc.)

**Python:**
- Pydantic runtime validation
- No static analysis (mypy, flake8, black)

## Test Gaps

**Critical Gaps:**
- Frontend: No test infrastructure
- Python services: No test infrastructure
- Java: Limited test coverage, mostly configuration

**Recommendations:**
1. Add Vitest + Vue Test Utils for frontend
2. Add pytest + pytest-cov for Python services
3. Add JaCoCo for Java coverage reporting
4. Implement E2E tests for critical workflows
5. Add pre-commit hooks for test execution

---

*Testing analysis: 2026-01-22*
*Update when test patterns change*

# Build Java Runtime (jlink)

Creates a custom, minimal JRE using `jlink` so users don't need Java installed.

## Prerequisites

- **JDK 21** (full JDK, not just JRE) — provides `java`, `javac`, `jlink`, `jdeps`
- **Maven 3.9+** — builds the Spring Boot fat JAR
- Ensure `JAVA_HOME` points to JDK 21 (JDK 25 breaks Lombok annotation processing)

## Usage

```bash
# From the repository root (parent of blackbox/ and blackbox-desktop/)
./blackbox-desktop/scripts/build-java-runtime.sh
```

## What It Does

1. Builds the multi-module Maven project from `blackbox/pom.xml` (`mvn clean package -DskipTests`)
2. Locates the fat JAR at `blackbox/backend/blackbox_application/target/blackbox_application-0.1.0-SNAPSHOT.jar`
3. Runs `jdeps` to detect required Java modules (falls back to a known Spring Boot module set if jdeps fails on the fat JAR)
4. Generates a stripped-down JRE with `jlink` to `blackbox-desktop/resources/runtime/java/`
5. Copies the JAR to `blackbox-desktop/resources/app/blackbox.jar`

## Output

```
blackbox-desktop/
  resources/
    runtime/
      java/          # Custom JRE (~50-70 MB)
        bin/
          java       # (or javaw.exe on Windows)
        ...
    app/
      blackbox.jar   # Spring Boot fat JAR (~80 MB)
```

## Platform Notes

- **The JRE is platform-specific.** A JRE built on macOS only runs on macOS.
- For production (Windows HP EliteBook), run this script on a Windows machine with JDK 21.
- The macOS build is only useful for local development and testing.

## Troubleshooting

### jdeps fails on fat JAR

Spring Boot fat JARs use a nested JAR layout that `jdeps` often can't parse. The script
falls back to a known module set that covers Spring Boot 3.x, H2, RestTemplate, and
standard Java features. If the application uses additional modules (e.g., `java.rmi`),
add them to the `FALLBACK_MODULES` variable in the script.

### "Module not found" at runtime

If the application fails to start with `java.lang.module.FindException`, a required module
is missing from the jlink output. Check the error message for the module name and add it
to `FALLBACK_MODULES` in the script, then rebuild.

### Maven build fails

The project uses a multi-module layout. Always build from the root POM:
```bash
cd blackbox && mvn clean package -DskipTests
```

Building from `blackbox/backend/blackbox_application/` alone will fail because it depends
on sibling modules (e.g., `blackbox_common`).

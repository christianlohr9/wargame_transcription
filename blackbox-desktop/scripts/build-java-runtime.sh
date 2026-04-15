#!/usr/bin/env bash
# build-java-runtime.sh — Build a portable JRE via jlink and copy the Spring Boot JAR.
# Must be run from the repo root (parent of blackbox/ and blackbox-desktop/).
set -euo pipefail

##############################################################################
# Paths
##############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DESKTOP_DIR="$PROJECT_ROOT/blackbox-desktop"
RESOURCES_DIR="$DESKTOP_DIR/resources"
JRE_OUTPUT="$RESOURCES_DIR/runtime/java"
APP_DIR="$RESOURCES_DIR/app"

# Maven artifact coordinates
GROUP_PATH="blackbox/backend/blackbox_application"
ARTIFACT="blackbox_application"
VERSION="0.1.0-SNAPSHOT"
JAR_NAME="$ARTIFACT-$VERSION.jar"
JAR_SOURCE="$PROJECT_ROOT/blackbox/backend/blackbox_application/target/$JAR_NAME"

##############################################################################
# Pre-flight checks
##############################################################################
echo "=== Portable JRE Build ==="
echo "Project root : $PROJECT_ROOT"
echo "Desktop dir  : $DESKTOP_DIR"
echo ""

command -v java >/dev/null 2>&1  || { echo "ERROR: java not found in PATH"; exit 1; }
command -v javac >/dev/null 2>&1 || { echo "ERROR: javac not found — need a full JDK, not just JRE"; exit 1; }
command -v jlink >/dev/null 2>&1 || { echo "ERROR: jlink not found — need JDK 21+"; exit 1; }
command -v jdeps >/dev/null 2>&1 || { echo "ERROR: jdeps not found — need JDK 21+"; exit 1; }
command -v mvn >/dev/null 2>&1   || { echo "ERROR: mvn not found in PATH"; exit 1; }

JAVA_VERSION=$(java -version 2>&1 | head -n1)
echo "Java version : $JAVA_VERSION"
echo ""

##############################################################################
# Step 1 — Build the Spring Boot fat JAR
##############################################################################
echo ">>> Step 1: Building Spring Boot fat JAR (multi-module, from root POM)..."
cd "$PROJECT_ROOT/blackbox"
mvn clean package -DskipTests -q
echo "    Build complete."

if [ ! -f "$JAR_SOURCE" ]; then
  echo "ERROR: Expected JAR not found at $JAR_SOURCE"
  echo "Searching for JAR files in target/..."
  find "$PROJECT_ROOT/blackbox/backend/blackbox_application/target/" -name "*.jar" 2>/dev/null || true
  exit 1
fi
echo "    JAR found: $JAR_SOURCE"

##############################################################################
# Step 2 — Detect required modules with jdeps (with fallback)
##############################################################################
echo ""
echo ">>> Step 2: Detecting required Java modules..."

# Known module set for Spring Boot 3.x + our stack.
# Fat JARs often confuse jdeps, so we use this as a reliable fallback.
FALLBACK_MODULES="java.base,java.desktop,java.instrument,java.management,java.naming,java.net.http,java.prefs,java.scripting,java.security.jgss,java.security.sasl,java.sql,java.xml,jdk.crypto.ec,jdk.httpserver,jdk.unsupported"

MODULES=""
if jdeps --ignore-missing-deps --print-module-deps "$JAR_SOURCE" > /tmp/jdeps_output.txt 2>/dev/null; then
  MODULES=$(cat /tmp/jdeps_output.txt | tr -d '[:space:]')
  if [ -z "$MODULES" ] || [ "$MODULES" = "java.base" ]; then
    echo "    jdeps returned minimal modules — using fallback set."
    MODULES="$FALLBACK_MODULES"
  else
    echo "    jdeps detected modules: $MODULES"
  fi
else
  echo "    jdeps failed on fat JAR (common) — using fallback module set."
  MODULES="$FALLBACK_MODULES"
fi
echo "    Final modules: $MODULES"

##############################################################################
# Step 3 — Generate custom JRE with jlink
##############################################################################
echo ""
echo ">>> Step 3: Generating custom JRE with jlink..."

# Remove previous JRE if present
if [ -d "$JRE_OUTPUT" ]; then
  echo "    Removing previous JRE at $JRE_OUTPUT"
  rm -rf "$JRE_OUTPUT"
fi

jlink \
  --add-modules "$MODULES" \
  --strip-debug \
  --compress zip-6 \
  --no-header-files \
  --no-man-pages \
  --output "$JRE_OUTPUT"

echo "    Custom JRE created at $JRE_OUTPUT"

##############################################################################
# Step 4 — Copy the JAR to resources/app/
##############################################################################
echo ""
echo ">>> Step 4: Copying application JAR..."
mkdir -p "$APP_DIR"
cp "$JAR_SOURCE" "$APP_DIR/blackbox.jar"
echo "    Copied to $APP_DIR/blackbox.jar"

##############################################################################
# Summary
##############################################################################
echo ""
echo "=== Build Summary ==="
JRE_SIZE=$(du -sh "$JRE_OUTPUT" 2>/dev/null | cut -f1)
JAR_SIZE=$(du -sh "$APP_DIR/blackbox.jar" 2>/dev/null | cut -f1)
echo "  Custom JRE size : $JRE_SIZE"
echo "  Application JAR : $JAR_SIZE"
echo "  JRE location    : $JRE_OUTPUT"
echo "  JAR location    : $APP_DIR/blackbox.jar"
echo ""
echo "NOTE: This JRE is platform-specific."
echo "  - macOS build  -> macOS JRE (dev/testing only)"
echo "  - Windows build -> Windows JRE (production target)"
echo ""
echo "Done."

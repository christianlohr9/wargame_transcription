#!/usr/bin/env bash
# build-windows-package.sh — One-shot script to build the complete Windows installer.
# Run this on the TARGET Windows machine in Git Bash.
# Usage: cd blackbox-desktop && bash scripts/build-windows-package.sh
set -euo pipefail

##############################################################################
# Paths
##############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$DESKTOP_DIR/.." && pwd)"

FRONTEND_DIR="$PROJECT_ROOT/blackbox/frontend"
BACKEND_DIR="$PROJECT_ROOT/blackbox"

##############################################################################
# Colors (Git Bash supports ANSI)
##############################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ok()   { echo -e "  ${GREEN}OK${NC} $1"; }
warn() { echo -e "  ${YELLOW}WARNING${NC} $1"; }
fail() { echo -e "  ${RED}FAILED${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}[$1/$TOTAL_STEPS]${NC} $2"; }

TOTAL_STEPS=7

##############################################################################
# Pre-flight checks
##############################################################################
echo ""
echo "=============================================="
echo "  Blackbox Wargaming — Windows Package Build"
echo "=============================================="
echo ""
echo "Project root: $PROJECT_ROOT"
echo "Platform:     $(uname -s) $(uname -m)"
echo ""

MISSING=""
HAS_CONDA=false

##############################################################################
# JDK 21 detection — Lombok requires JDK 21 (JDK 22+ breaks annotation processing)
##############################################################################
echo "Checking Java version..."

# Auto-detect JDK 21 if JAVA_HOME is not already set to one
detect_jdk21() {
  # 1. If JAVA_HOME is already JDK 21, use it
  if [ -n "${JAVA_HOME:-}" ]; then
    local ver
    ver=$("$JAVA_HOME/bin/java" -version 2>&1 | head -n1 || echo "")
    if echo "$ver" | grep -q '"21\.' ; then
      return 0
    fi
  fi

  # 2. macOS: check Homebrew
  local brew_jdk="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
  if [ -d "$brew_jdk" ]; then
    export JAVA_HOME="$brew_jdk"
    return 0
  fi
  # Intel Mac
  brew_jdk="/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
  if [ -d "$brew_jdk" ]; then
    export JAVA_HOME="$brew_jdk"
    return 0
  fi

  # 3. macOS: java_home utility
  if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    local jh
    jh=$(/usr/libexec/java_home -v 21 2>/dev/null || echo "")
    if [ -n "$jh" ] && [ -d "$jh" ]; then
      export JAVA_HOME="$jh"
      return 0
    fi
  fi

  # 4. Windows/Linux: check common paths
  for p in \
    "/c/Program Files/Eclipse Adoptium/jdk-21"* \
    "/c/Program Files/Java/jdk-21"* \
    "/usr/lib/jvm/java-21"* \
    "$HOME/.sdkman/candidates/java/21"* \
  ; do
    if [ -d "$p" ]; then
      export JAVA_HOME="$p"
      return 0
    fi
  done

  return 1
}

# Disable exit-on-error during checks — version commands may fail on stubs (e.g. macOS java shim)
set +e

if detect_jdk21; then
  export PATH="$JAVA_HOME/bin:$PATH"
  JAVA_VER=$("$JAVA_HOME/bin/java" -version 2>&1 | head -n1 || echo "unknown")
  ok "JDK 21: $JAVA_VER"
  ok "JAVA_HOME=$JAVA_HOME"
else
  echo -e "  ${RED}ERROR${NC} JDK 21 not found."
  echo ""
  echo "  Lombok annotation processing requires JDK 21 (JDK 22+ breaks it)."
  echo "  Install JDK 21:"
  echo "    macOS:   brew install openjdk@21"
  echo "    Windows: https://adoptium.net (Temurin 21 LTS)"
  echo "    Linux:   sudo apt install openjdk-21-jdk"
  echo ""
  echo "  Or set JAVA_HOME manually:"
  echo "    export JAVA_HOME=/path/to/jdk-21"
  echo ""
  fail "JDK 21 required — see instructions above."
fi

echo ""
echo "Checking other prerequisites..."

check_tool() {
  local name="$1" install_hint="$2"
  if command -v "$name" >/dev/null 2>&1; then
    return 0
  else
    MISSING="$MISSING $name"
    echo -e "  ${RED}MISSING${NC} $name — $install_hint"
    return 1
  fi
}

check_tool jlink "comes with JDK 21+" && ok "jlink"

if check_tool mvn "install from https://maven.apache.org or use sdkman"; then
  MVN_VER=$(mvn --version 2>&1 | head -n1 || echo "unknown")
  ok "Maven: $MVN_VER"
fi

if check_tool node "install from https://nodejs.org"; then
  NODE_VER=$(node --version 2>&1 || echo "unknown")
  ok "Node.js: $NODE_VER"
fi

check_tool npm "comes with Node.js" && ok "npm"

if command -v conda >/dev/null 2>&1; then
  CONDA_VER=$(conda --version 2>&1 || echo "unknown")
  ok "Conda: $CONDA_VER"
  HAS_CONDA=true
else
  warn "Conda not found — Python runtime will NOT be bundled (diarization unavailable)"
fi

# Re-enable exit-on-error for the actual build
set -e

if [ -n "$MISSING" ]; then
  echo ""
  fail "Missing required tools:$MISSING — install them and re-run this script."
fi

echo ""
echo "All required tools found."

##############################################################################
# Step 1: Install npm dependencies
##############################################################################
step 1 "Installing npm dependencies..."

cd "$DESKTOP_DIR"
if [ ! -d "node_modules" ]; then
  npm install
  ok "npm dependencies installed"
else
  ok "node_modules already present"
fi

# Also install frontend dependencies if needed
cd "$FRONTEND_DIR"
if [ ! -d "node_modules" ]; then
  npm install
  ok "frontend dependencies installed"
else
  ok "frontend node_modules already present"
fi

##############################################################################
# Step 2: Build Java backend (platform-independent JAR)
##############################################################################
step 2 "Building Java backend..."

cd "$BACKEND_DIR"
mvn clean package -DskipTests -q
ok "Spring Boot JAR built"

JAR_SOURCE="$BACKEND_DIR/backend/blackbox_application/target/blackbox_application-0.1.0-SNAPSHOT.jar"
if [ ! -f "$JAR_SOURCE" ]; then
  fail "JAR not found at $JAR_SOURCE"
fi
JAR_SIZE=$(du -sh "$JAR_SOURCE" 2>/dev/null | cut -f1)
ok "JAR size: $JAR_SIZE"

##############################################################################
# Step 3: Build frontend (platform-independent SPA)
##############################################################################
step 3 "Building frontend..."

cd "$FRONTEND_DIR"
npx quasar build
ok "Frontend built"

# Copy to Electron dist/
DIST_SRC="$FRONTEND_DIR/dist/spa"
DIST_DEST="$DESKTOP_DIR/dist"

if [ -d "$DIST_DEST" ]; then
  rm -rf "$DIST_DEST"
fi

cp -r "$DIST_SRC" "$DIST_DEST"
ok "Frontend copied to $DIST_DEST"

##############################################################################
# Step 4: Build portable Java runtime (jlink)
##############################################################################
step 4 "Building portable Java runtime (jlink)..."

cd "$DESKTOP_DIR"
bash scripts/build-java-runtime.sh
ok "Portable JRE built"

JRE_SIZE=$(du -sh "$DESKTOP_DIR/resources/runtime/java" 2>/dev/null | cut -f1)
ok "JRE size: $JRE_SIZE"

##############################################################################
# Step 5: Build portable Python runtime (conda-pack)
##############################################################################
step 5 "Building portable Python runtime (conda-pack)..."

if [ "$HAS_CONDA" = true ]; then
  cd "$DESKTOP_DIR"
  bash scripts/build-python-runtime.sh
  ok "Portable Python built"

  PYTHON_SIZE=$(du -sh "$DESKTOP_DIR/resources/runtime/python" 2>/dev/null | cut -f1)
  ok "Python runtime size: $PYTHON_SIZE"
else
  warn "Skipped — conda not available"
  warn "The app will work for transcription only (no speaker diarization)"
fi

##############################################################################
# Step 6: Bundle ML models (optional)
##############################################################################
step 6 "Bundling ML models..."

if [ "${BUNDLE_MODELS:-}" = "true" ]; then
  cd "$DESKTOP_DIR"
  bash scripts/bundle-models.sh
  ok "Models bundled"

  MODELS_SIZE=$(du -sh "$DESKTOP_DIR/resources/models" 2>/dev/null | cut -f1)
  ok "Models size: $MODELS_SIZE"
else
  warn "Skipped — set BUNDLE_MODELS=true to include (needed for air-gapped use)"
  warn "Without bundled models, the app will download them on first use (needs internet)"
fi

##############################################################################
# Step 7: Build Windows NSIS installer
##############################################################################
step 7 "Building Windows installer (NSIS)..."

cd "$DESKTOP_DIR"
npx electron-builder --win
ok "Windows installer built"

##############################################################################
# Summary
##############################################################################
echo ""
echo "=============================================="
echo "  Build Complete!"
echo "=============================================="
echo ""
echo "Installer location:"
echo ""

# Find the generated installer
INSTALLER=$(find "$DESKTOP_DIR/dist-electron" -name "*.exe" -type f 2>/dev/null | head -1)
if [ -n "$INSTALLER" ]; then
  INSTALLER_SIZE=$(du -sh "$INSTALLER" 2>/dev/null | cut -f1)
  echo -e "  ${GREEN}$INSTALLER${NC}"
  echo -e "  Size: $INSTALLER_SIZE"
else
  warn "No .exe found in dist-electron/ — check the output above for errors"
  echo "  Check: $DESKTOP_DIR/dist-electron/"
fi

echo ""
echo "What's included:"
echo "  - Electron desktop shell"
echo "  - Vue/Quasar frontend"
echo "  - Spring Boot backend + portable JRE"
[ "$HAS_CONDA" = true ] && echo "  - Python runtime + diarization/chat services"
[ "${BUNDLE_MODELS:-}" = "true" ] && echo "  - ML models (offline capable)"
echo ""
echo "Hand this .exe to your colleague — no admin rights needed to install."
echo ""

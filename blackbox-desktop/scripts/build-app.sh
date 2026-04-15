#!/bin/bash
set -e

echo "=== Building Blackbox Wargaming Desktop App ==="

# Step 1: Build frontend
echo "[1/5] Building frontend..."
cd ../blackbox/frontend && npx quasar build
cp -r dist/spa ../../blackbox-desktop/dist

# Step 2: Build Java backend + runtime
echo "[2/5] Building Java runtime..."
cd ../../blackbox-desktop
bash scripts/build-java-runtime.sh

# Step 3: Build Python runtime (if conda available)
echo "[3/5] Building Python runtime..."
if command -v conda &> /dev/null; then
  bash scripts/build-python-runtime.sh
else
  echo "WARNING: conda not available, skipping Python runtime build"
fi

# Step 4: Bundle models (if requested)
if [ "$BUNDLE_MODELS" = "true" ]; then
  echo "[4/5] Bundling ML models..."
  bash scripts/bundle-models.sh
else
  echo "[4/5] Skipping model bundling (set BUNDLE_MODELS=true to include)"
fi

# Step 5: Build Electron app
echo "[5/5] Building Electron app..."
if [ "$(uname)" = "Darwin" ]; then
  npx electron-builder --mac --dir
else
  npx electron-builder --win
fi

echo "=== Build complete! ==="
echo "Output: blackbox-desktop/dist-electron/"

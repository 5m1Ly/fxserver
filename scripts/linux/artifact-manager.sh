#!/bin/bash

# Get script directory
BASE_DIR="$HOME/fx-server"

# Create directories if they don't exist
mkdir -p "$BASE_DIR/.store"
mkdir -p "$BASE_DIR/artifact"

# Read the build number from .cfxrc file
BUILD_NUMBER=$(cat "$BASE_DIR/server-data/.cfxrc" | tr -d '[:space:]')
cd ../
if [ -z "$BUILD_NUMBER" ]; then
    echo "Error: Build number not found in .cfxrc file"
    exit 1
fi

# Check if artifact is already installed
CURRENT_BUILD=""
if [ -f "$BASE_DIR/artifact/.fxbuild" ]; then
    CURRENT_BUILD=$(cat "$BASE_DIR/artifact/.fxbuild" | tr -d '[:space:]')
fi

if [ "$BUILD_NUMBER" = "$CURRENT_BUILD" ]; then
    echo "Artifact build $BUILD_NUMBER is already installed"
    exit 0
else
    if [ -z "$CURRENT_BUILD" ]; then
        echo "No artifact currently installed"
    else
        echo "Build mismatch: installed=$CURRENT_BUILD, requested=$BUILD_NUMBER"
    fi
fi

echo "Looking for artifact build: $BUILD_NUMBER"

# Fetch the artifacts page and find the download link for the specific build
ARTIFACTS_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
DOWNLOAD_LINK=$(curl -s "$ARTIFACTS_URL" | grep -oP "href=\"\K[^\"]*${BUILD_NUMBER}[^\"]*fx\.tar\.xz" | head -1)

if [ -z "$DOWNLOAD_LINK" ]; then
    echo "Error: Could not find download link for build $BUILD_NUMBER"
    exit 1
fi

# Construct the full download URL
FULL_URL="${ARTIFACTS_URL}${DOWNLOAD_LINK}"
echo "Download URL: $FULL_URL"

# Download the artifact to .store folder
STORE_DIR="$BASE_DIR/.store"
OUTPUT_FILE="$STORE_DIR/${BUILD_NUMBER}-fx.tar.xz"

# Check if file already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "Artifact already exists: $OUTPUT_FILE"
else
    echo "Downloading to: $OUTPUT_FILE"
    curl -L -o "$OUTPUT_FILE" "$FULL_URL"

    if [ $? -eq 0 ]; then
        echo "Download complete: $OUTPUT_FILE"
    else
        echo "Error: Download failed"
        exit 1
    fi
fi

# Extract the artifact to the artifact folder
ARTIFACT_DIR="$BASE_DIR/artifact"
echo "Extracting to: $ARTIFACT_DIR"
tar xf "$OUTPUT_FILE" -C "$ARTIFACT_DIR"

if [ $? -eq 0 ]; then
    echo "Extraction complete"
else
    echo "Error: Extraction failed"
    exit 1
fi

# Copy .cfxrc to artifact/.build
cp "$BASE_DIR/server-data/.cfxrc" "$ARTIFACT_DIR/.fxbuild"
echo "Build number saved to: $ARTIFACT_DIR/.fxbuild"

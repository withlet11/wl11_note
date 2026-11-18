#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

APP_NAME="wl11_note"
APP_EXECUTABLE="wl11_note"

BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
INSTALL_DIR="$HOME/.local/opt/$APP_NAME"

ICON_SOURCE="$PROJECT_ROOT/packaging/linux/icons"
ICON_THEME_DIR="$HOME/.local/share/icons/hicolor"

DESKTOP_SOURCE="$PROJECT_ROOT/packaging/linux/$APP_NAME.desktop"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_DEST="$DESKTOP_DIR/$APP_NAME.desktop"

# Build
echo "Building Linux release..."
(
    cd "$PROJECT_ROOT"
    flutter build linux --release
)

# Check executable
if [[ ! -x "$BUILD_DIR/$APP_EXECUTABLE" ]]; then
    echo "Error: Application executable not found."
    exit 1
fi

# Install application bundle
echo "Installing application..."
mkdir -p "$INSTALL_DIR"
cp -a "$BUILD_DIR/." "$INSTALL_DIR/"

# Install icons
echo "Installing icons..."
if [[ -d "$ICON_SOURCE" ]]; then
    mkdir -p "$ICON_THEME_DIR"
    cp -a "$ICON_SOURCE/." "$ICON_THEME_DIR/"
fi

# Generate desktop entry with the installed executable path
echo "Installing desktop entry..."
mkdir -p "$DESKTOP_DIR"

python3 - "$DESKTOP_SOURCE" "$DESKTOP_DEST" \
    "$INSTALL_DIR/$APP_EXECUTABLE" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1])
destination = pathlib.Path(sys.argv[2])
executable = sys.argv[3]

if not source.is_file():
    raise SystemExit(f"Desktop entry not found: {source}")

lines = source.read_text().splitlines()
escaped = executable.replace("\\", "\\\\").replace('"', '\\"')

count = 0
for i, line in enumerate(lines):
    if line.startswith("Exec="):
        lines[i] = f'Exec="{escaped}"'
        count += 1

if count != 1:
    raise SystemExit("Expected exactly one Exec entry.")

destination.write_text("\n".join(lines) + "\n")
PY

# Validate desktop entry if validator is installed
if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "$DESKTOP_DEST"
fi

echo
echo "Build and installation completed."
echo "Application: $INSTALL_DIR/$APP_EXECUTABLE"
echo "Desktop entry: $DESKTOP_DEST"


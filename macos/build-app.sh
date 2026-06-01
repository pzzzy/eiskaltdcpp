#!/usr/bin/env bash
set -euo pipefail

arch="arm64"
preset=""
package=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch) arch="$2"; shift 2 ;;
    --preset) preset="$2"; shift 2 ;;
    --no-package) package=0; shift ;;
    -h|--help)
      cat <<'USAGE'
Usage: macos/build-app.sh [--arch arm64|x86_64] [--no-package]

Builds EiskaltDC++ as a modern macOS app using Homebrew Qt 5.
Set HOMEBREW_PREFIX to override the brew prefix; otherwise brew --prefix is used.
USAGE
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$preset" ]]; then
  preset="macos-${arch}-release"
fi

export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/opt/ccache/libexec:$PATH"

qt5_cmake="$HOMEBREW_PREFIX/opt/qt@5/lib/cmake"
cmake --preset "$preset" \
  -DQt5_DIR="$qt5_cmake/Qt5" \
  -DQt5Core_DIR="$qt5_cmake/Qt5Core" \
  -DQt5Widgets_DIR="$qt5_cmake/Qt5Widgets" \
  -DQt5Gui_DIR="$qt5_cmake/Qt5Gui" \
  -DQt5Network_DIR="$qt5_cmake/Qt5Network" \
  -DQt5Xml_DIR="$qt5_cmake/Qt5Xml" \
  -DQt5Sql_DIR="$qt5_cmake/Qt5Sql" \
  -DQt5Multimedia_DIR="$qt5_cmake/Qt5Multimedia" \
  -DQt5Script_DIR="$qt5_cmake/Qt5Script" \
  -DQt5Svg_DIR="$qt5_cmake/Qt5Svg" \
  -DQt5UiTools_DIR="$qt5_cmake/Qt5UiTools"
cmake --build --preset "$preset" --parallel
cmake --install "build/$preset"

app="dist/$preset/EiskaltDC++.app"
if [[ -d "$app" && -x "$HOMEBREW_PREFIX/opt/qt@5/bin/macdeployqt" ]]; then
  "$HOMEBREW_PREFIX/opt/qt@5/bin/macdeployqt" "$app" -always-overwrite
  codesign --force --deep --sign - "$app"
  codesign --verify --deep --strict "$app"
fi

if [[ "$package" -eq 1 ]]; then
  cmake --build --preset "$preset" --target package
fi

echo "Built preset $preset"

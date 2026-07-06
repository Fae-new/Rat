#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Rat"
APP_PATH="$ROOT_DIR/build/Release/$APP_NAME.app"

if [[ ! -d "$APP_PATH" ]]; then
  "$ROOT_DIR/scripts/build-release.sh" >/dev/null
fi

rm -rf "/Applications/$APP_NAME.app"
cp -R "$APP_PATH" /Applications/
open "/Applications/$APP_NAME.app"

echo "/Applications/$APP_NAME.app"

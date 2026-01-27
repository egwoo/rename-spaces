#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
APP_BUNDLE_NAME="Rename Spaces"
DIST_APP="$ROOT_DIR/dist/$APP_BUNDLE_NAME.app"
SYSTEM_APP_DIR="/Applications"

"$ROOT_DIR/scripts/build_app.sh"

install_to_dir() {
  local target_dir="$1"
  mkdir -p "$target_dir"
  rm -rf "$target_dir/$APP_BUNDLE_NAME.app"
  /usr/bin/ditto "$DIST_APP" "$target_dir/$APP_BUNDLE_NAME.app"
  printf "Installed to %s\n" "$target_dir/$APP_BUNDLE_NAME.app"
}

if [ -w "$SYSTEM_APP_DIR" ]; then
  install_to_dir "$SYSTEM_APP_DIR"
else
  printf "Requesting admin access to install to %s...\n" "$SYSTEM_APP_DIR"
  sudo mkdir -p "$SYSTEM_APP_DIR"
  sudo rm -rf "$SYSTEM_APP_DIR/$APP_BUNDLE_NAME.app"
  sudo /usr/bin/ditto "$DIST_APP" "$SYSTEM_APP_DIR/$APP_BUNDLE_NAME.app"
  printf "Installed to %s\n" "$SYSTEM_APP_DIR/$APP_BUNDLE_NAME.app"
fi

INSTALL_PATH="$SYSTEM_APP_DIR/$APP_BUNDLE_NAME.app"

/usr/bin/open "$INSTALL_PATH"
/usr/bin/open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true

printf "\nNext: enable %s in Accessibility and re-open Mission Control.\n" "$APP_BUNDLE_NAME"

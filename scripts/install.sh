#!/usr/bin/env bash
set -euo pipefail

OWNER="egwoo"
REPO="rename-spaces"
APP_NAME="Rename Spaces"
ASSET_NAME="Rename Spaces.zip"
INSTALL_DIR="/Applications"
FALLBACK_DIR="$HOME/Applications"

YES=false
OPEN_APP=false

usage() {
  cat <<EOF
Install $APP_NAME from the latest GitHub Release.

Usage:
  install.sh [--yes] [--open|--no-open]

Options:
  --yes       Skip prompts (may use sudo for /Applications).
  --open      Launch the app after install.
  --no-open   Do not launch after install (default).
EOF
}

confirm() {
  local prompt="$1"
  if $YES; then
    return 0
  fi
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      YES=true
      ;;
    --open)
      OPEN_APP=true
      ;;
    --no-open)
      OPEN_APP=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required."
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

API_URL="https://api.github.com/repos/$OWNER/$REPO/releases/latest"
echo "Fetching latest release from $OWNER/$REPO..."
RELEASE_JSON="$(curl -fsSL "$API_URL")"

asset_url=""
if command -v python3 >/dev/null 2>&1; then
  asset_url="$(python3 - <<'PY' <<<"$RELEASE_JSON"
import json, sys
data = json.load(sys.stdin)
target = "Rename Spaces.zip"
for asset in data.get("assets", []):
    if asset.get("name") == target:
        print(asset.get("browser_download_url", ""))
        sys.exit(0)
sys.exit(1)
PY
)"
elif command -v ruby >/dev/null 2>&1; then
  asset_url="$(ruby -rjson -e 'data=JSON.parse(STDIN.read); target="Rename Spaces.zip"; url=""; data["assets"].to_a.each{|a| if a["name"]==target then url=a["browser_download_url"]; break; end}; puts url; exit(url.empty? ? 1 : 0)' <<<"$RELEASE_JSON")"
else
  echo "Error: python3 or ruby is required to parse GitHub release JSON."
  exit 1
fi

if [[ -z "$asset_url" ]]; then
  echo "Error: could not find $ASSET_NAME in the latest release."
  exit 1
fi

ZIP_PATH="$TMP_DIR/$ASSET_NAME"
echo "Downloading $ASSET_NAME..."
curl -fL "$asset_url" -o "$ZIP_PATH"

UNZIP_DIR="$TMP_DIR/unzip"
mkdir -p "$UNZIP_DIR"
/usr/bin/ditto -xk "$ZIP_PATH" "$UNZIP_DIR"

APP_PATH="$(find "$UNZIP_DIR" -maxdepth 3 -name "$APP_NAME.app" -print -quit)"
if [[ -z "$APP_PATH" ]]; then
  echo "Error: $APP_NAME.app not found in the zip."
  exit 1
fi

install_to_dir() {
  local dest_dir="$1"
  local use_sudo="$2"
  if [[ "$use_sudo" == "true" ]]; then
    sudo mkdir -p "$dest_dir"
    sudo /bin/rm -rf "$dest_dir/$APP_NAME.app"
    sudo /usr/bin/ditto "$APP_PATH" "$dest_dir/$APP_NAME.app"
    sudo /usr/bin/xattr -dr com.apple.quarantine "$dest_dir/$APP_NAME.app" || true
  else
    mkdir -p "$dest_dir"
    /bin/rm -rf "$dest_dir/$APP_NAME.app"
    /usr/bin/ditto "$APP_PATH" "$dest_dir/$APP_NAME.app"
    /usr/bin/xattr -dr com.apple.quarantine "$dest_dir/$APP_NAME.app" || true
  fi
  echo "Installed to $dest_dir/$APP_NAME.app"
}

if [[ -w "$INSTALL_DIR" ]]; then
  install_to_dir "$INSTALL_DIR" "false"
else
  if confirm "Install to $INSTALL_DIR with sudo?"; then
    install_to_dir "$INSTALL_DIR" "true"
  else
    install_to_dir "$FALLBACK_DIR" "false"
  fi
fi

if $OPEN_APP || confirm "Open $APP_NAME now?"; then
  open "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || open "$FALLBACK_DIR/$APP_NAME.app"
fi

#!/usr/bin/env bash
set -euo pipefail

APP_EXECUTABLE="IPNetworkCalculator"
APP_FILENAME="IPNetworkCalculator.app"
DISPLAY_NAME="IP 地址计算器"
BUNDLE_IDENTIFIER="com.lawrenceywr.IPNetworkCalculator"
MIN_SYSTEM_VERSION="26.0"

INSTALL=false
INSTALL_PATH="/Applications/${APP_FILENAME}"
OUTPUT_PATH="/private/tmp/ipAddCal-package/${APP_FILENAME}"
RUN_TESTS=true
RUN_BUILD=true
KEEP_STAGING=false
INCLUDE_ICON=true
SIGN_IDENTITY="-"

usage() {
    cat <<'USAGE'
Usage: scripts/package-app.sh [options]

Builds a fresh macOS .app bundle for IPNetworkCalculator.

Options:
  --install              Replace the installed app at /Applications/IPNetworkCalculator.app
  --app-path PATH        Install to PATH instead of /Applications/IPNetworkCalculator.app
  --output PATH          Package-only output path when --install is not used
  --skip-tests           Do not run swift test before packaging
  --skip-build           Reuse the existing .build/release/IPNetworkCalculator binary
  --keep-staging         Keep the temporary staging directory after packaging
  --no-icon              Package without importing the icon from dev-win
  --sign-identity ID     Codesign identity to use; defaults to ad-hoc signing (-)
  --help                 Show this help text

Install behavior:
  The script always builds a new app bundle in a temporary staging directory.
  During installation, the old app bundle is moved aside, the new bundle is copied
  into place, and the backup is removed only after the replacement succeeds.
  This whole-bundle replacement avoids stale files left by older app versions.
USAGE
}

log() {
    printf '[package-app] %s\n' "$*"
}

die() {
    printf '[package-app] error: %s\n' "$*" >&2
    exit 1
}

require_tool() {
    command -v "$1" >/dev/null 2>&1 || die "required tool not found: $1"
}

assert_app_path() {
    local path="$1"
    [[ -n "$path" ]] || die "empty app path"
    [[ "$path" == *.app ]] || die "app path must end with .app: $path"
    [[ "$path" != "/" ]] || die "refusing to operate on /"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install)
            INSTALL=true
            shift
            ;;
        --app-path)
            [[ $# -ge 2 ]] || die "--app-path requires a path"
            INSTALL=true
            INSTALL_PATH="$2"
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || die "--output requires a path"
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --skip-tests)
            RUN_TESTS=false
            shift
            ;;
        --skip-build)
            RUN_BUILD=false
            shift
            ;;
        --keep-staging)
            KEEP_STAGING=true
            shift
            ;;
        --no-icon)
            INCLUDE_ICON=false
            shift
            ;;
        --sign-identity)
            [[ $# -ge 2 ]] || die "--sign-identity requires an identity"
            SIGN_IDENTITY="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "unknown option: $1"
            ;;
    esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
RELEASE_BINARY="${REPO_ROOT}/.build/release/${APP_EXECUTABLE}"
LOCAL_ICON="${REPO_ROOT}/Resources/AppIcon.icns"
VERSION_FILE="${REPO_ROOT}/VERSION"

require_tool swift
require_tool plutil
require_tool codesign
require_tool ditto
require_tool git
require_tool sips

assert_app_path "$OUTPUT_PATH"
assert_app_path "$INSTALL_PATH"
[[ -f "$VERSION_FILE" ]] || die "version file not found: $VERSION_FILE"

APP_VERSION="$(<"$VERSION_FILE")"
APP_VERSION="${APP_VERSION//[[:space:]]/}"
[[ "$APP_VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || die "invalid version in VERSION: $APP_VERSION"

BUILD_VERSION="$(git rev-list --count HEAD)"
[[ "$BUILD_VERSION" =~ ^[0-9]+$ ]] || die "invalid build version: $BUILD_VERSION"

cd "$REPO_ROOT"

if [[ "$RUN_TESTS" == true ]]; then
    log "running swift test"
    swift test
fi

if [[ "$RUN_BUILD" == true ]]; then
    log "building release binary"
    swift build -c release
fi

[[ -x "$RELEASE_BINARY" ]] || die "release binary not found or not executable: $RELEASE_BINARY"

STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ipaddcal-package.XXXXXX")"
APP_BUNDLE="${STAGING_ROOT}/${APP_FILENAME}"

cleanup() {
    if [[ "$KEEP_STAGING" == true ]]; then
        log "kept staging directory: $STAGING_ROOT"
    else
        rm -rf "$STAGING_ROOT"
    fi
}
trap cleanup EXIT

write_info_plist() {
    cat > "${APP_BUNDLE}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>zh_CN</string>
	<key>CFBundleDisplayName</key>
	<string>${DISPLAY_NAME}</string>
	<key>CFBundleExecutable</key>
	<string>${APP_EXECUTABLE}</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_IDENTIFIER}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>${DISPLAY_NAME}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${APP_VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${BUILD_VERSION}</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.utilities</string>
	<key>LSMinimumSystemVersion</key>
	<string>${MIN_SYSTEM_VERSION}</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST
}

extract_dev_win_icon() {
    local icon_path="$1"

    if git show "dev-win:src-tauri/icons/icon.ico" > "$icon_path" 2>/dev/null; then
        return 0
    fi

    if git show "origin/dev-win:src-tauri/icons/icon.ico" > "$icon_path" 2>/dev/null; then
        return 0
    fi

    return 1
}

prepare_icon() {
    [[ "$INCLUDE_ICON" == true ]] || return 0

    if [[ -f "$LOCAL_ICON" ]]; then
        log "using local app icon: $LOCAL_ICON"
        ditto "$LOCAL_ICON" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
        return 0
    fi

    local icon_source="${STAGING_ROOT}/icon.ico"
    if extract_dev_win_icon "$icon_source"; then
        log "importing icon from dev-win"
        sips -s format icns "$icon_source" --out "${APP_BUNDLE}/Contents/Resources/AppIcon.icns" >/dev/null
        return 0
    fi

    log "warning: dev-win icon not found; app will use the default macOS icon"
}

build_app_bundle() {
    log "assembling fresh app bundle in $APP_BUNDLE"
    mkdir -p "${APP_BUNDLE}/Contents/MacOS" "${APP_BUNDLE}/Contents/Resources"
    install -m 755 "$RELEASE_BINARY" "${APP_BUNDLE}/Contents/MacOS/${APP_EXECUTABLE}"
    write_info_plist
    prepare_icon

    plutil -lint "${APP_BUNDLE}/Contents/Info.plist" >/dev/null
    codesign --force --deep --sign - "$APP_BUNDLE"
    codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
}

quit_running_app() {
    osascript -e "quit app id \"${BUNDLE_IDENTIFIER}\"" >/dev/null 2>&1 || true
    sleep 0.5
}

replace_installed_app() {
    local install_dir
    local backup_name
    local BACKUP_PATH

    install_dir="$(dirname -- "$INSTALL_PATH")"
    backup_name=".$(basename -- "$INSTALL_PATH").previous.$$"
    BACKUP_PATH="${install_dir}/${backup_name}"

    mkdir -p "$install_dir"
    rm -rf "$BACKUP_PATH"

    if [[ -e "$INSTALL_PATH" ]]; then
        log "moving existing app aside: $INSTALL_PATH"
        mv "$INSTALL_PATH" "$BACKUP_PATH"
    fi

    log "installing fresh app bundle: $INSTALL_PATH"
    if ditto "$APP_BUNDLE" "$INSTALL_PATH"; then
        rm -rf "$BACKUP_PATH"
    else
        log "install failed; restoring previous app"
        rm -rf "$INSTALL_PATH"
        if [[ -e "$BACKUP_PATH" ]]; then
            mv "$BACKUP_PATH" "$INSTALL_PATH"
        fi
        die "failed to install app"
    fi

    touch "$INSTALL_PATH"
    codesign --verify --deep --strict --verbose=2 "$INSTALL_PATH"
}

replace_packaged_app() {
    local output_dir
    output_dir="$(dirname -- "$OUTPUT_PATH")"

    mkdir -p "$output_dir"
    rm -rf "$OUTPUT_PATH"
    log "writing package output: $OUTPUT_PATH"
    ditto "$APP_BUNDLE" "$OUTPUT_PATH"
    touch "$OUTPUT_PATH"
    codesign --verify --deep --strict --verbose=2 "$OUTPUT_PATH"
}

build_app_bundle

if [[ "$INSTALL" == true ]]; then
    quit_running_app
    replace_installed_app
    log "installed: $INSTALL_PATH"
else
    replace_packaged_app
    log "packaged: $OUTPUT_PATH"
fi

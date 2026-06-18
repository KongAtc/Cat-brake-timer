#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build/debug"
APP="$ROOT/dist/CatBreakTimer.app"
CONTENTS="$APP/Contents"

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  cd "$ROOT"
  swift build
fi

mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BUILD_DIR/CatBreakTimer" "$CONTENTS/MacOS/CatBreakTimer"
chmod +x "$CONTENTS/MacOS/CatBreakTimer"
cp -R "$BUILD_DIR/CatBreakTimer_CatBreakTimer.bundle" "$APP/CatBreakTimer_CatBreakTimer.bundle"
cp "$ROOT/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>CatBreakTimer</string>
  <key>CFBundleIdentifier</key>
  <string>local.CatBreakTimer</string>
  <key>CFBundleName</key>
  <string>CatBreakTimer</string>
  <key>CFBundleDisplayName</key>
  <string>Cat Break Timer</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "$APP"

#!/bin/bash
# 编译番茄钟菜单栏 App（只需要 Xcode Command Line Tools，不需要 Xcode 本体）
set -euo pipefail
cd "$(dirname "$0")"

APP="Build/Pomodoro.app"
rm -rf Build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

if [ ! -f "Resources/AppIcon.icns" ]; then
  echo "→ 生成 App 图标"
  swift Scripts/make-icon.swift
fi

echo "→ 编译 Sources/*.swift"
swiftc -O Sources/*.swift -o "$APP/Contents/MacOS/Pomodoro"

cp Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$APP/Contents/PkgInfo"
codesign --force --sign - "$APP" 2>/dev/null || true

echo "✅ 构建完成: $APP"

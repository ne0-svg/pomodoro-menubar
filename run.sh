#!/bin/bash
# 构建并启动番茄钟
set -euo pipefail
cd "$(dirname "$0")"

./build.sh
pkill -x Pomodoro 2>/dev/null || true
open "Build/Pomodoro.app"
echo "🍅 已在菜单栏启动（看屏幕右上角）"

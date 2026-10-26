# 番茄钟 · macOS 菜单栏小插件

原生 macOS 菜单栏番茄钟：菜单栏常驻**单色闹钟图标 + 倒计时**，点开是一个
贴合 macOS 设计语言的浮层面板（环形进度、SF Symbols、系统材质、胶囊按钮）。

纯 Swift，AppKit 负责状态栏、SwiftUI 负责面板，不依赖任何第三方库，
不需要 Xcode 本体，命令行即可编译成一个 `.app`。

## 界面

| 状态 | 预览 |
| --- | --- |
| 浅色 · 就绪 | `Preview/popover-light.png` |
| 浅色 · 计时中 | `Preview/popover-running.png` |
| 浅色 · 休息中 | `Preview/popover-rest.png` |
| 深色 · 就绪 | `Preview/popover-dark.png` |
| 菜单栏图标（浅 / 深） | `Preview/menubar.png` |

## 设计说明

- **状态栏图标**：直接用 emoji —— 计时状态显示 ⌛️，休息状态显示 ☕️，
  两个状态各只出现一个图标，不会同时出现。item 宽度固定，倒计时位数或
  emoji 切换都不会让锚定其上的面板跳动。
- **App 图标**：暖色渐变圆角底 + 白色沙漏 + 沙粒，由 `Scripts/make-icon.swift`
  离屏绘制并 `iconutil` 打包成 `Resources/AppIcon.icns`（构建时自动拷入 bundle）。
- **面板**：`NSPopover` + SwiftUI。环形进度（`Circle().trim` + 圆头端点）、
  等宽数字大号时间、`borderedProminent` 胶囊主按钮、`bordered` 次按钮、
  系统 pop-up 按钮与开关、语义化颜色（`.primary` / `.secondary` / `.accentColor`），
  深浅色自动适配。
- **排版**：13pt 半粗标题、44pt Rounded Light 计时、11pt 辅助说明，
  间距统一为 8 / 10 / 14 / 18。
- **定位**：`NSPopover` 自带的菜单栏自动定位在本机会把面板顶出屏幕上沿导致
  顶部被裁掉，因此 `popoverDidShow` 之外另做了屏幕几何校正，把面板夹在
  图标正下方、可见区域内。
- **稳定宽度**：状态栏 item 用固定宽度（按 `888:88` 量出来的 80pt），
  倒计时位数在 5:00 / 25:00 / 180:00 之间变化时图标不会变窄，
  锚定其上的面板也就不会左右跳动。

## 功能

- 菜单栏实时倒计时（等宽数字不跳动），运行中图标变实心
- 点图标打开面板；右键图标可直接退出
- 开始 / 暂停 / 继续 / 重置 / 跳过当前阶段
- 专注 / 休息时长：1–180 分钟任意值，可直接键入数字，也可用步进器 ±1 分钟微调
- 打开面板时不会把键盘焦点吸到输入框（避免误改时长）
- 自动循环：一轮 = 一次计时 + 一次休息。开启时休息结束自动进入下一轮；
  关闭时休息结束即自动停止，回到待机
- 阶段结束蜂鸣：合成**老式电子表方波「哔」声**（4000Hz / 55ms，振幅 80% 满刻度，
  播放音量 1.0，响度跟随系统输出音量），
  「滴滴。。」节奏：每组两声（间隔 0.28s，像呼吸换气）、组间停顿 0.65s，
  10 组共 20 声、约 10.4 秒；整段合成成一个音频一次播放，节奏不受主线程影响。
  点击开始/重置/跳过后立即停止，另可选系统通知
- 今日完成次数统计：以**北京时间 00:00** 为一天的分界，跨天自动归零
  （App 常驻时会定时在零点切换，无需重启）
- 设置写入 `UserDefaults`，重启后保留

## 构建 & 运行

```bash
cd "PomodoroMenubar"
./run.sh          # 编译 + 启动
```

或者分开做：

```bash
./build.sh                    # 产物：Build/Pomodoro.app
open Build/Pomodoro.app       # 启动后看屏幕右上角菜单栏
```

## 安装到 /Applications（可选）

```bash
cp -R Build/Pomodoro.app /Applications/
open /Applications/Pomodoro.app
```

## 开机自启

系统设置 → 通用 → 登录项 → 「登录时打开」点 `+`，选择 `Pomodoro.app`。
（App 设置了 `LSUIElement=true`，不占 Dock 和 Cmd+Tab，只在菜单栏。）

## 调整菜单栏里的位置

按住 `Cmd` 拖动菜单栏图标即可排序 / 移除。

## 卸载

```bash
pkill -x Pomodoro
defaults delete local.maxwell.pomodoro
rm -rf /Applications/Pomodoro.app
```

## 文件结构

```
PomodoroMenubar/
├── Sources/
│   ├── main.swift            # AppDelegate：状态栏 item、popover、调试钩子
│   ├── PomodoroEngine.swift  # 计时状态机 + 持久化 + 通知
│   ├── PopoverView.swift     # SwiftUI 面板
├── Resources/AppIcon.icns    # App 图标（脚本生成）
├── Scripts/make-icon.swift   # 图标绘制脚本
├── Info.plist                # LSUIElement=true（只驻留菜单栏）
├── build.sh                  # swiftc 编译 + ad-hoc 签名
└── run.sh                    # build + open
```

## 调试

```bash
# 打印状态栏 item 是否挂载成功、标题是否在走
POMODORO_DEBUG=1 POMODORO_DEBUG_START=1 ./Build/Pomodoro.app/Contents/MacOS/Pomodoro

# 离屏渲染面板与图标截图（不需要屏幕录制权限）
POMODORO_SNAPSHOT=/tmp/snap ./Build/Pomodoro.app/Contents/MacOS/Pomodoro
POMODORO_SNAPSHOT=/tmp/snap POMODORO_SNAPSHOT_RUNNING=1 ./Build/Pomodoro.app/Contents/MacOS/Pomodoro
POMODORO_SNAPSHOT=/tmp/snap POMODORO_SNAPSHOT_REST=1 ./Build/Pomodoro.app/Contents/MacOS/Pomodoro
POMODORO_SNAPSHOT=/tmp/snap POMODORO_SNAPSHOT_APPEARANCE=dark ./Build/Pomodoro.app/Contents/MacOS/Pomodoro

# 打印面板窗口 / 屏幕几何，检查是否贴住菜单栏
POMODORO_DEBUG_POPOVER=1 ./Build/Pomodoro.app/Contents/MacOS/Pomodoro

# 验证蜂鸣次数（工作结束 20 声、休息结束 20 声）
POMODORO_DEBUG=1 POMODORO_DEBUG_CHIME=1 ./Build/Pomodoro.app/Contents/MacOS/Pomodoro

# 导出合成的蜂鸣 wav（可用 afinfo/afplay 检查）
POMODORO_DUMP_BEEP=/tmp/watchbeep.wav ./Build/Pomodoro.app/Contents/MacOS/Pomodoro

# 改变时长并打印状态栏宽度 / 面板位置，检查是否还有跳动
POMODORO_DEBUG_RESIZE=1 ./Build/Pomodoro.app/Contents/MacOS/Pomodoro
```

`POMODORO_SNAPSHOT` 会写出 `-popover.png`、`-status-light.png`、`-status-dark.png`
三张图后自动退出，用于检查深色 / 浅色与运行态。

## 换成「脚本插件」方案？

如果不想维护一个 App，可以用宿主 App 的插件机制（适合改几行就生效）：

| 方案 | 形态 | 语言 | 适合 |
| --- | --- | --- | --- |
| 本项目（原生 App） | 独立菜单栏 App | Swift | 想长期用、要通知/声音/设置 |
| SwiftBar / xbar | 菜单栏脚本插件 | Shell / Python / JS | 10 行脚本快速出效果 |
| Übersicht | 桌面小组件 | JSX | 挂在桌面而不是菜单栏 |
| Hammerspoon | 菜单栏 + 全局快捷键 | Lua | 想和窗口管理联动 |
| Raycast 扩展 | 独立窗口 | TS/React | 想要搜索式交互 |

SwiftBar 版番茄钟最小实现（装好 SwiftBar 后放到它的插件目录，文件名如 `pomodoro.1s.sh`）：

```bash
#!/bin/bash
# <xbar.title>番茄钟</xbar.title>
# <xbar.desc>最简菜单栏番茄钟</xbar.desc>
# <xbar.refreshTime>1</xbar.refreshTime>

END_FILE="$HOME/.pomodoro_end"

case "${1:-}" in
  start) echo $(( $(date +%s) + 25*60 )) > "$END_FILE"; exit 0 ;;
  reset) rm -f "$END_FILE"; exit 0 ;;
esac

if [ ! -f "$END_FILE" ]; then
  echo "🍅 25:00"
  echo "---"
  echo "开始专注 | bash='$0' param1=start terminal=false refresh=true"
  exit 0
fi

left=$(( $(cat "$END_FILE") - $(date +%s) ))
if [ "$left" -le 0 ]; then
  rm -f "$END_FILE"
  echo "🍅 完成"
  exit 0
fi

echo "🍅 $(printf '%d:%02d' $((left/60)) $((left%60)))"
echo "---"
echo "重置 | bash='$0' param1=reset terminal=false refresh=true"
```

## 已知限制

- 用 ad-hoc 签名（`codesign --sign -`），没有公证，仅本机使用；分发给别人需要开发者证书。
- 通知通过 `osascript` 发送，首次可能被系统询问权限。
- 计时状态不跨进程重启保存（重启 App 回到就绪状态，今日计数会保留）。
- 面板为 SwiftUI，最低 macOS 13。

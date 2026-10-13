# cal_paste（财务快贴）· AI 维护指南

> 本文件写给 AI agent（Claude Code / Codex / Cursor / ZCode 等）和技术用户。
> 用户说"帮我改 cal_paste 的某个功能"时，**先读完本文件再动手**。

## 这是什么

Windows 桌面常驻小工具（AutoHotkey v2，单文件）：财务人员按住 CapsLock 前缀加字母键，
对**选中的数字**就地加减乘除、元↔万元换算、或写入累加器后直接粘贴回原位。
全部代码在 `cal_paste.ahk`（约 450 行），按键配置在 `config.ini`（首启自动生成）。

## 文件清单

| 文件 | 用途 | 维护规则 |
|---|---|---|
| `cal_paste.ahk` | 主程序（唯一代码文件） | UTF-8 with BOM，**保持原编码保存** |
| `使用说明.txt` | 普通用户说明书 | 改了功能/键位必须同步改它 |
| `config.ini` | 用户的按键配置+变量存储 | ⚠️ 不进仓库；首次运行自动生成（UTF-16 由代码写入，是故意的，别"修复"） |
| `README.md` / `LICENSE` | 仓库首页 / 开源协议 | — |

## 硬性契约（改代码必须遵守，违反 = 回归 bug）

1. **剪贴板还原**：每个功能开头 `saved := ClipboardAll()`；**每条退出路径**
   （包括出错提前 return）都要 `A_Clipboard := saved`。用户剪贴板永不丢失。
2. **复制等待统一 `ClipWait(0.6)`**：慢软件（SAP、老网页）0.3 秒复制不完，
   会误判"没选中"而贴错数——财务工具贴错数是事故。
3. **数字提取/格式化只走 `GrabNum()` / `FmtNum()`**：全角逗号、千分位、货币符号、
   "-0"、浮点尾数都在这两处集中处理，禁止在功能函数里自己写正则。
4. **提示文案用中文人话**：`Notify()` 气泡带 📌/⚠️ 前缀，报错要说清"用户该怎么做"。

## 加一个新功能（四步，约 10 分钟）

以 `K = ÷1000粘贴` 为样板，全局搜索 `to_kilo` 照抄：

1. `gDefs` 加一行：`"to_kilo", IniRead(iniFile, "hotkeys", "to_kilo", "K")`
2. `gNames` 加一行中文名（气泡和按键冲突提示会用到）
3. `DoAction()` 加一个 `case`
4. 照抄 `ToWan()` 写功能函数；`WriteDefaultConfig()` 模板加同名行

改完让用户：托盘绿 H 图标右键 → 重新加载配置（或重启脚本）。

## 常见改动落点速查

| 用户诉求 | 改哪里 |
|---|---|
| 换某个功能的按键 | 不改代码！让用户改 `config.ini` 对应行 → 托盘重载 |
| 换前缀（CapsLock 改别的） | `config.ini` 的 `prefix=`（支持 CapsLock/CtrlAlt/CtrlShift/AltShift/CtrlAltShift） |
| 新增功能 | 上节四步 |
| 改气泡/报错文案 | 对应功能函数里的 `Notify(...)`；功能中文名在 `gNames` |
| 支持新前缀键 | `PrefixToAHK()` 的 switch 加分支 |

## 改完必测（5 项，2 分钟）

1. **正常路径**：选中数字按键 → 气泡算式正确、粘贴内容正确
2. **剪贴板还原**：操作前复制一段文字 → 操作后 Ctrl+V 出来的还是原文字
3. **出错路径**：什么都不选中直接按 → 出气泡提示、无粘贴、无报错弹窗
4. **单按 CapsLock** 仍是正常大小写切换（前缀键不劫持原功能）
5. **文档同步**：`使用说明.txt` 的键位表/使用场景与代码一致

## 已知坑（真实踩过，别再踩）

- AHK v2 没有 v1 式语句：`DetectHiddenWindows On` 的 `On` 会被当成未定义变量
  弹警告窗，必须写 `DetectHiddenWindows true`
- `GetKeyState` 第 1 参是**键名**（`"CapsLock"`），不是状态名（`"CapsLockState"`），
  第 2 参 `"T"` 才是取 toggle 状态
- vbs/ps1 那套"纯 ASCII"规则不适用于本脚本：本脚本必须保留中文和 emoji，
  乱码多半是保存时编码被改（见文件清单）
- 本文件与 `cal_paste.ahk` 头部【维护速览】同源：改契约时**两处一起改**

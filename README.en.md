[简体中文](README.md) | **English**

# cal_paste · Financial Quick-Paste

**Select a number → hotkey-calculate → paste back in place.** A Windows utility for accountants and finance folks. Single AutoHotkey v2 file (≈450 lines), no runtime needed.

Stop doing copy → switch to calculator → calculate → copy → switch back: select a number, press one key, it becomes the result in place.

<!-- TODO: 10-second demo GIF, drop docs/demo.gif and uncomment
![demo](docs/demo.gif)
-->

## Features (10 hotkeys)

Default keys below — **every key is customizable** (see the bottom). All hotkeys = hold CapsLock, press a letter. CapsLock alone still toggles case as usual.

| Key | Action | Description |
|---|---|---|
| `CapsLock+A` | Add-paste | Selected number becomes (number + variable) in place; nothing selected → pastes the variable itself |
| `CapsLock+C` | Set variable | Select a number, press this — it becomes the variable (shared by add/multiply/divide) |
| `CapsLock+S` | Flip sign | +3000 ↔ -3000 (credit-notes / negative amounts) |
| `CapsLock+M` | Multiply-paste | Selected number × variable (e.g. tax rate 1.13) |
| `CapsLock+D` | Divide-paste | Selected number ÷ variable |
| `CapsLock+W` | Yuan → 10k | Copy 25000 → press → pastes 2.5 |
| `CapsLock+Y` | 10k → Yuan | Copy 2.5 → press → pastes 25000 |
| `CapsLock+K` | ÷1000 paste | Yuan→thousands, mm→m, same pattern |
| `CapsLock+X` | Accumulate | Selected number is added to a running total (**nothing pasted**), a tooltip shows the running sum |
| `CapsLock+Z` | Paste total | Pastes the accumulated total and resets the accumulator |

A tooltip next to your mouse shows the exact math on every operation, so mistakes are visible at a glance.

## Install (2 minutes)

1. Install AutoHotkey v2 from [autohotkey.com](https://www.autohotkey.com/) (free, next-next-next)
2. Download [`cal_paste.ahk`](cal_paste.ahk) from this repo and **double-click it** — a green **H** icon appears in the tray = running
3. (optional) Auto-start: right-click `cal_paste.ahk` → Create shortcut → `Win+R` → type `shell:startup` → move the shortcut in

## 3 typical workflows

1. **Every amount needs +3000**: select 3000, press `C` to set the variable → from now on, select any number and press `A`
2. **Yuan ↔ 10-thousand yuan**: copy 25000, press `W` to get 2.5; the other way round press `Y`
3. **Sum ten scattered numbers on a page**: select each number and press `X` (tooltip shows the running total) → click where the result should go, press `Z` to paste the total and reset. Negative amounts work too.

## Customize keys (no coding needed)

Open `config.ini` in Notepad, change the letter after `=`, save, then tray green **H** icon → right-click → **Reload config**.

- Change the prefix: `prefix=CapsLock` can be `CtrlAlt` / `CtrlShift` / `AltShift` / `CtrlAltShift` (e.g. `CtrlAlt` makes add = Ctrl+Alt+A)
- Don't need a feature: leave the value after `=` empty
- Standalone hotkeys: set `F1`–`F12` (prefix not required)
- Broken config? The script pops a dialog telling you exactly which line is wrong

## Let AI modify it for you

The repo ships an [`AGENTS.md`](AGENTS.md) maintenance guide written for AI coding agents (Claude Code / Codex / Cursor / ...): throw the folder at your AI and say "add a XX feature" — it will automatically pick up the hard contracts, the 4-step recipe for new features, the test checklist and known pitfalls.

## Details you might care about

- **Your clipboard is never overwritten**: every operation — including error paths — restores your previous clipboard content
- Thousands separators (`3,000` / `3，000`) and currency symbols are ignored automatically; floating-point noise (113.00000000000001) is cleaned up
- Variable and accumulator persist in `config.ini` across reboots
- Each operation simulates one Ctrl+C to read the selection (0.6 s wait, tolerant of slow apps like SAP)

## License

[MIT](LICENSE)

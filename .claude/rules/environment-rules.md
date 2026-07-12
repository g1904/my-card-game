# Environment rules (machine-specific)

> This records the **maintainer's machine** reality. It is not a universal convention — re-check after cloning to another machine.

## Platform
- OS: Windows 11. Shell: PowerShell (primary). Bash (Git Bash) also available.

## Available tools (usable directly)

| Tool | Notes |
|------|-------|
| `git` | Version control. |
| `dotnet` | .NET SDK — builds the C# assembly for the Godot project. |
| Godot editor | Godot 4.7 (.NET build). Opening/running/exporting the game is done from the **editor GUI**, not assumed on PATH. |
| Rider | C# IDE. |
| `chrome` | Available on PATH (useful for the web export target). |

## Broken / unavailable — do not depend on

- **`python` is broken.** On this machine `python` resolves to the Windows Store app-execution-alias stub and fails. **No hook or script may depend on python.** (The old harness's python-based edit-guard hooks were removed for exactly this reason.)
- Assume `node`/`npm`, `docker`, `gh` are **not** on PATH unless verified. If a step needs one, skip it and tell the user to run it manually.

## Build / run / verify

- **No CLI compile-check for gameplay code by default.** Verify by opening the project in the Godot editor and pressing Play, or by running an export. A headless `godot --headless` build check is only valid if a Godot binary is actually on PATH (verify first).
- `dotnet build` on the project's `.csproj` can catch C# compile errors, but the authoritative check is the Godot editor build (it drives the .NET build with the correct Godot references).
- No unit/integration tests are required unless the user asks.

## Hooks

- **There are no PreToolUse/SessionStart/Notification hooks.** `settings.json` has no `hooks` key. Branch-folder discipline is a convention enforced by `Context.md`, not by tooling.

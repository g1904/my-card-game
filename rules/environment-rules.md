# 环境规则（机器相关）

> 这记录的是**维护者的机器**实况。它不是普适约定 —— 克隆到另一台机器后需重新核对。

## 平台
- 操作系统：Windows 11。Shell：PowerShell（主要）。Bash（Git Bash）也可用。

## 可用工具（可直接使用）

| 工具 | 说明 |
|------|------|
| `git` | 版本控制。 |
| `dotnet` | .NET SDK —— 为 Godot 项目构建 C# 程序集。 |
| Godot 编辑器 | Godot 4.7（.NET 构建）。打开/运行/导出游戏通过**编辑器 GUI** 完成，不假定其在 PATH 上。 |
| Rider | C# IDE。 |
| `chrome` | 在 PATH 上可用（对网页导出目标很有用）。 |

## 已损坏 / 不可用 —— 不要依赖

- **`python` 已损坏。** 在本机上 `python` 解析到 Windows 应用商店的应用执行别名（app-execution-alias）桩并失败。**任何钩子或脚本都不得依赖 python。**（旧工具配置中基于 python 的编辑守卫钩子正是因此被移除。）
- 假定 `node`/`npm`、`docker`、`gh` **不**在 PATH 上，除非已核实。如果某个步骤需要它们，跳过并告知用户手动运行。

## 构建 / 运行 / 验证

- **默认不对玩法代码做 CLI 编译检查。** 通过在 Godot 编辑器中打开项目并按 Play，或通过运行一次导出来验证。仅当确有一个 Godot 二进制在 PATH 上（先核实）时，无头的 `godot --headless` 构建检查才有效。
- 对项目的 `.csproj` 运行 `dotnet build` 能捕获 C# 编译错误，但权威检查是 Godot 编辑器构建（它以正确的 Godot 引用驱动 .NET 构建）。
- 除非用户要求，不要求任何单元/集成测试。

## 钩子

- **没有 PreToolUse/SessionStart/Notification 钩子。** `settings.json` 没有 `hooks` 键。分支文件夹纪律主要由 `Context.md` 约束；此外 `settings.json` 的 permission **deny 规则**会拦截对四个只读快照目录（`game-testing-branch/`、`game-production-branch/`、`backend-testing-branch/`、`backend-production-branch/`）的 Edit/Write（Bash 写入不在拦截范围内）。

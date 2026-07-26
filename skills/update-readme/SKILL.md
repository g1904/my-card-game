---
name: update-readme
description: 对账仓库中所有 README.md 与它们所描述的实际内容（目录结构、技能清单、规则文件、设计库布局、根约定），把失真之处直接重写为最新事实。只写 README，不改被描述的对象。
argument-hint: [all | .claude | main | game-design | backend | <path/to/README.md>]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Update README

README 是**描述性**文档：它们不产生事实，只转述别处的事实（文件夹里实际有什么、`skills/` 里实际有哪些技能、`rules/Context.md` 实际怎么约定、设计库实际怎么组织）。随着项目演进，README 是最容易悄悄失真的一层。本技能把每份 README 重新对齐到它所描述的对象。

**范围守则：** 只写 `README.md` 文件。发现 README 与事实不符时，**改 README，不改事实**——除非用户明确要求。若 README 描述的做法明显优于现状（即 README 才是意图、现状是遗漏），如实报告给用户裁决，不擅自改动被描述的对象。

**写作守则（承自 `rules/Context.md`）：** 只保留最新事实，**重写替换**而非追加。不写「原为 X / 已改为 Y / 取代 Z / 旧结构保留待清理」之类的考古；历史归 git。语言沿用该 README 已有的语言（本仓库为中文正文 + 英文代码标识/树注释）。

## 步骤

### 1. 确定范围
解析 `$ARGUMENTS`：
- `all` 或空 → 下表全部。
- `.claude` / `main` / `game-design` → 只处理对应目录的 README。
- `backend` → 只处理 `backend-design-documents/` 与 `backend-feature-branch/` 的 README。
- 具体路径 → 只处理该文件。

**在范围内的 README（可写）：**

| README | 描述的对象 |
|---|---|
| `.claude/README.md` | 工具配置：技能、规则、知识、脚本、settings、`.gitignore` 忽略面 |
| `main/README.md` | 仓库分支指南：两条提升线 + 设计 / 配置分支、文件夹映射 |
| `game-design-documents/README.md` | 客户端设计库布局与设计→需求→代码流水线 |
| `backend-design-documents/README.md` | 后端设计库布局、与 `game-design` 的分线理由 |
| `backend-feature-branch/README.md` | 后端开发状态、技术栈、提升线 |

**绝不**编辑只读参考快照下的任何 README：`game-testing-branch/`、`game-production-branch/`、`backend-testing-branch/`、`backend-production-branch/`。它们各自的 README 由对应的 feature 分支提升带入。

Glob 时同时排除 `.godot/`、`bin/`、`obj/`、`node_modules/`。

### 2. 逐份 README：读它，再采集它所描述的事实
先完整读这份 README，列出它做出的**可核验断言**，然后逐条采集对应事实来源：

| README 中的断言类型 | 事实来源 |
|---|---|
| 目录树 / 文件清单 | `Get-ChildItem` 实际列目录 |
| 技能清单及其一句话说明 | `.claude/skills/*/SKILL.md` 的 frontmatter `name` + `description` |
| 规则文件清单及说明 | `.claude/rules/*.md` 的标题与首段 |
| 知识区结构 | `.claude/knowledge/**` 实际布局 + 各 `_index.md` |
| 根约定 / 工作流描述 | `.claude/rules/Context.md`（约定的权威） |
| 工作区 / 分支布局 | 顶层实际文件夹 + `git ls-remote --heads origin` 实际分支 + `.claude/scripts/push-all-impl.ps1` 的 `$branchDirs`（含 `.claude` 自身）|
| 哪些文件不入库 | 各检出的 `.gitignore`（`.claude/.gitignore` 决定工具配置的忽略面）|
| 客户端设计库文件夹图例、流水线 | `game-design-documents/` 实际文件夹 + 根级关键文件 |
| 后端设计库布局、后端状态 | `backend-design-documents/` 实际文件夹 + `backend-feature-branch/` 实际内容 |
| 客户端 ↔ 后端边界的描述 | `game-design-documents/system-overview.md`、`20-systems/services/_index.md` |
| 游戏定位（平台、朝向、在线性、引擎版本） | `rules/Context.md` 的「项目」段 + `game-design-documents/00-vision/scope.md` |
| 引擎 / 渲染 / autoload 等技术参数 | `game-feature-branch/project.godot` |
| 工具链、可用命令 | `.claude/rules/environment-rules.md` |

### 3. 逐条判定并修复
对每条断言判定为：
- **失真** —— 与事实矛盾（如 README 写「离线，存档持久化到 `user://`」而约定已改为「强制在线、云端权威」）→ **直接重写**为事实。
- **过时的清单** —— 目录树/技能表缺项、多出已删项、说明与 `SKILL.md` 的 `description` 不符 → 补齐 / 删除 / 改写，并保持该 README 既有的排版格式（表格就用表格，树就用树，注释风格一致）。
- **悬空引用** —— 指向已不存在的文件/文件夹/技能 → 改指当前位置，或删除该行。
- **跨 README 不一致** —— 同一事实在多份 README 中说法冲突 → 全部对齐到事实来源（而非互相抄）。
- **正确** —— 不动。最小扰动：不为文风重排一份已经准确的 README。

### 4. 交叉校验
全部改完后再扫一遍：各份 README 对**共有话题**的表述必须彼此一致且与事实来源一致：游戏定位一句话、分支 / 文件夹布局、两条提升线的方向与命名、客户端 ↔ 后端的边界描述、设计→需求→代码的工作流、技能名。

### 5. 报告
```
## README sync: <范围>

### Updated
- <README 路径>
  - <改了什么> ← 依据：<事实来源路径>

### Fact ≠ README（需要用户裁决，未改动）
- <README 路径>: README 称 <X>，现状 <Y>——疑似现状缺失而非 README 失真

### Clean（已核对，无失真）
- <README 路径>
```

# ADR-0012 — 授予来源 `Source` 的跨边界表示：契约走字符串枚举名，名与 code 双双冻结

- **状态：** Accepted
- **日期：** 2026-08-14
- **来源：** `handoffs/2026-08-12-grant-source-code-contract.md` · `handoffs/2026-08-14-profile-sync-contract.md` · `answer-logs/log-profile-sync-contract.md`

## 背景

两条既定通则在同一个字段上正面相撞，且**都明写覆盖「上行负载」**：`contracts/envelope.md` §2 定「枚举值一律字符串、与客户端 C# 枚举名逐字相同」；客户端定「`code` = 显式稳定整数，是存档与上行负载里实际序列化的东西」。二者不能同时成立。同时 `Source` 由封闭三值扩为按 `(Kind, Scope)` 分域的开放清单，而它正是后端复算 `x` 的自变量——收不了口，`profile-sync.md` §5 的透明白名单就写不实。

## 决策

**契约侧一律走字符串枚举名，存档侧走整数 code，客户端在序列化边界做一次映射。**

- `sourceCode` 在报文中的取值形如 `"FinaleWin"`，**与客户端 C# `enum Source` 成员名逐字相同**；存档内仍是整数 code。
- **`Source` 的成员名与 code 双双冻结**，已删成员的名与 code **永不复用**。
- 后端对**未知取值记录原值、不改写、不拒收**。
- 后端**不复制** `(Kind, Scope) → 允许的 Source 集合` 那张合法子集表。
- 只有**账号级** `/playerPower[*]/sourceCode` 进透明白名单（承载 `x = count(sourceCode == "FinaleWin")`）；**轮回级两类不进**，随 `characterDiffs` 整体不透明。

逐条兑现与白名单行 → `contracts/profile-sync.md` §5 §5a。

## 理由

**通则不开例外的价值高于重命名自由，而重命名本就极少发生**（`contracts/profile-sync.md` §5a 逐字）——`contracts/envelope.md` 自己在 GET-body 那条上用过同一句反驳。

未知取值**不得**归一为 `Unknown` 并回写：那会直接压低 `x`、让残卷档位回跳，推翻客户端「`x` 单调不减 ⇒ 档位只降不回跳」这条承重不变式（`handoffs/2026-08-12-grant-source-code-contract.md` 标为「最要紧的一条」）。

合法子集表约束的行为**根本不发生在服务端**，复制过来即第二处真值、必然漂移——与「回链而非复述」同源。

轮回级两类不进透明档：对后端无规则用途，而每条透明路径都要背上路径稳定性约束（路径移动 / 重命名 = 破坏性契约变更）。

## 备选方案

- **给 `Source` 在 `envelope.md` 开一个整数例外** — 有例外的通则不是通则。
- **两侧统一改用整数 code、推翻 `envelope.md` 的字符串枚举约定** — 影响面远超本字段（`OpError.code`、`reason`、三分支应答的枚举全在内），不为一个字段掀桌。
- **轮回级两类 `sourceCode` 进透明档** — 纯透传、无规则用途，`characterDiffs` 整体不透明。
- **后端复制 `(Kind, Scope)` 合法子集表以校验组装合法性** — 第二处真值。

## 后果

- `contracts/envelope.md` §2 的字符串枚举通则**保持零例外**；`sourceCode` 的 JSON path 移动 / 重命名即破坏性契约变更。
- 放弃**契约侧重命名 `Source` 成员的自由**（真要改须 bump `schemaVersion`、两侧同批切换、不设兼容期——三个成立前提见 `ADR-0014`）；放弃后端据 `(Kind, Scope)` 校验组装合法性的能力。
- 「未知取值仅记账、不拒绝、不改写」的**处置语义**权威在 `ADR-0005`（防作弊边界），本 ADR 只定线上表示，不复述处置。
- 集合字段名恒为单数（`playerPower`）属 `ADR-0014`。
- 客户端侧对位（`Source` 成员清单、四类各自的授予来源共有字段、序列化边界映射）权威在 `game-design-documents/systems/common-properties.md` 与 `game-design-documents/systems/player-profile/player-power/_index.md`；受影响成分为 `game-design-documents/systems/services/sync-service.md`。

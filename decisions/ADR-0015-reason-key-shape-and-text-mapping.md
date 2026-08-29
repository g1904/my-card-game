# ADR-0015 — `reasonKey` 形态锁死为 PascalCase，二级文案键由 `code` + `reasonKey` 机械变换

- **状态：** Accepted
- **日期：** 2026-08-16
- **来源：** `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md` · `answer-logs/log-compliance-and-session-arbitration.md`

## 背景

`auth.session_revoked` 一个 `code` 底下藏着对玩家完全不同的几句话（「另一设备登录」与「账号被运营吊销」），而 §5a 已定客户端**不得解析 `message`**——触发源必须对代码可见，于是落进 `detail.reasonKey`。四条 `compliance.*` 与 `auth.nickname_rejected` 各自也在用同一个字段名做同一件事。三处共用一个字段，却没有一处规定它长什么样，而客户端的错误文案键是**机械变换**得来的、没有手写对照表。

## 决策

**`reasonKey` 的全部取值用 PascalCase，形态自此锁死**，三处共用同一套规则（`auth.session_revoked` · `auth.nickname_rejected` · `compliance.*`）。

- **二级文案键由 `code` + `reasonKey` 机械变换得到**：`reasonKey` 按大写字母切分为 UPPER_SNAKE 后拼在一级键之后——`auth.session_revoked` + `SignedInElsewhere` → `ERR_AUTH_SESSION_REVOKED_SIGNED_IN_ELSEWHERE`。
- **未知 `reasonKey` → 退回一级键**（`ERR_AUTH_SESSION_REVOKED`）。因此后端新增一个取值**不要求客户端同批发版**。
- 取值表可持续扩张，但**引用它的地方一律写指路、不写条数**。

取值表与逐条语义 → `contracts/auth.md` §10；`compliance.*` 侧 → `contracts/compliance.md` §5。

## 理由

契约面上「一个字段的取值来自一个封闭集合」这件事，**现存全部先例都是 PascalCase**（`contracts/envelope.md` §2 的枚举值约定：`"Phone"` · `"SignIn"` · `"Rebind"` · `"Conflict"`）。让 `reasonKey` 成为唯一异形，只会让「到底该写哪种」在日后每加一个取值时被重新提出一次。

**锁死是必须的**：中途改大小写会让已发版客户端的机械变换全部落空，且是一次**静默失效**——文案回落到一级键，没有任何报错（`contracts/auth.md` §10）。

「未知取值退回一级键」与 `contracts/envelope.md` §5b「未知 `code` → 按 `class` 降级」同构，是取值表可以持续扩张的前提。

## 备选方案

- **`reasonKey` 用 camelCase** — 论据本身成立（它不是 C# 枚举、客户端必须容忍未知值，故 `envelope.md` §2 对它无适用对象），但代价是让它成为契约面上唯一的非 PascalCase 封闭取值集，而这类不一致正是「到底该写哪种」被反复提出的来源。
- **客户端维护一张 `reasonKey` → 文案键的手写对照表** — 与客户端已定的「`ERR_*` 由 `code` 机械变换、无手写对照表」正面冲突，且每加一个取值就要发一次版。
- **把触发源只写进 `message`** — §5a 已定客户端不得解析 `message`。
- **为每个触发源各开一个 `code`** — 玩家处置相同时只让处置表多几行走同一条路径（`restricted` / `banned` 共用 `compliance.account_restricted` 即此判据的应用）。

## 后果

- 形态锁死是一条**跨契约的护栏**：`contracts/auth.md`、`contracts/compliance.md` 以及日后任何引入 `reasonKey` 的域都受它约束；`contracts/envelope.md` §6 台账**只写指路、不复述取值表**。
- 后端可单方面扩张取值表；客户端**只在需要为新取值写二级文案时**才发版，缺文案的降级路径是无声的（回落一级键）——这一点在增补取值时必须被记住。
- 客户端侧的键命名规范、`ERR_*` 机械变换与二级文案措辞权威在 `game-design-documents/ux/error-and-blocking-ux.md`；本库不代为规定文案。
- `auth.session_revoked` 与 `auth.token_expired` 必须是两个 `code`（客户端处置完全不同）这条属 `contracts/envelope.md` §6 的既有台账纪律，不由本 ADR 承载。

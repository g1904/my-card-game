# ADR-0026 — 未过审昵称的处置只落 `status` 侧，后端绝不改写或置空云端昵称

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** `handoffs/2026-09-03-nickname-moderation-and-risk-control.md` · `answer-logs/log-nickname-moderation-and-risk-control.md`

## 背景

昵称违规必须有一条出路。两个方向二择一：P1 = 把玩家直接挡在门外（`restricted`），或后端带外改写 / 置空那个昵称；P2 = 玩家可照常登录，先去改名。同时 `auth.md` §8 如实记下了一条残留代价——改包客户端可以跳过改名端点、直接把未过审昵称 push 上来。

## 决策

**取 P2：处置只落 `status` 侧，后端绝不改写或置空云端昵称。**

- 三档阶梯：**观察**（`status` 不变，玩家无感）→ **须改名**（`status` 不变，`GET /v1/compliance/status` 的 `nicknameChangeRequired` 为真，登录后走一次改名流程即自解除）→ **限制 / 封禁**（`restricted` / `banned`，申诉走站外）。
- `nicknameChangeRequired` **由云端状态算出**，且**不在端点判定通过的那一刻清零**——玩家改名并 push 后由存量扫描 T1 的比对自动清零。
- `restricted` / `banned` 的解除**只改回 `status`，永不带外改写昵称**。
- 绕过路径由**存量扫描 T1 确定性检出**承接：比对本次 `nickname` 与该账号最近一次经改名端点接受的值，不等即判绕过——**只记账与判定，绝不拒绝上行、绝不改写**。
- 扫描台账落后端内部存储，**不进 profile**。处置阶梯、三条触发源与台账字段 → `operations/moderation.md`；服务内部形态 → `systems/account.md`。

## 理由

**后端改写 / 置空由两条独立理由封死。** 其一：`/accountInfo/nickname` 不满足「够格进 `profile-sync.md` §5 后端写入表」的判据——它的真值在客户端输入侧。其二：扩那张表会由 §5c 的恒等式**自动引入回声约束** ⇒ 每个改过名的玩家每次改名都丢一次本地缓冲（`contracts/auth.md` §8 把这列为反例一）。

**取 P2 的依据是三条既定纪律的合力**：pillar #4 不阻塞玩家 · 「仅两处硬阻塞」· 昵称**零玩家间可见性**——把玩家整个挡在门外与实际危害不成比例。

**T1 只记账不拒绝**：`/accountInfo/nickname` 不受回声校验约束（客户端有权写它），在 push 上拒绝会同时撞「客户端有权写的路径只记账不拒绝」「同步通道不承载合规拦截」与 pillar #4（`operations/moderation.md`）。而 T1 本身近乎零成本——后端本就要解 `playerDiff` 的顶层键，比对是一次字符串比较。

## 备选方案

- **P1：昵称违规即硬阻塞主线** — 与 pillar #4、「仅两处硬阻塞」相抵；昵称零玩家间可见性使代价与危害不成比例。`restricted` 因此降为**升级档**（拒不改名 / 恶意反复 / 申诉驳回）。
- **运营带外改写或置空 profile 里的昵称** — 不够格进后端写入表，且扩表会自动引入回声约束，代价落在每个改过名的正常玩家身上。
- **在 push 上拒绝含违规昵称的上行** — 同时撞三条既定纪律，收益是阻断一个零玩家间可见性的字段。
- **标记在改名端点判定通过的那一刻清零** — 造出「调用端点但不 push」的绕过路径。
- **存量扫描只做定期抽查** — T1 零成本且确定性，抽查是纯降级。
- **扫描台账写进 profile** — 后端内部状态，且写入字段表封闭。

## 后果

- **后端写入字段表不需要任何运营例外**——这是 `ADR-0008` 回声约束封闭性的第二个执行点。
- `contracts/compliance.md` §10 因此有 `nicknameChangeRequired` 这一字段（**不带 `reasonKey`**）；`status` 变更连带吊销全部会话、下行 `OperatorRevoked`（`ADR-0011`）。
- 复核队列与存量扫描是**同一条处置通道的两个入口**，不是两套机制。
- 三条触发源（T1 push 驱动 / T2 词表版本驱动 / T3 定期兜底）与词表的不可变版本化互为前提：没有版本化，T2 只能退化为每次全量 → `operations/moderation.md`。
- 玩家可见措辞归客户端（`game-design-documents/ux/error-and-blocking-ux.md`），本库只定 `status`、`reasonKey` 与标记字段。
- **不新增任何 `code`、不扩后端写入字段表** ⇒ 回声约束面不变、`schemaVersion` 不 bump。

# 昵称判定链与审核口径 · 未过审昵称的存量扫描 · 风控事件流与阈值

- id: 2026-09-03-nickname-moderation-and-risk-control
- date: 2026-09-03
- topic: contracts/auth（§8 判定链与两条承重口径）· contracts/compliance（`nicknameChangeRequired` 的语义来源 · §5 取值表首版不扩）· operations（词表版本化发布 · 存量扫描 · 风控事件流与阈值）· systems/account（判定链的服务内部形态）
- status: distilled
- distilled-to: `contracts/auth.md`、`contracts/compliance.md`、`operations/moderation.md`、`systems/account.md`、`systems/_index.md`、`open-questions/02-account-compliance.md`、`answer-logs/log-nickname-moderation-and-risk-control.md`

## Intent（distilled）

**一句话：** 三条待答项（敏感词口径 · 存量扫描 · 风控落地）共用同一个挂接点 `account.status`，一起答；答案是——判定链四级短路、复核走 accept-then-review、未过审昵称**不改写 profile** 而落一个「须改名」标记、风控取轻量档（事件流 + 累计计数 + 工单，`status` 变更须人工确认 + 全局熔断）。

### 1. 判定链：四级短路，顺序即语义

形态 → 频次 → 词表 → 第三方审核适配器 → 接受，**第一个失败级决定 `reasonKey`**。顺序不可颠倒：使「既超长又含敏感词」的应答唯一（`Malformed`），验收断言无歧义；且把唯一有外部成本的一级放最后，被频次闸挡住的刷子不产生外部调用。

两条承重口径：**频次计数只对被接受的一次改名 `+1`**（拒绝不计数，与「重复提交同一昵称回 `204`」配套——重放不消耗配额）；**词表判定用归一化串、`Malformed` 判定用原串**（不归一化则插一个零宽空格即绕过；长度判定不用原串则玩家看到的字数与判定不一致）。

### 2. 「待审」不进报文：accept-then-review

三值 `reasonKey` 表不扩第四值。给它加「待审」意味着端点从即时判定变成长时状态机，而 `compliance.md` §1 正是以这条相反纪律把合规域拆出 auth 域的。因此复核级一律先接受（`204`），昵称照常由客户端 push 写入，后台排进复核队列。**复核队列与存量扫描是同一条处置通道的两个入口**，不是两套机制。

第三方审核**首版不启用、只留适配器位**（透传恒放行）；适配器不可达时按「待复核」接受（`204`），不返回 `SensitiveWord`——把外部抖动伪装成明确拒绝会让玩家以为自己的昵称违规，与「渠道不可达 ≠ 明确拒绝」同源。

### 3. 词表：后端配置 · 不可变版本化 · 两档分级

词表不下发客户端、不进任何报文（客户端自带一份就是第二权威）。发布形态逐条复用 flags 规则集的 O1–O7 与留痕四项——**不是顺手抄一套：存量扫描必须能回答「这个昵称当初按哪一版词表放行」**，而随手改数据源正是 O1 要堵的静默失效模式。两档分级（禁止级 / 复核级）；**「放行」不是第三档，是补集**。来源三条通道（公开基础表导入 / 复核回灌 / 渠道反馈与工单）收敛到同一次发布动作，无旁路写入。

### 4. 处置：改写与置空明确否决，只落 `status` 侧

后端改写 / 置空 `/accountInfo/nickname` 由两条独立理由各自封死：它是后端写入字段表逐字点名的「反例一」；且扩表会由 §5c 恒等式**自动**引入回声约束 ⇒ 每个改过名的玩家每次改名都丢一次本地缓冲。

因此取「可登录先改名」：`status` 不变，`GET /v1/compliance/status` 带一项 `nicknameChangeRequired`；玩家正常登录后改一个合规昵称即自解除。`restricted` 不废弃，降为升级档（拒不改名 / 恶意反复）。依据：pillar #4 不阻塞玩家 · 「仅两处硬阻塞」· 昵称**零玩家间可见性** ⇒ 把玩家整个挡在门外与实际危害不成比例。

**标记由云端状态算出，不在端点判定通过的那一刻清零**——那会让「调用端点但不 push」成为绕过路径；玩家 push 合规昵称后由扫描的比对自动清零，定期兜底仍在。由此 `restricted` / `banned` 的解除只需改回 `status`，**永不带外改写昵称**，后端写入字段表不需要任何运营例外。

### 5. 存量扫描：三个触发源

**T1 push 事件驱动**（比对本次 `nickname` 与该账号最近一次经端点接受的值，不等即**确定性**检出绕过写入）· **T2 词表版本更新驱动**（增量面由不可变版本化保证，否则退化为每次全量）· **T3 定期兜底全量**（初值 30 天，只兜前两者的边角与沉睡账号）。T1 **只记账与判定，绝不拒绝上行、绝不改写**——在 push 上拒绝会同时撞三条既定纪律。扫描台账落后端内部存储、不进 profile。

### 6. 风控：轻量档，不是第四个服务

事件流 + 规则化累计计数 + 阈值触发**工单**；`status` 变更须人工确认。事件产出在 `account` / `profile-store` 内部旁路（不在同步热路径上裁决），聚合与处置流程落 `operations/`。一张统一的事件字段表同时装下回声校验与越界记账两组已具名字段，不另立两套；`expected` / `actual` 一律字符串序列化（取值域跨类型，`ulong` 类在 JSON number 上会静默丢低位）。

**全局熔断（承重）：** 同 `appVersion` / `contentVersion` 分组内 `RollMismatch` > 1% 或 `EchoRejected` > 0.5% ⇒ 判为我方实现缺陷，暂停该分组一切自动处置并告警。真实作弊渗透率不可能达到这个量级；它防的是「后端复算差一位 / 客户端一次发版 bug ⇒ 大批正常玩家被封」这类最坏事故。

### 7. 向玩家的可见粒度：两处取值表首版都不扩

`auth.session_revoked.reasonKey` 不扩（吊销后玩家动作恒为重登）；`compliance.account_restricted.reasonKey` 不扩（昵称违规不走 `restricted`，且三档处置对玩家无可执行差异；告知判据维度等于外泄判据、反向指导规避）。

## Clarifications（interview 产物）

- 未过审昵称的处置主线 P1 还是 P2 → **P2（可登录先改名）**（用户裁决）。`restricted` 保留为升级档。**「运营带外改写 profile」这条边界随之结构性消失**，无需裁定。
- 是否建独立风控系统 → **轻量档**（用户裁决）：事件流 + 累计计数 + 工单，`status` 变更须人工确认，全局熔断随之生效。
- 「P2 的登录后强制改名算不算第三处硬阻塞」→ 措辞裁定权在客户端侧，本库不代为决定。
- 自动采纳的标准默认（不占裁决）：短路顺序不可颠倒 · 拒绝不计频次 · 归一化串与原串的分工 · 适配器不可达按待复核接受 · 首版不启用第三方只留位 · 词表两档不设第三档 · 「须改名」标记由云端状态算出且不在端点通过时清零 · 事件 `kind` / `severity` 取 PascalCase 且未知取值不驱动判定。

## Open questions

- **合规能力的上线分级**（归 `02`）仍未答；**第三方审核首版是否启用**从属于它。
- `06`：第三方审核服务商 · 改名频次阈值 · 各项风控阈值的配置承载 · 风控事件流 / 复核队列 / 扫描台账的存储形态 · 可观测性口径的落点。
- **残留通道未关闭**：客户端自报的「最后一次有效机会」后端无法验真。本方案不主张关闭它，只让它被累计阈值接住——这是 pillar #1 下的必然取舍。
- 全部旋钮初值（兜底扫描 30 天 · 事件保留 180 天 · 各累计窗口与熔断率）待实测校准。

## Notes / triage

来源：`inbox/solution-draft-nickname-moderation-and-risk-control.md`（已人工评审）。与 `handoffs/2026-09-03-compliance-endpoint-payloads.md` **成对**：`nicknameChangeRequired` 的语义归本份、报文形态归那一份。

本次产生的 ADR 候选（交 `/write-adr` 处置）：① 未过审昵称的处置落 `status` 侧标记而非改写 profile（后端写入字段表封闭性的第二个执行点）；② 风控自动处置止步于工单 + 全局熔断（一次我方缺陷不得放大为全量误封）。

## 客户端侧影响

**是，跨边界，但客户端侧的新增义务只有一项**：`GET /v1/compliance/status` 多一个 `nicknameChangeRequired` 标记，客户端据此在登录后引导一次改名。呈现形态（落在哪一屏、失败如何处置、算不算第三处硬阻塞）归 `game-design-documents/systems/services/account-service.md` 与 `ux/error-and-blocking-ux.md`，已由 `game-design-documents/inbox/solution-draft-backend-batch-client-obligations.md` 承接。**对侧尚未落笔成正式文档，本次不宣称跨边界收口。**

不新增任何 `code`，不改任何已封定的 `reasonKey` 取值表，不扩后端写入字段表 ⇒ 回声约束面不变、`schemaVersion` 不 bump、无迁移。

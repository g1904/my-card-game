# 撤销云端剧本服务：剧本内容改由 content-service 的 overlay 通道承载

- id: 2026-08-11-plot-service-retired
- date: 2026-08-11
- topic: vision/scope · contracts/envelope · contracts/content-manifest · systems/_index · open-questions（`01` / `04` / `05` 作废）
- status: distilled
- distilled-to: `vision/scope.md`, `contracts/_index.md`, `contracts/envelope.md`, `contracts/content-manifest.md`, `systems/_index.md`, `decisions/_index.md`, `README.md`, `open-questions.md`, `open-questions/01-contracts.md`, `open-questions/04-content-delivery.md`, `open-questions/05-plot-service.md`（删除）, `answer-logs/log-0811.md`

## Intent（distilled）

**一句话：客户端侧已裁定剧本内容本地化——后端不再有剧本服务。跨越进程边界的客户端成分由四个降为三个（`account-service` · `sync-service` · `content-service`），剧本内容改由已有的 `content-manifest.md` 通道以普通内容文件下发。**

**来源：** `game-design-documents/handoffs/2026-08-11-plot-content-localization.md`（客户端侧已 `distilled`，其「Notes / triage」段点名本库需要这份对应 handoff）。本 handoff **不复述客户端的论证**，只落定后端侧的撤销范围与承接方式。

### 客户端侧已定的四条前提（回链，不在本库重新论证）

1. **剧本是预写式内容库**——人工 / 离线写就的静态文本，非运行时生成。这是本地化成立的前提（运行时生成需密钥、成本与内容审核留在服务端）。
2. **剧本文本落地为本地内容层的一员**，随基线包发布，热更走 content-service 的 overlay 通道。
3. **overlay 对剧本内容类型可新增 `Id`**（其余内容类型照旧「只改不增」）——因此「新剧情不发版」这项原属云端剧本服务的运营能力，由 overlay 通道承接。
4. **剧透 / datamine 可接受**，与客户端已定的「不承诺防作弊」完整性边界同调。

### 后端侧的撤销范围

| 项 | 处理 |
|---|---|
| `systems/plot.md`（计划中的服务） | **删除该计划**——服务不存在 |
| `contracts/plot.md`（计划中的契约） | **删除该计划**——无报文 |
| `/v1/plot/…` 端点域（`envelope.md` §3） | **删除该行** |
| `plot.unavailable` 错误码（`envelope.md` §6 台账） | **从台账删除**——它的产生者（事务前置的剧本请求、超时兜底）已随服务消失 |
| `open-questions/05-plot-service.md`（3 条） | **整片作废删除** |
| `01-contracts.md` 的「`plot.md` 尚未成文」 | **删除该条** |
| 「跨边界的客户端成分有四个」（`README.md` · `vision/scope.md` · `01-contracts.md`） | **改为三个**，删去 `PlotManager` 一行 |
| `vision/scope.md` In scope 的「剧本下发」 | **删除该项** |

### 后端侧的承接方式：剧本是 manifest 里的普通文件

**契约层无需任何新增。** 剧本内容以 `.tres` 内容文件的形态出现在 `manifest.files[]` 中，与卡牌 / 事件 / 敌人等条目在报文层**完全同形**——服务端不区分内容类别，三条服务端保证（URL 稳定 · 字节不可变 · 发布原子）原样覆盖它。

由此推出两条落在本库的判定：

- **「overlay 可新增剧本 `Id`」是客户端侧的合并纪律，不是契约条款。** manifest 本就是**全量文件清单**，新增文件是它天然支持的形态；「哪类内容允许新增 `Id`」由客户端合并后的强校验裁决，服务端不感知也不校验。契约文本不因这条例外而改变。
- **flags 通道对剧本条目无作用点。** `ContentEnabled` 的唯一作用点是产出侧 `AllEnabled()` 取抽取池，而剧本条目不进任何抽取池（它由 key point 定位读取，走不过滤的读取侧）。因此把剧本 `Id` 放进 `disabledIds` 不会产生任何效果——**flags 不是撤回一段已发布剧情的手段**，撤回剧情只能靠发布更大的 `contentVersion` 移除该文件（回滚即前滚）。

### 边界不变的部分

- **强制在线 · 云端权威（`game-design-documents/decisions/ADR-0003`）原样成立。** 本次改的是剧本内容的载体，不是账号 / 存档模型：仍必须登录、进度仍实时同步、冲突仍以云端为准。本库的 `account` / `profile-store` / `content-delivery` 三条线毫无影响。
- **`contracts/envelope.md` 的边界层原样成立**——删掉一个端点域与一条错误码不触动信封、版本协商或错误码分层的任何机制。
- **契约焦点顺序不变**：`auth.md` → `profile-sync.md`，只是其后**不再有第三份端点契约**。

## Clarifications（interview 产物）

本次未触发 interview——输入是客户端侧已完成 interview 并 `distilled` 的 handoff，其「另一侧需要一份对应的 handoff」段已把后端待办逐条点名。以下两项是本库校验中**由既有文档推演新增**的（客户端 handoff 未点名，但由「剧本无运行时请求」必然推出）：

1. **`envelope.md` §3 的 `/v1/plot/…` 端点域与 §6 的 `plot.unavailable` 错误码**须一并删除。留着即在契约里保留一个永无产生者的 `code`，违反「新增 `code` 一律在台账登记」所维护的台账可核对性。
2. **`vision/scope.md`** 的边界表与 In scope 同样列有剧本下发，须一并改——它是本库范围的事实来源，漏改即范围失真。

## Open questions

- **剧本内容的体积与分发形态。**（新增，落 `04-content-delivery.md`）剧本树本地化后，其全部文本进入 overlay 分发量。原云端方案的「按需请求」天然回避了这个问题。后端侧待定：是否需要按篇章分包（`contentRoot` 下多 manifest？还是单 manifest 内按路径前缀分组）、首包下载量的可接受上界、以及 CDN 成本模型。**客户端侧同题待答**（分包边界），两侧需一致——契约形态由本库定，分包边界由内容规模决定。

## Notes / triage

**ADR 候选：** 「剧本内容属本地内容层」是客户端侧的方向性决策（其 ADR 归 `game-design-documents/decisions/`）。本库不另立 ADR，只在 `decisions/_index.md` 的「已对后端构成约束的客户端决定」表登记它对后端的约束（撤销一整条边界）。

## 客户端侧影响

**本次改动不新增任何客户端 ↔ 后端语义**——它是客户端侧决策在本库的落地，客户端侧的文档更新已由 `game-design-documents/handoffs/2026-08-11-plot-content-localization.md` 完成（`status: distilled`）。**无需客户端再写一份 handoff。**

受影响的客户端成分：`future-event-service` 内的 `PlotManager` **不再跨越边界**（它现在只读本地内容层）。剩余跨边界成分三个：`account-service` · `sync-service` · `content-service`。

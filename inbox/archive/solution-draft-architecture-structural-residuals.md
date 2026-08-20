---
type: solution-draft
date: 2026-08-18
question: `systems/architecture.md` 待决问题里的三条结构残留——① 断线降级的具体行为 ② 热更「只改不增」的两个连带项 ③ ViewModel 层的文档落位
source: open-questions/05-service-contracts.md → 「`architecture.md` 的三条结构残留（08-16b 采集）」
targets: systems/architecture.md · systems/services/sync-service.md · systems/services/content-service.md · systems/balance.md · systems/viewmodel.md（提议新建）
status: distilled
reviewed: 2026-08-19 — 用户逐条裁决完毕（取向零剩余）；批量提炼时的合并 interview 另有 48 项裁决，全部取推荐项
distilled-to: handoffs/2026-08-19-architecture-structural-residuals.md
---

# 方案 — `architecture.md` 的三条结构残留

## 问题

`systems/architecture.md` 的 `## 待决问题` 里挂着三条从 07-25b 起就没动过的条目，08-16b 才被采集进 `open-questions/05-service-contracts.md`：

1. **断线降级的具体行为** —— push / pull 失败时阻塞玩家、本地缓冲重试、还是回退存档点？（原表述里的「剧本请求」一支已随「没有云端内容通道」的定案消失。）
2. **热更「只改不增」的连带项** —— 是否需要「预埋占位 `Id`」策略绕开审核周期、是否在存档中记录 `contentVersion` 以便诊断。（范围边界与确定性张力本身已定案。）
3. **ViewModel 层是否单列一份文档**（或归 `ux/`）—— 三层切分已在 `architecture.md` 显式化，文档落位未定。

**本次推演的第一个发现，先于任何方案：三条的性质完全不同。**

| # | 实际状态 | 残留的是什么 |
|---|---|---|
| ① | **主体已答定**，权威在 `services/sync-service.md`「断线降级」+「`Immediate` flush 的失败语义」+「`Upgrade` 类错误在非闸门点」，另有 `account-service.md` 的刷新失败分流、`content-service.md` 的两条降级 | **台账漂移** + 一处真实空白：**指数退避的参数形态与「放不放弃」** |
| ② | **两问皆已答定**，权威在 `services/content-service.md`「放量开关 `ContentEnabled`：不预埋占位 `Id`」（否决）与「存档记录 `contentVersion`：记两个」（采纳） | **纯台账漂移**，无任何设计空白 |
| ③ | **确实未答** | 真问题 |

即：`architecture.md` 的这三行**有两行是过期的待决登记**——答案在下游服务文档里已经写死，只是从没回头划掉上游的条目。这本身是本库「活文档只保留最新设计」纪律的一处失守，也是本草稿要交付的主要价值：**把两条收口、把一条真答了。**

---

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| C1 | **强制在线 · 云端权威**；冲突一律以云端为准，不做字段级三路合并 | `decisions/ADR-0003` |
| C2 | **绝不回退存档点。** 「云端权威」解决的是冲突，不是丢进度 | `services/sync-service.md`「断线降级」总原则 |
| C3 | **硬阻塞只有两处**：登录 / 启动 pull 的 `client.version_unsupported`、`auth.session_revoked`；迁移失败落在「启动 pull」之内，不构成第三处；**未知 `code` 永不新增第三处** | `architecture.md` 总则 7 · `ux/error-and-blocking-ux.md` |
| C4 | **push 失败恒不阻塞玩家，且从不按 `PushPolicy` 分叉**；`Immediate` 声明「不等」，不声明「必须成功」 | `services/sync-service.md`「`Immediate` flush 的失败语义」 |
| C5 | 软阻塞的**两个闸门**（事件级存档点数 ≥ 3 · 最早一条滞留 ≥ 180 s）与**唯一触发时机**（下一次 AdventureEvent 选择前）已定；`Upgrade` 变体只换文案与选项、不换机制 | 同上 + 「`Upgrade` 类错误在非闸门点」 |
| C6 | 退避间隔取 `max(本地退避计算值, Retry-After / detail.retryAfterSeconds)`，本地 jitter 照常叠加；**限流绝不映 `Conflict`** | `services/sync-service.md` |
| C7 | **两种「永不恢复」态必须暂停退避**：`class: Upgrade` 与 `auth.session_revoked`；解除条件唯一 = 重新登录成功 | 同上 + `services/account-service.md` |
| C8 | **overlay 只改不增**（剧本内容是唯一例外，两条边界 + `newIds` 双闸）；**不预埋占位 `Id`** | `services/content-service.md` |
| C9 | **不冻结轮回的 `contentVersion`**，overlay 热更在轮回进行中即生效；确定性降级为「同一 `contentVersion` 内」的性质 | 同上 + `.claude/rules/state-save-rules.md` |
| C10 | **ViewModel 层是架构中的一个显式层**：位于 services / 核心「类」与屏幕场景之间，单向依赖，不落存档、不进云端负载；**服务不返回 ViewModel** | `architecture.md`「展示层契约：数据 / 运行时 / ViewModel 三层」 |
| C11 | **定义在最小公共祖先、投影在各落点**；投影只写落点 / 本层合法子集 / 本层消费点 / 回链，**不得复述定义** | `systems/common-properties.md` 判据卡（08-14 答定，`answer-logs/log-common-properties-layering.md`） |
| C12 | **按「它服务于谁」定位，而不是按「谁先用到它」** | `ux/error-and-blocking-ux.md`（`ErrorText` 归位与 `FR-ux-translation-foundation` 不挂任何单屏的理由） |
| C13 | **纪律的可执行化四级阶梯 + 两条选级判据**；同步 / 内容管线旋钮属「不硬编码、可线上调」的可调数值 | `architecture.md` · `systems/balance.md`「同步 / 内容管线旋钮」 |
| C14 | **回链而非复述。** 抄一份 = 制造第二权威，两份各自漂移而本库无机制发现 | `.claude/rules/design-library-routing.md` · `content/` 硬边界 |

---

## 建议方案

# ① 断线降级：一张逐场景行为表 + 一处真实空白（退避形态）

## 1a. 全景行为表 —— 它是**核对表，不是新决策**

`[既有推演]` 下表把散在四份文档里的降级行为拼成一张全景，**每一行都注明它已经写在哪里**。目的只有一个：**证明「断线降级的具体行为」这条待决问题已无空白**（除 1b 一处）。

**它不建议落库。**（理由见 `## 与既有决策的张力` 第 1 条：落库即复述，违反 C14。落库的只应是 `sync-service.md` 断线降级节末尾的一行索引。）

| # | 场景 | 处置 | 阻塞级 | 权威出处 |
|---|---|---|---|---|
| 1 | **启动期 content manifest 比对 / 增量下载失败**（网络） | 跳过更新，用现有 overlay + `res://` 基线开局 | 不阻塞 | `content-service.md`「断网降级」「增量下载：文件级事务」④ |
| 2 | **manifest 验签失败 / `keyId` 未知** | 拒绝该 overlay + 回退基线 + `PushError` + **上报一次** | 不阻塞 | `content-service.md`「防篡改」 |
| 3 | **manifest `manifestSchema` 高于客户端支持集合** | 跳过本次更新（**不是重下**），照常用现有层 | 不阻塞 | `content-service.md`「增量下载」 |
| 4 | **manifest `minAppVersion` 高于本机**（内容维度） | 跳过本次 overlay、用基线 | **永不阻塞** | 同上「manifest 契约对位」 |
| 5 | **登录失败（网络）** | `OpError.Network`，登录屏内重试 | 不进入游戏，但非阻塞屏 | `account-service.md` |
| 6 | **登录被拒 `client.version_unsupported`** | `BlockingNoticeScreen`「需更新」变体 | **硬阻塞（既定两处之一）** | `ux/error-and-blocking-ux.md` |
| 7 | **flags 首次拉取失败** | `PushWarning` + 降级到 `user://cache/flags.json`（无缓存 → overlay 的 `ContentEnabled`）；下次搭车信封自然重试 | **绝不阻塞** | `content-service.md`「flags」 |
| 8 | **启动全量 pull 失败（网络）** | 呈现「重试 / 退出」，**不提供本地缓存开局** | **硬阻塞（既定两处之一）** | `sync-service.md`「断线降级」表 |
| 9 | **启动 pull 后迁移失败：云端 schema 高于客户端上界** | 阻塞屏「需更新」变体 | 硬阻塞（**落在第 8 行之内**，非第三处） | `sync-service.md`「迁移失败的清晰拒绝」 |
| 10 | **启动 pull 后迁移失败：范围内但抛错** | 阻塞屏「存档读取失败」变体 + **必上报一次** | 同上 | 同上 |
| 11 | **轮回内 push 失败（`Debounced`）** | 进 `user://cache/pending/`（原子写、跨启动保留）+ 指数退避；常驻「离线 · 待同步 N」 | **不阻塞** | `sync-service.md`「断线降级」表 |
| 12 | **轮回内 push 失败（`Immediate`）** | **与第 11 行逐字相同**；`policy` 不改变失败处置 | **不阻塞** | C4 |
| 13 | **进入战斗前 flush 失败** | 变更进待发队列 → **照常进入战斗**；**不产生任何额外提示** | **不阻塞** | `sync-service.md`「`Immediate` flush 的失败语义」 |
| 14 | **战斗中的决策点存档** | 纯本地原子写；**不驱动 push、不计闸门、不影响断线判定** | 不阻塞 | 同上，推论 ② |
| 15 | **事件收口（结算后存档点）push 失败** | 同第 11 行；闸门 +1，达阈值则模态在**下一次事件选择前**弹 | 不阻塞 → 可能触发软阻塞 | C5 |
| 16 | **缓冲超限（≥ 3 事件级存档点 或 ≥ 180 s）** | 下一次 AdventureEvent 选择前弹模态「网络异常，正在重连」，选项「重试 / 退出到主界面」；队列**保留本地** | **软阻塞** | 同上 |
| 17 | **应用失焦 / 挂起时的 `Immediate` flush 失败** | 进队列；**无处弹模态、也不该弹** | 不阻塞 | `sync-service.md` |
| 18 | **`rate.limited`** | 映 `OpError.Network`，走第 11 行；退避取 `max(本地值, Retry-After)` + jitter；**绝不映 `Conflict`** | 不阻塞 | C6 |
| 19 | **token 刷新失败（网络）** | **视同断线**，走同一条缓冲通道，不另开路径 | 不阻塞 | `account-service.md` |
| 20 | **收到 `auth.session_revoked`** | 阻塞屏「被挤下线」变体；**暂停退避**；重登后先 pull 后 flush | **硬阻塞（既定两处之一）** | 同上 |
| 21 | **`class: Upgrade`（如轮回中途 push 返回 `sync.payload_schema_unsupported`）** | 缓冲**保留不丢** · 非模态「需更新版本才能同步」 · **暂停退避** · `UpgradeRequired = true`，常驻指示改写为 `需更新 · 待同步 N` · 软阻塞模态取第二变体（无「重试」） | 非阻塞 → 既定软阻塞 | `sync-service.md`「`Upgrade` 类错误在非闸门点」 |
| 22 | **恢复后 `FlushPendingAsync`：云端 `revision` 已领先** | 以云端为准丢弃本地缓冲 + `OpError.Conflict` + **明确告知玩家**；不静默合并 | 不阻塞 | `sync-service.md`「恢复后的合并语义」 |
| 23 | **CAS 不可能态（`baseRevision > cloudRevision`）** | 同 Conflict 处置 + `PushError` **上报一次**；不自愈 | 不阻塞 | 同上 CAS 三分支表 |
| 24 | **购后 pull 失败** | **阻塞在主菜单重试直到成功**；走收据幂等读，`receiptId` 跨启动持久化 | 阻塞（**主菜单内**，无进行中轮回） | `sync-service.md`「后端主动写入的唯一情形」 |
| 25 | **剧本读取失败** | **不存在这一行**——剧本属本地内容层，纯内存查找无网络失败态；唯一缺失情形是悬空 key point → `PushWarning` + 叙事降级 | — | `sync-service.md` 表下注 · `content-service.md` |

**三条可直接读出的不变式**（本表的真正产物，建议这三句落库，而非整张表）：

1. **除了既定的两处硬阻塞与「购后 pull」这一处主菜单内阻塞，任何网络失败都不阻塞玩家。** 25 行里的阻塞行恰好是第 6 / 8（含 9、10 于其内）/ 20 / 24，无第五处。
2. **「回退存档点」在全表零次出现。** 云端权威只在**冲突**（22、23）与**迁移失败**（9、10）处生效，两者都不是「把玩家已打完的进度倒回去」。
3. **降级永远只有三种形状**：进队列 + 退避（push 侧）· 用上一个已知好值（内容 / flags 侧）· 硬阻塞并给出唯一动作（身份 / 权威档侧）。**新的失败态必须归入这三种之一，不得发明第四种。**

## 1b. 真实空白：指数退避的参数形态与「放不放弃」

`[既有推演]` 现状是：全库出现 5 次「指数退避」，但**只有 overlay 下载那一条给了参数**（`3 次 / 1s · 2s · 4s`，`balance.md`）。push 侧的退避**从未给过底数、上限、jitter 幅度或放弃条件**——而它是唯一一条会**跨启动持续存在**的重试通道。

### 建议 1：退避阶梯落 `balance.md` 既有的「同步 / 内容管线旋钮」表，追加四行

`[既有推演]` 落点无需新造：该表已经装着 push 防抖窗口 5 s、两个闸门 3 / 180 s，本条与它们**同族**（不硬编码、可线上调、不是玩法平衡值）。

| 旋钮 | 建议初值 | 依据 |
|---|---|---|
| push 退避底数 / 因子 | **2 s 起，×2** | `[通行做法]` 移动端同步客户端的常规值；与 overlay 侧 `1s · 2s · 4s` 同族但起点更宽——push 的单次失败**没有用户在等**（不阻塞），而 overlay 下载卡在启动链上 |
| push 退避上限（cap） | **60 s** | `[既有推演]` 滞留闸门是 180 s；cap 必须 **< 闸门**，否则「玩家已断线 180 s」这个判定可能在一次退避睡眠中途才被发现。60 s 给出至少两次窗口内重试 |
| jitter 幅度 | **±20%（乘性）** | `[通行做法]` C6 已定「本地抖动照常叠加」但未给幅度；±20% 是错峰的常规下限 |
| 放弃阈值 | **无——永不放弃** | 见建议 2 |

### 建议 2：**push 侧退避没有放弃阈值**，只有两种「暂停」

`[既有推演]` 这不是取向，是三条既有定案的合取：

- C2「绝不回退存档点」+ 待发队列**原子写、跨启动保留** ⇒ 放弃一条待发变更 = 丢玩家进度，**无论重试了多少次**。
- C5 软阻塞闸门已经承担了「告知玩家 + 拦住他继续累积」的全部职责，且**触发点是次数 / 时长，不是重试耗尽** ⇒ 放弃阈值没有任何职责可承担。
- 真正「重试必然失败」的两种态（C7：`Upgrade` / `session_revoked`）已各自定了**暂停**（不是放弃）+ 唯一解除条件。

⇒ **形态定为：退避无限进行、以 cap 封顶；只在 C7 两态暂停；队列条目永不因重试次数被丢弃。** 队列的唯一淘汰路径是既定的三条——被后端接受、被 `Conflict` 按云端权威丢弃、切账号清空。

### 建议 3：退避计时在应用挂起期间**不补偿、不追赶**

`[既有推演]` 应用被挂起时无法执行重试；恢复前台时**按恢复那一刻重新起算下一次退避（不重置阶梯层级）**，且**不为挂起时长补发多次重试**。理由：滞留计时器已经如实记录了「玩家离线了多久」（`sync-service.md` 明写「滞留计时不因战斗进行而暂停，这是正确行为」），补发重试只会在恢复瞬间打出一串必然同时失败或同时成功的请求。

### 建议 4：`architecture.md` 的该条待决问题收口为一行回链

`[既有推演]` 依「活文档只保留最新设计」，条目改写为：

> **断线降级** → 已答定，逐场景处置的权威在 `services/sync-service.md`「断线降级」/「`Immediate` flush 的失败语义」/「`Upgrade` 类错误在非闸门点」、`services/account-service.md`（刷新失败分流）、`services/content-service.md`（内容与 flags 侧降级）。退避参数见 `balance.md`「同步 / 内容管线旋钮」。

——**不在 `architecture.md` 复述任何处置**（C14）。

---

# ② 热更「只改不增」的两个连带项：两问皆已答定，本条应整条移除

## 2a. 预埋占位 `Id` —— **否决，已是定案**

`[既有推演]` `content-service.md`「放量开关 `ContentEnabled`：不预埋占位 `Id`」已逐字否决，两条理由原样成立：

1. 与「合并后强校验」直接冲突——空壳条目要么迫使校验放宽（丢掉启动期早失败），要么携带假数值被抽中；
2. 属应用商店审核灰区（随包发的是不可玩的壳）。

**且它要解决的问题已被更好的手段解决**：`ContentEnabled` 三层覆盖（`.tres` 默认 → overlay → **flags 按账号解析**）给出了灰度 / 分批放量 / **线上秒关**三项运营能力，秒关延迟 = 该玩家的下一次上行（分钟级）。占位 `Id` 换来的「绕开审核周期上新内容」在此之上只多出一件事——**发布未经审核的新玩法内容**，而那正是审核灰区本身。

**如实记下它没解决的那一半**（`content-service.md` 已写明的能力边界）：本机制压缩的是**已随包发布内容的放量时机**，**不压缩内容本身的发版节奏**。新卡 / 新事件仍受审核周期约束。**建议接受这个代价，不再重开占位 `Id`。**

## 2b. 存档记录 `contentVersion` —— **采纳，且已是定案：记两个**

`[既有推演]` `content-service.md`「存档记录 `contentVersion`：记两个」已定：

| 字段 | 语义 |
|---|---|
| `CharacterProfile.StartContentVersion` | 轮回开始时生效的版本，**写一次不再变** |
| `CharacterProfile.LastContentVersion` | **每个自动存档点**更新为当时生效的版本 |

二者不等 = 该轮回跨过内容更新，是排查「数值突变」类反馈的**第一判据**。**因 C9 不冻结 `contentVersion`，一个版本号无法表达「跨过」，故必须记两个。** 类型已随 08-17h 由 `string` 改 `int`（`sync-service.md`「存档 schema 版本」），push 负载信封另带 `contentVersion` / `appVersion` / `revision` 供后端不解 Profile 即可做版本维度聚合。

**明确否决的第三种做法（本次新增的记录，防止日后再被提起）：** 在 `PastEventEntry` 上逐事件记 `contentVersion`。它把一个**每轮回至多变化数次**的量抄进一个**每事件一条、约 770 B 预算**的追加型结构里，体积换不回信息——`Start` / `Last` 两个端点加上 push 信封的逐次记录，已足以定位「哪几个存档点之间跨了版本」。这与「重算得出来的不存」是同一条快照判据。

## 2c. 收口动作

`[既有推演]` **`architecture.md` 的该条待决问题整条删除**，理由：两个子问都在 `content-service.md` 里有权威答案，上游留一条「待决」是纯粹的过期登记，会让读者以为还有空白。若需保留线索，`architecture.md`「内容与档案的存储分界」小节已有指向 `services/content-service.md` 的回链，**不必再加**。

---

# ③ ViewModel 层的文档落位：建议**单列 `systems/viewmodel.md`**

## 3a. 判据先行（不谈偏好）

`[既有推演]` 三条既有判据，逐条套用：

**判据 A —— 「定义在最小公共祖先、投影在各落点」（C11）。** 关键是先数清楚：**ViewModel 层的横切纪律现在散在几处？**

| # | 纪律 | 当前落点 |
|---|---|---|
| 1 | ViewModel 单向依赖（读 Data + 运行时状态），不被服务反向依赖，不参与存档 / 同步；**服务不返回 ViewModel** | `systems/architecture.md`「展示层契约」 |
| 2 | 只存在于呈现期，**不落存档、不进云端负载** | 同上 + `systems/common-properties.md` |
| 3 | 对 `EventOption` 定稿实例**只读消费**，不得回查模板重算、不得改写字段 | `systems/adventure-event/common-properties.md` · `future-event-service.md` |
| 4 | `IsRevealed == false` 时**不读** `RevealedEventId` / `DestinationLocationId` | `systems/adventure-event/explore/_index.md` |
| 5 | 内容正文由 ViewModel 向 ContentRegistry 按 `Id` 取，**不经 UI 代码传递** | `ux/error-and-blocking-ux.md`（CJK 审计判据的前提） |
| 6 | `LocalizedText.Get()` 的缓存**只能缓存在 ViewModel 上**，绝不写回 `XxxData` | `systems/common-properties.md` · `content-service.md` |
| 7 | **订阅翻译变更通知，收到即重新组装一次**（`LocalizedText` 不经 `TranslationServer`，已组装的 ViewModel 不会自己变） | 仅存在于 `handoffs/2026-08-13-*`——**至今没有任何主题文档承载它** |
| 8 | `OpResult.Detail` **永不**赋给任何 `Label.Text`；诊断展示（`BaseRevision` / `requestId`）只读一次、不进玩法路径 | `ux/error-and-blocking-ux.md` · `sync-service.md` |
| 9 | 需要整场信息时读 combat-service 组装的 `CombatSnapshot`（只读视图，不落存档） | `systems/architecture.md` · `combat-service.md` |

**九条纪律、七份文档、且第 7 条已经掉出了主题文档层只剩在 handoff 里。** 按 C11，这九条的**最小公共祖先就是「ViewModel 层」本身**，而这个落点当前不存在——于是它们全部上浮或旁落到了各自最近的邻居文档。**判据 A 直接给出「单列」。**

**判据 B —— 「按它服务于谁定位，而不是按谁先用到它」（C12）。** ViewModel 层服务于**全部屏 × 全部服务**，不属任何单屏，与 `FR-ux-translation-foundation`「横切所有屏，不挂在任何一个屏下」同形 ⇒ 不该塞进 `ux/` 的任一屏文档，也不该继续寄居在 `architecture.md` 的一节里（那一节已被八条 API 契约总则挤满，第 7 条这类落地纪律进不去也留不住）。

**判据 C —— 「这句话的权威在哪一侧」，决定 `systems/` 还是 `ux/`。**
- `ux/` 的职责已被自己写死：**「怎么说、说在哪、说几次」**（`error-and-blocking-ux.md` 开篇）；`ux/_index.md` 的四问判据管的是「谁是内容、谁是界面」。
- 上表九条里，**没有一条在回答「怎么说」**——它们回答的是依赖方向、生命周期、只读性、缓存归属、重组装时机，全是**结构与边界**。
- ⇒ 归 **`systems/`**，不归 `ux/`。

## 3b. 先例：非服务的横切件已经有过一次同样的裁决

`[既有推演]` `system-overview.md`「非服务的横切件」表恰好列三件：**game-progression · EventBus · ViewModel**。前两件的文档落位早已各自定下：

| 横切件 | 落位 | 为什么 |
|---|---|---|
| **game-progression** | **`systems/game-progression.md` 单列**（与 `architecture.md` 平级的顶层单文件） | 它有自己的机制面（核心循环、location 抽象、配额闸门），装不进 `architecture.md` 一节 |
| **EventBus** | **`architecture.md` 总则 5 一节** | 它的全部内容就是一条 API 契约总则（负载形态 + 三条负载纪律 + 退订审计），**天然属于总则表** |
| **ViewModel** | ← 本条待答 | — |

**判据是「它的内容是不是一条 API 契约总则」。** ViewModel 的九条纪律里只有第 1、2 条像总则，其余七条是**跨屏的落地纪律**（何时重组装、哪些字段遮罩期不读、缓存放哪、哪些串永不渲染）——形态上更接近 game-progression 那一侧。⇒ **按先例取「单列顶层单文件」**：`systems/viewmodel.md`。

## 3c. 建议的文件形态（可直接落笔的骨架）

`[既有推演]` 遵 C11「定义在最小公共祖先、投影在各落点，投影不复述定义」：

```
systems/viewmodel.md
├── ## 意图
│   ├── 三层切分中的第三层：它是什么、不是什么   ← 从 architecture.md 迁入本体
│   ├── 依赖方向（单向；服务不返回 ViewModel；不进存档 / 云端负载）
│   ├── 组装源三件套：XxxData（静态文案）+ 运行态实例 + 服务快照（CombatSnapshot / Snapshot）
│   ├── 重组装的触发面（翻译变更通知 · CapabilitiesChanged 空负载后自查 · EventBus 既成事实广播）
│   ├── 只读消费纪律（定稿实例不回查模板、遮罩期不读的字段族）
│   ├── 缓存归属（LocalizedText.Get() 的缓存只落这一层）
│   └── 永不渲染清单（OpResult.Detail · 诊断编号只读一次不进玩法路径）
├── ## 决策(-> ADR)
│   └── 展示层三层切分 → 现有 ADR 候选（待固化）；固化时本文件是它的落点
└── ## 待决问题
```

配套的三处**投影**（各自只留一句 + 回链，不复述）：
- `systems/architecture.md`「展示层契约」小节 → **保留三层切分的定义**（它是三层的最小公共祖先，第一、二层的权威也在这里），第三层展开处改为一句「ViewModel 层的完整契约见 `systems/viewmodel.md`」。
- `ux/_index.md` → 表中加一行指路，说明「ViewModel 是结构契约，归 `systems/`；`ux/` 只管各屏显示什么」。
- `system-overview.md`「非服务的横切件」表的 ViewModel 行 → 回链本文件。

## 3d. 时机：建议**现在建**，不等第一份 UI FR

`[既有推演]` 两条理由：
1. **纪律 7 已经掉出主题文档层**（只在 handoff 里），再拖它会在第一次写屏时被漏掉——而它的症状是「切语言后卡面文字不变」，属**能上线且线上不可见**那一档（C13 的选级判据），代价不对称。
2. `error-and-blocking-ux.md` 已把 `FR-ux-translation-foundation` 定为「一切含 UI 文案的 FR 的 `depends-on`」，而该 FR 的第 5 件事（两条审计）与 ViewModel 的重组装纪律直接咬合 ⇒ **derive 之前就需要这个落点存在**。

---

## 具体形态（可 derive 的落地面）

### A. `balance.md`「同步 / 内容管线旋钮」表追加四行

| 旋钮 | 初值 | 归属 |
|------|------|------|
| push 退避底数 / 因子 | **2 s · ×2** | `systems/services/sync-service.md` |
| push 退避上限（cap） | **60 s**（硬约束：必须 < 滞留闸门 180 s） | 同上 |
| push 退避 jitter | **±20%（乘性）** | 同上 |
| push 退避放弃阈值 | **无**（永不放弃；只在 `Upgrade` / `session_revoked` 两态暂停） | 同上 |

### B. `sync-service.md`「断线降级」小节的三处增补

1. 在既有两行降级表下加一段**退避形态**：底数 / cap / jitter 取 `balance.md`；`实际间隔 = max(本地计算值, Retry-After) × jitter`；**无放弃阈值**（三条依据照 1b 建议 2 写）；挂起恢复后不补偿、不追赶、不重置阶梯层级。
2. 加一行**索引**（不复述）：「内容 / flags 侧的降级见 `content-service.md`；身份侧的刷新失败分流见 `account-service.md`。」
3. 加上 1a 末尾的**三条不变式**（阻塞点穷举 = 4 处 · 「回退存档点」零次出现 · 降级只有三种形状，新失败态必须归入其一）。第三条是可被后续设计直接引用的判据，值得成文。

### C. `architecture.md`「待决问题」的三条编辑

| 原条目 | 动作 |
|---|---|
| 断线降级的具体行为 | **改写为一行回链**（1b 建议 4 的措辞） |
| 热更「只改不增」的连带项 | **整条删除**（2c） |
| ViewModel 层是否单列文档 | **删除待决登记**，同时把「展示层契约」小节第 3 点收束为一句 + 指向 `systems/viewmodel.md` |

### D. 新建 `systems/viewmodel.md`

骨架见 3c；同时在 `systems/_index.md` 登记一行，并在 `architecture.md`「决策(-> ADR)」的「展示层三层切分 → ADR 候选」那一行注明**固化时的落点是本文件**。

### E. 待答清单侧（归 `/analyze-new-ideas`，本草稿不写）

`open-questions/05-service-contracts.md` 的「`architecture.md` 的三条结构残留」整条移出；答案落 `answer-logs/`。**若仅采纳 ①③、②留待再议，该条不得整条移出**——按既有纪律只移已答定的部分。

---

## 后果

- **文档：** 新增 `systems/viewmodel.md`（+ `systems/_index.md` 一行）；改 `systems/architecture.md`（待决问题 3 条 + 展示层契约 1 小节 + ADR 候选 1 行）、`systems/services/sync-service.md`（断线降级节 3 处增补）、`systems/balance.md`（旋钮表 4 行）、`ux/_index.md`（1 行指路）、`system-overview.md`（1 行回链）。
- **存档 schema：** **零影响。** 三条的任一建议都不新增 / 不改动任何持久化字段（`StartContentVersion` / `LastContentVersion` 已在册且已随 08-17h 那次 bump 落地）。
- **协议契约：** **零影响。** 退避参数是纯客户端行为；`Retry-After` / `detail.retryAfterSeconds` 的消费语义 C6 已定，本方案只补本地侧的计算形态。**不需要后端做任何事，也不产生对侧库的承接项**（故本次不写对侧草稿）。
- **derive 就绪度：** `open-questions.md` 现把 `systems/architecture.md` 判为 **partial**，卡点列了四项，本方案清掉其中三项（断线降级 · 热更连带项 · ViewModel 落位），剩 `CostKey` 资源族 element 清单（承重）一项。**就绪度重估归 `/assess-derive-readiness`，本草稿不判。**
- **迁移：** 无。

---

## 备选方案（已考虑并否决）

- **把 1a 那张 25 行全景表落进 `sync-service.md`** —— 否决：其中 14 行的权威在别的文档，抄进来即制造第二权威（C14），且这张表**恰恰是最容易漂移的形态**（任一服务改一条降级行为，这张表不会跟着改，而本库无机制发现）。只落三条不变式 + 一行索引。
- **另建 `systems/offline-degradation.md` 汇总断线降级** —— 否决：同上，且它会与「服务文档持有自己的失败语义」这条既有布局对撞；断线降级不是一个横切件，而是**三个边界服务各自的失败面**。
- **为 push 退避设「重试 N 次后丢弃并提示玩家」** —— 否决：直接违反 C2，且软阻塞闸门已覆盖告知职责（1b 建议 2）。
- **重开「预埋占位 `Id`」** —— 否决，理由见 2a（与合并后强校验冲突 + 审核灰区），且 flags 通道已提供它想要的运营能力的合法部分。
- **逐事件在 `PastEventEntry` 记 `contentVersion`** —— 否决，见 2c（体积换不回信息，撞快照判据）。
- **ViewModel 归 `ux/viewmodel.md`** —— 否决：九条纪律无一在回答「怎么说」，而 `ux/` 已自我限定为「怎么说、说在哪、说几次」（判据 C）。
- **ViewModel 继续留在 `architecture.md` 一节** —— 否决：该节已被八条 API 契约总则占满，落地纪律进不去；且现状已证明它留不住（纪律 7 已掉出主题文档层）。
- **等第一份 UI FR 落地时再建** —— 否决：见 3d，两条理由都指向「晚建只多一次迁移 + 一次漏写」，与 `error-and-blocking-ux.md` 否决「先用 C# 常量表再迁」同一条论证。

---

## 与既有决策的张力

1. **「回链而非复述」vs 本草稿 1a 的全景表。** 张力是真实的：这张表在**评审期**极有价值（它是「已无空白」这个结论的证据），落库后却会立刻成为漂移源。**处置：表只活在本草稿里，落库的是三条不变式 + 一行索引。** 若评审者认为全景表本身值得长期持有，那它的正确形态是**一份 handoff**（历史快照，天然不承诺跟随更新），不是主题文档的一节——这一点请在裁决时明确。
2. **`architecture.md` 的「结构与边界的权威」身份 vs 把三层切分的第三层迁出去。** 迁出后 `architecture.md` 只留三层切分的**定义与分层理由**（第一、二层的权威仍在它那里），第三层的展开在 `systems/viewmodel.md`。这**符合** C11（定义在最小公共祖先、投影在落点），但会让「展示层三层切分」这条 ADR 候选**跨两份文档**。建议固化 ADR 时以 `systems/viewmodel.md` 为主落点、`architecture.md` 保留定义段——**此处已定案：主落点 `systems/viewmodel.md`**，见「用户裁决」D3。
3. **新增一份顶层文档 vs 「层数不是成熟度指标」的克制取向。** `architecture.md` 明写「不封顶也不封底」「不为了让层级看起来更完整而拆」。本建议的抗辩是：这里拆的**不是代码层级而是文档落点**，且触发条件是可数的客观事实（九条纪律、七份文档、一条已掉出主题文档层），不是对称性诉求。仍如实记下这条张力。
4. **无张力可报的一项：** ②的两条结论与 `content-service.md` 完全一致，本草稿只是把上游过期登记收口，不改动任何已定案内容。

---

## 前置依赖

- **无硬性前置。** 三条的建议各自独立成立，可分别采纳。
- **软依赖（不阻塞定稿，但会影响落笔顺序）：**
  - `systems/viewmodel.md` 的「重组装触发面」一节需要与 `ux/error-and-blocking-ux.md` 的待答项「Godot 4.7 上 `Control` 自动翻译（`auto_translate_mode`）的默认行为」对齐——但**该待答项已明写「两种情况下键的形态、分区表、两条审计完全相同」**，故只影响写法示例，不影响纪律本身。
  - 退避参数的**具体数值**待实测校准（与 `balance.md` 该表其余各行同一性质，表头已写明「初值已给，待实测校准」）。**形态（无放弃阈值 / cap < 闸门 / jitter 叠加）不待实测**，它是推演结论。

---

## 用户裁决（2026-08-19 · 全部定案）

**五项取向全部按本方案的推荐定案（各取 A）**：D2 / D3 沿用 2026-08-18 批量评审的裁决，D1 / D4 / D5 于本次一并采纳。本方案自此为**定案方案**，`## 建议方案` 与 `## 具体形态` 各节即最终形态，可直接喂给 `/analyze-new-ideas` 提炼。

| # | 取向 | 定案 | 承重理由（保留） |
|---|---|---|---|
| D1 | push 退避的三个初值与「无放弃阈值」 | **取 A —— `2 s · ×2 · cap 60 s · jitter ±20% · 无放弃阈值`**，四行进 `balance.md` 旋钮表 | 每一项都由既有定案推出：**cap < 滞留闸门 180 s 是硬约束**（留出至少两次窗口内重试）；**无放弃阈值是 C2 + C5 + C7 的合取**（设放弃阈值即违反 C2「绝不回退存档点」，且需新定义「丢弃时怎么告诉玩家」，而软阻塞模态并非为此设计）。数值本身属「初值待实测」，与该表其余行同档 |
| D2 | ViewModel 层是否现在单列 `systems/viewmodel.md` | **取 A —— 现在单列**，九条纪律归位，`architecture.md` / `ux/_index.md` / `system-overview.md` 各留一句回链。**现在建，不等第一份 UI FR**<br>*（2026-08-18 已裁，照录）* | 三条判据（最小公共祖先 / 服务于谁 / 权威在哪一侧）与一条先例（game-progression 单列、EventBus 归总则）**四路同向指向 A**，无一支持 B 或 C。症状属「能上线且线上不可见」那一档——纪律 7（翻译变更后重组装）已掉出主题文档层、只存在于 handoff，第一次写屏时大概率漏掉，表现为「切语言后卡面不变」 |
| D3 | 「展示层三层切分」ADR 固化时的主落点 | **取 A —— 主落点 `systems/viewmodel.md`**，`architecture.md` 保留三层定义段<br>*（2026-08-18 已裁，照录）* | 由 D2 取 A 蕴含 |
| D4 | 1a 全景降级表的去向 | **取 A —— 只落三条不变式 + 一行索引**，25 行全景表随本方案归档，不进主题文档 | C（落进 `sync-service.md`）明确违反 C14 且是本库已踩过的坑；B（另写成 handoff）无害但也无用——本方案本身已在 `inbox/` 留档，再复制一份到 `handoffs/` 只是多一处待漂移的副本 |
| D5 | ② 的收口力度 | **取 A —— `architecture.md` 待决问题里的「热更只改不增的连带项」整条删除** | 「活文档只保留最新设计，不留考古」。①因为答案散在四份文档、需要一行索引才能导航，故取回链；②的答案集中在 `content-service.md` 一份文档且已有回链路径，多写一行只是噪音 |

**②的两个连带项本身照录为已答定（本方案 §2 的结论不变）：** 预埋占位 `Id` → **否决**；存档记录 `contentVersion` → **采纳，且记两个**。

> **越界发现（已采纳为新待答项，交由 `/analyze-new-ideas` 落笔，本方案不写 `open-questions`）：** `architecture.md` 待决问题小节的**模式性过期登记**（本次三条里两条已在下游答定），连同 `solution-draft-costkey-statkey-registry.md` 发现的 `ResourceElements` 表两份投影漂移（`architecture.md` 7 行 vs `profile-service.md` 11 行），一并立为「做一次 `architecture.md ↔ services/*` 待决问题与投影表对账」。

---
type: solution-draft
date: 2026-08-28
question: 两条跨边界空档的客户端半 —— ① flags 是否落客户端本地缓存（缓存策略 / 失效语义 / 断网降级）；② 二进制资产能否经 overlay 下发（合并期处置与随包基线约束）。
source: open-questions.md → 「跨边界闭合（强制检查项）」前两条 · open-questions/deferred-content.md → 「美术与音频」的「二进制资产是否可经 overlay / blob 通道下发」 · art/visuals/_index.md → 「待决问题」
targets: systems/services/content-service.md（`flags.json` 的四格落盘纪律 + overlay 非 `.tres` 文件的处置）· systems/common-properties.md（`Artwork` 的 overlay 一格由「尚未答定」改为收口）· art/visuals/_index.md（移出一条待决问题 + 一条条件化记录）· open-questions/deferred-content.md（移出「二进制资产是否可经 overlay / blob 通道下发」）· decisions/（ADR 候选一条）
counterpart: backend-design-documents/inbox/solution-draft-client-flag-cache-and-binary-overlay.md
status: distilled
reviewed: 2026-08-28 批量评审取选项 A（二进制资产不经 overlay / blob 下发，换图 / 加图随版本发布）；2026-08-30 提炼时零问题进 interview，四条机械性对账按既有权威与路由规则处置
distilled-to: handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md
---

# 方案草稿 — flags 本地缓存的落盘纪律 · 二进制资产不经 overlay（客户端半）

> **本草稿只写归客户端的那一半。** 报文形态、服务端保证、blob 通道的能力边界与签名覆盖面归对侧，见 front matter 的 `counterpart`。**下文凡涉及对侧语义处一律写路径回链，不复述。**

## 问题

`open-questions.md` 的「跨边界闭合（强制检查项）」列出两条**两侧都没有承接项**的空档——它们的危险不在于难，而在于**可能被两侧同时当成对方的责任**而无限期悬着：

1. **「flags 是否落客户端本地缓存」** —— 对侧 `backend-design-documents/contracts/content-manifest.md` 的 Open questions 明标「归客户端侧裁决，本库不代为决定」，而本库的 `open-questions/cross-boundary.md`「待承接」里没有它。
2. **「二进制资产能否经 overlay / blob 通道下发」** —— 两库均登记为待答，谁也没往前推一步。它影响 `ADR-0120`（2026-08-28）刚落的共有字段 `Artwork : Texture2D`（挂 `CardData` / `EnemyData` / `PowerData` / `ItemData` / `CharacterData` / `LocationData` / `AdventureEventData` 七类），**但不阻塞字段 derive**——本库已写到「overlay 覆盖 `.tres` 时该字段随之被覆盖，且指向必须落在随包基线内已存在的资产」为止，形态自足。

**读完两库后的第一个结论：这两条的性质完全不同，不能用同一种力度处理。**

- **第 1 条是台账错位，不是设计空档。** `systems/services/content-service.md` 的「flags：`ContentEnabled` 的第三层」**早已定案**了 `user://cache/flags.json`（字段、原子写、跨启动保留、切账号即失效、冷启动内存版本归零、拉取失败时的降级值口径），来源是 `handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md`。缺的只是**三处落盘细节**与**一次对账**——把对侧那条「归对侧裁决」关掉。
- **第 2 条是真空档**，且它撞上一条当天刚 Accepted 的 ADR 的承重形态。本草稿主张给它一个**明确的否定答案**，理由不是「不重要」，而是它会连锁推翻三条已定判据。

---

## 约束（来自既有设计）

**A. `flags.json` 已定的部分（`systems/services/content-service.md`「flags：`ContentEnabled` 的第三层」）：** 字段 `accountId` / `flagsVersion` / `disabledIds`；原子写走共享静态工具 `AtomicJsonFile`；跨启动保留；与 `sync-envelope.json` 同处同纪律；`accountId` 不匹配 → 丢弃（`PushError` + 定位上下文）；**内存 `FlagsVersion` 冷启动一律归零，缓存只提供 `disabledIds` 的降级值、不回填版本**。

**B. 缓存的收益口径已被本库明确收窄——不是「离线开局」。** 同节明写：「缓存的收益不在离线开局——那条路径根本不存在：启动 pull 是硬阻塞，强制在线下无权威档即不可玩。真实收益只有一处：**登录成功但 flags 拉取失败**时的降级值。」⇒ 对侧 Open question 里「以支撑离线开局」那半句**在本库不成立**，答复时须一并纠正措辞（对侧改写归 `counterpart`）。

**C. `user://` 文件带不带 `schemaVersion` 有判据，不是全称要求。** `systems/architecture.md`：「**多字段的结构体（存档聚合、信封）必须带 `schemaVersion` 并有一条迁移路径**……**单字段的设备维度小文件不带版本**……判据是**这份文件的结构会不会增长到需要逐版迁移**。逐份落点见 `systems/services/content-service.md`、`account-service.md`、`sync-service.md`、`player-profile/game-setting.md`。」——**该判据点名了 `content-service.md` 是逐份落点之一，而本库当前没有为 `flags.json` 写下这一格。**

**D. 三份同处小文件的既有形态可直接类比：** `refresh-token.json` = `{ schemaVersion, accountId, refreshToken }`，处置「解析失败 / 字段缺失 / 版本不认识 / `accountId` 空串 → `PushWarning` + 删除」；`device-id.json` 单字段、**刻意不带** `accountId` 与 `schemaVersion`；`device-settings.json` 一个账号字段也没有 ⇒ **切账号不失效**。三者的差异都由判据推出，`account-service.md` / `game-setting.md` 明写「『`user://cache/` 下切账号即失效』不是通则，是那两份文件各自的性质」。

**E. 不做绝对时间 TTL 是本库的既定判据。** `content-service.md`「manifest 契约对位」：「**不做绝对时间 TTL**——设备时钟不可信，会误伤离线玩家。」`envelope.md` 侧同源（`X-Server-Time` 仅作诊断）。

**F. `Artwork` 取的是直接资源引用，这是 `ADR-0120` 的承重形态。** `systems/common-properties.md`：`[Export] public Texture2D Artwork`，「**取直接资源引用，不取路径字符串、也不取按 `Id` 的约定路径推导**」，三条理由各自自足（撞「不用路径作内容的键」+「不散落 `ResourceLoader.Load`」；`.tres` 里落为 `ExtResource`、**悬空由引擎在资源加载期报出**，本库不另写悬空校验；插画与 locale 无关）。

**G. overlay 的收益边界写得很窄。** `content-service.md`：「**收益：** 平衡数值、事件定义、卡牌数值**可热更而不发版**」；「**能力边界（如实）：** 本机制压缩的是**已随包发布内容的放量时机**，**不压缩内容本身的发版节奏**」；且 overlay **只改不增**，唯一例外是剧本内容。

**H. 「不做字节级断点续传」这条否决**有一个被写明的前提：「`.tres` 是 KB 级，续传复杂度换不回收益」（`content-service.md`「增量下载：文件级事务」）。**前提一旦变成 MB 级二进制，这条否决的理由当场失效。**

**I. 内容侧纪律的客户端天花板是启动期告警，等价强形态前移到打包工具。** `content-service.md` 的 `newIds` 双闸一节 + `systems/architecture.md`「纪律的可执行化」：检查对象是 `.tres` 的引用图，编译期够不着 ⇒ **同一份校验前移进 overlay 打包工具，不通过就不产出包**；客户端启动期报错保留为兜底。

**J. 美术是路线末段、挂点先占位。** `ADR-0006` / `vision/scope.md`：「美术挂点占位、末段替换」「架构中始终为美术保留可轻松替换 / 定制的挂点」。

---

## 建议方案

### 1. flags **确认落本地缓存**，且收益口径按本库既定表述、不写「离线开局」
`[既有推演]`

答案是**已经答过的「落」**（约束 A）。本草稿在这一条上**不改变任何既有规则**，只做两件事：

- **对账关闭：** 对侧的「归客户端裁决」按本库既有定案关闭；**本库 `open-questions/cross-boundary.md` 不新增待承接项**（本库无欠账），只在「对账基线」补一条留痕。对侧的改写归 `counterpart`。
- **措辞纠正：** 对侧问句里的前提「以支撑离线开局」在本库不成立（约束 B）。**真实收益只有一处：登录成功但 flags 拉取失败时的降级值**——用上一次已知 flags 优于回落到 overlay 里的布尔（后者会让被秒关的条目复活）。

### 2. `flags.json` 补 `schemaVersion`，处置 = 版本不认识就整份丢弃
`[既有推演]`

按约束 C 的判据逐项落：

| 判据 | `flags.json` | 结论 |
|---|---|---|
| 是不是多字段结构体 | 是（三格，且**字段面确会增长**——对侧 schema 里的 `enabledIds` 是已立好的保留字段，见 `counterpart`） | ⇒ **须带 `schemaVersion`** |
| 「版本不认识就整份丢弃」是否有害 | **无害**——它是**可再生的降级缓存**，丢弃的代价只是本次会话在拉到第一批 flags 之前退回 overlay 的布尔值 | ⇒ 不需要迁移路径，**丢弃即是那条路径** |

**故建议字段面为 `{ schemaVersion: int, accountId: string, flagsVersion: int, disabledIds: string[] }`，与 `refresh-token.json` 同形（约束 D）。** 这与 `device-id.json` 刻意不带版本恰好相反，而那一条的理由（单字段、无迁移面、丢弃 = 一次假换设备）**在此都不成立**——丢弃一份 flags 缓存不产生任何后端可见的副作用。

### 3. 失效语义封闭为三条，**不设 TTL**
`[既有推演]`

| 情形 | 语义 | 处置 |
|---|---|---|
| `accountId` ≠ 当前登录账号 | 必需但错误——跨账号复用等于灰度串号 | **丢弃 + `PushError`**（已定，原样保留） |
| 解析失败 / 字段缺失 / `schemaVersion` 不认识 | 可选缺失 | **丢弃 + `PushWarning`**（带 `path=user://cache/flags.json`），本次会话按「无缓存」处理 |
| 其余 | 有效 | 作为 `disabledIds` 的降级值 |

**不引入时间 TTL / 过期戳**（约束 E）：设备时钟不可信；且一份「过期的 flags」与「最新的 flags」相比，唯一的差别是它可能少关了几条内容——而这正是拉取成功后的第一件事就会修正的东西。**给缓存加 TTL 只会在断线时把玩家从「上一批已知开关」推回「overlay 布尔」，即让被秒关的条目复活**——恰好是这份缓存存在的目的之反面。

### 4. 写入时点唯一：**只在一批 flags 通过单调闸并被应用之后写**
`[既有推演]`

`content-service.md` 已定「拉回版本 > 内存值 → 应用；否则整批丢弃 + 告警 + 上报一次」，且「验签失败 / `keyId` 未知 → 拒绝该批 + 保留上一批」。缓存作为「上一批**已生效** flags」的载体，其写入点必须与「应用」逐字重合：

- 应用成功 → 覆写缓存（原子写）；
- 等值 / 更小而被丢弃 → **不写**；
- 验签失败被拒 → **不写**；
- 拉取失败（网络 / 限流） → **不写**。

**这条不写下来就会被实现成「拉回即落盘」**，那样一批未通过单调闸的旧 flags 会把已生效的那批覆盖掉——把一条内存里的护栏在盘上打穿。

### 5. 落盘的 `flagsVersion` 只作诊断，读取路径不消费它
`[既有推演]`

已定「内存 `FlagsVersion` 冷启动一律归零，缓存只提供 `disabledIds` 的降级值、**不回填版本**」（约束 A，理由是把契约依赖被违反时的停摆限制在单次会话内）。**那么盘上那一格是干什么用的，须明写**，否则日后必有人「顺手」拿它回填而悄悄拆掉那道爆炸半径闸：**它只进日志与告警上下文**（例如「用缓存降级：`accountId=… flagsVersion=…`」），**不参与任何判断**。

### 6. 登出不主动删除缓存文件
`[通行做法]`

判据已由 `accountId` 那一格承接（约束 A / D）：下次登录若是同一账号，缓存照常可用；换了账号则命中既有的丢弃分支。**主动删除只是多一条会失败的 I/O 路径，换不到任何安全性**——文件里没有凭据（凭据在 `refresh-token.json`，`account-service.md` 已明写它与 `flags.json` 的分工）。

---

### 7. 二进制资产：建议答**「不开放」**——不经 overlay 下发，换图 / 加图随版本发布
`[既有推演]`

四条理由，**任意一条单独都足以否掉，合起来是连锁的**：

- **① 它撞 `ADR-0120` 的承重形态。** `Artwork` 是直接资源引用（约束 F），在 `.tres` 里落为 `ExtResource`。**Godot 的贴图资源是导入产物**：`res://xxx.png` 能被 `Texture2D` 引用，是因为导入器在打包时产出了导入产物并随包分发；落在 `user://overlay/` 的裸 `.png` **没有经过导入器**，`ResourceLoader.Load` 不产出可被 `ExtResource` 指向的 `Texture2D`（运行时可行的路径是 `Image.LoadFromFile` + `ImageTexture.CreateFromImage`，产物是运行时对象，不是资源）。
  ⇒ 要让 overlay 下发的图被条目引用，只能**退回 `ADR-0120` 已逐条否决的形态**：路径字符串 + 运行时加载（撞「不用路径作内容的键」与「不散落 `ResourceLoader.Load`」），并自己重写一套悬空校验与解码失败处置——而这几条恰是当天那份 ADR 的理由段。
  > **落笔前须在 Godot 编辑器中实测确认这一段引擎行为**（本库纪律：不假定某机制已存在）。**但即使实测发现某条运行时加载路径可用，下面三条理由依然独立成立。**
- **② overlay 的收益边界里没有它。** overlay 的既定收益是「平衡数值、事件定义、卡牌数值可热更而不发版」，且它**只改不增**（约束 G）。新内容的图本就随版本发布；能被 overlay 改的只有既有条目——**改一张既有条目的插画是纯视觉修订，不是线上事故的止血手段**（止血手段是 flags 秒关，分钟级）。为一件从不紧急的事新开一条通道，是把复杂度买在没有收益的地方。
- **③ 它会连锁推翻「不做字节级断点续传」。** 那条否决的**前提被写明为「`.tres` 是 KB 级」**（约束 H）。贴图是 MB 级，弱网下一次失败重下整份的代价与成功率都会翻过来 ⇒ 开放二进制等于同时把断点续传、下载进度 UI、流量提示这一整块已被排除的复杂度请回来。**这是四条里最硬的一条，因为它指名了既有判据的前提。**
- **④ 排期上不需要。** 美术是路线末段、挂点先占位、末段替换（约束 J）；资产替换与发版天然同节奏。

**因此建议把 `systems/common-properties.md` 的 `Artwork` overlay 一格从「尚未答定」改为收口：**

> **overlay：** overlay 覆盖一条 `.tres` 时 `Artwork` 随之被覆盖；**指向必须落在随包基线内已存在的资产**——overlay 能做的是把这一格**改指到另一张已随包的资产**或置空（置空 → ViewModel 占位回落）。**二进制资产本身不经 overlay / blob 通道下发**，换图 / 加图随版本发布。

### 8. 配套：manifest 中出现非 `.tres` 文件时的处置 = **打包工具硬闸 + 客户端跳过并汇总告警**
`[既有推演]`

「不开放」若只是一句约定，实现期一次误配置就会把二进制推到设备上。按约束 I 的既定分级：

| 层 | 处置 | 理由 |
|---|---|---|
| **overlay 打包工具**（发布侧，强形态） | `files[]` 出现非 `.tres` 路径 → **不产出包** | 与既有两条合并期闸的前移形态同款；发布侧是唯一能在事故前拦住的地方。运维形态归对侧 `open-questions/04-content-delivery.md` 的「发布侧内容校验闸」一条，**本库不实现、不复述** |
| **客户端**（兜底） | **跳过该文件、不落盘**，`LoadAll()` 后**汇总一行** `PushWarning`（条数 + 前 N 个 path） | 处理手工塞进 `user://overlay/` 的非发布路径 |

**为什么客户端是「跳过」而不是「拒绝整批」：** 拒绝整批 = 一次误配置让全体玩家的内容更新停摆；而跳过不破坏任何既有性质——文件级事务的提交点不变，`.tres` 侧的合并与强校验照常，被跳过的文件不会被任何 `ExtResource` 指向（指向随包基线是上一条的收口）。**告警取汇总一行而非逐文件**，与 `ADR-0120` 给 `Artwork` 缺失定的告警形态同款（逐条目告警会训练出忽略整个通道的行为）。

### 9. 把「不开放」写成**可撤销的条件化记录**，而不是永久封门
`[既有推演]`

在 `art/visuals/_index.md` 留一条：**日后若确需「换图不发版」，代价是成对改动 `ADR-0120` 的引用形态 + 重开断点续传评估 + 对侧契约核对三点**（对侧那三点归 `counterpart`）。**纯加法窗口在第一批 `.tres` 写下时关闭**（`content/` 现零条目），故这条记录的作用是让日后的复议知道自己在动什么，而不是暗示它随时可做。

---

## 具体形态（可 derive 的落地面）

### 形态 1 —— `flags.json` 的四格落盘纪律（落 `systems/services/content-service.md`「flags：`ContentEnabled` 的第三层」的本地缓存那一段）

| 项 | 形态 |
|---|---|
| 路径 | `user://cache/flags.json`（不变） |
| 字段 | `{ schemaVersion: int, accountId: string, flagsVersion: int, disabledIds: string[] }`（**新增 `schemaVersion`**） |
| 写入 | 原子写走 `AtomicJsonFile`（不变）；**写入时点 = 一批 flags 通过单调闸并被应用之后，仅此一处** |
| 读取消费面 | **只消费 `disabledIds`**；`flagsVersion` 只进日志 / 告警上下文，不回填内存版本（既有规则原样） |
| 失效 | `accountId` 不匹配 → 丢弃 + `PushError`；解析失败 / 字段缺失 / `schemaVersion` 不认识 → 丢弃 + `PushWarning`；**无 TTL** |
| 生命周期 | 跨启动保留；登出不主动删除 |
| 存档影响 | **零**——不进存档、不进 Profile、不上云、不 bump 任何存档 schema |

### 形态 2 —— `Artwork` 的 overlay 收口（落 `systems/common-properties.md`）

- 现有那一行的后半句「**二进制资产本身能否经 overlay / blob 通道下发尚未答定**（见 `open-questions/deferred-content.md`），故本条只陈述可机械成立的那一半」→ **删除**，替换为建议 7 的收口表述。
- `ADR-0120` 的「后果」第 4 条同批补一句指向新 ADR（**不推翻 `ADR-0120` 的任何一条**：七类挂载面、单格形态、可空语义、告警形态、占位回落全部原样）。

### 形态 3 —— overlay 文件类别的两道处置（落 `systems/services/content-service.md`「增量下载：文件级事务」）

一行表，形态见建议 8。**不新增 manifest 字段、不提升客户端支持的 `manifestSchema` 集合、不新增第三处硬阻塞。**

### 形态 4 —— 台账（由 `/analyze-new-ideas` 执行）

| 文件 | 动作 |
|---|---|
| `open-questions/deferred-content.md` | 移出「二进制资产是否可经 overlay / blob 通道下发」一条 |
| `art/visuals/_index.md` | 「待决问题」移出同一条，改为建议 9 的条件化记录 |
| `open-questions.md`「跨边界闭合」 | 两条空档均关闭 |
| `open-questions/cross-boundary.md` | **不新增待承接项**（本库无欠账）；「对账基线」补一条留痕：两条空档由本次成对落笔关闭，对侧改动见 `counterpart` |
| `decisions/` | ADR 候选一条：**「二进制资产不经 overlay 下发；`Artwork` 的指向恒落在随包基线内」** |

---

## 后果

- **两条跨边界空档同时关闭**，`open-questions.md` 的「跨边界闭合（强制检查项）」由三条降为一条（余下的 `ComplianceManager` 覆盖面切分是本库自己的取向，不是跨边界缺口）。
- **`flags.json` 获得它在 `systems/architecture.md` 判据表里本就该有的那一格**（该判据点名 `content-service.md` 是逐份落点，而本库此前漏写）。**零存档影响、零契约影响、后端零配合。**
- **`ADR-0120` 与 `common-properties.md` 的 `Artwork` 字段定义一字不改**，只把 overlay 那一格从悬置改为收口——`common-properties.md` 因此**净变小**（删一条待答指引，补一句收口）。
- **对 derive 的影响：解除而非新增。** `systems/common-properties.md` 是 derive 顺序第 1 位；本草稿删掉的正是它内部两条指向待答清单的悬置引用之一（另一条是境界基数，见「前置依赖」）。
- **美术侧获得一条硬前提：** 资产变更随发版，`art/visuals/` 的 guide 与产出排期可据此规划，不必为「热更换图」预留任何形态。
- **对侧：** 契约报文零改动（`manifestSchema` / `flagsSchema` 均不提升），仅两处 Open question 的关闭与澄清，见 `counterpart`。

## 备选方案（已考虑并否决）

- **flags 不落缓存** — 否决：与本库既有定案直接冲突（`content-service.md` 已定），且「登录成功但 flags 拉取失败」时会回落到 overlay 的布尔，**让被秒关的条目当场复活**——正是这份缓存存在的理由。
- **`flags.json` 不带 `schemaVersion`（照 `device-id.json`）** — 否决：`device-id.json` 不带的两条理由（单字段无迁移面 · 丢弃 = 一次假换设备、有后端可见的副作用）在此**都不成立**；而 flags 的字段面确会增长（对侧保留字段）。
- **给 `flags.json` 加 TTL / 过期戳** — 否决：设备时钟不可信（本库既定判据）；且过期后的回落方向恰好与缓存目的相反。
- **拉回即落盘（不与「应用」绑定）** — 否决：会让未过单调闸的旧批次在盘上覆盖已生效批次，把一条内存护栏在盘上打穿。
- **开放二进制走 overlay，`Artwork` 改为路径字符串 + 运行时加载** — 否决：逐条撞 `ADR-0120` 的理由段（路径作键 · 散落 `ResourceLoader.Load` · 自写悬空校验），并连锁推翻「不做字节级断点续传」的前提。
- **开放二进制，但只允许「替换既有资产」不允许新增** — 否决：替换的实现难点与新增完全相同（`user://` 的裸资产仍不是导入产物），限制范围换不到任何实现简化；且「只改不增」在**资产**这一层没有对应的校验面（`newIds` 双闸检查的是内容 `Id`，不是文件）。
- **客户端遇到非 `.tres` 文件即拒绝整批更新** — 否决：一次误配置停摆全体玩家的内容更新；跳过不破坏文件级事务的任何性质。
- **把「不开放」写成永久封门（不留条件化记录）** — 否决：与本库「决策可被推翻」的治理原则不符；留一条写明代价的记录，成本是三行。

## 与既有决策的张力

**① 与 `ADR-0120` 的关系是「补完」而非冲突，但须明写，否则会被误读为推翻。**
- `ADR-0120` 的「后果」第 4 条只写到「overlay 语义只写可机械成立的部分……**已登记为待答项**」。本草稿把那个待答项答成「不开放」，**方向与 `ADR-0120` 的形态选择完全一致**（正因为取了直接资源引用，才推不出二进制热更）。
- **需要的松动：无。** 只需在 `ADR-0120` 后果第 4 条补一句指向新 ADR。**不松动时的替代：** 把收口句只写进 `common-properties.md`，不出 ADR——但那会让「为什么不开放」的四条论证无处安放，日后必被重新问一遍。**建议出 ADR。**

**② `content-service.md`「不做字节级断点续传」的理由段建议补半句适用口径。**
- **冲突点：** 那条否决的理由是「`.tres` 是 KB 级」。它当前读起来像一条无条件结论，但实际有前提。
- **松动的代价：** 一句话——「该判据的前提是 overlay 只承载 KB 级 `.tres`；二进制不经本通道下发（见 `common-properties.md` 的 `Artwork` 收口），故前提恒成立」。**不松动时的替代：** 不改，但日后任何一次「要不要开放二进制」的复议都会先在这条上绊一次。**建议补。**

**③ 对侧 Open question 的问句前提（「以支撑离线开局」）与本库口径不符。**
- 这不是本库要松动什么，而是**回答时必须一并纠正的措辞**——否则关闭动作会把一个错误前提一并固化。对侧改写归 `counterpart`；本库侧只需在留痕里写明「按本库既定口径：收益是拉取失败时的降级值，不是离线开局」。

## 前置依赖

- **本方案的第 1–6 条（flags 缓存）须与 `counterpart` 的「`no-cache` 的层次澄清 + 后端对客户端缓存的零义务 + B 组第 7 条被本缓存所依赖」一节同时采纳。** 单侧采纳即两侧不一致：只落客户端会留下对侧那条「归对侧裁决」的悬空指针（正是本次要关的空档）；只落对侧则本库的三处落盘细节仍缺。
- **本方案的第 7–9 条（二进制不开放）须与 `counterpart` 的「blob 通道不承载二进制 · 契约零改动 · 若日后开放需核对的三点」一节同时采纳。** 单侧采纳即两侧不一致：只落客户端，对侧契约里仍写着「本契约不代为裁决」的待答项；只落对侧，则 `common-properties.md` 与 `art/visuals/_index.md` 的两处悬置引用仍在。
- **建议 7 的引擎行为需在 Godot 编辑器中实测确认**（`user://` 下未导入的图能否被 `Texture2D` 字段引用）。**它不阻塞裁决**——即使实测结果不同，理由 ②③④ 独立成立。
- **姊妹草稿 `inbox/solution-draft-realm-progression-artwork-basis.md`（境界与 `Artwork` 基数）** 的「前置依赖」点名了本题。两份形状一致：该草稿的 `RealmArtwork` 换的仍是**引用**、不是二进制，故本草稿答「不开放」对它零影响，反而**关闭它的一条前置依赖**。两份可同批采纳，无先后要求。
- 本草稿**不依赖**任何仍待答的问题；两条都可独立于内容 / 美术阶段落笔。

## 仍需用户决定

**（1 项）「换图 / 加图不发版」这项运营能力，值不值 `ADR-0120` 形态的代价？**

这是本草稿唯一一条无法由既有设计推演的项——它取决于产品取向（是否预期会有节日皮肤、紧急图替、按渠道换图这类需求），而本库对此**没有任何表述**。

| 选项 | 后果 |
|---|---|
| **A. 不开放**（建议 7–9） | 换图 / 加图随版本发布。**零新增机制**：不改 `ADR-0120`、不改 `Artwork` 字段、不重开断点续传、契约零改动。代价 = 运营无法在不发版的情况下修一张画错的图（但可用 flags 秒关整条内容止血，分钟级）。**日后要开放仍可复议**，代价写在条件化记录里 |
| **B. 开放** | 须成对推翻 `ADR-0120` 的引用形态（改为某种间接寻址 + 运行时加载）、自写悬空与解码失败处置、重开字节级续传评估、并按 `counterpart` 核对契约三点。换来「换图不发版」一项能力。**纯加法窗口在第一批 `.tres` 写下时关闭** |

**推荐：A（不开放）。** 理由三条：① 收益侧全库无一处表述需要它，而代价侧要动的是一条当天刚 Accepted 的 ADR 的承重形态；② 它连锁推翻「不做字节级断点续传」这条已定判据的前提（约束 H），代价不止一处；③ 线上事故的止血手段本就已经有了（flags 秒关，分钟级，且比换图更彻底）——「换图」从来不是紧急动作。

**选 B 的正当理由（如实列出）：** 若产品侧预期存在按渠道 / 按活动换图的商业化玩法，那么在写下第一批 `.tres` 之前定 B 会便宜得多——`content/` 现零条目，纯加法窗口开着；一旦内容铺开，改的是全部条目的字段形态与全部资产的落地方式。**两个选项的成本差随时间单调扩大，这是唯一需要现在决定的理由。**

→ **已裁决（2026-08-28 · 批量评审）：选项 A —— 不开放。** 二进制资产不经 overlay / blob 通道下发，换图 / 加图随版本发布。

连带确定：

- **建议 7–9 与对侧建议 5–7 一并按「不开放」采纳**（两份成对，单侧采纳即两侧不一致）。对侧 `counterpart` 的建议 7 三点核对项**维持条件化记录形态**，不升格为待办。
- **「不做字节级断点续传」这条已定判据的前提保持成立**（`.tres` 恒为 KB 级），按草稿张力 ② 在 `content-service.md` 补半句适用口径。
- **本裁决关闭姊妹草稿 `solution-draft-realm-progression-artwork-basis.md` 的前置依赖 4。** 该草稿同批裁为「玩家角色随境界换形象（稀疏 `RealmArtwork`）」，其多张立绘随版本发布——换的是引用不是二进制，与本裁决相容。
- **flags 本地缓存那一半（建议 1–6）不含取向项，随本次评审一并采纳**：它经查证**本就不是设计空档而是台账错位**（`user://cache/flags.json` 自 08-11b 已定案），缺的只是 `schemaVersion` 等三处落盘细节；**关闭时须一并纠正对侧问句「以支撑离线开局」这一错误前提**（客户端启动 pull 硬阻塞，该路径不存在），否则会把错误前提固化进契约。

---

> **本文件是提案，不是定案。** 它与 `backend-design-documents/inbox/solution-draft-client-flag-cache-and-binary-overlay.md` 成对，**须一同评审、一同采纳**。
> 评审后请运行
> `/analyze-new-ideas game-design-documents/inbox/solution-draft-client-flag-cache-and-binary-overlay.md`
> 以提炼进主题文档、并把这两条移出待答清单。

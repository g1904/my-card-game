# content-service（服务）

> 内容资产服务：`res://` 基线 + `user://overlay/` 热更层的合并、按 `Id` 索引、统一仓储接口。**判据 ③ —— 外部 I/O 边界（内容版本比对与下载）+ 启动流程。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 存储形态：三层覆盖来源

```
res://content/**.tres        基线内容，随版本发布，只读
                             → 保证首启可用、离线可读
user://overlay/**.tres       云端下发的增量，可热更，按 Id 覆盖基线
flags（运行时态，不落 .tres）  按账号解析后的开关结果，只覆盖 ContentEnabled
       ↓ 合并（flags > overlay > res://；flags 只作用于产出侧取池）
ContentRegistry（内存）       按 Id 索引，全游戏唯一内容读取入口
```

- **overlay 不是唯一热更层**：`ContentEnabled` 另有 flags 通道这一覆盖来源，它**只覆盖这一个布尔、不改任何数值**，且不参与合并后强校验。整节见下方「flags：`ContentEnabled` 的第三层」。
- `res://content/manifest.json` 携带 **`contentVersion`** 与逐条目 hash。启动时 ContentUpdateManager 比对云端版本，有更新则下载增量到 `user://overlay/`。
- **校验点在合并之后。** 重复 `Id`、悬空交叉引用（如某遭遇战列出未知敌人 `Id`）→ `GD.PushError` **启动期早失败**。热更并未削弱这条纪律，只是把校验点从「加载 `res://` 后」后移到「合并完成后」。
- **断网降级：** 跳过更新，直接使用 `res://` 基线 —— **首启不依赖网络下载内容**（但进入游戏仍需登录）。
- **收益：** 平衡数值、事件定义、卡牌数值**可热更而不发版**，规避微信 / App Store 审核周期；同时保留启动期强校验与离线首启能力。

### 热更范围：只改不增，剧本内容是唯一例外

- **overlay 只能修改既有条目的数值 / 文案，不得新增 `Id`。** 新卡 / 新事件 / 新道具等**新内容只能随版本发布**，走应用商店审核。
- **收益：** 「旧版本客户端的存档引用到未知内容」这一风险**从根上消失**，无需任何兼容规则；ContentRegistry 的合并后强校验只需处理「已知 `Id` 的数值被覆写」这一种情形。
- **代价：** 内容更新节奏受审核周期约束——只有平衡与文案能绕开发版。

#### 例外：**overlay 对剧本内容可新增 `Id`**

**判据 = 这条纪律唯一的存在目的。** 「只改不增」防的是「旧客户端存档引用到未知内容」；而剧本文本是内容类别里**唯一不被存档引用**的一类（`CharacterProfile` 只存 key points），故为它放开新增 `Id` **不重新引入那条纪律要防的风险**。**收益 = 新剧情可热更不发版**，且不需要任何运行时请求。

例外的边界必须写窄，两条：

1. **只覆盖剧本内容类型本身**（AdventurePlot 的节点 / 分支 / 文本条目）。`CardData` / `AdventureEventData` / `ItemData` / `EnemyData` / `PlayerPowerData` / 平衡表 / **状态转换触发的定性文案**（隐藏属性跨档叙事、Finale「失败但存活」补白）**照旧只改不增**——后者有稳定 `Id` 且需启动期校验，不在例外内。
2. **新增的剧本条目不得引用本次 overlay 之外的新 `Id`。** 一条新剧本 arc 若需要一张新卡或一个新 AdventureEvent，那两者仍只能随版本发版；剧本条目只能引用**已存在**的非剧本 `Id`。这保住合并后强校验的「交叉引用不悬空」。

**残留风险与其处置：** key points 是指向剧本节点的持久化锚点，所以 overlay 或客户端版本回退可使 key point 悬空。处置为 **`PushWarning` + 叙事降级、不阻塞轮回**（与本服务「读取侧不过滤」的不对称原则同构），完整规则见 `plot-manager.md`。

##### 两条边界的机械形态：合并期的 `newIds` 双闸

合并阶段 ContentRegistry 本就知道每个 `Id` 来自基线还是 overlay，故 **`newIds` = overlay 中不存在于基线的 `Id` 集合**是免费拿到的。两条闸跑在**合并后强校验**里，全量、非 `#if DEBUG`：

| 闸 | 规则 | 违反 |
|---|---|---|
| **A · 只改不增** | `newIds` 中每个 `Id` 的宿主类型必须 ∈ { `PlotArcData`, `PlotNodeData` } | `PushError` 带 `Id` + 类型名 + 抛 |
| **B · 例外的边界二** | 新增剧本条目的每一个**外部引用 `Id`**：被引用者是**非剧本类型** ⇒ 必须存在于**基线**；是剧本类型 ⇒ 允许来自 `newIds` | `PushError` 带引用方 `Id` + 悬空 / 越界的被引用 `Id` |

**闸 A 是顺带的净收益：** 它让「overlay 只改不增」连同它的例外一起从一条评审级约定变成启动期硬校验。**闸 B 之所以不误伤正常编排**，是因为一条新 arc 的全部构件（arc + 若干 node + 内嵌的正文）都是剧本类型，它不需要引用任何新的非剧本 `Id` 就能自足（形态见 `plot-manager.md`）。

**客户端侧的天花板是阶梯第 3 级，等价的第 2 级由打包工具承担。** 第 1 级靠类型 / 可见性、第 2 级靠编译期，而这两条闸检查的对象是 `.tres` 的**引用图**，C# 编译器与类型系统都触不到它。故按「纪律的可执行化」对内容侧纪律的通用补注（`systems/architecture.md`）：**同一份校验前移进 overlay 打包工具**——喂「基线 + 待发 overlay」跑同一个 `LoadAll()` 路径，不通过就不产出包；客户端启动期的 `PushError` 保留为兜底，处理手工塞进 `user://overlay/` 的非发布路径。发布侧的执行归属见 `backend-design-documents/open-questions/04-content-delivery.md`。

### 放量开关 `ContentEnabled`：不预埋占位 Id

**否决「预埋空壳 `Id`、日后用 overlay 填充数值文案」。** 两条理由：① 与「合并后强校验」直接冲突——空壳条目要么迫使校验放宽（丢掉启动期早失败这条纪律），要么携带假数值被抽中；② 属应用商店审核灰区（随包发的是不可玩的壳）。

**采用的形态：内容随版本发布，翻开关放量。**

- 内容共有字段新增 **`ContentEnabled: bool`，默认 `true`**（见 `systems/common-properties.md`）。翻这个**既有布尔字段**完全落在「不得新增 `Id`」纪律内。**它有两个覆盖来源：** overlay（随 `.tres` 走，对全体玩家同值，生效点是下一次冷启动）与 **flags 通道**（按账号解析、轮回中途可热应用，见下方专节）——**线上秒关与灰度走 flags**，overlay 只承担随内容一起发布的初值。
- **过滤只发生在产出侧，不在读取侧**——这条不对称是机制成立的支点：

  | 侧 | 行为 |
  |----|------|
  | **产出侧**（`future-event-service` 产 eventOptions、商店库存、奖励掷骰） | **只从 `ContentEnabled == true` 的集合抽取** |
  | **读取侧**（`ContentRegistry.Get(id)`） | **不过滤**——存档引用到刚被关闭的条目仍能正确解析 |

  因此「存档引用未知内容」的风险**依然为零**：关闭一个条目只让它不再被新抽到。
- **合并后校验对 disabled 条目照常全量执行**（`Id` 唯一性、交叉引用不悬空）——它们是完整内容，只是不进抽取池。
- **结构性查表的内容类型恒启用。** 有一类内容条目**不是抽取池的成员，而是被查表读取的结构**。**这条不对称对它们的推论是「放量开关无处安放」**：关掉一条不会让它「不再被抽到」，只会在结构上造出**空洞**。故：**这类条目的 `ContentEnabled == false` → 加载期 `PushError`**，字段随内容共有字段照带但无语义；它们的解析走 `AllIncludingDisabled()`，**flags 对其不生效**。

  | 类型 | 结构身份 | 关掉一条会怎样 |
  |---|---|---|
  | `HiddenStatBandData` | 隐藏属性档位表的一行 | 档位表出空洞、触发**假跨档**，`BandIndex` 连续性校验失去意义 |
  | `LocationData` | `locationMap` 的一个**顶点** | 改图 —— 而图的稳定性是对玩家的隐性承诺（改连边 = 清空一份账号级 `LocationCodex` 资产） |
  | `LocationMapData` | 图本身（全局唯一） | 全体玩家路由崩塌 |
  | `PlotNodeData` | 剧本树上的一个节点 | 树上出空洞，一条正在进行的 arc 卡死在缺口前 |

  - **剧本内容的两个类型分野相反，同一条判据两侧都用得上：`PlotArcData` 照常参与放量**（arc 是被激活抽取的，关一条只让它不再被**新激活**；已在 key points 里的照常经 `Get(id)` 解析），**`PlotNodeData` 恒启用**。**放量的正确粒度是 arc，不是 node** —— 这也让 overlay 热更推上去的一条坏 arc 有秒关手段。形态与校验见 `plot-manager.md`；后端 flags 通道的对应表述见 `backend-design-documents/contracts/content-manifest.md`。

  - **判据的完整形态：结构身份优先于抽取身份。** 「能被抽取的才配有开关」这句话在 `LocationData` 上不够用——它**双重身份**：既是 Travel 的目的地候选（看似产出侧），又是图的顶点。**取结构一侧**。
  - **承重理由（location 一侧）：flags 是按账号解析、轮回中途可热应用、且不参与合并后强校验的通道。** 若 location 参与 flags 过滤，线上关掉若干地域可使某玩家当前 location 的邻接集合为空 ⇒ 配额闸门时产不出任何 Travel ⇒ **轮回死锁**，而 Travel 是既定的死局兜底。**这条风险加载期校验够不着**，故只能在准入上封死。
  - **代价如实记下：地域没有「线上秒关」这条运营手段**，出问题只能改 overlay、下次冷启动生效。这是为「图恒连通、Travel 恒可产出」付的价。
  - **与之配对的文案条目照常参与放量**（每档 2–3 条候选，关一条只是少一个候选、结构无空洞），秒关一条措辞的运营手段因此保留。
- 为免各产出侧漏写过滤（漏写即线上事故），ContentRegistry 直接提供 **`AllEnabled()`**，让「正确」成为最短路径。**纪律条款：任何从内容集合抽取的代码必须走 `AllEnabled()`**——与「不散落 `ResourceLoader.Load`」同级，见 `.claude/rules/data-resource-rules.md`。**这条纪律不止于条款：仓储上没有中性名 `All()`**，全量走 `AllIncludingDisabled()`，见下方「`AllEnabled()` 纪律的可执行化」。
- **加载期的「负向能力条目清单」告警。** 合并校验完成后，**逐条列举携带 `AbilityChangeElement`（`Remove` / `Disable`）的事件条目，并报出它们在全部事件条目中的占比**，`PushWarning` 输出——与既有的「战斗内法则 ≤ 1/5 配额」检查同形（**列举 + 比例，供人工审阅**，不是硬校验）。
  - **落点在内容加载侧，不在事件 outcome 侧。** 两条论证：① outcome 侧的运行时统计**样本量是 1**——1% 是**出现频次**口径，无法机械化校验，单个玩家一次轮回本就该有方差，任何阈值都会误报；② **告警要落在能被看见的地方**——内容编排的错误发生在内容侧，需在启动 / 编辑期被看见，落在玩家进程里的 `PushWarning` 等于落在没人看的地方。
  - **告警文案必须明写：这个比例不是 1% 的口径。** 1% 说的是**玩家的出现频次**、归内容编排与抽取权重侧；这里的比例只用来看**清单本身**有没有失控。
  - **同时校验 `Rarity` 与不变式：** `PowerData` / `ItemData` / `CardData` 的 `Rarity` 缺失 → `PushError`（默认值会让漏填条目悄悄落进 `Tier1` 池并污染置换候选）；模板的 `SelectCost` 内出现 `AbilityElements` → `PushError`（见 `systems/adventure-event/common-properties.md` 的不变式）。
- **能力边界（如实）：** 本机制压缩的是**已随包发布内容的放量时机**，**不压缩内容本身的发版节奏**；换来**灰度 / 分批放量 / 线上秒关**三项运营能力。

### 内容文本的语言校验与覆盖率审计

> 内容文本的多语言载体是条目内嵌的 **`LocalizedText`**（`Entries: locale → 文本`，locale 封闭为二值 `zh` / `en`）——类型形态、挂载面与两条配套纪律的权威在 `systems/common-properties.md`「内容文本的多语言形态」。本节只定**校验、审计与热更权限**。

**失败语义必须分方向，否则英文占位符阶段会被警告刷屏：**

| 情形 | 语义 | 处置 |
|---|---|---|
| **默认语言（`zh`）缺失 / 空串** | 必需缺失——一条没有正文的内容就是坏数据 | **合并后强校验** `GD.PushError` + `Id` + 字段名 + `throw`，**启动期早失败**（与 `Rarity` 缺失 → `PushError` 同档）。走 `AllIncludingDisabled()`，**disabled 条目照常参与** |
| **非默认语言缺失** | 可选缺失——降级完全可用 | **读取侧静默回落 `zh`，不逐次警告**；改由**合并后一次性审计**汇总：当前 locale 下的缺失条目数、**覆盖率**与前 N 个 `Id`，一条 `GD.PushWarning` |
| **`Entries` 出现 `zh` / `en` 之外的键** | 拼错 locale | 合并后 `GD.PushWarning` + `Id` + 该键 |

- **为什么读取侧必须静默：** 既定的英文列「全部预设占位符」意味着**每一条内容**在 `en` 下都会命中回落。逐次 `PushWarning` = 每帧刷屏的日志噪音，还会把真正的告警淹掉。
- **为什么审计必须有：** 「**告警要落在能被看见的地方**」——这正是本文件为负向能力条目清单告警写下的判据，本条是它的**第三个同形实例**（前两个：`ErrorText.AuditTranslations()`、负向条目清单）。**审计同时报覆盖率**（`en: 12 / 840 条目已翻译`），使「英文版做到哪一步了」成为一个能一眼读到的数，而不必人工点数。
- **locale 拼写校验之所以写得起，正是因为语言域封闭。** `En` / `en_US` 这类拼错会让整条文案在英文下回落中文且**没有任何症状**；若语言域是开放的，这条校验根本无从写起。
- **`en` 的占位形态 = 该 locale 干脆没有这个键**（`Entries` 只有 `zh`），由静默回落承接。这让「缺 `en` 键」= 「未翻译」成为一个**干净可判的条件**，覆盖率审计因此不需要第二套「什么算占位符」的识别规则。（`res://text/` CSV 一侧的占位符形态是另一个问题，仍待定，见 `ux/error-and-blocking-ux.md`。）
- **overlay 热更权限：`LocalizedText` 的内容归「只改不增」内。** 改一个条目的文案（含**新增一个语言键**）是「修改既有条目的字段值」，**新增语言键不构成新增 `Id`** ⇒ **线上补英文文案不必发版**，且不触碰「热更只改不增」纪律的任何前提。
- **抽取池零影响：** 一条内容仍是一个 `Id`、一个池成员，`AllEnabled()` 的行为完全不变，权重不被语言数稀释。

### flags：`ContentEnabled` 的第三层

> `GET /v1/content/flags`（**需鉴权**、按账号解析、`no-cache`）下发一批 `disabledIds`——**已按当前账号解析完毕的结果**。报文形态权威在 `backend-design-documents/contracts/content-manifest.md`；此处只定客户端怎么用。

**为什么独立于 overlay：** overlay 的合并与 `LoadAll()` 校验在**启动链第一步**，沿用 overlay 通道时「秒关」的真实生效点是玩家**下一次冷启动**；且 `.tres` 里的布尔对全体玩家同值，**灰度 / 分批放量无处安放**。

**为什么这一层安全（三条，逐条对上既有纪律）：** 不改任何数值 ⇒ 不触碰合并后强校验的任何输入，校验模型原样成立；不新增 / 不删除 `Id` ⇒ 完全落在「热更只改不增」纪律内；不影响读取侧 ⇒「存档引用未知内容」的风险依然为零。**它之所以能秒关，恰恰因为它被限制得足够窄。**

> **硬边界（不可放宽）：flags 只能覆盖 `ContentEnabled` 这一个布尔，不得携带任何数值 / 文案 / 新 `Id`。** 一旦放宽，上述三条立即失效。

- **作用点唯一 = `AllEnabled()` 取池。** 读取侧 `Get(id)` 照旧不过滤；合并后强校验照旧走 `AllIncludingDisabled()`，**flags 不参与校验**。
- **首次拉取排在登录之后。** flags 端点需鉴权，而本服务是启动链第一步（登录之前）——两者对不上。`InitializeAsync` 仍只做 manifest 比对 + overlay 合并 + 校验；flags 首次拉取由 Bootstrap 在 `SignInAsync` **之后**、`SyncService.InitializeAsync` **之前**调用（抽取池必须在轮回开始前正确，而它失败不阻塞，放在硬阻塞的 pull 之前不增加阻塞风险）。启动链见 `systems/architecture.md` 总则 4。
- **刷新时机 = 搭车信封，零轮询。** 共享应答头处理点观察到 `X-Flags-Version` 与内存值不同 → 拉一次全量 flags。秒关的实际延迟 = 该玩家的下一次上行，**分钟级以内**。不引入长连接 / 第三方推送。
- **热应用：拉到即生效于下一次抽取。** 不需重启、不需重新合并 overlay、不触碰 ContentRegistry 的校验 ⇒ **轮回进行中安全**。数值型 overlay 无此性质，这正是把它独立出来的收益。
- **本地缓存 `user://cache/flags.json`**（`accountId` / `flagsVersion` / `disabledIds`；原子写、跨启动保留，与 `sync-envelope.json` 同处同纪律）。
  - **缓存的收益不在离线开局——那条路径根本不存在**：启动 pull 是**硬阻塞**，强制在线下无权威档即不可玩，故不存在「断网启动并进入轮回」。
  - 真实收益只有一处：**登录成功但 flags 拉取失败**时的降级值。用上一次已知 flags 优于回落到 overlay 里的布尔（后者会让被秒关的条目复活）。
  - **切账号即失效**：`accountId` 不匹配 → 丢弃（`PushError` + 定位上下文）。分桶是**按账号解析后的结果**，跨账号复用等于灰度串号。与 `sync-envelope.json` 的切账号纪律同构。
- **拉取失败 → `PushWarning` + 用缓存（无缓存则用 overlay 的 `ContentEnabled` 值）+ 绝不阻塞**（硬阻塞仍只有两处）。下一次搭车观察到版本差异时自然重试——不为它另开重试机制。
- **验签走同一密钥体系**（ES256 detached + `keyId`）。**验签失败 / `keyId` 未知 → 拒绝这批 flags + `PushError` + 上报一次 + 保留上一批**，与 overlay 验签失败 → 拒绝 + 回退基线同构。
- **分桶规则哪也不放在客户端。** 端点按账号计算后只给结果；客户端始终只看到「这些 `Id` 现在不进抽取池」，**永远不知道分桶规则存在**。⇒ `DrawPool<T>` 的构造签名**不必**变成 `AllEnabled(bucketContext)` 一类，它的唯一依赖就此解除。

### 存档记录 `contentVersion`：记两个

| 字段 | 语义 |
|------|------|
| `CharacterProfile.StartContentVersion` | 轮回开始时生效的版本，**写一次不再变** |
| `CharacterProfile.LastContentVersion` | **每个自动存档点**更新为当时生效的版本 |

- 二者不等 = 该轮回**跨过内容更新**，是排查「数值突变」类玩家反馈的**第一判据**。因不冻结 `contentVersion`（见上节），一个版本号无法表达「跨过」，故必须记两个。
- **push 负载信封同时携带** `contentVersion` / `appVersion` / `revision`，让后端**不解 Profile** 即可做版本维度聚合与异常检测（见 `sync-service.md`）。
- **不为每日种子 / 排行挑战预留冻结结构**——它们不在中期路线图内（`vision/scope.md` 的开发路线第 ④ 阶段）。**方向性记录：** 若将来引入挑战模式，正确做法是让**该模式内的轮回绑定一个冻结的 `contentVersion` 快照**，把例外**局部化**，而非回退全局的「以 overlay 为准」决策。

### 增量下载：文件级事务

- **粒度 = 文件级。** manifest 已携带逐条目 hash，只下载 hash 不匹配的文件。**整包全量重下仅两种情形**：首次安装 overlay、本地 overlay 是按**旧 `manifestSchema`** 落地的（客户端支持云端那个 schema，但本地布局对不上）。
- **`manifestSchema` 不受支持则跳过，不是重下。** 客户端内置一个「支持的 `manifestSchema` 集合」；云端 manifest 的 schema **高于**该集合 → **跳过本次更新、照常用现有 overlay / 基线**，与断网降级同构。两种情形必须分开——把「不认识的结构」当成「重下一遍」只会把同一个失败重复一次。
- **不做字节级断点续传**（`.tres` 是 KB 级，续传复杂度换不回收益），改做**文件级事务**：

```
user://overlay/                 已生效热更层（永远完整）
user://overlay.manifest.json    提交点：contentVersion + 逐文件 hash + 签名
user://overlay.staging/         下载落地区，允许脏，失败即清空
```

- **更新流程：** ① 比对本地与云端 manifest 得出待下集；② 逐文件下载进 `overlay.staging/` 并**逐文件校验 hash**，失败重下该文件（指数退避，最多 3 次）；③ **全集齐备且全部校验通过后**才搬入 `overlay/`，最后**原子写 `overlay.manifest.json`（临时文件 → rename）= 提交点**；④ 任一步失败 → 清空 staging，`overlay/` 与其 manifest **保持上一个完整版本**，本次更新视为**未发生**，走既有断网降级（用现有层照常开局）。
- **由此永不存在半套 overlay：** `overlay/` 的有效性由**那一次 rename** 定义——与存档原子写**同构**。

### manifest 契约对位：客户端的四条义务

服务端只保证三件事（每个文件有稳定 URL · URL 字节不可变 · manifest 与它列出的文件发布上原子），事务模型全在客户端一侧。对上后端 manifest 字段表，客户端另有四条**具体义务**：

- **`files[].path` 落盘前校验路径穿越**（禁 `..` 与绝对路径）——这是内容分发里唯一有实质危害的注入面。
- **`files[].size` 用于下载前的磁盘空间预检**，使「磁盘空间」这类失败提前判定，而非写到一半才失败（对上 `CheckAndUpdateAsync` 已定的磁盘分支）。
- **拒绝 `contentVersion` 小于本地已生效版本的 manifest**（防回放）。**不做绝对时间 TTL**——设备时钟不可信，会误伤离线玩家。
- **`minAppVersion`（manifest 内 · 内容维度）由客户端自行比对**，规则 = **semver 三段逐段整数比较**，不做字典序（字典序会判 `1.10.0 < 1.9.0`，且这类 bug 发版后才显形、无法在设备上复现）。低于它 → **跳过本次 overlay、照常用基线，永不阻塞**。**它与协议维度的强更闸门互不兼职**：后者由服务端判定、以 `client.version_unsupported` 在登录 / 启动点硬阻塞，客户端**不比较** `X-Min-App-Version`、也不持有兼容矩阵的任何副本。内容太新只是不更新内容；协议不兼容才拦人。

### 防篡改：manifest 签名

- 后端**私钥签 manifest**（ES256 detached），客户端**内置公钥验签**；逐文件完整性由**已签名 manifest 内的 hash**（SHA-256）保证（一次验签 + N 次 hash，近乎零成本）。
- **客户端内置的是一组 `keyId → publicKey` 映射，不是一把公钥。** 轮换靠先发内置新旧两把的客户端版本、覆盖率足够后服务端再切私钥；没有 `keyId` 则轮换只能靠强更，且事后无法补救。信任根是**固定公钥（pinned）**，不引入证书链 / PKI——威胁模型只到「防误 / 防随手改」。
- 校验不过 → `GD.PushError` **拒绝该 overlay、回退 `res://` 基线**、上报一次事件。
- **明确边界：** 客户端完整性做到「**防误 / 防随手改**」为止，**不承诺防作弊**（改内存 / 改二进制不在防御范围）。纯 PvE + PlayerPower 已被接受为「轻度提升、影响平衡可容忍」，反作弊无收益。

### overlay 与进行中轮回：以 overlay 为准

- **不冻结轮回的 `contentVersion`。** 轮回进行中 overlay 被更新时，**新数值立即对进行中的轮回生效**。
- **明确放弃「同一 seed 必然复现同一轮回」的保证**——它让位于「线上数值可随时修正」。确定性因此降级为**同一 `contentVersion` 内的性质**：存档恢复仍必须正确继续（RNG 状态照常持久化），只是不承诺跨内容版本可复现。详见 `systems/common-properties.md`。

### 统一操作接口

ContentRegistry 为每种 `XxxData : Resource` 持有一个仓储，对外是**同一形状**：

```csharp
IContentRepository<T> where T : Resource
    T                Get(string id);                 // 必需：缺失 → PushError + 抛出；不过滤 ContentEnabled
    bool             TryGet(string id, out T v);     // 可选：缺失 → 调用方降级
    IReadOnlyList<T> AllEnabled();                   // 抽取池：仅 ContentEnabled == true
    IReadOnlyList<T> AllIncludingDisabled();         // 全量：启动期校验 / 图鉴统计 / 调试
    IEnumerable<T>   Where(Func<T,bool> predicate);  // 不过滤；调用方自负
```

**没有中性名 `All()`——它已被删除**（见下方「`AllEnabled()` 纪律的可执行化」）。

**所有服务经此取内容；代码中不散落 `ResourceLoader.Load`。** 新增一种内容类型 = 新增一个 `XxxData` 与一个仓储条目，**不新增服务、不改调用方**——这正是「同类内容的统一入口与标准操作接口」这一诉求的正确落点（而非按内容类型各开一个服务，见 `_index.md` 的拆分轴）。

### `AllEnabled()` 纪律的可执行化：删掉中性诱饵名

> 「抽取必走 `AllEnabled()`，漏写即线上事故」此前只是一条约定。按 `systems/architecture.md`「纪律的可执行化」的选级判据，它属**能上线且线上不可见**（漏写过滤后游戏照常运行，错误只在真实玩家身上显形），**必须做到阶梯第 1 / 2 级**。

**核心动作是删除 `All()` 本身，而不是给它改名。** 漏写过滤的发生机制是「随手写了那个最短、最中性、看起来最无害的名字」——只要 `All()` 还在，它就是诱饵。两个名字都带修饰语时，作者**必须在两种语义之间做一次显式选择**；写下 `AllIncludingDisabled()` 的人不可能声称自己没意识到有 disabled 条目这回事。

| 成员 | 语义 | 阶梯级 |
|------|------|--------|
| `AllEnabled()` | 抽取池，`ContentEnabled == true`。**产出侧唯一取池入口** | 1 |
| `AllIncludingDisabled()` | 全量。**合并后强校验是它的第一个正当调用方**（disabled 条目照常参与 `Id` 唯一性与交叉引用校验），另有图鉴统计 / 调试——这使「两个显式名」不是多余的对称 | — |
| `[Obsolete(error: true)] All()` | **过渡期硬闸**，恒抛。任何出于惯性写下 `All()` 的代码（**包括 AI 生成的**）当场编译失败并被指路。保留至少到内容阶段结束 | 2 |

**否决 `All()` 保留但语义改为 enabled-only：** 最短路径确实安全了，但一个叫 `All` 却不返回全部的方法**会撒谎**——用错误的名字换安全，只是把 bug 挪到未来（写图鉴统计的人读到 `All()` 会以为拿到了全集）。**否决 Roslyn 分析器：** `[Obsolete(error: true)]` 拿到同一份编译期保证，成本低几个数量级。

#### `DrawPool<T>`：抽取池独立为一个类型（已采纳，排到第二阶段开工前）

命名改造让漏写过滤极难，但仍未做到不可能：`Where(...)` 或 `AllIncludingDisabled()` 的结果照样能被拿去抽取。终局形态是把 `AllEnabled()` 的返回类型换成 `readonly struct DrawPool<T>`（薄包装、零堆分配），并**只在其上定义 seeded 抽取方法**（`PickOne(rng)` / `PickMany(rng, count)` / `Filter(predicate)` —— 过滤后仍是 `DrawPool<T>`）。于是「从内容集合抽取」这个动作在语言层**只能从抽取池发起**：`AllIncludingDisabled()` 返回的 `IReadOnlyList<T>` 上根本没有 `PickOne`。顺带给 seeded 抽取一个统一落点（抽取逻辑散在下方五个已登记调用方）。

**排期：第二阶段（内容）开工前、第一份内容 FR 之前落地；本阶段 `AllEnabled()` 仍返回 `IReadOnlyList<T>`。** 理由：彼时各抽取侧都已有真实调用方，能验证 `PickOne` / `PickMany` 的形状是否够用，此刻定死形状是纸上设计。（**原先的第二条理由已消失**：分桶留在服务端，客户端只见按账号解析后的 `disabledIds`，构造签名不必带 `bucketContext`——见上方 flags 一节。）**延后风险低**（纯加法改造，受影响的只有抽取侧），**但不可再往后拖**——抽取侧一旦写完再改返回类型，就从「纯加法」退化为「改调用方」。

**同批落地的还有 `LocalizedText`：** 两者的排期理由完全相同（纯加法窗口，一旦内容写完就退化为「改全部调用方 / 全部资产」），且都是同一次 `XxxData` 面的改动，宜一并做掉。见 `systems/common-properties.md`「内容文本的多语言形态」。

**调用方共五处：** future-event-service 物化 · 商店库存 · 奖励掷骰 · **账号级 / 轮回级能力的授予池**（残卷 · 礼包 · 置换共用一段抽取，宿主是 profile-service 的 `GrantPoolPicker`，见 `systems/player-profile/player-power/_index.md`）· **闭关构筑面板的功法候选**（`CultivationTechniqueData` 加权无放回抽取，见 `systems/adventure-event/research/common-properties.md`）。**这加强了「第二阶段开工前落地」的排期理由。**

**抽取原语只有两级，不设第三级（承重）。** 第一级 `DrawPool<T>`（本服务，`readonly struct`）是抽取动作在语言层的**唯一发起面**，只认内容侧的过滤（`ContentEnabled` / `ExclusiveSource` / `Rarity`）；第二级 `GrantPoolPicker`（profile-service 内 `internal`）在其上固化能力授予的四道过滤 + 排重 + 稀有度锚定，供残卷 · 礼包 · 置换共用。

- **分界判据 = 这道过滤需不需要读 `Profile`。** 不需要的留第一级；需要的（排除已持有）只能在第二级——它读的是 profile-service 的自有状态。这条判据同时解释了为何其余调用方不经第二级：它们抽的不是能力条目、没有「已持有」这个概念。
- **否决「为统一抽取再造一个通用原语」**（带策略参数的 `Draw(spec)` 之类）：两级分工已经对上判据，第三级只会给「抽取代码只有一处」这条纪律多一个绕行入口；且策略参数化无法被编译器约束——一个填错的 spec 与一个正确的 spec 类型相同。
- **推论：全库抽取代码的落点恰好是两处**，其余调用方都是「构造一个 `DrawPool<T>` 然后 `PickOne`」的三五行。

**两条契约由授予池这个调用方定死：**

- **`PickMany(rng, count)` 是无放回的。** 礼包一次给 2 件古宝必须两件不同；这是 `PickMany` **唯一一处会被误实现成有放回**的地方，故无放回写进契约、不留给实现自由裁量。数量不足 `count` 时按可选缺失处理（返回 false + `PushWarning`），不静默少给。
- **`PickOne` / `PickMany` 需要加权重载**（按内容定义上的 `Rarity: RarityTier` 取权重表）。战后奖励池的稀有度权重（`Rarity` 的消费点 ①）同样需要它。权重表本身是平衡数值，归 `systems/balance.md`，不落 `DrawPool<T>`。
- **随机源参数是泛型约束的 `IRandomSource`**，不是 Godot 的 `RandomNumberGenerator`：`PickOne<TRng>(TRng rng, …) where TRng : IRandomSource`。账号级授予传 `AccountRandom`（契约定义的 SplitMix64），轮回级三处抽取传 `GodotRandomSource`（子流的薄适配）。**取泛型约束而非裸接口参数**——值类型经泛型特化调用，零装箱、零堆分配。类型定义见 `systems/common-properties.md`。

### 全部内容都属本地内容层

**没有云端内容通道。** 一切内容——包括 AdventurePlot 的剧本文本与分支——都存于 `res://content/` 基线 + `user://overlay/`，经 ContentRegistry 按 `Id` 读取。**运行时内容零网络请求**；网络只在启动期用于 manifest 比对与增量下载。

**不要按「按进度动态请求、一次性呈现、不被存档引用」把某类内容划到云端。** 那条判据是描述性的（「动态请求」是选择的结果而非理由），且它划出的云端一侧要带来整套为网络失败而生的复杂度与一条跨进程边界。理由全文见 `plot-manager.md`。

内容仍按**是否被存档引用**分两类，但这条区分现在只决定 **overlay 能否为它新增 `Id`**（见下节），不决定它存在哪里：

| 是否被存档引用 | 内容 | overlay 权限 |
|---|---|---|
| **被存档引用** | `AdventureEventData`、`CardData`、`EnemyData`、`ItemData`、`PlayerPowerData`、平衡表，**含静态展示文案与状态转换触发的定性文案** | **只改不增** |
| **不被存档引用** | AdventurePlot 的剧本节点 / 分支 / 文本（`CharacterProfile` 只存 key points，剧本正文永不进存档） | **可新增 `Id`** |

## 管理器

| manager | 职责 |
|---------|------|
| **ContentRegistry** | 合并 overlay + 基线，按 `Id` 建立索引，暴露泛型仓储接口；合并后统一校验 |
| **ContentUpdateManager** | 读本地 manifest、比对云端 `contentVersion`、**manifest 验签**、逐文件下载进 `overlay.staging/` 并校验 hash、事务性搬入 `overlay/`、断网降级 |

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-08-09e-discipline-enforceability.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-11-plot-content-localization.md` · `handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md` · `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md` · `handoffs/2026-08-12e-ability-grant-draw-pool.md` · `handoffs/2026-08-13-translation-key-rollout-and-content-localization.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md`

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务实现 `IBootstrappable`，是启动链**第一步**（版本比对 + overlay 合并 + 校验；断网降级到 `res://` 基线）。**`RefreshFlagsAsync` 不在 `InitializeAsync` 内**——flags 端点需鉴权，故它是启动链中登录之后的独立一步（见 `systems/architecture.md` 总则 4）。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 版本比对 + 下载 | B | `Task<OpResult<ContentUpdateInfo>> CheckAndUpdateAsync(CancellationToken ct)` | 业务失败 → `OpResult`；`OpError` 区分 `Network` / `Validation`（hash 或签名不符）/ 磁盘空间，三者 UX 与上报处置各不相同 |
| 合并加载 + 校验 | A | `void LoadAll()` | 校验失败 = **坏数据** → `GD.PushError` + 定位 `Id` + `throw`（启动期早失败）。**disabled 条目照常参与校验** |
| 取仓储 | A | `IContentRepository<T> Repo<T>() where T : Resource` | 未注册的类型 = 程序缺陷 → `PushError` + 抛 |
| 当前版本 | A | `int ContentVersion { get; }` | — |
| flags 刷新 | B | `Task<OpResult> RefreshFlagsAsync(CancellationToken ct)` | 失败 → `PushWarning` + 降级到 `user://cache/flags.json`（无缓存则用 overlay 的 `ContentEnabled` 值）；**绝不阻塞**。验签失败 → `PushError` + 拒绝该批 + 保留上一批 |
| flags 版本观测 | A | `void OnFlagsVersionObserved(int flagsVersion)` | 由 `src/Core/` 的共享应答头处理点调用；与内存值不同则内部触发一次拉取。**观测者不判断要不要拉，判断在本服务内**——否则每个 backend 各写一份判断 |
| 当前 flags 版本 | A | `int FlagsVersion { get; }` | — 只读诊断 |

```csharp
public readonly record struct ContentUpdateInfo(int FromVersion, int ToVersion, int FilesApplied, bool FellBackToBaseline);

public interface IContentRepository<T> where T : Resource
{
    T                Get(string id);                 // 必需：缺失 → PushError + throw；不过滤 ContentEnabled
    bool             TryGet(string id, out T v);     // 可选：缺失 → PushWarning，调用方降级
    IReadOnlyList<T> AllEnabled();                   // 抽取池：ContentEnabled == true；产出侧唯一取池入口
    IReadOnlyList<T> AllIncludingDisabled();         // 全量：启动期校验 / 图鉴统计 / 调试
    IEnumerable<T>   Where(Func<T, bool> predicate); // 不过滤；调用方自负

    [Obsolete("抽取走 AllEnabled()；确需含已关闭条目走 AllIncludingDisabled()。", error: true)]
    IReadOnlyList<T> All();                          // 过渡期编译闸，恒抛
}
```

- **`Repo<T>()` 而非七个具名属性：** 新增内容类型 = 注册一个仓储，**调用方与服务签名都不动**（可加性）。
- **`AllEnabled()` 是物化取池的唯一入口：** future-event-service 物化时必须从 `AllEnabled()` 取候选；`Get(id)` 不过滤——使存档中引用到已关闭条目的实例仍能正确解析。
- **没有中性名 `All()`；合并后强校验走 `AllIncludingDisabled()`。** 理由与 `DrawPool<T>` 的第二阶段排期见上方「`AllEnabled()` 纪律的可执行化」。
- **返回的集合一律 `IReadOnlyList<T>`**（总则 3：服务不返回内部可变集合）。

**后端接口（总则 7）：** 本服务持有 `IContentBackend`（`GetManifestAsync` 等），两份实现 `HttpContentBackend` / `OfflineContentBackend`。

**事件面：** `ContentUpdateFinished(ContentUpdateInfo Info, bool Success)` 经 EventBus 广播给启动流程 / UI；校验失败明细与 overlay 验签拒绝走 `GD.PushError` 日志 + 该事件的 `Success = false`。

## 决策(-> ADR)

- **内容载体形态（随包基线 + user:// 覆盖层 + 云端版本校验）** → **ADR 候选**（待固化）。**固化时须一并纳入两条**：全部内容属本地内容层（不设云端剧本服务）· overlay 对剧本内容可新增 `Id`。
- **overlay 增量下载**仍依赖 **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。其适用面**只剩启动期的 manifest 比对与下载**——运行时内容读取全程本地。

## 待决问题

- **flags 拉取的频次护栏。** `X-Flags-Version` 每次应答都带；若服务端版本在短时间内连续抖动，客户端是否需要一个最小拉取间隔，或只在版本**增大**时拉？
- **disabled 条目被存档引用时的 UX。** 读取侧不过滤，故存档能正确解析；但玩家手中一张「已被线上关闭」的卡 / 道具**是否应有任何提示**，还是完全静默照常可用，未定。→ 亦见 `ux/`。
- **剧本内容的体积与分发粒度。** 三篇章的完整剧本树是一笔真实的包体 / 下载量成本。是否需要按篇章分包、按进度增量下载？文件级事务与逐文件 hash 已现成，未定的是**分包边界**。**语言维度不在其内**：多语言已定为全语言内嵌于同一 `.tres`、**不按语言分包**（双语封顶 ⇒ 体积上限固定为 ×2，分包的唯一实质动机消失），故这条问题回归它原本的形态——**剧本树该不该按篇章分包**，两者互不牵动。权威归 `plot-manager.md` 的同名待答项。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-11-plot-content-localization.md` · `handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md` · `handoffs/2026-08-13-translation-key-rollout-and-content-localization.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-16i-plot-data-encoding.md`

## 对应
提炼至：`.claude/knowledge/systems/content-service.md`（引用层，待建）。

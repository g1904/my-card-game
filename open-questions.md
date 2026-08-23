# Open questions — 跨 session 待答清单（索引）

> 本文件是**客户端**（Godot 项目）待答清单的**索引**：问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 后端侧的待答清单在 `backend-design-documents/open-questions.md`（`backend-design` 分支）。
>
> 每次 session 结束时，未答的 Open questions 汇总到对应分片，供下次拾起；一旦答定，就从分片中移除、
> 归档进对应主题文档的 `## 待决问题` / `## 决策`，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> 本清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**。
>
> 最近更新：2026-08-22 — 十一份 solution draft 补跑 Phase B（移出 15 条 · 新增 10 条 · 修 8 处活文档漂移 · 11 份 answer log）
> （逐次变更摘要见 `open-questions/update-log.md`；已答定问题的逐条移出记录见 `answer-logs/`）

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序，**只留最近 10 条**。不含问题条目本身。 |
| `open-questions/update-log-archive.md` | 更早的更新摘要，原样归档、按时间正序。只读，不写新条目。 |
| `open-questions/01-combat.md` | **① 战斗机制**（焦点之首）：能力剥夺与统计计数的残留（片区主体已于 08-10c 答结）、结构与配置、内容与数值（多数已归 ch1 数值标杆专场）、**信息面**（意图移除后图鉴是唯一事前通道）、呈现。 |
| `open-questions/02-event-options.md` | **② eventOptions 生成流程**：生成 / 加权与配比、物化字段、优先级、寿元打穿、Explore 揭示池、Travel 出场、location 与图鉴连边。 |
| `open-questions/03-adventure-event-types.md` | **③ 逐类型 AdventureEvent 机制**（五类各开一场专门 session）。 |
| `open-questions/04-hidden-attributes-plot.md` | **④ 隐藏属性 / 剧本机制**：档位阈值、跨档叙事、`lifeSpanCost` 分档、隐藏属性推拉映射、DnD 选分支的触发点与 UI、剧本内容的分发粒度。 |
| `open-questions/05-service-contracts.md` | **⑤ 服务契约 / 工程侧残留**：`#if DEBUG` 判据与 `Control` 自动翻译的实测、需求流水线形态、`architecture.md` 的三条结构残留、层级词的过早性。 |
| `open-questions/06-meta-progression.md` | **⑥ 元进程的失败侧与中长期规划感**：死亡 / 轮回结束屏尚无设计、轮回内的进度感是否需要补充、失去法则三支的频次预算、角色模板池的形态。 |
| `open-questions/07-codex-monetization.md` | **⑦ 图鉴族与商业化**：`CharacterPower`、六本图鉴、premium bundle。 |
| `open-questions/cross-boundary.md` | **跨边界承接**：对侧（后端）已定案、本库尚未落笔的条目。**不是待答问题**——答案已有，等的只是落笔；形态、关闭条件与维护者分工见分片抬头。 |
| `open-questions/deferred-content.md` | **已搁置：内容充实**（07-30 起暂不推进）＋ **美术与音频（`art/`，08-04 加入）** ＋ 随内容搁置的 UX 呈现细节 ＋ 尚未设计的占位主题。 |

## 当前焦点：各系统机制细节

> **焦点判据（07-30 定）：** **规则、字段语义、流程与算法 = 机制细节 = 焦点**（分片 ①–⑦）；
> **具体条目目录与数值 = 内容充实 = 搁置**（`open-questions/deferred-content.md`）。
> 与既定开发路线「框架 → 内容 → 平衡与体验 → 社交及其他」的第 ① 阶段一致。
> Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。
>
> 焦点顺序即分片编号顺序；**① 战斗机制**优先级最高。

## derive 就绪度

> **本小节由 `/assess-derive-readiness` 独占写入**（`/analyze-new-ideas` 与 `/summarize-open-questions` 均不得改动）。就绪度是全库横切判断，须基于一次性全量扫描才有意义；逐次 handoff 顺带的评估会迅速过时且互相矛盾。

**最近全量评估：2026-08-22（由 `/assess-derive-readiness` 产出）。** 扫描范围：`vision/`（3）· `systems/**`（53）· `art/**`（12）· `ux/`（5）· `decisions/`（29）+ 根级横切 3 份（`terminology.md` / `program-overview.md` / `system-overview.md`），共 **105 份**。本次重估的触发是 08-22 单日的三批集中落笔——`/batch-analyze-new-ideas` 两轮（10 份 + 11 份 solution draft，移出 24 条）与 `/write-adr` 固化 4 份新 ADR（`ADR-0025` ~ `ADR-0028`），外加 `/summarize-open-questions` 的 9 处主题文档修平。

**全局结论：ready 4 份 · partial 24 份 · blocked 77 份 —— 可 derive 的面由 17 份增至 28 份，玩法侧首次出现可 derive 的切片。** 上次评估记录的**两处 🔴 大卡点倒下了一处**：

- **✅ `future-event-service` 的生成 / 加权运算形态（上次的第二处 🔴，四个非战斗子类型 + `game-progression` + `plot-manager` 合并算法共六份文档的共同上游）。** 08-22 落成 `ADR-0026`「eventOptions 十步管线」：类型修正 = 乘性系数 · 多 arc 权重相乘 / 白名单取并 · 三层框定的叠加顺序 · 批次规模由 `BatchSizeWeights` 掷定且收缩保底走 Travel（**连带答掉 Travel 槽位数 `k` 的来源**）· `SelectionWeightGrade` 三档 · 满级 Finale 走闸门式旁路。它一举把 `future-event-service` / `plot-manager` / `game-progression` / Explore / Travel / Research / Exchange **七份文档从 blocked 抬进 partial**，是本次全部增量的来源。
- **🔴 ch1 数值标杆专场（唯一剩下的大规模卡点，未动，且比上次更大）。** `systems/balance.md` 的待决问题由 11 条**增至 12 条**（新增「卡牌费用曲线是否随境界整体上移」——它是 08-22 定案的「`manaLimit` 每次大境界 +1」这条结论**唯一的翻盘前提**）。量纲基准 / `lifeSpanCost` 定价表逐格 / 三档奖励厚薄 / 回复幅度 / 商店四组数值格 / `HiddenStatGrade` 三个映射值 / Explore 真身占比 / 功法层数上限 / 闭关三格 / `EncounterTighten` 六个界常量 / `EnemyManaLimit` 校准 / blind · ante 曲线全部挂在这一场上；其中**商店定价仍被 `currency.md` 的 jade 获取渠道阻塞**（产出侧空白时无从反推消耗侧）。

**本次新增的一类判定输入：`[采纳推荐 — 待复核]` 项。** 08-22 两批批量提炼共留下 **20 项**「按推荐落笔、但未经用户拍板」的取向（分布在 13 份主题文档中）。按批量编排铁律，它们**不算用户裁决**，仍是待答项。本次采用的收窄判据是：**一项 `[采纳推荐 — 待复核]` 只有在「推翻它会改变由该文档推导出的 FR 的某条可验证验收标准」时才降级该文档**；纯落笔位置 / 权威归属类的编辑性项不降级（例：`systems/common-properties.md` 只承接「`Id` 不含 `#` / `:` 的权威上提」一项，属编辑性，故仍判 ready）。据此，`systems/architecture.md` 因两项字段形态待复核（`HiddenStatDirection` 不设 `Unset` 哨兵 · `HiddenStatGrant.Stat` 宽类型 + 加载期收窄）**由 ready 降为 partial**——排除面很小，但它改的是一个枚举的形状和一条加载期校验，正是验收标准会逐字引用的东西。

> **本次最便宜的一次解锁不是任何一场设计 session，而是一次复核会（把这 20 项逐条转正或推翻）。** 它零新增设计，却能把 `architecture.md` 送回 ready，并同时收窄 `future-event-service` / `plot-manager` / `account-service` / `content-service` / `adventure-event/common-properties.md` 五份的排除面。

**跨边界闭合（强制检查项）：两处未闭合，均须在 derive 时显式排除。**
- **`account-service` 的合规呈现面**（沿用上次）：后端 `contracts/compliance.md` 只定了端点集与承重纪律，**六端点的报文字段表与合规域自身的错误码仍在它的 Open questions 里**，故客户端写不出可验证的验收标准。
- **`content-service` 的 flags「增大即拉」整条**（本次新增）：客户端 08-22 已采纳并**开始依赖**「flags 回滚须以更高 `flagsVersion` 发布」，而该条款在 `backend-design-documents/contracts/content-manifest.md` 中**明写「本契约尚未写下」**。依赖未成文条款即上线，症状是设备**永久停拉 flags**（秒关不生效、误关的内容永不恢复）——这正是横切检查 6 要挡的东西。
- 另有一处**不判 blocked 但须留痕**：`sync-service` 的上行整键回声校验**成对采纳尚未完成**（客户端半已落笔，后端半的受约束 path 封闭清单与非整数比较口径未落笔）。后端库明写「客户端半的『不得再加工』纪律在两种口径下都成立，故不阻塞客户端」，故本次判 partial 而非 blocked，但该切片须排除。
- `open-questions/cross-boundary.md` 的「待承接」仍是 **1 条**（`ComplianceManager` 客户端覆盖面的切分，是本库自己的取向）。

| 文档 | 判定 | 卡点 / 就绪切片 |
|------|------|------------------|
| `systems/common-properties.md` | **ready** | 待决问题明写「无」，唯一挂靠项（`Id` 不含 `#` / `:` 的权威上提）属编辑性。整面 = 稳定 `Id` 与展示字段三层切分 · 物化模型 · `LocalizedText`（封闭二值 locale · `Get()` 纯读 · 不落存档）· `ContentEnabled` + `AllEnabled()` / `AllIncludingDisabled()` 双名与编译闸 · `RarityTier` 五档 · `SourceCode` + `Source` 八值 + 合法子集表 · `ExclusiveSource` · 两级 seeded RNG（轮回级四子流 + `State` / `DrawCount` 持久化；账号级 SplitMix64，8 组测试向量在 `backend-design-documents/contracts/profile-sync.md` §6a，验收可逐位对表）· API 契约总则三形态 / 三失败语义 · `deviceId` 落点 |
| `systems/viewmodel.md` | **ready** | `## 待决问题` 明写「当前无未决项」，零待复核。整面 = 展示层第三层的结构契约（呈现期对象、不落存档 / 不进云端负载 · 单向依赖且服务 API 面永不返回 ViewModel · 组装源三件套 · 三条重组装触发面，含「订阅翻译变更即重组装」· 只读消费与缓存归属 · 永不渲染清单）。**须与 `systems/architecture.md` 同批 derive** |
| `systems/player-profile/codex/common-properties.md` | **ready** | **本次由 partial 升级**：本文件无 `## 待决问题` 小节且无待复核项；`ADR-0027`（`LocationCodex` 顶点级显影）已 Accepted，存档面因此整份闭合。整面 = `CodexEntry` 首批一格 `Id` + `CodexKind` 六值 / `CodexUnlock(Kind, Id)` + `CodexElements` 列与零 `Op` / 恒不经 pipeline + 四行失败语义 + 六本解锁触发（全部搭在既有提交上，零新增提交点）+ `CodexFlavor` 作为全库第一个可选 `LocalizedText`。**呈现面不在本文件**（在 `codex/_index.md`，blocked），derive 时不取任何图鉴屏 |
| `ux/onboarding.md` | **ready** | `## 待解问题` 明写「当前无未决项」。整面 = 强制登录无游客 + 首版只呈现已实现渠道 + 手机两步握手 UI（验证码框 + 倒计时始终可见的重发按钮 + 过期重取，无 hover 提示）+ 绑定 / 解绑不落登录屏 + 首玩篇章门禁。**与 `ux/screen-flow.md` 的登录屏切片重叠，须同批 derive** |
| `systems/architecture.md` | **partial** | **本次由 ready 降级**（唯一一处降级）：`## 待决问题` 的一条是自陈「台账事项 · 不阻塞 derive」的 `architecture.md ↔ services/*` 对账，不构成卡点；真正的排除面是意图正文里两项 `[采纳推荐 — 待复核]`——`HiddenStatDirection` 二值封闭不设 `Unset` 哨兵 · `HiddenStatGrant.Stat` 保持宽类型 `HiddenStat` 由加载期校验收窄为 `{ Faith, Bloodlust }`。就绪切片 = 其余全部：三层切分 · 七服务边界与 autoload 注册顺序 · EventBus 总则 · API 契约总则 · 边界服务「接口 + Http/Offline 双实现」骨架 · `ElementSpec` 六列 / `ModifierKey` / 钳制表 · `ProfileChangeSpec` 的完整十列 · 「一个新的施加语义该落在哪一列」三级判据 |
| `systems/services/sync-service.md` | **partial** | **本次由 ready 降级（跨边界）**：`## 待决问题` 的 `pushId` 后端记忆窗口是对侧参数、不阻塞；排除面是**上行整键回声校验的成对采纳未完成**——受约束 path 的封闭清单与非整数路径比较口径的权威在 `backend-design-documents/contracts/profile-sync.md` §5c，对侧尚未落笔。就绪切片 = 其余全部：存档点 ↔ push 解耦 + 5 秒防抖 + 立即 flush 清单 + `PushPolicy` + 本地缓存原子写 + schema 版本化与迁移 / 拒绝 + `CharacterProfile` 级 diff + `revision` CAS / `pushId` 幂等 + `Source` 上行走成员名 + 后端主动写入后的 pull 时序 + 断线降级与退避阶梯 + 两层 Profile 的完整字段面 |
| `systems/services/future-event-service.md` | **partial** | **本次由 blocked 升级（本轮最大的一处，`ADR-0026` 的直接受益方）**。就绪切片 = **eventOptions 十步管线整条**（类型修正乘性 · 多 arc 权重相乘 / 白名单取并 · 三层框定叠加顺序 · `BatchSizeWeights` 掷批次规模且收缩保底走 Travel · `SelectionWeightGrade` 三档 · 满级 Finale 闸门式旁路）+ 候选短缺三道闸（加载期断言 / 取池期拦截 / 物化期降级，不做单项补位）+ `EventOutcomeSpec` 字段面（两侧复用 `ProfileChangeSpec` 三列 + 置换 / 禁用候选前移到物化时掷定落 `EventOption.AbilityChangeSlots`）+ `Priority = 1` 抬升判据与三条与门子判据。其余卡于：`BaseTypeWeights` / `BatchSizeWeights` 每格取值（ch1 专场）· 两项待复核（`GrantFromPool` 不加加载期池断言 · 三条抬升子判据的密度成本） |
| `systems/services/plot-manager.md` | **partial** | **本次由 blocked 升级**（合并算法的阻塞源「框定叠加顺序」已随 `ADR-0026` 倒下）。就绪切片 = `PlotArcData` + `PlotNodeData` 数据形态（正文内嵌 · key points 每 arc 一条含 `Queued` 态 · 排队 arc 落存档）+ `PlotModulation` 六字段与加载期悬空校验 + **多条 `Active` arc 的合并算法**（权重相乘 / 白名单取并）+ `EncounterTighten` 五格增量的方向约束与 `Finale` 整档豁免 + 档位表 / 阈值 / 回滞 / 跨档叙事的结构面。其余卡于：DnD 式选分支的触发点与 UI · 隐藏属性的逐条推拉映射 · `HiddenStatGrade` 三个映射值与 `EncounterTighten` 六个界常量（均 ch1，文档自陈只约束标定不约束结构）· 剧本树不分包的三项配套待复核 |
| `systems/services/life-cycle-service.md` | **partial** | **本次由 blocked 升级**（非战斗四类的决策点清单、战斗内运行态计数器、RNG 写入通道、带边界配置落点四条于 08-22 逐条答结）。就绪切片 = 轮回骨架 —— 两层持有模型 + 角色状态分类法（`ongoing` / `defeated` / `completed`，`discarded` 为子类型）+ 寿元扣减与归 0 终态 + `DefeatReason` 四值与 Finale 失败的**显式旁路**（`ADR-0025`）+ 「账号级残卷累加先于角色终结提交」这条顺序不变式 + 事件收口的存档点 / 决策点清单（R1/R2/X1/X2/X3 + 两条「无」）+ RNG 子流与 `Project(spec)` 只读投影。其余卡于：`experiencePoint` 阈值曲线与产出分布 · 重试上限可变后的存档表达 · 隐藏属性的增减触发 · 元进程各字段的解锁 / 获取触发 · 两项待复核（Exchange 面板打开不设 X0 标记 · 「非战斗决策点不触发第二次写入」口径及其连带改写的全称表述） |
| `systems/services/profile-service.md` | **partial** | 就绪切片 = `ProfileChangeSpec` 的**全部十列**与逐列失败语义 + `CostKey` 15 成员 / `StatKey` 首批 2 项（08-22 已确认不为「购买次数」增设成员）+ 两族三条书写分野与成员名冻结 + `ResourceElements` 配表六列 + `TryApply` 的整批原子性与钳制 + `ActiveCombat` / `RngElements` / `TraceElements` 三处通道 + `CodexElements` 的四行失败语义与 `#if DEBUG` 护栏 + 「收口是一次事务、事件内主动消费即时提交」的两条判据。其余卡于：capability flag 枚举与叠加 / 冲突规则（承重）· `status` × 拥有 / 失去的存档表达 · 成就采集面（EventBus 被动 vs 主动上报）· 成就两档奖励内容 · `PlayerPower` 平衡边界 |
| `systems/services/account-service.md` | **partial** | **切片本次扩大**（refresh token 持有形态于 08-22 落定：明文 `user://cache/refresh-token.json` 带版本 · `AuthManager` 私有 · 不与 `device-id.json` 合并 · 启动期静默续期使 `Account.Init` 上提到登录屏之前）= 会话生命周期 + 四个账号方法 + refresh 失败拆两条路径（网络失败 → 缓冲通道 / `auth.session_revoked` → 硬阻塞重登 + 暂停退避）+ `AccountInfo` 五字段 + `deviceId` 落点 + 被挤下线后「先 pull 后 flush」。其余卡于：**合规呈现面须整体排除**（跨边界未闭合，对侧 `contracts/compliance.md` 六端点报文字段表与合规域错误码均未落笔）· `ComplianceManager` 覆盖面切分（唯一在办的跨边界承接项）· 多设备并发登录的云端裁决（归后端）· 两项待复核（不存 `refreshExpiresAtUtc` · 明文落盘 + 平台密钥库后置评估） |
| `systems/services/content-service.md` | **partial** | 就绪切片 = 启动期 manifest 比对 + blob 内容寻址 + ES256 签名校验 + 文件级事务 + overlay 合并 + 合并后全量校验 + `AllEnabled()` 取池 + 断网降级到随包基线 + 语言覆盖率审计（空单元格即未翻译 · `fallback = "zh"`）+ overlay 剧本例外的 `newIds` 双闸 + 可执行化阶梯四处应用 + 单例内容的注册与加载期条数校验（结构面）。其余卡于：**flags 的「增大即拉」整条须排除**（跨边界未闭合——对侧 `contracts/content-manifest.md` 明写「flags 回滚须以更高 `flagsVersion` 发布」尚未成文，依赖它即开出「设备永久停拉 flags」的口子）· disabled 条目被存档引用时的 UX · 五项待复核（单例注册形态四项 + 退避 cap = 60 s） |
| `systems/adventure-event/common-properties.md` | **partial** | **切片本次显著扩大**（上游生成 / 加权已随 `ADR-0026` 落定）= `EventOption` 13 格物化字段（含 `OutcomeSpec` / `Encounter` / `ExchangeStock` / `RerolledCount` / `DestinationLocationId` / `RevealedEventId`）+ `OutcomeRule` 与 `HiddenStatGrants` 三格 + 「产出即定稿、不得回查模板重算」+ 事件收口的事务语义（一次事务、一个存档点；事件内主动消费即时提交，附两条可判定判据）+ `PastEventEntry` 与 `AppliedChange` = 「本次事件的最终账」+ 成本侧 `LifeSpan` 取值域非负 + 九条加载期校验。其余卡于：`lifeSpanCost` 定价表逐格与五类配比取值（ch1 专场）· 四项待复核（校验 9 拒绝 `Stat == LifeSpan` · `HiddenStatGrant.Stat` 宽类型 · `OutcomeRule` 不支持多选一 · `lifeSpanCost` 一律定值） |
| `systems/adventure-event/explore/_index.md` · `explore/common-properties.md` | **partial** | **本次由 blocked 升级**（`common-properties.md` 的待决问题明写「无」，专有字段清单闭合）。就绪切片 = 揭示机制整套 —— 真身分布 = 条目池组成 × 既有加权抽取、三处数据类一律不加字段 · 取池期「真身须同样 enabled」过滤（堵住「放量开关对 Explore 静默失效」）· 揭示 = `eventStart` 内一次 `with` 派生且 **resolver 按真身选取**（不按 `EventOption.EventType`）· 遮罩卡与其余选项完全同构 · 全屏覆盖层转场、不进屏幕栈、不给任何部分线索 · `IsRevealed` 只存在于物化侧。其余卡于：真身占比 `5:3:2` 与定价表 Explore 行取值（ch1）· 转场时长 ≈1.2s 的真机实测 |
| `systems/adventure-event/travel/_index.md` · `travel/common-properties.md` | **partial** | **本次由 blocked 升级**（🔴 类型概率修正的运算形态与槽位数 `k` 的来源双双随 `ADR-0026` 落定——`k` 由 `BatchSizeWeights` 掷定、收缩保底走 Travel）。就绪切片 = `LocationData` + 单份 `LocationMapData` 载体与恒启用 · 80/20 全局常量不可调制 · 目的地取自邻接集合、`DestinationLocationId` 物化时掷定且不得事后算 · 闸门形态（最高 `Priority = 1`、无 `IsMandatory` 字段）· 结算写入判据为 `DestinationLocationId != ""` 而非 `EventType == Travel` · 痕迹侧记出发地 · 两条 `StatusAssignment` 由 life-cycle-service 组装 · 不计入 `eventCountLimit` 与回寿禁令。其余卡于：Travel 行定价（ch1，结构约束已定为 > 0 且为常规基准的 1/3 ~ 1/2）· 失去 flags 关地域后的运营替代通道 |
| `systems/adventure-event/research/_index.md` · `research/common-properties.md` | **partial** | **本次由 blocked 升级**（上游生成链路已定）。就绪切片 = 构筑面板 = 复数决策槽（`ADR-0022`）· 六类操作闭合 · 产出面 = 卡组 + `manaLimit` + `lifeTotal` · 候选物化时掷定走 `RngStream.Reward` · `AllowDecline` 默认 `true` · 不另收资源代价 · 三道短缺闸 · `ProfileChangeSpec.DeckElements` 承载。其余卡于：`Recuperate` 回复量 / 走火入魔风险档权重 / 开局构筑 `lifeSpanCost = 0` 覆盖登记三个数值格与**功法层数上限**（均 ch1，且层数上限决定 `ResearchCandidate.Amount` 的取值域）· 风险档的竖屏视觉标注与非 hover-only 说明通道未设计 |
| `systems/adventure-event/exchange/_index.md` · `exchange/common-properties.md` | **partial** | **本次由 blocked 升级**，但**切片偏薄、须显式排除道具族的购买路径**。就绪切片 = 仍走 `GenericEventResolver`（不开第三个 resolver）· 交易逐笔即时提交 · 库存物化时经 `RngStream.Shop` 掷定并落存档 · 五个商品族映射到既有仓储、不新建抽取池 · 「商品族 × 稀有度」统一定价表的**结构**与两条折扣通道 · `ModifierKey.ShopPrice` 在物化侧单点施加（`Jade` 两个修正列恒 `null`）· 售出仅 `CharacterItem` 一族且为代码级常量判据（`Source.ExchangeSell`，唯一只出现在 `Op == Remove` 上的成员）· 刷新机制与三道短缺闸。其余卡于：**满袋时能否购买道具**（阻于 `item/_index.md` 的储物袋满袋处理这条承重未决 ⇒ 道具族的购买前置校验写不出）· 四组数值格全欠（ch1，且绝对数字被 jade 获取渠道阻塞） |
| `systems/game-progression.md` | **partial** | **本次由 blocked 升级**（eventOptions 生成 / 加权、三层框定叠加顺序、`eventCountLimit` 可否被剧本推拉三条于 08-22 全部答结）。就绪切片 = 篇章 / 境界推进与检查点重试模型（`ADR-0004`）· 存档点即结束点、途中死亡从章首重试 · `eventCountLimit` 的地域配额语义与「不可被剧本调制、`PlotModulation` 不加第七字段」· 事件循环与 Finale 胜负即篇章闸门（`ADR-0025` 推翻旧结论）。其余卡于：中长期**进度感**那一半（图鉴只给方位感）· 选择区的排布与滑动手感（批次规模 1–5，两端差 5 倍）· 五类配比取值（ch1）· **blind / ante 整体尚未陈述** · 一项待复核（「不可调制」只约束剧本层、overlay 照常可改） |
| `systems/character-profile/_index.md` | **partial** | 就绪切片 = `CharacterProfile` 完整存档 schema（23 字段逐格标注类型 / 写入通道 / 权威 + `Status` 具名子类 12 格 + `currentMana` 不入 `Status` 的判据 + 集合型 build 状态与 `Status` 平级 + `activeEvent` / `eventOption` 两块与 7 条读档校验）+ 角色 = 有身份模板（`CharacterData`，自带一个 `CharacterPower` + 两门绑定功法，绑定可弃置）。其余卡于：**角色模板池的形态**（承重——池规模 / 是否账号级解锁 / 能否重抽或指定，改写元进程压力模型）· 隐藏属性是否有第四项 |
| `systems/player-profile/_index.md` | **partial** | 就绪切片 = 15 字段表整张（写入通道列无空洞）+ 规则层 / 统计层分层判据 + 三样不进 Profile 的排除项 + 三个具名子类（`PlayerStatistics` / `PlayerPowerFragment` / `PlayerEntitlement`，后者含 `BundleRedeemedOrdinal`）+ 受 `ADR-0028` 回声校验约束的顶层键（客户端半）。其余卡于：`Achievement` 条目 schema 与进度模型 · 各账号级条目的解锁 / 获取 / 失去触发 · `PlayerPower` 平衡边界 |
| `systems/player-profile/game-setting.md` | **partial** | 就绪切片 = 切分判据（「取值是否取决于这台机器」+ 换机自检反问 + 拿不准归设备本地 + 一项只落一侧）+ 账号级四项（三条音量轨 `int [0,100]` + `FastCombatAnimation` `bool`）+ 设备本地一项（`locale`）+ `SettingChanges` 通道与 `SettingFields` 配表（`int?` / `bool?` 的失败语义）+ `PushPolicy`。唯一残留：三条音量轨默认值 100 / 80 / 100 是**待实测初值**（相对关系有依据）——不阻塞结构，derive 时按初值写入并标注可调 |
| `systems/monetization.md` | **partial** | 就绪切片 = 付费凭证 `PlayerEntitlement` 两字段与不变式 `0 ≤ Redeemed ≤ Grant`（`ADR-0023`）+ 空池三道闸 + 购买入口三条前置条件与灰态 + 兑现事务（`AccountRng.For(PremiumBundle, ordinal)` 一次派生连抽 3 条 → 一次 `TryApply` → `Immediate` push，`ordinal = Redeemed + 1` 逐一追平）+ 五项排除。其余卡于：**平台内购 SDK 的选型与封装层未定 ⇒ 购买段无法落地**（三渠道虽已纳入 MVP，`ADR-0024`）· `K` 与 `GrantPoolMargin` 数值待内容规模 · 两个通用池当前条目为零 · 纯外观付费点未定案 |
| `ux/error-and-blocking-ux.md` | **partial** | 就绪切片 = 翻译键基建（`res://text/` 分区表十项 + 键命名三条 + `ERR_*` 由 `code` 机械变换 + `reasonKey` 三参 `ErrorText.For` 与静默回落 + 三条启动期审计与定死的调用顺序 + `TranslationAudit.AuditCoverage()` 独立入口 + locale 启动期归一 + `fallback = "zh"` 使回落零分支）+ 灰态判据 + `BlockingNoticeScreen` 一屏三变体 + 三档版本提示去重 + 诊断编号出口。其余卡于：逐条中文措辞（`ERR_*` / 四条兜底 / `reasonKey` 二级，均属内容充实，不阻塞结构）· `auto_translate_mode` 与 `#if DEBUG` 判据的实测（文档自陈不阻塞任何已定案内容，宜合并到 `.csproj` 生成后的一次实测） |
| `ux/screen-flow.md` | **partial** | 就绪切片 = 登录屏 + 主菜单五入口导航骨架与 Store 三条呈现纪律 + 建议更新横幅去重 + 储物袋全屏面板形态（9 格一屏可见）+ 玩家档案屏的绑定 / 解绑列表与两处二次确认 + Settings 屏形态 + 各入口读取的两层 Profile 字段逐格可指。其余卡于：元婴证书形态 · 成就两档奖励内容 · 寿元告警是否伴音效 / 震动 · Explore 揭示转场时长与音效实测 · `PlayerPower` 获取 / 失去触发与平衡边界 · 图鉴入口与浏览形态 |
| `vision/pillars.md` · `vision/scope.md` · `vision/references.md` | blocked | 北极星 / 参考登记，**非 derive 对象**（作为其余文档的挂靠前置；三份均无 `## 待决问题` 小节。`scope.md` 的美术资源策略与 AI 生成合规立场仍未定） |
| `terminology.md` · `program-overview.md` · `system-overview.md` | blocked | 根级横切参照面（术语表 / 运行时调用链 / Godot 工程落地形态），**非 derive 对象**——它们的行为面全部由 `systems/**` 的对应文档承载，单独 derive 必与之重复 |
| `decisions/ADR-0002` ~ `ADR-0028`（27 份 Accepted） | blocked | 已采纳的决策记录，**非 derive 对象**（作为其余文档的就绪前置，本身不产 FR）。本次新增四份：`ADR-0025` Finale 失败即角色终结 · `ADR-0026` eventOptions 十步管线 · `ADR-0027` `LocationCodex` 顶点级显影 · `ADR-0028` 上行整键回声校验通则 |
| `decisions/ADR-0001-example.md` | blocked | 示例占位，`## Decision` 明写「待定」；status 仍为 Proposed |
| `decisions/_index.md` | blocked | 台账，非 derive 对象 |
| `systems/_index.md` · `systems/services/_index.md` · `ux/_index.md` · `content/_index.md` | blocked | 导航索引 / 登记表，非 derive 对象（各自的待决项已下沉到对应主题文档；`content/_index.md` 另持内容类型的 **scaffold** 就绪度，与本小节的 derive 就绪度是两套闸，勿混） |
| `systems/balance.md` | blocked | 🔴 **ch1 数值标杆专场未开——本库唯一的大规模卡点，待决问题由 11 条增至 12 条**：`lifeSpanCost` 定价表逐格（承重）· 商店定价与 Exchange 三组数值格 · 道念两组剩余数值 · `RarityTier` 剩余权重表与三格取池余量 · 重试上限两档 · 回寿量三档 · 闭关三格 · Explore 真身占比 · `EncounterTighten` 六个界常量 · **卡牌费用曲线是否随境界上移（承重 · 本次新增，是「`manaLimit` 每次大境界 +1」唯一的翻盘前提）** · `EnemyManaLimit` 初值 5 校准 · blind / ante 曲线。**其中商店定价被 jade 获取渠道阻塞**；另有四项待复核（赋级资源三项 + 退避 cap）挂在本文件 |
| `systems/scoring.md` | blocked | 规则面已定（道念产削 / 下限 0 / 胜负两条支路 + 单价表 / 负侧 1:1 / `WinMargin` 在 `Finale` 退场），但三档 `BaseReward` / `RewardPoolId` 取值与卡牌量纲基准均归 ch1 专场；且它必须依附一场可运行的战斗，而 `combat-service` 的战斗内容整体为空 |
| `systems/adventure-event/_index.md` | blocked | 五类之间的配比与 Combat 内 `combatTier` 三档配比**只欠取值**（运算形态已随 `ADR-0026` 落定，归 ch1）；且其行为面（resolver 分派轴 / 物化链路）已被 `future-event-service` 与 `adventure-event/common-properties.md` 的切片覆盖 ⇒ **本文件不另产 FR，避免与上述两份撞车** |
| `systems/adventure-event/combat/_index.md` · `combat/common-properties.md` | blocked | 待决 8 条：量纲基准与三档奖励厚薄归 ch1 专场 · 敌人 AI 规划形态未定 · 隐藏属性与战斗资源的其余耦合面未定 · 敌人 schema 其余字段未定 · 三档各推哪一档 `HiddenStatGrade` 的逐条目编排未定 · 叙事一致性编写口径属内容阶段。战斗内容整体为空 ⇒ 无可独立成立的切片 |
| `systems/enemies/_index.md` · `enemies/common-properties.md` | blocked | `EnemyData` 其余字段未定（立绘 / 台词 / 音效引用、产出缩放参数、行为脚本表达）· AI 决策算法与粒度未定 · 敌人是否也以功法构筑卡组未定 · 道念产出缩放归 ch1 专场。（**篇章框定载体已答结**：`EnemyData.ChapterScope : int[]`，空 = 三章通用，空池校验扩到 `combatTier × 篇章`；样本卡组规模两侧皆不设硬限）；另有四项待复核挂在本文件 |
| `systems/character-profile/currency.md` | blocked | jade 的获取渠道 / 掉落权重整体未设计（承重）——**它同时卡住商店定价表的全部绝对数字**，是 ch1 专场里唯一一条「不先答就没法开工」的前置 |
| `systems/character-profile/deck/_index.md` · `deck/common-properties.md` | blocked | 效果三层 + `KeywordData` + target / scope 分离 + `EntryFilter` + `CardType` 五分 + `Subtypes` + `Pool` + 出牌费用 = mana + counters 键空间已收口；仍卡于：`CardData` 的**费用与触发器两格仍是结构占位** · 效果流水线阶段划分未定 · starter deck 未设计 · 功法规模参数与量纲基准归 ch1 专场 · 关键字与次类型首批清单为空 · 抽 / 弃 / 洗三组数值待定 |
| `systems/character-profile/item/_index.md` · `item/common-properties.md` | blocked | **两条承重未决**：战斗外道具的使用入口未设计（阻塞回寿法宝定稿，连带「是否单独构成存档点」与「事件外使用时无 `PastEventEntry` 可挂」两问）· 储物袋满 9 格的处理未定（**它同时是 Exchange 道具族购买路径的阻塞源**）。另：道具种类目录与「什么该做成卡 / 道具 / 神通」的判据未给 · `common-properties.md` 的共有字段全为占位 |
| `systems/character-profile/life-total.md` | blocked | 规则面已定（境界基线 10 / 25 / 40、归 0 = 角色终结），回复幅度与来源分布归 ch1 专场；且不构成可独立成立的 FR 面，应随战斗资源一并落地 |
| `systems/character-profile/mana.md` | blocked | **本文件自身的 `## 待决问题` 已清空**（08-22 定案：`manaLimit` 每次大境界 `+1`，增量语义走既有 `CostKey.ManaLimit`，显式推翻 `log-0730b.md` 第 4 条）；但 ① 该结论的**唯一翻盘前提**「卡牌费用曲线是否随境界上移」仍是 `balance.md` 的承重未决 ② 它不构成可独立成立的 FR 面（须依附一场可运行的战斗）⇒ 依赖未闭合 |
| `systems/character-profile/power/_index.md` · `power/common-properties.md` | blocked | 战斗外那一半的复用边界未定（承重——capability flag / modifier pipeline 注册面是否两层共用、持有列表与清理规则落点）· 获取 / 失去触发未定 · 与卡牌 / 法宝的边界判据未给 · `status` 开关的存档表达未定 · `common-properties.md` 明写「待定的字段清单」 |
| `systems/player-profile/account-info.md` | blocked | 字段面五项已定，仅剩合规字段归属一条待后端分级 ⇒ 表仍可能增行；**且它单独不构成可独立成立的 FR 面**，应随 `account-service` / 登录切片一并落地 |
| `systems/player-profile/achievement/_index.md` · `achievement/common-properties.md` | blocked | 成就条目 schema 与进度模型未设计（分组结构、权重来源、触发条件表达、隐藏成就揭示时机）· 触发采集面（EventBus 被动 vs 主动上报）未定 · 两档具体奖励条目清单未定 |
| `systems/player-profile/codex/_index.md` | blocked | 六本的入口与浏览形态未定（含战斗内能否查阅）· `LocationCodex` 除连边外的词条深度未定 · 边缘顶点显示程度与显影半径两项待复核 ⇒ **呈现面整体无可 derive 的切片**；存档 / 写入面已下沉到同目录的 `common-properties.md`（见上方 ready 行） |
| `systems/player-profile/codex/enemy-codex.md` | blocked | 五项词条规格本身已定且**已无 `## 待决问题` 小节**（慷慨度与退让阶梯已升格为决策），但词条的数据源逐项落在 `EnemyData` 上，而 `EnemyData` 字段清单未定 ⇒ **依赖未闭合**，写不出可验证的验收标准 |
| `systems/player-profile/player-item/_index.md` · `player-item/common-properties.md` | blocked | 道具种类目录、次数补充机制、价格 / 库存权重、战斗外效果形态均未设计 · `common-properties.md` 的共有字段全为占位 |
| `systems/player-profile/player-power/_index.md` · `player-power/common-properties.md` | blocked | `RelicData` 字段清单与触发器体系未设计 · capability flag 枚举 / 命名空间 / 聚合面宿主服务 / 叠加与冲突规则未定 · 战后奖励池按优势档三张权重表未定 · 平衡边界未定 · 「失去法则」三支的频次预算需重新配平（归 ch1 内容编排） |
| `systems/services/combat-service.md` | blocked | **战斗内容整体为空**（卡牌定义 / 起始卡组 / 敌人目录 / 遭遇编排 / 回合内效果与状态系统骨架）· 敌人 AI 决策形态未定 · Finale 奖励加厚幅度归 ch1 专场。（counters 读写 API 与战斗内运行态计数器已于 08-22 答结；另有四项 counters 待复核挂在本文件） |
| `ux/combat-ux.md` | blocked | 待决 11 条，含三处承重：竖屏分区整体是否过载（**已排期专门 session**）· 结算 ticker 文案体系（唯一动态情报通道）· 栈与战场同屏呈现。另有出牌手势 / 手牌布局 / 疲劳呈现 / 三步结构呈现 / 战后奖励面板 / 节奏与动画时长整体未设计 |
| `art/_index.md` · `art/visuals/_index.md` · `art/soundtracks/_index.md` | blocked | 流水线说明与资产类目表；本库不承载生成产物（归 `game-feature-branch/`），无客户端行为面可 derive。`visuals/_index.md` 另有 4 条未决；`soundtracks/_index.md` 的生成工具仍「倾向 Suno、未拍板」 |
| `art/visuals/art-direction.md` · `art/soundtracks/audio-direction.md` | blocked | 主体各节仍为 `> _（待写）_` 占位（各 6 处）——**尚无设计意图** |
| `art/visuals/animations/_index.md` | blocked | 明写占位：范围 / 技术载体 / 制作方式 / 与战斗节奏的关系待咨询专业人士后确定，**尚无设计意图** |
| `art/visuals/references/_index.md` · `art/soundtracks/references/_index.md` | blocked | 参考登记表基本为空（视觉侧 3 行、音频侧全空，另 4 处 `_（待写）_`），且二进制是否入库未定 |
| `art/visuals/guides/_index.md` · `art/soundtracks/guides/_index.md` | blocked | guide 台账为空，**尚无任何 guide** |
| `art/visuals/guides/_TEMPLATE.md` · `art/soundtracks/guides/_TEMPLATE.md` · `content/_TEMPLATE-*.md` · `requirements/_TEMPLATE*.md` | blocked | 模板骨架，非 derive 对象 |

### 建议的 derive 顺序（仅限 ready / partial 项；被依赖者在前）

1. `/derive-requirements systems/common-properties.md` —— **唯一整份就绪且被几乎所有内容与服务代码依赖的地基文档**。共有字段类型与两级 RNG 先落，后面每一份 FR 都能直接引用而不必各自重新约定。账号级 RNG 的验收有现成的 8 组测试向量，是全库当前最硬的验收标准。文档自己也写明排期——`LocalizedText` 与 `DrawPool<T>` 同批、**在写下第一批 `.tres` 之前**。
2. `/derive-requirements ux/error-and-blocking-ux.md` —— 翻译键基建（文档自己已点名 `FR-ux-translation-foundation`）。**无上游依赖**，是「每屏从第一行起就用键」这条起手纪律的前置，越早越省返工。**排除逐条中文措辞。**
3. `/derive-requirements systems/architecture.md` + `systems/viewmodel.md` —— 服务骨架：七个 autoload 的注册顺序、EventBus、边界服务的接口 + Offline stub 双实现、`ProfileChangeSpec` 的完整十列。**两份同批处理**：三层切分的定义在前者、展开在后者，分两次必出两份互相打架的 FR。**排除 `HiddenStatGrant` 三格的枚举形态与收窄方式（两项待复核）。**
4. `/derive-requirements systems/services/profile-service.md` —— 写入通道这一层地基（十列 spec + `CostKey` 15 成员 / `StatKey` 2 项 + `ResourceElements` 配表 + `TryApply` 原子性与钳制 + 逐列失败语义）。它必须先于任何写 Profile 的系统。**排除 capability flag 的叠加 / 冲突规则与成就采集面。**
5. `/derive-requirements systems/character-profile/_index.md` + `systems/player-profile/_index.md` + `systems/player-profile/codex/common-properties.md` + `systems/player-profile/game-setting.md` —— 两层 Profile 的存档 schema 地基（数据类 + 序列化 + `schemaVersion` 与迁移）。**四份同批处理**：它们互相引用、共用同一个 `schemaVersion` 与同一条迁移路径，分批 derive 必出互相打架的 FR。**只取存档 / 写入面，不取任何图鉴屏或设置屏的呈现。**
6. `/derive-requirements systems/services/content-service.md` —— 内容加载与校验链路（依赖 1、3）。它被一切内容读取方依赖，应先于任何玩法系统。**排除 flags「增大即拉」整条**（对侧回滚条款未成文）。
7. `/derive-requirements systems/services/sync-service.md` —— 本地缓存原子写 + push 调度与退避 + CAS / 幂等 + 两层 Profile diff 的完整字段面（依赖 1、3、4、5）。**排除回声校验的逐条受约束 path 与非整数比较口径**（成对采纳未完成）。
8. `/derive-requirements ux/screen-flow.md` + `ux/onboarding.md` —— 登录屏 + 主菜单导航骨架（依赖 2、3、5）。**两份同批处理**：登录屏切片在两份文档中重叠。
9. `/derive-requirements systems/services/account-service.md` —— 会话生命周期 + 四个账号方法 + refresh 两条路径 + `deviceId` 与 refresh token 落点 + 启动期静默续期（依赖 2、3、8）。**合规呈现面整体排除**（对侧报文字段表未落笔）。
10. `/derive-requirements systems/adventure-event/common-properties.md` —— `EventOption` 的数据形态与事件收口的事务语义（依赖 1、5）。**它是后续全部事件类型 FR 的共同类型地基**，必须先于第 11 项。**不取定价表与配比取值。**
11. `/derive-requirements systems/services/future-event-service.md` + `systems/services/plot-manager.md` —— **本轮新解锁的最大一块**：eventOptions 十步管线 + 三道短缺闸 + `Priority` 抬升判据，以及它的调制输入（`PlotModulation` 六字段与多 arc 合并算法）。**两份必须同批**：管线的第二、三层框定读的就是 plot-manager 的输出，分两次 derive 会各写一份互不相认的叠加顺序。**排除全部权重取值（ch1）与两侧的待复核项。**
12. `/derive-requirements systems/services/life-cycle-service.md` —— 轮回骨架、角色状态分类法、`DefeatReason` 四值与 Finale 旁路、事件收口的存档点与决策点清单（依赖 4、10、11）。**排除 `experiencePoint` 曲线与重试上限的存档表达。**
13. `/derive-requirements systems/game-progression.md` —— 篇章 / 境界推进与 `eventCountLimit` 配额（依赖 11、12）。**排除选择区呈现、进度感与 blind / ante。**
14. 四个非战斗事件子类型，按依赖薄厚依次：`travel/` → `explore/` → `research/` → `exchange/`（依赖 10、11、12）。**四份各自的机制面已闭合，全部排除数值取值**；`exchange/` 另须**排除道具族的购买前置校验**（阻于储物袋满袋处理）。
15. `/derive-requirements systems/monetization.md` —— 兑现段 + 三道闸 + 入口前置条件 + 兑现水位幂等（依赖 1 的账号级 RNG、7 的 push 调度）。**排在最后**：它依赖的两个通用内容池当前为空；**只取兑现与拦截，购买段等平台 SDK 选型。**

> **仍然不要**对战斗 / 卡组 / 敌人 / 道具 / 法则 / 平衡 / 元进程失败侧 / 图鉴呈现侧任何文档 derive。玩法侧剩下的欠账收敛为**三处**，按解锁面从大到小：**① ch1 数值标杆专场**（唯一的大规模卡点，只欠取值不欠结构，其前置是 `currency.md` 的 jade 获取渠道）· **② 战斗内容与敌人 AI 专场**（`combat-service` / `enemies` / `deck` / `scoring` / `combat-ux` 五份的共同上游，且它是 ch1 专场的切入点——starter deck）· **③ 一次 20 项 `[采纳推荐 — 待复核]` 的复核会**（零新增设计，却能收窄六份文档的排除面并把 `architecture.md` 送回 ready）。**③ 的成本最低、可立刻做。**

## 下一阶段

- **ADR 状态：** `decisions/` 现有 **27 份 Accepted**（`ADR-0002` ~ `ADR-0028`，`ADR-0001` 为 Proposed 示例占位）。
  台账与逐条影响文档见 `decisions/_index.md`。**当前待固化的 ADR 候选 2 条**（均因主项仍标 `[采纳推荐 — 待复核]` 而暂缓建档，待用户正式复核后再固化）：
  - **剧本树不按篇章分包**（`handoffs/2026-08-22-plot-tree-chapter-packaging.md`）—— 三项取向全为待复核，含「本条关闭为定案」这一项本身。
  - **单例平衡资源经 ContentRegistry + `ISingletonContent` / `Single<T>()`**（`handoffs/2026-08-22-singleton-balance-resource-registry.md`）—— 「不设兜底大表」已正式拍板，但承载机制（两段式 `Id` · 标记接口 · 早于 `LoadAll()` 的旋钮写死为常量）四项待复核。
  （注：ADR 现可自由编辑，改决定直接改 ADR，不再新开取代 ADR。）
- **流水线闭环（07-30）：** design → code 链路补上 `/breakdown-requirements`（一份 FR → 一个文件夹的可执行子需求），完整形态见 `README.md` 与 `requirements/_index.md`。
- **架构闭环缺口：** 8 处**全部闭合**（移出记录见 `answer-logs/log-0725c.md` 与 `log-0726b.md`）；状态表见 `systems/architecture.md` 的「闭环缺口」小节。残留细节已下沉为各焦点分片的普通待决问题。

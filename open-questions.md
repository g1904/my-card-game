# Open questions — 跨 session 待答清单（索引）

> 本文件是**客户端**（Godot 项目）待答清单的**索引**：问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 后端侧的待答清单在 `backend-design-documents/open-questions.md`（`backend-design` 分支）。
>
> 每次 session 结束时，未答的 Open questions 汇总到对应分片，供下次拾起；一旦答定，就从分片中移除、
> 归档进对应主题文档的 `## 待决问题` / `## 决策`，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> 本清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**。
>
> 最近更新：2026-08-17 — 五份已评审草稿批量提炼（移出 11 条 · 跨库）
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
| `open-questions/06-meta-progression.md` | **⑥ 元进程的失败侧与中长期规划感**：轮回内的进度感是否需要补充、1% 存活分支的叙事补白落点。 |
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

**最近全量评估：2026-08-18（由 `/assess-derive-readiness` 产出）。** 扫描范围：`vision/` · `systems/**` · `art/**` · `ux/` · `decisions/`，共 **79 份**。本次重估的触发是 08-16i 与 08-17 ~ 08-17k 共十二次落笔（剧本数据编码 · Travel 目的地与 `StatusChanges` · Research 构筑面板与 `DeckElements` · Explore 揭示 · Exchange 交易与事务纪律 · Finale 与隐藏属性双向 · 回寿通道 · element 载体缺口 · **两层 Profile 字段 schema** · `EventOption` 物化字段 · 派生实例落存档 · 抽取原语与实例形态）——**上一次评估的两处承重卡点之一已倒下**。

**全局结论：ready 2 份 · partial 10 份 · blocked 67 份 —— 可 derive 的面由 8 份增至 12 份，且第一次覆盖了存档 schema 这一层地基；本库整体仍未进入玩法侧的可 derive 阶段。** 上次评估立着的两处承重卡点，现在只剩一处：

- **✅ 已倒下 —— Profile 字段 schema。** 08-17h 把 `CharacterProfile`（23 字段 + `Status` 12 格子表，每格标注写入通道与权威）与 `PlayerProfile`（15 字段，含分层标注与三样不进 Profile 的排除项）逐格落定。它连带解锁了 `sync-service` 的上行负载面、`ux/onboarding.md` 的篇章门禁、`ux/screen-flow.md` 的五个入口数据源，并使两份 `_index.md` 自身第一次具备可 derive 的存档地基切片。
- **🔴 仍然立着 —— ch1 数值标杆专场。** 量纲基准 / `lifeSpanCost` 定价表逐格 / 三档奖励厚薄 / 回复幅度 / 商店四组数值格 / `HiddenStatGrade` 三个映射值 / Explore 真身占比 / 功法层数上限 —— **本库现存的唯一一处大规模卡点**，且它已从「一处未决」长成一份长清单（`systems/balance.md` 的待决问题已积到 11 条，几乎每条都标着「归 ch1 数值标杆专场」）。
- **🟠 半处 —— `CostKey` 资源族 element 清单**（能力族 `AbilityChangeElement` 与统计族 `StatDelta` 已闭合），它卡住 `profile-service` / `architecture` 的 `TryApply` 形状面。
- **🟠 新长出的一处 —— 「有纪律、无通道」三连**：`activeCombat` 的写入通道未明写（承重）· RNG 子流 `State` / `DrawCount` 无 spec 列 · `pastEvent` 追加无 spec 列。三者形状相同（不变式已落、机械保证暂缺），08-17k 只补上了 `activeEvent` 那一处。

**跨边界侧维持全闭合**：后端六份契约悉数成文，客户端无一文档卡于「契约缺失」；承接项由三条降至 **1 条**（`ComplianceManager` 客户端覆盖面的切分，是本库自己的取向），见 `open-questions/cross-boundary.md`。

| 文档 | 判定 | 卡点 / 就绪切片 |
|------|------|------------------|
| `systems/common-properties.md` | **ready** | 待决问题为空、无 `⟨待定⟩` 占位、依赖全部闭合。可 derive 的整面 = 稳定 `Id` 与展示字段三层切分 · 物化模型 · **`LocalizedText`**（封闭二值 locale · `Get()` 纯读 · 不落存档）· **`ContentEnabled` + `AllEnabled()` / `AllIncludingDisabled()` 双名与编译闸** · **`RarityTier` 五档** · **`SourceCode` + `Source` 八值 + 兜底**（存档走 code、上行走成员名、名与 code 双双冻结）· **`ExclusiveSource`** · **两级 seeded RNG**（轮回级 Godot 四子流 + `State`/`DrawCount` 持久化；账号级 SplitMix64 三参数派生，8 组测试向量已在 `backend-design-documents/contracts/profile-sync.md` §6/§6a 填好，验收可逐位对表）· API 契约总则的三形态 / 三失败语义 |
| `ux/onboarding.md` | **ready** | **本次由 partial 升级**：`## 待解问题` 明写「当前无未决项」，且上次的唯一卡点——篇章门禁与「有可挑战角色」所读的 schema——已随 08-17h 闭合（`CharacterProfile.status` / `chapter` / `realm` + `PlayerProfile.characterProfile` 逐格落定）。可 derive 的整面 = 强制登录无游客 + 首版只呈现已实现渠道 + **手机两步握手 UI**（验证码框 + 倒计时始终可见的重发按钮 + 过期重取，无 hover 提示）+ 绑定 / 解绑不落登录屏 + 首玩篇章门禁与「解锁 = 有可挑战角色」的动态语义。**与 `ux/screen-flow.md` 的登录屏切片重叠，须同批 derive、不得出两份 FR。** |
| `systems/character-profile/_index.md` | **partial** | **本次由 blocked 升级（承重卡点倒下的主受益方）**：就绪切片 = **`CharacterProfile` 完整存档 schema**（23 字段逐格标注类型 / 写入通道 / 权威 + `Status` 具名子类 12 格 + `currentMana` 不入 `Status` 的判据 + 集合型 build 状态与 `Status` 平级）+ 角色 = 有身份模板（`CharacterData`、自带一个 `CharacterPower` + 两门绑定功法、绑定可弃置）。其余卡于：**角色模板池的形态**（承重——池规模 / 是否账号级解锁 / 能否重抽或指定，改写元进程压力模型）、隐藏属性是否有第四项 |
| `systems/player-profile/_index.md` | **partial** | **本次由 blocked 升级**：就绪切片 = **`PlayerProfile` 顶层字段表**（15 字段 + 规则层 / 统计层分层判据 + `baseRevision` / `revision` / `schemaVersion` 三样不进 Profile 的排除项 + 六个 Codex 落六个具名字段 + `PlayerStatistics` / `PlayerPowerFragment` / `PlayerEntitlement` 三个具名子类）。其余卡于：`CodexEntry` 的字段 schema 与六处写入通道仍为 `⟨待定⟩` · `GameSetting` 设置项清单与写入通道 `⟨待定⟩` · `Achievement` 条目 schema · `StatKey` 完整成员清单 |
| `systems/services/sync-service.md` | **partial** | **切片本次大幅扩大**（上次的承重卡点「被同步的 Profile 字段 schema 本身未定」已消解）= 存档点 ↔ push 解耦 + 5 秒防抖 + 立即 flush 清单 + `PushPolicy` + 本地缓存原子写 + schema 版本化与迁移/拒绝 + `CharacterProfile` 级 diff + `revision` CAS / `pushId` 幂等 + `Source` 上行走成员名 + 后端主动写入后的 pull 时序 + **两层 Profile 的实际字段面**。其余卡于：`CodexEntry` / `GameSetting` 两个子对象 schema 未定 ⇒ 本地缓存序列化写不出这两块的具体类型；`pushId` 后端记忆窗口（归后端，非本库卡点） |
| `ux/error-and-blocking-ux.md` | **partial** | 就绪切片 = 翻译键基建（`res://text/` 分区表 + 键命名三条 + `ERR_*` 由 `code` 机械变换 + `reasonKey` 二级键的三参 `ErrorText.For` 与静默回落 + 反向审计放宽为前缀匹配 + 两条审计 + locale 启动期归一 + 灰态判据 + `BlockingNoticeScreen` 一屏三变体 + 三档版本提示去重）。其余卡于：**英文占位符形态**（它决定 `AuditTranslations()` 能否识别，否则英文覆盖率恒读作 100%——这是唯一带行为面的一条）、逐条中文措辞（内容充实）、`auto_translate_mode` 实测（文档自陈不阻塞任何已定案内容） |
| `systems/architecture.md` | **partial** | 就绪切片 = 三层切分 + 七服务边界与 autoload 注册顺序 + EventBus 总则 + API 契约总则 + 边界服务「接口 + Http/Offline 双实现」骨架 + `ElementSpec` 六列 / `ModifierKey` / 钳制表结构 + **「一个新的施加语义该落在哪里」三级判据**（08-17k）。其余卡于：`CostKey` 资源族 element 清单（承重）、断线降级的具体行为、热更「只改不增」的连带项、ViewModel 层是否单列文档 |
| `systems/services/content-service.md` | **partial** | 就绪切片 = 启动期 manifest 比对 + blob 内容寻址 + ES256 签名校验 + 文件级事务 + overlay 合并 + 合并后全量校验 + `AllEnabled()` 取池 + 断网降级到随包基线 + 语言覆盖率审计 + overlay 剧本例外的 `newIds` 双闸 + 可执行化阶梯四处应用。其余卡于：flags 拉取频次护栏、disabled 条目被存档引用时的 UX、剧本树按篇章分包的边界 |
| `ux/screen-flow.md` | **partial** | **切片本次大幅扩大**（上次卡点「五个入口的数据源 schema 未定」已随 08-17h 消解）= 登录屏 + 主菜单五入口导航骨架与 Store 三条呈现纪律 + 建议更新横幅去重 + 储物袋全屏面板形态 + 玩家档案屏的绑定 / 解绑列表与两处二次确认 + **各入口读取的两层 Profile 字段已逐格可指**。其余卡于：元婴证书形态、成就两档奖励内容、寿元告警是否伴音效 / 震动、Explore 揭示转场时长与音效实测 |
| `systems/services/account-service.md` | **partial** | **本次由 blocked 升级**：就绪切片 = 会话生命周期 + 四个账号方法（登录 / 绑定 / 解绑 / 改名）+ **refresh 失败拆两条路径**（网络失败 → 缓冲通道 / 收到 `auth.session_revoked` → 硬阻塞重登 + 暂停退避，判据钉为「收到了明确应答」，三处同源措辞已同批改齐）+ `AccountInfo` 五字段 + 被挤下线后「先 pull 后 flush」。其余卡于：`deviceId` 的生成与持久化落点（后端两条要求已知，本库落点未定）、`ComplianceManager` 客户端覆盖面的切分（唯一在办的跨边界承接项）、refresh token 客户端持有形态的落笔 |
| `systems/adventure-event/common-properties.md` | **partial** | **本次由 blocked 升级**：就绪切片 = **`EventOption` 13 格物化字段**（08-17i/j 收口，含 `OutcomeSpec` / `Encounter` / `ExchangeStock` / `RerolledCount` / `DestinationLocationId` / `RevealedEventId`）+ **「产出即定稿、不得回查模板重算」**+ **事件收口的事务语义**（收口是一次事务、一个存档点；事件内部的主动消费即时提交，附两条可判定判据）+ `PastEventEntry` 与 `AppliedChange` = 「本次事件的最终账」+ 成本侧 `LifeSpan` 取值域非负。其余卡于：**可用事件的生成 / 加权运算形态**（类型配比算子、location + Plot 叠加顺序、批次规模区间两端由什么驱动）、`lifeSpanCost` 定价表逐格取值（ch1 专场） |
| `systems/monetization.md` | **partial** | 就绪切片 = 付费凭证 `PlayerEntitlement`（类内单字段 + 透明 JSON path + 空迁移）+ **空池三道闸** + 购买入口三条前置条件与灰态 + 兑现事务（`AccountRng.For(PremiumBundle, ordinal)` 一次派生连抽 3 条 → 一次 `TryApply` → `Immediate` push，序号先算后写）+ 五项排除与「允许的呈现穷举为两处」。其余卡于：平台内购 SDK 明确在 MVP 之外（购买段无法落地）、`K` 与 `GrantPoolMargin` 数值待内容规模、两个通用池当前条目为零（闸 ① 无可校验对象）、纯外观付费点未定案 |
| `vision/pillars.md` · `vision/references.md` · `vision/scope.md` | blocked | 北极星 / 参考登记，**非 derive 对象**（作为其余文档的挂靠前置；`scope.md` 的「开发顺序」仍是 ADR 候选、美术资源策略与合规立场未定） |
| `decisions/ADR-0002` · `ADR-0003` · `ADR-0004` · `ADR-0005` | blocked | Accepted 的决策记录，**非 derive 对象**（作为其余文档的就绪前置，本身不产 FR） |
| `decisions/ADR-0001-example.md` | blocked | 示例占位，`## Decision` 明写「待定」；status 仍为 Proposed |
| `decisions/_index.md` · `decisions/_TEMPLATE.md` | blocked | 台账 / 模板，非 derive 对象 |
| `systems/_index.md` · `systems/services/_index.md` · `ux/_index.md` | blocked | 导航索引，非 derive 对象（各自的待决项已下沉到对应主题文档） |
| `systems/balance.md` | blocked | **ch1 数值标杆专场未开——本库现存的唯一大规模卡点，待决问题已积到 11 条**：`lifeSpanCost` 定价表逐格 · 卡牌道念产 / 削量纲基准 · 敌人各级产出缩放 · 战后奖励池 `RarityTier` 权重 · 商店四组数值格 · 回寿量三档点数 · 闭关三个数值格 · Explore 真身占比校准 · 带边界配置落点 · 重试上限数值 · blind / ante 缩放曲线。**其中商店定价被 jade 获取渠道阻塞**（产出侧一片空白时无从反推消耗侧） |
| `systems/game-progression.md` | blocked | eventOptions 生成 / 加权的运算形态未定、三层框定（location / PlotManager / seeded RNG）叠加顺序未定、`eventCountLimit` 可否被剧本推拉未定、中长期进度感那一半未定、blind / ante 缩放未陈述 |
| `systems/scoring.md` | blocked | 规则面已定（道念产削 / 下限 0 / 胜负两条支路 + 单价表 / 负侧 1:1），但三档 `BaseReward` / `RewardPoolId` 取值与卡牌量纲基准均归 ch1 专场；且它必须依附一场可运行的战斗，而 `combat-service` 的战斗内容整体为空 |
| `systems/adventure-event/_index.md` | blocked | 五类之间的配比、Combat 内 `combatTier` 三档配比未定 |
| `systems/adventure-event/combat/_index.md` · `combat/common-properties.md` | blocked | 量纲基准与三档奖励厚薄归 ch1 专场、敌人 AI 规划形态未定、隐藏属性与战斗资源的其余耦合面未定、失败后果其余部分未定、敌人 schema 其余字段未定。**注：该 `_index.md` 仍把「效果关键字体系与目标规则」列为承重未决，此条已由 08-16c 收口，属活文档漂移**（本技能不改主题文档，留待下次 `/analyze-new-ideas` 或 `/summarize-open-questions` 清理） |
| `systems/adventure-event/exchange/_index.md` · `exchange/common-properties.md` | blocked | **机制面已于 08-17d 全面收口**（五个商品族映射既有仓储、库存经 `RngStream.Shop` 掷定并落存档、「族 × 稀有度」定价表、`ModifierKey.ShopPrice` 物化侧施加、售出仅 `CharacterItem` 且准入为代码级常量、`Source.ExchangeSell`）；卡于四组数值格全欠（ch1 专场，且被 jade 获取渠道阻塞）· 满袋能否购买（阻于储物袋满袋处理）· 上游取池 / 物化链路（future-event-service 生成规则）未定 ⇒ 无可独立成立的切片 |
| `systems/adventure-event/research/_index.md` · `research/common-properties.md` | blocked | **机制面已于 08-17b 全面收口**（构筑面板 = 决策点面板第三实例、六类操作闭合、`DeckElements` 载体、`manaLimit` 自选风险档、候选生成零新增抽取代码）；卡于三个数值格与功法层数上限（ch1 专场）· 风险档的竖屏呈现未设计 · 上游生成链路未定 |
| `systems/adventure-event/explore/_index.md` · `explore/common-properties.md` | blocked | **机制面已于 08-17c 全面收口**（遮罩下的固定真身、揭示 = `eventStart` 内一次 `with` 派生、resolver 按真身选取、真身 `ContentEnabled == false` 的取池期过滤、全屏覆盖层呈现、部分线索完全不给）；`common-properties.md` 的待决问题已明写「无」。卡于两个待实测初值与定价表 Explore 行（ch1 专场）· 上游生成链路未定 ⇒ 无可独立成立的切片 |
| `systems/adventure-event/travel/_index.md` · `travel/common-properties.md` | blocked | **载体与结算已收口**（`LocationData` + 单份 `LocationMapData`、恒启用、80/20、`EventOption.DestinationLocationId` 物化时掷定、两条 `StatusAssignment` 由 life-cycle-service 组装、判据取 `DestinationLocationId != ""`）；卡于事件类型概率修正的运算形态 · 槽位数 `k` 的来源（依赖批次规模区间两端）· Travel 行定价（ch1 专场）· 失去 flags 关地域后的运营替代 |
| `systems/enemies/_index.md` · `enemies/common-properties.md` | blocked | `EnemyData` 其余字段未定、AI 决策算法未定、**敌人池的篇章框定载体未定**（`EnemyData` 上没有任何字段表达篇章 ⇒ 空池校验只能按 `EventType` 单维）、道念产出缩放归 ch1 专场、敌人是否也以功法构筑卡组未定 |
| `systems/character-profile/currency.md` | blocked | jade 的获取渠道 / 掉落权重整体未设计（承重）——**它同时卡住商店定价表的全部绝对数字**，产出侧空白时无从反推消耗侧 |
| `systems/character-profile/deck/_index.md` · `deck/common-properties.md` | blocked | 效果三层 + `KeywordData` + target/scope 分离 + `EntryFilter` + `CardType` 五分 + `Subtypes` + `Pool` 已收口；仍卡于：`CardData` 的**费用与触发器两格仍是结构占位**、效果流水线阶段划分未定、starter deck 未设计、功法规模参数与量纲基准归 ch1 专场、关键字与次类型首批清单为空 |
| `systems/character-profile/item/_index.md` · `item/common-properties.md` | blocked | **战斗外道具的使用入口未设计（承重）**——它阻塞回寿法宝定稿，并连带两问（是否单独构成存档点 · 事件外使用时无 `PastEventEntry` 可挂，寿元曲线出现无痕迹回升）· 储物袋满 9 格的处理未定（承重）· 道具种类目录与「什么该做成卡 / 道具 / 神通」的判据未给 · 共有字段无实质设计 |
| `systems/character-profile/life-total.md` | blocked | 规则面已定（境界基线 10 / 25 / 40、归 0 = 角色终结），回复幅度与来源分布归 ch1 专场；且不构成可独立成立的 FR 面 |
| `systems/character-profile/mana.md` | blocked | 更高境界的基线跃升未定（`lifeTotal` 已定为境界跃升，mana 尚未表态）；`manaLimit` 下降的承载点已由 Research 风险档答结（08-17b） |
| `systems/character-profile/power/_index.md` · `power/common-properties.md` | blocked | 战斗外那一半的复用边界未定（承重——capability flag / modifier pipeline 注册面是否两层共用、持有列表与清理规则落点）· 战斗内运行态计数器的存档形态未定 · 获取 / 失去触发未定 · `common-properties.md` 字段清单整体为待定 |
| `systems/player-profile/account-info.md` | blocked | 字段面五项已定（08-16e），仅剩合规字段归属一条待后端分级 ⇒ 表仍可能增行；**且它单独不构成可独立成立的 FR 面**，应随 `account-service` / 登录切片一并落地 |
| `systems/player-profile/achievement/_index.md` · `achievement/common-properties.md` | blocked | 成就条目 schema 与进度模型未设计、触发采集面（EventBus 被动 vs 主动上报）未定、两档具体奖励条目清单未定 |
| `systems/player-profile/codex/_index.md` · `codex/common-properties.md` · `codex/enemy-codex.md` | blocked | 四本图鉴的解锁触发与词条深度未定、`LocationCodex` 记连边的显影粒度未定（承重）、计数字段是否要未定、`CodexEntry` 字段清单整体待定（**它同时是 `player-profile/_index.md` 六处 `⟨待定⟩` 与 `sync-service` 序列化面的来源**）；且依赖未定的 `EnemyData` |
| `systems/player-profile/game-setting.md` | blocked | 设置项清单未定、设备本地项 vs 账号级项切分未定（**同为 `player-profile/_index.md` 的 `⟨待定⟩` 来源之一**） |
| `systems/player-profile/player-item/_index.md` · `player-item/common-properties.md` | blocked | 道具目录与次数补充机制未设计、战斗内运行态存档形态未定、共有字段无实质设计 |
| `systems/player-profile/player-power/_index.md` · `player-power/common-properties.md` | blocked | `RelicData` 字段清单与触发器体系未设计、capability flag 枚举与叠加 / 冲突规则未定、战后奖励池权重表未定、平衡边界未定 |
| `systems/services/combat-service.md` | blocked | 战斗内容整体为空（卡牌定义 / 起始卡组 / 敌人目录 / 遭遇编排）、敌人 AI 决策形态未定、Finale 奖励加厚幅度归 ch1 专场 |
| `systems/services/future-event-service.md` | blocked | 生成 / 加权的运算形态未定（承重——**它是四个事件子类型 partial 化的共同上游**）、`EventOutcomeSpec` 内部字段面阻于效果关键字那条、`PickMany` 抽不足时两个调用侧的处置未定、框定叠加顺序未定、`Priority = 1` 的其余抬升条件未定 |
| `systems/services/life-cycle-service.md` | blocked | 非战斗四类的决策点清单未给（已由四类减为三类）、**RNG 状态的写入通道形态未定**、只读投影 `Project(spec)` 的语义面未定、`experiencePoint` 阈值曲线未定、隐藏属性增减触发未定、重试上限的存档表达未定、元进程各字段解锁 / 获取触发未定 |
| `systems/services/plot-manager.md` | blocked | 数据编码已收口（`PlotArcData` + `PlotNodeData` · 正文内嵌 · key points 每 arc 一条 · `PlotModulation` 六字段 + 加载期悬空校验 · 排队 arc 落存档）；仍卡于：多条 `Active` arc 的 `PlotModulation` 合并算法（阻于框定叠加顺序）、DnD 式选分支的触发点与 UI、隐藏属性的逐条推拉映射、剧本分包边界、`HiddenStatGrade` 三个映射值待 ch1 专场校准 |
| `systems/services/profile-service.md` | blocked | `CostKey` 资源族 element 清单未定（承重；能力族与统计族已闭合）、**`activeCombat` 的写入通道未明写（承重）**、RNG 与 `pastEvent` 同样没有 spec 列、`Project(spec)` 语义面未定、capability flag 叠加 / 冲突规则未定、`status` × 拥有 / 失去的存档表达未定、成就采集面未定 |
| `ux/combat-ux.md` | blocked | 竖屏分区整体是否过载（承重，**已排期专门 session**）、结算 ticker 文案体系（承重，唯一动态情报通道）、栈与战场同屏呈现（承重）、出牌手势 / 手牌布局 / 疲劳呈现 / 节奏整体未设计 |
| `art/_index.md` · `art/visuals/_index.md` · `art/soundtracks/_index.md` | blocked | 流水线说明与资产类目表；本库不承载生成产物（归 `game-feature-branch/`），无客户端行为面可 derive。`visuals/_index.md` 另有 4 条未决（guide 粒度、落地命名规则、UI 元件是否 AI 生成、境界是否改外观） |
| `art/visuals/art-direction.md` · `art/soundtracks/audio-direction.md` | blocked | 主体各节仍为 `> _（待写）_` 占位（各 6 处）——色彩 / 光照 / 构图、配器 / 调式 / 混音均**尚无设计意图** |
| `art/visuals/animations/_index.md` | blocked | 明写占位：范围、技术载体、制作方式、与战斗节奏的关系**待咨询专业人士后确定**，**尚无设计意图** |
| `art/visuals/references/_index.md` · `art/soundtracks/references/_index.md` | blocked | 参考登记表基本为空（视觉 3 行的「不借什么」栏全空、音频表空），且二进制是否入库未定 |
| `art/visuals/guides/_index.md` · `art/soundtracks/guides/_index.md` | blocked | guide 台账为空，**尚无任何 guide** |
| `art/visuals/guides/_TEMPLATE.md` · `art/soundtracks/guides/_TEMPLATE.md` | blocked | 模板骨架，非 derive 对象 |

### 建议的 derive 顺序（仅限 ready / partial 项；被依赖者在前）

1. `/derive-requirements systems/common-properties.md` —— **唯一整份就绪的地基文档，且被几乎所有内容与服务代码依赖**。共有字段类型与两级 RNG 这一层先落，后面每一份 FR 都能直接引用而不必各自重新约定。账号级 RNG 的验收有现成的 8 组测试向量，是全库当前最硬的验收标准。文档自己也写明排期——`LocalizedText` 与 `DrawPool<T>` 同批、**在写下第一批 `.tres` 之前**，窗口一旦关闭每多一条内容就多一份要改的资产。
2. `/derive-requirements ux/error-and-blocking-ux.md` —— 翻译键基建（文档自己已点名 `FR-ux-translation-foundation`）。**无上游依赖**，是「每屏从第一行起就用键」这条起手纪律的前置，越早越省返工。
3. `/derive-requirements systems/architecture.md` —— 服务骨架：七个 autoload 的注册顺序、EventBus、边界服务的接口 + Offline stub 双实现。**只取骨架切片，不取 `CostKey` 资源族相关面。**
4. `/derive-requirements systems/character-profile/_index.md` + `systems/player-profile/_index.md` —— **本次评估新解锁的一批，也是变化最大的一处**：两层 Profile 的存档 schema 地基（数据类 + 序列化 + `schemaVersion` 与迁移）。**两份同批处理**：它们互相引用（`PlayerProfile.characterProfile`）、共用同一个 `schemaVersion` 与同一条迁移路径，分两次 derive 必出两份互相打架的 FR。**排除 `CodexEntry` 与 `GameSetting` 两块**（子 schema 仍待定），其余逐格已可指。
5. `/derive-requirements systems/services/content-service.md` —— 内容加载与校验链路（契约已成文；依赖 1、3）。它被一切内容读取方依赖，应先于任何玩法系统。
6. `/derive-requirements systems/services/sync-service.md` —— 本地缓存原子写 + push 调度 + CAS / 幂等 + 两层 Profile diff（依赖 1、3、**4**）。上行负载的字段面本次已解锁；**仅排除 codex / gameSetting 两块的序列化**。
7. `/derive-requirements ux/screen-flow.md` + `ux/onboarding.md` —— 登录屏 + 主菜单导航骨架（依赖 2、3、4）。**两份同批处理**：登录屏切片在两份文档中重叠，分两次 derive 必出两份互相打架的 FR。各入口的数据面本次已可指（依赖 4 先落）。
8. `/derive-requirements systems/services/account-service.md` —— 会话生命周期 + 四个账号方法 + refresh 两条路径（依赖 2、3、7）。**`deviceId` 落点未定 ⇒ signin 上行留一个显式的待填口，不要在 FR 里替它拍板。**
9. `/derive-requirements systems/adventure-event/common-properties.md` —— **只取 `EventOption` 的数据形态与事件收口的事务语义**（依赖 1、4）。它是玩法侧唯一具备可独立成立切片的文档，且这一切片是后续全部事件类型 FR 的共同类型地基。**不取生成 / 加权面**（那是 `future-event-service` 的未决核心）。
10. `/derive-requirements systems/monetization.md` —— 兑现段 + 三道闸 + 入口前置条件（依赖 1 的账号级 RNG、6 的 push 调度）。**排在最后**：它是唯一一份依赖两个通用内容池的 partial，而池当前为空；**只取兑现与拦截，购买段等平台 SDK（MVP 外）。**

> **仍然不要**对战斗 / 卡组 / 敌人 / 平衡 / 元进程侧任何文档 derive。四个非战斗事件子类型（Explore / Research / Exchange / Travel）的**机制面已在 08-17 那一批中全面收口**，它们不再欠机制——欠的是同两处：**ch1 数值标杆专场**（现已是本库唯一的大规模卡点）与 **`future-event-service` 的生成 / 加权运算形态**（四者共同的上游）。这两场 session 是解锁整个玩法侧的最短路径，且第二场的门槛比第一场低得多。

## 下一阶段

- **ADR 状态：** 已固化——
  - **ADR-0002**（修行事件**五类**分类，五值枚举 + Combat 的 `combatTier` 三档）
  - **ADR-0003**（强制在线 · 云端权威 · 重账号）
  - **ADR-0004**（境界存档 · 重试模型，含寿元归 0=defeated）
  - **ADR-0005**（**`.claude` 是工程层、对设计只做薄引用**；07-30 由 `knowledge/` 扩到整个 `.claude`，含 rules / skills 与冲突裁决规则）

  ADR 候选：**开发顺序**（框架 → 内容 → 平衡与体验 → 社交及其他，见 `vision/scope.md`）；
  **内容载体形态**（随包基线 + overlay + 版本校验，见 `systems/services/content-service.md`）。
  （注：ADR 现可自由编辑，改决定直接改 ADR，不再新开取代 ADR。）
- **流水线闭环（07-30）：** design → code 链路补上 `/breakdown-requirements`（一份 FR → 一个文件夹的可执行子需求），完整形态见 `README.md` 与 `requirements/_index.md`。
- **架构闭环缺口：** 8 处**全部闭合**（移出记录见 `answer-logs/log-0725c.md` 与 `log-0726b.md`）；状态表见 `systems/architecture.md` 的「闭环缺口」小节。残留细节已下沉为各焦点分片的普通待决问题。

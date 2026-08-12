# Open questions — 跨 session 待答清单（索引）

> 本文件是**客户端**（Godot 项目）待答清单的**索引**；问题条目本身按主题拆在 `open-questions/` 下的分片里。后端侧的待答清单在 `backend-design-documents/open-questions.md`（`backend-design` 分支）。
>
> 每次 session 结束时，未答的 Open questions 汇总到对应分片，供下次拾起；一旦答定，就从分片中移除、归档进对应主题文档的 `## 待决问题` / `## 决策`，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。此清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；已答定问题的移出记录见 `answer-logs/`。
>
> **最近更新：2026-08-12e**（账号级能力授予的候选池与排重规则：**残卷 · 礼包 · 置换共用同一段抽取**（`AllEnabled()` → `(Kind, Scope)` → 去成就限定 → 排除已持有 → 按 `RarityTier` **单张共用权重表**加权 → seeded 抽；多条**无放回**）。**「抽到重复怎么办」在结构上被消解**——排重在**取池阶段**而非掷骰之后，池 = 未持有集合 ⇒ 抽不出重复；这不是新选择，而是 08-09b 全局前置「尚未拥有的法则数 > 0 才掷骰」唯一自洽的读法。由此 **`HasGrantable()` ⟺ 池非空**（与全局前置是同一个判断）、`pickedPowerId` 有定义，**残卷伪码补完**。**⚠ interview 三项裁定**：① **账号级 RNG 加具名域 `AccountStream`**（修订既定的两参数 `Hash64(AccountSeed, ordinal)` 为三参数——礼包也走账号级掷骰后两条渠道的序号会撞出同一序列；否决「序号区间隔离」）；② **闸 ① 收窄为「礼包所需 + 可调余量」**（原写法依赖「残卷分档上限」，而残卷在 `balance.md` 中**无上限**、「池取尽 → 静默停摆」本就是既定终局 ⇒ 那个判据不可定义）；③ 准入字段**保留 `ExclusiveSource: Source?`**。礼包空池走**三道闸**（加载期 `PushError` / **购买入口前置拦截**——把失败点挪到掏钱之前 / 兑现处报错**不补发**）。**成就奖励改为指定条目 + 成就限定**（除该成就外无其他获取途径 ⇒ **成就奖励恒不落空**，附一条可断言的不变式 + 三条 `PushError` 校验），新增内容共有字段 `ExclusiveSource`。`Rarity` 消费点 2 → **3**；`DrawPool<T>` 调用方 3 → **4**，**无放回 + 加权**成为其契约。**不 bump 存档 schema**（`BundleGrantOrdinal` 待落点确定后再 bump）。答结 2 条、部分答结 2 条、新增待答 1 条。**⚠ 后端侧需一份对应 handoff**（`AccountSeed` 复算多一个参数，可与既有那笔合并）。见 `answer-logs/log-ability-grant-draw-pool.md`）。
>
> 上一次更新：2026-08-12d（隐藏属性的档位模型与跨档叙事：**三属性共用一套档位表**（道心 `[0,100]` 起始 50 **5 档**带符号 `-2..+2` / 煞气 `[0,100]` 起始 0 **4 档** / 寿元既定 **3 档**），**档号方向 = 离常态的距离** ⇒ 三属性共用一条触发规则 `|newBand| > |oldBand|`（读成「数值下降」会把寿元既定的 30% 提示字面废掉）；每档带**回滞 δ** ⇒ 档位不是当前值的纯函数 ⇒ **3 个 band 字段落存档**。**「达阈值触发剧情线」与「跨过隐藏档位」两套并行说法收敛为同一张表**，四个消费方各取所需且**密度互不绑定**（调制用全部档 · 剧情线 3 档 · 叙事 4 档 · 寿元红字 1 档）——**档多 ≠ 文案多**。文案**挂档位不挂事件 · 走内容层 · 每档 2–3 条等概率取一（随机源不带种子）· 只挂极值档**（**≈ 6–10 条 / 轮回**，依据 = 本作是 **deck building game 不是 visual novel** + 因果的主要载体是事件文案本身）· 呈现 = **结算面板内一档一行**、多属性同跨逐条陈列（寿元 → 煞气 → 道心）、寿元 10% 的红字倒数**是常驻标注而非叙事**。寿元百分比的分母定为新字段 **`ChapterLifeSpanBudget`**（篇章边界冻结结转后预算）。**⚠ interview 追加**：档位条目**恒启用**（立通则「**能被抽取的才配有开关**」）· 道心下臂 `-2` **挂 `PlotTriggerId`**，剧情线目录 2 → **3 条**。**不推翻任何既有决策**（「UI 文案走翻译键」vs「叙事走内容层 overlay」经核不冲突，四问判据已落 `ux/_index.md`）。答结 2 条（+2 条部分）、新增待答 2 条。见 `answer-logs/log-hidden-stat-bands-and-crossing-narrative.md`）。
>
> 更早：2026-08-12c（标识符单数收口：立通则「**类型名恒为单数，复数只属于集合字段名**」，`CharacterItems` 整体作废。法宝三层分工一次写死：`ItemData`（内容定义，两层共用，**无 `CharacterItemData`**）↔ `CharacterItem`（持有条目，一份实例 = 一个集合元素）↔ **`CharacterProfile.magicPack`**（集合字段**借用已定名的容器概念「储物袋」** ⇒ 单复数之争直接消失，9 格上限 / 按 `ItemId` 堆叠 / `UsableScene` 筛「随身」等规则与字段名对齐）。**连带一并收口**：`Achievements` → 元素类型 `Achievement` + 字段 `achievement`，**裸提及一并单数化、文件夹 `achievements/` → `achievement/`**（interview 追加，超出原草稿声明范围）；`pastEvent` 类型漂移 `List<AdventureEvent>` → `IReadOnlyList<PastEventEntry>` **三处全部纠正**（含 ADR-0004，纯类型标注订正、不改该 ADR 的决策语义）。**纯标识符收口：机制侧零改动、不 bump schema、无迁移**（无线上账号、无对应代码 ⇒ 最便宜的改到位窗口）；只改活文档，历史文档不回改。答结 1 条（+2 条连带）、新增待答 0 条。见 `answer-logs/log-character-item-singular-naming.md`）。
>
> 更早：2026-08-12b（授予来源 `Source` 收口：**封闭三值 → 按 `(Kind, Scope)` 分域的七值开放清单**（`Unknown=0` · `FinaleWin=1` · `PremiumBundle=2` · `AchievementReward=3` · `EventOutcome=4` · `CombatReward=5` · `ExchangePurchase=6` · `InitialGrant=7`）。**推翻 08-10b 的「成员清单已穷举 / 清单是封闭的」**——原待答的两个收口（收窄字段到账号级两类 / 轮回级恒 `Unknown`）**全部否决**，该扩的是清单而非字段覆盖面；「**不为置换所得预留成员**」保留并强化为禁令。**保留单一枚举不拆四个**（拆分会把 `Source` 形参逼成 `object` / `int`），**分域差异由合法子集校验表承载而非类型系统**（代码常量静态查表，不进 `.tres`、不走 overlay）。新立承重规则 **「入口严、读档宽」**（`Grant` 非法组合 → `PushError` + 整批拒绝；读档不合法 → `PushWarning` + **保留原值**，回落 `Unknown` 会压低 `x` 并让档位回跳）。**残卷 `x` 口径与单调不减完全不变、不 bump schema、签名不变。** 另新立通则「一个字段不为部分落点无规则消费点而拆出第二套同步口径」。答结 1 条、新增待答 2 条。**⚠ 后端侧承接已就位**（枚举序列化形态冲突待该库收口）。见 `answer-logs/log-grant-source-per-kind-scope.md`）。
>
> 更早：2026-08-12（错误文案与版本提示片区收口：**玩家可见文案归 UI 层、键 = 后端 `code`、载体 = 翻译键**（`code → ERR_*` 为机械变换，不建第二张对照表；缺条目 → `PushWarning` + 按 `OpError` 回落 + 启动期审计；翻译资源随包、不走 overlay）· **三条「去更新」提示 = 同一根轴上的三档，同一时刻只呈现最高一档**（`UpgradeRequired` 复用常驻同步指示并**必须换掉「离线」二字**）· **三种终局态收敛为一个阻塞屏 + 变体表**（**三变体 ≠ 三处硬阻塞**，阻塞点仍只有两处）· **迁移失败分两种情形**（超上界走「需更新」/ 迁移抛错走「存档读取失败」+ 必上报），否决重装与回退云端旧版。**推翻 `OpResult.Detail` 的「面向玩家的原因串」表述**（收口为诊断串）；**新定全库 UI 文案统一走翻译键**（中文默认、英文全占位符）。答结 3 条、新增待答 2 条。**⚠ 后端侧需一份对应 handoff**（错误体 `detail` 增更新地址字段，可与 08-11b 那笔合并）。见 `answer-logs/log-error-copy-and-update-prompts.md`）。
>
> 更早：2026-08-11c（战斗流程收口：**先后手由 `EncounterSpec.FirstSide` 决定**（剧情可指定、否则由 combat 子流掷）· **抽牌堆不重洗、抽空即疲劳**（每抽一张 −1 道念 ⇒ **道念的削减通道从一条变成两条**，卡组规模成为真实取舍）· **卡牌侧数值重定**（起手 5→**4**、手牌上限 10→**9**、卡组规模两侧**不设硬限**、储物袋 99→**9**）· **`CardType` 六值 → 五值**（删灵宠，永久物统一归阵法，「实体 / 非实体」二分取消）· **不设 mulligan**。答结 2 条、推翻 5 处既有定案、新增 4 条待答。见 `answer-logs/log-combat-system.md`）。
>
> 更早：2026-08-11b（契约边界层的客户端侧承接：**传输信封走 HTTP 头、客户端 record 一字不改**（`X-Request-Id` 每次重试必换 vs `pushId` 必不变）· **错误处置 = 以 `code` 为键的数据表**，未知项按 `class` 走四条保守默认路径，**硬阻塞仍只有两处且只由已知 `code` 触发** · **`Upgrade` 类错误只在登录 / 启动 pull 硬阻塞**，非闸门点保留队列 + 暂停退避，**与「缓冲超限 → 软阻塞」的衔接 = 闸门口径不变、只换模态文案** · **`Retry-After` 是退避下界** · **flags 成为 `ContentEnabled` 的第三层覆盖来源**，启动链插入 `RefreshFlagsAsync`（登录之后）。答结 3 条、**推翻「overlay 是唯一热更层」**、新增 2 条待答。**后端侧需一份对应 handoff**（删 `/v1/plot/…` 与 `plot.unavailable`）。见 `answer-logs/log-0811_2.md`）。
>
> 更早：2026-08-11（剧本内容本地化 · 撤销云端剧本服务：剧本文本改归**本地内容层**并走 content-service 的 overlay 通道，**overlay 对剧本内容可新增 `Id`**——「只改不增」的唯一例外，因剧本是唯一不被存档引用的内容；**跨进程边界成分 4 → 3**、`IPlotBackend` 整套作废、`PlotManager` 全部方法降为形态 A；新生承重规则**悬空 key point → `PushWarning` + 叙事降级、不阻塞轮回**。答结 3 条、**推翻 07-25c 的本地 / 云端分界判据**、新增 2 条待答。**后端侧需要一份对应 handoff**。见 `answer-logs/log-0811.md`）。
>
> 更早：2026-08-10（solution-draft-ability-deprivation-and-player-statistics · 「本轮回禁用」与置换型剥夺片区**四条一次性全部答结**：禁用落 `CharacterProfile.disabledAbility`（三档时长 `NextEvent / ThisChapter / ThisCycle`）、生效判据统一为「截断在进入生效面那一步」、置换 = outcome 侧的一个决策点（排除已有 · 同稀有度 · 先看后决 · 拒绝无代价 · 四类通用）、`ProfileChangeSpec` 拆为资源 / 能力 / 统计三个平级列表、`PlayerStatistics` 首批两项、宽松同步口径五条；**推翻**「置换作为选择成本似乎合理」与 08-06b 的「统计首项 = 篇章重试累计」；新定名 `RarityTier` 五档并合并 `PowerScope` / `ItemScope` 为 `AbilityScope`）。** 逐次更新摘要（本次答结了什么、推翻了什么）见 `open-questions/update-log.md`。

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身。 |
| `open-questions/01-combat.md` | **① 战斗机制**（焦点之首）：能力剥夺与统计计数的残留（片区主体已于 08-10c 答结）、结构与配置、内容与数值（多数已归 ch1 数值标杆专场）、呈现。 |
| `open-questions/02-event-options.md` | **② eventOptions 生成流程**：生成 / 加权、物化字段、优先级、`CostKey` 与资源打穿、`pastEvent`、location 与图鉴连边。 |
| `open-questions/03-adventure-event-types.md` | **③ 逐类型 AdventureEvent 机制**（九类各开一场专门 session）。 |
| `open-questions/04-hidden-attributes-plot.md` | **④ 隐藏属性 / 剧本机制**：档位阈值、跨档叙事、`lifeSpanCost` 分档、AdventurePlot 数据编码与 key points 粒度、剧本内容的数据形态与分发粒度。 |
| `open-questions/05-service-contracts.md` | **⑤ 服务契约 / 工程侧残留**：翻译键的铺开节奏、`#if DEBUG` 判据实测、`.claude/rules/*` 的设计性表述、需求流水线形态、共有属性提炼粒度。 |
| `open-questions/06-meta-progression.md` | **⑥ 元进程的失败侧与中长期规划感**：轮回内的进度感是否需要补充、1% 存活分支的叙事补白落点。 |
| `open-questions/07-codex-monetization.md` | **⑦ 图鉴族与商业化**：`CharacterPower`、六本图鉴、premium bundle。 |
| `open-questions/deferred-content.md` | **已搁置：内容充实**（07-30 起暂不推进）＋ **美术与音频（`art/`，08-04 加入）** ＋ 随内容搁置的 UX 呈现细节 ＋ 尚未设计的占位主题。 |

## 当前焦点：各系统机制细节

> **焦点判据（07-30 定）：** **规则、字段语义、流程与算法 = 机制细节 = 焦点**（分片 ①–⑦）；**具体条目目录与数值 = 内容充实 = 搁置**（`open-questions/deferred-content.md`）。与既定开发路线「框架 → 内容 → 平衡与体验 → 社交及其他」的第 ① 阶段一致。Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。
>
> 焦点顺序即分片编号顺序；**① 战斗机制**优先级最高。

## derive 就绪度

> **当前：全量回滚，本库尚未进入可 derive 的阶段。** 先前逐文档的 derive 就绪度判定（07-22 ~ 07-25）已**全部作废**——设计仍在快速演进，逐次 handoff 顺带下的就绪度结论会迅速过时且互相矛盾。
>
> **就绪度不再由 `/analyze-new-ideas` 顺带评估或更新。** 它由专门的 **`/assess-derive-readiness`** 全量扫描产出，**由用户在时机成熟时手动调用**；该技能是本小节的**唯一写入者**。在它跑过之前，本小节保持「尚未就绪」。

## 下一阶段

- **ADR 状态：** 已固化 **ADR-0002**（修行事件九类分类，九值枚举）、**ADR-0003**（强制在线 · 云端权威 · 重账号）、**ADR-0004**（境界存档 · 重试模型，含寿元归 0=defeated）、**ADR-0005**（**`.claude` 是工程层、对设计只做薄引用**；07-30 由 `knowledge/` 扩到整个 `.claude`，含 rules / skills 与冲突裁决规则）。ADR 候选：**开发顺序**（框架 → 内容 → 平衡与体验 → 社交及其他，见 `vision/scope.md`）；**内容载体形态**（随包基线 + overlay + 版本校验，见 `systems/services/content-service.md`）。（注：ADR 现可自由编辑，改决定直接改 ADR，不再新开取代 ADR。）
- **流水线闭环（07-30）：** design → code 链路补上 `/breakdown-requirements`（一份 FR → 一个文件夹的可执行子需求），完整形态见 `README.md` 与 `requirements/_index.md`。
- **架构闭环缺口：** 8 处**全部闭合**（移出记录见 `answer-logs/log-0725c.md` 与 `log-0726b.md`）；状态表见 `systems/architecture.md` 的「闭环缺口」小节。残留细节已下沉为各焦点分片的普通待决问题。

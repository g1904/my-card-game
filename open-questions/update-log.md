# 待答清单更新日志

> 每次 `/analyze-new-ideas` / `/summarize-open-questions` 运行后，在此**顶部**追加一条更新摘要：本次答结了什么、推翻了什么、新增待答落在哪个分片。问题条目本身在 `../open-questions.md` 的各分片里；已答定问题的逐条移出记录在 `../answer-logs/`。
>
> 本文件只记「发生了什么变化」，不承载问题条目本身。

> **只保留最近 10 条。** 更早的条目原样移入 [`update-log-archive.md`](update-log-archive.md)（按时间正序），
> 一字未改、仅换了文件——本日志与归档合起来即全部历史（`decisions/ADR-0005`：台账不无限膨胀）。

## 2026-08-22d（`/write-adr --lib=game` · 固化 4 条 · 新登记候选 2 条 · 只写 `decisions/` 与「下一阶段」）

- **来源不是候选清单**——`open-questions.md` 的「下一阶段」当时明写「当前无待固化的 ADR 候选」，那句写于 08-19 清账之后。本次候选全部由**扫 `handoffs/` 中 `status: distilled` 的散落定案**得到：08-22 单日新增 22 份 handoff，逐份按「能否被单独推翻而不牵动其余」与既有 ADR 的粒度线筛选。
- **建 4 份 ADR（均已逐条回主题文档核实事实已落地）：** `ADR-0025` Finale 失败即角色终结 · `ADR-0026` eventOptions 十步管线 · `ADR-0027` `LocationCodex` 顶点级显影 · `ADR-0028` 上行整键回声校验通则。
- **2 条够格但暂不建档，改登记进「下一阶段」**：剧本树不分包 · 单例平衡资源进 ContentRegistry。两者的主项或承载机制仍标 `[采纳推荐 — 待复核]`，按铁律「待复核不当作用户拍板」不建 `Accepted` 的 ADR。
- **其余 16 份 08-22 handoff 判为字段级 / 参数级收口**（`EncounterTighten` 字段面 · `HiddenStatDirection` · counters 键空间 · `mana +1` · `eventCountLimit` 不可调制 · 购买次数 `StatKey` · 敌人卡组规模 · `ChapterScope` · 带边界配置落点 · flags 拉取护栏 · `Priority = 1` 判据 · 非战斗决策点清单 · `EventOutcomeSpec` 字段面 · 运行态计数器 · refresh token 落点 · `Practice`/`Standard` 失败后果），低于既有 ADR 的粒度线，不建档。
- **未动主题文档、未动 `## derive 就绪度`、未动任何分片的问题条目。**

## 2026-08-22c（`/batch-analyze-new-ideas game` 补跑 · 11 份草稿 · 移出 15 条 · 新增 10 条 · 修 8 处活文档漂移 · 单库无跨边界）

- **起因是一处阻断发现**：上一轮批量的 `answers.md`（5 轮 interview 全部裁决完毕）已落盘，但**它的 Phase B 从未执行**——11 份草稿仍在 `inbox/` 顶层、无 handoff，三个裁决产物 `EncounterTighten` / `EnemyManaLimit` / `HiddenStatDirection` 在全库主题文档中零承载。用户裁定先补跑 Phase B，再做收尾。
- **写入面高度重叠 ⇒ 切 5 个波次串行**（`balance.md` 被 6 个 worker 争用、`plot-manager.md` 4 个、`combat-service.md` / `content-service.md` 各 2~3 个）。每波内 `balance.md` 与 `plot-manager.md` 各只有一个 owner，无并行写同一文件。
- **移出 15 条**（各记 answer log）：counters 家族三条（非异能计数器 / `CardInstanceSave.Counters` 读写 API / 子名字符集与登记）· 样本卡组规模两处矛盾 · 疲劳量是否可调 · 更高境界的 mana 基线 · `EncounterTighten` 字段面 · `HiddenStatGrant` 推拉方向 · `eventCountLimit` 能否被剧本调制 · `LocationCodex` 显影粒度（部分）· 剧本内容的体积与分发粒度 · 购买次数 `StatKey`（**同题两处登记，主题文档侧与分片侧同批移出**）· 失败后果的其余部分 · 散落平衡旋钮兜底大表 vs 逐份切 · 单例平衡资源如何进 ContentRegistry（降为待复核）。
- **三条逆推荐裁决**：① `manaLimit` **每次大境界 +1**（增量语义、走既有 `CostKey.ManaLimit`）——**显式推翻 `answer-logs/log-0730b.md` 第 4 条**；② `EncounterTighten` **一并覆盖五格**（原推荐两格），新增三格牌流量各需一个上界常量与下界钳制，否则剧本能把每回合抽牌压到 0；③ 内容 / 呈现类轻项只逐项问三条失败后果，其余按推荐。
- **两处本批新发现的真缺口，当场答定**：`KeywordRef.Amount` 展开成 `Transient` 条目后无承载字段（→ 战场条目增 `amount:int`，默认 `-1`）· 敌人侧 `manaLimit` 全库无取值来源（→ `EnemyManaLimit = 5` 住 `CombatRulesData`，可被 `EncounterSpec` 覆写；**参战方对称在 mana 一项被打破，已在 `combat-service.md` 列名为已知例外**）。
- **新增 10 条**：`01-combat.md` +6（`EncounterTighten` 三格界常量取值 · `EnemyManaLimit` 初值校准 · 卡牌费用曲线是否随境界上移 · 三条待复核归并条目）· `02-event-options.md` +6（三条 `HiddenStat*` 待复核 · `LocationCodex` 边缘顶点与半径 · `eventCountLimit` overlay 边界 · 词条深度改写保留）· `04-hidden-attributes-plot.md` +1（剧本树不分包的三项配套裁决）。
- **本批 20 项 `[采纳推荐 — 待复核]` 全部维持待复核**（铁律 ①）：按推荐落笔，但留在待答清单。**后果：11 份草稿中 7 份不满足归档前置条件第三条，留在 `inbox/` 顶层**；4 份（`encounter-tighten-fields` / `purchase-count-statkey` / `mana-baseline-realm-jump` / `combat-defeat-consequences`）全项正式拍板，已归档。
- **修 8 处活文档漂移**：`enemies/common-properties.md`「规模 15」孤例 · `enemy-codex.md` 三处「15 张」· `deck/_index.md` 手牌上限 9→7（**此前未进任何待答清单的纯漏改**）· `character-profile/_index.md` 与 `combat/_index.md` 两处「炼气基线 10/10」· `combat/_index.md` 的 `manaLimit`「不随境界自动成长」· `EncounterSpec.FirstSide`「剧情指定」措辞（`PlotModulation` 六字段无一格能表达先手 ⇒ 改为**内容侧在事件模板上编排**）· `exchange/_index.md` ↔ `03-adventure-event-types.md` 同题两处登记 · 本分片顶部摘要块（单行 1578 字 + 考古段）压成一句回链 `answer-logs/`。
- **两处漂移按用户裁决跳过**：`../open-questions.md` 第 82 / 106 行落在「derive 就绪度」小节内，该小节由 `/assess-derive-readiness` 独占写入，留待下次全量重估。
- **仍欠一步（与本批无关的既有积压）**：上批 14 项 `[采纳推荐 — 待复核]` 已于第 5 轮确认转正，但对应条目尚未移出 `open-questions/`，故上批 7 份草稿仍留顶层。

## 2026-08-22b（`/batch-analyze-new-ideas game 全部 solution draft` · 10 份草稿 + 1 次 interview 新裁决 · 移出 9 条 · 新增 21 条 · 跨库承接 3 条）

- **范围**：`inbox/` 顶层全部 10 份 `solution-draft-*`（均已过用户评审）。Phase A 十个 worker 并行只读校验产出 🔴 31 · 🟠 33 · `[采纳推荐 — 待复核]` 15，去重并追加跨草稿核对后收敛为 20 问，一场合并 interview 全部裁决；Phase B 按写入面分 5 个波次落笔。
- **用户在 interview 中提出一条推翻既有设计的新裁决（不属任何草稿）：Finale 失败必死。** 「移除 finale 结算认定失败后存活的场景，章节立即结束」+ 判定二值化（`d >= 0` 通过 / `d < 0` 失败，`Draw` 归入胜利侧取最低档奖励）。它单独成一个波次、排在全部草稿之前，因为它推翻的正是其余分片要引用的承重前提。
  - **改动面 22 份主题文档 + 3 份 ADR**：`ADR-0004` Decision 第 4 条**实质推翻**（战斗失败不再「不终结角色」——`Finale` 档失败是独立终结原因）· `ADR-0002` 的「整体保留」清单剔除「失败但存活仍完成篇章」· `ADR-0016` 论据自足化。
  - **`game-progression.md` 的承重结论整条反转**：「渡劫的胜负不是篇章推进闸门」→「胜负即闸门」。
  - **`DefeatReason` 三值 → 四值**（新增 `FinaleFailed`），且终态判定从**纯查表驱动**变为「查表 + 一条显式旁路」——Finale 失败不是资源触底、没有对应 `CostKey`，塞不进 `ResourceElements` 表。**这个口子已明写**，否则实现侧会以为照表走就行。
  - **一条差点静默失效的承重机制**：残卷 `PlayerPowerFragment.Accumulated` 是账号级写入，而 `DefeatCharacter` 会清理终态数据。失败恒等于死亡后，若不写死顺序，「Finale 失败累积残卷」会在**每一次**失败上丢 ⇒ 100% 失效。已在 `life-cycle-service.md` 明写「账号级残卷累加先于角色终结提交」。
  - **`WinMargin` 在 Finale 退场**：胜负线固定为 0 后它在该档没有消费者，`VictoryRule` 单字段三档共用故取值恒 0，并明写两条纪律（不是难度旋钮 · `Practice` 与 `Finale` 同取 0 是巧合、不得提共享常量）。Finale 因此**失去唯一的难度旋钮**，`balance.md` 已如实写下这一点并指向三条替代手段。
  - **「奖励最低档」零成本**：代入既定数值验算，`0 <= d < WinMargin` 整个区间的 `advantage` 上界仅 0.13 / 0.125 / 0.093，本就整体落在 `Tier.Narrow`（险胜档），由既有换算规则自动兑现。
  - 通过所需追分 ch1 8→5 / ch2 18→13 / ch3 33→25（降 24–38%）；ch3 重试上限维持 ∞/3/1、不做补偿（用户裁定）。
- **跨草稿交叉核对抓到的东西**（批量相对逐次运行的独有产出）：
  - **一处真矛盾**：`event-outcome-spec` 与 `remaining-decision-points` 各自独立撞上「置换 / 禁用候选的掷定时点」，两个 worker 推荐方向一致但**承载形状不同**（`OutcomeRule` 第四个 Kind vs `EventOption` 定稿字段）。合一为后者，逐次运行时第二个 session 会直接覆盖第一个。
  - **一处误报已拦下**：有 worker 把 `future-event-service.md` 的 `Finale 12 / 0` 判为 Finale 重构的遗留，实为正确（三档共用单字段）；已撤回该修改指令。
  - **三处「同一事实多份副本」**：生成 / 加权规则 5 份 · 硬阻塞枚举 3 种 · 「登录屏 = 应用首屏」3 处。
  - **两份草稿自身的事实错误**：`combat-runtime-counter` 称 `item/_index.md` 未表态（实已明写）· `echo-validation` 与其后端对侧草稿的「前置依赖」双双过时（实已落笔）。若照草稿写会造重复条目或改坏已正确的内容。
  - **`flags-throttle` 自称「张力：无 / API 零改动」被推翻**：存在一处自我递归无限发请求的 bug，且因 flags 无「回滚即前滚」契约，「增大即拉」在版本回滚后会让设备**永久停拉**。
- **移出 9 条**（各记 answer log）：生成 / 加权规则与叠加顺序 · `EventOutcomeSpec` 内部字段面 · `Priority = 1` 抬升条件 · 战斗之外的决策点清单 · 战斗内运行态存档形态 · 敌人池篇章框定载体 · 带边界配置落点 · 上行整键回声校验适用面 · refresh token 客户端持有形态 · flags 拉取频次护栏。
- **新增 21 条**：`01-combat.md` +9（赋级资源三项待复核 · `ChapterScope` 命名待复核 · 单例平衡资源如何进 ContentRegistry · 非异能计数器 · `CardInstanceSave.Counters` API · 子计数器名字符集 · 样本卡组规模两处矛盾 · X0 标记待复核 · 不触发第二次写入口径待复核）· `02-event-options.md` +5 · `05-service-contracts.md` +4 · `06-meta-progression.md` +1（死亡 / 轮回结束屏尚无设计）· `cross-boundary.md` +1（球在对侧的三条）。
- **15 项 `[采纳推荐 — 待复核]` 全部维持待复核状态**（用户裁定）：按推荐落笔，但留在待答清单不随本批移出。**后果：10 份草稿中 7 份不满足归档三前置条件，留在 `inbox/` 顶层。**
- **跨库**：三条承接项写入 `backend-design-documents/`（回声校验后端半 · flags 回滚即前滚条款 · 静默续期闸门收口手段），两侧互相回链。**⚠ 回声校验两侧草稿明写须成对采纳，本批只落客户端半 —— 成对采纳尚未完成。**
- **未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。

## 2026-08-22（`/summarize-open-questions --game` · 全量对账 · 移出 0 条 · 归集 10 条 · 修平主题文档 9 处 · 单库）

- **范围**：客户端库全部主题目录（`vision/` · `systems/**` · `art/**` · `ux/`）的 `## 待决问题` / `## 待解问题` / `## Open questions` 小节，逐条与 `open-questions/` 九个分片对账。不引入新想法、不裁决任何问题。
- **移出 0 条 —— 本次不建 answer log。** 逐条回主题文档核对，**没有任何一条待答项已在 `## 决策` / `## 意图` 或 `decisions/ADR-*` 中获得定论**。合理：上一次大规模收口是 08-19 的十份草稿批量提炼，`/analyze-new-ideas` 当批已把该移的都移了；此后无新的裁决输入。
- **归集 10 条「主题文档里有、分片里没有」的漏网项**（本技能的主要产出）。它们各自在主题文档中登记已久，却从未进过跨 session 清单 —— 也就是说**下一次 session 拾起清单时看不见它们**：
  - `01-combat.md` **+2**：战斗内运行态的决策点存档形态（`Power` 触发计数 + `PlayerItem` 剩余次数，须与战场条目一并落定）· 更高境界的 mana 基线是否跃升（`lifeTotal` 已定为境界跃升，mana 尚未表态，**两者分工不同不能类推**）。
  - `02-event-options.md` **+1**：选择区的呈现与导航手感（批次规模 1–5，两端差 5 倍，竖屏排布未落定）。
  - `03-adventure-event-types.md` **+1**：是否为「购买次数」设一个 `StatKey` 成员（轻，不统计则零依赖）。
  - `05-service-contracts.md` **+2**：refresh token 的客户端持有形态（**硬约束已成立**——不得与 `device-id.json` 合进同一文件）· flags 拉取的频次护栏。
  - `07-codex-monetization.md` **+1**：平台内购 SDK 的选型与封装层（三渠道已纳入 MVP，是客户端唯一必须引入第三方 SDK 处；**购买段在 SDK 落定前无法落地**）。
  - `deferred-content.md` **+3**：jade 获取渠道与掉落权重（**承重**——它卡住商店定价表的全部绝对数字）· `RelicData` 字段清单与触发器体系 · `PlayerItem` 种类目录与次数补充机制。
- **合并 1 条**：`deferred-content.md` 的「各 `ERR_*` 与四条兜底文案的逐条措辞」并入 `reasonKey` 二级措辞 —— 三者同为「结构已定、只欠中文文案」，同一处定稿，分列徒增条目。
- **`deferred-content.md` 的「尚未设计」小节整体重写。** 原表把 `account-info.md`（08-16 收口）· `game-setting.md` 与 `codex/common-properties.md`（08-19 收口）· 四类非战斗事件子类型（08-17 机制面全部收口）仍列为「空占位、尚无成形问题」——四处均已过期。改为只留两处真占位（`character-profile/item/common-properties.md` · `player-profile/player-item/common-properties.md` + `achievement/`），并单列一条「已不再适用的占位登记」说明它们欠的是**条目目录而非设计**。
- **`01-combat.md` 的 `RarityTier` 一条补齐取池余量**：由「`GrantPoolMargin` / `K`」扩为**三格**（另有 `ResearchPoolMargin` / `ExchangePoolMargin`），并带上 `balance.md` 的「可先填 0 而不阻塞落地」。
- **`update-log.md` 溢出裁剪**：本条写入前已有 12 条，超「只留最近 10 条」的上限。最旧三条（`2026-08-16i` · `2026-08-16j` · `2026-08-17`）**一字未改**移入 `update-log-archive.md`（按时间正序追加）。当前 10 条。
- **未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。

### 主题文档的 9 处修平（用户当场授权，覆盖本技能「不改主题文档」的范围守则）

对账查出的 9 处问题逐条报告后，用户裁决「更新过期登记和决策混入 · 问题 8 按慷慨度已定案 · 问题 9 补登回去」，据此改了 **9 份主题文档**：

- **过期登记（答案早已定，只是没回头划掉）—— 5 处：**
  - `systems/adventure-event/combat/_index.md` 删「效果关键字体系与目标规则（承重）」——已于 08-16c 收口。
  - `systems/balance.md` 删「成本类型的 element 清单与数值分档未定」——已由 08-16d 成本侧收口 + 08-19 `CostKey` 15 成员覆盖；两处定价表条目已各自承载剩余的数值面。
  - `systems/enemies/_index.md` 改写「敌人 AI / 意图规划逻辑」——原文写着「**回合级一次性规划已定**」，而该约束早随 08-15d 意图机制整条移除而**解除**。`combat/_index.md` 与 `combat-service.md` 当时都改了，唯独此处漏改，是三处同源表述里最后一处未同步的。
  - `systems/services/life-cycle-service.md` 改写「元进程持久化范围」——`AccountInfo`（08-16）· `GameSetting` 与 `CodexEntry`（08-19）三块字段面均已收口，改为只留 `Achievement` schema、`PlayerPower` / `PlayerItem` 的触发、`PlayerPower` 平衡边界三条。
  - `systems/character-profile/power/_index.md` 改写「写入面与存档形态」——持有列表（`CharacterProfile.characterPower` 字段 13）与写入通道（`AbilityElements` 经 `TryApply`）已于 08-17h 定案，条目收窄为**只剩 `status` 开关的存档表达**，并回链 `profile-service.md` 的同名待决项。
- **决策混入待决区（形式问题）—— 2 处，均为「移到 `## 决策(-> ADR)`」而非删除：**
  - `systems/adventure-event/combat/_index.md` 的「平局」（`CombatOutcome.Draw` 规则 + Practice 档 `Draw` 永不可达的退化）。
  - `systems/character-profile/deck/_index.md` 的「出牌费用 = mana」（每回合恢复至 `manaLimit`、不结转）。
- **问题 8 按「慷慨度已定」定案 —— 2 处：** `combat/_index.md` 删掉「敌人图鉴的慷慨度是否该上调」这条待决项，并在其 `## 决策` 补一行；`codex/enemy-codex.md` 的 `## 决策(-> ADR)` 同批补上**慷慨度 + 退让阶梯**一行。**该文档正文本就完整载有这条裁决**（三条理由 + 「加厚 ③④ → `KeyCardIds` 上界 3→5 → 才考虑全表」的阶梯），只是从未上升到决策清单，于是 `combat/_index.md` 一直照旧把它当未决 —— 典型的「正文已答、台账未同步」。
- **问题 9 补登回主题文档 —— 3 处（权威归属归位）：**
  - `systems/services/sync-service.md` ← **上行整键回声校验的适用面未穷举**（承重；`accountInfo` 是与 `entitlement` 同形的第二处，缺封闭清单则逐键临时判必漏，漏掉的那处即客户端静默改写后端权威字段的口子）。
  - `systems/architecture.md` ← **`architecture.md ↔ services/*` 的对账**。**明写为「台账事项 · 不阻塞 derive」**：本文件设计面无未决项，对账不产出 FR、不构成任何 derive 前置。
  - `systems/player-profile/player-power/_index.md` ← **「失去法则」三支的频次预算需重新配平**（`IgnoresProtection` 由 1% 上调至 ≈5% 后单支已吃掉三类合计的全部预算）。
- **删除「效果关键字体系」一条牵出的悬空引用 —— 顺手修 2 处。** 该条删除后，两处仍写着「阻于它」：`systems/services/future-event-service.md` 与 `open-questions/02-event-options.md` 的 `EventOutcomeSpec` 内部字段面。两处均改为**指向 08-16c 的收口权威**（`KeywordData` + target / scope 分离 + `EntryFilter`）并**明标「阻塞来源待重新确认」**——**没有替用户宣布它已解除**：若确已解除，该条就只欠自身落笔、可单独排专场，这是一个需要用户拍板的排期判断，不是对账能代做的。
- **⚠ 连带影响需 `/assess-derive-readiness` 重估：** `systems/architecture.md` 的 `## 待决问题` 由「当前无未决项」变为一条台账事项，而就绪度表当前判它 **ready**。该条已按不阻塞 derive 的口径落笔，但**判定权归 `/assess-derive-readiness`**，本次未动就绪度小节。

## 2026-08-19b（`/write-adr --game` · 全量固化 · 新建 19 份 ADR · 候选清单清空）

- **范围**：客户端库全量候选——`open-questions.md`「下一阶段」两条 + 散落在七份主题文档 `## 决策(-> ADR)` 小节里的 17 条「ADR 候选（待固化）」。逐条回主题文档核对「事实是否已落地」，**19 条全部查有实据**，无一条判为查无实据或矛盾。
- **新建 `ADR-0006` ~ `ADR-0024`**（19 份）：开发顺序 · 内容载体形态 · 五级层次词表 · 两条唯一入口 + 编排顶点 · 展示层三层切分 · API 契约总则 · 物化模型 · 纪律可执行化阶梯 · PlotManager 隶属 · 剧本树数据形态 · 隐藏属性档位模型 · capability flag + modifier pipeline · 道念计分模型 · 卡牌类型五分与战场划线 · 事件事务纪律 · `pastEvent` 痕迹 schema · Research 构筑面板 · 付费凭证与兑现 · 内购三渠道纳入 MVP。
- **分组上的一处刻意偏离**：`plot-manager.md` 三条候选原注「宜与内容载体形态候选合并固化」。按「能否被单独推翻」判据拆为三份——剧本本地内容层与 overlay 剧本例外并入 `ADR-0007`，档位模型（`ADR-0016`）与剧本树数据形态（`ADR-0015`）各自单列，两者均可在不牵动内容载体形态的前提下被推翻。
- **`decisions/_index.md`**：新增 19 行，全表按日期降序重排（同日按编号降序）；台账 ↔ 文件无不一致需修平。
- **`open-questions.md`「下一阶段」的 ADR 段落改写为一行状态**：候选清单清空，指向 `decisions/_index.md`。该小节其余三条（流水线闭环 / 架构闭环缺口）与其他小节一字未动。
- **主题文档未改**：各 `## 决策(-> ADR)` 小节里的「ADR 候选（待固化）」标注仍在原处，改指到具体 ADR 号属主题文档写入，不在本技能范围内 —— 留给下次 `/analyze-new-ideas` 或 `/summarize-open-questions` 清理。

## 2026-08-19（`/batch-analyze-new-ideas` · 10 份 `decided` 草稿一次清完 · 移出 20 条 · 新增 2 条 · **跨库**）

- **来源**：`inbox/` 顶层全部十份 `status: decided` 的 solution-draft —— `CostKey`/`StatKey` 注册表 · `ProfileChangeSpec` 载体缺口 · `CodexEntry` schema · `GameSetting` schema · `BundleGrantOrdinal` 施加权 · `architecture.md` 结构残留 · `deviceId` 供给 · 拆解粒度与签核 · 英文占位形态 · `PickMany` 短缺处置。产出 `handoffs/2026-08-19-*` 十份 + 后端 `2026-08-19-breakdown-granularity-and-signoff.md`。逐条移出记录见十份 `../answer-logs/log-*.md`。
- **合并 interview 48 项裁决，全部取推荐项。** 十份草稿虽都已由用户逐条评审至「取向零剩余」，Phase A 交叉校验仍查出 21 条与既有权威相抵或草稿自相矛盾的硬冲突。要紧的几条：
  - **兑现循环写错会付两次拿一份** —— `ordinal = BundleGrantOrdinal` 与「差值 > 1 时逐一按序兑现」不可同时成立（差值为 2 时中间序号永不兑现）。改 `ordinal = Redeemed + 1` 循环；「差值 ≤ 1」的不变式只保证单设备，挡不住两台设备各自付款。
  - **`Project` 的签名借错了档** —— `bool TryProject(..., out ...)` 是「可选缺失」的形状配「必需缺失」的严重度，全库无先例。改 `PlayerProfile Project(spec)` + `PushError` + `throw`。
  - **战斗内逐点提交会把约 31 份完整 `ActiveCombat` 块灌进 `AppliedChange`**（2–4 KB/份），与痕迹侧只存轻摘要的体积纪律正面相抵。明写累加时的列剔除清单。
  - **闸③的「另取一条填补批次」就是单项补位**，直接推翻 `future-event-service.md` 明写的「不设单项补位」。整条作废，抽不足即本批少一项。
  - **`SettingAssignment` 的失败语义不可机械检查** —— `bool` 缺省 `false` 与合法 `false` 同形、`int` 缺省 `0` 与合法 `0`（静音）同形。改 `int?` / `bool?`。
  - **退避公式 `±20%` 会以 0.8× 击穿服务端下界**，改为只向上抖 `× (1 + rand[0,0.2])`。
  - **草稿的一条承重理由是假陈述** —— arch 草稿称「纪律 7 至今无主题文档承载」，实则 `common-properties.md:202` 逐字载有。新建 `viewmodel.md` 的结论不变，但该假陈述不得按「保留理由」写进活文档。
- **跨草稿矛盾（逐个跑发现不了，本批独有）**：game-setting 的「`en` 列全部预设占位符」与 translation 的「`en` 留空、不写哨兵值」直接相抵，而两份都要写 `ux/error-and-blocking-ux.md`。统一取留空口径。另有三处共写面按单写者收口：`terminology.md` 的 `ProfileChangeSpec` 列枚举（四列一次加齐）· `sync-service.md` 的 schema bump（**全库只此一句**，涵盖四个新增列与两个子对象 schema）· `AtomicJsonFile` 共享工具（本体登记 `systems/architecture.md`）。
- **新增待答 2 条**（均落 `05-service-contracts.md`）：上行整键回声校验的适用面未穷举（`accountInfo` 是与 `entitlement` 同形的第二处）· 做一次 `architecture.md ↔ services/*` 的待决问题与投影表对账（本批已发现两个过期登记实例）。
- **松动的既有定案两处**（用户知情后批准）：pickmany 的「零 UI 改动、零文案键」为 reroll 前置校验松一格；breakdown 的软下界由「L1~L4 合取」改为「L1 ∨ L2 触发、L3/L4 降为辅助信号」。另按授权直接改写 `decisions/ADR-0005`（归属判据入 ADR，未新开取代 ADR）。
- **`systems/architecture.md` 的「待决问题」现已清空**（本批多个分片各清掉几条）。`user://cache/` 的 schema 版本要求由全称改为判据形态，三处同源措辞（含 `.claude/rules/state-save-rules.md`）同批改齐。

## 2026-08-17h（`/batch-analyze-new-ideas` · 5 份客户端草稿 + 1 份后端 counterpart · 移出 11 条 · 新增 9 条 · **跨库**）

- **来源**：`inbox/` 的五份 `status: reviewed` solution-draft 一次清完 —— element 载体缺口 · 两层 Profile 字段 schema · `EventOption` 物化字段清单 · 派生实例落存档 · 抽取原语与物化实例形态；对侧 `backend-design-documents/inbox/solution-draft-profile-field-schema.md` 同批纳入。产出 `handoffs/2026-08-17g` ~ `2026-08-17k` 五份 + 后端 `2026-08-17-profile-field-naming.md`。逐条移出记录见五份 `../answer-logs/log-*.md`。
- **一场合并 interview 共 28 问（🔴 8 · 🟠 19 · 跨草稿矛盾 1），分 7 轮问齐，用户逐题裁决。** 批量的独有价值兑现在三处**逐次运行发现不了的跨草稿矛盾**上：
  - **`PlotModulation` 六字段 vs 删为五字段。** 抽取原语草稿评审时裁了「删 `EnemyPoolScope`」，理由是「无用例」；而 `plot-manager.md` 逐字写着一个用例（剧情线 boss「派心魔 / 煞气化身**而非**常规敌人」——「而非」是排他语义），且物化字段草稿的复核结论正是「六字段不变」。**用户据此推翻了自己评审阶段的「删」**，改为保留字段 + 加载期悬空校验（把「静默换池」变成「大声报错」）。
  - **「敌人实例全库只有一份副本」这条依据被同批另一份草稿推翻。** 派生实例草稿裁定 `activeEvent` 持**整份快照** ⇒ 嵌套的 `Encounter` 必然同时存在于当前批与 `activeEvent` 两处。结论（嵌套）保留，**依据重写**，并新增一句「结算期以 `activeEvent` 为权威」。
  - **`activeCombat.enemyRef` 是一个双方都以为对方在答的洞** —— 字段 schema 草稿写「归抽取原语那片答」，而那片没答。本次定为 `EnemyInstance.InstanceId`，经 `activeEvent` 比对。
- **两条承重纪律的正面冲突用新增设施化解，而非改写任何一条。** 「一个事件的收口是一次事务、一个存档点」与「依**更新后**的 profile 重算、`pastEvent` 是一等输入」在收口那一刻互相顶牛：新一批塞进同一次 `TryApply` 只能算在尚未落账的旧 profile 上，拆两次提交又破前者。裁决取**只读投影 `Project(spec)`**（先算后提交），两条纪律一字未动。
- **本批新增的最大一块承重正文：`architecture.md` 的「三级判据」** —— 「一个新的施加语义该落在哪里」自上而下三问（① 分列 ⟺ 六面核对全不对齐 / ② 加 `Op` ⟺ 同族但方向或形式不同 / ③ 配表加列 ⟺ 该性质是 element 类型的属性），附反判据「同一 key 的不同次变更可能取不同值 ⇒ 必须逐条带；唯『谁有权改写它』永远配表」。它约束此后所有 element 形态问题。
- **结构增量汇总（一次 bump、空迁移）**：`ProfileChangeSpec` 5 → **7 列**（`PlotElements` + `EventStateChanges`）· `ChangeElement` 增 `ApplyOp Op` · `ElementSpec` 增第六列 `AllowedOps` · `DeckChangeOp` 4 → 5 值（`AddLooseCard`）· `EventOption` 11 → **13 格**（`OutcomeSpec` + `Encounter`）· `PastEventEntry` 增 `EnemyTraceRef` · `CharacterProfile` 增七格（五个新字段 + `eventOption` + `activeEvent`）· `PlayerProfile` 六 Codex 具名字段与四类持有条目定形 · 新登记枚举 `Realm` / `ApplyOp` / `ApplyOps` / `PlotArcState` / `EventStateKey` · `CostKey` 增 `Experience` / `Faith` / `Bloodlust`。
- **跨库对称落笔（这是本批解除「拆两次运行、第二次经常不发生」那条老账的一次实践）**：客户端裁定「集合字段名全库统一为单数」并把条目键名收口为 `powerId` / `itemId` ⇒ 后端同批改 `contracts/profile-sync.md` §5 白名单与排除清单四条路径 + 新增 §5b 命名通则与**一次性切换的三个成立前提**（线上无真实账号数据 · 两侧同批落笔 · 一次性不设兼容期）+ `schemaVersion` bump。**单数通则的适用边界一并钉死**：受约束的只有两层 Profile 及其子对象的**存档字段名**；`characterDiffs` / `playerDiff`（diff 报文结构）与运行时 / 内容侧集合属性**不受约束**。**§6 算法与 §6a 的 8 组测试向量零改动**（已三重自查）。
- **两处既有漂移顺手修**：`terminology.md` 的 `ProfileChangeSpec` 词条此前只列到 4 列（连 `DeckElements` 都缺）· `achievement/_index.md` 写着「日后全库统一把集合字段改为**复数**」的预言，与本次方向相反。另 `combat-service.md` 一句错话（把 `currentMana` 也说成「战斗内不变」）一并改正。
- **移出 11 条**：`01` 分片 2 条（统一抽取收口 · `PoolScope` 数据形态）· `02` 分片 3 条（完整物化字段清单 · 派生实例落存档 · 物化后敌人实例类型形态）· `04` 分片 1 条（`PlotModulation` 字段面）· `05` 分片 4 条（`ApplyOp` 列 · 散牌入组载体 · `plotKeyPoint` element 形态 · 道心 / 煞气入 `CostKey`）· 后端 2 条（切换时序 · `ordinal` 口径确认，其中后者零改动关闭）。**收窄 3 条**（`RarityTier` 只剩数值面 · `Priority` 只剩抬升条件 · 角色模板池只剩取值面）。
- **新增 9 条**：`01` 分片 1 条（敌人池的篇章框定载体）· `02` 分片 4 条（`EventOutcomeSpec` 内部字段面 · 投影设施形态 · `PickMany` 不足 `count` 的调用侧处置 · `lifeSpanCost` 定值待复核）· `05` 分片 4 条（`BundleGrantOrdinal` 由谁施加 · `activeCombat` 写入通道 · RNG 写入通道 · `pastEvent` 无 spec 列）。**后三条是同一形状的缺口**：「有纪律、无通道」——本批只补上了 `activeEvent` 那一处。
- **七个 `[采纳推荐 — 待复核]` 项全部留在待答清单**（分散在 `02` / `05` 与各 handoff 的 Open questions 节）：它们是用户以「取推荐项」方式定下的，按纪律不当作拍板。
- **未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。

## 2026-08-17g（`/analyze-new-ideas` · 移出 1 条 · 新增 1 条 · 单库）

- **来源**：`inbox/solution-draft-lifespan-gain-paths.md`（`status: decided`）→ `handoffs/2026-08-17f-lifespan-restoration-paths.md`。移出记录见 `../answer-logs/log-lifespan-gain-paths.md`。**跨库复核结论：不跨库**——寿元与 `magicPack` 均落在 `characterProfile` 内，而 `contracts/profile-sync.md` 把 `characterDiffs` 整体划为不透明段；本次不新增任何 `Source` 成员、不触及唯一的透明路径 `/playerPowers[*]/sourceCode`。不写对侧库、不立承接项。
- **四项取向一律取推荐项**（草稿以 `decided` 进入）：① 回寿**收紧为只走 outcome 侧** · ② 回寿数字与 `selectCost` **同 Band 2 门控** · ③ 回寿量中档取 **10%** · ④ **接受**「不设每篇章回寿总量硬上限」。
- **草稿自陈的唯一硬冲突已按裁决改写三处现有文本。** `systems/adventure-event/common-properties.md`（两处）与 `systems/balance.md`（一处）原明写「内容条目可标产出向（回寿）的覆盖值」，即把回寿放在 `selectCost` 成本侧；现改为**成本侧的 `LifeSpan` 取值域收紧为非负**。**代价如实落笔**：内容作者少一个书写位——「一个便宜又回寿的事件」要写成「表值定价 + outcome 侧产出」两处，而不是在定价格里写个负数。（代价很小：定价表本就默认不填、取类型基准值，作者的默认动作不变。）**最硬的理由是规则层的**：成本侧回寿会让「`TryApply(SelectCost)` → 立刻判负 → 短路」这一步从压力点变成救命点，「明知是死路仍然走」这条承重取向被一个内容条目的符号翻转悄悄取消。
- **新不变式与前两条形状不同，明写不合并。** `AbilityElements` / `DeckElements` 恒空是「某个列表恒为空」；本条是 `Elements` 内某个 key 的**取值域**收紧（成本侧 `Elements` 本就非空）。三条各自一处断言 + 一处加载期校验。
- **展示门控 = 寿元档位表的第六个消费方**，判据仍是「寿元 Band == 2」，与红字倒数、`selectCost` 精确展示同一个开关。道具描述的门控形态一并定下：**正文恒为定性文案，精确值由 UI 在 Band 2 追加一行**（`LocalizedText` 做不到按 Band 变体；数值取自 ability 定义、不进文案，翻译侧不必写两版）。
- **本次自行推演并落笔三项**（依据既有承重纪律，非草稿原文，已在 handoff 的 Clarifications 中标名）：
  - **`PowerData` 不得含 `LifeSpan` 产出**（两个 `Scope` 皆然）。草稿只关了 `(Item, Player)` 一半，但礼包同时给 1 条随机法则，且 `PowerData` **没有 `Charges` 字段** ⇒ 一条能产寿元的能力条目是**无次数上限的回寿源**，比古宝更彻底地架空时长旋钮。
  - **Travel 条目不得带回寿产出。** 裁决 ④「不设硬上限」的依据是两道软闸，而 Travel **不计入 `eventCountLimit`** ⇒ 软闸「占配额」对它整条失效，只剩定价最低一档的那道，等于开出「来回横跳换寿元」——与「Travel 那一格必须 > 0」要堵的零成本 reroll 是同一个漏洞的两半。**这是被接受的护栏的边界条件，不是新加的限制。** Explore 遮罩的情形自动覆盖（真身本身就是 Travel 条目）。
  - **中档 10% 的回滞校验。** Band 1 的退出阈值 = 10% + δ 3 = 13% < 15%，故「Band 2 中位一颗丹拉回一档」在回滞下仍成立——裁决 ③ 的手感目标经校验为真，不是口头断言。
- **草稿的一条前置依赖已随同日 Exchange 专场消解。** 草稿写「通道 C 阻于 Exchange 专场未开」；该专场已落地，故补天丹被落笔为 `ExchangeGoodsKind.CharacterItem` 一族的普通商品，走既有购买路径（`ChangeElement(Jade, -ListPrice)` + `Grant` 携 `Source.ExchangePurchase`）与「族 × 稀有度」定价表，**零机制增量**。
- **与 Research 的 `Recuperate` 明确区分**并写进文档：后者回复 `lifeTotal`（战斗耐久），本次回复 `lifeSpan`（寿命预算），两者在 `ResourceElements` 表里各占一行、终态原因各异。
- **本次零结构增量**：不加字段、不加 element、不增 spec 列、**不 bump 存档 schema、无迁移**；事务纪律与 `AppliedChange` 语义一字未动。**未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。
- **移出 1 条**（`04` 分片）：非境界突破的寿元增长途径。**新增 1 条**（落 `03` 分片的道具那一路，同时登记在 `systems/character-profile/item/_index.md`）：**战斗外道具的使用入口未设计**——它阻塞回寿法宝定稿，并连带两问（是否单独构成存档点；在事件之外使用时没有 `PastEventEntry` 可挂，寿元曲线会出现一段无痕迹的回升）。

## 2026-08-17f（`/analyze-new-ideas` · 移出 2 条 · 新增 0 条 · 单库）

- **来源**：`inbox/solution-draft-combat-finale-and-hidden-attributes.md`（`status: decided`）→ `handoffs/2026-08-17e-finale-combat-only-and-hidden-stat-io.md`。移出记录见 `../answer-logs/log-combat-finale-and-hidden-attributes.md`。**跨库复核结论：不跨库**——本次全部落在客户端本地的内容编排与结算参数上，隐藏属性字段在 `contracts/profile-sync.md` 里属 `characterDiffs` 不透明段，后端零可见；不写对侧库、不立承接项。
- **本次的定案推翻了草稿的主体方案，方向是「关掉一个尚未存在的分支」。** `/provide-solution-draft` 原推荐「非战斗 Finale 仍是 Combat 类特例、载体为 `EncounterSpec.Trial` 可空字段 + 抉择链形态的试炼」，用户定案 **不存在非战斗形态的 Finale、也不存在非战斗试炼**。故 `EncounterSpec` 与 `CombatEventResolver` **一字未改**，连带关掉四样尚未存在的分支：`Enemy` 不必放宽为可空（「无敌人的 Finale」这一分支从结构中消失，`TurnLimit` / `FirstSide` 恒有意义）· resolver 无内部分派 · 不新建 `TrialOutcome` / `TrialResult`（那会连带出第二套奖惩换算、第二套残卷判定、第二条失败通道）· 危险度刻度三档无例外。被否决方案的完整论证保留在草稿的「备选方案」一节，不进活文档。
- **`eventType == Combat` 的命名张力随定案消失**，原草稿为它准备的口径澄清句**未写入**——非战斗形态不存在，Combat 类的每一条都真的动手。
- **隐藏属性从「产出侧全开」扩为「输入与输出两侧全开」，仍是零新增机制。** 输入经**调制通道**（Band 触发 arc → `PlotModulation` 六字段）与**结算输入通道**承载。**承重限定已明写：这不等于把隐藏属性接进胜负判定**——`VictoryRule` 仍是单字段，影响路径是**拧参数**（更凶的天劫模板、更高的 `WinMargin`、更差的起手）而非**加一条并列的判定条件**。**「输入」不含「作为 `selectCost` 消耗」**（用户已确认）：成本侧只放可如实计价的量、且道心 / 煞气触底不构成终态故没有消费者 ⇒ `selectCost` 的 element 清单仍只有 `lifeSpanCost` 一项，**「道心 / 煞气是否列入 `CostKey`」那条待答项不受本次施压、原样保留**。
- **推拉口径：一份 `HiddenStatGrade`、胜负同施、不套 `FailureRatio`。** 判据是语义差异而非对称性偏好——经验的语义是「学到多少」（失败也学到，折算说得通），隐藏属性的语义是「做了什么」（屠戮就是屠戮）；且比率对双向的道心无从解释。日后若要让胜负推不同的量，落点是内容侧第二个**可空档位字段**（不牵动存档迁移），不是一个比率。三档默认口径：`Practice` 推道心 · 对位低一档 · 不推煞气；`Standard` 逐条目编排；`Finale` 胜负都推道心。
- **剧情线不转入 `Finale`**，四条理由中第一条是致命的：「每角色每篇章至多累积一次或掷骰一次」这条残卷不变式的**唯一支撑就是「每篇章一个 Finale」**，第二个 Finale 会让「残卷不需要任何冷却 / 次数上限规则」的豁免当场失效。替代形态 = 被 `PlotModulation` 拧过的 `Standard` 档 Combat（六个字段刚好凑齐一个「剧情线 boss」），**代价明写：不给残卷、不是篇章闸门、失败不影响境界突破**。
- **顺带更正一处清单前提**：待答项把「大限将至」当作隐藏属性剧情线的例子，但它对应**寿元归 0 的终态**、不经 `PlotTriggerId`——寿元归 0 时角色已 `defeated`，**没有任何东西可以转入**。真正经 `PlotTriggerId` 的只有煞气 Band 3 与道心 Band −2 两条。措辞已修正。
- **本次零结构增量**：不加字段、不加枚举成员、**不 bump 存档 schema、无迁移**；`EncounterSpec` / `CombatEventResolver` / `EventOutcome` / `CombatOutcome` / `PastEventEntry` / `PlotKeyPoint` / `PlotModulation` / `ProfileChangeSpec` 一律不动。**未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。
- **移出 2 条**（均在 `03` 分片）：非战斗形态的 Finale · 各档与隐藏属性的交互。后者**部分留下**——「隐藏属性的增减触发」与 `HiddenStatGrade` 映射值仍待答，条目收窄措辞后留在原分片。**本次不新增待答项。**

## 2026-08-17e（`/analyze-new-ideas` · 移出 4 条 · 新增 4 条 · 单库）

- **来源**：`inbox/solution-draft-exchange-mechanics.md`（`status: decided`）→ `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md`。**单库运行**，但**跨库判定是本次独立复核过的**：`Source.ExchangeSell` 只落在 `(Item, Character)` = 轮回级法宝上，而后端契约把 `characterDiffs` 整体划为不透明段（不递归、不比对、不校验），透明路径只有 `/playerPowers[*]/sourceCode` 一条且服务于 `x = count("FinaleWin")` 的复算——新成员对后端零可见，`AppliedChange` 同理（后端明写不重放它）。故不写对侧库、不立承接项。移出记录见 `../answer-logs/log-exchange-mechanics.md`。
- **本次最重的落点是两条全局纪律的改写，适用面不限 Exchange。** ①「一个事件 = 一次事务 = 一个存档点」→ **「一个事件的收口是一次事务、一个存档点；事件内部的主动消费即时提交」**。它统一的是三个**已经存在**的实例（古宝使用次数 · 战斗内血 / mana · Exchange 逐笔交易），旧措辞与前两者本来就对不上；`profile-service.md` 与 `adventure-event/common-properties.md` 两处承载点**同改**，另有 life-cycle-service 数处引用句一并改——留一处旧措辞就是留一个第二权威。同时补上**两条判据**（是玩家主动按下的消费 + 不即时写就开出「退出重进即回滚」的窗口或分裂出影子余额），使「哪些该即时提交」可判定而非逐例特批。② `PastEventEntry.AppliedChange` → **「本次事件的最终账」**，由 life-cycle-service 把逐笔已提交的 spec **累加**进去（**记账，不再施加**）。**代价一并写进文档、未省略**：它不再与「收口那一次 `TryApply` 的入参」逐字段相等，一致性**不能再机械断言**；可重放性不受影响（element 只承载已定稿 `Id`）。
- **售出定案推翻原推荐：开放售出，但仅 `CharacterItem` 一族，且准入是代码级常量判据。** 不做成内容可配的族白名单——内容侧若能逐条目开族，一个填错的条目就打开一条本该封死的通道，而校验无从判断作者是不是故意的。条目侧保留 `SellEnabled` / `SellRatePercent` 两个字段。**原三条反对理由逐条记账**：卖卡 = 第二条弃卡通道 → 已消解（卡组增删仍唯一归 Research）· 古宝被贱卖 → 已消解 · **储物袋 9 格从纯取舍位变成可换灵玉的位置 → 仍然成立，且正落在被开放的这一族上**，已在 `character-profile/item/_index.md` 明写接受，缓解只靠两个旋钮（回收率 30–50% · 折算基准取定价表基准价而非 `ListPrice`，否则「在打折商店卖东西更亏」读不出因果）。连带新增 `Source.ExchangeSell`（code 8），它是清单里**唯一一个只出现在 `Op == Remove` 上**的成员，合法子集表只对 `(Item, Character)` 开 ✅。
- **交易机制本身几乎全部落在既有结构上。** 不开第三个 resolver（拆分轴是「有没有状态机」，Exchange 没有）· 库存在物化阶段经既有 `RngStream.Shop` 子流掷定并落存档 · 五个商品族一一映射到既有仓储、**不新建任何抽取池** · 定价走「商品族 × 稀有度」统一表（与 `lifeSpanCost` 表同构，**不设篇章维**——灵玉每章重置，篇章差异该由掉落量承载）· `ModifierKey` 增 `ShopPrice` 且**在物化侧施加**，故 `Jade` 的两个修正列恒为 `null`（「一个 `ModifierKey` 只能有一个施加点」，双施加会让玩家看到 80 实扣 64）· `EventOption` 骨架九字段 → **十一字段**（`ExchangeStock` / `RerolledCount`）。**NPC / 势力降级为风味层、零新增字段**：好感度若有持久数值就是第四个隐藏属性，而 arc 的进度本来就是「关系走到哪一步」的离散表达。
- **新增待答 4 条**：`03` 分片两条（Exchange 的四组数值格 · 满袋时能否购买道具）· `02` 分片一条（**结算进行中的 `EventOption` 派生实例如何落存档**——Explore 揭示与 Exchange 刷新是同一个缺口，两者都必须在玩家可退出之前落盘，而实例是 immutable 定稿的）· `05` 分片一条（**游离散牌入组没有 element 载体**——`DeckChangeOp` 只有 `RemoveLooseCard` 没有增向，同时卡住商店 `Card` 族购买、战斗奖励单卡入组、事件负向奖励塞业障三条既有通道；这是 Research 专场留下的缺口，不是 Exchange 制造的）。
- **答结 4 条**：`Jade.CostModifier` 取值（恒 `null`）· NPC / 势力模型是否仍需要（不需要）· 道具定义与交易机制的切分（换成判据 + 两处重复登记收口为回链）· Exchange 通用结算器的数据形态。**bump 一次存档 schema**（`EventOption` 两个新字段，当前无线上存档 ⇒ 空迁移）· **不增 `ProfileChangeSpec` 的列** · **未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。

## 2026-08-17d（`/analyze-new-ideas` · 移出 4 条 · 新增 1 条 · 单库）

- **来源**：`inbox/solution-draft-explore-mechanics.md`（`status: decided`，四项取向一律取推荐）→ `handoffs/2026-08-17c-explore-reveal-mechanics.md`。**单库运行**：全部落点都是客户端的内容形态与呈现，后端零改动。移出记录见 `../answer-logs/log-explore-mechanics.md`。
- **收口要点 ①：「揭示池权重」被证明不是一个机制，而是既有抽取链路的涌现结果。** 「遮罩的是一个**固定**条目」一旦成立，运行时就没有任何一个时刻可以掷这个权重——揭示阶段读的是模板上写死的 `RevealedEventId`。故**三处数据类一律不加字段**（`AdventureEventData` 无 Explore 权重字段 · `LocationData` 无 Explore 子权重行 · `PlotModulation` 不出第七个字段）。由此三档调制能力**不对称且明写接受**：location 只到类型级（「洞天多秘境」可、「洞天的秘境多半是战斗」不可）、剧本靠对单条 Explore 条目加权（既有能力零改动，落在**内容面**而非约束面）、篇章不设旋钮。**剧本只能间接调分布恰好合规**——若另设「真身类型权重」字段，剧本一旦能改它就等于隔着遮罩改写玩家实际面对的类型分布而玩家全程无感。
- **收口要点 ②：唯一的行为面新增是一条取池期过滤——真身 `ContentEnabled == false` ⇒ 该 Explore 壳不进候选池。** 这是本草稿捞出的一处**真实漏洞**：线上关掉一个坏掉的 Combat 条目后，指向它的壳仍在 `AllEnabled()` 池里（壳自己是 enabled 的），玩家照常付费、揭示后落到被关闭的条目上（读取侧不过滤，能解析不崩）——**放量开关对这条路径静默失效**，正是「能上线、线上不可见」那一类。**它是抽取侧过滤，不违反「读取侧不过滤」纪律**（`pastEvent` 回溯与图鉴解析照常解析 disabled 条目）。**代价如实记：** 关掉一个 Combat 条目会连带压低 Explore 的出场率——这是正确方向，坏掉的事件不该靠遮罩偷渡上场。否决的替代「揭示后降级为空结算」会让玩家付了费什么也没发生，并在痕迹上留一条诡异记录。
- **收口要点 ③：揭示 = `eventStart` 内一次 `with` 派生，resolver 按真身选取而非按 `EventOption.EventType`。** 后者恒为 `Explore`，照它选会把一个战斗真身送进 `GenericEventResolver`；这与「resolver 的拆分轴是有没有状态机」以及 `Source` 的「按谁组装判」是同一条判据的三处应用。`IsRevealed` **保留不删**——当前批落存档，退出重进后呈现层要靠它判断「这一步已经揭示过了」。
- **收口要点 ④：呈现侧三条同时定。** 遮罩卡**与其余 eventOption 完全同构**（异形卡会把「未知」读成「特殊奖励」，而秘境有一半概率是一场架，且破坏横滑区等宽节奏）· 揭示是一层**全屏覆盖层**（不进屏幕栈、无确认按钮、全屏任意触点跳过、不做二次揭示分层）· **部分线索完全不给**（机械的危险度档等价于把真身类型印在卡上，Explore 会退化为换皮的 Combat 标签；那个表达位已让渡给文案与美术）。
- **明写接受一处张力：** 「精确展示敌人等级让越级挑战可主动选择」在 Explore 路径上失效。**这不是缺陷，正是元类型的定价**——补一条「秘境内战斗不得越级」等于用规则抹平风险，且会成为 `±2` 带那条无例外硬规则的例外。
- **新增待答 1 条**（落 `03-adventure-event-types.md`）：Explore 的两个待实测初值——真身占比 `5:3:2`（归 ch1 数值标杆专场）与转场时长 ≈ 1.2s（纯手感项）。**本次不替既有待答「寿元告警是否伴随音效 / 震动」拍板**，两者是独立问题。
- **顺带修三处滞后措辞**：`03` 分片仍把「遮罩下的成本呈现」列为 Explore 待答，而它已由成本侧收口那场答结；`adventure-event/common-properties.md` 与 `02` 分片仍写 `EventOption` 骨架「八字段」，实为九字段。**不 bump schema · 不新增服务方法 / manager · 对后端库零改动 · 未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。

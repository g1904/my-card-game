# 合并 interview 裁决（2026-08-22）

> **本文件中的每一条 = 用户当面裁决，优先级高于草稿原始措辞。** 与草稿冲突时以本文件为准，并在 handoff 的 `## Clarifications` 中如实记下它推翻 / 细化了草稿的哪一句。

---

## 一、Finale 重构（用户在 interview 中新提出，推翻既有设计 — 独立于任何草稿）

**F-0（裁决逐字）：** 「移除 finale 结算认定失败后存活的场景。finale 失败必死，章节立即结束，清除之前失败后存活的相关内容。」

**F-1 `DefeatReason` 表达方式** → **新增 `DefeatReason.FinaleFailed`（枚举四值）+ 显式旁路**。
终态判定原为纯查表驱动（遍历 `ResourceElements` 的 `DepletionDefeat` 列），而 Finale 失败不是资源触底、无对应 `CostKey`，塞不进表 ⇒ 必须在查表之外补一条显式旁路调 `DefeatCharacter(FinaleFailed)`。
**这是本次唯一的结构性新增，必须明写这个口子**，否则实现侧会以为照表走就行。枚举成员按既定纪律只增不删、code 不复用。

**F-2 Finale 档的判定** → **二值化：非胜即败。`Draw` 归类到胜利，但奖励为最低档。**
即：`d >= 0` → 通过（角色存活、篇章推进、境界突破），落在 `0 <= d < WinMargin` 区间时奖励取最低档；`d < 0` → 失败 ⇒ 角色终结。
**「奖励最低档」由既有规则自动兑现、零新增字段** —— 代入既定数值验算，该区间 `advantage` 上界仅 0.13 / 0.125 / 0.093，本就整体落在 `Tier.Narrow`（险胜档）。
`Draw` 在 Finale 档永不可达 ⇒ `CombatOutcome.Draw` 收为**仅 `Standard` 一档可达**。
**`Practice` / `Standard` 两档的失败语义原样保留，不要顺手扩到三档。**

**F-3 ch3 重试上限** → **维持 ∞ / 3 / 1（付费 ∞ / 9 / 3），不做任何补偿。**
`ADR-0004` 的 Consequences 需明写：免费档账号在终局的容错次数。
（注：用户做此裁决时判定线尚未下移；核查结论是该裁决在新语境下理由更强，无需复核。通过所需追分 ch1 8→5 / ch2 18→13 / ch3 33→25。）

**F-4 残卷写入顺序 + 失败扣血** → **明写顺序 + 照常扣。**
- **必须在 `life-cycle-service.md` 明写：残卷 `PlayerPowerFragment.Accumulated`（账号级写入）在角色终结提交之前完成。** 否则「Finale 失败累积残卷」这条承重机制在每一次失败上都会丢 ⇒ 100% 失效。**这是本次裁决最危险的一处隐性后果。**
- 那笔按道念差 1:1 扣 `lifeTotal` **照常扣**（合进 `eventEnd` 那一次 `TryApply`），只是不再是死亡判据。

**F-5 `WinMargin`** → **Finale 侧删掉该字段。**
胜负线固定为 0 后它在 Finale 已成死结构，最低档由既有 `Tier.Narrow` 承担。按本库已执行两次的判据（不可达的拒绝语义留在类型上会诱导后来者）直接删。
⚠ **连带：`solution-draft-priority-elevation-conditions` 把「下调 `WinMargin`」列为 Finale 抬升的退让位 —— 该退让位本身不再成立**，不是换个理由的问题，须整条改写。

**F-6 难度旋钮** → **不补新旋钮；在 `balance.md` 如实写下「Finale 的难度不再有专属旋钮」并指向替代手段**（敌人赋级带 / 天劫条目本身的强度 / 回合数）。难度校准归 ch1 数值标杆专场。
`PlotModulation.Tighten` 对 Finale `WinMargin` 那一项需换例或删。

**F-7 残卷与里程碑** → **四项照常 + 首胜照常置位。**
「残卷掷骰 + 发放 + `FinaleWinOrdinal` +1 + `LastRoll`/`LastEffectiveChance`」四项不可拆（后端契约明写「序号 +1 却不掷骰」会使其校验①稳定失败）；`Ch*FirstWinDone` 照常置位、首胜 100% 照常。
**这是唯一能保住后端零改动的选项。** 需明写代价：玩家可能用一次刚好打平兑掉一生一次的首胜里程碑。

**F-8 叙事** → **补一条「渡劫身死」定性文案**，复用刚被腾空的链路（`ResolveOutcome` → `eventEnd`，内容层 `LocalizedText`、启动期校验、overlay 只改不增）。
连带：`content-service.md` / `ux/_index.md` / `system-overview.md` / `ADR-0016` 四处「内容层举例」**保留 Finale 补白这个例子**（改为指向新的身死文案），不必换例。

> 完整受影响清单见 `questions-finale-death-rescope.md`（A 段 18 处必改 + B 段 6 处对称补写）与 `questions-finale-draw-as-win.md`（增量）。
> **三份 ADR 要动**：`ADR-0004`（实质推翻 Decision 第 4 条 + 补 Consequences）· `ADR-0002:42`（「整体保留」清单剔除「失败但存活仍完成篇章」）· `ADR-0016:29`（论据自足化，先例改指新文案）。
> **写入形态**：按根约定「活文档只保留最新设计」，删除「失败但存活」时不留任何「原 X / 已取代 / 曾经如此」的痕迹。`answer-logs/` 与 `handoffs/` 的历史记录不追改。

---

## 二、跨草稿合并裁决

**M-1 置换 / 禁用候选的掷定时点与承载形态**（合并 `event-outcome-spec` R5 + `remaining-event-decision-points` 🔴-1）
→ **前移到物化时掷定，落 `EventOption` 上的一个定稿字段**（形状与 `EventOption.ResearchSlots` 同构，仍走 `Reward` 子流）。
- **不是** `OutcomeRule` 增第四个 `Kind`。`OutcomeSpec` 的 `AbilityElements` 相应只承载物化时定稿的授予。
- 改写 `adventure-event/common-properties.md` L50–60 那张表的「候选何时掷定 = 结算时」一格。
- 顺带消掉「三个决策点面板掷定时点各不相同」这处既有不对称。
- ⚠ `EventOption` 加一个物化字段 ⇒ `remaining` 分片「零结构增量」那句须按此改写。
- **两个分片都受此裁决约束，落笔须一致**（W2 的 outcome-spec 与 W4 的 remaining）。

**M-2 跨库落笔** → **三条都写对侧承接项**（`backend-design-documents/`），两侧互相回链：
1. `echo-validation` 的后端半 → **只写承接项**，不写完整契约半（用户未选一并落笔那一项）。
2. `flags-throttle` → 「flags 回滚须以更高 `flagsVersion` 发布（回滚即前滚的 flags 对位条款）」。
3. `refresh-token` → 「静默续期使旧客户端可长期不经协议维度闸门，收口手段（滑动续期上限 / 强制 re-signin 周期）待定」。
- 对侧只写归属判给它的那一半，**不复述客户端语义、不替用户拍板它自己的取向问题**。
- ⚠ **`echo-validation` 两侧草稿都明写须成对采纳** —— 本批只落客户端半 + 后端承接项，须在报告与 handoff 中**显式标注这是未完成的成对采纳**，后端契约半仍待另跑一批。

**M-3 `AdventureEventData.ChapterScope` 的事件侧落笔归属**（orchestrator 编排决定）
→ 事件侧归 **`generation-weighting` 分片（W1）**；`enemy-pool` 分片（W4）只写 `EnemyData` 侧。

---

## 三、逐分片裁决

### future-event-generation-weighting
- **🔴-1 + 🔴-1.3 批次规模** → **N = 目标槽位数 + 收缩保底**。实际输出允许少于 N，只保底 `Count >= 1`；收缩到 0 时补一个 Travel（走既有死局兜底通道，**明写这不是单项补位** —— 不重新取池挑条目）；⑥ 步按各类型收窄后的可用条目数封顶。断言 `1 <= Count <= 5` + 保底路径显式化。`travel/_index.md` 的死局兜底扩写为两个触发面。
- **🔴-2 `PlotModulation.EventWeights`** → **松动既有措辞，与 `TypeWeights` 统一为乘性系数**（见 D-1①）。
- **🟠 全部按 worker 推荐**：事件侧 `ChapterScope` 取 (b)（照抄敌人侧处置 + 加事件侧启动期断言，粒度取 `(chapter, EventType)`）· 十步管线标明**仅常规批**、闸门批在 ① 之前短路 · `SelectionWeight` 落 `adventure-event/common-properties.md`。
- **连带输入（来自 priority-elevation 分片，必须落笔）：满级后 Finale 条目恒进候选池、不参与类型加权，写成「闸门式旁路」而非高权重** —— 在类型加权抽取之前判定，命中则该条目直接占一个槽位。理由：加权只能提高概率，抬升需要的是必现；旁路形态同时封堵「剧本把 Combat 排除出白名单即间接封死篇章推进」这条 PlotManager 越权面。

### event-outcome-spec-fields
- **R1 列数口径** → 承重句**不写列数**、逐列穷举断言；**并补齐 `architecture.md` 漏登的 `CodexElements` 一行**。
- **R2 白名单** → **排除 `ExperiencePoint` / `Faith` / `Bloodlust`**（只能由物化组装从档位表展开，`OutcomeRule` 写不出它们）。`FixedResource` 可写 key 收窄为 `LifeSpan` / `LifeTotal` / `ManaLimit` / `Jade`。
- **R3 `ManaLimit`** → 加一条加载期校验 + 一条物化断言：`ResourceKey == ManaLimit ⇒ Magnitude == 1`。
- **R4 古宝** → **正向白名单收窄**：`AbilityElements` 的 `(Kind, Scope)` 恒为 `Character` 作用域，`PoolKind` 能力族取值收窄为 `{ CharacterItem, CharacterPower }`，`PlayerItem` 直接拒绝。**事件产出不能给账号级古宝。**
- **R5** → 见 **M-1**（`AbilityElements` 只承载物化时定稿的授予）。
- **🟠 全部按推荐**：`DeckOp` 改用 element 层 `DeckChangeOp` 五值 + `GrantFromPool.PoolKind` 只含能力族 · `FailureRatio` 改动面补上 `game-progression.md` · 明写批内抽取顺序 + `#if DEBUG` 顺序断言 · `SelectCost` 镜像按 9 条口径逐条补 · Combat 条目允许声明 `GrantFromPool` 并在 `combat/_index.md` 留一句编排须知。

### priority-elevation-conditions
- **🔴-1** → **改写 `adventure-event/common-properties.md:78`**，删去「与剧情线的强制事件共用同一档」，共现兜底改为中性表述。
- **🔴-2 + 🔴-3** → **两条都按推荐**：判定式改写为 `chapter == 1 且 pastEvent 为空`（真正零结构增量）；**ch1 篇章重试算「新角色首批」、照常抬升**，散文改为「排除 ch2 / ch3 的续章与重试」，`research/_index.md` 写成「炼气新角色的起始批次（含 ch1 篇章重试）」。
- **🔴-4 Finale 守卫** → **已被 F-0/F-2 取代**：Finale 失败必死、通过即离开本篇章，两支都离开 ⇒ 守卫恒不可达，**不写守卫**。`:42`「失败后可继续消耗寿元找事件」整条随 F-0 删除。
- **🟠-1 日志** → 并进既有行：`[FutureEvent-Materialize] … prio=<n> prioReason=<QuotaGate|InitialBuild|Finale|None>`。
- ⚠ **退让位论证整条改写**（F-5：`WinMargin` 在 Finale 已删，「下调 `WinMargin`」不再是可用的退让位）。改写为指向 F-6 的替代手段。

### remaining-event-decision-points
- **🔴-1** → 见 **M-1**。「零结构增量」那句按此改写。
- **🔴-2** → 改写 `life-cycle-service.md` L209 为「每个决策点都是一个可退出点；该时刻若产生了尚未落盘的新状态，则立即原子写本地缓存 —— 非战斗四类的新状态已由既有写入覆盖，故不触发第二次写入」。
- **🟠 全部按推荐**：Travel 零决策点上取消请求返 `AdvanceResult(Success: true, FailedAt: None)`、取消在收口后生效，并在取消语义表补一行 · Research 中途退出照既有返 `Cancelled`、保留 `activeEvent`、恢复回面板初始态 · 在 `life-cycle-service.md` 的 `## 决策(-> ADR)` 加一行 ADR 候选（**不建 ADR、不动 `decisions/_index.md`**）。

### enemy-pool-chapter-scoping
- **🔴-1** → 见 **M-3**（本分片只写 `EnemyData` 侧）。
- **🔴-2 `EncounterScopes`** → **就地订正为 `CombatTier[]`，取值 `{ Practice, Standard, Finale }`**，9 组合改写为 `(combatTier × chapter)`。同改 `enemies/_index.md` 与 `enemies/common-properties.md` 字段表与第四条校验、`future-event-service.md` 三处伪码（`spec.EventType` → `spec.Tier`）。**授权把 `systems/adventure-event/combat/_index.md` 纳入本分片写入面**用于核对。
- **🔴-3 通用池定义** → **保留既有口径**：`PoolScope == null` **或两字段皆空**；改写只在其后加 `AND ChapterScope 命中该章`。
- **🔴-4 Travel** → **Travel 一类豁免 `ChapterScope`**：`eventType == Travel` 的条目其 `ChapterScope` 必须为空，加载期 `PushError`。写明理由（与「Travel 不计入 `eventCountLimit`」「Travel 的 outcome 不得含 `LifeSpan` 产出」同族，Travel 是结构性通道而非内容）。
- **🟠 全部按推荐**：闸②计数在篇章过滤之后做 · 「去重」改为「只告警、取池不受影响」（不写回共享只读单例）· `Finale` 行放宽为「该 `(Finale, chapter)` 下的池（含专属条目）非空」· 境界词文案扫描**改为纯结构判定**、落尚未开张的 `content/enemy/` 评审清单（不做文案子串扫描）· **`content/_index.md` 本次不改**（写进 handoff 的 Notes 交给日后的 `/scaffold-content-type enemy`）。

### band-boundary-config-placement
- 落点 = 平衡资源（已裁决，无争议）。
- **🔴-1** → **一并清理三处意图机制残留**（`balance.md` L29 · `future-event-service.md` L151 / L136），并在落点条目下写明「不设『下界不得使 `diff` 门槛不可达』这条校验（被检查对象不存在）」。
- **🔴-2** → **删除 `future-event-service.md` L155 那条重复且失效的推论⑦**，把 L153 重编为 ⑦。
- **🟠 全部按推荐**：行类型改名避开 `Band`（如 `EnemyLevelRange` / `LevelDiffRange`，容器仍为 `EnemyLevelingData`），并在 `terminology.md` 登记一行 · 五条校验 + 资源形态全部落 `balance.md`，`future-event-service.md` L146 改为「本服务只读；资源形态与加载期校验见 `systems/balance.md`」· 权重表保持百分数呈现 + 表下补一句存储单位，**但校验条的和值必须落成一个确定值**（不照抄草稿那句两可的括号）。
- 三项 `[采纳推荐 — 待复核]` 维持待复核状态（见 D-2）。

### combat-runtime-counter-persistence
- **净增量只有三块**：`counters` 键约定 · 消费面 API 与计数时机 · 三条读档校验。§1 / §4 是纯确认，不重写。
- **事实订正（不进 interview，但必须执行）**：草稿称 `character-profile/item/_index.md` 对「法宝次数是否即时写」未表态 —— **不成立**，L31 已明写即时写。**该文件本次不改**，草稿要求的「补这半句」取消（照写会造重复条目）。至多在 `combat-service.md` 侧加一句回链。
- **🔴-1 计数时机** → **结算成功后才 +1**（弹栈结算成功那一刻），删掉「压栈成功时 / 付费成功后」两句。`BumpCounter` 调用点唯一、落在 StackManager 的结算收口回调；`ActivationCost` 已付但 fizzle 的启动式**不吃配额**（成本仍不退）。
- **🔴-2 悬空语义** → **统一为 `PushError` + 抛**（⚠ **用户裁决与 worker 推荐不同** — worker 推荐开例外，用户选择统一）。`combat-service.md` L174 校验② **不动**，只在 `counters` 字段说明处点名它同样受②约束。**不要写例外条款。**
- **🟠 全部按推荐**：非异能计数器**暂不表态**、只写「当前键的合法形态是 `<abilityId>[#<子名>]`」并显式写一句「当前仅此一种形态」· `CardInstanceSave.Counters` 的消费面**明写为已知未覆盖面**（本稿只定存档形态与键约定）· 闸门在结算时再查一次（双查）· **`AbilityData.Id` 不得含 `#`（加载期 `PushError`）为必须**，子名正则留待 `content/` 的 id 约定表成型时统一定。
- 三处回填已核实属实：`open-questions/01-combat.md` L21 · `power/_index.md` L54 · `player-item/_index.md` L39。

### echo-validation-scope
- **前置已解除**（草稿的「前置依赖」一节已过时，**不要原样提炼**）：后端 `bundle-grant-ordinal-authority` 已归档、回声规则本体已落 `contracts/profile-sync.md` §5c、本库 `sync-service.md:143` 的回链现已有效。
- **🔴-1** → 见 **M-2**（本批只写客户端半 + 后端承接项；成对采纳未完成须显式标注）。
- **🔴-2 `BundleGrantOrdinal`** → 改为「`< 0` → `GD.PushError` + 该顶层键本次不进 diff + 触发一次 pull，**不钳制**」。`BundleRedeemedOrdinal` 的两向钳制原样保留。
- **🔴-3 `AccountSeed`** → **第二处（`player-profile/_index.md:115`）一并松动**，与 `account-info.md:13` 的既有措辞对齐。
- **🟠 全部按推荐**：`account-info.md:37` 改写为「客户端写入的字段补默认值（空昵称）；回声路径缺失走必需缺失处置 + 重新 pull」（不逐项标注例外）· 顺手在字段表点明「`AccountId` 不在后端写入封闭表内、不受回声约束」· 按 (a) 写死顺序（组装期先判缺失即剔键，出口断言只处理「两值都在但不等」）· 改昵称失败窗口**不进 UI**（纯内部分支，`ux/` 不进本次改动面）。
- 本次**不触及任何 ADR**（已核实 `decisions/` 零改动）。

### refresh-token-client-storage
- **🔴-1 启动链** → **`AccountService.InitializeAsync` 上提到 `LoginScreen` 之前**，其内部做「读文件 → 尝试刷新」；`LoginScreen` 降为条件步。改写 `architecture.md` 总则 4 的序列与 `account-service.md` L77；复核 `deviceId` 那节「登录屏之前没有降级落点」的措辞（现在有了 = 回落登录屏）。
- **🔴-2 强更闸门** → **改本库三处 + 客户端不自收口**：`architecture.md` L291 · `error-and-blocking-ux.md` L247 / L286 · `sync-service.md` L99 不变式① 改为**只在登录点**；启动 pull 上的「需更新」变体是**存档 schema 维度**的迁移路径，改写时须明确区分。收口手段全在后端（见 M-2③）。
- **🟠 全部按推荐**：不存 `refreshExpiresAtUtc`（`auth.md` §8 应答里的该字段**读取即丢弃**须明写）· 明文 `user://cache/` **但理由改写为「依托平台沙箱 + 后端 rotation 兜底」，不得再挂靠「不承诺防作弊」**（那是跨类别外推，被引用文字不支持），并在 `open-questions/` 留一条「平台密钥库后置评估」· 「硬阻塞只有两处」**不复述枚举**、只写「本节不新增阻塞点」并回链 `sync-service.md` 不变式①。
- **`ux/onboarding.md` 不改**（已实地核实全篇无「登录屏 = 首屏」陈述）。`ux/screen-flow.md` 是**两句**要改（L7 流程行 + L9）；`vision/scope.md` L12 是同一事实的第三处复述，一并轻改或改为回链。

### flags-fetch-throttle
- **🔴-1 退避形态** → **纯闸门式退避（无定时器）**：退避窗口只是「窗口内的观测不发请求」，窗口到期后仍等下一次搭车观测才拉。「不为它另开重试机制」原样保留，其后补一句退避闸门。
- **🔴-2 尾随** → 尾随条件改为「本次拉回版本 > 拉取前的 `FlagsVersion`」，否则停并告警（显式封顶，杜绝自我递归无限环）。
- **🔴-3 告警** → **`PushWarning` + 上报一次**（沿用验签失败那条既定通道）。去重口径随之定为「上报侧本会话一次」。
- **🔴-4 版本回滚** → **增大即拉 + 要求后端补契约条款**（见 M-2②）。⚠ 草稿「与既有决策的张力：无」「前置依赖：无」两处结论**随之失效，须改写**。
- **🟠 全部按推荐**：内存 `FlagsVersion` 冷启动**一律归零**（缓存只提供 `disabledIds` 降级值、不回填版本），并明写进 `content-service.md` · 沿用「尊重服务端给出的等待时间」、**不沿用抖动**并写明理由（观测触发已错峰）· 验签失败记**单个版本号**，明写「更高版本照常重试，上界 = 发布批次数」。
- **API 面按「签名零改动、语义有改动」如实写**，不沿用草稿的「零改动」措辞。
- 两项 `[采纳推荐 — 待复核]` 维持待复核状态（见 D-2）。

---

## 四、全局裁决

**D-1 九项文档漂移一次性清理**（全部按推荐）：
① `PlotModulation.EventWeights` 注释「加成」→ 乘性系数 · ② 删 `adventure-event/common-properties.md:78`「与剧情线的强制事件共用同一档」· ③ 清理意图机制残留三处 · ④ 删 `future-event-service.md` 重复失效的推论⑦ · ⑤ 保留通用池「或两字段皆空」· ⑥ `BundleGrantOrdinal` 钳制改 `PushError` 不钳制 · ⑦ `AccountSeed` 第二处一并松动 · ⑧ `life-cycle-service.md` L209 改写 · ⑨ `ProfileChangeSpec` 承重句不写列数 + 补 `CodexElements`。

**D-2 15 项 `[采纳推荐 — 待复核]`** → **全部维持待复核状态**：按推荐落笔，但在 handoff 与 `open-questions/` 双处标 `[采纳推荐 — 待复核]`、**留在待答清单不随本批移出**。
⚠ **后果：含待复核项的草稿不满足归档三前置条件 ⇒ 留在 `inbox/` 顶层**，`inbox/_index.md` 的待处理行「下一步」列写清还差什么。

**D-3 33 项 🟠** → **全部按 worker 推荐**，逐项在 handoff 的 `## Clarifications` 记「含糊点 → 取哪种解读 → 依据」。

**D-4 越界发现登记**（4 条，进待答清单）：
1. **样本卡组规模两处矛盾** —— `enemies/_index.md`「规模逐条编排、不设硬限」vs `enemies/common-properties.md`「规模 15」。
2. **`EncounterTighten` 字段面全库未定** —— `plot-manager.md` 新增的多 arc 合并算子表里 `Tighten` 一行只能写「逐字段取更紧」。（注：它原本能拧 Finale 的 `WinMargin`，而 F-5 已删该字段 ⇒ 需一并换例。）
3. **单例平衡资源如何进 ContentRegistry 全库未定** —— Id 形态 / 仓储 / `AllEnabled()` 对单例是否有意义。本批新增的赋级资源是这个空白的又一个实例。
4. **`DeckChangeOp` 成员数两处不一致** —— `architecture.md` 为 5 值（含 `AddLooseCard`），`research/common-properties.md` 写「四值」是未跟上的旧值。

**未登记的越界发现**（如实记入总报告，不进待答清单）：`open-questions/01-combat.md` 顶部摘要块与治理提示块的体积 / 过程坐标 · `sync-service.md`「降级只有三种形状」措辞是否加括注 · 「硬阻塞只有两处」在本库有三种枚举（全库收口归独立 session）· `content-service.md`「待决问题」第 2 条。

---

## 五、Phase B 波次（写入面已按铁律③分区）

| 波次 | 分片 | 说明 |
|---|---|---|
| **W0**（单独串行 · 排最前） | **Finale 重构** | 20 份主题文档 + 3 份 ADR。**它推翻的是其余分片正在引用的承重前提**，必须先落笔。 |
| W1（并行 3） | generation-weighting · combat-runtime-counter · echo-validation | |
| W2（并行 2） | event-outcome-spec · flags-throttle | |
| W3（并行 2） | priority-elevation · refresh-token | priority 的退让位论证须按 F-5 整条改写 |
| W4（并行 2） | remaining-decision-points · enemy-pool + band-boundary（同一 worker） | |

**共享台账由 orchestrator 收尾统一写**：`handoffs/_index.md` · `open-questions/` 分片 + `update-log.md` · `open-questions.md` 索引「最近更新」一行 · `answer-logs/_index.md` · `inbox/_index.md` + 草稿归档 · `decisions/_index.md`（三份 ADR 的状态行）。**不碰「derive 就绪度」小节。**

⚠ **W0 会大幅改动多份文件的行号，W1–W4 的 worker 一律按内容定位，不得按行号定位。**

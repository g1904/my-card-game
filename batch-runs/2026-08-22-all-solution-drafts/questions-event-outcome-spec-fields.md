# Phase A — event-outcome-spec-fields

来源草稿：`game-design-documents/inbox/solution-draft-event-outcome-spec-fields.md`（已评审）
目标库：`game-design-documents/`

## 一句话意图

给 `EventOption.OutcomeSpec`（`EventOutcomeSpec`）定内部字段面：两侧复用 `ProfileChangeSpec`（三列开放 / 其余恒空）、`Elements` 内 key 取值域收紧、经验失败折算在物化组装时完成、模板侧五格参数空间（`OutcomeRule` 规则 → 物化展开），并顺带答定 Explore 壳的 `OutcomeSpec` 取真身模板物化。

## 已裁决（评审中定下，不进 interview）

- 隐藏属性推拉的承载 → **A · 两侧各展开一份相同 element，不加顶层 `Always` 第三格**
- Explore 壳的 `OutcomeSpec` 由谁的模板物化 → **A · 取真身模板**（须在 `explore/_index.md` 与 `future-event-service.md` 写明「成本取壳、产出取真身」这条不对称及其理由）
- `GrantFromPool` 型产出的加载期池断言（闸 ①）→ **A · 不加**，短缺时降级 + `PushWarning` `[采纳推荐 — 待复核]`
- `OutcomeRule` 是否支持多选一 / 加权掷一条 → **A · 不支持**，一条规则一条产出 `[采纳推荐 — 待复核]`

## 🔴 冲突

### R1. 列数三处对不上，且与库中实际列数都不符（草稿自相矛盾）

- **[问题陈述]** 草稿 ① 写「9 条恒空断言」、② 写「三列开放、九列恒空」「`ProfileChangeSpec` 的 12 列」，但 ② 的表只有 **11 行**（❌ 仅 8 行），「物化组装后的断言清单」第 2 条也只列 **八列**恒空。
  ✗ 既有权威：`systems/architecture.md`「共享核心类型」的 `ProfileChangeSpec` 只登记 **10 列**（无 `CodexElements`）；`systems/services/profile-service.md` 另有一整段 `CodexElements` 的施加语义 ⇒ **实际为 11 列**（3 开放 + 8 恒空）。草稿的「12 / 9」两处都错一格。
  - 选项 (a) 按 **11 列 = 3 开放 + 8 恒空**落笔，并顺手把 `architecture.md` 的 `ProfileChangeSpec` 补上 `CodexElements` 一行（后果：修掉一处既有漂移，改动面多一处但都在本次已列的文件内）/ (b) 只写 11 列、不动 `architecture.md`（后果：架构文档继续少登记一列，本次断言清单与共享类型定义对不上，下一次 derive 会读出两套列数）/ (c) 承重表述不写列数、只写「三列开放、其余各列恒空 + 逐列断言清单」（后果：列数增长时不必回改，与 `profile-service.md`「列表数不进承重表述」那条纪律同向）
  - 推荐：**(c) + (a)** —— 承重句不写数字（既有纪律明写「列表数不是判据的一部分」），断言清单逐列穷举；同时补齐 `architecture.md` 的 `CodexElements` 行。

### R2. `ExperiencePoint` / `Faith` / `Bloodlust` 进 `OutcomeRule.FixedResource` 白名单 ⇒ 内容侧裸数字 + 同一产出两个书写通道

- **[问题陈述]** 草稿 ③ 把 `ExperiencePoint` · `Faith` · `Bloodlust` 一并放进 `Elements` 的 outcome 侧白名单，而加载期校验 #2 只要求「`ResourceKey` 落在 ③ 的白名单内、`Magnitude >= 0`」⇒ 内容作者可写 `FixedResource(ExperiencePoint, 7)` / `FixedResource(Faith, 12)`。
  ✗ 既有权威：`systems/balance.md`:186「`ExperienceGrade { None 0 / Minor 0.5× / Standard 1.0× / Major 1.5× }` 枚举 + 平衡表映射，**内容侧不落裸数字**」；:191「`HiddenStatGrade` 沿用同一范式，**内容侧不落裸数字**」；`systems/game-progression.md`:48 同句。另与草稿自己的 ⑤ / ⑥ 冲突——经验只该走 `ExperienceGrade` 一格、隐藏属性只该走 `HiddenStatGrants` 一格。
  - 选项 (a) 白名单**排除**这三个 key（`ExperiencePoint` / `Faith` / `Bloodlust` 只能由物化组装从档位表展开，`OutcomeRule` 写不出它们），加载期校验拒绝（后果：`FixedResource` 的可写 key 收窄为 `LifeSpan` / `LifeTotal` / `ManaLimit` / `Jade` 四个；一条断言、一条加载期校验）/ (b) 保留白名单，但另加一条「`OutcomeRule` 不得声明这三个 key」的加载期校验，物化侧白名单照旧（后果：等价于 (a)，只是把边界写在两层上，读者要读两处才知道谁能写）/ (c) 照草稿原样开放（后果：同一个经验产出有两个书写位——档位表与裸数字，平衡表反推口径当场失效；隐藏属性亦然）
  - 推荐：**(a)** —— 白名单本身就该按「谁组装出这条 element」分层：物化侧 `Elements` 可以出现这三个 key（由服务展开），**模板侧的 `OutcomeRule` 不可以**。草稿 ③ 把「物化后可出现的 key」与「模板可声明的 key」写成了同一张表，这是根因。

### R3. `ManaLimit` 的 `Magnitude` 无约束 ⇒ 一个 `.tres` 即可推翻「单次变动幅度恒为 1」

- **[问题陈述]** 草稿 ③ 允许 `ManaLimit` 在 outcome 侧出现，⑥ 的 `OutcomeRule.Magnitude` 是任意非负整数，加载期校验只查 `Magnitude >= 0`。
  ✗ 既有权威：`systems/character-profile/mana.md`:16「**`manaLimit` 的单次变动幅度恒为 1，不设 ±2 档**」（承重）；:14「该行的两个修正列必须留空：任一列开放，一条法则即可把 ±1 放大为 ±2，**直接推翻下方『单次变动幅度恒为 1』这条承重规则**」——修正口被封死，而本方案从内容侧另开了一个同效果的口，且**能上线、线上不可见**（写错的 `.tres` 要到玩家吃到 +3 才发现）。
  - 选项 (a) 加一条加载期校验 + 一条物化断言：`ResourceKey == ManaLimit ⇒ Magnitude == 1`（后果：一行校验，承重规则闭合；`ResearchCandidate.ManaDelta ∈ {-1,0,+1}` 的既有形态得到对偶）/ (b) 把 `ManaLimit` 也移出 `FixedResource` 白名单，只允许经 Research 的 `ManaDelta` 与「负向奖励条目」两条既有通道（后果：`mana.md`:28「压低只以负向奖励条目形态出现」需要重新指明落点，可能反而挖一个洞）/ (c) 不管（后果：承重规则失去载体）
  - 推荐：**(a)**。

### R4. `(Item, Player)`（古宝）缺口：`GrantFromPool` 的 `PoolKind` 值域含 `PlayerItem`，而它对 `Source.EventOutcome` 是 ❌

- **[问题陈述]** 草稿 ③ / 断言 6 只排除 `(Power, Player)`；⑥ 的 `PoolKind` 复用 `ExchangeGoodsKind` 五值族，其中 **`PlayerItem` = `(Item, Player)`**。
  ✗ 既有权威：`systems/common-properties.md`:257–262 的合法子集表——`EventOutcome` 行对**法则 `(Power, Player)` 与古宝 `(Item, Player)` 双双为 ❌**，只有 `(Power, Character)` / `(Item, Character)` 为 ✅。另：`systems/adventure-event/exchange/_index.md`:28 明写「法则 `(Power, Player)` **不在族内**」⇒ 草稿的「`PoolKind` 映射到 `(Power, Player)` 时直接拒绝」这条校验**恒不可达**，真正的缺口是 `PlayerItem`。
  - 选项 (a) 断言与加载期校验改写为**正向白名单**：`AbilityElements` 的 `(Kind, Scope)` 恒为 `Character` 作用域；`PoolKind` 的能力族取值收窄为 `{ CharacterItem, CharacterPower }`，`PlayerItem` 直接拒绝（后果：一条正向断言替掉两条负向排除，与合法子集表逐格对齐）/ (b) 保留负向排除但补上 `(Item, Player)`（后果：等价，但每新增一个 ❌ 格都要回来补一条，与「合法子集表是静态查表」的既有形态不同构）/ (c) 为事件产出**开放**古宝授予，即改写合法子集表把 `(Item, Player) × EventOutcome` 改为 ✅（后果：推翻既有决策，须由用户裁定；古宝是账号级持久资产，由轮回内事件产出会改变账号级经济）
  - 推荐：**(a)** —— 除非用户确实想让事件产出账号级古宝（那是 (c)，属推翻既有决策，须明确拍板）。

### R5. 置换型剥夺 / 三档禁用：② 声明 outcome 侧开放，但 ⑥ 写不出它们；且掷定时点与既有表正面相抵

- **[问题陈述]** 草稿 ② 的 `AbilityElements` ✅ 行写「置换型剥夺 · 三档禁用 · 授予法宝 / 神通**只能出现在 outcome 侧**」，但 ⑥ 的 `OutcomeRule.Kind` 只有 `FixedResource | GrantFromPool | DeckOperation` 三值——**没有任何一格能表达 `Remove` / `Disable` / `PairKey` / `DisableDuration`**。
  ✗ 更重的一处：`systems/adventure-event/common-properties.md`:50–58 的「outcome 侧的对应形态（置换与禁用共用同一条链路）」表明写：**候选何时掷定 = 结算时（`eventEnd` 之前），走 `reward` 子流**；玩家看到「失去 A · 得到 B」+ 接受 / 拒绝，**事件内决策点：有**。而本方案 ①「抽取在物化时掷定」把这条链路整个前移，且草稿全文未提这个决策点。两者不可同时成立。
  - 选项 (a) `OutcomeRule` 增第四个 `Kind`（`AbilityChange`，带 `AbilityChangeOp` / `AbilityKind` / `DisableDuration` / 池或定值目标），并**把置换 / 禁用候选一并前移到物化时掷定**，改写 `common-properties.md` 那张表的「结算时」一行（后果：与「抽取在物化时掷定」一条纪律收口，防重掷更严；代价是要同步改写一张承重表，并说明决策点的候选来自定稿实例而非结算时现掷——这其实与 `future-event-service.md`:80 的理由 ③「决策点需要一份施加之前就已定稿的候选」同向）/ (b) 保持既有表不动：置换 / 禁用**不由 `OutcomeSpec` 承载**，仍由 resolver 在结算时组装并并入 `eventEnd` 那一次 `TryApply`；② 的 `AbilityElements` ✅ 相应收窄为「只承载物化时定稿的授予（`Grant`）」（后果：`OutcomeSpec` 的 `AbilityElements` 只出 `Grant`，断言可写死 `Op == Grant`；但「一切 outcome 走 `OutcomeSpec`」不再完整，`ResolveOutcome` 仍有一条独立的 element 组装路径）/ (c) 搁置，本次只落 `Grant`，把置换 / 禁用的归属留成一条新的待答项（后果：`GenericEventResolver` 的实现面**没有真正闭合**，与草稿「解锁面」那一段的结论相反）
  - 推荐：**(a)** —— 理由是 `future-event-service.md`:80 已经把「决策点候选须在施加之前定稿」写成物化前移的三条理由之一，那条与置换面板「候选必须预先算定并落决策点存档」逐字同源；`common-properties.md` 那张表的「结算时」是 08-10c 的旧口径，08-17j 的物化前移事实上已经越过它。**但这是一次对承重表的推翻，必须由用户拍板，不能由 worker 代做。**

## 🟠 含糊

### A1. `OutcomeRule.DeckOp` 复用六值面板枚举，两个成员落不进 `DeckElements`；且与 `GrantFromPool` 表达位重叠

- 草稿 ⑥ 写 `[Export] public DeckOperationKind DeckOp; // 复用面板层六值枚举`。
  ✗ `systems/adventure-event/research/common-properties.md`:40–48：`DeckOperationKind` 六值 = `LearnTechnique / UpgradeTechnique / ForgetTechnique / RemoveLooseCard / GrantItem / Recuperate`，其中 **`GrantItem` 落 `AbilityElements`、`Recuperate` 落 `Elements`**，不落 `DeckElements`；且该枚举**不含 `AddLooseCard`**，而草稿 ② 明写「业障入组走 `AddLooseCard`」。⇒ `Kind == DeckOperation` 用这个枚举既装不下要装的、又装进了不该装的。
  - 另一层重叠：`Kind == GrantFromPool` 的 `PoolKind` 值域含 `Card` / `CultivationTechnique`——「从卡牌池抽一张塞进卡组」既可写成 `GrantFromPool(Card)` 也可写成 `DeckOperation(AddLooseCard, TargetId 空 → 从 PoolKind 抽)`，同一产出两个写法。
  - 选项 (a) `DeckOp` 改用 element 层的 `DeckChangeOp`（`architecture.md`:447 的五值），并把 `GrantFromPool` 的 `PoolKind` 收窄为**只含能力族**（`CharacterItem` / `CharacterPower`），卡牌 / 功法一律走 `DeckOperation`（后果：两个 `Kind` 的职责不重叠，`GrantFromPool` ↔ `AbilityElements`、`DeckOperation` ↔ `DeckElements` 一一对应，断言可逐 Kind 写死落哪一列）/ (b) 保留 `DeckOperationKind` 但加载期校验限定为四个合法成员，`PoolKind` 保留五值（后果：重叠仍在，作者要靠约定选写法）/ (c) 为 outcome 侧新开一个枚举（后果：第三个同族枚举，与「不发明第三种范式」相反）
  - 推荐：**(a)**。

### A2. `FailureRatio` 由 `0.5`（float）改为 `50`（百分比整数）——改动面漏了它的既有落点

- 草稿 ⑥ 写 `[Export] public int FailureRatio = 50; // 百分比整数，不用 float`，理由（可重放）成立。
  ✗ 但 `systems/game-progression.md`:52 明写「`FailureRatio`（默认 **0.5**，逐条可覆写）」，而草稿「后果 · 改动面」**没有列 `systems/game-progression.md`**（也没列 `systems/balance.md`）。不改即两处真值。
  - 选项 (a) 改动面补上 `systems/game-progression.md`（把 `0.5` 改写为「百分比整数 50」并注明向下取整、下限 1 的既有口径回链 `balance.md`:187）/ (b) 保持 `0.5` 的 float 形态，物化时用定点换算（后果：与「重放不依赖浮点」相抵）/ (c) 只改 `AdventureEventData` 的 `[Export]` 类型，`game-progression.md` 的文字不动（后果：留一处漂移）
  - 推荐：**(a)**。

### A3. `RngStream.Reward` 的「从不并发」前提在一次批物化内不再自明

- 草稿 ⑥ 写「随机源 `RngStream.Reward` 子流，不新开（与 Research 候选、战后奖励候选完全同构，且**三者从不并发**）」。
  ✗ `future-event-service.md`:157 的原论证是「奖励候选与构筑候选**从不并发**（一次只结算一个事件）」——那是**结算期**的论证。本方案把 outcome 抽取放在**物化期**，而一次 `ComputeEventOptions` 会为 3–5 个选项**连续**做 Research 候选抽取与 outcome 抽取，同批共用 `Reward` 子流。这不违反确定性，但要求**批内抽取顺序被明确固定**，否则两种实现给出不同的种子复现结果。
  - 选项 (a) 明写批内抽取顺序（按 option 在批内的索引升序，单个 option 内按「Research 槽 → outcome 规则数组顺序」），落一条文字纪律 + `#if DEBUG` 顺序断言（后果：一句话 + 一条断言，确定性闭合）/ (b) 为 outcome 抽取新开一条子流（后果：与「不新开子流」的既有克制相反，且草稿的备选方案里已把它否决）/ (c) 不写（后果：同一种子在两次实现下产出不同批次，属「能上线、线上不可见」）
  - 推荐：**(a)**。

### A4. `SelectCost` 侧「不变式」的口径数写错，而本次要在 `profile-service.md` 写它的 outcome 侧镜像

- 草稿「约束」段写「`SelectCost` 的**三条**不变式」，① 段写「与 `SelectCost` 侧已有的**七条**同款」。
  ✗ `systems/services/profile-service.md` 的施加失败语义表实为 **8 列恒空**（`AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` / `RngElements` / `TraceElements` / `SettingChanges` / `CodexElements`）**+ 1 条取值域收紧**（`LifeSpan > 0`）= **9 条**。
  - 选项 (a) 落笔时按 9 条口径写，并在 `profile-service.md` 的表里逐条补 outcome 侧镜像行（后果：表加若干行，两侧对称可机械核对）/ (b) 只补一行汇总的 outcome 侧镜像（后果：与既有「各自独立成行、不合并成通则」的明写纪律相抵——那条明写「日后新增的列未必都该被排除在成本侧之外」）
  - 推荐：**(a)**，但**镜像行数取决于 R1 的裁决**（列数口径）与 R5（`AbilityElements` 是否只出 `Grant`）。

### A5. Combat 类事件能否声明 `GrantFromPool` 产出（与「战利品恒不进 `OutcomeSpec`」的边界）

- 草稿 ⑥ 写模板侧五格「`eventType` 不限」。Combat 条目因此可写 `GrantFromPool(CharacterItem, 1)`，产出一件法宝、记 `Source.EventOutcome`，与 `CombatResult.Spoils` 的 `Source.CombatReward` 并存于同一次结算。
  - 既有边界（`future-event-service.md`:256）只说「战利品恒不进 `OutcomeSpec`」，按「谁组装出这条 element」判，上述写法**合规**；但玩家侧看到的是同一场战斗掉了两批东西，且平衡侧的战后奖励厚度轴不覆盖后一批。
  - 选项 (a) 明写允许并说明两者的区分（内容作者可为某个战斗条目编排事件级产出）/ (b) 对 `eventType == Combat` 的条目禁用 `GrantFromPool`（只留 `FixedResource` / `DeckOperation`），加载期校验（后果：奖励厚度轴保持唯一）/ (c) 不写（后果：内容作者自行发挥，平衡反推失去边界）
  - 推荐：**(a)** 并在 `combat/_index.md` 留一句编排须知；(b) 也自洽，取决于用户是否愿意让战斗条目有第二条掉落通道。

## 🔵 可推演

- **「阻于效果关键字体系与目标规则」这处误挂，核实成立。** `systems/character-profile/deck/_index.md`:152 的七个原子操作（`ModifyMomentum` / `Draw` / `Discard` / `ModifyMana`（明写**不改 `manaLimit`**）/ `ApplyState` / `RemoveEntry` / `MoveCard`）无一写 Profile；`TargetSlot` / `EffectScope` / `EntryFilter`（`deck/common-properties.md`:106–120）锚定的是战场条目与手牌，而事件产出没有战场。⇒ 两套作用面确不相交，本条**只欠自身落笔**。根因确如草稿所述：「效果」一词有两个所指。术语纪律「产出 element」建议成立。
- **① 复用 `ProfileChangeSpec` 成立。** `systems/architecture.md`:482「`CostSpec` / `RewardSpec` 合并为单一 `ProfileChangeSpec`」是明写定案；`life-cycle-service.md`:103–106 的五步组装第 ① 步本就是拼各列，选中一侧后直接并入零转换。
- **⑤ 的折算形态有现成依据。** `systems/balance.md`:187「失败 = 同档的 50%，**向下取整、下限 1**」；`game-progression.md`:52「折算在 `ProfileChangeSpec` 组装时完成，`TryApply` 收到的已是最终整数」。`ExperienceGrade == None` 不产出 element 与「无产出用空 spec 不用 `null`」同向。
- **⑦（已裁决取真身）与既有形态同构。** `future-event-service.md`:32 / :263：`DestinationLocationId` 与 `Encounter` 均在物化时按真身填好壳实例，依据是防重掷；产出侧无展示泄漏面（`explore/_index.md`:25「遮罩态卡面只取 Explore 模板自己的显示名 / 描述 / 风味文案 / 图标」）。⇒ 不对称成立，须明写。
- **断言 5（Travel 真身两侧不得出现 `LifeSpan`）是既有禁令的物化侧对偶。** `adventure-event/common-properties.md`:116 的结构性禁令 + 「Explore 遮罩的情形自动覆盖」在**取真身**裁决下继续成立（若当初取壳则会失效）——这条是 ⑦ 裁决的一个附带收益，值得写进文档。
- **快照零增量成立。** `PastEventEntry` 按「重算不出来**且有消费方**」判据，本次掷定的结果已在 `AppliedChange` 里（`adventure-event/common-properties.md`:213）。
- **存档 schema 零字段增量。** `EventOption.OutcomeSpec` 一格已在字段表与 `sync-service.md`:310 的增量表里，本次只填内部。

## 拟改动文档清单（供跨草稿核对）

- `systems/services/future-event-service.md`
  - :243 那段「**内部分解 ⟨待定：归「效果关键字体系与目标规则」那次专门 handoff⟩**」→ 整段重写为 `EventOutcomeSpec` 的内部定义（两侧 `ProfileChangeSpec`、三列开放 / 其余恒空、`Elements` key 白名单）。
  - 「意图」段新增：outcome 抽取链复用（`TryPickGrantableMany` / `DrawPool<T>`）· `RngStream.Reward` 子流 + **批内抽取顺序**（A3）· 短缺降级 + `PushWarning` · 物化后断言清单 8 条 · 日志 `[FutureEvent-Outcome] …`。
  - 「待决问题」删「`EventOutcomeSpec` 的内部字段面未定」整条。
  - **与其它草稿的潜在打架点**：任何同批改写 `ComputeEventOptions` 物化伪码 / 子流清单 / 取池链 / 「待决问题」列表的草稿。
- `systems/adventure-event/common-properties.md`
  - 新增模板侧产出格五格（`ExperienceGrade` / `FailureRatio` / `HiddenStatGrants` / `OnResolvedRules` / `OnFailureRules`）与 `OutcomeRule` 加载期校验 6 条。
  - 新增「outcome 侧的第四条不变式」（`Elements` key 取值域收紧）。
  - **若 R5 裁 (a)**：改写 :50–58「outcome 侧的对应形态」表的「候选何时掷定 = 结算时」一行为「物化时」。
  - **与其它草稿的潜在打架点**：任何改写 `selectCost` 不变式段、结算流程伪码、`PastEventEntry` schema 的草稿。
- `systems/architecture.md`「共享核心类型」
  - 新增 `EventOutcomeSpec` / `OutcomeRule` / `OutcomeRuleKind` / `OutcomeDirection` / `HiddenStatGrant` / `HiddenStatGrade`（若尚未登记）。
  - **顺手补** `ProfileChangeSpec` 缺失的 `CodexElements` 一行（R1）。
  - **与其它草稿的潜在打架点**：**任何**新增共享类型 / 枚举成员的草稿都会写这一节 —— 高冲突面，建议与其它触碰本节的分片串行。
- `systems/adventure-event/explore/_index.md`
  - 「取池与校验」段的物化断言处新增一条：壳的 `OutcomeSpec` 由 `RevealedEventId` 的模板物化，且不读真身任何成本字段；并明写「成本取壳、产出取真身」的不对称与理由。
- `systems/services/profile-service.md`
  - 施加失败语义表新增 outcome 侧镜像行（行数待 R1 / R5 裁定）：`OutcomeSpec` 两侧的恒空列、`Elements` key 白名单、`LifeSpan` 取值域镜像（`BaseValue >= 0`）、`Op == Grant ⇒ (Kind, Scope) 作用域恒为 Character 且 Source == EventOutcome`。
  - **若 R3 裁 (a)**：`ManaLimit` 行补一句「outcome 侧 `Magnitude == 1`」的回链。
  - **与其它草稿的潜在打架点**：该失败语义表是全库最热的共享表，任何改 `ProfileChangeSpec` 列 / `CostKey` / `Source` 的草稿都会写它。
- `systems/game-progression.md`（**草稿改动面漏列，见 A2**）
  - :52 的 `FailureRatio` 默认 `0.5` → 百分比整数 `50`，补「向下取整、下限 1」的回链。
- `systems/adventure-event/combat/_index.md`（**仅当 A5 裁 (a) / (b)**）
  - 补一句 Combat 条目的 `OutcomeSpec` 产出编排须知 / 或 `GrantFromPool` 禁令。

## 待移出的 open-questions 条目

- `open-questions/02-event-options.md` → **「`EventOutcomeSpec` 的内部字段面（08-17 新增 · 承重）」** → **整条答结**：内部字段面落定（两侧复用 `ProfileChangeSpec`、三列开放、`Elements` key 白名单、经验折算在物化组装时完成、模板侧五格 + `OutcomeRule`、Explore 壳取真身）；同时**答结该条附带的「⚠ 阻塞来源待重新确认」**——核实结论为「阻塞从一开始就挂错对象，两套作用面不相交」。
  - answer-log 建议文件名：`answer-logs/log-event-outcome-spec-fields.md`（`solution-draft-<slug>` 规则）。
  - answer-log 中应如实记下误挂根因（本库「效果」一词有两个所指：战斗效果原语 vs 事件产出 element）与由此定下的术语纪律。
- **不移出**：`open-questions/02-event-options.md` 的「生成 / 加权规则与叠加顺序」🔴 一条 —— 草稿明写它不阻塞本条、本条也不答它。
- **可能连带**：`systems/services/future-event-service.md`「待决问题」段同名一条须删（那是主题文档侧，不是清单侧，由 Phase B worker 自己删）。

## 越界发现

1. **`systems/architecture.md`「共享核心类型」的 `ProfileChangeSpec` 缺 `CodexElements` 一列。** `profile-service.md` 有整段 `CodexElements` 的施加语义与失败语义行，`architecture.md`:331–343 的类型定义只有 10 列。本次因 R1 必须裁定列数口径，故建议顺手补；若用户不批，请记为一条独立待答。
2. **`DeckChangeOp` 的成员数在两处不一致。** `systems/architecture.md`:447 为 **5 值**（含 `AddLooseCard`）；`systems/adventure-event/research/common-properties.md`:48 写「`DeckChangeOp`（**四值** · element 层）」。`open-questions/update-log.md`:82 记录过「`DeckChangeOp` 4 → 5 值（`AddLooseCard`）」⇒ research 侧那句是**未跟上的旧值**。不在本分片写入面内，交回 orchestrator。
3. **`systems/adventure-event/common-properties.md`:50–58 的「候选何时掷定 = 结算时」与 `future-event-service.md`:79 的「抽取在物化时掷定」是一处既有张力**，本次落笔必然撞上（见 R5）。它不是本草稿制造的，但本草稿是第一个被它卡住的落笔。

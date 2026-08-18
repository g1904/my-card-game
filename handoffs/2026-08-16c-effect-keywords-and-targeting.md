# 效果关键字体系与目标规则

- id: 2026-08-16c-effect-keywords-and-targeting
- date: 2026-08-16
- topic: systems/character-profile/deck/common-properties.md · systems/character-profile/deck/_index.md · systems/services/combat-service.md · ux/combat-ux.md · terminology.md · content/_index.md
- status: distilled
- distilled-to: `systems/character-profile/deck/common-properties.md` · `systems/character-profile/deck/_index.md` · `systems/services/combat-service.md` · `ux/combat-ux.md` · `terminology.md` · `content/_index.md`

**一行摘要：** 效果的**关键字体系**定为一个与次类型同构的内容层注册表条目（`KeywordData`，两种 `KeywordKind`，机制先定、清单归零）；**目标 target 与作用域 scope 正式切分为两个东西**，共用同一个 `EntryFilter`；合法目标集定为四条可交换过滤的即时求解、方位一律相对施放者解析；结算时逐槽位重检并采 MTG 式**部分 fizzle**；挂起态收窄为三条与门。连带：`PlayCard` 改收目标列表、战场条目新增 `keywordId`、清掉两处漂移。

## Intent（distilled）

### 一、关键字 = 内容层的注册表条目，与次类型同构

`[GlobalClass] partial class KeywordData : Resource`：稳定字符串 `Id`（`<kind>.<name>`，点号分段、`snake_case` 词身）· 经 ContentRegistry 加载 · `.tres` 编写 · 带 `ContentEnabled` · **不挂 `Rarity`**（关键字不进抽取池）。

它必须是独立条目而非「纯呈现层的文案简写」，三条理由与功法否决「纯标记方案」逐条同构：

| 理由 | 纯文案简写方案会怎样 |
|---|---|
| ① 效果筛选要能按关键字引用 | 战场条目没有 `Subtypes`（次类型挂 `CardData`，而持续状态条目的来源可能是异能而非某张牌），「移除对方所有带某状态的条目」这类 payoff 没有筛选键 |
| ② `ContentEnabled` 的原子性 | 关掉一个关键字要改 N 张卡的效果定义，漏一张即得到一条半生效的规则 |
| ③ 一处可读 / 可校验 | 「这个关键字什么意思」要 grep 全库；拼错从编译期推迟到运行时，悬空引用无从校验 |

**两种关键字，与既定三层各归其位：**

| 种类 | `KeywordKind` | 定义体 | 落在三层的哪一层 |
|---|---|---|---|
| 关键字动作 | `Action` | 一段 `EffectData[]` 模板 | 第一层（结算时执行的原子操作组合） |
| 关键字状态 | `State` | 一份战场条目模板 `BattlefieldEntryTemplate` | 第二层（`ApplyState` 产出的非永久战场条目） |

**关键字不新增第四类东西**——`Action` 展开为已有的原子操作，`State` 展开为已有的战场条目。它是**命名与复用的一层，不是机制的一层**，须写死，否则日后会有人把它当成第三种效果载体。

**参数化 = 单个 `Amount` 占位，不做通用表达式。** `KeywordData.HasAmount : bool`，引用侧写 `KeywordRef(KeywordId, Amount)`。通用表达式会把「效果是数据不是代码分支」拖回一个需要求值器与沙箱的小语言，而 overlay 热更一段脚本的风险面远大于改一个数值。

**展开在结算时做，不在加载时内联**——否则 overlay 热更改一个关键字的定义，已加载的卡牌拿的是旧展开（`XxxData` 是共享只读单例，不能回写）。

### 二、关键字首批清单 = 空

机制现在就定，清单一条不预铺，与次类型「清单归零，机制保留」完全同构。

- 当前**没有任何一个关键字被规则直接引用**：`IgnoresProtection` 是效果级布尔字段、埋伏是次类型 `enchantment.ambush`、疲劳是规则。次类型能留一条是因为 `enchantment.ambush` 是埋伏机制的定名；关键字侧没有对应的东西，故一条都不留。
- **准入判据照抄次类型两条**：① 至少 3 个内容条目共享它；② 至少 1 处目标筛选或 payoff 引用它。**没有 payoff 的关键字就是风味词**，风味写进描述文本。
- **重建时机 = ch1 内容横向扩展阶段**，切入点同为 starter deck 的设计过程。关键字的正确清单只能从「哪些组合真的重复了 ≥3 次」倒推，而当前内容条目数为零；预铺一批 = 制造一批 filler，且每条都要在 ch1 专场推翻重来。

### 三、目标 target 与作用域 scope 是两个东西（承重）

这是「目标规则完整判据」缺的那一半，此前已隐含存在但从未命名——`CardInstance` 运行态判据的第二条理由「『所有灵兽获得 +1』作用于一个随时间变化的集合」讲的就是它。

| | **目标 target** | **作用域 scope** |
|---|---|---|
| 锚定 | 结算那一刻由 `TargetRef` 锚定到具体条目 | 求值那一刻按筛选条件动态匹配 |
| 承载 | `EffectData.TargetSlots` | 静止式修正的 `EffectScope` |
| 玩家参与 | 可能需要玩家点选 | **永不需要玩家输入** |
| 局面变了 | 可能非法 → fizzle | 无所谓，下次求值自然重算 |
| 落存档 | `chosenTargets : TargetRef[]` | **不落存档**（不是状态，是筛选条件） |
| 卡面文案 | 「目标〈类别〉」 | 「所有〈筛选〉」 |

- **推论 ①：静止式修正永远不需要目标规则。** 故「效果必须显式声明目标类别」这条纪律只约束 `TargetSlots`，不约束 `EffectScope`。此前两者混在一起，正是目标规则写不下去的直接原因。
- **推论 ②：两者共用同一个筛选结构 `EntryFilter`**，不各写一套——两份筛选条件会各自漂移而本库没有机制发现。差别只在是否需要 `TargetRef` 锚定。

### 四、合法目标集的完整判据 + 部分 fizzle

**合法目标集 = 在需要它的那一刻对当前局面跑一遍筛选，永不预存、永不缓存**（既定「`LegalTargets` 不落存档、恢复时按当前局面重算」的正面表述）。

四条过滤：方位（`SideConstraint` 相对 `controllerSide` 解析）· 类别（`AllowedEntryKinds`）· 保护（`IsProtected == false || IgnoresProtection`）· 筛选（`EntryFilter`）。**四条的顺序不是规则**——结果与顺序无关，交集可交换，写成某个顺序只为可读与短路。这一点须明写，以免日后被误当成第二条顺序敏感性（第一条是「加法先于乘法」）。

**`SideConstraint` 一律相对施放者解析，绝不写绝对方。** 这是 `CardData.Pool = Both` 的直接推论：同一张牌可能同时出现在玩家卡组与敌人卡组里，写绝对方会让它在敌人手里语义翻转。枚举里就不放绝对方取值。

**结算时逐槽位重检 + MTG 式部分 fizzle。** LIFO 连锁下，栈上更靠上的条目可能移除掉下面那条已选定的目标，fizzle 情形在本作真实存在：

- 部分槽位非法 → 该槽位不产生效果，其余槽位照常结算；
- 全部有目标的槽位都非法 → 整条不结算（`Declared` 记 0，ticker 明写「目标已不存在」）。

否决「全有全无」：一张两槽位的牌因为对手拆掉其中一个目标就整条落空，在 5 回合定长对局里惩罚过重，且玩家没有响应窗口去补救。

### 五、什么时候才让玩家点一下

挂起态昂贵：一个决策点 + 一次存档写 + 打断结算状态机。**槽位产生挂起，当且仅当三条同时成立**：① `Kind ∈ { BattlefieldEntry, HandCard }`；② `controllerSide == Character`；③ `LegalTargets.Count > 1`。

- `Count == 1` → 自动选定，省一次无意义点击、一个决策点与一次存档写。
- `Count == 0` → 该槽位判非法，走 fizzle 分支，不挂起（不能让玩家面对一个空的高亮集）。
- **推论：`Kind == Side` 且 `SideConstraint != Any` 的槽位永不挂起** ⇒ 绝大多数产 / 削道念的牌零点击，与低交互定位一致。

**这三条只管结算侧的槽位**（触发式 / 启动式异能在栈上回头问的那些）。玩家主动出牌的全部槽位在打出前由 UI 按 `slotIndex` 顺序一次收齐，入栈即 `Resolved`——见下方「六」。

### 六、`PlayCard` 改收目标列表（Clarification 产物）

既定签名 `PlayCard(CardInstance card, TargetRef target)` 只收一个 `TargetRef`，与「一效果可有多个 `TargetSlot`」不齐。改为 `PlayCard(CardInstance card, IReadOnlyList<TargetRef> targets)`，主动出牌的全部槽位由 UI 在打出前一次收齐。

这样既定的「玩家主动出牌的目标在打出时就选定、入栈时 `targetState = Resolved`；挂起态只来自压进去的东西在结算时回头问」原样成立，D4 的稀缺配额（≤10% 触发式异能、一场期望 1~2 次）与 ≈31 个决策点的量级估算都不受冲击。

否决「多槽位一律走挂起逐个问」：决策点密度按每张多目标牌 +N 暴涨，与该配额正面冲突。

### 七、`HandCard` 槽位强制 `Self`，且只吃次类型筛选

`SideSnapshot.HandCardInstanceIds` 敌方恒为空（既定填充纪律），`HandCount` 只给计数 ⇒ 玩家看不见对手手牌的任何条目 ⇒ UI 无从高亮 ⇒「指定对手某张手牌」不可能成为合法目标。故 `Kind == HandCard` 时 `SideConstraint` 必须为 `Self`。这同时封住一条会与既定信息面正面冲突的口子（对手手牌的可见性是埋伏之外的第二条信息泄漏面）。

**这不封死「弃掉对手一张手牌」这类效果**——那走 `EffectScope`（随机 / 全部，无 `TargetRef`），不走目标槽位。`Discard` 原子操作本就在清单里。**这正是第三条切分的第一个实用价值。**

`HandCard` 槽位的 `EntryFilter` **只吃 `RequiredSubtypes`**（读 `CardData.Subtypes`）；`AllowedEntryKinds` / `RequiredKeywords` / `IncludeFaceDown` 在该 `Kind` 下须为空，否则加载期 `PushError`。理由：手牌是 `CardInstance` 不是战场条目，前者无对象、后者无意义；且关键字是**效果的命名层**，不是卡牌的标签，让它同时成为卡牌标记会给关键字第二重语义。

### 八、战场条目新增 `keywordId`（Clarification 产物）

`Kind == State` 的关键字展开产出的 Transient 条目**必须携带产出它的关键字 id**，否则「移除对方所有带某状态的条目」这类 payoff 仍然写不出来——而那正是关键字必须是独立条目的头号理由。它**不可由 `sourceId` 推导**：同一张牌可施加两条不同的关键字状态，两条条目的 `sourceId` 相同。

故 `ActiveCombat` 的战场条目表新增 `keywordId : string?`（仅关键字展开产出的 Transient 条目非空），随下一次 schema bump 一起走（当前无线上存档 = 空迁移，成本近零）。

### 九、四项取向（草稿评审时定下）

1. **一槽位 = 一个目标，多目标靠多槽位。** `TargetSlot` 不设 `TargetCount`；`chosenTargets` 与 `pending.slotIndex` 的既定结构直接够用，UI 一次只问一个。否决 `TargetCount { Exactly(N), UpTo(N) }`：竖屏多选态是真实成本，且 `pending` 的「一个 slotIndex」结构要扩。**方向不对称是关键理由**——日后真需要时补一个字段是纯加法，而先做多选再退回单选要改存档结构。
2. **关键字提醒文本永远走长按，首次出现不自动展开。** 否决「本轮回首次自动展开一次」：要为「首次」记账（落哪个 Profile？跨轮回还是轮回内？），为一条呈现便利新增一个存档字段不划算。若实测新手看不懂，自动展开一次是现成的退让位。
3. **`EntryFilter` 的多条件组合语义恒为 AND，不支持 OR / NOT。** 可机械校验、卡面文案好写。否决 OR / NOT：筛选条件会从一张表变成一棵树，卡面文案立刻变长，与竖屏可读性相反。OR 的需求由内容侧绕过（把两个关键字都挂上），不进结构。
4. **`IncludeFaceDown` 保留字段、默认 `false`，内容侧纪律 = 当前不使用。** 保留成本为零，日后真有「揭示一张埋伏」这类效果时不必改 schema。与 `CountdownSide.Either` 的处理同构——机制在、纪律管住它。

### 十、顺带清理的两处漂移

- **`CombatSnapshot.IntentView? Intent` 删除。** 敌人意图机制已整条移除，该字段与其注释是残留。
- **`PendingTargetRequest` 补 `SlotIndex`。** `pending` 存档结构里已有 `slotIndex`，视图侧缺一格，两侧不齐。

## Clarifications（interview 产物）

- **战场条目怎么获得关键字筛选键？** → **条目新增 `keywordId` 字段并随下一次 schema bump**。这推翻了草稿「后果」一节的「不 bump 存档 schema」——草稿把该结论建立在「本方案只补声明侧」上，而理由①要求的筛选键落在运行态侧。
- **多目标槽位与「打出时选目标」的关系？** → **`PlayCard` 签名改收 `IReadOnlyList<TargetRef>`，草稿建议 5 的三条挂起条件只适用于结算侧槽位**。草稿建议 5 未区分主动出牌槽位与结算侧槽位，照字面读会与既定「入栈时 `targetState = Resolved`」冲突。
- **`EntryFilter` 落在 `HandCard` 槽位上时哪些字段有效？** → **只吃 `RequiredSubtypes`，其余三格在该 `Kind` 下须为空**。草稿的四条过滤伪码把 `HandCard` 与战场条目混在同一条筛选链上，未回答手牌没有 `AllowedEntryKinds` 这一问。

## Notes / triage

- 草稿正文的 `IgnoresProtection` 配额 **≈1%** 已过时，现行权威是 **≈5% + 两条准入规则**（`systems/balance.md`）。落笔时只回链、不复述数字。
- 草稿 `targets:` 里的 `systems/adventure-event/common-properties.md` **不承载效果 / 目标机制**（已通读确认），本次不写入它；待答项指向里的这处陈旧路由随条目移出一并消失。
- `KeywordData` 是一个新内容类型，已登记进 `content/_index.md`；因清单为空，**不开张 `content/keyword/`**，与次类型同批处理。
- 本次未评估任何文档的 derive 就绪度。

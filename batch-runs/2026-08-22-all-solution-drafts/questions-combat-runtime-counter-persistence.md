# Phase A — combat-runtime-counter-persistence

分片：`inbox/solution-draft-combat-runtime-counter-persistence.md`（`status: awaiting-review`，但 `## 仍需用户决定` 已标「已全部裁决（2026-08-22 · 批量评审）」）
目标库：`game-design-documents/`

## 一句话意图

战斗内两块运行态计数器（`Power` 的「本场已触发 N 次」、道具的「本场已用几次」）的承载字段其实早已写进 `combat-service.md`；本稿不重新设计结构，只补齐 `counters` 的**键约定**、三条读档校验、法宝一侧的对称性、以及计数器的**消费面 API**，并把三处落后的登记回填。

## 相对 `combat-service.md` 现状的净增量（逐条核实）

已核实 `systems/services/combat-service.md`（L138–176）原文，逐条判定：

| 草稿条目 | 文档现状 | 净增量 |
|---|---|---|
| §1 `Power` 运行态 = 战场条目 `counters` | **已在**（L162 字段行 + L164 明写「不需要独立结构」） | **0**（纯确认） |
| §1 三条连带确认（未入场无落点 / `PlayerPower` 本场计数落 `ActiveCombat` 不算层级错配 / 敌人侧同表） | 未明写；但 L172「`Power` 的入场本身可重建」+ L157 `ownerSide` 已蕴含 | **小**（三句显性化推论） |
| §2 `counters` **键 = `AbilityData.Id`[`#`子名]** + 悬空校验 + 值域 ≥0 + 0 不写入 + 与 `CardInstanceSave.Counters` 共用一套 | **文档完全没有** | **本稿的实质新内容** |
| §3 消费面 `GetCounter` / `BumpCounter` 落 BattlefieldManager + 计数时机 + fizzle 不计数 | 文档没有；L217 BattlefieldManager 职责可容纳 | **新增** |
| §4 `CombatItemSave(ItemId, UsesThisCombat)`、剩余次数不落 `ActiveCombat`、不带 `Scope` | **已在**（L170 一字不差，含「唯一载体」论证） | **0**（纯确认） |
| §4 法宝 `CharacterItem.Charges` 同样即时写 | **已在** `systems/character-profile/item/_index.md` **L31**：「消耗即时经 `ProfileManager.TryApply` 写 CharacterProfile，不攒到收口」 | **0 —— 草稿此处判断有误，见下** |
| §4 敌人侧无 Profile `Charges`，次数上限只能靠 `UsesThisCombat` 对 `ItemData.Charges` 比 | `ItemData.Charges` = 上限/初值 已定（`player-profile/_index.md` L65）；此推论未明写 | **小**（一句推论） |
| §5 三条读档校验 | 文档 L174 只有四检查点，无这三条 | **新增**（但第一条与既有 ② 相抵，见 🔴-2） |
| 后果：`ActiveCombat` schema 不变、空迁移 | 与 L176 / L178 一致 | **0** |

**净增量收敛为三块：`counters` 键约定（§2）· 消费面 API 与计数时机（§3）· 三条读档校验（§5）。** 其余全是确认与回填。

### ⚠ 事实订正（不进 interview，但必须传达）

草稿「与既有决策的张力」第二段称 **「`character-profile/item/_index.md` 对『法宝次数是否即时写』未表态，`player-item/_index.md` 只论证了古宝一侧」——不成立**。两侧均已明写：
- `systems/character-profile/item/_index.md` L31：法宝「消耗即时经 `ProfileManager.TryApply` 写 CharacterProfile，不攒到收口」；
- `systems/player-profile/player-item/_index.md` L18：古宝「使用次数即时经 `ProfileManager.TryApply` 写 PlayerProfile，不攒到收口」。

⇒ 已裁决 #2（「是 · 对称即时写」）**只是确认既有文档**，不是补白。草稿「后果」里写的「`character-profile/item/_index.md` 补『法宝次数即时写』这半句」**应当取消**——照写会在同一文档制造重复条目。该文件建议**本次不改**（或至多在 `combat-service.md` 侧加一句回链，不在 item 侧复述）。

## 已裁决（不进 interview）

1. **`counters` 键约定 → A：`<abilityId>[#<子名>]`，`#` 前一段须能经 `ContentRegistry` 解析出 `AbilityData`（悬空校验）。** 依据链已核实：`AbilityData` 是带稳定 `Id` 的独立资源（`deck/common-properties.md` L19–26）、`PowerData.Abilities` 至少一个可多个（`power/_index.md` L19）、`ContentRegistry` 确实按 `Id` 取 `AbilityData`（`combat-service.md` L368）。
2. **法宝 `CharacterItem.Charges` 与古宝对称、即时写。**（= 确认既有，见上方订正）
3. **`combat-service.md` 已写的 `counters` / `CombatItemSave` 两格视为已批准定案** ⇒ §1 / §4 为回填；三处落后登记（`open-questions/01-combat.md` · `power/_index.md` · `player-item/_index.md`）一并改正。

**三处 ⚠ 回填已逐处核实属实：**
- `open-questions/01-combat.md` **L21**「战斗内运行态的决策点存档形态（本次归集）…字段形态未定」→ 属实，落后。
- `systems/character-profile/power/_index.md` **L54**「`Power` 的战斗内运行态存档形态未定」→ 属实，落后。
- `systems/player-profile/player-item/_index.md` **L39**「战斗内道具运行态的存档形态未定」→ 属实，落后。

## 🔴 冲突

- **[问题陈述] §3 的计数时机自相矛盾：「触发式 = 压栈成功时 +1 / 启动式 = 支付 `ActivationCost` 成功之后 +1」与同段「fizzle 掉的条目不计数」互斥。** ✗ 权威：`combat-service.md` L166 栈条目 `targetState`、L174/L200 与「全部有目标的槽位都非法 → 整条不结算」——**fizzle 发生在弹栈结算那一刻，晚于压栈与付费**。按草稿写法，一条压了栈但结算时 fizzle 的异能仍会 +1，直接违反它自己那句「一条没结算的异能不该吃掉配额」。
  - 选项 (a)：**计数写在「异能实际产生效果的那一刻」（弹栈结算成功后）**，删掉「压栈成功时 / 付费成功后」两句。后果：`BumpCounter` 的调用点唯一、落在 StackManager 的结算收口回调里而非压栈处；`ActivationCost` 已付但 fizzle 的启动式**不吃配额**（成本仍不退，与「`SelectCost` 不回滚」同纪律）。
  - 选项 (b)：**计数写在「宣告那一刻」（压栈 / 付费成功）**，删掉「fizzle 不计数」。后果：配额闸门更简单（宣告即扣），但玩家可能因自己选错目标而白白吃掉「每场一次」的配额，与既有「fizzle 是玩家可预期的结果、不做补偿」之外的负反馈叠加。
  - 选项 (c)：**两档分开**——启动式在付费成功时计（成本已付即视为用掉），触发式在结算成功时计。后果：内容侧要背一张「哪类异能在哪一刻扣配额」的例外表。
  - **推荐 (a)。** 理由：草稿自己给出的论据（「一条没结算的异能不该吃掉配额」）只有 (a) 兑现；且 `combat-service.md` 已把「整条不结算」定为一个明确的终态，把计数挂在这个终态上不需要新概念。

- **[问题陈述] §5 第一条（`counters` 键的 `abilityId` 段解析不到 → `PushWarning` + 丢弃）与 `combat-service.md` L174 读档校验 ② 直接抵触。** ✗ 权威：`combat-service.md` L174 校验 ②「`cardId` / `sourceId` / **`abilityId`** 解析不到 → `PushError` 并报出 id」——**同一份文档、同一块 `ActiveCombat`、同一类 id，两处给出相反的失败语义**。草稿只在论证里提到「读取侧不过滤 `ContentEnabled`」，但那解释的是**被关闭**的条目仍能取到，与**解析不到**（真悬空）是两回事：真悬空意味着内容被删或键被写错，`PushWarning` 会让一次内容删除静默吃掉玩家的配额状态。
  - 选项 (a)：**统一为 `PushError` + 抛**，`counters` 键的 `abilityId` 段与其余 `abilityId` 同档，L174 ② 不动、只在字段说明处点名它也受 ② 约束。后果：一次内容删除会让进行中的战斗无法恢复（但既有 ② 本就如此，`sourceId` 悬空同样致命）。
  - 选项 (b)：**给 `counters` 键开显式例外**，改写 L174 ② 为「…解析不到 → `PushError`；**`counters` 键内的 `abilityId` 段除外 → `PushWarning` + 丢弃该键**」，并写明理由（计数器是纯配额运行态，丢失只影响一次配额、不破坏局面）。后果：`combat-service.md` 的校验条款多一条例外；「战斗中途内容被删仍能恢复」多兑现一格。
  - 选项 (c)：**`PushWarning` + 保留该键原值不丢弃**（不解析、不消费，恢复后仍占配额）。后果：最保守——既不阻断恢复也不放宽配额，但引入一个「存在但无人能解释」的键。
  - **推荐 (b)。** 理由：既有 ② 的括号注释本身就是为「战斗中途某条目被线上关闭仍能恢复」写的，方向一致；且丢一个计数器的最坏后果（多用一次「每场一次」）远小于废掉一场进行中的战斗。**但必须在 L174 就地改写把例外写明**，不能只在新段落里加一行——那正是本库会漂移的形态。

## 🟠 含糊

- **[问题陈述] 键约定 A 排他之后，「非异能计数器」往哪放？** 战场条目 `counters` 的类型说明是中性的「运行态计数器」（L162），而 `KeywordKind.State` 展开出的 `Transient` 条目（`BattlefieldEntryTemplate = AbilityData[] + 生命周期三件套`，`deck/common-properties.md` L68）以及 `KeywordRef.Amount` 的**叠加层数**（同一状态被施加两次会不会累加？文档未定）都不天然对应某条 `AbilityData`。
  - 可解读为 (a)：`counters` **只**承载 per-ability 配额，其余一律不存 → 键约定纯净，但「同一关键字状态叠加 N 层」这类效果日后无落点，要么再开字段要么再开条目。
  - (b)：键约定放宽为「`<abilityId>` **或** `<keywordId>`，两者都须可解析」→ 悬空校验仍成立，覆盖面更宽；代价是解析时要试两个注册表。
  - (c)：暂不表态，只写「当前键的合法形态是 `<abilityId>[#<子名>]`；出现非异能计数需求时再扩」。
  - 推荐 (c) 或 (b)；**(c) 更稳**——关键字清单当前**归零**（`deck/common-properties.md` L74），现在就为空清单定第二类键是预铺。但必须显式写一句「当前仅此一种形态」，否则读者会以为 `counters` 什么都能塞。

- **[问题陈述] `CardInstanceSave.Counters` 的消费面无人承载。** §2 要求它与战场条目 `counters` **共用同一套键约定**，但 §3 的 `GetCounter(entryId, key)` / `BumpCounter(entryId, key, by)` 按 **`entryId`** 索引、挂 **BattlefieldManager**；卡牌实例不在战场上（`instances` 挂参战方 `sides`，由 CharacterManager / EnemyManager 的 `DeckModule` 侧持有，L133 / L220）。照草稿落地会出现「约定共用、API 只覆盖一半」。
  - (a)：签名改为按**统一的运行态载体引用**寻址（战场条目与卡牌实例各一枚 id，用一个 `CounterHost` 判别式或重载两个方法），实现落 BattlefieldManager + 参战方各一处。
  - (b)：只定战场条目一侧的 API，`CardInstanceSave.Counters` 的读写形态留待卡牌效果系统落地时再定（本稿只定存档形态与键约定）。
  - (c)：把计数器读写整体上提为战斗服务级的一个小门面（不挂任一 manager）。
  - 推荐 (b)：本稿的自我定位就是「只定形态」，且 `CardData` 字段清单本就未定案（`open-questions/01-combat.md` L27）。但需在文档里写明这是**已知的未覆盖面**，不要让 §2 的「共用一套」读起来像 API 也共用了。

- **[问题陈述] 「每场限 N 次」的闸门在何处读、能否被栈穿透。** §3 只说「启动 / 触发之前读到当前计数」。若采纳 🔴-1 的 (a)（结算成功才 +1），则在**结算之前**闸门读到的仍是旧值——玩家侧因「无优先权内循环、栈清空才回到行动阶段」（L166 / L188 D2）不会连续宣告两次，但**连锁触发**（多条同源触发同时压栈）可在同一次结算链内全部通过闸门。
  - (a)：闸门只在**宣告 / 触发注册**那一刻查一次，接受连锁链内的穿透（认定为极罕见）。
  - (b)：结算时**再查一次**（双查），链内第二条到达时计数已 +1，自然被拦。
  - (c)：为配额引入「已预留」计数（宣告即预留、fizzle 时释放）。
  - 推荐 (b)：一次额外查询，无新状态，且与 (a)-计数时机组合起来行为闭合。(c) 引入第二份运行态，与本稿「不新增结构」的取向相悖。

- **[问题陈述] 子计数器名 `<name>` 的形态与校验。** 草稿只写「点分小写短标识」，未定是否在加载期 / 读档期做正则校验、`#` 分隔符是否会与 `AbilityData.Id` 本身的合法字符冲突、`content/_index.md` 的 id 约定表是否要登记。
  - (a)：写死正则（如 `^[a-z][a-z0-9]*(\.[a-z0-9]+)*$`），读档期不匹配 → `PushWarning` + 丢弃该键；并规定 `AbilityData.Id` 不得含 `#`（加载期 `PushError`）。
  - (b)：只写形态描述，不加机械校验，等 `content/` 的 id 约定表成型时统一定。
  - 推荐 (a) 的后半句为**必须**（`AbilityData.Id` 不得含 `#`，否则 `#` 分隔在语法上就不成立，这是键约定 A 的隐含前提，草稿没写）；前半句（子名正则）可取 (b)。

## 🔵 可推演

- `Power` 本场触发次数 = 战场条目 `counters`，不新增结构 —— 依据 `combat-service.md` L162 / L164（已成文，本次仅回填其余文档）。
- 未入场的 `Power` 没有战场条目 ⇒ 没有计数器落点，是自洽而非缺口 —— 依据 L172「`Power` 的入场本身」由三条与门重放 + L224 三条与门原文。
- `PlayerPower`（账号级）的本场计数落轮回级 `ActiveCombat` 不是层级错配 —— 计数寿命 = 本场，与 `PlayerProfile` 上的持有 / `status` / 残卷语义不同，不构成双写（判据与 `enemyRef` 拒绝整份拷贝同款，L135）。
- 敌人的 `Power` 同表承载（`ownerSide = Enemy`），不另立第二结构 —— 依据 L157 + L217「单一战场记录，不分双场区容器」。
- `CombatItemSave` 不带 `Scope` —— `ItemData.Scope` 是内容侧静态字段（`item/_index.md` L10），与「`CardType` / `Subtypes` 不落存档」（L146）、「栈内位置不落 `position`」（L166）同款判据。
- 敌人道具的次数上限只能靠 `UsesThisCombat` 对 `ItemData.Charges` 比 —— `ItemData.Charges` = 上限/初值、持有条目上的才是剩余次数（`player-profile/_index.md` L65），而敌人无 Profile 持有条目（L222 / `enemies/common-properties.md` L19）。
- 值域 `>= 0`、为 0 的键不写入 —— 与 `CardInstanceSave.Counters`「空则整字段省略」（L142）同向。
- `ActiveCombat` schema 不变 ⇒ 2–4 KB / 决策点与 ≈93 KB / 场的量级不受影响，版本化仍是随下一次 bump 的空迁移 —— L176 / L178。
- §5 第三条（`CombatItemSave.ItemId` 不在重建出的「本场可用道具」内 → `PushWarning` + 丢弃该条）—— 与 L172「本场可用道具列表不落存档、按 `UsableScene` ∩ 持有 ∩ ¬`disabledAbility` 重建」一致，丢弃一条已不可用道具的计数无副作用。
- §5 第二条（值为负 / `UsesThisCombat < 0` → `PushError` + 抛）—— 与既有 ③ ④「内部一致性破损」同档。
- 内容侧纪律「每场限 N 次类异能必须给自己的 `AbilityData` 一个稳定 `Id`」—— `AbilityData` 本就必带 `Id`（`deck/common-properties.md` L26），故只是把已有约束显性化。

## 拟改动文档清单（供跨草稿核对）

- `systems/services/combat-service.md`：
  - 战场条目字段表 `counters` 行 / 其下引述块（L162–164）**扩写**：键的 BNF（`<abilityId>["#"<子名>]`）、`#` 前一段须经 `ContentRegistry` 解析出 `AbilityData`、值域 ≥0、0 不写入、与 `CardInstanceSave.Counters` 共用同一套键约定、`AbilityData.Id` 不得含 `#`。
  - **L174 读档校验就地改写**（🔴-2 的裁决落点）：给 ② 加 `counters` 键的例外条款，并追加「值为负 / `UsesThisCombat < 0` → `PushError`」「`CombatItemSave.ItemId` 不在重建结果内 → `PushWarning` + 丢弃」两条。
  - **L170「战斗内道具运行态」段追加两句**：法宝一侧对称即时写（**回链** `systems/character-profile/item/_index.md`，不复述）、敌人侧次数上限靠 `UsesThisCombat` 对 `ItemData.Charges` 比。
  - **L217 BattlefieldManager 职责行或其后**：`GetCounter` / `BumpCounter` 两个签名 + 计数时机（🔴-1 裁决）+ 闸门查询时机（🟠-3 裁决）。
  - ⚠ **写入面重叠预警**：`combat-service.md` 体量 80 KB / 401 行，且是多份草稿的共同注入点。**必须由单一 worker 串行写。**
- `systems/character-profile/power/_index.md`：删除 L54 待决问题条目，改写为意图段的一句（`Power` 战斗内运行态 = 战场条目 `counters`，形态权威回链 `combat-service.md`）。
- `systems/player-profile/player-item/_index.md`：删除 L39 待决问题条目；`CombatItemSave` 形态**不复述**，只留一句回链。
- `systems/character-profile/item/_index.md`：**建议不改**（L31 已明写即时写；草稿要求的补写会造重复）。若 orchestrator 坚持留痕，至多在 L31 后加半句「与古宝一侧对称」。
- `systems/character-profile/deck/common-properties.md`：**只在采纳 🟠-1 的 (b) 时**才需要动（`KeywordData` 侧补一句 counters 键可为 `keywordId`）。默认不动。

## 待移出的 open-questions 条目

- `open-questions/01-combat.md` → `## 结构与配置的残留` → **L21「战斗内运行态的决策点存档形态（本次归集 · 此前未进清单）」整条移出**（草稿裁决 #1 使键约定落定，两块运行态形态齐备）。
- answer log 建议文件名：`answer-logs/log-combat-runtime-counter-persistence.md`（`solution-draft-<slug>` ⇒ 取 slug；已核实同名文件不存在）。移出条数 1（若 🟠 中有项被裁决为「留待后续」，需在 log 中写明剩余部分仍留在待答清单，并把剩余部分作为新条目并回 `01-combat.md`）。
- **台账行（由 orchestrator 代笔）**：`answer-logs/_index.md` 追加 `log-combat-runtime-counter-persistence.md | 2026-08-22 | inbox/solution-draft-combat-runtime-counter-persistence.md | 1`。

## 越界发现

- `open-questions/01-combat.md` L5 的「已答结并移出」摘要块已膨胀到单行数千字，且 L7–L9 的治理提示块含大量过程坐标（`08-15d` / `08-06d` / 「一律作废」）。**不属本分片范围，未处理**——但 `01-combat.md` 会被本批多个分片同时触碰，属共享台账，须由 orchestrator 单写。
- `systems/character-profile/power/_index.md` L14 正文含「出入 / 不引入指挥区」等对比论述，属正常设计论证，非违规；未处理。
- 本稿多处引用 `player-profile/player-power/_index.md` 的「每场一次重排手牌 / 查看抽牌堆顶」样板能力作为「本场配额确实存在」的依据——未逐字核实该文件（超出分片必读面），若 orchestrator 需要可补验。

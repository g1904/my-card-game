# Answer log effect-keywords-and-targeting

- 日期：2026-08-16
- 来源：`inbox/archive/solution-draft-effect-keywords-and-targeting.md` → `handoffs/2026-08-16c-effect-keywords-and-targeting.md`
- 移出条数：1

---

**效果关键字体系与目标规则（承重 · 需一次专门 handoff）** → **整条答结**，分两半：

**① 关键字体系** = 一个内容层的注册表条目 `KeywordData : Resource`，形态与次类型同构（稳定字符串 `Id` · ContentRegistry 加载 · `.tres` 编写 · `ContentEnabled` · **不挂 `Rarity`**）。两种 `KeywordKind`：`Action` 展开为一段 `EffectData[]`（第一层）、`State` 展开为一份 `BattlefieldEntryTemplate`（第二层）；**它是命名与复用的一层，不新增第三种效果载体**。参数化 = 单个 `Amount` 占位（`HasAmount` + `KeywordRef`），不做通用表达式。**展开在结算时做，不在加载时内联**（否则 overlay 热更后已加载的卡牌拿旧展开）。**首批清单为空、机制保留**，准入判据照抄次类型两条（≥3 条目共享 + ≥1 处筛选或 payoff 引用）。
否决三个备选：C# 枚举 `EffectKeyword`（内容侧可扩展的词汇不该焊进枚举，overlay 永远补不上）· 纯呈现层文案简写（战场条目没有筛选键，「移除所有带某状态的条目」写不出来）· 通用表达式 / 小型脚本语言（把「效果是数据不是代码分支」拖回需要求值器与沙箱的形态）。
（→ `systems/character-profile/deck/common-properties.md`「效果关键字体系」、`terminology.md`、`content/_index.md`）

**② 目标规则的完整判据** = **目标 target 与作用域 scope 分开建模**（承重，本条此前写不下去的直接原因），两者共用同一个筛选结构 `EntryFilter`、差别只在是否需要 `TargetRef` 锚定；「效果须显式声明目标类别」这条纪律只约束 `TargetSlots`。合法目标集 = **在需要它的那一刻对当前局面跑一遍筛选**，四条过滤（方位 / 类别 / 保护 / 筛选）**顺序非规则**。`SideConstraint` 一律相对施放者解析（`Pool = Both` 的直接推论）。结算时**逐槽位重检 + 部分 fizzle**（否决全有全无：5 回合定长无响应窗口下惩罚过重）。挂起态收窄为三条与门（`Kind ∈ { BattlefieldEntry, HandCard }` + `controllerSide == Character` + `LegalTargets.Count > 1`），`Count == 1` 自动选定、`Count == 0` 判非法走 fizzle。`HandCard` 槽位强制 `Self` 且只吃 `RequiredSubtypes`。
（→ `systems/character-profile/deck/common-properties.md`「目标（target）与作用域（scope）」、`systems/services/combat-service.md`、`ux/combat-ux.md`）

**草稿评审时定下的四项取向**（全部取推荐项，均已并入上述归档去向）：一槽位 = 一个目标（无 `TargetCount`）· 关键字提醒文本永远长按（首次不自动展开）· `EntryFilter` 组合语义恒为 AND · `IncludeFaceDown` 保留但默认不用。

**本次 interview 的三项裁决**（改变了草稿的结论，故一并记账）：

- **战场条目新增 `keywordId : string?`**，随下一次 schema bump（当前无线上存档 = 空迁移）。**推翻草稿「不 bump 存档 schema」**——草稿把该结论建立在「只补声明侧」上，而它自己的头号理由（战场条目要有关键字筛选键）落在运行态侧，且该键**不可由 `sourceId` 推导**。
- **`PlayCard` 签名改收 `IReadOnlyList<TargetRef>`**，挂起三条件**只适用于结算侧槽位**。草稿建议 5 未区分主动出牌槽位与结算侧槽位，照字面读会与既定「入栈时 `targetState = Resolved`」冲突并使决策点密度暴涨。
- **`HandCard` 槽位的 `EntryFilter` 只吃 `RequiredSubtypes`**，其余三格在该 `Kind` 下须为空（加载期 `PushError`）。草稿的四条过滤伪码把手牌与战场条目混在同一条筛选链上。

**顺带清理的两处漂移**（本就不是待答项，不计移出）：`CombatSnapshot.IntentView? Intent` 删除（意图机制整条移除后的残留）· `PendingTargetRequest` 补 `SlotIndex`（存档侧 `pending` 已有该格，视图侧缺）。

**新增待答 1 条**：关键字与次类型的首批清单（归 ch1 数值标杆专场，切入点 = starter deck）→ `open-questions/01-combat.md`。

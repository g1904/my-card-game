# 事件产出的卡牌取池链 · 与「牌送回抽牌堆」开口

- id: 2026-08-27-card-pool-and-reshuffle
- date: 2026-08-27
- topic: systems/adventure-event/common-properties · systems/character-profile/deck/_index · systems/services/combat-service · systems/balance · decisions/ADR-0052
- status: distilled
- distilled-to: systems/adventure-event/common-properties.md, systems/character-profile/deck/_index.md, systems/services/combat-service.md, systems/balance.md, decisions/ADR-0052-no-reshuffle-fatigue.md

## Intent（distilled）

两个子问题各自独立，同批落笔只因写入面重叠。

### ① `OutcomeRule.DeckOperation` 的「该 `Op` 对应的池」

**保留走池抽，并收窄为仅 `AddLooseCard` 一个 `Op`**；其余四个 `Op` 的 `TargetId` 必填非空（`UpgradeTechnique` 的 `Tier` 是目标层数、一次抽取给不出两个量；`ForgetTechnique` / `RemoveLooseCard` 的「池」是玩家当前卡组即运行期状态；`LearnTechnique` 见下）。这同时把「留空即无从物化」这个静默口子堵死。

- **取池链逐字沿用商店 `Card` 族那一条**：`AllEnabled()` → `Pool != Enemy` → 排除功法成员卡 → `CardTypeFilter` → `RarityFilter` → 按 `RarityTier` 权重表 `PickMany` 无放回。**子流复用 `RngStream.Reward`**（既有明文，不新开）。
- **新增一格 `CardTypeFilter : CardType[]`**，使「随机塞两张业障」写得出来（`[Affliction]`）。原反对意见（「业障从通用卡牌池抽讲不通」）反对的是**通用池**、不是走池抽，收窄后即成立。`RarityFilter` / `Count` 与 `GrantFromPool` **共用既有两格**，不重复声明。
- **`LearnTechnique` 不开池抽**：它会造出唯一「随机塞给你、不给选」的第五处功法获取，且功法池抽需排除已持有 ⇒ 需读 `Profile` ⇒ 撞 `ADR-0068` 的两级边界。内容侧有等价出口（多条定值 `TargetId` + 模板分支 / Research 三选一）。

### ② 卡牌效果把牌送回抽牌堆

**开口**，但形态限定为 `MoveCard` 的**目的地扩展**，不是新增一条重洗规则。

- **首批只开「抽牌堆顶 / 底」两个确定性位置，不开随机位**——随机位才使抽牌堆重新成为战斗中途的随机消耗点；顶 / 底对玩家可读、可规划。
- **护栏落在载体消耗性上**（法术天然一次性 · 道具须有限充能 · 启动式异能有 `ManaCost` / 配额两格闸 · 静止式在结构上装不下原子操作），外加「`Count` 必须有限、『整堆 / 全部』形态硬禁」——那正是被否决的规则性重洗换个写法。
- **同批重写三句措辞**：`combat-service.md` 推论 ④ 与其前瞻注记 · `deck/_index.md`「只减不增」。并收掉 `deck/_index.md` 内「闭集流转 `⇄`」（对）与「只减不增」（错）的自相矛盾——**改的是后者，不动 `⇄`**。
- `ADR-0052` 只在**后果**补一条边界说明（决策 / 理由 / 备选三节不动）：它否决的是规则性、无限次的弃牌堆回流重洗，有限次消耗性的一次性效果不落在那条理由的射程内。

## Clarifications（interview 产物）

- **触发式载体携带回堆效果，草稿要求它「须有配额」，与既有校验「配额只对启动侧成立」互相排斥**（两条永不可能同时通过）→ 裁决：**允许触发式携带，不加配额、不加任何新校验**。论证与疲劳那条同源——`TurnLimit` 是终止性的硬护栏；同批已推翻「启动式必须有有限性闸」这条硬性限制，无限组合是被接受的设计面。
- **池容量校验 5f（加载期硬闸）与「事件产出侧不加加载期池断言」的既定分界相反** → 裁决：**保留 5f 但降为清单式 `PushWarning`，不拒绝加载**。两侧承重点都不放弃：作者仍能在启动期看到池有多大，而「事件产出没付过钱 ⇒ 短缺不构成空面板」的既定分界不被推翻；运行期的物化期降级 + `PushWarning`(want / got) 照旧。
- **`MoveCard` 的目的地形态与同批 ability 草稿冲突**（两份对同一字段给出两套形状）→ 裁决：`To : CardZone` 保持四值 + **独立一格 `InsertPosition { Top, Bottom }`**；校验「`From == To` → `PushError`」放宽为「且 `To != DrawPile`」⇒ **抽牌堆内重排（把堆顶废牌压到堆底）可写**。
- **`AddLooseCard` 池抽用哪张稀有度权重表**（全库只有两张，分表维度是用途）→ 裁决：**挂战后奖励池权重表**（族维度已含卡牌、同为轮回内用途）；**事件产出侧固定取一档，不按战斗优势档选表**。取值一格不动，仍归待答清单。
- **`MoveCardEffect` 可把对手抽牌堆的牌搬走，触发了「疲劳扣减是否进 `EncounterSpec` 覆写组」的重开判据**（跨草稿追加）→ 裁决：**允许该形态、不加校验**；`balance.md` 那条理由改写为「该形态已存在但很窄」，**重开判据触发，作为一条新的待答项登记，本次不答定、不改任何数值**。

**标准默认（自动采纳，不占 interview）：**

- **池抽在物化时掷定**，随定稿实例落存档、绝不重抽（草稿「不需要额外保护」那句作废——落存档是自动且强制的，Combat 类的产出在战斗之后结算，其间隔着多个决策点）。
- 实际只新增 `CardTypeFilter` **一格**（`RarityFilter` / `Count` 共用既有格）。
- 静止式载体那条校验**不单列**（由 `AbilityData` 的 XOR 校验结构性吸收）；`Count` 有限那条也不单列（`Count : int` 的形状已封死「整堆」）。正文保留两条正面纪律。
- 载体术语按本库口径：法宝 = `CharacterItem`（`Charges` 允许无限）· 古宝 = `PlayerItem`（`Charges > 0` 已是硬约束，且事件产出不能给账号级古宝）⇒ 道具侧的闸实际只有「`Charges == -1` 的法宝不得携带该操作」一条。
- 短缺处置沿用既定的物化期降级 + `PushWarning`(want / got)，不补位、不提示、不新增文案键。
- `ADR-0041` 的读档校验（三区 `Id` 序列并集 = `instances` 全集）不受影响：回堆是闭集内的区间搬运。**无存档 schema 变更、无迁移。**
- 引用 `ADR-0088` 时按其当前措辞写「以 `TurnLimit` 为硬护栏允许疲劳被**削减至 0**」，不写「可被取消」。
- 不制造第二个数字口径：牌流入上限沿用 `balance.md` 的现成口径，不在本次另算一份。

## Open questions

- **`RarityTier` 的分布与权重表取值**：结构已挂靠（战后奖励池那张表），各档权重仍待定。
- **疲劳扣减是否进 `EncounterSpec` 覆写组**：重开判据已触发，需重新评估（本次不答定）。
- `GrantFromPool` 的取池链在事件侧同样没有落点，要跳到 `systems/services/future-event-service.md` 才读得到——**既有的不对称，非本次引入**，宜顺手补一句回链。

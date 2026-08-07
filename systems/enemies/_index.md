# enemies（敌人）

> 敌人的内容定义与物化规则：`EnemyData`（模板）↔ `EnemyInstance`（物化定稿实例）、样本卡组、item / power 持有列表、作用域与池归属、赋级带的接受面。

**与 `adventure-event` 平级的一个系统。** 三类战斗事件（Combat / Practice / Finale）**共同引用同一批敌人条目**（天劫也是 Enemy 的一种），把共用类型挂在其中一个使用者名下违反归属直觉。这**不违反「内容并入系统、不单列内容层」**——本目录不是一个泛化的内容层，而是承认 `Enemy` 已具备独立的「类」身份：它有模板 ↔ 实例二元、有自己的 `.tres` 注册表、有独立的图鉴引用面、有自己的赋级规则。并列的另两个二元中 `Card` 住在 `character-profile/deck/`、`AdventureEvent` 住在 `adventure-event/`，三者因此在归属上对称。

## 意图

### `EnemyData` —— 静态内容条目

- **`[GlobalClass] partial class EnemyData : Resource`**，稳定 `Id`，一个 `.tres` 一条，经 `ContentRegistry` 加载并按 `Id` 建索引；带共有字段 `ContentEnabled`。**抽取一律走 `AllEnabled()`，读取侧 `Get(id)` 不过滤。**
- 字段（当前已定的部分）：

  | 字段 | 语义 |
  |------|------|
  | `Id` | 稳定唯一键 |
  | 图鉴五项词条 | 人物背景 / 功法简介 / 运作方式 / 特点与弱点 / 关键卡牌；写作规格见 `systems/player-profile/codex/enemy-codex.md` |
  | `KeyCardIds : string[]` | **长度 2–3**，必须是样本卡组内的 `Id`。图鉴「关键卡牌」词条的数据源，**显式标注不自动挑选** |
  | 样本卡组 | 物化时按赋级对齐 / 风味替换；**规模固定 15，允许同名条目重复** |
  | item 持有列表 | 敌人没有储物袋，道具直接挂模板 |
  | power 持有列表 | 开局入场的受保护永久物；「不可被移除的场上特性」是 boss / 天劫最自然的表达 |
  | `EncounterScopes : EventType[]` | 可出现在哪些事件类型（仅限 `{ Practice, Combat, Finale }`）；**空数组 = 数据缺陷 → 加载期 `PushError`** |
  | `PoolScope` | 池归属：**通用 / 某地点专属 / 某剧情线专属**。**为空 = 通用池，不报错** |
  | `OverridesDeck : bool` | 定制卡组标记（天劫等）；为 `true` 时跳过「关键卡牌不得被改写」的检查，图鉴条目自带说明 |

- **敌人等级不在模板上定死**——等级是 future-event-service 的**物化产物**，故同一个敌人可在不同篇章 / 情境下以不同等级出场。
- **敌人持有道念、意图、行为，并持有自己的卡组**；**敌人侧的战斗内量与玩家侧对称**，也是道念，不设独立的血量池。
- **敌人的战斗强度以 `baseMomentum` 为主刻度**：等级 → 起始道念 → 开局领先量，这是越级压迫感的直接来源。**卡组保持强度中立，不叠第二条强度曲线**（否则 `±2` 带的数值安全性推导立刻失效）。

Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` + `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

### `EnemyInstance` —— 物化定稿实例

```csharp
public sealed record EnemyInstance(       // 物化定稿 · immutable · 随 EventOption 落存档
    string                InstanceId,     // 本次物化实例的稳定标识
    string                EnemyId,        // 溯源到模板：ContentRegistry.Get<EnemyData>(EnemyId)
    int                   Level,          // 物化赋级产物（全局序 1–22，落在角色 ±2 带内）
    IReadOnlyList<string> DeckCardIds,    // 改写后的卡组（Id 序列；闭集，无凭空生成的牌）
    IReadOnlyList<string> ItemIds,        // 本场可用道具
    IReadOnlyList<string> PowerIds);      // 开局入场的受保护永久物
```

- **性质对齐 `EventOption` 而非 `CardInstance`**：模板 ↔ 实例通则的三对里，`EventOption` 是定稿不可变、`CardInstance` 是运行态可变；敌人实例属前者——**物化产出即冻结、落存档、下游只读消费**。
- **战斗内的敌人运行态**（道念、手牌、卡组状态、已用道具、`Power` 计数器）由 **EnemyManager 持有**，不进 `EnemyInstance`，也不另立类型。
- **嵌在 `EventOption` 上随批次落存档**，不在战斗开始时二次展开。三条依据任一条单独成立即封死另一选项：**① 唯一物化点**（战斗开始时展开 = 在 combat-service 里开第二个物化点）· **② 选择界面就要显示敌人等级**（等级是物化产物）· **③ 意图档位在进入战斗之前即需可算**（`EventOption` 卡片上的越阶提示与风险评估都发生在战斗之前）。
- **本作不存在多敌人场景 —— 承载字段一律写单数** `EnemyInstance Enemy`：战斗模型恒为双方对称的两个参战方、道念各持一份、EnemyManager 一份。**不写列表、不留「日后可能变多」的伸缩位**——留一个恒长 1 的列表只会让每个消费点都要处理一个永不发生的分支。
- **已知代价**：`EnemyInstance` 嵌进 `EventOption` 会放大定稿快照的体积（一批 eventOptions 里每个战斗事件都带一份卡组 `Id` 序列），这让「增量 push 粒度」那条待答更承重。

Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

### 取池 —— 三层框定，全部叠在 `AllEnabled()` 之后

```csharp
var pool = ContentRegistry.AllEnabled<EnemyData>()
    .Where(e => e.EncounterScopes.Contains(spec.EventType))                    // ① 事件类型作用域
    .Where(e => e.PoolScope.Matches(currentLocationId, activePlotLineId));     // ② 池归属
    // ③ 篇章框定照旧
```

- **共享敌人池 + 作用域字段，而非另立一批「切磋对手」条目。** 依据：赋级规则已定为「挂 Enemy 不挂事件类型，三类战斗一视同仁」，其自然延伸是**敌人条目本身也一视同仁**；Practice 的低风险已由 `WinMargin: 0` 承担，不必靠特例；**内容成本**——敌人条目含图鉴五项 + 基准数值 + 样本卡组 + 两个持有列表，是本作最重的内容单元之一，翻倍不可接受。
- **承重论据 = 图鉴的正向增益**：共享池使玩家**能先在低风险的 Practice 里遇到并解锁某个敌人的图鉴，再在 Combat 里正式对上它**——这条教学路径正好补上「意图揭示退出教学职能」后留下的空缺。另立一批则图鉴要么翻倍、要么分裂成两套。
- **`PoolScope` 是剧情线表达差异化的唯一合法途径**：剧情线**不可调制敌人模板**，「大限将至」线上的绝境敌人 = **该线专属池里的一条完整 `EnemyData`**（自带更凶的样本卡组与 power），不是把通用条目临场改凶。好处：改写幅度天然有界、图鉴词条与实际遭遇恒对得上、可确定性复算；代价：内容量上升，归内容排期。
- **叙事一致性靠内容纪律**：标为 `[Practice, Combat]` 的条目，其图鉴与台词必须同时说得通「切磋」与「厮杀」两种语境——归 `enemy-codex` 的写作规格。

Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

### 赋级带的接受面

- **敌人等级的合法区间 = `[角色等级 − 2, 角色等级 + 2]`**，在全局序 1–22 上截断，**三章统一**；带边界是内容侧可调数值。**`±2` 是无例外的硬规则**——赋级函数不接受任何区间覆盖参数。
- **赋级规则挂在 Enemy 上、不挂事件类型上** ⇒ Combat / Practice / Finale 一视同仁；**天劫亦然**（角色在境界巅峰 13 / 17 / 21，天劫在下一境界初期 14 / 18 / 22，`diff` 恒为 +1 且必然越阶）。
- 带内分布权重、截断重分配、批内去重见 `systems/balance.md`；物化管线见 `systems/services/future-event-service.md`。
- **推论**：越阶遭遇只出现在每个境界的末两级（12·13 / 16·17 / 20·21），三章统一。

### 埋伏

- **敌人侧同样布置埋伏**，且**埋伏不进入意图的呈现**（意图只描述敌人自己回合的行动，埋伏在玩家回合触发，时间归属不重叠——它是被公开计数的「已知未知」）。
- **埋伏的既有规则对敌人侧原样适用**（同名不可重复、触发后进弃牌堆、面朝下、对手只见计数），不为敌人侧另立一套。
- 样本卡组可含埋伏 ⇒ 物化改写多一个旋钮（这一场带不带、带几张）。

Source: `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md`。

## 决策(-> ADR)

- **敌人模板与实例只有两个类型：模板统一定名 `EnemyData`（不存在第二层「模板」结构），实例定名 `EnemyInstance`，嵌在 `EventOption` 上随批次落存档；不存在多敌人场景（字段单数）** —— 已定案。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **enemies 升为与 `adventure-event` 平级的系统；三类战斗事件共享同一批条目，由 `EncounterScopes` 声明作用域** —— 已定案。Source: 同上。
- **剧情线不可调制敌人模板；剧情线与地点各自可拥有专属敌人模板池** —— 已定案。Source: 同上。

## 待决问题

- **敌人 AI / 意图规划逻辑：** 回合级一次性规划已定（见 `systems/services/combat-service.md` 的 EnemyManager），但具体的规划算法、多回合行为倾向、难度旋钮的落点未定义。
- **敌人各等级的道念产出缩放：** 起始值已由 `baseMomentum` 给定，产出能力的缩放曲线未定 → `systems/balance.md`（ch1 数值标杆专场）。
- **`PoolScope` 的数据形态：** 是一个带 `LocationId?` / `PlotLineId?` 两个可空字段的内嵌类型，还是一组 tag？与 location / 剧情线的内容条目如何交叉校验（悬空引用）？→ `systems/services/future-event-service.md`。

## 对应
提炼至：`.claude/knowledge/systems/enemies.md`（待建）

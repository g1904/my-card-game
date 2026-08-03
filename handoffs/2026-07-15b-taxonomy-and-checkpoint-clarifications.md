# 分类法定案 + 存档/重试模型澄清

- id: 2026-07-15b-taxonomy-and-checkpoint-clarifications
- date: 2026-07-15
- topic: 承接 2026-07-15-adventure-event-profiles 的 Open questions；feeds terminology, systems/adventure-event-combat, run-manager, map-progression, decisions/ADR-0002
- status: distilled
- distilled-to: terminology.md, systems/adventure-event-combat.md, systems/run-manager.md, systems/map-progression.md, decisions/ADR-0002-adventure-event-taxonomy.md

## Intent（你的原话，已提炼）

对 `2026-07-15-adventure-event-profiles.md` 的三组 Open questions 做出裁定。

### 1. 命名
- 单个节点用 **修行事件 / AdventureEvent**（不再用「修行历程」指代单节点）。「修行历程」可留作**整段旅程**（`List<AdventureEvent>`）的集合称谓。

### 2. 修行事件分类法（**定案**，六类）
六类保留；两处细化：
- **休养 / Rest 不单列**为顶层类型——它**并入 战斗 或 闭关** 之中发生。
- **未知 / Mystery 是元类型**：进入后才**揭示**为其它某一类。
- **修炼 / Practice ≈ 比试**（切磋 / 对练，低风险的战斗式历练）。
- **闭关 / Research ≈ 研究**（钻研 / 潜修）。
- 其余：战斗 / Combat、交易 / Exchange、社交 / Social。

→ 应你要求定为决策，见 `decisions/ADR-0002-adventure-event-taxonomy.md`。

### 3. 多角色 · 篇章存档 · 重试模型
- **多角色并行。** 玩家可同时持有多个角色（CharacterProfile）。
- **每个篇章内至多一个 `ongoing`。** 同一时刻，一个篇章推进只有一个进行中的角色态。
- **篇章边界 = 境界存档。** 篇章通关即在所达境界落一个存档点（例：打通炼气→筑基后，得到一个**筑基存档**）。
- **读档续章。** 从某个境界存档可读档，开始下一篇章（如从筑基存档开始「筑基→金丹」）。
- **炼气起手 = 随机角色，可无限重试。** 第 1 篇章（炼气→筑基）以随机生成的角色开局，失败可无限重来。
- **存档后的角色有重试上限。** 一旦落下境界存档（越过第 1 篇章），该角色在后续篇章有**有限的重试次数**。

**隐含结构（推演，非新增机制）：**
- 篇章边界的「可用结束点」= 到达下一境界所落的**存档点**；这回答了 map-progression 的元进程契约之一。
- 篇章途中死亡 → 从该篇章的**起始存档**重试；第 1 篇章无限、后续篇章有限——这界定了本作的 roguelite 手感（入门无惩罚，越深越珍贵）。
- 境界存档过的角色是一种**有限资源**（重试会耗尽），构成元进程的张力。

## Open questions
- **篇章间继承什么？** 读档续章时，角色带入下一篇章的具体内容（deck、relics/法宝、属性、叙事标记）仍未逐项敲定。→ `systems/map-progression.md`、`run-manager.md`。
- **重试上限的数值。** 存档后角色的重试次数是多少、是否随境界递减——属平衡待调项。→ `30-content/balance.md`（未来）。
- **「每个篇章至多一个 ongoing」的精确语义。** 解读为：同一角色谱系不能并行两个同篇章的进行中尝试；但不同角色（不同存档谱系）可并行处于各自的篇章。请确认此解读。
- **篇章边界高潮事件。** 境界突破（渡劫 / boss）是作为一场 战斗/Combat 事件发生在篇章末，还是独立于分类法的存档转场？（此前 (b) 项）——倾向：突破即存档转场，若含战斗则复用 战斗/Combat 类型。请确认。

## Notes / triage
承接式 handoff，裁定前一份的 Open questions。分类法 → `adventure-event-combat.md` + **ADR-0002**。存档/重试模型 → `run-manager.md`（状态机、多角色、重试）+ `map-progression.md`（篇章衔接 = 境界存档、死亡重试）。命名 → `terminology.md`（修行事件）。

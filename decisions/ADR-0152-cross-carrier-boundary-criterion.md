# ADR-0152 — 跨载体边界判据：卡牌 / 法宝 / 神通共用一张按代价排序的表

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** handoffs/2026-09-03-character-power-mechanics.md

## 背景

一个新想出来的效果该做成一张卡、一件法宝，还是一个神通？此前三者各有自己的定义文档，但**没有任何一处回答「边界在哪」**。缺这条判据的直接后果是内容侧按直觉分配载体：把一个累积型效果写成神通（它没有任何节流阀，一局拿两条就能把定长的战斗打崩），或把一个战斗外的全局改写写成法宝（`ItemData` 上根本没有落点）。三者共享同一套 `RarityTier` 与折价换算体系，误分配不会在任何一处报错，只会在平衡上显形。

以「可在一局里被重复触发多次」这类**表象**排序也不成立——它对神通与阵法同时成立，照此判定会把神通误判成卡牌。

## 决策

**立一张三者共用的跨载体边界判据表，按「这个效果要付什么代价才能生效」排序，第一条命中即定型：**

- 需要**消耗 mana、按次打出、每次生效都重新付一次代价** → **卡牌**（`Sorcery` / `Enchantment`）；
- 需要**明确的使用次数上限、由玩家主动在某一刻花掉** → **法宝**（`ItemData`，`Scope == Character`）；
- **存在即生效、无代价、一局内不消耗**的常驻改写 → **神通**（`PowerData`，`Scope == Character`）。

**本表是三者边界的唯一权威，住 `systems/character-profile/power/_index.md`**；`systems/character-profile/deck/_index.md` 与 `systems/character-profile/item/_index.md` 各留一行回链、不复述。四条推论与逐条依据同住该表。

## 理由

- **代价才是承重条件。** 判据表按代价面排序的理由是：`PowerData` 同时缺 mana 与次数上限两格，`ItemData` 不设 `Abilities` ⇒ 载体的表达力上界本就由「它有没有节流阀」决定，判据只是把这个既有事实读出来。
- **「无节流阀」是神通的定义性约束，不是它的便利**——由此直接得出「任何随对局延长而累积的效果一律不得写成神通」，这条对神通比对法则更硬（法则另受配额纪律与老账号全开校准约束）。
- **战斗外的改写只能写成神通**：法宝的战斗外表达力上界是一次性、恒定、无随机的 `ProfileChangeSpec`，改写 capability flag / modifier pipeline 在 `ItemData` 上无落点。
- **回寿的效果恒不得写成神通**（已有加载期 `PushError` 兜底），只能是法宝或事件产出。

## 备选方案

- **按「能否在一局里被重复触发多次」排序** — 否决：该条对神通与阵法都成立，不是区分项，照抄会把神通误判成卡牌。
- **三者各自在自己的文档里写一段边界说明** — 否决：三份措辞必然各自漂移，而本库无机制发现；判据表定为单一权威、另两处只回链。

## 后果

- 三者共享 `RarityTier` 五档与既有折价换算体系这一点被明写为推论；神通侧对应的强度刻度另立（见 `decisions/ADR-0153-character-power-strength-ceiling.md`）。
- 「不得随对局延长而累积」的可机械化那一半落成加载期 `PushWarning`，口径见 `systems/character-profile/power/_index.md`。
- 受约束的文档：`systems/character-profile/power/_index.md`（表本体 + 四条推论）· `systems/character-profile/deck/_index.md` · `systems/character-profile/item/_index.md`（各一行回链）· `systems/balance.md`（强度刻度侧回链本表）。
- 内容层 `content/character-power/` 开张时，其字段核对清单从 `power/_index.md` 的「内容编排口径」子块回链取用。

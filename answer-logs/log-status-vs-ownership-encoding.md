# Answer log status-vs-ownership-encoding

- 日期：2026-09-06
- 来源：`inbox/solution-draft-status-vs-ownership-encoding.md` → `handoffs/2026-09-06-status-vs-ownership-encoding.md`
- 移出条数：**1**（`open-questions/deferred-content.md` 的 `status` 半句 + 整个 ⚠ 矛盾段；该条目的 `Achievement` 那一半仍留在待答清单）

## 移出的待答项

**`status`（启用 / 禁用）与「拥有 / 失去」两个正交维度如何编码进 schema** → **编码本身早已成文**，本次是一次**对齐**而非裁决。权威在 `systems/player-profile/_index.md` 的四条持有条目 record（`CharacterItem` / `CharacterPower` / `PlayerItem` / `PlayerPower`，共有 `bool Status`），并已进 v1 登记表（四类条目定形 + 四个持有列表顶层键）。

**连带裁定的一处「矛盾」不成立。** `profile-service.md` 的「正交两维」句与元进程待决项**并不互相矛盾**：后者的括号是一句**显式排除**，明写本编码已成文并给出权威，被索引读成了「登记为未定」。本次把该括号提为独立句，消掉再次被误读的可能。
（归档去向：`systems/services/profile-service.md`、`systems/architecture.md`、`systems/services/profile-schema-versions.md`、`systems/player-profile/_index.md` 及四份下游文档）

## 逐条裁决

1. **唯一真实缺口 = `Status` 没有写入通道** → 新增 `ProfileChangeSpec.AbilityStatusChanges`，元素 `AbilityStatusAssignment(Kind, Scope, AbilityId, Enabled)`，语义 = 按 `(Kind, Scope, AbilityId)` 的绝对置值。**分列而非给 `AbilityElements` 加 `Op`**：该列明文定位「改变持有」且 `Source` 强制携带，而开关不改变持有、无来源、`Duration` / `PairKey` 恒空。同族先例 `SettingChanges`。
2. **门面收敛为一个方法** → `SetAbilityStatus(AbilityCarrierKind kind, AbilityScope scope, string abilityId, bool enabled)` 替换只覆盖 power 的旧签名；`kind` / `scope` 不给默认值。判据是库内已用过两次的「两层用同一个门面、用 `AbilityScope` 选层」（`UseItemOutOfCombat` / `ConsumeItem`）。
3. **道具两类是否开放 `Status` 开关** → **选 A · 四类一律开放，门面一个方法覆盖**。连带采纳：**关掉的法宝仍占储物袋位、`Charges` 不变**（与「禁用不影响持有、也不影响 `Charges`」逐字同构）。未取「item 两类恒 `true` + 一条入口校验」，也未取「从 item record 上删掉 `Status`」。

## 采纳的标准默认（未出题）

- **四维落点表**（内容启用 `ContentEnabled` / 拥有 / 启用开关 / 本轮回禁用）与三条不变式（失去 ≠ 禁用 · 禁用不挤进 `Status` · 生效 = 三条与门）为既有内容的汇总，直接落笔。
- **反向澄清「`StatusChanges` 不承载本维」**写进 `profile-service.md` / `architecture.md` / `player-profile/_index.md` 三处——否则「`Status` 的变更走 `StatusChanges`」是几乎必然会被写出来的误推。
- **四条施加失败语义行 + 「`SelectCost` 内恒为空」不变式**照既有各列同款落笔；`EventOutcomeSpec` 那一行的理由是**内容不得代替玩家拨开关**。
- **老档缺 `status` 格 → 补 `true`**，默认值口径留在字段所在处。
- **不 bump**：新列追加进 v1 登记表既有的 `ProfileChangeSpec` 分列行；四条 record 与四个持有列表的形状零改动 ⇒ **零迁移、后端零配合**。

## 附带清理

四份下游文档指向「`profile-service.md` 的同名待决项」的回链**全部悬空**（该待决项不存在）：`systems/character-profile/item/common-properties.md` · `systems/character-profile/power/common-properties.md` · `systems/character-profile/power/_index.md` · `systems/player-profile/player-power/common-properties.md`。本次整条删除或改写为已定投影 + 回链。

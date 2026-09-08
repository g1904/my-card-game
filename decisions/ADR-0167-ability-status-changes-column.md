# ADR-0167 — 能力启用开关的写入通道：新开 `AbilityStatusChanges` 列 + 单一门面 `SetAbilityStatus`

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-status-vs-ownership-encoding.md · answer-logs/log-status-vs-ownership-encoding.md

## 背景

四类持有条目（`characterPower` / `magicPack` / `playerPower` / `playerItem`）的 record 上各有一格 `bool Status`（启用 / 禁用），它与「拥有 / 失去」是**两个正交维度**。编码本身早已成文，但这一格**没有任何写入通道**——`AbilityChangeOp` 的三个语义面（`Grant` / `Remove` / `Disable`）没有一个能表达「把已持有条目的 `Status` 置为 X」。这是全库解锁面最宽的那条裁决被长期挂着的真实原因：不是编码未定，是通道缺失。

## 决策

**一、`ProfileChangeSpec` 新开独立列 `AbilityStatusChanges`**，元素 `AbilityStatusAssignment(Kind, Scope, AbilityId, Enabled)`。语义六面：键是 `(Kind, Scope, AbilityId)` 三元组 → 载荷是单个 `bool`；**不钳制 · 无量纲 · 幂等绝对置值 · 恒不走 modifier pipeline · 无 `Source`**。四类 record 上的 `Status` 不提供 setter，**唯一写入路径是本列经 `TryApply`**，与其余各列同批、同事务提交。

**二、必须分列，不是给 `AbilityElements` 加第四个 `Op`；`StatusChanges` 也不承载本维。**

**三、门面收敛为单一方法** `ApplyResult SetAbilityStatus(AbilityCarrierKind kind, AbilityScope scope, string abilityId, bool enabled)`——用 `AbilityScope` 选层，`kind` / `scope` 不给默认值；未持有 → `ApplyResult.Fail`（业务失败，**绝不抛**），供 UI 灰显。

**四、四类持有条目一律对玩家开放这个开关**：储物袋里可以关掉一件不想自动触发 / 不想误点的法宝；关掉的法宝仍占储物袋位、`Charges` 不变。**生效 = 三条与门**：拥有 ∧ `Status == true` ∧ 不在 `disabledAbility` 内。

载荷定义、四条施加失败语义与逐面语义 → `systems/services/profile-service.md`、`systems/architecture.md`。

## 理由

- **分列而非加 `Op`**：`AbilityElements` 明文定位「改变**持有**」且 `Source` 强制携带（`Unknown` 即整批拒绝），而开关不改变持有、没有来源可言，`Duration` / `PairKey` 对它恒空——塞进去即让载荷有一半字段对某个 `Op` 恒空，正是 `ChangeElement` 拒绝加可空字段时否决过的形状。
- **同族先例是 `SettingChanges`**：同样是玩家自己拨的开关、按固定键绝对置值、恒不走 pipeline。本列逐面与它同构。
- **恒不走 modifier pipeline**：一条法则若能改写玩家自己拨的开关，等于内容替玩家做主。
- **`Status` 取 `bool` 而非枚举**：它是二值开关；第三维（轮回级的外部抑制）另有承载面 `CharacterProfile.disabledAbility`。
- **未持有返回 `Fail` 而非抛异常**：这是业务失败，UI 需要它来决定灰显。

## 备选方案

- **给 `AbilityElements` 加第四个 `Op`** — 否决：见上，制造「载荷一半字段对某个 `Op` 恒空」的形状。
- **复用 `StatusChanges` 列** — 否决：那一列绑定 `CharacterProfile.Status` 上的**数值型规则字段**（`CurrentLocationId` · `LocationEventCount` · 两个 band），与本列名字撞车、语义无交集。**不写下这条反向澄清，「`Status` 的变更走 `StatusChanges`」是一个几乎必然会被写出来的误推。**
- **只对 power 两类开放开关、item 两类恒 `true`**，或**从 item record 上删掉 `Status`** — 否决（用户裁决）：取四类一律开放、门面一个方法覆盖。

## 后果

- **编码本体零改动、零迁移、不 bump schema**——老档缺格补 `true`；本条补的是通道，不是编码。
- **`profile-service.md` 此前那处自相矛盾就此消失**：`status` × 拥有 / 失去的编码不再登记为未定，四份下游文档的悬空回链一并清理。
- **门面替换 power 侧的旧签名**，不并存两套。
- 受约束的文档：`systems/services/profile-service.md`（列定义 + 门面 + 四条失败语义）· `systems/architecture.md`（载荷定义）· `systems/services/profile-schema-versions.md` · `systems/player-profile/_index.md` · `systems/player-profile/player-power/common-properties.md` · `systems/character-profile/item/common-properties.md` · `systems/character-profile/power/common-properties.md`。

# Answer log character-power-mechanics

- 日期：2026-09-03
- 来源：`inbox/solution-draft-character-power-mechanics.md` → `handoffs/2026-09-03-character-power-mechanics.md`
- 移出条数：**1**（`open-questions/07-codex-monetization.md` 第 1 条）

---

**`CharacterPower`（神通）的机制细节（概念已定，待专场）——与法则的复用边界 · 事件侧的获取 / 失去触发 · 篇章突破是否随「全部继承」带入 · 与卡牌 / 法宝的边界 · 数量与强度尺度** → 五个子项全部答定，整条移出：

1. **与法则的复用边界** → 分界只在生命周期层：持有列表不共用（账号级 `PlayerProfile.playerPower` / 轮回级 `CharacterProfile.characterPower`），清理规则不需要任何代码（随 `CharacterProfile` 整体拆解、flag / modifier 随重新聚合自然消失）。无剩余待决面。（`systems/character-profile/power/_index.md`）
2. **事件侧的获取 / 失去触发** → 机制面已由四个合法 `Source` 与 `AbilityChangeSlot` 的三种失去形态闭合，零结构增量；剩余为内容口径，首批值已给（开 `InitialGrant` / `CombatReward`（`Standard` · `Finale` 两档）/ `ExchangePurchase`；`EventOutcome` 保留机制零条目；Research 暂不放；Travel / Explore 恒不产出；失去恰三种形态、无第四种；失去事件计入与法则共用的同一份频次预算）。（`systems/character-profile/power/_index.md`）
3. **篇章突破是否带入** → **带入**，是「全部继承 · 无逐项筛选」的直接推论，不为它单列规则；连带推论：`Duration == ThisChapter` 的禁用在篇章边界剔除 ⇒ ch1 被禁用的神通进 ch2 自动恢复。起手授予落点补写在 `StartCycle`（`AbilityElements` 的 `Grant`，`SourceCode = Source.InitialGrant`）。（`systems/services/life-cycle-service.md`、`systems/character-profile/power/_index.md`）
4. **与卡牌 / CharacterItem 的边界** → 三行判据表（按「这个效果要付什么代价才能生效」排序）+ 四条推论，归 `power/_index.md`；`deck/_index.md` 与 `item/_index.md` 各留一行回链、不复述。（`systems/character-profile/power/_index.md`、`deck/_index.md`、`item/_index.md`）
5. **数量与强度尺度** → 定性三条已答（单条显著强于法则 · 「不得随对局延长而累积」照搬且更硬 · 不设持有数量硬上限）；战斗内强度上沿的**形状**已立（单条道念净贡献 / 本方 `baseMomentum` ≤ X%，X 显著高于法则的 10%；**不设合计总闸**），**取值属【待内容】**，与「一次轮回获得几条」「各 `RarityTier` 档条目数」一并留给 ch1 平衡打磨。（`systems/balance.md`、`systems/character-profile/power/_index.md`）

**本条另有两项裁决同批答定：** 绑定神通**不填 `ExclusiveSource`**（照常进抽取 / 置换换入池；代价 = 辨识度在内容侧被稀释，已写入内容编排口径）· 加载期校验取「在册 `CharacterData` 的 `PowerId` 唯一性 → `PushError` + 抛」而非草稿的总量前置检查（后者与既有的 `ContentEnabled` 退池处置相抵且恒真）。

**⚠ 不含**「`status`（启用 / 禁用）与『拥有 / 失去』两个正交维度如何编码进 schema」——它是 `power/_index.md` 与 `systems/services/profile-service.md` 的并列待决项，本次明确不覆盖，**仍留在待答清单**。

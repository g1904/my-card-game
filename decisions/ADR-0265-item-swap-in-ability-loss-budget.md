# ADR-0265 — 法宝置换与法宝 / 古宝禁用一并计入「失去能力」上层 ≈ 1.0 的分子；份额归 item 侧裁定

- **状态：** Accepted
- **日期：** 2026-09-10
- **来源：** handoffs/2026-09-10-item-family-supply-guardrails.md · handoffs/2026-09-10-player-power-acquisition-and-balance.md · answer-logs/log-item-family-supply-guardrails.md · answer-logs/log-player-power-acquisition-and-balance.md

## 背景

法宝置换给出目标频次（≈ 2 次 / 完整轮回）时，随之而来的问题是它记在哪本账上：并入「失去能力」上层 ≈ 1.0 的合计，还是像 `IgnoresProtection` 那样**自持**一本战斗侧分母、不进上层合计。原始草稿取的是自持口径。

## 决策

**法宝（`CharacterItem`）置换与法宝 / 古宝禁用一并计入上层 ≈ 1.0 的分子**，不适用自持口径。

**具体份额归 `systems/character-profile/item/` 侧裁定并回链四支频次表**（权威表在 `systems/player-profile/player-power/_index.md`）。

**「失去能力有四条支路」的枚举不扩为五支，`decisions/ADR-0161-ability-loss-budget-absolute-frequency.md` 不改写**——「≈ 1.0 不被高频次撑爆」由**份额**这个旋钮兑现，不动口径结构。

→ `systems/player-profile/player-power/_index.md`「法宝一族的失去事件」· `systems/character-profile/item/_index.md`。

## 理由

`systems/player-profile/player-power/_index.md`：**自持口径的第一条判据是「它不写 Profile」**——`IgnoresProtection` 之所以能自持战斗分母正因如此；而法宝置换**写 `CharacterProfile`**，判据当场失败。同层的神通置换（同为轮回级 build 损失、同写 Profile）在上层合计内已占 ≈ 0.5；古宝禁用事件另已明写一并计入该分子。法宝一族排在合计之外需要一条**不存在的新判据**。

法宝本就是上层口径所保护的「构筑投入」本身（与 deck、神通并列），故它触碰的恰是上层口径保护的那条心理契约。

## 备选方案

- **自持口径、不进上层合计** — 否决：自持判据首条（不写 Profile）不成立。
- **把四支枚举扩为五支** — 否决：口径结构不必动，份额旋钮已足够兑现「≈ 1.0 不被撑爆」。

## 后果

- 约束 `character-profile/item/` 侧必须给出一个份额，且该份额要回链 `player-profile/player-power/_index.md` 的四支频次表；「份额归 item 侧裁定」本身仍是一条待答项。
- 法宝置换应比法则两支更常见——法宝在「持久度 × 是否经玩家同意」两轴上都是最轻的一端（轮回级 + 有同意，储物袋不设容量上限、随售是常态弃置途径）。
- 配套的一条编排后果：**法宝逐档启用条目数 ≥ 2**（置换池排除已持有 ⇒ 某档仅 1 条会让玩家持有它后该档置换池恒空），首批条目数矩阵的法宝行 Tier5 由 1 提到 2。该格数的是**非回寿**法宝，与「Tier1 / Tier5 留空不编排」不冲突。

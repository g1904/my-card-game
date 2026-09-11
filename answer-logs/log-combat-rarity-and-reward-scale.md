# Answer log combat-rarity-and-reward-scale

- 日期：2026-09-09
- 来源：`inbox/solution-draft-combat-rarity-and-reward-scale.md` → `handoffs/2026-09-09d-combat-rarity-and-reward-scale.md`
- 移出条数：**3**（其中 1 条为部分移出，条目改写保留）

---

**`RarityTier` 的分布与权重表 —— 战后奖励池各档权重、事件产出侧选表、内容侧「每档应有多少条目」的编排口径**（`open-questions/01-combat.md` 第 1 条，部分移出）
→ **部分答定。**
① 战后奖励池权重表 ✔ —— 由**三个递减比 `r`（0.42 / 0.52 / 0.70）× 三个篇章乘数 `m(c)`（1.00 / 1.15 / 1.30）** 生成的九行表，`r_eff = r(Tier) × m(c)`，权重 ∝ `1, r_eff, r_eff², r_eff³, r_eff⁴` 归一到 100。加载期三条校验：任一档权重 ≤ 0 → `PushError`；随机占优逐篇章各验一次；`r_eff < 1` → `PushError`。
② 事件产出侧与商店库存的选表 ✔ —— 固定取「优胜 `Solid` 那一张 × 本篇章 `m(c)`」。
③ 内容编排口径与首批矩阵 ✔ —— 挂池占比 ≈30% · 领取率 0.75 · 族占比 82/8.5/7/2 · `m = 1.5` · 神通同档 ≥ 2 · 首批全库 48 条矩阵；核对落 `/audit-content` 两项汇总，只报告不阻断。
④ 池的数据载体 ✔ —— 具名成员清单（`.tres` 逐条编排），一个条目可属多个池；每个池五档全非空，**表管分布、池管族成分与具体条目**。
**仍留待答**（条目改写保留，不整条删除）：三格取池余量（`GrantPoolMargin` / `ResearchPoolMargin` / `ExchangePoolMargin`）与 `K` 的取值 · 功法维分母按灵根收缩后的重估 · `ADR-0073` 三段处置边界的复核。
（归档去向：`systems/balance.md`「战后奖励池稀有度权重表」与「战后奖励的内容编排口径」· `systems/services/combat-service.md`「可选奖励的候选生成」· `systems/adventure-event/common-properties.md`「`DeckOperation` 走池抽的取池链」· `systems/adventure-event/exchange/common-properties.md`「商品族与取池链」· `content/_index.md`「跨类型对账项」）

**逐项领取后的奖励厚度重估 —— `Tier` 三档的质量落差与 `BaseReward` 的相对分量是否随之重估**（`open-questions/01-combat.md` 第 2 条，整条移出）
→ **全部答定。** 吞吐量的节流压在**挂池占比**上：`EncounterSpec.RewardPoolId` 明确为可空（空 = 本场不开可选奖励面板 / `activeCombat.reward` 为 `null` / 决策点 `D6` 不出现），初值 ≈30% 的 Combat 条目挂池、`Finale` 恒挂 ⇒ ≈10 次面板 / ≈30 候选槽 / 轮回。**`Tier` 三档的质量落差与 `BaseReward` 的三档相对分量均不重估**——逐项领取抬的是数量、三档管的是质量，两者正交。已接受的代价：约七成的普通战斗打完只有 `BaseReward`。`ADR-0082` 一字不改。
（归档去向：`systems/services/combat-service.md`「可选奖励的候选生成」· `systems/adventure-event/combat/_index.md`「结算产物」· `systems/balance.md`「战后奖励的内容编排口径」）

**量纲基准落笔牵出的三条复核项**（`open-questions/01-combat.md` 第 3 条，整条移出）
→ **三条全部答定。**
① `itemPowerRatio` 的「不占手牌位」**上调至 ×1.15**（取建议区间下沿——手牌上限 7 紧但不是每场都咬）⇒ 合计 ≈ ×1.85、等价折价 ≈ 0.54，四档折价整体下移 0.03 为 **0.52 / 0.62 / 0.72 / 0.87**；另两项溢价不动。
② 战斗内法则 / 神通的强度闸**维持单闸**（以 `baseMomentum` 计），不加以摆幅计的第二把闸；折成摆幅的换算栏保留供内容评审对照。
③ `advantage` 三档边界**三章恒 `0.25 / 0.75`**（不分格），ch1 品质偏厚作为有意的早期正反馈，接受「ch3 碾压档接近不可达」；连带按 `ADR-0163` 的字面口径改写「按篇章调三档边界须先立 ADR」这句过严表述（篇章是被明确允许的第二条分格轴，须先立 ADR 的是第三条轴）——**不新建 ADR、不改写 `ADR-0163`**。
（归档去向：`systems/balance.md` 的 `:580` / `:582` / `:585` 三条回代台账行 + `itemPowerRatio` 分层表 + 「战后奖励池稀有度权重表」条）

---

> **另有一条主题文档级待决项同批收口**（不计入上方移出条数——它不在 `open-questions/` 分片里）：`systems/balance.md` 「待决问题」的 `itemPowerRatio` 上调条整条删除，结论已并入分层表本体。
>
> **本次新增一条待答项**（`open-questions/01-combat.md`）：九行权重表与 `m(c)` 的实测校准——`advantage` 三档的实际分布尚无样本，Tier5 的 ≈2.1 次 / 轮回是按三档等占比估出的初值。

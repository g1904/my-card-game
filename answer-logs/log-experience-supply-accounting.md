# Answer log experience-supply-accounting

- 日期：2026-09-10
- 来源：`inbox/solution-draft-experience-supply-accounting.md`（handoff：`handoffs/2026-09-10-experience-supply-accounting.md`）
- 移出条数：1

---

**胜侧 `rewardPerMomentum[experiencePoint]` 是否计入经验供给账 `G_c`** → **计入。** 三条独立依据：灵石侧 `I(c)` 对同一条式子已计入而经验侧不计、且无任何文档给过这个差别的理由；失败代价 ⑤「胜侧加厚归零」已定案，若经验不吃加成则 ⑤ 在经验一列上是空的；单价表有 `experiencePoint` 一列且逐章有取值，不计入等于让一列已定案的数据在账上不存在。（归档去向：`systems/balance.md`「胜侧单价表」与「`experiencePoint` 供需对账」· `systems/game-progression.md` · `systems/adventure-event/combat/_index.md`）

同批答定的四项从属结论（随上条一并收口，不另计条数）：

- **「供给 / 需求 ≈ 1.15–1.20」这条带管辖哪一个量** → 只管辖**扣 N 次典型失败后的比** `(G_c − N × X_c) / D_c`（A3 口径）；全胜比降级为**导出量**，带不管辖它。此前该带被同时施加在相差 6–8% 的两个量上，算术上不可能同时落带 —— A3 三章不达标的根因是这处口径撞车。已接受的代价：全胜路线经验冗余上移到 25–30%。（`systems/balance.md` · `systems/game-progression.md`）
- **`experiencePoint` 的胜侧单价取什么** → 计入 + 单价下调，存储形态由分数记法改为**整数 `K = 5 / 6 / 9`**，量 = `floor(道念差 / K)`（`floor` 语义明写；`K` 正整数、逐章不下降；`K == 0` ⇒ 加载期 `PushError`）。`K` 整除 `E[道念差]` 使两种估计口径重合。`p_c` = 1 / 2 / 2 · `G_c` = 103 / 314 / 488 · `X_c` = 4 / 11 / 14 · A3 = 1.203 / 1.181 / 1.176（三章落带，ch1 落在「1.20 + ε」的 ε 上）。（`systems/balance.md`）
- **A3 的偏紧如何收口** → 由补记一个从未入账的产出项收口，属**调构成**；阈值曲线一格不动、不加旋钮。`N = 2、三章统一` 的定案不受影响，三章一律由寿元侧封顶（5.30 / 4.97 / 2.69），经验侧上界 6.00 / 6.09 / 6.93 全程宽松。ch3 仍是最薄的一章（2.69），是已登记的实测复核点。（`decisions/ADR-0176-accept-tight-tolerance-no-knobs.md` · `systems/balance.md`）
- **运行期总量的可校验形式** → 新增表侧断言 **A4** `Major 映射值 + E[道念差]_c × 单价_c < 2 × 该境界最小阈值`（7 < 12 · 20 < 138 · 26 < 216，实际只咬 ch1）；不进 `.tres`、不进加载期校验。（`systems/balance.md`）

**仍留在待答清单的部分：** `E[道念差]` 三格与败率 20% 仍是 ⚠ 待实测标定格；`E[floor(d/K)] ≤ E[d]/K` 的估计偏差须按实测分布复算（`K` 可能移动一档）；ch2 / ch3 逐类型构成表补齐后两列须整列重算；`E[道念差]` ch3 偏高一条与本条的先后已明确（本条先落，`E_3` 改写时同式重算）。

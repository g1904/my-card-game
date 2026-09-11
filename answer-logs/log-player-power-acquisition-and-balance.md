# Answer log player-power-acquisition-and-balance

- 日期：2026-09-10
- 来源：`inbox/solution-draft-player-power-acquisition-and-balance.md`（提炼至 `handoffs/2026-09-10-player-power-acquisition-and-balance.md`）
- 移出条数：1

---

**PlayerPower（法则）的获取 / 失去具体触发与平衡边界（是否影响 cycle seed / 计分公平、防 pay-grind-to-win）—— 同一条未决在五份文档上的五个投影，需一次合成收口** → **收口。** 五个组成部分逐一落定，收敛为「单一权威 `systems/player-profile/player-power/_index.md` + 四处回链」：

1. **获取触发** → 通道已闭合：`(Power, Player)` 域恰三个合法 `Source`（`FinaleWin` / `PremiumBundle` / `AchievementReward`），逐条已有组装者与施加链路，零新机制 / 零新字段 / 零新存档点。归档去向：`systems/player-profile/player-power/_index.md`（三渠道表）。
2. **第三条获取渠道（事件 outcome 直接给予）是否开放** → **不开**（用户裁决）。`(Power, Player)` 域的 `EventOutcome` / `ExchangePurchase` 两格由「※ 暂不开放」改判为**规则层封死**。归档去向：`systems/common-properties.md`（分域校验表 + 改写后的封死理由，※ 脚注整段删除）、`player-power/_index.md`。附带修正：`EventOutcome × (Item, Player)`（古宝域）那格的 ※ 是陈旧副本（该格早被「事件产出不能给账号级古宝（承重）」封死），一并改判。
3. **失去触发** → 已闭合（三形态 + 四支频次预算）；「具体落在哪些 AdventureEvent 上」按定义是内容编排的产物，不是设计层的待决。归档去向：`player-power/_index.md`（三形态表 · 四支频次表）。
4. **是否影响 cycle seed / 计分公平** → **cycle seed 侧两者不相交（结构性，双向都不成立）**；计分公平侧刻度已有（单条 ≤ 10% `baseMomentum` · 老账号全开合计 ≤ 25%），但它落纪律阶梯**第 4 级（零保证）**、不得被引为承重依据、不为它补代理指标。归档去向：`player-power/_index.md`。
5. **防 pay-grind-to-win 的边界** → 已有**七道护栏**，本次整理成表、**不新增任何机制**；两条已被接受的代价（礼包是净强度增益 · 账号级法则总量无硬上限）如实并列；并补一个**可算的分母**（账号级法则获取速率的派生量，落 `systems/balance.md`，推导来源、不进 `.tres`、待实测校准）。归档去向：`player-power/_index.md` + `systems/balance.md`。

**同批答定的两项：**

- **法宝置换的频次口径** → 法宝置换与法宝 / 古宝禁用**一并计入上层 ≈1.0 的分子**，具体份额归 `character-profile/item/` 侧裁定并回链四支频次表。`ADR-0161` 的四支枚举不扩为五支、该 ADR 不改写。归档去向：`player-power/_index.md`（四支频次表旁）。
- **法则列表屏的开关控件落在哪一层** → 给**候选项列表语言**的构件加**第七位「行尾操作控件」（仅纵向侧）**，并同批写明外溢判据（仅当该行的操作是幂等的账号级开关时开放；其余七个决策面不开放）。「触控目标 = 整个条目」改写为「纵向侧允许行尾一个独立操作热区，其余区域仍为整行」。归档去向：`ux/screen-flow.md`（构件表 · 触控目标纪律）、`player-power/_index.md`（呈现面回链）。

**分场（不合入本条）：** 三格取池余量（`GrantPoolMargin` / `ResearchPoolMargin` / `ExchangePoolMargin`）与 `K` 的取值**原样留在待答清单**——它们是数值取值题（结构已定、可先填 0 而不阻塞落地），解锁条件与本条不同。

**仍留的远期未知（未答定，已登记）：** 成就组数（⇒ `AchievementReward` 渠道的法则供给量），归内容阶段；派生表待实测校准。

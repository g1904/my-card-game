# ADR-0267 — 法则获取通道恰三条；`EventOutcome` / `ExchangePurchase` 三格改判为规则层封死

- **状态：** Accepted
- **日期：** 2026-09-10
- **来源：** handoffs/2026-09-10-player-power-acquisition-and-balance.md · answer-logs/log-player-power-acquisition-and-balance.md

## 背景

`(Power, Player)` 域的分域校验表上，`EventOutcome` 与 `ExchangePurchase` 两格此前标着「※ 暂不开放」——一个悬而未决的状态，意味着「是否开放第三条获取渠道（事件 outcome 直接给予法则）」这条取向一直开着，而它是 PlayerPower 那条长期未决问题的最后一项。

## 决策

**不开第三条获取渠道。** `(Power, Player)` 域的合法 `Source` **恰三个**：① 道统残卷（`FinaleWin`）· ② premium bundle（`PremiumBundle`）· ③ 成就 90% 档一次性奖励（`AchievementReward`），逐条已有组装者与施加链路，**不需要任何新机制、新字段、新 element、新存档格、新存档点、新枚举**。

**`EventOutcome` / `ExchangePurchase` 由「暂不开放」改判为规则层封死**，`※` 脚注整段删除。分域校验表上受此改判的是**三格**：`EventOutcome × (Power, Player)` · `EventOutcome × (Item, Player)` · `ExchangePurchase × (Power, Player)`——第三格早已被「事件产出不能给账号级古宝」与「`GrantFromPool` 的 `PoolKind` 拒绝 `PlayerItem`」封死，那格 `※` 是陈旧副本，改判属修正。

**`x` 只被渠道 ① 推动**；② ③ 不计入。

→ `systems/player-profile/player-power/_index.md`（唯一权威）· `systems/common-properties.md` 分域校验表 · `systems/services/future-event-service.md`。

## 理由

`systems/player-profile/player-power/_index.md`：轮回内事件产出会**改变账号级经济、绕开「打 / 买 / 成就」三条既定渠道**，且会开出一条**后端无输入可复算的账号级永久授予**——既定防作弊边界是「可复算 `roll`、不复算阈值」，三条现有渠道逐条成立而第四条不成立。它同时会用一条**不受 `x` 调控、随游玩时长线性增长**的平行供给，旁路掉残卷那条受调控的递减曲线。

「在冒险中拿到东西」的体验位已由轮回级的神通 / 法宝 / 卡牌 / 功法四族完整承载；账号级这一层的定位本就是「跨轮回我强了多少」。

## 备选方案

- **开放事件 outcome 直接给予法则** — 否决：三条独立依据如上（改变账号级经济 · 后端不可复算 · 旁路残卷递减曲线）。
- **维持「暂不开放」的悬置状态** — 否决：悬置让内容侧无法判断该不该为它预留编排位，且每次复核都要重开一次会。

## 后果

- **后端零义务**：不 bump `schemaVersion`、不新增会被后端读到的取值、不移动任何透明路径 ⇒ **不落对侧 counterpart**，不写 `backend-design-documents/`。
- 三者互不撞车是机械保证：① ② 共用同一段抽取与同一张 `GrantPoolWeights`；③ 走 `ExclusiveSource == Source.AchievementReward` 的专属条目、按定义不进任何抽取池 ⇒ **成就奖励恒不落空**。
- **失去侧同样闭合**：「具体落在哪些 `AdventureEvent` 上」按定义不是设计层的答案，它是内容编排的产物，答案形态是「每支 1–2 条 `Rare` 档条目」。
- PlayerPower 那条长期未决问题由此收敛为**单一权威 + 四处回链**（`player-profile/_index.md` · `profile-service.md` · `life-cycle-service.md` · `ux/screen-flow.md`）。

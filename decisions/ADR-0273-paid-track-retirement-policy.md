# ADR-0273 — `Track == Paid` 的退役口径：flags 临时关闭允许，基线永久退役禁止（加载期 `PushError`）

- **状态：** Accepted
- **日期：** 2026-09-12
- **来源：** handoffs/2026-09-12-premium-character-series-unlock.md · answer-logs/log-premium-character-series-unlock.md

## 背景

内容退役此前只有一套通用路径：flags 秒关（临时、可恢复）与基线置 `ContentEnabled = false`（永久退役）。付费角色打破了这套通用性 —— 一个玩家花钱买下的角色，如果能被运营永久关掉，那笔购买就被游戏本身销毁了。而运营的应急关停能力又不能因为付费而丧失。

## 决策

**按「临时 / 永久」两分，不按轨道整体开关：**

- **flags 秒关（临时、可恢复）对两条轨道都允许。** 运营应急不为轨道让路 —— 它是运营事故的处置手段，不是玩法分支。
- **基线里置 `ContentEnabled = false`（永久退役）对 `Track == Paid` 禁止**，落**加载期 `PushError`**（即校验 #18）。付费角色只能靠 flags 临时关闭，或改内容修。

`systems/services/content-service.md` 的**退役路径表已按轨道收窄**，与校验 #18 是同一条规则的两处兑现（**本 ADR 不复述表格**）。

## 理由

`systems/monetization.md`：**「付费内容不会被游戏销毁」** 是既有承诺，本条只是把它从外观族平移到角色轨道。

与 `decisions/ADR-0182-baseline-id-superset-invariant.md`「随包基线 `Id` 集合单调不减，退役 = 禁用或掏空」自洽：那条管的是 `Id` 不消失，本条进一步管住付费轨道上连"禁用"这一档也不许用。

临时与永久必须分开处置，否则只能二选一地失去一样：要么运营在事故时束手无策，要么玩家的购买可被单方面作废。两分之后两者都保住。

## 备选方案

- **付费轨道连 flags 秒关也禁止** — 否决：一个问题付费角色若能崩掉战斗，运营连止血手段都没有。
- **付费轨道与免费轨道同等对待（永久退役也允许）** — 否决：与「付费内容不会被游戏销毁」正面冲突。
- **永久退役时给补偿** — 否决：补偿要求一条账号级可支配货币，该形态已被明确关死。

## 后果

- **被接受的代价：** 运营失去「永久下架一个问题付费角色」这一手，只能靠改内容修。
- `systems/services/content-service.md` 的退役表与 `systems/character-profile/_index.md` 的校验 #18 **必须同批维护**，两处并存即互相矛盾。
- 与轨道棘轮双向（`decisions/ADR-0255-paid-character-series-track.md`）合起来，`Track == Paid` 的条目在发布后既不能改轨道、也不能被永久移除。

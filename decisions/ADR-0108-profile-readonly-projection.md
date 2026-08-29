# ADR-0108 — 收口前的重算走只读投影 `Project(spec)`：先算后提交，不新增第二个写入面

- **状态：** Accepted
- **日期：** 2026-08-19
- **来源：** handoffs/2026-08-19-profile-change-spec-gaps.md · handoffs/2026-08-17j-event-option-derived-persistence.md

## 背景

两条承重纪律在收口那一刻正面相撞：新一批 eventOptions 必须依**更新后的** profile 重算（`pastEvent` 是 future-event-service 的一等输入），而收口又必须是**一次**事务、一个存档点（`ADR-0020`）。先提交再重算会开出第二个存档点；先重算再提交则重算读到的是旧 profile。

## 决策

profile-service 提供 **`ProfileProjection Project(ProfileChangeSpec spec)`**：施加 spec 后返回一份**未提交**的只读视图，供收口前重算新一批；life-cycle-service 用它算出新一批，再把批一并放进同一次 `TryApply`。

语义面四条：与 `TryApply` / `CanAfford` **共用同一段 `Evaluate(spec)`**；**做钳制、不判终态**；判负照常重算照常提交，重算入口不多分支；**一次性视图**——不缓存、不存字段、不跨 `await` 持有。

**不提交、不广播、不落存档点。** 失败 = 收口 spec 组装缺陷 = 必需缺失 → `PushError` + `throw`。返回类型是包装 `PlayerProfile` 的 **`ref struct`**，使一次性纪律在语言层写不出违例。

收口的五步组装顺序与闭合性条件 → `systems/services/life-cycle-service.md`；API 面与校验档位 → `systems/services/profile-service.md`。

## 理由

**它不是第二个写入点，而是把「预览」与「提交」分清**——写入面仍然只有一个。两条纪律因此都不必松动。

共用 `Evaluate(spec)` 是承重的：分叉的代价是玩家拿到一批**依据一份从未存在过的历程**算出的选项，且事后无从发现。

一次性纪律取阶梯第 1 级而非第 3 级（`ADR-0013`）：跨 `await` 持有可能只在线上时序下发生，按「能上线且线上不可见 → 必须第 1 或第 2 级」的判据，第 3 级不够。`ref struct` 让 C# 在语言层禁止存字段与跨 `await` 持有。

## 备选方案

- **`bool TryProject(ProfileChangeSpec spec, out PlayerProfile projected)`** — 否决：那是可选缺失的签名形状，却配了必需缺失的严重度且不履行 `throw`，不落总则 2 的任何一档。取直返形态 + `PushError` + `throw`。
- **先提交再重算** — 否决：开出第二个存档点，与「收口是一次事务」直接冲突。
- **重算读旧 profile** — 否决：`pastEvent` 是产出侧的一等输入，读旧的等于让玩家看到与自己历程不符的一批选项。
- **把一次性纪律留在第 3 级（组装代码的静态形状）** — 否决：见理由。

## 后果

- `systems/services/profile-service.md` 是 API 与语义的权威；`systems/services/life-cycle-service.md` 承载收口的五步组装顺序与闭合性条件（`Project` 之后只允许追加「不构成重算依据」的列）。
- `systems/architecture.md` 的服务 API 面随之列入本方法。
- **`Project` 目前恒只有一个消费点**（收口重算）。一次性视图纪律在只有一个消费点时代价为零；若日后出现第二个消费点，须同批复核缓存问题。

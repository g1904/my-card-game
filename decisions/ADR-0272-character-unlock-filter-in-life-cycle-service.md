# ADR-0272 — 付费角色的解锁过滤落 `life-cycle-service.GetSelectableCharacters()`，绝不落 `ContentRegistry`

- **状态：** Accepted
- **日期：** 2026-09-12
- **来源：** handoffs/2026-09-12-premium-character-series-unlock.md · answer-logs/log-premium-character-series-unlock.md

## 背景

付费系列一旦存在，「哪些角色能被选」就不再只由内容层决定，而要读账号侧的解锁集合。这道过滤放在哪一层是一个会长期锁死依赖方向的选择：放进注册表最省事，但会让内容层反向依赖存档层。

## 决策

**解锁过滤落在 `life-cycle-service.GetSelectableCharacters()` 内，作用在 `AllEnabled()` 的返回值之上：**

```
可选角色 = AllEnabled<CharacterData>()
           ∩ 全部绑定条目 ContentEnabled == true
           ∩ ( Track == Free ∨ entitlement.CharacterSeries 含该条目的 SeriesId )
```

- **签名不变**，仍是 `IReadOnlyList<CharacterData> GetSelectableCharacters()`。
- **`StartCycle` 零改动** —— 既有守卫原样覆盖新增的这一层，不新增拦截点、不新增失败语义。
- **完全不涉及 RNG** —— 解锁是一次集合包含判定。
- **绝不写成 `AllEnabled(accountContext)` 一类**：注册表不吃账号上下文。

## 理由

`systems/services/life-cycle-service.md`：**让内容层反向依赖存档层这条形态已为 flags 分桶明确关死。** `ContentRegistry` 的契约是「按 `Id` 索引合并后的内容」，一旦它开始吃账号上下文，同一个 `Id` 在不同账号下返回不同结果，注册表就不再是一个可缓存、可校验、可在启动期全量验完的东西。

过滤不会把池清空：首批五角恒免费恒可用 —— 这也是 `decisions/ADR-0269-character-series-id-and-track-fields.md` 明确否决「解锁后池为空」那条校验的同一依据。

## 备选方案

- **过滤落 `ContentRegistry`（`AllEnabled(accountContext)`）** — 否决：内容层反向依赖存档层，注册表失去可全量校验的性质。
- **过滤落 `StartCycle` 的守卫里** — 否决：那是一道失败语义，而这里要的是一个可选清单；把两者混在一起会让选择屏无法预先知道该渲染什么。
- **过滤落呈现层（角色选择屏自己筛）** — 否决：服务 API 面返回不可选的条目，等于把一条准入规则交给每个调用方各实现一遍。

## 后果

- 角色选择屏直接渲染本方法的返回值 ⇒ 未拥有的付费角色**完全不出现**，与 `decisions/ADR-0277-paid-series-surface-enumeration.md` 的推销面穷举自洽。
- 解锁集合的来源是 `PlayerEntitlement.CharacterSeries` → `decisions/ADR-0270-player-entitlement-character-series.md`。
- 依赖方向自此单向锁定：`systems/services/content-service.md`（内容层）→ 不知道账号；`systems/services/life-cycle-service.md`（轮回层）→ 同时读两侧。

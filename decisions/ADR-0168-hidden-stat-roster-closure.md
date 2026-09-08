# ADR-0168 — 隐藏属性清单永久收口为道心 / 煞气两项，并立准入四问

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-third-hidden-stat.md · answer-logs/log-third-hidden-stat.md

## 背景

「隐藏属性完整清单是否还有第三项」在库里挂了很久，卡着 `plot-manager.md` 与 `character-profile/_index.md` 两份文档的收口。问题的形态不好：它是一个开放式的「还要不要再加」，没有任何输入能让它自然答结——只要不正面关掉，它就会一直在。

## 决策

**隐藏属性清单定稿为道心 `Faith` / 煞气 `Bloodlust` 两项，不加第三项。**

**不留占位枚举成员、不预留 band 字段**——取「关闭 + 留判据」而非「留一个扩展口」。

**新增一项隐藏属性须逐条通过准入四问，一条不成立即不加：** ① 在 scope 之内 · ② 不可替代（道心 / 煞气都表达不了）· ③ 必须连续且必须隐藏 · ④ 消费方是**调制**而非旁白。**举证责任在提案侧。**

**`HiddenStatGrant.Stat` 就取 `HiddenStat` 本身**，不另立 `PushableHiddenStat` 一类近同义子枚举——枚举成员即全部可推拉的属性，取值域无需再由校验收窄。

准入四问全文与两项的形态分工 → `systems/services/plot-manager.md`。

## 理由

- **两项已把两种形态占满**：道心是**双臂状态轴**（可正可负、有常态档），煞气是**单臂累积物**（只增不减）。第三项若不是这两种形态之一，它多半根本不是隐藏属性。
- **本作的求生张力只有寿元一条压力线**，隐藏属性的职责是给 eventOptions 调制提供维度，不是再开一条压力线。
- **预留占位的成本是立刻发生的**：占位成员会当场污染 `ResourceElements` 表、`StatusFields` 封闭表与「每 `Stat` 须有常态档」那行校验；而**加一项从来不需要今天预留**——枚举可增，档位是内容条目。加一项的边际成本已被逐点数到 14 处结构点。
- **唯一被正式提过的第三属性候选（好感 / 关系度）已被逐条驳回**，判词是「代价与收益完全不成比例」「好感度本质上就是一条 arc 的进度」。

## 备选方案

- **留一个扩展口（占位枚举成员 / 预留 band 字段）** — 否决：见上，成本立刻发生而收益在不确定的未来。
- **继续挂着待答、等内容阶段再说** — 否决：它等不来输入，只会持续卡住两份文档的收口。
- **另立 `PushableHiddenStat` 子枚举** — 否决：与 `HiddenStat` 近同义，制造同页两义；宽类型 + 加载期校验收窄的口径已随 `ADR-0127` 退役。

## 后果

- **`enum HiddenStat` 收为 `{ Faith, Bloodlust }` 两成员**，全库「三个属性」的措辞同批订正。
- **`character-profile/_index.md` 的「是否还有第三项」待决条整条删除**，该文档的两条剩余卡点均与本项无关。
- **准入四问是本条的正面产物**：它把一个开放式问题换成一道可判定的门——推翻本 ADR 与「通过四问加一项」是两回事，后者不需要推翻本 ADR。
- 受约束的文档：`systems/services/plot-manager.md` · `systems/architecture.md` · `systems/balance.md` · `systems/character-profile/_index.md` · `decisions/ADR-0016-hidden-stat-band-model.md` · `decisions/ADR-0129-hidden-stat-direction-slot.md`。

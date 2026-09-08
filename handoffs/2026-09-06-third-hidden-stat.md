# 隐藏属性清单收口：两项 + 准入四问

- id: 2026-09-06-third-hidden-stat
- date: 2026-09-06
- topic: systems/services/plot-manager.md · decisions/ADR-0016-hidden-stat-band-model.md · systems/architecture.md · systems/balance.md
- status: distilled
- distilled-to: systems/services/plot-manager.md, decisions/ADR-0016-hidden-stat-band-model.md, decisions/ADR-0129-hidden-stat-direction-slot.md, systems/architecture.md, systems/balance.md

## Intent（distilled）

隐藏属性的**一切结构**早已定案 —— 取值域 `[0,100]`、档位表（道心 5 档 / 煞气 4 档 = 9 档）、阈值、回滞 δ、跨档叙事形态、推拉的允许面、战斗层边界、方向格 `HiddenStatDirection`、内容类型 `HiddenStatBandData`、存档字段、加载期校验表。**唯独「一共几项」这个数没有被明写**，于是它以待答项挂着，并让同条目下的另两项（逐条目 `HiddenStatGrants` 映射、两条剧情线的具体内容）在名义上被「清单未定」阻塞。

**清单收口为道心 faith / 煞气 Bloodlust 两项，不加第三项。** 四条依据：

1. **它正面撞上一条愿景级约束（最强）。** `vision/pillars.md`「压力线是一条」——本作明确不要 Reigns 的多仪表，道心 / 煞气是**塑形**而非压力计；`vision/scope.md` 把「支撑 Reigns 式平衡张力的完整属性模型」列入范围之外，而 `systems/character-profile/_index.md` 明确该条指的就是「`faith` / `bloodlust` 一类运行时可推拉的资源条」。再加一条 = 正面走进 scope 的排除项。
2. **唯一被正式提出过的候选（好感 / 关系度）已被逐条驳回**，判词「代价与收益完全不成比例」，且「好感度本质上就是一条 arc 的进度」——`systems/adventure-event/exchange/_index.md` 的四条依据活在主题文档里。
3. **全库扫描找不到需要它来填的设计缺口**：五类事件的产出格与载体面无「后果无载体」残留；「声望 / 业力 / 气运 / 因果 / 宗门」的关键词命中全部落在无关处或那段既定否决里；角色差异化的第三维已由静态灵根承担。
4. **加一项的边际成本落在 14 处结构点**（`HiddenStat` / `CostKey` / `StatusKey` / `StatusFields` / `ResourceElements` / `Status` 子表 / band 专段 / `schemaVersion` 登记 / 档位表 / 内容台账 / 物化展开式 / key 表 / 结算面板优先序 / `balance.md` 反推口径）+ 逐条目编排 +50% + 超线性的标定难度。

**正面产物 = 准入四问**（落 `systems/services/plot-manager.md`「取值域与档位表」小节，`ADR-0016` ②b 后一句回链）：① 落在 scope 之内吗 · ② 不可替代（道心 / 煞气任一能否表达） · ③ 必须连续且必须隐藏（不连续 → `PlotArcData` + `PlotKeyPoint.State`；需要精确数值 → 明文资源） · ④ 消费方是调制而非旁白。**举证责任在提案侧。**

**「关闭 + 留判据」而非「留一个扩展口」。** 结构上加一项从来不需要今天预留什么（枚举可增、档位是内容条目、`Status` 字段可增），预留占位反而是被明确禁止的形态（占位成员会立刻污染 `ResourceElements` 表、`StatusFields` 封闭表与「每 `Stat` 须有常态档」那行校验）。时机上现在最便宜：`content/hidden-stat-band/` 尚未开张，「9 档」这个数还没写进任何条目台账。

### 顺带收口的三处口径失真

同一批落笔顺带修正三处与两项清单同源的失真：

- `systems/architecture.md` 的 `HiddenStat` 枚举收为 `{ Faith, Bloodlust }`；同段「对三个属性一律无歧义」改为「两个属性」。
- `systems/architecture.md` 与 `decisions/ADR-0129` 的「`Stat` 保持宽类型 + 加载期校验收窄」口径改写为「`Stat` 就取 `HiddenStat` 本身，不另立近同义子枚举」——枚举成员即全部可推拉的属性，与之配套的那条加载期校验已整条退役；「不另立近同义枚举」这条理由原样承重、保留。
- `systems/balance.md` 的跨档叙事目标密度改为 **≈ 2–4 条 / 轮回**（煞气 1–2 · 道心 1–2）、每 21–42 个事件一条、文案总量 4–6 条，与 `plot-manager.md`、`ux/screen-flow.md` 对齐。

## Clarifications

- **属性清单是否就此收口为两项、并关闭这条待答项？** → **是（选项 A）**：两项 + 关闭待答项 + 写入四问准入判据。（用户裁决，2026-09-06 批量评审）
- **手上是否已有具体的第三属性候选？** → **无**。§3 的「没有设计缺口」结论只覆盖已成文的设计；用户确认无未成文候选，按 A 落笔。
- **`ADR-0129` 的两句「宽类型 + 加载期校验收窄」是否本批一并订正？** → **是**：就地订正措辞，**结论一格不动、不新增 ADR 编号、不改 `decisions/_index.md`**。（用户裁决）
- **`systems/architecture.md`「三个属性」与 `systems/balance.md` 同行派生量「每 8–14 个事件一条」是否随改？** → **随改**（同源漏改 / 纯算术：84 ÷ 4 = 21、84 ÷ 2 = 42）。

## 零增量声明

不新增字段、不新增内容类型、不新增校验行、不 bump `schemaVersion`、无迁移、**后端零参与**（隐藏属性纯本地，PlotManager 永不跨进程边界）。`HiddenStatGrant` 三格、方向格、五类全开、战斗层边界、档位表、`future-event-service.md` 的二值三元式、`ux/screen-flow.md` 的「煞气 → 道心」优先序与「最坏情形两行」全部原样成立。

## Open questions

- **逐条目的 `HiddenStatGrants` 映射**（哪条内容推哪个属性、各推哪一档 `HiddenStatGrade`）与**两条剧情线（煞气反噬 / 心魔滋生）的具体内容** —— 仍待答，但它们不再被「清单未定」阻塞，转为纯内容编排工作量。
- `HiddenStatGrade` 的三个映射值（`Minor 2 / Standard 5 / Major 10` 是反推验收项）仍待内容扩充后的统计校准，其校验依赖上一条。

# Answer log hidden-stat-bands-and-crossing-narrative

- 日期：2026-08-12
- 来源：`inbox/solution-draft-hidden-stat-bands-and-crossing-narrative.md`（`status: decided`，两轮共六项已裁决）→ `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md`
- 移出条数：**2 条完整 + 2 条部分**

## 完整移出

**隐藏属性的档位划分与阈值（08-01 新增 · 承重）。** → **三属性共用一套档位模型，档位是内容条目 `HiddenStatBandData`。** 道心 `[0,100]` 起始 50 **5 档**（阈值 20/40/60/80，带符号档号 `-2..+2`，唯一的双臂属性）· 煞气 `[0,100]` 起始 0 **4 档**（阈值 25/50/75）· 寿元 **3 档**（既定 30% / 10%，分母 = 新字段 `ChapterLifeSpanBudget`）。**档号方向 = 离常态的距离**，触发规则统一为 `|newBand| > |oldBand|`；每档带**回滞 δ**（道心 / 煞气 4、寿元 3 个百分点）⇒ 档位不是当前值的纯函数 ⇒ 三个 band 字段落存档。一张表同时服务四个消费方（eventOptions 调制用全部档 · 剧情线触发用 3 档 · 叙事文案用 4 档 · 寿元红字用 1 档），**「达阈值触发剧情线」与「跨过隐藏档位」两套并行说法就此收敛为同一件事**。（归档去向：`systems/services/plot-manager.md`、`systems/character-profile/_index.md`、`systems/services/life-cycle-service.md`）

**跨档叙事文案的归属与呈现（08-01 新增）。** → **挂档位不挂事件**（挂事件是 `事件 × 属性 × 档 × 方向` 的组合爆炸，且泄露事件↔属性映射）· **走内容层**（`content-service.md` 早已点名它属「被存档引用 / 只改不增」类，本次只是取回）· **每档 2–3 条候选、等概率随机取一、随机源不带种子** · **只挂极值档**（全库 4 档：道心 `+2` / 煞气 3 / 寿元 1、2 ⇒ ≈ 6–10 条 / 轮回，文案总量 8–12 条）· **播在事件结算面板内一档一行**（不是独立弹层）· **多属性同跨则逐条陈列，固定优先序 寿元 → 煞气 → 道心** · **寿元 30% 与其他属性跨档同形态，10% 的红字倒数是常驻标注而非叙事**（跨进 Band 2 时两者叠加）。（归档去向：`systems/services/plot-manager.md`、`ux/screen-flow.md`）

## 部分移出（其余仍留在待答清单）

**`TryApply` 施加负值时各资源的钳制规则未定**（`life-cycle-service.md`）→ **隐藏属性那一半答定**：道心 / 煞气施加后**截断到 `[0, 100]`、不构成终态**（寿元归 0 与 `lifeTotal` 归 0 照旧构成终态）。**其余资源的逐项钳制规则仍待定**，条目留在 `open-questions/02-event-options.md` 的既有位置。

**隐藏属性清单（`04-hidden-attributes-plot.md`）** → 取值域、档位、阈值、剧情线目录（2 条 → 3 条：煞气反噬 / 心魔滋生 / 大限将至）答定；**「是否还有第四项属性」与「增减触发」仍待答**，条目已改写留在原分片。

## 本次新增待答

- **`HiddenStatGrade` 的三个映射值**（初值 2 / 5 / 10，归 ch1 数值标杆专场；校验依赖「增减触发」）→ `open-questions/04-hidden-attributes-plot.md`。
- **内容条目自己的多语言表达形态**（UI 文案 ↔ 内容文案的边界本次已澄清并落 `ux/_index.md`，但内容条目内的多语言尚无定案）→ 记为 `open-questions/05-service-contracts.md`「翻译键的铺开节奏」的邻域备注。

## interview 追加裁定（草稿未覆盖）

- **档位条目与放量开关的关系** → **档位恒启用（`ContentEnabled == false` → `PushError`）、文案可秒关。** 判据：`AllEnabled()` 只约束**抽取**，档位判定是**查表读取**；关一档 = 档位表空洞 + 假跨档。立为 content-service 的一条通则「**能被抽取的才配有开关**」。
- **道心下臂极值 `-2` 是否挂 `PlotTriggerId`** → **挂，剧情线目录扩为三条。** 它是「下臂不播文案」那条取舍能成立的前提：若既无文案又无剧情线，玩家对「掉道心」这条因果链完全无感。

# Answer log life-lifespan-merge

- 日期：2026-08-30
- 来源：`inbox/solution-draft-life-lifespan-merge.md`（`/provide-solution-draft` 产物，用户已评审 · `status: decided`）
- 移出条数：**2**（均为复合条目中被答结的那一半）

## 逐条移出

**「`lifeTotal` 是否常驻战斗屏」（`open-questions/01-combat.md`「道念对比的视觉形态、回合进度与道念差的组合呈现、lifeTotal 是否常驻战斗屏」的第三半；第二书写位 `open-questions/deferred-content.md` 同条）** → **不常驻。** 合并后的寿元不进战斗屏；战斗屏只呈现道念对比与差值，余量在进入战斗前的确认页已知，**结算面板如实展示本次扣减量与扣后余量**。理由：战斗内本就没有任何手段改变这个值，常驻显示只增噪音并诱导「留血打」的错误心智。
> **剩余部分仍留在待答清单**：同条目的另两半（道念对比的视觉形态 · 回合进度与道念差的组合呈现）**不被答结**；且「道念差是否显式呈现」的原推荐论据（1:1 当场可算）在 `lossPerMomentum` 于 ch2 / ch3 引入系数后被削弱，须重估。
> 归档去向：`ux/combat-ux.md`、`systems/character-profile/life-span.md`。

**「每条剧情线的具体内容」中『大限将至』这一条的载体（`open-questions/04-hidden-attributes-plot.md`「隐藏属性清单与推拉触发」条内「目录已由两条扩为三条」那一半）** → **该剧情线整条退役，不另找载体。** 寿元余量已明文常驻、恒精确展示，预警型提示文案失去存在理由；剧情线目录收回为**两条**（煞气反噬 / 心魔滋生）。**终态死亡屏的 `DefeatReason` 呈现照旧保留**（它是结果呈现，不是提示文案）。「跨档叙事频次是否过稀」**不记为待答项**。
> **剩余部分仍留在待答清单**：同条目的「是否还有第四项隐藏属性」（基数由三改二）与「逐条目的映射 / 各推哪一档 `HiddenStatGrade`」不受影响，继续待答。
> 归档去向：`systems/services/plot-manager.md`、`decisions/ADR-0016-hidden-stat-band-model.md`。

## 被本次方案取代的旧结论（旧 log 不改，仅在此记明取代关系）

旧 answer log 是只读的历史记录，本次**一份都不编辑**。下列四份中的部分结论已被本次合并取代，权威一律以主题文档与 ADR 的当前内容为准：

- **`log-hidden-stat-bands-and-crossing-narrative.md`** —— 「一套档位表统一四个消费方：道心 5 档 / 煞气 4 档 / **寿元 3 档** + 回滞 δ」。现：隐藏属性收敛为道心 / 煞气两项，共 9 档；寿元退出该体系、无 Band、无档位文案。
- **`log-lifespan-gain-paths.md`** —— 「三条通道…**数字与 `selectCost` 同 Band 2 门控**」。现：三条通道原样保留，但**门控整体退役**，回寿数字与 `selectCost` 一律恒精确展示。
- **`log-combat-defeat-consequences.md`** —— 「失败已有六条代价，其中扣 `lifeTotal` 与已付 `lifeSpanCost` 打水漂是**两条独立终结路径**上的两笔账」。现：条目仍是六条，但两笔落在同一个值上，终结路径收敛为一条连续曲线；`FailureRatio` 保持 50%，依据改写。
- **`log-cost-side-closure.md`** —— 涉及 `CostKey` 全表 16 值、`ResourceElements` 含 `LifeTotal` 行、`DefeatReason` 四值的计数结论。现：`CostKey` 15 值、`ResourceElements` 删 `LifeTotal` 行、`DefeatReason` 三值。

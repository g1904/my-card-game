# ADR-0165 — 轮回出口的三层处置：`completed` 保留实体状态，单记录 + `chapterStartSnapshot`

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-completed-data-retention.md · answer-logs/log-completed-data-retention.md

## 背景

一个轮回有两条出口（`completed` / `defeated`），而「清理」这个词在库里一直是含混的：它可能指拆掉运行时节点、可能指清空运行态字段、也可能指销毁角色的实体状态。三者混作一谈时，`TeardownCycle()` 该做什么无从判断——而**境界存档**这条承重机制恰恰要求 `completed` 之后角色的实体状态**必须活着**。

## 决策

**「清理」拆为三层，两条出口各自表态：**

| 层 | `completed` | `defeated` |
|---|---|---|
| **L1 运行时拆解** | 做 | 做 |
| **L2 运行态字段清空** | 做 | 做 |
| **L3 角色实体状态处置** | **不做（保留 = 境界存档）** | 做（留墓碑） |

**`CharacterProfile` 字段按三分而非二分归类**（运行时 / 运行态 / 实体状态），**`chapterRetry` 必须落第三类**。

**存档表达 = 单记录 + `chapterStartSnapshot`**：一个角色恒为 `characterProfile` 列表里的**一条**记录，原地跨三篇章推进；`completed → ongoing` 是合法转移，**只有 `defeated` 是吸收态**。

**`defeated` 留墓碑而非整条删除**（含 `chapterStartSnapshot`）；**snapshot 回收只发生在 ch1 墓碑上**，不引入任何「读取上限」判定。

**ch3 `completed` 永久保留完整档**——为奖杯感付的价，**两条出口的处置自此不对称**。

**`TeardownCycle()` 语义收窄为纯运行时拆解、零存档语义。**

三分表逐字段归属、墓碑形态与 L1–L3 的执行时序 → `systems/services/life-cycle-service.md`。

## 理由

- **`completed` 保留实体状态就是「境界存档」本身**（`ADR-0004`）——L3 若在 `completed` 上执行，重试模型当场失效。
- **`chapterRetry` 落第三类是承重的**：它若进 snapshot，重试就成了「回滚到 0 再 +1」，计数永远停在 1，**重试上限静默失效**。
- **单记录 + snapshot 优于「每篇章一条记录 + 血统引用」**：后者省下一句措辞，换来一条必须新写、随时间失效即静默膨胀的回收规则。
- **`TeardownCycle()` 不塞存档语义**：塞进去就要在方法内分支 `status`，而两屏摘要的组装时点已钉在它之前。
- **ch3 通关档永久保留**：与「元婴为奖杯」同向；零消费方与体积代价在用户明知的前提下被接受。

## 备选方案

- **每篇章一条记录 + 血统引用** — 否决：见上，回收规则会静默膨胀。
- **ch3 `completed` 与 `defeated` 同档处置**（草稿推荐） — 否决（用户裁决）：在明知零消费方与体积代价下选奖杯感。
- **按「读取上限」回收墓碑 snapshot** — 否决：撞上「礼包把重试上限从 3 抬到 9 而 snapshot 已回收」的边角。

## 后果

- **不新增存档点、不 bump schema、后端零配合**；新增字段 `chapterStartSnapshot` 属纯加法。
- **两条出口的处置不对称是有意的**，`life-cycle-service.md` 须明写，不得被后来的「对称化」重构抹平。
- **已通关角色档没有清理通道**——这是 `ADR-0162` 只对 `ongoing` 开放放弃动作的直接后果，同一笔代价。
- 受约束的文档：`systems/services/life-cycle-service.md` · `systems/character-profile/_index.md` · `systems/services/profile-schema-versions.md` · `program-overview.md` · `decisions/ADR-0004-realm-checkpoint-retry-model.md`。

# 打包闸简化定案与爆炸半径闸优化路径的读数面（后端半 · 跨库成对）

- id: 2026-09-06-baseline-superset-and-pack-proof
- date: 2026-09-06
- topic: operations/content-delivery-ops（C6 前提句改写 · A4' 读数面与采纳触发）
- status: distilled
- distilled-to: operations/content-delivery-ops.md
- counterpart: `game-design-documents/handoffs/2026-09-06-baseline-superset-and-pack-proof.md`（客户端半：内容发版纪律 · 退役三分 · 归档闸 · `entryCountsByType` dormant 形态）

## Intent（distilled）

**一句话：** 客户端已确立基线 `Id` 超集纪律并由发版快照归档闸机械保证（本体见 counterpart），本份收后端半：**C6 的「只跑最新」简化经推演不成立、不采纳、不再是待优化项**，逐基线各跑定为长期形态；**A4' 优化路径的读数面与采纳触发现在定死**（形态先定、采纳后置），采纳日退化为一个双侧开关。零新增契约面、零报文改动。

### 一、C6：不采纳任何单基线简化，前提句改写

- 推演（与 counterpart 建议 4 同一条推演的本库落笔）：即便超集成立，「只跑最新」也**不健全且方向反了**——存在性判据在 `Id` 最少的**最旧**在架基线上最严（overlay 触到新版本才有的 `Id`，对老基线即非法新增）；「只跑最旧」同样漏值敏感断言（合并校验结果依赖各基线自身字段值）。
- C6 原写「它需要『更高版本基线是更低版本基线的超集』这个本库不裁决且不必然成立的前提」——现改写为：超集由客户端内容发版纪律保证并由归档闸机械核对（回链 `game-design-documents/systems/services/content-service.md`「内容发版纪律」），但该简化经推演不成立，**逐基线各跑一遍是长期形态、不再是待优化项**。成本已注明可忽略，本来就无需省。
- 连带：`deployment.md` 的快照可达性要求因此是永久义务——该段从未写成过渡态，无句可改，不动。

### 二、A4' 读数面（采纳时的形态，现在定死）

| 项 | 形态 |
|---|---|
| 数据来源 | 产包证明的 `entryCountsByType`（字段形态归客户端，dormant 预写见 counterpart，本库只读数字） |
| 分组 | 对 `disabledIds` 逐条取首个 `.` 之前的前缀做纯字符串分组——语法操作，不解析内容，与「后端不区分内容类别」相容 |
| 池规模口径 | 同前缀计数在兼容矩阵内全部在架基线中取**最小值**（分母取小 = 阈值取严 = 保守） |
| 阈值合成 | 确认参数在「新增解析规模 > 20 **且** > 5% × 该前缀池规模」时才要求（等效阈值 = max(20, 5% × 池)） |
| 兜底 | 前缀不在计数表（未知前缀 / 计数缺失 / 证明过旧）→ 该组按绝对阈值 20 单独判，不放行 |
| 数据时效 | 用最近一次内容发布的证明计数；flags 发布不重取 |

### 三、采纳触发判据（触发前一字不动）

- 触发信号（满足其一）：① 一个季度内 ≥ 2 次**合法**批量关闭被迫携带显式确认参数（绝对 20 已成日常摩擦）；② 任一 flags 适用前缀的最小在架池规模 > **400**（= 20 / 5% 的直接推导，此时缩放才有意义）。
- **触发者 = 本库运维**（闸与摩擦都在本库可见处），触发后提起同批落地，不由客户端猜测时机。
- 三个数值（20 / 5% / 400 与季度 ≥ 2 次）均为待实测校准初值，登记于数值初值一览。

### 四、同批落地协议

采纳日一批改两库：客户端开启 `entryCountsByType` 的 emit（形态已预写）；本库把 A4' 的「未采纳」形态改写为已采纳规则；步 ⓪ 的「证明自洽」核对顺带扩展到计数项（非负整数 · 前缀符合两段式语法）。**任一侧未落，另一侧不启用。**

## Clarifications

- **批量评审裁决（2026-09-06）：「只跑最新」简化不成立，逐基线各跑定为长期形态** → 采纳推演；三处既有落笔同批订正：本库 C6 前提句 · 本库 `handoffs/2026-09-03-content-delivery-ops.md` Open questions 同句 · 对侧 `ADR-0141` 后果句与备选方案句。
- **09-03 handoff 同句取同批订正**（草稿自注「同批订正或由回链承载」二选一）——裁决点名了这一处，旧 handoff 可自由编辑（根约定「一切皆可改」）。
- **A4' 两张表落 `operations/content-delivery-ops.md` 正文**，不取「回链草稿提炼落点」的备选——inbox 归档是过程档案，活文档不得回链它。
- 其余按草稿 `[既有推演]` / `[通行做法]` 标注整体放行（「仍需用户决定：无」经批量评审确认）。

## Open questions

- 无新增。本库 `open-questions/04-content-delivery.md` 无对应条目（超集 / 计数两条的跟踪条目在对侧 `game-design-documents/open-questions/cross-boundary.md`，已由对侧移出）。

## Notes / triage

- 输入：`inbox/solution-draft-baseline-superset-and-pack-proof.md`（已评审）。跨库成对：本份只写后端半，内容发版纪律与产包证明字段形态**全部归对侧**，一律回链不复述。
- 无 ADR 候选——C6 / A4' 均为既有运维形态的定案与形态预写，不产生新的方向性决策；`decisions/` 未改动。
- 明确不改动：`operations/deployment.md`（见上）· `contracts/content-manifest.md`（计数不下发、不进 flags 应答）。

## 客户端侧影响

**零报文改动、零新增契约面**——`entryCountsByType` 活在发布侧产包证明里，不下发客户端。客户端侧的成对落笔（内容发版纪律节 · 退役三分 · 归档闸 · dormant 字段附注 · ADR-0141 订正）已由 counterpart 同批完成，见 `game-design-documents/handoffs/2026-09-06-baseline-superset-and-pack-proof.md`；受影响成分是 content-service 的发版 / 打包流程，运行时零改动。

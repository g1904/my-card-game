# `receipt_idem` 的冷存归档形态与对账阈值 N 的旋钮化

- id: 2026-09-06-receipt-idem-cold-archive
- date: 2026-09-06
- topic: operations/purchase-ops（§1 去计数化 · §3a 清理阈值提为旋钮 · §3b 部分索引 · §3d 整节 · §4 阈值 N）· systems/profile-store（`receipt_idem` 承重列与永久保留口径）· operations/environments（旋钮清单）
- status: distilled
- distilled-to: `operations/purchase-ops.md`、`systems/profile-store.md`、`operations/environments.md`、`operations/_index.md`、`open-questions/06-platform-stack.md`、`open-questions.md`、`open-questions/update-log.md`、`answer-logs/log-receipt-idem-cold-archive.md`

## Intent（distilled）

收据幂等表的两项残余——**体量增长后的冷存归档形态**与**对账信号阈值 N 的旋钮位置与校准方法**——一并落定。存储选型、同事务写入、下单预落未决态、永久保留不设 TTL 这一半此前已定，本次不重新设计。

### 一、归档形态：三层，热层不动

- **热层 = 现有 `receipt_idem` 表本身。** 每张收据永远在这里保留一行（**哨兵行**），承载唯一约束与「他账号核销」判定所需的最小列集。归档不删行，只把记录体列置 `NULL`。
- **温层 = 同库同实例的独立表 `receipt_idem_archive`**，只装记录体列，按 `record_at_utc` 年度 RANGE 分区，每分区上有 `receipt_id` 唯一索引 ⇒ 仍是点查，只是多一跳。
- **冷层 = 对象存储的年度导出**，不在任何在线读路径上，只作长期备份与离线分析；导出不得触发温层分区删除。

三层同库同实例，是「不引入独立存储系统」与「玩家读路径全部走写入区」的直接推论：温层若移到另一实例或只读副本，读己所写与同事务写入当场破防。

**归档表是另一张表，这正是在线哈希分区与按年 RANGE 分区能并存的原因**——单表只有一个分区键。在线分区键不因归档而改动。

### 二、哨兵五列与记录体

常驻：`receipt_id`（唯一性本体）· `account_id`（他账号判定是索引冲突后的当场判定，不可退化为二跳）· `status`（`Unknown` / `Rejected` 无需记录体即可作答）· `tier`（是否走二跳）· `record_at_utc = COALESCE(verified_at_utc, ordered_at_utc)`（二跳的分区剪枝键，缺它则按 `receipt_id` 查温层会广播到全部年度分区）。其余列为记录体，归档时搬走并置 `NULL`。

由此**归档不触碰任何事务路径**：verify 与下单仍只写一张表、仍是一次本地事务。

### 三、读路径与延迟预算

热层主键点查一跳；未命中即新票；他账号 / 非 `Verified` / `tier = hot` 三种情形零二跳；只有 `tier = archived` 才按 `(record_at_utc → 年度分区, receipt_id)` 点查温层。**verify 热路径永不二跳**——新票在第一跳未命中即结束；走二跳的只有老票重复提交与客服补查，这两条路径的延迟预算本就宽松。预算初值：热层 p99 ≤ 20 ms · 温层二跳 p99 ≤ 100 ms · 补查端点端到端 p99 ≤ 300 ms。

### 四、归档任务：单向、幂等、可重入

按批循环，每批一个事务：选取 → `INSERT … ON CONFLICT (record_at_utc, receipt_id) DO NOTHING` → 确认温层已存在后再改哨兵并置空记录体。**顺序不可颠倒**：中断的最坏结果是「温层多一行、热层仍是 `hot`」这一可重跑的空转，而不是「热层已置空、温层未写」这一不可恢复的记录体丢失。`status = 'Unknown'` 的记录不归档（它们是日频对账的日常工作面）。任务周级、低峰、走既有的定时任务出口，不新增调度设施；它是唯一被允许置空记录体的路径，`receipt_idem` 没有任何删除行的路径。

### 五、TTL 禁用断言与备份口径同步扩写

断言须逐张表、逐个分区覆盖 `receipt_idem` 与 `receipt_idem_archive`；两表须在同一 PITR 一致点恢复，并列为恢复演练必检项。少写一张表 = 归档表被一次误配置清掉 = 老票二跳查不到 = 重复发放且线上不可发现，与合表漏洞逐字同形。

### 六、触发信号的一处重分类

行数阈值在「唯一性索引永不归档」这条硬约束下**归档解决不了**——哨兵行常驻，键的条数只增不减；归档能降的只有行宽、堆体积与二级索引条目数。因此它是**容量 / 扩容信号**，处置是纵向扩容 + 哈希分区数扩容。体积阈值与点查 p99 才是归档信号，且 p99 命中时须先按序排除 bloat / 二级索引膨胀 / 连接池与最长事务 / 实例规格四项——在 0.5 GB / 年的体量下，p99 劣化几乎必然出自这四项之一。归档对体积阈值的收益上界约 30–50%，不是一个数量级：`receiptId` 本身往往就是行的主体。

**二级索引 `(accountId, verifiedAtUtc)` 改为 `WHERE tier = 'hot'` 的部分索引**——索引高度与缓存命中率才是点查 p99 的因变量，压住它比搬运记录体更直接。

### 七、对账阈值 N

初值 3 天不动（推导已成立，不重推），提为运行期旋钮 `grantRedeemedLagAlertDays`；另加 `grantRedeemedLagTicketEnabled`（初值 `false`），上线后静默观测 4 周再产出工单——N 的正确性取决于「正常玩家的追平时长分布」，而这条分布在有真实玩家之前不存在。校准公式 `N := clamp(ceil(P99(追平时长_天)) + 1, 3, 14)`，分桶 1 / 2 / 3 / 5 / 7 / 14 / 30+ 天；下界 3 天是一个周末的缺席，上界 14 天是「工单须留出至少两周处置期」。每季度复核，客户端兑现触发点形态一变即刻复核。「差值 ≥ 2」不参与校准（故障与缺席不同轴），仍不做逐账号告警，仍不驱动任何自动写入。

### 八、迁移与开关

迁移按 expand → deploy → contract：expand 加三列 + 建温层空表 + 建部分索引；deploy 发带二跳读路径的新代码；contract 删旧的全量二级索引。**归档任务在 contract 之后、且触发条件命中并完成四项排除后才开启**（`receiptArchiveEnabled` 初值 `false`）。首版不做的结论因此不变，本次补的是形态——触发条件真的命中那天不必临场设计一条正确性关键路径。

## Clarifications

- `receiptArchiveAgeMonths` 初值 → **24 个月**（用户裁决）。它等价于「客服与对账的日常工作面有多宽」而非「查不查得到」——归档后仍可点查。24 个月是唯一不依赖尚未存在的输入（DAU / 成本模型）又能同时覆盖两个年度对账周期与以月计的退款窗口的取值；且它是旋钮，实测后可调。
- 哨兵行永不删的承重前提 → 由合规域的注销删除深度裁决坐实：注销执行时 `receipt_idem` 全行保留。本 handoff 只写归档路径不删行，**保留深度的权威在 `operations/compliance-ops.md`**，不复述。
- 行数阈值的处理 → 采纳重分类（容量信号）而非「三条同列 + 加一句说明」，两者后果相同，重分类更不易被误读为「归档能降行数」。
- 归档任务的 `INSERT … ON CONFLICT` → 冲突目标取 `(record_at_utc, receipt_id)`：分区表上的冲突推断必须覆盖分区键，只写 `receipt_id` 无法命中。
- 旋钮初值的落点 → 初值写在 `operations/purchase-ops.md`，`operations/environments.md`「旋钮清单」只登记名目与权威回链（该清单的既有纪律是初值不重复）。
- 补查端点在热层未命中时的应答语义 → 不在运维文档另立说法，回链 `contracts/purchase.md` §4。
- §1「三把钥匙」的计数表述 → 改为判据式（按轮换驱动方划分，不写个数），使凭据类别增员时不必回头改一个写死的数。

## Open questions

- 归档三条触发阈值与 N 的**定值**仍待上线后的实测数据；本次定的是形态、旋钮位置与校准公式。该残余归 `open-questions/06-platform-stack.md` 的「成本模型」条目。
- 冷层导出的保留期与备份保留期同源，随成本模型落定，本次不越位定值。

## Notes / triage

- 契约面零改动：`contracts/purchase.md` §6 的七条服务端保证在归档后全部成立——「任意时间跨度重复提交仍 `deduplicated = true`」恰恰靠「哨兵行永不删 + 二跳可点查」兑现。
- 无存档 / 报文迁移，无 `schemaVersion` 变化。
- 代价如实记下：归档任务是一条新增的正确性关键路径，因此默认关闭且设了开启前置。

## 客户端侧影响

**无。** 报文、字段、端点语义均不变，客户端零感知、零发版义务。

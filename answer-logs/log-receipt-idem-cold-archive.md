# Answer log receipt-idem-cold-archive

- 日期：2026-09-06
- 来源：`inbox/solution-draft-receipt-idem-cold-archive.md` → `handoffs/2026-09-06-receipt-idem-cold-archive.md`
- 移出条数：1

---

**`receiptId` 幂等记录的冷存归档与对账阈值（`open-questions/06-platform-stack.md`，部分答结的那一条）** → **整条答结并移出。**

- **冷存归档形态**：三层——热层 = 现有 `receipt_idem`（哨兵五列常驻、行永不删、归档只把记录体列置 `NULL`）· 温层 = 同库同实例的 `receipt_idem_archive`（按 `record_at_utc` 年度 RANGE 分区、每分区 `receipt_id` 唯一索引，仍是点查）· 冷层 = 对象存储年度导出（不在任何在线读路径上，只作备份与离线分析）。读路径一跳命中，二跳只对 `tier = archived` 且需要记录体时发生；verify 热路径永不二跳。归档任务按批、单向、可重入，先写温层后改哨兵；`status = 'Unknown'` 不归档。TTL 禁用断言扩为逐表逐分区覆盖两张表，两表须同一 PITR 一致点恢复并列入恢复演练必检项。触发信号中「行数 > 5,000 万」重分类为容量 / 扩容信号（哨兵行常驻使归档不可能降低行数），体积与点查 p99 才是归档信号，且 p99 命中须先排除 bloat / 索引膨胀 / 连接池与最长事务 / 实例规格四项。二级索引改为 `WHERE tier = 'hot'` 的部分索引。迁移走 expand → deploy → contract；归档任务 `receiptArchiveEnabled` 初值 `false`，触发条件命中且完成排除后才开启。`receiptArchiveAgeMonths` 初值 **24 个月**（用户裁决）。
  （归档去向：`operations/purchase-ops.md` §3b §3d · `systems/profile-store.md`）
- **对账阈值 N**：初值 3 天不改，提为运行期旋钮 `grantRedeemedLagAlertDays`；新增 `grantRedeemedLagTicketEnabled`（初值 `false`，上线后静默观测 4 周再产出工单）；校准公式 `N := clamp(ceil(P99(追平时长_天)) + 1, 3, 14)`，分桶 1 / 2 / 3 / 5 / 7 / 14 / 30+ 天，季度复核且客户端兑现触发点形态一变即刻复核。「差值 ≥ 2」不参与校准；仍不做逐账号告警、不驱动任何自动写入。
  （归档去向：`operations/purchase-ops.md` §4 · 旋钮名目登记于 `operations/environments.md`「旋钮清单」）
- **剩余部分**：三条触发阈值与 N 的**定值**仍需真实体量 / 流量，已并入同分片「成本模型」条目；本次答定的是形态、旋钮位置与校准方法。

**顺带落定（非移出项）**：`operations/purchase-ops.md` §3a 悬挂 `claiming` 记录的清理阈值（初值 10 分钟）提为旋钮 `claimingSweepMinutes` 并登记进旋钮清单，标明仅在该退化形态启用时生效。

**跨库**：本次裁决不改动客户端语义，无客户端侧对位 log。

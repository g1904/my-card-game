# 合并 interview 裁决 — 2026-08-18

原始待决 44 项（10 份草稿）→ 去重合并 + 交叉核对后提问 **16 问（4 轮）** → 全部取得裁决。
未提问的 28 项原样保留在各草稿的 `## 仍需用户决定`，由用户评审时处理（`/analyze-new-ideas` 按其既有规则「已定的按定的处理，未定的仍按 Open question 搁置」消费）。

## 轮 1 — 跨草稿冲突 + 最承重

| # | 问题 | 裁决 |
|---|---|---|
| 1 | 🔴 **冲突 1** `BundleGrantOrdinal` 施加权（W3 ↔ W8 相反） | **后端唯一 `+1`，加水位字段 `BundleRedeemedOrdinal`**。连带：`ResourceElements` 整行撤下、不登记为 `CostKey`；W3 账号层第 8 成员换为 `BundleRedeemedOrdinal`（总数仍 15）；W3 决定 3 自动消解 |
| 2 | 🔴 **冲突 2** `ProfileChangeSpec` 总列面 7 → 11 | **接受 11 列，四份单批收口、共用同一次 `schemaVersion` bump** |
| 3 | W6 ① `locale` 归属 | **设备本地**（唯一不动「归一是单点、只发生一次」的选项）。连带：`game-setting.md` 改写为两侧对照表 |
| 4 | W5 取向 3 EnemyCodex 慷慨度 | **维持 3 张关键卡**，退让阶梯保留 |

## 轮 2 — 两条跨草稿交叉 + 两条承重

| # | 问题 | 裁决 |
|---|---|---|
| 5 | 🟠 **交叉 3** `deviceId` 与 `locale` 是否共用一份文件 | **各自一份，不合并**（「整份丢弃」对 `locale` 安全，对 `deviceId` 是一次假换设备 + 假挤下线） |
| 6 | 🟠 **交叉 4** `user://` 原子写五份实现 | **抽成共享静态工具**（`AtomicJsonFile`），五处同用；牵动四处既有文档 |
| 7 | W4 ② `ActiveCombat.rng` 是否收敛 | **收敛，删三格**（消掉一处已存在的相抵；空迁移） |
| 8 | W8 Q2 `/entitlement` 回声校验 | **不等即整批拒绝 + 风控**（后端写入字段封闭表首次获得执行点） |

## 轮 3 — 关闭窗口项 + 前置 + 确认题

| # | 问题 | 裁决 |
|---|---|---|
| 9 | W3 决定 1+2 key 名改名对齐 | **全部改名**（`ExperiencePoint` · `PowerFragmentFinaleWinOrdinal` · `TotalCyclesCompleted/Defeated`）；窗口随第一批存档关闭 |
| 10 | W7 D2 ViewModel 是否单列 | **现在单列 `systems/viewmodel.md`**；D3 随之取 A |
| 11 | W5 前置：图鉴是否与成就 / 奖励挂钩 | **不挂钩** ⇒ 六个键不进透明路径白名单、后端零配合，W5 序列化结论成立 |
| 12 | W10 决定 1 子需求签核形态 | **继承 + 例外闸**（`Open questions` 非空 ⇒ `draft`） |

## 轮 4 — 越界发现是否转新待答项

四组**全部采纳**：

1. **设计库内部对账三条** —— `architecture.md` 待决问题的模式性过期登记（需一次 `architecture.md ↔ services/*` 对账）· `ResourceElements` 表两份投影漂移（7 行 vs 11 行）· 另有 7 个字段（`status`/`defeatReason`/`realm`/`level`/`chapter`/`chapterRetry`/`lastContentVersion`）同为「有纪律、无通道」却不在任何清单里
2. **`LocationCodex` 未确认的默认理解** —— 「本库现按前者理解，待确认」，而三条推论已建在它之上
3. **审计 / 契约两条漏洞** —— 反向审计扫 `errors.csv`（`.csv` 不随导出包分发，波及正向审计）· `/accountInfo` 是「整键替换覆写后端写入字段」的第二处同形
4. **工程层文本不一致两条** —— `inbox/_index.md` 三列 vs 技能第 6b 步五列 · `requirements/_index.md` 残留 `20/30/40` 旧编号（归 `/update-readme` 或技能修订，不进设计库待答清单）

## 落笔提醒（非取向，交 `/analyze-new-ideas`）

- W5 与 W6 都要求追加进 `sync-service.md` **同一次**既有 bump 清单 —— 须合并成一张表，**不得写成两次 bump**。
- W4 张力 5：三份结算流程图（`architecture.md` · `adventure-event/common-properties.md` · `life-cycle-service.md`）须同改，把「记入 pastEvent」移入事务内。**最易漏的一处。**
- W4 张力 1：三级判据第六面措辞须补「形状包含**键的取值空间**与**载荷的字段集合**」，否则 `RngElements` 分列没有判据支撑。
- W8：内部相抵是**三处**而非两处，`systems/player-profile/_index.md` 字段表第 14 行是第三处，**须三处同改**。
- W3：`LastRoll` / `LastEffectiveChance` 无 `CostKey` 是实打实的不一致（按当前字面，Finale 收口的 `TryApply` 会被自己拒绝），补两行闭合。
- W8 两份草稿**必须成对采纳**。

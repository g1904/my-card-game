# 合并 interview 出题清单（2026-08-22 · 10 份 solution draft）

原始分级合计：🔴 31 · 🟠 33 · `[采纳推荐 — 待复核]` 15（分散在各分片）。
去重 + 跨草稿核对后 → **20 问**，分 5 轮。

---

## 一、orchestrator 追加的跨草稿核对

### X-1 【真矛盾 · 必答】置换 / 禁用候选：两个 worker 给出**形状不同**的方案

- `event-outcome-spec` R5 与 `remaining-event-decision-points` 🔴-1 是**同一个问题**（`adventure-event/common-properties.md` L50–60 那张表的「候选何时掷定 = 结算时」），两 worker 独立发现、独立推荐「前移到物化时」，方向一致。
- **但承载形态不同**：
  - outcome-spec (a)：`OutcomeRule` 增第四个 `Kind = AbilityChange`（带 `AbilityChangeOp` / `AbilityKind` / `DisableDuration` / 池或定值目标），走 `OutcomeSpec` 链路。
  - remaining (a)：`EventOption` 上加一个定稿字段，形状与 `EventOption.ResearchSlots` 同构，走 `Reward` 子流。
- 两者若各自落笔 ⇒ 同一个候选有两处承载。**必须合并成一个裁决。** → Q1

### X-2 `ChapterScope` 事件侧落笔归属（编排决定，orchestrator 直接定，不占 interview 名额）
`enemy-pool` 🔴-1 的三选项 → 取 **(a)**：事件侧（`AdventureEventData.ChapterScope`）归 `generation-weighting` 分片（W1）落笔，`enemy-pool`（W4）只写 `EnemyData` 侧。两 worker 的已裁决区对此本就一致。
⚠ 但 `enemy-pool` 🔴-4（Travel 是否豁免）**必须先于 W1 落笔回答** → Q2。

### X-3 「篇章」表示形态交叉核对（band-boundary 提请）
`band-boundary` 的 `BandFor(chapter)` 读**角色所在篇章**（`CharacterProfile.chapter : int`）；`enemy-pool` 的 `ChapterScope : int[]` 表**内容条目的篇章归属**。两者是不同对象、同一底层表示（`int`），**无冲突**。不出题，报告中说明。

### X-4 跨库承接项集中出现（三份草稿各产生一条）
`echo-validation` 🔴-1（对侧半是否本批落笔）· `flags-throttle` 🔴-4（flags 回滚即前滚需契约条款）· `refresh-token` 🔴-2（静默续期绕过协议闸门的收口手段）。
用户本次指定的库是 `game-design-documents`，后端同名草稿**不在本批**。三条合并为一个跨库落笔授权问题 → Q5。

### X-5 热点写入面串行安排（编排决定，不占名额）
`future-event-service.md`（5 份）· `adventure-event/common-properties.md`（4 份）· `balance.md`（3 份）· `architecture.md`（2 份）· `sync-service.md`（2 份）· `combat/_index.md`（2 份）已由 plan.md 的 4 个波次错开。
⚠ 执行注意：W1 会大幅改动 `future-event-service.md` 行号，W2–W4 的 worker **必须按内容定位、不得按行号定位**。

### X-6 三处「同一事实多份副本」（各 worker 独立发现，收尾统一处理）
- 「生成 / 加权规则与叠加顺序」在全库有 **5 份副本**（generation worker 一并清理，收尾 grep 复核）。
- 「硬阻塞 / 阻塞点」在本库有 **3 种互不相同的枚举**（refresh worker 规避为「不复述、回链」）。
- 「登录屏 = 应用首屏」有 **3 处**（`ux/screen-flow.md` L7 + L9、`vision/scope.md` L12）。

---

## 二、分轮出题

### 轮 1 — 会改变机制形状 / 承重结论
- **Q1** X-1 置换 / 禁用候选的掷定时点与承载形态（合并 outcome-spec R5 + remaining 🔴-1）
- **Q2** enemy-pool 🔴-4 Travel 是否豁免 `ChapterScope`（关系到「Travel 兜底恒可产出 ⇒ 无轮回死锁」）
- **Q3** priority 🔴-4 Finale 守卫 + `combat/_index.md` `:42` / `:45` 两读法
- **Q4** enemy-pool 🔴-2 `EncounterScopes` 类型与 ADR-0002 不一致

### 轮 2 — 跨库与契约冲突
- **Q5** X-4 跨库落笔授权（echo 对侧半 + flags 承接项 + refresh 承接项）
- **Q6** refresh 🔴-2 强更闸门：本库三处记载与后端契约相抵 + 客户端是否自收口
- **Q7** refresh 🔴-1 启动链顺序（静默续期 vs `LoginScreen` 位置）
- **Q8** flags 🔴-4 「增大即拉」在版本回滚下的永久停摆

### 轮 3 — 内容侧口子与承重表
- **Q9** outcome-spec R4 事件产出能否给账号级古宝 `(Item, Player)`
- **Q10** outcome-spec R2 + R3 打包（经验 / 隐藏属性裸数字白名单 · `ManaLimit` 幅度恒 1）
- **Q11** flags 🔴-1 退避形态（纯闸门 vs 定时器 = 是否「另开重试机制」）
- **Q12** flags 🔴-3 回退观测告警的可见性（`PushWarning` vs 上报一次）

### 轮 4 — 战斗与事件机制
- **Q13** combat-counter 🔴-1 计数时机（压栈 / 付费 vs 结算成功）
- **Q14** combat-counter 🔴-2 `counters` 键悬空的失败语义（与 L174 校验②相抵）
- **Q15** generation 🔴-1 + 🔴-1.3 批次规模 N 语义与收缩保底
- **Q16** priority 🔴-2 + 🔴-3 打包（开局构筑判定式改写 · ch1 篇章重试是否算新角色首批）

### 轮 5 — 文档口径清理 + 待复核项
- **Q17** 打包：8 项「按推荐修既有文档漂移」（generation 🔴-2 · priority 🔴-1 · band 🔴-1 / 🔴-2 · enemy-pool 🔴-3 · echo 🔴-2 / 🔴-3 · remaining 🔴-2 · outcome-spec R1）
- **Q18** 15 项 `[采纳推荐 — 待复核]` 的复核处置
- **Q19** 33 项 🟠 的处置（各 worker 均已给推荐）
- **Q20** 收尾登记项（越界发现中值得进待答清单的条目）

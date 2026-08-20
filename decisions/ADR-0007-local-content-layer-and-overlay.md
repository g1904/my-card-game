# ADR-0007 — 内容载体形态：随包基线 + overlay 热更 + 云端版本校验

- **状态：** Accepted
- **日期：** 2026-08-11
- **来源：** handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md · handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md · handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md · handoffs/2026-08-11-plot-content-localization.md

## 背景

内容（卡牌、事件、敌人、道具、剧本、平衡表）需要一个存储与分发形态，同时满足三件互相拉扯的事：**平衡数值与文案能绕开应用商店审核周期**、**启动期能对坏数据大声失败**、**首启不依赖网络下载内容**。另有一条边界始终悬着：剧本文本是不是该走云端服务、按进度动态请求。

## 决策

**内容有三层覆盖来源，合并为内存中唯一的 ContentRegistry：**

```
res://content/**.tres        基线内容，随版本发布，只读
user://overlay/**.tres       云端下发的增量，可热更，按 Id 覆盖基线
flags（运行时态，不落 .tres） 按账号解析后的开关结果，只覆盖 ContentEnabled
       ↓ 合并（flags > overlay > res://）
ContentRegistry（内存）       按 Id 索引，全游戏唯一内容读取入口
```

四条配套规则：

1. **校验点在合并之后。** 重复 `Id`、悬空交叉引用 → 启动期 `PushError` 早失败。热更不削弱这条纪律，只把校验点后移。
2. **overlay 只改不增**，新 `Id` 只能随版本发布。**唯一例外 = 剧本内容**（`PlotArcData` / `PlotNodeData`），并由合并期的 `newIds` 双闸机械保证。
3. **全部内容属本地内容层，没有云端内容通道**——剧本正文同样存于 `res://` + overlay，运行时内容零网络请求；网络只在启动期用于 manifest 比对与增量下载。
4. **断网降级到 `res://` 基线**，首启不依赖网络下载内容（但进入游戏仍需登录）。

manifest 携带 `contentVersion` 与逐条目 hash；增量下载走**文件级事务**（staging → 全量校验通过 → 搬入 → 原子写 manifest 为提交点），manifest 由后端 ES256 签名、客户端内置 `keyId → publicKey` 映射验签。完整字段面、四条客户端义务、放量开关 `ContentEnabled` 的三层语义与 flags 通道见 `systems/services/content-service.md`；剧本侧的对应表述见 `systems/services/plot-manager.md`。

## 理由

- **「只改不增」让「旧版本客户端的存档引用到未知内容」这一风险从根上消失**，无需任何兼容规则；合并后强校验只需处理「已知 `Id` 的数值被覆写」一种情形。
- **剧本例外不重新引入那条风险**：剧本文本是内容类别里**唯一不被存档引用**的一类（`CharacterProfile` 只存 key points），故为它放开新增 `Id` 与该纪律的存在目的不冲突，且换来「新剧情可热更不发版」。
- **不设云端剧本服务的判据**：原判据「按进度动态请求、不被存档引用 ⇒ 归云端」是描述性、近乎循环的——「动态请求」是选择的结果而非理由。留在本地后，跨进程边界成分全部是服务本身，「manager 不跨边界」成为无例外的结构性事实；云端一侧则要背整套为网络失败而生的复杂度（事务前置、LRU 预取、延迟预算、超时兜底、断网降级文案）。前提是剧本为预写式内容库，且剧透 / datamine 被接受（与「不承诺防作弊」同调）。
- **文件级事务而非字节级断点续传**：`.tres` 是 KB 级，续传复杂度换不回收益；`overlay/` 的有效性由那一次 rename 定义，与存档原子写同构，故永不存在半套 overlay。

## 备选方案

- **预埋空壳 `Id`、日后用 overlay 填充数值文案** — 否决：与合并后强校验直接冲突（要么放宽校验、要么携带假数值被抽中），且属应用商店审核灰区。运营诉求改由 `ContentEnabled` 三层覆盖满足。
- **剧本走云端服务、按进度逐事件请求** — 否决：见上方判据三条。
- **overlay 全面放开新增 `Id`** — 否决：直接重新打开「旧客户端存档引用未知内容」的风险面。
- **不冻结的例外做成全局回退（挑战模式为此冻结全局 `contentVersion`）** — 否决：正确做法是让该模式内的轮回绑定冻结快照、把例外局部化（见 `decisions/ADR-0006-development-phase-order.md` 的第 ④ 阶段）。

## 后果

- **明确放弃「同一 seed 必然复现同一轮回」**：确定性降级为**同一 `contentVersion` 内**的性质。故存档必须记两个版本号（`StartContentVersion` / `LastContentVersion`），二者不等 = 该轮回跨过内容更新，是「数值突变」类反馈的第一判据。
- 内容更新节奏仍受审核周期约束——只有平衡、文案与剧本能绕开发版。
- 后端因此少一个服务、少一份协议（无 `IPlotBackend` / `PlotRequest` / `PlotSegment`）；错误码映射表不含 `plot` 域。
- 唯一残留风险 = **悬空 key point**（overlay 或客户端版本回退），处置为 `PushWarning` + 叙事降级、不阻塞轮回，并反向约束 key point 的 schema 必须可独立解析、缺失时安全跳过。
- 影响文档：`systems/services/content-service.md`（权威）· `systems/services/plot-manager.md` · `systems/architecture.md`「内容与档案的存储分界」· `vision/scope.md`「时段形态」· `.claude/rules/data-resource-rules.md`。跨库：`backend-design-documents/contracts/content-manifest.md`（manifest 与 flags 报文形态）。

# 收件箱 — 草稿（2026-07-27）

内容管线 / 热更遗留六项 + 断线韧性，**全部裁决通过**。以下为已定案内容，供分流至 handoff 与主题文档。

目标文档：`systems/services/content-service.md`、`sync-service.md`、`account-service.md`、`plot-manager.md`、`life-cycle-service.md`、`systems/common-properties.md`、`systems/character-profile/`、`vision/scope.md`。

---

## 1. 热更节奏：不设占位 Id，改用 `ContentEnabled` 开关放量（已定案）

- **否决「预埋空壳 `Id`、日后用 overlay 填充数值文案」**：与「合并后强校验」冲突（空壳条目要么迫使校验放宽、要么携带假数值被抽中），且属应用商店审核灰区。
- **改为：内容随版本发布、由 overlay 翻开关放量。** 内容共有字段新增 **`ContentEnabled: bool`，默认 `true`**；overlay 只改这个既有布尔字段，完全落在「不得新增 `Id`」纪律内。
- **过滤只发生在产出侧，不在读取侧**（关键不对称）：
  - `future-event-service` 产出 eventOptions、商店库存、奖励掷骰等**只从 `ContentEnabled == true` 的集合抽取**；
  - `ContentRegistry.Get(id)` **不过滤**——存档引用到一个刚被关闭的条目仍能正确解析，只是不再被新抽到。因此「存档引用未知内容」的风险依然为零。
- **合并后校验对 disabled 条目照常全量执行**（`Id` 唯一性、交叉引用不悬空）：它们是完整内容，只是不进抽取池。
- 为免各产出侧漏写过滤（漏写即线上事故），`ContentRegistry` 直接提供 **`AllEnabled()`**。
- **纪律条款**：任何从内容集合抽取的代码必须走 `AllEnabled()`——与「不散落 `ResourceLoader.Load`」同级，补进 `.claude/rules/data-resource-rules.md`。
- **能力边界（如实）**：本机制压缩的是「已随包发布内容的放量时机」，**不压缩内容本身的发版节奏**；换来灰度、分批放量、线上秒关三项运营能力。

## 2. 存档记录 `contentVersion`：记两个（已定案）

- `CharacterProfile.StartContentVersion` —轮回开始时生效的版本，**写一次不再变**。
- `CharacterProfile.LastContentVersion` — **每个自动存档点**更新为当时生效的版本。
- 二者不等 = 该轮回跨过内容更新，是排查数值突变类玩家反馈的**第一判据**（07-26 已裁决不冻结 `contentVersion`，故必须记两个而非一个）。
- **push 负载信封同时携带** `contentVersion` / `appVersion` / `revision`，让后端不解 Profile 即可做版本维度聚合与异常检测。
- **每日种子 / 排行挑战不在中期路线图内**（见第 7 节路线顺序），因此**不预留冻结结构**；仅在 `content-service.md` 留一句方向性记录：若将来引入挑战模式，正确做法是让该模式内的轮回绑定一个**冻结的 `contentVersion` 快照**，把例外局部化，而非回退全局的「以 overlay 为准」决策。

## 3. 增量下载与防篡改（已定案）

- **粒度 = 文件级。** manifest 已携带逐条目 hash，只下载 hash 不匹配的文件。整包全量重下仅在两种情形：首次安装 overlay、`manifestSchema` 不匹配。
- **不做字节级断点续传**（`.tres` 为 KB 级），改做**文件级事务**：

```
user://overlay/                 已生效热更层（永远完整）
user://overlay.manifest.json    提交点：contentVersion + 逐文件 hash + 签名
user://overlay.staging/         下载落地区，允许脏，失败即清空
```

- **更新流程：** ① 比对本地 `overlay.manifest.json` 与云端 manifest 得出待下集；② 逐文件下载进 `overlay.staging/` 并**逐文件校验 hash**，失败重下该文件（指数退避，最多 3 次）；③ **全集齐备且全部校验通过后**才搬入 `overlay/`，最后**原子写 `overlay.manifest.json`（临时文件 → rename）= 提交点**；④ 任一步失败 → 清空 staging，`overlay/` 与其 manifest 保持上一个完整版本，本次更新视为未发生，走既有断网降级（用现有层照常开局）。
- **由此永不存在半套 overlay**：`overlay/` 的有效性由那一次 rename 定义，与存档原子写同构。
- **防篡改 = manifest 签名（做）。** 后端私钥签 manifest，客户端内置公钥验签；逐文件完整性由已签名 manifest 内的 hash 保证（一次验签 + N 次 hash，近乎零成本）。校验不过 → `GD.PushError` 拒绝该 overlay、回退 `res://` 基线、上报一次事件。
- **明确边界**：客户端完整性做到「防误 / 防随手改」为止，**不承诺防作弊**（改内存 / 改二进制不在防御范围）。纯 PvE + PlayerPower 已被接受为「轻度提升、影响平衡可容忍」，反作弊无收益。
- `ContentUpdateManager.CheckAndUpdate()` 返回 `{ updated, fromVersion, toVersion, failReason }`；**`failReason` 必须区分 网络 / 校验（hash 或签名不符）/ 磁盘空间**——三者 UX 与上报处置不同。

## 4. 断线降级（已定案）

**总原则：绝不回退存档点。** 回退会抹掉玩家已打完的战斗；「云端权威」解决的是冲突，不是丢进度。

| 通道 | 失败时行为 |
|------|-----------|
| **Push（上行存档）** | **不阻塞玩家。** 变更进本地待发队列（`user://cache/pending/`，原子写，跨启动保留），指数退避重试；UI 常驻「离线 · 待同步 N」指示 |
| **Pull（启动全量）** | **硬阻塞。** 强制在线下无权威档即不可玩；呈现「重试 / 退出」，**不提供本地缓存开局**（本地非权威，用它开局等于制造必然冲突） |
| **剧本请求** | **事务前置。** 剧本内容取得**之前**不施加任何成本、不推进 key point；取不到 → 该事件呈现「内容加载失败 · 重试」，Profile 零变更 |

- **缓冲上限（两个闸门，先到先触发）：未同步的自动存档点数 ≥ 3**，或**最早一条待发变更滞留 ≥ 180 秒**。
- **超限 → 软阻塞（已确认可接受）：** 不打断进行中的事件（战斗打完），但在**下一次 AdventureEvent 选择前**弹模态「网络异常，正在重连」，提供「重试 / 退出到主界面」。退出时待发队列保留本地。
- **恢复后的合并语义：** `FlushPending()` 前**先 pull**；若云端 `revision` 已领先本地基线（多设备），**以云端为准丢弃本地缓冲**，并明确告知玩家「另一设备的进度已生效，本次离线进度未保留」。不做静默合并、不引入字段级三路合并（那会实质削弱 ADR-0003）。
- **token 失效 / 被挤下线：** `RefreshToken()` 静默刷新；刷新失败**视同断线**走同一缓冲通道（不另开一套）；被后端明确挤下线 → **硬阻塞**要求重登，重登后同样先 pull 后 flush。（本条同时答结 `account-service.md`「token 失效时正在进行的轮回如何处理」。）
- **剧本缓存：** PlotManager 按 key points **预取下一批**剧本文本，LRU 缓存于 `user://cache/plot/`（纯缓存、可随时丢弃、不落存档）。有缓存直接用，无缓存才走上表失败路径。（本条同时答结 `plot-manager.md`「剧本离线降级」。）
- `SyncService` 事件面补充：`进入断线缓冲态(pendingCount)` / `缓冲超限(软阻塞)` / `离线进度被云端覆盖`。

## 5. RNG 状态持久化形态（已定案）

- 子流派生：**`streamSeed = Hash64(CycleSeed, streamName)`**——子流 seed 可随时从 `CycleSeed` 重算，存档中存它只为诊断与自校验。
- schema（挂在 `CharacterProfile` 下）：

```jsonc
"rng": {
  "CycleSeed": 12345678901234567890,        // u64，轮回开始时生成，不变
  "streams": [
    { "name": "map",    "seed": 0, "state": 0, "drawCount": 0 },
    { "name": "combat", "seed": 0, "state": 0, "drawCount": 0 },
    { "name": "shop",   "seed": 0, "state": 0, "drawCount": 0 },
    { "name": "reward", "seed": 0, "state": 0, "drawCount": 0 }
  ]
}
```

- **`State`（u64）是恢复用的权威字段** —— 重建子流后回填 `RandomNumberGenerator.State`，O(1)，不必重放。
- **`DrawCount`（int）是诊断与迁移保险** —— `State` 是引擎实现细节，Godot 升级可能改变其语义；届时用 `seed + drawCount` **fast-forward 重放**恢复（一次轮回抽取数千次，重放成本可忽略）。冗余成本每流 4 字节。
- **子流清单是 `SeedManager` 内的常量。** 读档遇存档中没有的**新子流** → `GD.PushWarning` + 按 `Hash64(CycleSeed, name)` 全新初始化；遇清单里已不存在的**旧子流** → 警告并丢弃。**增删子流不 bump schema 版本。**
- **防 re-roll：** 战斗内随机**不直接用 `combat` 子流**，而是每场再派生 `Hash64(combatStreamSeed, eventId, attemptIndex)`；否则「退出重进」会重掷战斗随机——强制在线 + 云端权威下这是最易被发现的漏洞。

## 6. 自动存档点频率（已定案）

- **「存档点」与「push」解耦。** 既有逻辑存档点清单（轮回开始 / 每个 AdventureEvent 结算后 / 篇章边界 / 轮回结束）**保持不变**，每个点**立即原子写本地缓存**（毫秒级、无流量电量顾虑，是崩溃恢复第一道防线）；受频率约束的只是**网络 push**。
- **合并窗口：push 5 秒防抖**（窗口内多次变更合成一次上行）。一次 AdventureEvent 以分钟计，5 秒足以吃掉「事件结算 + 奖励 + 属性推拉」这类连续写。
- **强制立即 flush（不受防抖约束）：** 篇章边界、轮回结束、角色 `defeated`、进入战斗前、**应用失焦 / 挂起**（`NOTIFICATION_APPLICATION_PAUSED` / `WM_GO_BACK_REQUEST`）。最后一条比调频率重要得多——它是移动端被系统杀死前的最后机会。
- `SyncService.Push(profile, reason)` 增加 **`PushPolicy { Debounced | Immediate }`**。
- **增量 push 粒度一并定案：按 `CharacterProfile` 粒度做 diff。** `PlayerProfile` 整聚合含全部历史角色、随账号年龄单调增长，整体上行不可持续。粗算一次轮回约 200 事件 × ~2 KB diff ≈ 400 KB，移动网络可接受。

## 7. 开发路线顺序（已定案 · ADR 候选「开发顺序」）

**框架 → 内容 → 平衡与体验 → 社交及其他。**

1. **先做游戏框架**（服务骨架、核心循环、存档 / 同步、内容管线）；
2. **再横向填充内容**（九类 AdventureEvent、卡牌、敌人、剧本）；
3. **然后打磨平衡与体验**；
4. **最后才考虑社交与其他功能**——每日种子、排行挑战归于此阶段，故当前不为其预留结构。

## 8. 连带修订

- **存档 schema bump 版本**（新增 `rng` / `StartContentVersion` / `LastContentVersion`）。当前无线上存档，迁移为**空迁移**——就在此刻把 `MigrationManager` 的逐版迁移骨架立起来（最便宜的时机）。
- **`vision/scope.md` 第 10 / 57 行**仍写「轮回带 seed 且可复现，便于复现 bug」——已被 07-26 决策推翻，改写为：**同一 `contentVersion` 内可复现；跨版本以存档记录的 `contentVersion` 归因**。
- **可移出 `open-questions.md` 的条目：** 内容管线 / 热更主题组全 6 条；`sync-service.md` 的「增量 push 粒度」「自动存档点清单」；`account-service.md` 的「token 失效时正在进行的轮回」；`plot-manager.md` 的「剧本离线降级」。

## 9. 数值旋钮初值（待实测校准，归 `balance.md` 或运行时配置）

| 旋钮 | 初值 |
|------|------|
| push 防抖窗口 | 5 s |
| 断线缓冲上限（存档点数） | 3 |
| 断线缓冲上限（时长） | 180 s |
| 下载重试次数 / 退避 | 3 次 / 1s · 2s · 4s |
| 剧本预取深度 | 下一批 eventOptions 对应的 key points |

## 10. 新增 / 变更字段汇总

| 位置 | 字段 | 类型 | 默认 |
|------|------|------|------|
| `XxxData`（内容共有） | `ContentEnabled` | `bool` | `true` |
| `CharacterProfile` | `StartContentVersion` | `string` | — |
| `CharacterProfile` | `LastContentVersion` | `string` | — |
| `CharacterProfile.Rng` | `CycleSeed` | `ulong` | — |
| `CharacterProfile.Rng.Streams[]` | `Name` / `Seed` / `State` / `DrawCount` | `string` / `ulong` / `ulong` / `int` | — |
| push 信封 | `contentVersion` / `appVersion` / `revision` | `string` / `string` / `long` | — |

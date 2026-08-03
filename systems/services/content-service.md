# content-service（服务）

> 内容资产服务：`res://` 基线 + `user://overlay/` 热更层的合并、按 `Id` 索引、统一仓储接口。**判据 ③ —— 外部 I/O 边界（内容版本比对与下载）+ 启动流程。**
> Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 存储形态：三层（已定案）

```
res://content/**.tres        基线内容，随版本发布，只读
                             → 保证首启可用、离线可读
user://overlay/**.tres       云端下发的增量，可热更，按 Id 覆盖基线
       ↓ 合并（overlay 优先，res:// 兜底）
ContentRegistry（内存）       按 Id 索引，全游戏唯一内容读取入口
```

- `res://content/manifest.json` 携带 **`contentVersion`** 与逐条目 hash。启动时 ContentUpdateManager 比对云端版本，有更新则下载增量到 `user://overlay/`。
- **校验点在合并之后。** 重复 `Id`、悬空交叉引用（如某遭遇战列出未知敌人 `Id`）→ `GD.PushError` **启动期早失败**。热更并未削弱这条纪律，只是把校验点从「加载 `res://` 后」后移到「合并完成后」。
- **断网降级：** 跳过更新，直接使用 `res://` 基线 —— **首启不依赖网络下载内容**（但进入游戏仍需登录）。
- **收益：** 平衡数值、事件定义、卡牌数值**可热更而不发版**，规避微信 / App Store 审核周期；同时保留启动期强校验与离线首启能力。

### 热更范围：只改不增（已定案）

- **overlay 只能修改既有条目的数值 / 文案，不得新增 `Id`。** 新卡 / 新事件 / 新道具等**新内容只能随版本发布**，走应用商店审核。
- **收益：** 「旧版本客户端的存档引用到未知内容」这一风险**从根上消失**，先前设想的兼容规则不再必要；ContentRegistry 的合并后强校验只需处理「已知 `Id` 的数值被覆写」这一种情形。
- **代价：** 内容更新节奏受审核周期约束——只有平衡与文案能绕开发版。Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。

### 放量开关 `ContentEnabled`：不预埋占位 Id（已定案）

**否决「预埋空壳 `Id`、日后用 overlay 填充数值文案」。** 两条理由：① 与「合并后强校验」直接冲突——空壳条目要么迫使校验放宽（丢掉启动期早失败这条纪律），要么携带假数值被抽中；② 属应用商店审核灰区（随包发的是不可玩的壳）。

**改为：内容随版本发布，由 overlay 翻开关放量。**

- 内容共有字段新增 **`ContentEnabled: bool`，默认 `true`**（见 `systems/common-properties.md`）。overlay 只改这个**既有布尔字段**，完全落在「不得新增 `Id`」纪律内。
- **过滤只发生在产出侧，不在读取侧**——这条不对称是机制成立的支点：

  | 侧 | 行为 |
  |----|------|
  | **产出侧**（`future-event-service` 产 eventOptions、商店库存、奖励掷骰） | **只从 `ContentEnabled == true` 的集合抽取** |
  | **读取侧**（`ContentRegistry.Get(id)`） | **不过滤**——存档引用到刚被关闭的条目仍能正确解析 |

  因此「存档引用未知内容」的风险**依然为零**：关闭一个条目只让它不再被新抽到。
- **合并后校验对 disabled 条目照常全量执行**（`Id` 唯一性、交叉引用不悬空）——它们是完整内容，只是不进抽取池。
- 为免各产出侧漏写过滤（漏写即线上事故），ContentRegistry 直接提供 **`AllEnabled()`**，让「正确」成为最短路径。**纪律条款：任何从内容集合抽取的代码必须走 `AllEnabled()`**——与「不散落 `ResourceLoader.Load`」同级，见 `.claude/rules/data-resource-rules.md`。
- **能力边界（如实）：** 本机制压缩的是**已随包发布内容的放量时机**，**不压缩内容本身的发版节奏**；换来**灰度 / 分批放量 / 线上秒关**三项运营能力。Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。

### 存档记录 `contentVersion`：记两个（已定案）

| 字段 | 语义 |
|------|------|
| `CharacterProfile.StartContentVersion` | 轮回开始时生效的版本，**写一次不再变** |
| `CharacterProfile.LastContentVersion` | **每个自动存档点**更新为当时生效的版本 |

- 二者不等 = 该轮回**跨过内容更新**，是排查「数值突变」类玩家反馈的**第一判据**。因不冻结 `contentVersion`（见上节），一个版本号无法表达「跨过」，故必须记两个。
- **push 负载信封同时携带** `contentVersion` / `appVersion` / `revision`，让后端**不解 Profile** 即可做版本维度聚合与异常检测（见 `sync-service.md`）。
- **不为每日种子 / 排行挑战预留冻结结构**——它们不在中期路线图内（`vision/scope.md` 的开发路线第 ④ 阶段）。**方向性记录：** 若将来引入挑战模式，正确做法是让**该模式内的轮回绑定一个冻结的 `contentVersion` 快照**，把例外**局部化**，而非回退全局的「以 overlay 为准」决策。Source: 同上。

### 增量下载：文件级事务（已定案）

- **粒度 = 文件级。** manifest 已携带逐条目 hash，只下载 hash 不匹配的文件。**整包全量重下仅两种情形**：首次安装 overlay、`manifestSchema` 不匹配。
- **不做字节级断点续传**（`.tres` 是 KB 级，续传复杂度换不回收益），改做**文件级事务**：

```
user://overlay/                 已生效热更层（永远完整）
user://overlay.manifest.json    提交点：contentVersion + 逐文件 hash + 签名
user://overlay.staging/         下载落地区，允许脏，失败即清空
```

- **更新流程：** ① 比对本地与云端 manifest 得出待下集；② 逐文件下载进 `overlay.staging/` 并**逐文件校验 hash**，失败重下该文件（指数退避，最多 3 次）；③ **全集齐备且全部校验通过后**才搬入 `overlay/`，最后**原子写 `overlay.manifest.json`（临时文件 → rename）= 提交点**；④ 任一步失败 → 清空 staging，`overlay/` 与其 manifest **保持上一个完整版本**，本次更新视为**未发生**，走既有断网降级（用现有层照常开局）。
- **由此永不存在半套 overlay：** `overlay/` 的有效性由**那一次 rename** 定义——与存档原子写**同构**。Source: 同上。

### 防篡改：manifest 签名（已定案）

- 后端**私钥签 manifest**，客户端**内置公钥验签**；逐文件完整性由**已签名 manifest 内的 hash** 保证（一次验签 + N 次 hash，近乎零成本）。
- 校验不过 → `GD.PushError` **拒绝该 overlay、回退 `res://` 基线**、上报一次事件。
- **明确边界：** 客户端完整性做到「**防误 / 防随手改**」为止，**不承诺防作弊**（改内存 / 改二进制不在防御范围）。纯 PvE + PlayerPower 已被接受为「轻度提升、影响平衡可容忍」，反作弊无收益。Source: 同上。

### overlay 与进行中轮回：以 overlay 为准（已定案）

- **不冻结轮回的 `contentVersion`。** 轮回进行中 overlay 被更新时，**新数值立即对进行中的轮回生效**。
- **明确放弃「同一 seed 必然复现同一轮回」的保证**——它让位于「线上数值可随时修正」。确定性因此降级为**同一 `contentVersion` 内的性质**：存档恢复仍必须正确继续（RNG 状态照常持久化），只是不再承诺跨内容版本可复现。详见 `systems/common-properties.md`。Source: 同上。

### 统一操作接口（已定案）

ContentRegistry 为每种 `XxxData : Resource` 持有一个仓储，对外是**同一形状**：

```csharp
IContentRepository<T> where T : Resource
    T                Get(string id);              // 必需：缺失 → PushError + 抛出
    bool             TryGet(string id, out T v);  // 可选：缺失 → 调用方降级
    IReadOnlyList<T> All();
    IReadOnlyList<T> AllEnabled();                // 抽取池：仅 ContentEnabled == true
    IEnumerable<T>   Where(Func<T,bool> predicate);
```

**所有服务经此取内容；代码中不散落 `ResourceLoader.Load`。** 新增一种内容类型 = 新增一个 `XxxData` 与一个仓储条目，**不新增服务、不改调用方**——这正是「同类内容的统一入口与标准操作接口」这一诉求的正确落点（而非按内容类型各开一个服务，见 `_index.md` 的拆分轴）。

### 本地 / 云端内容分界（已定案）

一条判据划清：

| 判据 | 归属 | 内容 |
|------|------|------|
| 有稳定 `Id`、**被存档引用**、需启动期校验 | **本地内容层**（`res://` + overlay） | `AdventureEventData`、`CardData`、`EnemyData`、`ItemData`、`PlayerPowerData`、平衡表 —— **含静态展示文案** |
| 按进度**动态请求**、一次性呈现、**不被存档引用** | **云端剧本服务** | AdventurePlot 的剧本分支文本与揭示内容（见 `plot-manager.md`） |

因此 **AdventureEvent 的定义本身属本地内容层**，ContentRegistry 的启动期强校验模型成立；云端剧本服务只下发文本，不进 ContentRegistry、不落存档。

## 管理器

| manager | 职责 |
|---------|------|
| **ContentRegistry** | 合并 overlay + 基线，按 `Id` 建立索引，暴露泛型仓储接口；合并后统一校验 |
| **ContentUpdateManager** | 读本地 manifest、比对云端 `contentVersion`、**manifest 验签**、逐文件下载进 `overlay.staging/` 并校验 hash、事务性搬入 `overlay/`、断网降级 |

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务实现 `IBootstrappable`，是启动链**第一步**（版本比对 + overlay 合并 + 校验；断网降级到 `res://` 基线）。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 版本比对 + 下载 | B | `Task<OpResult<ContentUpdateInfo>> CheckAndUpdateAsync(CancellationToken ct)` | 业务失败 → `OpResult`；`OpError` 区分 `Network` / `Validation`（hash 或签名不符）/ 磁盘空间，三者 UX 与上报处置各不相同 |
| 合并加载 + 校验 | A | `void LoadAll()` | 校验失败 = **坏数据** → `GD.PushError` + 定位 `Id` + `throw`（启动期早失败）。**disabled 条目照常参与校验** |
| 取仓储 | A | `IContentRepository<T> Repo<T>() where T : Resource` | 未注册的类型 = 程序缺陷 → `PushError` + 抛 |
| 当前版本 | A | `int ContentVersion { get; }` | — |

```csharp
public readonly record struct ContentUpdateInfo(int FromVersion, int ToVersion, int FilesApplied, bool FellBackToBaseline);

public interface IContentRepository<T> where T : Resource
{
    T                Get(string id);               // 必需：缺失 → PushError + throw
    bool             TryGet(string id, out T v);   // 可选：缺失 → PushWarning，调用方降级
    IReadOnlyList<T> All();
    IReadOnlyList<T> AllEnabled();                 // 抽取池：ContentEnabled == true；产出侧唯一取池入口
    IEnumerable<T>   Where(Func<T, bool> predicate);
}
```

- **`Repo<T>()` 而非七个具名属性：** 新增内容类型 = 注册一个仓储，**调用方与服务签名都不动**（可加性）。
- **`AllEnabled()` 是物化取池的唯一入口：** future-event-service 物化时必须从 `AllEnabled()` 取候选；`Get(id)` 不过滤——使存档中引用到已关闭条目的实例仍能正确解析。
- **返回的集合一律 `IReadOnlyList<T>`**（总则 3：服务不返回内部可变集合）。

**后端接口（总则 7）：** 本服务持有 `IContentBackend`（`GetManifestAsync` 等），两份实现 `HttpContentBackend` / `OfflineContentBackend`。

**事件面：** `ContentUpdateFinished(ContentUpdateInfo Info, bool Success)` 经 EventBus 广播给启动流程 / UI；校验失败明细与 overlay 验签拒绝走 `GD.PushError` 日志 + 该事件的 `Success = false`。

## 决策(-> ADR)

- **内容载体形态（随包基线 + user:// 覆盖层 + 云端版本校验）** → 已定案，**ADR 候选**（待固化）。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- 云端下发依赖 **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **`AllEnabled()` 纪律的可执行性。** 约定已立（抽取必走 `AllEnabled()`），但**如何在代码评审之外强制**未定：`All()` 是否应改名为 `AllIncludingDisabled()`，让默认路径就是安全路径？还是靠 Roslyn 分析器 / 评审清单？Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。
- **`ContentEnabled` 的粒度是否够用。** 单一布尔只支持「全开 / 全关」；**灰度与分批放量**需要按玩家分桶（百分比 / 白名单 / 篇章档位），而布尔字段本身不携带分桶信息。分桶信息放哪（overlay 的另一层配置？后端下发的 bucket 列表？）未定。Source: 同上。
- **disabled 条目被存档引用时的 UX。** 读取侧不过滤，故存档能正确解析；但玩家手中一张「已被线上关闭」的卡 / 道具**是否应有任何提示**，还是完全静默照常可用，未定。→ 亦见 `ux/`。Source: 同上。
- **`manifestSchema` 的版本化。** 它触发整包全量重下，但其自身的版本号形态、与 `contentVersion` / `appVersion` 的关系未定。Source: 同上。

## 对应
提炼至：`.claude/knowledge/systems/content-service.md`（引用层，待建）。

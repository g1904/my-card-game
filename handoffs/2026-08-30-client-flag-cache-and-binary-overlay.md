# flags 本地缓存的落盘纪律 · 二进制资产不经 overlay（客户端半）

- id: 2026-08-30-client-flag-cache-and-binary-overlay
- date: 2026-08-30
- topic: systems/services/content-service（`flags.json` 落盘纪律 + overlay 非 `.tres` 处置）· systems/common-properties（`Artwork` 的 overlay 收口）· art/visuals（条件化记录）· decisions/ADR-0120（后果第 4 条）
- status: distilled
- distilled-to: systems/services/content-service.md, systems/common-properties.md, art/visuals/_index.md, decisions/ADR-0120-content-artwork-and-enemy-lines.md
- counterpart: `backend-design-documents/handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md`

> **本 handoff 只写归客户端的那一半。** 报文形态、服务端义务边界、blob 通道的能力声明归对侧，见 `counterpart`。凡涉及对侧语义处一律写路径回链，不复述。

## Intent（distilled）

**一句话：** 两条「两侧都以为归对方」的跨边界空档同批关闭 —— ① flags 落客户端本地缓存这件事本就已定案，缺的只是落盘细节（`schemaVersion` · 写入时点 · 盘上 `flagsVersion` 的用途）与一次对账；② 二进制资产**不**经 overlay / blob 通道下发，`Artwork` 的 overlay 语义由悬置改为收口，契约报文零改动。

### 1. 两条空档的性质完全不同，不能用同一种力度处理

- **flags 缓存是台账错位，不是设计空档。** `content-service.md`「flags：`ContentEnabled` 的第三层」早已定下 `user://cache/flags.json` 的字段、原子写、跨启动保留、切账号即失效、冷启动内存版本归零、拉取失败时的降级口径。缺的是两处真空缺（`schemaVersion`、写入时点）与一处须明写的补强（盘上 `flagsVersion` 只作诊断），以及把对侧那条「归客户端裁决」关掉。
- **二进制资产是真空档**，且它压在一条刚 Accepted 的 ADR 的承重形态上。答案是**不开放**。

### 2. `flags.json` 的落盘纪律（四格）

| 项 | 形态 |
|---|---|
| 路径 | `user://cache/flags.json`（不变） |
| 字段 | `{ schemaVersion, accountId, flagsVersion, disabledIds }`——**新增 `schemaVersion`** |
| 写入 | 原子写走 `AtomicJsonFile`（不变）；**写入时点 = 一批 flags 通过单调闸并被应用之后，仅此一处** |
| 读取消费面 | 只消费 `disabledIds`；`flagsVersion` 只进日志 / 告警上下文，不回填内存版本 |
| 失效 | `accountId` 不匹配 → 丢弃 + `PushError`；解析失败 / 字段缺失 / `schemaVersion` 不认识 → 丢弃 + `PushWarning`；**无 TTL** |
| 生命周期 | 跨启动保留；**丢弃 ≠ 删文件**；登出不主动删除 |
| 存档影响 | **零**——不进存档 / Profile / 上行负载，不 bump 任何 schema |

三条判据各自成立：

- **带 `schemaVersion`** —— `systems/architecture.md` 的逐份判据（多字段结构体带版本、单字段设备维度小文件不带）点名 `content-service.md` 是逐份落点之一，而本库此前漏写这一格。三格且字段面会增长（报文侧的 `enabledIds` 是保留字段）⇒ 判据直接给出答案，与 `refresh-token.json` 同形。
- **「版本不认识即整份丢弃」不需要迁移路径** —— 它是可再生的降级缓存，丢弃代价仅为本次会话在拉到第一批 flags 前退回 overlay 布尔。`device-id.json` 刻意不带版本的两条理由（单字段无迁移面 · 丢弃 = 一次假换设备、有后端可见副作用）在此都不成立。
- **写入时点与「应用」逐字重合** —— 不写下来必被实现成「拉回即落盘」，那样一批未过单调闸的旧 flags 会在盘上覆盖已生效批次，把一条内存护栏在盘上打穿。

### 3. 二进制资产：不开放

四条理由，任意一条单独足以否掉，合起来是连锁的：

1. **撞 `ADR-0120` 的承重形态。** `Artwork` 是直接资源引用，在 `.tres` 里落为 `ExtResource`；落在 `user://overlay/` 的裸资产不是导入产物。要让它被条目引用，只能退回 ADR 已逐条否决的路径字符串 + 运行时加载，并自写一套悬空校验与解码失败处置。
2. **overlay 的收益边界里没有它。** overlay 的既定收益是平衡数值 / 事件定义 / 卡牌数值可热更而不发版，且它只改不增。改一张既有条目的插画是纯视觉修订，不是线上事故的止血手段（止血手段是 flags 秒关，分钟级）。
3. **连锁推翻「不做字节级断点续传」。** 那条否决的前提被写明为「`.tres` 是 KB 级」。贴图是 MB 级，弱网下失败重下整份的代价与成功率都会翻过来。**这是四条里最硬的一条，因为它指名了既有判据的前提。**
4. **排期上不需要。** 美术是路线末段、挂点先占位、末段替换，资产替换与发版天然同节奏。

**收口句覆盖本节的全部资产引用格，不止 `Artwork` 一格。** 同批另有一格随境界索引的稀疏资产引用落在同一小节内，收口纪律对它同样成立；只说 `Artwork` 会在那一格写下后漏掉它。

### 4. 配套：非 `.tres` 文件的两道处置

「不开放」若只是一句约定，实现期一次误配置就会把二进制推到设备上。按内容侧纪律的既定分级：**打包工具硬闸（`files[]` 出现非 `.tres` → 不产出包，运维形态归对侧）+ 客户端兜底（跳过该文件、`LoadAll()` 后汇总一行 `PushWarning`）**。客户端取「跳过」而非「拒绝整批」——拒绝整批 = 一次误配置停摆全体玩家的内容更新，而跳过不破坏文件级事务的任何性质。**不新增 manifest 字段、不提升 `manifestSchema` 支持集合、不新增第三处硬阻塞。**

### 5. 写成可撤销的条件化记录

`art/visuals/_index.md` 留下代价清单：成对改动 `ADR-0120` 的引用形态 + 重开断点续传评估 + 对侧契约三点核对。纯加法窗口在第一批 `.tres` 写下时关闭。这条记录的作用是让日后的复议知道自己在动什么，不是暗示它随时可做。

## Clarifications

- **「换图 / 加图不发版」值不值 `ADR-0120` 形态的代价 → 选项 A：不开放**（用户 2026-08-28 批量评审裁决）。二进制不经 overlay / blob 通道下发。
- **`ADR-0120` 后果第 4 条不指向任何 ADR 编号。** 草稿要求「补一句指向新 ADR」，但本次不产出 ADR（立档归 `/write-adr`），指向一个尚不存在的编号 = 写下一个悬空引用。改为直接写结论 + 回链 `systems/common-properties.md`。**同批删掉该条尾句「后端库留对侧承接项」**——对侧的登记实际在 `contracts/content-manifest.md` 的 Open questions 与 `open-questions/04-content-delivery.md`，不在承接分片，该半句在落笔时就不准。
- **`content-service.md`「服务端只保证三件事」改为回链对侧「服务端保证」小节。** 该处的计数是服务端保证被重构为 A 组四条之前的残留；两库对同一契约不一致时以后端契约为准。取回链而非改数字，避免长出第三份副本。
- **收口句按「本节的全部资产引用格」写，不止 `Artwork`。** 两份草稿都未写到这一点；同小节内另有一格随境界索引的稀疏资产引用同批落笔。
- **理由 ① 的引擎行为不作事实断言。** 草稿自陈须在 Godot 编辑器实测确认，本次无法运行编辑器，故正文只保留可由既有判据推出的部分（形态撞 ADR 已否决的路径），不断言引擎行为；理由 ②③④ 独立成立。
- **草稿引文的六处订正**（落笔以文档原文为准）：`common-properties.md` overlay 行的引文不逐字；「`user://cache/` 下切账号即失效不是通则」只在 `player-profile/game-setting.md`；「整批丢弃 + 告警 + 上报一次」逐字来自 `open-questions/cross-boundary.md` 的对账基线而非 `content-service.md` 正文；「三处落盘细节」实为 2 处真空缺 + 1 处补强。

## Open questions

无新增。本 handoff 关闭的两条见 `answer-logs/log-client-flag-cache-and-binary-overlay.md`。

## Notes / triage

- 落笔面四份：`systems/services/content-service.md`（flags 缓存段 · 增量下载段 · manifest 契约对位首句）· `systems/common-properties.md`（`Artwork` 的 overlay 一格）· `art/visuals/_index.md`（移出一条待决问题 + 条件化记录）· `decisions/ADR-0120-content-artwork-and-enemy-lines.md`（后果第 4 条）。
- **ADR 候选一条：「二进制资产不经 overlay / blob 通道下发；`Artwork` 的指向恒落在随包基线内」**，立档归 `/write-adr`；`decisions/_index.md` 本次未改动。
- `ADR-0120` 的七类挂载面 / 单格形态 / 可空语义 / 告警形态 / 占位回落**全部原样**，无一条被推翻。
- 对侧改动见 `counterpart`：`no-cache` 的层次澄清 · 后端对客户端缓存的零义务 · B 组第 7 条的依赖登记 · blob 通道不承载二进制的能力中立声明 · `ADR-0002` 后果段的措辞纠正。

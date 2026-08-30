# ADR-0125 — 二进制资产不经 overlay / blob 通道下发

- **状态：** Accepted
- **日期：** 2026-08-30
- **来源：** handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md

## 背景

「二进制资产能否经 overlay / blob 通道下发」是一处**两侧都以为归对方**的跨边界空档：客户端库与后端库都没有承接项。它压在一条刚 Accepted 的 ADR 的承重形态上——`decisions/ADR-0120-content-artwork-and-enemy-lines.md` 把 `Artwork` 定为直接资源引用，而 overlay 若要下发裸贴图，这条形态当场失效。同时 `systems/common-properties.md` 的 overlay 一行一直悬置未收口。

## 决策

**二进制资产本身不经 overlay / blob 通道下发；换图 / 加图随版本发布。** overlay 覆盖一条 `.tres` 时，**本节的全部资产引用格**随之被覆盖，但**指向必须落在随包基线内已存在的资产**——overlay 能做的只有改指到另一张已随包的资产，或置空（→ ViewModel 占位回落）。该收口句覆盖本节全部资产引用格，不止 `Artwork` 一格（同批落下的稀疏境界覆写同样适用）。

配套两道处置，防止实现期一次误配置把二进制推到设备上：**打包工具硬闸**（`files[]` 出现非 `.tres` → 不产出包，运维形态归后端）+ **客户端兜底**（跳过该文件、`LoadAll()` 后汇总一行 `PushWarning`）。**不新增 manifest 字段、不提升 `manifestSchema` 支持集合、不新增第三处硬阻塞。**

报文侧对位（blob 通道的能力对文件类别中立，限制来自字段形态而非契约）见 `backend-design-documents/contracts/content-manifest.md`。

## 理由

四条各自足以否掉，合起来是连锁的（逐条见 `systems/common-properties.md` 的 overlay 一行与 `systems/services/content-service.md`）：

1. **撞 `ADR-0120` 的承重形态。** `Artwork` 是直接资源引用、在 `.tres` 里落为 `ExtResource`；落在 `user://overlay/` 的裸资产不是导入产物。要让它被条目引用，只能退回该 ADR 已逐条否决的路径字符串 + 运行时加载，并自写一套悬空校验与解码失败处置。
2. **overlay 的收益边界里没有它。** overlay 的既定收益是平衡数值 / 事件定义 / 卡牌数值可热更而不发版，且它只改不增。改一张既有条目的插画是纯视觉修订，不是线上事故的止血手段——止血手段是 flags 秒关，分钟级。
3. **连锁推翻「不做字节级断点续传」。** 那条否决的前提被写明为「`.tres` 是 KB 级」。贴图是 MB 级，弱网下失败重下整份的代价与成功率都会翻过来。**这是四条里最硬的一条，因为它指名了既有判据的前提。**
4. **排期上不需要。** 美术是路线末段、挂点先占位、末段替换（`decisions/ADR-0006-development-phase-order.md`），资产替换与发版天然同节奏。

客户端兜底取「跳过」而非「拒绝整批」：拒绝整批 = 一次误配置停摆全体玩家的内容更新，而跳过不破坏文件级事务的任何性质。

## 备选方案

- **开放二进制经 overlay / blob 下发（换图 / 加图不发版）** — 否决理由即上列四条；`ADR-0120` 的引用形态须成对推翻。
- **保持悬置不收口** — 这正是两侧都以为归对方的那个空档本身；悬置一行会在第一批 `.tres` 写下时变成既成事实。

## 后果

- **契约报文零改动**；`ADR-0120` 的七类挂载面 / 单格形态 / 可空语义 / 告警形态 / 占位回落全部原样，无一条被推翻。
- 该结论**可撤销但成本明写**：`art/visuals/_index.md` 留下代价清单——成对改动 `ADR-0120` 的引用形态 + 重开字节级断点续传评估 + 对侧契约三点核对。**纯加法窗口在第一批 `.tres` 写下时关闭。** 这条记录的作用是让日后的复议知道自己在动什么，不是暗示它随时可做。
- 因此必须这么写的文档：`systems/common-properties.md`（overlay 一行的收口）· `systems/services/content-service.md`（增量下载段与 manifest 契约对位首句）· `art/visuals/_index.md`（移出该条待决 + 条件化记录）· `decisions/ADR-0120-content-artwork-and-enemy-lines.md`（后果第 4 条）。
- 对侧承接见 `backend-design-documents/handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md`：blob 通道不承载二进制的能力中立声明 · 后端对客户端缓存零义务。

# 剧本内容形态的后端承接：flags 对 arc 生效 · 发布侧的内容校验闸

- id: 2026-08-16d-plot-content-shape-adoption
- date: 2026-08-16
- topic: contracts/content-manifest.md · open-questions/04-content-delivery.md
- status: distilled
- distilled-to: `contracts/content-manifest.md`（「剧本文本」一节）、`open-questions/04-content-delivery.md`

## Intent（distilled）

客户端把剧本内容的数据形态收口为两个内容类型（`PlotArcData` = 剧本线的头，`PlotNodeData` = 树上的一个节点），权威在 `game-design-documents/systems/services/plot-manager.md`。**本库只承接边界两侧真正相关的两半**，不复述客户端的类型定义与校验规则。

### 1. flags 通道对剧本条目的作用面按 arc / node 分野（契约描述须改）

本库原写「flags 通道对剧本条目无作用点——剧本条目不进任何抽取池」。该判断建立在「剧本条目只由 key point 定位读取」这一未细分的前提上；客户端把剧本切成 arc（**被激活抽取** ⇒ 产出侧）与 node（**查表定位** ⇒ 结构性读取）之后，该前提对 arc 不再成立。

改写为：**arc 的 `Id` 进 `disabledIds` 生效**（使其不再被新激活；已在 key point 里的照常解析，不会悬空），**node 的 `Id` 进 `disabledIds` 无效且危险**（客户端直接 `PushError`）。**服务端仍不感知这一分野**——`disabledIds` 只是一串 `Id`，语义与准入由客户端裁决，报文层零改动、无新增字段。

**运营后果的措辞随之精确化：** flags 能做的是**停止新激活**（分钟级），不是撤回；**撤回一整段已发布剧情仍只能靠发布更大的 `contentVersion`**（冷启动级），即本库已定的「回滚即前滚」。

### 2. 发布侧的内容校验闸（新增承接项，落 `04-content-delivery.md`）

客户端为 overlay 的「剧本例外」定了两条合并期闸（新增 `Id` 的宿主类型必须是剧本类型 · 新增剧本条目引用的非剧本 `Id` 必须来自基线），并明确这类纪律的客户端天花板只到「启动期大声失败」——检查对象是 `.tres` 的引用图，编译期手段够不着。等价的更强形态是**把同一份校验前移到发布侧：产包前跑一遍，不通过就不产出包**。

这落在本库，因为**执行时点在发布流程上**（推 blob → 推 manifest 之前），而本库已定「manifest 与它列出的全部文件在发布上是原子的」。待定的是它的运维形态：校验在哪一步跑、由谁触发、失败如何阻断发布、是否需要留痕。**校验逻辑本身归客户端**（复用其 `LoadAll()` 路径），本库不实现、不复述其规则。

## Open questions

- 发布侧校验闸的运维形态（见 `open-questions/04-content-delivery.md` 新增条目）：执行时点、触发方式、失败阻断形态、与签名步骤的先后。共同前置是 `06-platform-stack.md` 的托管与流水线选型。

## Notes / triage

- 对侧（客户端）handoff：`game-design-documents/handoffs/2026-08-16i-plot-data-encoding.md`。
- 本次不改动任何 schema、端点、错误码或签名形态；改的是「剧本文本」一节的两条推论表述，并新增一条运维待答项。

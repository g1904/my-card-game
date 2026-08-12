# Decisions (ADR) — Index（后端）

后端侧已定的设计决定。每个决定一个 ADR，顺序编号。后端开发尚未开始——**ADR 可自由编辑 / 重构**：要改一个决定，直接改这份 ADR，不必新开一个 ADR 去取代它（历史归 git）。

**编号与客户端库各自独立**：本库的 `ADR-0001` 与 `game-design-documents/decisions/ADR-0001` 无关。引用另一侧的 ADR 一律写全路径。

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| _(暂无)_ | | | |

<!-- Next ADR: ADR-0001. Copy _TEMPLATE.md. -->

## ADR 候选（已定案，待固化为 ADR 正文）

方向已由用户裁决，但尚未写成 ADR。写正文时从此处取 Context / Decision / Consequences 的来源。

| 候选 | 要点 | 来源 |
|---|---|---|
| 内容寻址 + `contentVersion` 严格单调递增（回滚即前滚） | blob URL 以 SHA-256 寻址、字节不可变、边缘可永久缓存；撤回坏 overlay 靠发布更大的 `contentVersion` 指回旧 blob，**不允许版本号回退**（否则客户端多一条降级分支，且破坏 `StartContentVersion` / `LastContentVersion` 的单调判据） | `handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md` · `contracts/content-manifest.md` |
| flags 第三层只覆盖 `ContentEnabled` | `ContentEnabled` 从 overlay 通道独立为第三层覆盖来源，可在轮回进行中热应用；**限定条款：只能覆盖这一个布尔，不得携带数值 / 文案 / 新 `Id`**——正是这条限制让「合并后强校验」「只改不增」「存档必可解析」三条纪律原样成立。带有对客户端存储模型的松动，值得固化其边界条款 | 同上 |
| 契约表达形式 = OpenAPI 3.1 单点，不共享 DTO 代码 | 契约以文档级 **OpenAPI 3.1 + JSON Schema** 单点定义，两侧各自持有自己的 DTO；**即使后端最终也选 C# 也不共享 DTO 代码**。依据不在技术栈选型而在根约定的分支线独立性：共享 DTO 需要一个被两条独立分支线同时引用的编译期依赖，它要么住在某一条分支里（当场违反「后端不得被编译进游戏程序集」），要么需要第三个发布物，其版本节奏要同时迁就 Godot 4.7 的 .NET 目标框架与后端运行时。**值得固化**——否则「后端也用 C# 了，不如共享 DTO」会反复被重新提出 | `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md` · `contracts/envelope.md` |

## 已对后端构成约束的客户端决定

后端尚未产出自己的 ADR，但下列客户端侧决定已经限定了后端的设计空间：

| 客户端 ADR | 对后端的约束 |
|---|---|
| `game-design-documents/decisions/ADR-0003-online-cloud-authority.md` | 强制在线 · 云端权威 · 重账号（已删游客态）。后端必须承载账号、权威存档与冲突裁决。 |
| `game-design-documents/decisions/ADR-0004-realm-checkpoint-retry-model.md` | 境界存档 · 篇章重试模型 ⇒ 自动存档点频率与上行节奏的下界。 |
| 剧本内容属客户端本地内容层（**客户端侧 ADR 候选**，见 `game-design-documents/handoffs/2026-08-11-plot-content-localization.md`） | **撤销一整条边界**：后端无剧本服务、无剧本契约、无 `/v1/plot/…` 端点；剧本文本改由 `content-manifest.md` 通道以普通内容文件承接。跨边界的客户端成分由四降为三。本库侧落地见 `handoffs/2026-08-11-plot-service-retired.md`。 |

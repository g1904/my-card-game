# ⑤ 服务契约 / 工程侧残留（焦点，但均为下一层细节）

> 本分片属 `../open-questions.md` 的当前焦点区。
>
> 「七个服务的 API 面未定义」已答结（八条契约总则、共享核心类型、逐服务签名骨架、EventBus 负载 schema 均已定案，权威在 `systems/architecture.md`「API 契约总则」；移出记录见 `../answer-logs/log-service-api-contracts.md`）。

- **`[Export] bool UseOfflineBackend` 的发布期防护。** 四个边界服务的离线 stub 开关默认 `true` 直到后端上线；正式包如何保证它不为 `true`（导出预设 / 编译期 `#if` / 启动期断言）未定——**这是一个能悄无声息发到线上的开关**。→ `system-overview.md`。
- **`OpError` → 玩家文案的映射归属。** 这份映射表由谁持有（UI 层常量？本地化表？服务返回已本地化串？）。→ `ux/`。
- **EventBus 退订纪律的可执行性。** 「`_Ready` 订阅 / `_ExitTree` 退订」是约定；漏退订即泄漏且在 C# 事件上不报错。是否需要 EventBus 侧的调试期订阅计数 / 泄漏检查？→ `systems/architecture.md`。
- **`AllEnabled()` 纪律的可执行性。** 约定已立（抽取必走 `AllEnabled()`），但如何在代码评审之外强制未定：`All()` 是否应改名为 `AllIncludingDisabled()` 让默认路径就是安全路径？还是靠 Roslyn 分析器 / 评审清单？→ `systems/services/content-service.md`。
- **`manifestSchema` 的版本化。** 它触发整包全量重下，但自身版本号形态、与 `contentVersion` / `appVersion` 的关系未定。→ 同上。
- **`revision` 的产生方与语义。** 断线合并依赖比较云端与本地基线的 `revision`（单调递增计数？服务端时间戳？ETag？），由谁分配、客户端如何持有基线值未定——属**客户端 ↔ 后端协议契约**，应同步登记进 `backend-design-documents/open-questions.md`。→ `systems/services/sync-service.md`。
- **软阻塞与「进入战斗前强制 flush」的交互。** 进入战斗前是 Immediate flush 点；若此时已处于断线缓冲超限态，玩家是被挡在战斗外（软阻塞发生在 AdventureEvent 选择前）还是可以进入？两条规则的先后顺序未明写。→ 同上。
- **`.claude/rules/*` 中夹带的设计性表述如何处理。** 主从关系已定（`.claude` = 工程层，见 ADR-0005）；但现存规则文件里确实嵌着设计结论（`state-save-rules.md` 的确定性边界、`data-resource-rules.md` 的 `AllEnabled()` 语义）。这些是「一句话承重纪律 + 回链」的合法形态，还是应进一步瘦身？→ `systems/common-properties.md`。
- **`/breakdown-requirements` 的两项形态确认（07-30 新增）：** ① **子需求是否需要用户逐个签核**——当前技能取「**父 FR 签核即覆盖其子需求**」、子需求直接产出为 `ready`，需确认符合意图；② **拆解粒度判据**——当前定为「一次 `/blueprint` 能一口吃下的薄纵切片，1~5 条验收标准，且可在 Godot 中跑出来」，粒度上下界（最多改几个文件 / 是否允许纯数据资源型子需求）仍偏经验。→ `requirements/_index.md`。
- **共有属性提炼粒度。** 哪些字段应下沉到子树各自的 `common-properties.md`、哪些留在顶层。→ `systems/common-properties.md`。

# ⑤ 服务契约 / 工程侧残留（焦点，但均为下一层细节）

> 本分片属 `../open-questions.md` 的当前焦点区。
>
> 「七个服务的 API 面未定义」已答结（八条契约总则、共享核心类型、逐服务签名骨架、EventBus 负载 schema 均已定案，权威在 `systems/architecture.md`「API 契约总则」；移出记录见 `../answer-logs/log-service-api-contracts.md`）。
>
> `revision` 的产生方与语义、软阻塞 × 进战斗前 flush 两条已于 08-09 答结（权威在 `systems/services/sync-service.md`；移出记录见 `../answer-logs/log-sync-revision-and-soft-block.md`）。
>
> **三条「靠约定执行」的工程纪律**（离线开关发布期防护 / EventBus 退订可执行性 / `AllEnabled()` 可执行性）已于 08-09 一次答结——统一判据「纪律的可执行化」四级阶梯落在 `systems/architecture.md`，三处形态分别落在 `system-overview.md` 第四节、总则 5、`systems/services/content-service.md`；移出记录见 `../answer-logs/log-discipline-enforceability.md`。

- **`OpError` → 玩家文案的映射归属。** 这份映射表由谁持有（UI 层常量？本地化表？服务返回已本地化串？）。→ `ux/`。
- **`#if DEBUG` 判据的实测确认（08-09 新增）。** 离线后端「Release 构建里根本不存在」这一主闸依赖「Godot 的 .NET 集成在 Release 导出配置下不定义 `DEBUG`」。`game-feature-branch/` 当前**尚无 `.csproj`**，无从验证；**首次生成 `.csproj` 后需实测一次**。若不成立，改用显式 `<DefineConstants>MYCARDGAME_OFFLINE_OK</DefineConstants>`，方案形态不变。→ `system-overview.md`。
- **`manifestSchema` 的版本化。** 它触发整包全量重下，但自身版本号形态、与 `contentVersion` / `appVersion` 的关系未定。→ 同上。
- **`pushId` 的后端记忆窗口与报文字段名。** 客户端侧语义已定（幂等键随待发队列持久化、跨启动重试不变）；**记多少个 / 保留多久属后端侧**，字段名与序列化形态待后端协议表达形式定案。→ `backend-design-documents/open-questions.md`。
- **`.claude/rules/*` 中夹带的设计性表述如何处理。** 主从关系已定（`.claude` = 工程层，见 ADR-0005）；但现存规则文件里确实嵌着设计结论（`state-save-rules.md` 的确定性边界、`data-resource-rules.md` 的 `AllEnabled()` 语义）。这些是「一句话承重纪律 + 回链」的合法形态，还是应进一步瘦身？→ `systems/common-properties.md`。
- **`/breakdown-requirements` 的两项形态确认（07-30 新增）：** ① **子需求是否需要用户逐个签核**——当前技能取「**父 FR 签核即覆盖其子需求**」、子需求直接产出为 `ready`，需确认符合意图；② **拆解粒度判据**——当前定为「一次 `/blueprint` 能一口吃下的薄纵切片，1~5 条验收标准，且可在 Godot 中跑出来」，粒度上下界（最多改几个文件 / 是否允许纯数据资源型子需求）仍偏经验。→ `requirements/_index.md`。
- **共有属性提炼粒度。** 哪些字段应下沉到子树各自的 `common-properties.md`、哪些留在顶层。→ `systems/common-properties.md`。

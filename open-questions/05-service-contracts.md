# ⑤ 服务契约 / 工程侧残留（焦点，但均为下一层细节）

> 本分片属 `../open-questions.md` 的当前焦点区。
>
> 「七个服务的 API 面未定义」已答结（八条契约总则、共享核心类型、逐服务签名骨架、EventBus 负载 schema 均已定案，权威在 `systems/architecture.md`「API 契约总则」；移出记录见 `../answer-logs/log-service-api-contracts.md`）。
>
> `revision` 的产生方与语义、软阻塞 × 进战斗前 flush 两条已于 08-09 答结（权威在 `systems/services/sync-service.md`；移出记录见 `../answer-logs/log-sync-revision-and-soft-block.md`）。
>
> **契约边界层的客户端侧承接**（`pushId` 的报文字段名与序列化形态 · `manifestSchema` 的版本化）已于 08-11b 答结（表达形式 = OpenAPI 3.1 单点、两侧各持 DTO；`manifestSchema` 三版本号分工 + 不受支持则跳过。权威在 `systems/services/content-service.md` 与 `systems/architecture.md` 总则 7；移出记录见 `../answer-logs/log-0811_2.md`）。
>
> **玩家文案的映射归属**与**三条「去更新」提示的呈现与去重**（含强更硬阻塞屏形态）已于 08-12 答结：文案归 UI 层、键 = 后端 `code`、载体 = 翻译键（`code → ERR_*` 为机械变换，无第二张对照表）；三条提示 = 同一根轴上的三档，**同一时刻只呈现最高一档**；三种终局态收敛为**一个阻塞屏 + 变体表**（阻塞点仍只有两处）。权威在 `ux/error-and-blocking-ux.md`；移出记录见 `../answer-logs/log-error-copy-and-update-prompts.md`。
>
> **三条「靠约定执行」的工程纪律**（离线开关发布期防护 / EventBus 退订可执行性 / `AllEnabled()` 可执行性）已于 08-09 一次答结——统一判据「纪律的可执行化」四级阶梯落在 `systems/architecture.md`，三处形态分别落在 `system-overview.md` 第四节、总则 5、`systems/services/content-service.md`；移出记录见 `../answer-logs/log-discipline-enforceability.md`。

- **翻译键的铺开节奏（08-12 新增）。** 「全库 UI 文案统一走 `TranslationServer` 翻译键」已定，`res://text/errors.csv` 是第一批；**逐屏改造如何排期**（随各屏 FR 一并落地？集中做一次？）、以及**是否需要一条集中的键命名规范**（`ERR_*` 之外的前缀分区）未定。→ `ux/error-and-blocking-ux.md`。
  - **邻域（08-12d 标注）：内容条目自己的多语言表达形态。** UI 文案 ↔ 内容文案的边界已于 08-12d 澄清并落 `ux/_index.md`（**四问判据**，两条纪律作用于不同文本层、不冲突）；但**内容条目**（卡面描述、事件正文、跨档叙事、Finale 补白）出英文版时走的是**内容条目内的多语言表达**，不是 `res://text/` 翻译表——**这一层尚无定案**。→ `systems/services/content-service.md`。
- **`#if DEBUG` 判据的实测确认（08-09 新增）。** 离线后端「Release 构建里根本不存在」这一主闸依赖「Godot 的 .NET 集成在 Release 导出配置下不定义 `DEBUG`」。`game-feature-branch/` 当前**尚无 `.csproj`**，无从验证；**首次生成 `.csproj` 后需实测一次**。若不成立，改用显式 `<DefineConstants>MYCARDGAME_OFFLINE_OK</DefineConstants>`，方案形态不变。→ `system-overview.md`。
- **`.claude/rules/*` 中夹带的设计性表述如何处理。** 主从关系已定（`.claude` = 工程层，见 ADR-0005）；但现存规则文件里确实嵌着设计结论（`state-save-rules.md` 的确定性边界、`data-resource-rules.md` 的 `AllEnabled()` 语义）。这些是「一句话承重纪律 + 回链」的合法形态，还是应进一步瘦身？→ `systems/common-properties.md`。
- **`/breakdown-requirements` 的两项形态确认（07-30 新增）：** ① **子需求是否需要用户逐个签核**——当前技能取「**父 FR 签核即覆盖其子需求**」、子需求直接产出为 `ready`，需确认符合意图；② **拆解粒度判据**——当前定为「一次 `/blueprint` 能一口吃下的薄纵切片，1~5 条验收标准，且可在 Godot 中跑出来」，粒度上下界（最多改几个文件 / 是否允许纯数据资源型子需求）仍偏经验。→ `requirements/_index.md`。
- **⚠ `Source` 在上行负载里的序列化形态（08-12b 新增 · 承重 · 收口归后端库）。** 客户端 08-10b 定「**code = 显式稳定整数，是存档 / 上行负载里实际序列化的东西**」；`backend-design-documents/contracts/envelope.md`（08-11 成文，晚于 08-10b）定「**枚举值一律字符串，取值与客户端 C# 枚举名逐字相同**」（理由：同名可省掉一整张最易写漏的映射表）。**两条都明写覆盖「上行负载」，不能同时成立。** 倾向收口：**契约侧走字符串名 · 存档侧走整数 code · 客户端在序列化边界做一次映射**（通则不开例外），若如此则须补一条「**成员名与 code 双双冻结、永不复用**」，并改写 `systems/common-properties.md` 那句表述。**不阻塞 `Source` 扩清单落地**——只决定线上表示形态。裁决在 `backend-design-documents/handoffs/2026-08-12-grant-source-code-contract.md`。→ `systems/common-properties.md`、`backend-design-documents/contracts/envelope.md`。
- **共有属性提炼粒度。** 哪些字段应下沉到子树各自的 `common-properties.md`、哪些留在顶层。→ `systems/common-properties.md`。

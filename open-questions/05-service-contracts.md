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
> **翻译键的铺开节奏**与其邻域小项**内容条目自己的多语言表达形态**已于 08-13 一次答结：**没有改造期，只有一条起手纪律**（存量为零 ⇒ 每屏从第一行起就用键）+ 集中基建 `FR-ux-translation-foundation` + 键命名规范三条 + 分区表十项 + `ERR_` 禁令；内容侧走**条目内嵌 `LocalizedText`**（locale 封闭二值、overlay 可热更、缺 `en` 键即未翻译）。权威在 `ux/error-and-blocking-ux.md`、`systems/common-properties.md`、`systems/services/content-service.md`；移出记录见 `../answer-logs/log-translation-key-rollout-and-content-localization.md`。
>
> **共有属性提炼粒度**已于 08-14 答结：要定的不是一张字段归属表而是一条判据——**定义在最小公共祖先、投影在各落点**（投影只写落点 / 本层合法子集 / 本层消费点 / 回链，不得复述定义）；上移需语义同一、下沉后顶层不留摘要；某层是否建 `common-properties.md` **按内容建不按对称建**。权威在 `systems/common-properties.md` 的 `## 内容共有字段` 判据卡与 `systems/_index.md` 收尾约定；移出记录见 `../answer-logs/log-common-properties-layering.md`。
>
> **`.claude/rules/*` 中夹带的设计性表述如何处理**已于 08-14b 答结：形态合法、**不**瘦身到纯链接（依据 = knowledge 主动读 vs rules 前置注入的加载模型差异），改为补上量化阈值（投影四件套 + 七条硬边界 + 三条机械规则）与执行者（扩 `/sync-knowledge` 的对账范围到 `rules/`）。权威在 `decisions/ADR-0005` 的「### 2. 规则层的具体形态」，`systems/common-properties.md` 只留一段投影；移出记录见 `../answer-logs/log-claude-rules-design-content-thinning.md`。
>
> **`Source` 在上行负载里的序列化形态**已于 08-16 答结：契约侧走字符串成员名 · 存档侧走整数 code · 客户端在 `sync-service` 组装上行负载时做一次映射，并补上「名与 code 双双冻结、永不复用」纪律。权威在 `systems/common-properties.md` 与 `backend-design-documents/contracts/profile-sync.md` §5a；移出记录见 `../answer-logs/log-cross-library-alignment.md`。
>
> **三条「靠约定执行」的工程纪律**（离线开关发布期防护 / EventBus 退订可执行性 / `AllEnabled()` 可执行性）已于 08-09 一次答结——统一判据「纪律的可执行化」四级阶梯落在 `systems/architecture.md`，三处形态分别落在 `system-overview.md` 第四节、总则 5、`systems/services/content-service.md`；移出记录见 `../answer-logs/log-discipline-enforceability.md`。

- **上行整键回声校验的适用面未穷举（08-19 新增 · 承重）。** `entitlement` 已定：上行时 `bundleGrantOrdinal` 须与后端下发值逐位相同，否则整批拒绝并风控。但 `accountInfo` 是**同形的第二处**（后端写三项、客户端只写 `nickname`，同样整键替换上行）⇒ 「哪些顶层键的哪些路径受回声校验约束」缺一份封闭清单，逐键临时判会漏。→ `systems/services/sync-service.md`、`backend-design-documents/contracts/profile-sync.md`。
- **做一次 `architecture.md ↔ services/*` 的待决问题与投影表对账（08-19 新增 · 轻）。** 已有两个实例证明上游会留下过期登记：`architecture.md` 三条结构残留里有两条的答案早已写死在下游服务文档、只是从没回头划掉；`ResourceElements` 表在 `architecture.md` 与 `profile-service.md` 之间也出现过投影漂移。需要一次系统性对账而非逐次顺手修。→ `systems/architecture.md`。
- **refresh token 的客户端持有形态未落笔（本次归集 · 此前未进清单）。** 后端已定「不进 `Session`、落 `user://cache/`」；客户端侧的**具体文件与失效路径**未定。**一条硬约束已成立：不得与 `user://cache/device-id.json` 合进同一文件**——refresh token 是鉴权材料、**必须**在切账号 / 登出时失效，而设备标识**必须**切账号不变；同处一份文件会逼出一条「清一半留一半」的写入路径，正是最容易写错、错了以后症状指向不明的形态。落点形态（`user://cache/` 下的单字段 json · 原子写 · 跨启动保留）可直接复用 `deviceId` 那一节。→ `systems/services/account-service.md`。
- **flags 拉取的频次护栏（本次归集 · 此前未进清单 · 轻）。** `X-Flags-Version` 每次应答都带；服务端版本在短时间内连续抖动时，客户端是否需要一个最小拉取间隔，或只在版本**增大**时拉。→ `systems/services/content-service.md`。
- **`#if DEBUG` 判据的实测确认（08-09 新增）。** 离线后端「Release 构建里根本不存在」这一主闸依赖「Godot 的 .NET 集成在 Release 导出配置下不定义 `DEBUG`」。`game-feature-branch/` 当前**尚无 `.csproj`**，无从验证；**首次生成 `.csproj` 后需实测一次**。若不成立，改用显式 `<DefineConstants>MYCARDGAME_OFFLINE_OK</DefineConstants>`，方案形态不变。→ `system-overview.md`。
  - **同批实测（08-13 新增）：Godot 4.7 上 `Control` 自动翻译（`auto_translate_mode`）的默认行为。** 若默认即生效，`.tscn` 里把 `text` 直接写成键就够了、UI 代码里连 `tr()` 都不必出现；否则显式 `tr()`。**两种情况下键的形态、分区表、三条审计完全相同**，故不阻塞任何已定案内容——纯属落地写法确认，宜与上一条合并到同一次 `.csproj` 生成后的实测。→ `ux/error-and-blocking-ux.md`。
- **第四 / 第五级层级词（processor / handler）是否过早（08-15d 体检登记 · 轻）。** 两级均明确「暂不落实例，保持空是健康的」，判据先于实例而定。既有辩护（「先有判据、后有实例」比反过来安全）成立，故本条只作登记：**首次真要拆一个 processor 时，回头验证那三条与门判据是否还适用**，而不是照着填。→ `systems/architecture.md`。

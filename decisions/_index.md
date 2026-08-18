# Decisions (ADR) — Index（后端）

后端侧已定的设计决定。每个决定一个 ADR，顺序编号。后端开发尚未开始——**ADR 可自由编辑 / 重构**：要改一个决定，直接改这份 ADR，不必新开一个 ADR 去取代它（历史归 git）。

**编号与客户端库各自独立**：本库的 `ADR-0001` 与 `game-design-documents/decisions/ADR-0001` 无关。引用另一侧的 ADR 一律写全路径。

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| _(暂无)_ | | | |

<!-- Next ADR: ADR-0001. Copy _TEMPLATE.md. -->

## ADR 候选（待固化为 ADR 正文）

方向已由用户裁决，但尚未写成 ADR。写正文时从此处取 Context / Decision / Consequences 的来源。

| 候选 | 要点 | 来源 |
|---|---|---|
| 内容寻址 + `contentVersion` 严格单调递增（回滚即前滚） | blob URL 以 SHA-256 寻址、字节不可变、边缘可永久缓存；撤回坏 overlay 靠发布更大的 `contentVersion` 指回旧 blob，**不允许版本号回退**（否则客户端多一条降级分支，且破坏 `StartContentVersion` / `LastContentVersion` 的单调判据） | `handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md` · `contracts/content-manifest.md` |
| flags 第三层只覆盖 `ContentEnabled` | `ContentEnabled` 从 overlay 通道独立为第三层覆盖来源，可在轮回进行中热应用；**限定条款：只能覆盖这一个布尔，不得携带数值 / 文案 / 新 `Id`**——正是这条限制让「合并后强校验」「只改不增」「存档必可解析」三条纪律原样成立。带有对客户端存储模型的松动，值得固化其边界条款 | 同上 |
| 契约表达形式 = OpenAPI 3.1 单点，不共享 DTO 代码 | 契约以文档级 **OpenAPI 3.1 + JSON Schema** 单点定义，两侧各自持有自己的 DTO；**即使后端最终也选 C# 也不共享 DTO 代码**。依据不在技术栈选型而在根约定的分支线独立性：共享 DTO 需要一个被两条独立分支线同时引用的编译期依赖，它要么住在某一条分支里（当场违反「后端不得被编译进游戏程序集」），要么需要第三个发布物，其版本节奏要同时迁就 Godot 4.7 的 .NET 目标框架与后端运行时。**值得固化**——否则「后端也用 C# 了，不如共享 DTO」会反复被重新提出 | `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md` · `contracts/envelope.md` |
| 防作弊边界 = 可复算 `roll`、不可复算阈值；不一致仅记账不拒绝 | 「后端可离线复算」拆开是两件事：算 `roll` **能且必须能**（纯函数，输入全在透明子集里）；判定**是否命中不能可靠地做**——生效概率取决于按 `(x, chapter)` 分档、随 overlay 热更且**不冻结 `contentVersion`** 的平衡表，把它复制到后端即第二份真值 + 必然漂移，与 pillar #1 / #5 同时相悖。复算不一致**接受写入 + 上报风控**，不拒绝（一次误报 = 一次玩家进度丢失）、不改写（会让两侧 Profile 在客户端不知情时分叉）。**值得固化**——它是 pillar #1 在最具体处的兑现，也是「后端要不要持有平衡表」这个问题的永久答案 | `handoffs/2026-08-14-profile-sync-contract.md` · `contracts/profile-sync.md` §7 §7a |
| 账号级掷骰的随机源 = 契约定义的纯函数 SplitMix64 | 账号级掷骰**不走 Godot `RandomNumberGenerator`**：跨语言逐位一致是复算成立的**前提**，押在引擎实现细节上等于让「Godot 升级」成为一次静默的作弊窗口（客户端自己已为 `RandomNumberGenerator.State` 写过同一条警告）。算法、常量、三参数混入顺序、`+1` 全零防御、`mod 10000` 不做拒绝采样**全部是契约的一部分**，`stream` 取值随 `AccountStream` 成员序冻结，**测试向量表是唯一可执行的检查点**。**轮回级 RNG 完全不受影响**。**值得固化**——否则「客户端本来就有 RNG，为什么另写一个」会反复被重新提出 | `handoffs/2026-08-14-profile-sync-contract.md` · `contracts/profile-sync.md` §6 |
| 购买写入只由 verify 端点承担，渠道回调降为对账通道 | 付费权益的推进（`bundleGrantOrdinal += 1`）**只由客户端触发的验票端点写入**，平台 / 渠道回调**只作对账与补偿发现**，不作写入路径。依据：回调时序不可控（可能早于、晚于、或永不到达客户端的 verify），作为写入路径会让「玩家已付款但序号未涨」无处排查，且要额外处理回调与 verify 的竞态——而那条竞态的收益仅在「客户端崩溃且从不回来」这一场景。**同时固化的连带条款**：幂等键取平台收据 id、重复提交绝不重复 `+1`、序号与 `revision` 同事务自增、verify 不走 CAS 且应答不内联 profile。**值得固化**——否则「用回调直接写库省一次往返」会反复被重新提出 | `handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md` · `contracts/purchase.md` |
| auth 域的幂等 = sync 域的幂等（同一条 pillar #2 的两次兑现） | `POST /v1/auth/refresh` 采用 refresh token rotation，但**必须带 60 秒宽限窗口**：窗口内旧 token 回放**与上次相同的那一对新 token**、不再轮换、不判泄漏，窗口外才判泄漏并吊销全账号会话。它与 `pushId` 的「重复到达不再 `+1`，直接回上次结果」是**同一个模式、理由同源**——「请求已达、应答丢失」是移动网络常态。**值得固化**——否则「rotation 是标准做法，为什么要开宽限口子」会反复被重新提出，而裸 rotation 会把一次弱网变成一次轮回中途的硬踢下线 | `handoffs/2026-08-13-auth-endpoint-contract.md` · `contracts/auth.md` |

## 已对后端构成约束的客户端决定

后端尚未产出自己的 ADR，但下列客户端侧决定已经限定了后端的设计空间：

| 客户端 ADR | 对后端的约束 |
|---|---|
| `game-design-documents/decisions/ADR-0003-online-cloud-authority.md` | 强制在线 · 云端权威 · 重账号（已删游客态）。后端必须承载账号、权威存档与冲突裁决。 |
| `game-design-documents/decisions/ADR-0004-realm-checkpoint-retry-model.md` | 境界存档 · 篇章重试模型 ⇒ 自动存档点频率与上行节奏的下界。 |
| 剧本内容属客户端本地内容层（**客户端侧 ADR 候选**，见 `game-design-documents/handoffs/2026-08-11-plot-content-localization.md`） | **撤销一整条边界**：后端无剧本服务、无剧本契约、无 `/v1/plot/…` 端点；剧本文本改由 `content-manifest.md` 通道以普通内容文件承接。跨边界的客户端成分共三个。本库侧落地见 `handoffs/2026-08-11-plot-service-retired.md`。 |

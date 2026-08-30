# 跨边界承接（对侧已定案、本库尚未落笔）

> 本分片属 `../open-questions.md`，但它跟踪的**不是待答问题**。
>
> **与普通分片的关键区别，必须先读：普通待答项等的是「设计裁决」，本分片的条目等的只是「落笔」——答案在对侧库里已经写好了。**
> 混进普通分片会让它们和真正的开放问题一起被无限期搁置，而这正是 2026-08 上半月发生过的事：
> 后端 08-14 的契约把七点客户端欠账逐条列在了它的 handoff 里，两周后一点未落——**因为一次性文档不是台账，没有任何东西会再读它**。
>
> **每条的固定形态：** `对侧权威文档路径#小节 | 对侧定案日期 | 本库需改的文档 | 一句话摘要`。
> **只写回链与摘要，绝不复述对侧的设计内容**——复述即制造第二权威，两份各自漂移而本库无机制发现。
>
> **关闭条件：** 本库落笔完成（对应 handoff `distilled`）后从本分片移除，记进 `../answer-logs/`。
> 两侧的条目**各自独立关闭**，不要求同时。
>
> **谁维护：** `/analyze-new-ideas` 跨库落笔时同批写两侧（主库写决策、对侧库立承接项）·
> `/summarize-open-questions` 对账时发现「一侧已定案、另一侧零承载」即补登 ·
> `/assess-derive-readiness` 只报告缺口、不写对侧。

## 待承接

- `backend-design-documents/contracts/compliance.md` | 2026-08-16 | 本库需改：`systems/services/account-service.md` | **合规拦截的落地点与四条码已定**，`ComplianceManager` 的覆盖面切分（哪些拦截由它呈现、哪些落在登录屏本身）可裁决。切分本身仍是本库自己的取向，对侧不代为决定。

## 对账基线（不是待办）

- **两条跨边界空档（flags 是否落客户端本地缓存 · 二进制资产能否经 overlay / blob 通道下发）已于 2026-08-30 成对落笔关闭。** 本库落 `systems/services/content-service.md` 的 flags 落盘纪律（`schemaVersion` · 写入时点 · 三条失效语义 · 不设 TTL）与非 `.tres` 的两道处置、`systems/common-properties.md` 的资产引用格 overlay 收口；对侧落 `no-cache` 的层次澄清、后端零义务表、B 组第 7 条依赖登记与 blob 通道的能力中立声明，见 `backend-design-documents/handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md`。**两侧无遗留欠账。** 移出记录见 `../answer-logs/log-client-flag-cache-and-binary-overlay.md`。
- **后端契约面五份全部成文**，客户端侧的对位落笔已于 2026-08-16 同批完成：`Source` 上行走成员名的边界映射 · `profile-sync` 的两个新字段与写入约定 · `accountSeed` 的 hex 序列化 · 透明路径稳定性纪律 · 随机源换 SplitMix64 · diff 与顶层键浅合并对齐 · `bundleGrantOrdinal` 的 JSON path 与购买契约回链。移出记录见 `../answer-logs/log-cross-library-alignment.md`。
- **预警（尚未成为承接项）：`characterProfile` 的资源字段一旦提进透明档，必须同批把钳制语义写进契约。** 当前 `backend-design-documents/contracts/profile-sync.md` §5 把 `characterDiffs` 整体划为不透明段（后端不递归、不比对、不校验），故客户端的截断语义对后端零可见。若日后把寿元 / 灵玉 / 耐久任一字段提进透明字段表，后端就会看到「`AppliedChange` 记未截断值、快照记截断值」这个差，复算会在正常账号上误报。**本条现在无需任何一侧动手**，只在提取字段时触发。**适用面已比登记时更宽**：`AppliedChange` 现在是「本次事件的最终账」（含事件内逐笔即时提交的 spec 累加），与收口那一次 `TryApply` 的入参不再逐字段相等——提取字段时要同批带过去的不止钳制语义，还有这条累加语义。本库权威：`systems/services/profile-service.md`、`systems/adventure-event/common-properties.md`。
- **账号身份模型两侧同批落笔**（2026-08-16）：后端定契约本体（`backend-design-documents/contracts/auth.md` 的身份模型与绑定 / 改名端点），本库同批落 `account-service` 的四个新方法、`AccountInfo` 的三个新字段与绑定 UX。**两侧无遗留欠账**；余下的 `deviceId` 落点与 refresh token 持有形态是本库自己的待决问题（登记在 `systems/services/account-service.md`），不是跨边界承接项。移出记录见 `../answer-logs/log-account-identity-model.md`。
- **refresh 失败的两条路径已承接**（对侧 `contracts/auth.md` §10 → 本库 2026-08-17 落笔）：`account-service.md` 的 token 处置段拆为「网络失败 → 缓冲通道」/「收到 `auth.session_revoked` → 硬阻塞重登 + 暂停退避」两行表，判据钉为**「收到了明确应答」而非「失败了」**；`architecture.md` 的 `Reauth` 默认路径行与 `sync-service.md` 的对应一句**同批同改**（三处此前都写着同一句会被实现成单路径的「刷新失败视同断线」）。移出记录见 `../answer-logs/log-0817.md`。
- **球在对侧的第二条：** 残卷 `ordinal` 的口径本库已明写为**本次（自增后）序号**（`systems/common-properties.md` 的账号级 RNG 通则 + `systems/services/life-cycle-service.md` 的显式先算后写）。对侧 `backend-design-documents/contracts/profile-sync.md` §7 ① 的复算输入与之一致，**两侧无需改动即认为已对齐**；后端侧同批留了一条确认性承接项与一处措辞消歧。本库不再跟踪，本条只作对账留痕。
- **两层 Profile 字段命名两侧同批落笔**（2026-08-17）：本库把集合字段名统一为单数并收口条目键名为 `powerId` / `itemId`，对侧同批改 `contracts/profile-sync.md` §5 白名单与排除清单四条路径并新增 §5b 命名通则。**两侧无遗留欠账。**
- **球在对侧的一条：** 购买域契约 `backend-design-documents/contracts/purchase.md` 已成文，其 `receipt` 字段的渠道形态与错误码映射待后端 `02` —— **本库不催办、不重复设计**，它出现在后端库自己的 `cross-boundary.md` 与 `01-contracts.md` 里。
- **08-22 产生的三条球在对侧，已于 2026-08-23 全部落笔，三处成对采纳均完成：** ① **回声校验通则的后端半** → `backend-design-documents/contracts/profile-sync.md` §5c（适用面恒等式 · 类型感知比较口径）；客户端半 08-22 已落，本次对侧零要求。② **flags 回滚即前滚的对位条款** → `backend-design-documents/contracts/content-manifest.md`「服务端保证」B 组；本库「增大即拉」所依赖的那一半到位，**既有规则一字未改**。③ **静默续期绕过强更闸门的收口** → `backend-design-documents/contracts/auth.md` §5b；本库同批落了对位的二级文案键与软信号反应形态（`ux/error-and-blocking-ux.md` · `systems/services/account-service.md`）。移出记录见 `../answer-logs/log-refresh-cap-and-flags-gate.md`。
- **对侧落笔时点出的一处本库缺口，已同批自行裁决**：flags 单调闸此前只挂在观测 `X-Flags-Version` 头处，**拉回批次 body 的 `flagsVersion` 也须过同一道闸**（> 内存值才应用，否则整批丢弃 + 告警 + 上报一次）。→ `systems/services/content-service.md`。对侧明写不代为改客户端规则，本条由本库裁决。

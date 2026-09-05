# 跨边界承接（客户端已定案、本库尚未落笔）

> 本分片属 `../open-questions.md`，但它跟踪的**不是待答问题**。
>
> **与普通分片的关键区别，必须先读：普通待答项等的是「设计裁决」，本分片的条目等的只是「落笔」——答案在客户端库里已经写好了。**
> 混进普通分片会让它们和真正的开放问题一起被无限期搁置——客户端 08-15b 定案的购买段在本库空悬了整整一周，即是一例。
>
> **每条的固定形态：** `客户端权威文档路径#小节 | 客户端定案日期 | 本库需改的文档 | 一句话摘要`。
> **只回链、不复述**——复述即制造第二权威。
>
> **一类常规触发源：** 对侧 `game-design-documents/systems/services/profile-schema-versions.md` 的 `schemaVersion` 登记表**新增一行**（= 一次 bump 定案）——本库须把该版本号登进 `operations/version-matrix.md` 的 `schemaVersion` 子表，条目照上述四段式。登记流程与责任人分段见 `../operations/_index.md`。
>
> **关闭条件：** 本库落笔完成（对应 handoff `distilled`）后从本分片移除，记进 `../answer-logs/`。两侧条目各自独立关闭。
>
> 机制的完整设计、病因诊断与维护者分工见客户端库同名分片 `game-design-documents/open-questions/cross-boundary.md`（两份不重复写）。

## 待承接

- `game-design-documents/ux/error-and-blocking-ux.md` · `game-design-documents/systems/services/account-service.md` | 2026-09-03 | 本库需改：`contracts/envelope.md` §6 | **四条 `compliance.*` 拦截码的「客户端处置」列改为回链客户端库。** 该列现写作「阻塞屏 + XX 动作」，而对侧已定四条拦截码一律在**登录屏就地呈现**、一条也不进阻塞屏变体表（呈现形态的裁决权在客户端库，本库不代为决定）。**语义不变，只消除措辞不一致**——照现列实现会造出第三处由 `code` 触发的硬阻塞。改法：该列写「呈现形态见 `game-design-documents/ux/error-and-blocking-ux.md`」。对侧 handoff：`game-design-documents/handoffs/2026-09-03-compliance-client-surface.md`。

## 对账基线（不是待办）

- **`contracts/content-manifest.md` 的两条 Open question（blob 是否向二进制资产开放 · flags 是否落地客户端本地缓存）已于 2026-08-30 成对落笔关闭。** 本库落 `no-cache` 的层次澄清（回链 `envelope.md` §3，不复制）、后端对客户端缓存的**零义务**、B 组第 7 条的依赖方登记与「blob 通道不承载二进制资产」一节；对侧落 flags 落盘纪律与资产引用格的 overlay 收口，见 `game-design-documents/handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md`。**报文零改动**（`flagsSchema` / `manifestSchema` 均不提升）。**两侧无遗留欠账。** 移出记录见 `../answer-logs/log-client-flag-cache-and-binary-overlay.md`。

- **Codex 顶层键的计数措辞已去计数化**（客户端 2026-08-25 图鉴族扩员 → 本库同批落笔）：`contracts/profile-sync.md` §5 排除清单由计数指代改为按 `*Codex` 顶层键后缀恒定覆盖全族，并回链客户端族清单权威（`game-design-documents/systems/player-profile/codex/_index.md`，**本库不复述**）。**契约报文形态一字未变，字段面零配合** —— 新顶层键落不透明段 ⇒ 不进白名单 ⇒ 按 §5c 适用面恒等式结构性地不受回声校验约束，且 §5c 无需加行。`schemaVersion` bump 的新值须进 `envelope.md` §7e 兼容矩阵，属**每次 bump 均有的既有机械义务**（矩阵已建立于 `operations/version-matrix.md`，登记流程见 `operations/_index.md`），已记入 `handoffs/2026-08-25-codex-key-count-neutralization.md`，不进契约正文。**两侧无遗留欠账。**

- **客户端 08-22 产生的三条球在本库，已于 2026-08-23 全部落笔，三处成对采纳均完成：**
  ① **回声校验通则的后端半** → `contracts/profile-sync.md` §5c（适用面恒等式 · 类型感知比较口径 · 追加字段刚性）+ `contracts/envelope.md` §8 指路。客户端半 08-22 已落，本库半落笔即完成成对采纳。
  ② **flags「回滚即前滚」的对位条款** → `contracts/content-manifest.md`「服务端保证」B 组三条 + `operations/_index.md` 的发布 / 回滚流程。客户端「增大即拉」所依赖的那一半到位，**客户端规则一字未改**。落笔时发现的对侧缺口（应答体 `flagsVersion` 是否也过单调闸）已由客户端自行裁决并同批落笔，本库不代为决定。
  ③ **静默续期绕过协议维度强更闸门的收口** → `contracts/auth.md` §5b（refresh 链绝对寿命上限 · `SessionExpired` · `reauthRecommended`）。客户端半同批落笔（二级文案 + 软信号反应形态）。
  移出记录见 `../answer-logs/log-echo-validation-scope.md` · `log-flags-version-monotonic.md` · `log-refresh-lifetime-cap.md`。**三条本库侧均无遗留欠账。**

- **`bundleGrantOrdinal` 施加权收归后端唯一 `+1` 已承接**（客户端 2026-08-19 定案 → 本库 2026-08-22 落笔）：本库既有口径与该裁决同向，故无一句被改写，落的全是护栏与登记——`contracts/profile-sync.md` §5c 回声校验（后端写入封闭表的首个报文层执行点）· §5 补入 `/entitlement/bundleRedeemedOrdinal`（后端只读 + 不变式）· §4 拒绝面补所有权类与判定顺序 · §7a 判据边界 · §8 只读副本受读己所写约束；`contracts/purchase.md` §6 保证 3 升格为一致性要求 + 新增保证 5–7 · 新增 §7 收据幂等窗口（全局唯一键 · 永久保留）· §3 `platform` 取值域收敛为三条具名渠道。**两侧无遗留欠账**；客户端侧的兑现段形态权威在 `game-design-documents/systems/monetization.md` 与 `decisions/ADR-0023-premium-entitlement-and-redemption.md`，**本库不复述**。
  **该连带（回声校验的适用面与非整数比较口径）已于 2026-08-23 答结**，见本节第一条。

- **两层 Profile 字段命名两侧同批落笔**（2026-08-17）：客户端把集合字段名统一为单数并收口条目键名，本库同批改 `contracts/profile-sync.md` §5 白名单与排除清单四条路径 + 新增 §5b 命名通则与一次性切换的三个成立前提。**两侧无遗留欠账。**
- **球在对侧、本库无欠账的第三处：** 残卷 `ordinal` 的口径**两侧已对齐**——本库 §7 复算读的就是本次（自增后）的 `finaleWinOrdinal`，客户端侧的账号级 RNG 通则权威在 `game-design-documents/systems/common-properties.md`（本库不复述）。本次只在 §7 做了一句零风险的措辞消歧，**算法与 §6a 的 8 组测试向量未改**。**本库不重复设计、也不催办。**
- **购买段已承接**（客户端 08-15b 定案 → 本库 2026-08-16 落笔）：新增 `contracts/purchase.md` · `profile-sync.md` §2 §5 改为后端写入字段封闭两行表并补入白名单行 · 契约面四份 → 五份。移出记录见 `../answer-logs/log-cross-library-alignment.md`。
- **账号身份模型两侧同批落笔**（2026-08-16）：本库定契约本体（`contracts/auth.md` 七端点 + identity 模型 + `profile-sync.md` §5 写入表扩到四行），客户端同批落 `account-service` 的四个新方法、`AccountInfo` 的三个新字段与绑定 UX。**两侧无遗留欠账**；余下的 `deviceId` 落点与 refresh token 客户端持有形态登记在客户端库自己的清单上，**本库不催办**。
- **球在对侧、本库无欠账的两处：** `Source` 的序列化形态已由 `contracts/profile-sync.md` §5a 收口 · §6 §7 的随机源与复算协议已成文。二者欠的都只是客户端传导，且**已于同批落笔**。**本库不重复设计、也不催办。**

# 跨边界承接（客户端已定案、本库尚未落笔）

> 本分片属 `../open-questions.md`，但它跟踪的**不是待答问题**。
>
> **与普通分片的关键区别，必须先读：普通待答项等的是「设计裁决」，本分片的条目等的只是「落笔」——答案在客户端库里已经写好了。**
> 混进普通分片会让它们和真正的开放问题一起被无限期搁置——客户端 08-15b 定案的购买段在本库空悬了整整一周，即是一例。
>
> **每条的固定形态：** `客户端权威文档路径#小节 | 客户端定案日期 | 本库需改的文档 | 一句话摘要`。
> **只回链、不复述**——复述即制造第二权威。
>
> **关闭条件：** 本库落笔完成（对应 handoff `distilled`）后从本分片移除，记进 `../answer-logs/`。两侧条目各自独立关闭。
>
> 机制的完整设计、病因诊断与维护者分工见客户端库同名分片 `game-design-documents/open-questions/cross-boundary.md`（两份不重复写）。

## 待承接

*（空）*

## 对账基线（不是待办）

- **`bundleGrantOrdinal` 施加权收归后端唯一 `+1` 已承接**（客户端 2026-08-19 定案 → 本库 2026-08-22 落笔）：本库既有口径与该裁决同向，故无一句被改写，落的全是护栏与登记——`contracts/profile-sync.md` §5c 回声校验（后端写入封闭表的首个报文层执行点）· §5 补入 `/entitlement/bundleRedeemedOrdinal`（后端只读 + 不变式）· §4 拒绝面补所有权类与判定顺序 · §7a 判据边界 · §8 只读副本受读己所写约束；`contracts/purchase.md` §6 保证 3 升格为一致性要求 + 新增保证 5–7 · 新增 §7 收据幂等窗口（全局唯一键 · 永久保留）· §3 `platform` 取值域收敛为三条具名渠道。**两侧无遗留欠账**；客户端侧的兑现段形态权威在 `game-design-documents/systems/monetization.md` 与 `decisions/ADR-0023-premium-entitlement-and-redemption.md`，**本库不复述**。
  **唯一仍开放的连带**：回声校验的适用面与非整数路径的比较口径，登记在 `01-contracts.md`（**不是承接项**——它等的是设计裁决，且已有 `decided` 草稿在办）。

- **两层 Profile 字段命名两侧同批落笔**（2026-08-17）：客户端把集合字段名统一为单数并收口条目键名，本库同批改 `contracts/profile-sync.md` §5 白名单与排除清单四条路径 + 新增 §5b 命名通则与一次性切换的三个成立前提。**两侧无遗留欠账。**
- **球在对侧、本库无欠账的第三处：** 残卷 `ordinal` 的口径**两侧已对齐**——本库 §7 复算读的就是本次（自增后）的 `finaleWinOrdinal`，客户端侧的账号级 RNG 通则权威在 `game-design-documents/systems/common-properties.md`（本库不复述）。本次只在 §7 做了一句零风险的措辞消歧，**算法与 §6a 的 8 组测试向量未改**。**本库不重复设计、也不催办。**
- **购买段已承接**（客户端 08-15b 定案 → 本库 2026-08-16 落笔）：新增 `contracts/purchase.md` · `profile-sync.md` §2 §5 改为后端写入字段封闭两行表并补入白名单行 · 契约面四份 → 五份。移出记录见 `../answer-logs/log-cross-library-alignment.md`。
- **账号身份模型两侧同批落笔**（2026-08-16）：本库定契约本体（`contracts/auth.md` 七端点 + identity 模型 + `profile-sync.md` §5 写入表扩到四行），客户端同批落 `account-service` 的四个新方法、`AccountInfo` 的三个新字段与绑定 UX。**两侧无遗留欠账**；余下的 `deviceId` 落点与 refresh token 客户端持有形态登记在客户端库自己的清单上，**本库不催办**。
- **球在对侧、本库无欠账的两处：** `Source` 的序列化形态已由 `contracts/profile-sync.md` §5a 收口 · §6 §7 的随机源与复算协议已成文。二者欠的都只是客户端传导，且**已于同批落笔**。**本库不重复设计、也不催办。**

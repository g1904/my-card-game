# Answer log cross-library-alignment

- 日期：2026-08-16
- 来源：`inbox/solution-draft-cross-library-alignment.md` → `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md`
- 移出条数：1

**`Source` 在上行负载里的序列化形态（承重 · 08-12b 起挂在 `05-service-contracts.md`）** → **契约侧走字符串成员名（`"FinaleWin"`）· 存档侧走整数 code · 客户端在序列化边界做一次映射**，映射发生在 `sync-service` 组装上行负载时，不在 `profile-service` 内部做（存档态与内存态始终是 code）。连带补上承重纪律「**成员名与 code 双双冻结、永不复用**」——存档靠 code、契约靠名，两者各自都是稳定键，重命名成员在两侧都是破坏性变更。未知取值记录原值、不改写、不拒收；`(Kind, Scope) → 允许的 Source 集合` 静态表只约束客户端组装，后端不复制。
（归档去向：`systems/common-properties.md` 的 `## 内容共有字段` · `systems/services/sync-service.md` 的传输信封小节；契约侧权威在 `backend-design-documents/contracts/profile-sync.md` §5a。）

> 收口方向取的正是该条目自己写的「倾向收口」，依据是**契约权威在后端库** + `envelope.md` §2「枚举一律字符串」是通则、不为一个枚举开例外。同批落笔的 `profile-sync` 七点欠账与购买段两处收尾**本就不是待答项**（对侧已定案，欠的只是客户端落笔），故不计入移出条数；它们的落点见上述 handoff 的 `distilled-to`。防止此类欠账再次积压的机制是新增的 `open-questions/cross-boundary.md`。

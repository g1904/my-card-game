# Answer log premium-character-series-unlock

- 日期：2026-09-12
- 来源：`inbox/solution-draft-premium-character-series-unlock.md` → `handoffs/2026-09-12-premium-character-series-unlock.md`
- 移出条数：1（`open-questions/cross-boundary.md`「待承接」第一条 —— 内含两问，一并答定）

## 逐条

**付费角色系列的后端承接（`ADR-0255` 三项义务 · 09-11 登记 · 此前为待答 / 提案形态）** → **两问一并答定，条目由「待答 / 提案」转为「已承接」：**

① **SKU 粒度是系列级还是角色级** → **系列级，且只有这一种可购商品**。单解 SKU 不存在，对侧 ADR 里的「付 4 个 / 8 个单解之价」是**定价锚**（记账单位），不对应任何可购商品；`ADR-0255` 不需改写。推论：一个角色系列 = 一个 SKU，后端**不持有任何「系列包含哪几个角色」的内容编排知识**；`productId ↔ seriesId` 走**机械变换**（`productId = "series_" + slug`），不建映射表、不给 SKU 表加手写 `seriesId` 列。后端只校验形态不校验存在性，反解失败复用 `purchase.receipt_invalid` + 风控事件。

② **封闭表加的是哪张表** → **两张都加，不是二选一**。`profile-sync.md` §5 的**后端写入字段封闭表** 4 行 → **5 行**（新增 `/entitlement/characterSeries`），**透明字段白名单**同加一行——两表正交（前者答「谁写」，后者答「后端看不看得懂」），由后端写入的字段必然对后端透明。用户明确批准这次扩表（**本表成文以来的第一次**）并要求按「破坏性契约变更」的规格处理；**护栏措辞规则一字不改**，论证按判据 ① / ② 逐条写进正文。§5c 的适用面恒等式使该 path **自动**进入回声约束，`entitlement` 本就是受约束顶层键之一 ⇒ **「受约束的顶层键恰有两个」一字不改**。

（归档去向：`contracts/purchase.md` §2 §3 §3a §3c §4 §5 §6 §7 · `contracts/profile-sync.md` §5 §5c · `operations/version-matrix.md` · `operations/purchase-ops.md` §1a §3d §5 · `systems/profile-store.md`）

## 同批裁决（合并 interview / 批量评审 · 2026-09-11）

- **重复购买一个已拥有的系列时是否自动发起渠道退款** → **不自动退款，记风控事件走人工工单**（按标准默认采纳，未单独出题）。依据：自动退款要求后端持三渠道**退款 API 写权限凭据**（当前凭据面只覆盖查询 / 核销，是显著攻击面扩大）并引入一条异步补偿状态机；「折价抵扣」的前提（账号级可支配货币）已被客户端侧明确关死；主防线（平台侧非消耗型商品 + 微信渠道首版不开通）使触发率近乎为零，且 **A → B 是纯加法**，触发率超预期时不需回头改任何契约条款。（归档去向：`contracts/purchase.md` §3c · `operations/purchase-ops.md` §5）
- **新增机制：付费系列有购买时限（限时销售窗口）** → 用户在评审中提出并裁定三条语义：**不绝版**（窗口可重开，或转常驻仅失去限时优惠价）· **已购玩家永久可用**（下架的只是购买入口）· 限时的是价格与销售节奏、不是可得性。后端义务：SKU 表加一格上架窗口、`verify` 据此拒绝窗口外新购、**窗口不进 profile / 不进任何封闭表**。窗口外拒绝**复用 `purchase.receipt_invalid`**（窗口外 = 商品此刻不可售，与「`productId` 不在 SKU 表」客户端处置逐字相同），故「失败 `code` 零新增」仍然成立。（归档去向：`contracts/purchase.md` §3a · `operations/purchase-ops.md` §1a）
- **`GET receipt` 的 `Verified` 应答条件化对老客户端是否破坏性** → **不是**，前提是老客户端不可能持有系列 SKU 的 `receiptId`。该前提已如实写进 `contracts/purchase.md` §4 正文，作为分形成立的条件而非事后解释。

## 仍留在清单上的

- **商户侧下单渠道（微信）在上架窗口外的下单请求如何应答**（本次新增 · 落 `01-contracts.md`）：窗口校验当前只在 verify（付款之后）；前移到 `POST /v1/purchase/order` 更符合「把失败点挪到掏钱之前」，但下单端点没有语义合身的既有 `code`。微信渠道首版不开通 ⇒ 不阻塞首版；答案可能触及 `envelope.md` §6 台账。
- **首批付费系列的 `seriesId` / `productId` 取值**取决于客户端侧「双灵根批与付费系列的推出时点与主题包装」。本次只定变换规则与校验形态，不定任何取值——**球在对侧，本库不催办**。

## 跨边界

客户端半（`CharacterData` 轨道字段 · `PlayerEntitlement` 集合字段形态与读档校验 · 取池过滤落点 · `schemaVersion` 逐版形状 · 购买流程与 UI）同批落笔于 `game-design-documents/`，见对侧 `handoffs/2026-09-12-premium-character-series-unlock.md`；本 log 不复述其形态。

**四条前置依赖，单侧采纳即两侧不一致：** 解锁粒度 = 系列 · `/entitlement/characterSeries` 与元素形状 · 客户端对该 path 原样回声（本库 §5c 的有序逐元素口径依赖它）· 客户端登记行与本库矩阵行同批且**矩阵先加、客户端后发**。

**`envelope.md` 零改动**（`code` / 端点 / `OpError` 全部零新增）；§8 的连带刚性由本次**首次真实行使**，条文一字不改。

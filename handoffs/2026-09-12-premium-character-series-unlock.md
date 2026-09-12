# 付费角色系列的后端承接：SKU 类别 · 验票写入 · 封闭表首次扩表 · 上架窗口

- id: 2026-09-12-premium-character-series-unlock
- date: 2026-09-12
- topic: contracts/purchase.md · contracts/profile-sync.md · operations/version-matrix.md · operations/purchase-ops.md · systems/profile-store.md
- status: distilled
- distilled-to: `contracts/purchase.md`（§2 §3 §3a §3c §4 §5 §6 §7）· `contracts/profile-sync.md`（§5 §5c）· `operations/version-matrix.md`（`schemaVersion` 子表）· `operations/purchase-ops.md`（§1a §3d §5）· `systems/profile-store.md`（事务边界 · 实现纪律 5 · `receipt_idem` 列）

## Intent（distilled）

客户端已把「付费解锁角色系列」定为商业化第三支（`game-design-documents/decisions/ADR-0255-*`）。本 handoff 承接它落在后端这一侧的全部义务：**第二类 SKU 怎么表达、验票后往 profile 里写什么、封闭表要不要加行、兼容矩阵怎么登记、失败 `code` 要不要新增**。

**客户端半在 `game-design-documents/handoffs/2026-09-12-premium-character-series-unlock.md`**（`CharacterData` 的轨道字段 · `PlayerEntitlement` 的集合字段形态与读档校验 · 取池过滤落点 · `schemaVersion` 的逐版形状 · 购买流程与 UI）。两侧互相回链，**一字不复述对方**。

### 1. SKU 粒度 = 系列级，且只有这一种

可购商品只有整系列礼包一种；**不存在角色级 SKU**，定价上的「几个单解之价」是记账用的定价锚。⇒ 一个角色系列 = 一个 SKU，后端**不持有「这个系列包含哪几个角色」的任何知识**——那是内容编排，抄进本库即第二权威，而两库都没有机制能发现它漂移。

### 2. `productId ↔ seriesId` 是机械变换，不建映射表

`productId = "series_" + <seriesId 的 slug 段>`。后端校验的是**形态而非存在性**（它没有内容知识）；反解不出合法形态 → `purchase.receipt_invalid` + 风控事件，与「`productId` 不在 SKU 表」逐字同一处置。存在性的真实防线在发版前的商店配置核对。判据是本库已行使过的那条：**能机械变换的绝不建第二张手写表**。

推论：**客户端零新增下发面、零新增端点**——商店该列哪些系列由客户端内容层自行归组。

### 3. verify 请求一格不加，应答按 `kind` 分形

`seriesId` 不进请求（客户端自述违反「提交的一切只作索引不作判据」）。应答新增判别式 `kind`，`bundleGrantOrdinal` 降为 `kind == PremiumBundle` 时才存在——它的存在理由是「兑现段掷骰的 `ordinal`」，而系列解锁**没有兑现段**。spec 层取 `oneOf` + `discriminator`，与请求根判别式同构。`GET receipt` 的 `Verified` 应答同款分形；`Rejected` 的取值域一字不变。

### 4. 验票事务内的写入 = 集合追加，与 `revision += 1` 同事务

```
kind == PremiumBundle    →  /entitlement/bundleGrantOrdinal += 1
kind == CharacterSeries  →  /entitlement/characterSeries 尾部追加一个元素（保证唯一）
两类共有                 →  cloudRevision += 1（同一次事务）
```

两类写入的幂等性质不同（自增 vs 自然幂等的并入），但**都必须走 `receiptId` 幂等**：`cloudRevision` 的推进不幂等、「已被他账号核销」依赖 `receiptId` 全局唯一、§6 的保证是对全域的承诺。

### 5. 重复购买一个已拥有的系列：接受写入 + 风控事件，绝不拒绝

主防线是平台侧非消耗型商品（Google / Apple 在平台层即拒绝重复购买）。**微信支付没有这一概念**，且多设备并发能绕过客户端的「已拥有即置灰」⇒ 后端兜底：接受写入（集合幂等 ⇒ 实际无变化）· `revision` 仍 `+1` · 回 `deduplicated = false` · 打风控事件 · **不自动退款，走人工工单**。

绝不拒绝是承重的：钱已经扣了，付款之后的失败面是整条链上最糟的失败时机。处置形态与 `profile-sync.md` §7a 逐字同构，不新开处置语义。

### 6. `profile-sync.md` 两张表各加一行（封闭表的第一次扩表）

后端写入字段封闭表 4 行 → **5 行**，新增 `/entitlement/characterSeries`；透明字段白名单同加一行（两表正交：前者答「谁写」，后者答「后端看不看得懂」，由后端写入者必然对后端透明）。

按护栏要求的显式论证：判据 ①（真值只可能在服务端产生）成立——客户端写入即等于客户端有权发货；判据 ②（客户端无其他通道取到它）成立——本 path **没有兑现段**，不进表就没有任何通道能让解锁到达客户端。**「写入时机」列不被触碰**：本行落在既有的「验票」时机下。

§5c 因适用面恒等式**自动**覆盖新 path，不需要第二次决定；`entitlement` 本就是两个受约束顶层键之一 ⇒ **「受约束的顶层键恰有两个」一字不改**。比较口径取**有序逐元素**（同 `identities`），其成立前提是后端恒在尾部追加、客户端原样回声。

### 7. 服务端保证新增第 8 条

`/entitlement/characterSeries` **只增不删、元素唯一**——含「该系列改走免费轨道」与「上架窗口关闭」两种情形：那两件事改的是「能不能买」，不是「拥有什么」。保证 4 / 7 对本类不适用；保证 5 由恒等式自动覆盖。

### 8. 失败 `code` 零新增

逐一核对本次引入的全部新情形：`productId` 不在表 / 反解失败 / 上架窗口外 → 复用 `purchase.receipt_invalid`；重复购买已拥有系列 → 不回错误（玩家面为空）。⇒ **零新增 `code` · 零新增端点 · 零新增 `OpError`**，`envelope.md` §6 台账与 §3 端点全集表**均不加行**，P-1 / P-3 两条护栏不被触碰，两条机检断言零变化。

### 9. 上架窗口（限时销售）

每个 `kind == CharacterSeries` 的 SKU 在 SKU 表上带一格上架窗口（可空 = 常驻）；验票时不落在窗口内 ⇒ 复用 `purchase.receipt_invalid` + 风控事件（窗口外 = 商品此刻不可售，与既有不可售态同码）。

三条语义：**不绝版**（窗口可重开，或转常驻仅失去限时优惠价）· **已购玩家永久可用**（下架的只是购买入口）· 限时的是价格与销售节奏，不是可得性。**窗口不进 profile、不进 `/entitlement/characterSeries`、不进任何封闭表**——它约束「能不能买」，不是「拥有什么」，故第 6 条的两张表加行形态不受影响。

### 10. 幂等记录存储形态加三格

`receiptId → { accountId, productId, kind, bundleGrantOrdinal?, grantedSeriesId?, revision, verifiedAtUtc, status }`。存 `productId` **原值**（SKU 会下架，靠反查会断）；`grantedSeriesId` 是解析结果的**快照**（变换规则日后调整时历史工单仍要能定位）。退款态仍只记在运维侧字段，不进 `GET receipt` 的 `status` 枚举。

### 11. 兼容矩阵：`schemaVersion = 2`，矩阵先加、客户端后发

本库的承接义务是给 `schemaVersion` 子表加 `2` 一行 + 下线计划，`sync.payload_schema_unsupported` 的 `detail.supportedSchemaVersions` 随之为 `[1, 2]`。**逐版形状的权威在客户端库**，本库一个字段名都不写。

**顺序纪律是硬的**：矩阵未加就发客户端 ⇒ 每一个新版客户端的第一次 push 即被拒（`Upgrade` 档、不硬阻塞，但玩家进度上不去云端）。

**条件分支如实写下**：若付费系列改在客户端首发**之前**落地，客户端侧的一切改动仍归 `schemaVersion = 1`，**本条整条不发生**，矩阵零改动。当前预期是首发之后。

## Clarifications

本 handoff 的来源草稿在 2026-09-11 的批量评审中由用户逐项裁定，以下为对原草稿的改动与定案：

- **SKU 粒度是系列级还是角色级？** → **系列级，且只有这一种**（单解 SKU 不存在，「几个单解之价」是定价锚）。`ADR-0255` 不需改写。
- **封闭表加的是哪张表？** → **两张都加**（后端写入字段封闭表 + 透明字段白名单，两表正交非二选一）。用户明确批准封闭表的首次扩表，并要求按「破坏性契约变更」的规格处理——护栏措辞规则一字不改。
- **重复购买已拥有系列时是否自动发起渠道退款？** → **不自动退款，记风控事件走人工工单**（按标准默认采纳）。依据：自动退款要求后端持三渠道退款 API 写权限（当前凭据面只覆盖查询 / 核销，是显著攻击面扩大）并引入一条异步补偿状态机；「折价抵扣」的前提（账号级可支配货币）已被客户端侧明确关死；且主防线使触发率近乎为零，**改为自动退款是纯加法**。
- **新增机制：付费系列有购买时限（限时销售窗口）** → 用户在评审中提出并裁定三条语义（不绝版 · 已购永久可用 · 限时的是价格与销售节奏）。后端义务见上方第 9 条。
- **`GET receipt` 的 `Verified` 应答条件化对老客户端是否破坏性？** → **不是**，前提是老客户端不可能持有系列 SKU 的 `receiptId`。该前提已如实写进 `purchase.md` §4 正文，作为分形成立的条件。

## Open questions

- **商户侧下单渠道（微信）在上架窗口外的下单请求如何应答？** 窗口校验当前只落在 verify（付款之后）。前移到 `POST /v1/purchase/order` 更符合「把失败点挪到掏钱之前」，但下单端点没有一条语义合身的既有 `code`（`channel_disabled` 讲渠道未开通，`receipt_invalid` 的客户端处置针对已付款的玩家）。**微信渠道首版不开通 ⇒ 不阻塞首版**；答案可能触及 `envelope.md` §6 台账，是本次唯一一处可能破坏「`code` 零新增」的地方。
- **首批付费系列的 `seriesId` 取值、进而 `productId` 取值**，取决于客户端侧「双灵根批与付费系列的推出时点与主题包装」。本次只定变换规则与校验形态，不定任何取值。

## Notes / triage

- **契约变更的完成判据**（`contracts/_index.md`）在本次的落位：① markdown 已更新（`purchase.md` 六处 + `profile-sync.md` 两处）；② spec 尚未落笔 ⇒ **本次无对象**；③ 新增 / 变更 `code` **本次无对象**；④ 三条机检断言走降级形态——断言① `skipped: no spec yet`（**不是 `pass`**），断言② 台账 ⇔ 正文 `code` 字面量双向**零变化**，断言③ 端点全集 ⇔ 正文 `METHOD 路径` 双向**零变化**；⑤ 人工清单四项：`detail` / `message` 零变化 · 承重纪律段落已逐条复核（`profile-sync.md` §5 白名单与 §5c 恒等式）· 需 bump `schemaVersion`（URL 主版本不动、spec `info.version` bump **minor**）· 另一侧 handoff 已写；⑥ 两侧 handoff 互相回链。
- **分域判据复核**：不新开契约文档。本次没有引入任何与既有六份相反的承重纪律——它是 `purchase.md` 既有纪律（后端权威写入 · 必须裁决 · 必须能拒绝）在第二类 SKU 上的直接延伸。
- **`envelope.md` §8 的连带刚性由本次首次真实行使**（向受约束顶层键内追加字段 ⇒ 两侧同批落笔）。**条文一字不改**，此处只记它被行使了一次。

## 客户端侧影响

**是。** 本 handoff 改动客户端 ↔ 后端边界的语义，受影响的客户端成分是 **`sync-service`**（profile 上下行的透明字段面与回声约束）与购买流程调用的 `IPurchaseBackend` 应答形状。

客户端侧的对位改动已由 `game-design-documents/handoffs/2026-09-12-premium-character-series-unlock.md` 承载：`PlayerEntitlement` 的集合字段与元素形状 · 对该 path 不改写 / 不去重 / 不归一化的回声纪律 · `schemaVersion` 登记表新增一行 · verify / `GET receipt` 三个应答 record 随本次分形同批调整。

**四条前置依赖，单侧采纳即两侧不一致：**

1. 解锁粒度 = 系列、集合元素承载 `seriesId`；
2. `/entitlement/characterSeries` 这条 path 与元素的字段形状；
3. 客户端对该 path **原样回声**（本库 §5c 的有序逐元素口径依赖它）；
4. 客户端的 `schemaVersion` 登记行与本库的矩阵行同批，且**矩阵先加、客户端后发**。

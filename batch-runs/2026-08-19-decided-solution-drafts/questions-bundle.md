# Phase A — bundle

输入：`game-design-documents/inbox/solution-draft-bundle-grant-ordinal-authority.md`（`status: decided`）
目标库：`game-design-documents/`（用户显式给定 `game`）
counterpart（只读核对，**本分片不写后端库任何文件**）：`backend-design-documents/inbox/solution-draft-bundle-grant-ordinal-authority.md`

## 一句话摘要

`BundleGrantOrdinal` 的施加权收口为**后端唯一 `+1`**：客户端侧整行撤下它的 `ResourceElements` 施加路径，改为在 `PlayerEntitlement` 上新增客户端写的兑现水位 `BundleRedeemedOrdinal`（`Grant > Redeemed ⟺ 有一次待兑现`），兑现事务、购买入口第 4 条前置条件、购后阻塞与兑现结果屏随之定形。

## 已定案项（用户已裁决，不进 interview）

| # | 定案 | 落笔含义 |
|---|---|---|
| Q1 | `PlayerEntitlement` **加第二个字段** `BundleRedeemedOrdinal`（int，客户端写，兑现事务内置为本次 ordinal，`0` = 从未兑现） | 承重表述「类内只有一个字段」改写为「类内只放付费凭证本身与其兑现水位，不放任何派生量」 |
| Q1 连带 a | `ResourceElements` 里 `BundleGrantOrdinal` **整行撤下**、不登记为 `CostKey` 成员 | 缺行即 `PushError` + 整批拒绝，成为客户端置位的硬闸 |
| Q1 连带 b | 新增 `BundleRedeemedOrdinal` 行：`Min 0` · `Max 无` · 归 Min 时无 · 两修正列 `null` · `AllowedOps = Set` | 自动满足既有两条启动期断言 |
| Q1 连带 c | 内部相抵是**三处同改**（`monetization.md` 伪码 / 同文档购买段 / `player-profile/_index.md` 字段表第 14 行） | 见下方 🔴-3：第 14 行的目标写法本身有误 |
| Q5 | **设立兑现结果屏**，列出本次获得的 1 法则 + 2 古宝 | `monetization.md`「允许的全部呈现穷举为两处」→ 三处 |
| Q6 | **不允许**在结果屏之前离开；维持「阻塞在主菜单重试直到成功、不允许开始新轮回」 | 载体形态仍待定，见 🔴-1 |
| 相邻 | 平台内购 SDK **纳入 MVP**（Google Play Billing · StoreKit · 微信支付三渠道） | 推翻 `monetization.md`「落在 MVP 之外」；`vision/scope.md` 同步（改写幅度见 🟠-3） |
| 相邻 | 纯外观付费点 **架构预留、首批不做** | `vision/scope.md`「外观装饰」由「范围之外」改写为「架构预留、首批不做」；首批不新增字段、不新增屏 |
| 相邻 | `K` / `GrantPoolMargin` 数值仍待内容规模明朗 | 不阻塞，留在 `systems/balance.md` |

## 跨库核对（客户端 vs backend counterpart / contracts）

**逐条比对结论：**

| 客户端草稿的陈述 | 后端权威 | 结论 |
|---|---|---|
| 后端在验票事务内 `bundleGrantOrdinal += 1` 与 `cloudRevision += 1` | `contracts/profile-sync.md` §5 后端写入封闭表（`/entitlement/bundleGrantOrdinal`，写入时机「每次验票通过时 +1」）· `purchase.md` §3 | ✅ 一致 |
| verify 只回序号 + `revision`、不内联 profile ⇒ 购后必须强制一次 pull | `purchase.md` §3「应答只回序号 + revision，不内联新 profile」 | ✅ 一致 |
| 「已被他账号核销」属不可重试类 | `purchase.md` §3 失败面 | ✅ 一致 |
| `receiptId` 幂等读可跨启动补查 | 后端草稿 Q3 定案：幂等记录**永久保留、不设 TTL** | ✅ 一致（且比客户端假设更强） |
| `/entitlement/bundleRedeemedOrdinal` 后端**只读**、校验不变式、不驱动任何自动发放 | 后端草稿子项 3 A/B/C/D | ✅ 一致 |
| 客户端侧「不做后端主动推送」 | 后端草稿子项 4 明确否决推送 | ✅ 一致 |
| 读己所写（verify 后 pull 必读到新序号） | 后端草稿 Q2 定案：升格为服务端一致性要求 | ✅ 一致（客户端侧无需承接文字，但它是「客户端不重试」这条得以成立的前提） |
| **回声校验**：`playerDiff` 含 `entitlement` 键时 `bundleGrantOrdinal` 必须与云端逐位相同，否则**整批拒绝 `sync.conflict` + 风控事件** | 后端草稿 Q1 定案 · 拟写入 `contracts/profile-sync.md` §4/§5 与 `purchase.md` §6 保证 5 | ❌ **客户端草稿全文未提**，见 🔴-4 |

**总结论：两侧在已写下的部分逐条一致；唯一不一致是客户端侧存在一处「后端已定案、客户端零承接」的闭合缺口（🔴-4）。** 成对采纳的硬要求两侧措辞一致，无冲突。

## 🔴 冲突

### 🔴-1 购后阻塞屏的载体，与「硬阻塞只有两处」这条承重表述直接相抵

草稿子项 6：第 4–6 步呈现「**既有阻塞屏的一个变体**：正在处理你的购买… + 进度指示；≥15 秒追加副文案 + 显式『重试』」，**不可继续游玩**、只允许退出应用。

✗ 既有权威三处：
- `systems/architecture.md`:288 —「**硬阻塞仍然只有两处，且只由已知 `code` 触发**——`auth.session_revoked` 与登录 / 启动 pull 点的 `client.version_unsupported`。……**一个未知 `code` 永远不得新增第三处硬阻塞**。」
- `ux/error-and-blocking-ux.md`:222–240 — 变体表恰三行、`enum BlockingNoticeKind { VersionUnsupported, SessionRevoked, MigrationFailed }`、`BlockingNoticeSpec` 四格（无进度 / 无副文案格）；并明写「**三个变体 ≠ 三处硬阻塞**，硬阻塞点仍是既定两处」。
- `ux/screen-flow.md`:125 — 同句复述。

购买处理态**不由任何后端 `code` 触发**（它是客户端等待态），且它确实让玩家在主菜单走不下去 ⇒ 若做成 `BlockingNoticeScreen` 的第 4 个变体，「两处 / 由 code 触发」两条同时被推翻。
（注：`systems/services/sync-service.md` 既有句「UI 复用既有阻塞屏的变体表，不新增拦截点」已埋下同一张力，本草稿只是把它具体化。）

- 选项 **(a) 不做成 `BlockingNoticeScreen` 变体**：购买处理态是 Store / 主菜单流程内的一个**全屏模态进度态**（自带进度指示 + 重试 + 退出应用），文案走 `STORE_` 分区。后果：`BlockingNoticeKind` 与变体表**不动**，「硬阻塞只有两处、只由 `code` 触发」原样成立；须在 `error-and-blocking-ux.md` 补一句判据「购买处理态不进本表，因为它不由 `code` 触发且有自愈路径」；`sync-service.md` 那句「复用既有阻塞屏变体表」须改写为指向该模态。
- 选项 **(b) 做成第 4 个变体**：`BlockingNoticeKind` 加 `PurchasePending`，`BlockingNoticeSpec` 加进度 / 副文案两格，并把 `architecture.md` 总则 7、`error-and-blocking-ux.md`、`screen-flow.md` 三处「只有两处 / 只由 `code` 触发」**一并改写为三处**。后果：一条承重的可机械检查纪律被松动，代价是日后每新增一个等待态都可以援引本例。
- 选项 **(c) 维持既有措辞不改、也不新增载体**，把购买处理态降级为主菜单上的非全屏遮罩 + 「开始新轮回」禁用。后果：与 Q6「不允许在结果屏之前离开」的字面相抵（玩家仍能翻别的面板），须确认 Q6 的意图是「不允许开始新轮回」还是「不允许离开这一屏」。

- **推荐：(a)** —— 它同时满足 Q6 的行为定案与既有两条承重纪律，且既有纪律的判据（「只由已知 `code` 触发」）恰好把这个客户端自愈等待态排除在外；`STORE_` 分区已存在（`error-and-blocking-ux.md`:129）正好承接文案。

### 🔴-2 兑现伪码 `ordinal = BundleGrantOrdinal` 与「`Grant - Redeemed > 1` 时逐一按序兑现」自相矛盾

草稿子项 4 伪码：`ordinal = profile.Entitlement.BundleGrantOrdinal`（直接取 pull 下来的值）。
草稿子项 3 末条：「若真读到 `Grant - Redeemed > 1` 属异常 → `PushError` + 上报，**逐一按序兑现**（每个 ordinal 一次独立 `TryApply`）」。

✗ 两句在同一份草稿内不可同时成立：差值为 2 时按伪码只兑现 `ordinal = Grant`，`Redeemed` 直接跳到 `Grant` ⇒ **中间那个序号永不被兑现**（玩家付了两次钱只拿一份货），正是本方案要防的「收了钱不给货」。

- 选项 **(a)** 伪码改为 `ordinal = Redeemed + 1` 的循环（`while Grant > Redeemed`），差值 = 1 时行为与现伪码逐字相同，差值 > 1 时自然逐一按序；保留 `PushError` + 上报。后果：伪码多一层循环，`AccountRng` 的 `(域, 序号)` 逐次对位保住。
- 选项 **(b)** 保留 `ordinal = Grant`，删除「逐一按序兑现」一句，把差值 > 1 定为**不可发生**（靠购买入口第 4 条前置条件 + 后端回声校验）。后果：多设备并发购买（两台设备各自通过本地前置条件）时静默少发一次，无补救路径。
- **推荐：(a)** —— 不变式只保证**单设备**下差值 ≤ 1；(b) 的前置条件读的是本地 pull 快照，挡不住两台设备各自付款。(a) 的成本是伪码一层循环。

### 🔴-3 `player-profile/_index.md` 字段表第 14 行「写入通道」的目标写法本身是错的

草稿子项 2 末条 + 具体形态 B：第 14 行写入通道由「`Elements`（`BundleGrantOrdinal` 置值）」改为「**后端写入 · 经 pull 下行进入内存态，无客户端写入通道**」。

✗ 与同一草稿的子项 3 / 子项 4 相抵：`BundleRedeemedOrdinal` **正是客户端经 `ProfileChangeSpec.Elements` 写入**的（`spec = { Elements: [ BundleRedeemedOrdinal := ordinal ], … }`）。按草稿的写法落笔，第 14 行会成为**新的第三处相抵**——与本方案要消除的那一处完全同型。

- 选项 **(a)** 第 14 行写作：类型 `PlayerEntitlement`（**2 字段**）· 写入通道「`Elements`（`BundleRedeemedOrdinal` 置值）；`BundleGrantOrdinal` 由后端写、经 pull 下行，无客户端通道」。后果：一行内如实呈现「一个类两种写入方」，与第 1 行 `accountInfo`「后端写三项 / 客户端写 `Nickname`」的既有写法同构。
- 选项 **(b)** 照草稿原文写「无客户端写入通道」。后果：与 `ResourceElements` 新增行、与兑现伪码直接矛盾，下一个读到它的人会照它写代码。
- **推荐：(a)** —— 第 1 行 `accountInfo` 已有同型先例，零新形态。

### 🔴-4 跨边界闭合缺口：后端已定案的「回声校验」在客户端侧零承接

后端 counterpart Q1 **已定案**：`playerDiff` 含顶层键 `entitlement` 时，其中 `bundleGrantOrdinal` 必须与云端**逐位相同**，否则**整批拒绝 → `sync.conflict` + 风控事件**。
而客户端侧 `systems/services/sync-service.md` 的 diff 语义是「顶层键出现即整键替换」⇒ **每一次兑现 push 都会提交 `entitlement` 整键**，因此每次兑现都会走一遍回声校验。客户端草稿与 `sync-service.md` 现文**均未写**这条义务与其失败处置。

✗ 后端权威：`backend-design-documents/inbox/solution-draft-bundle-grant-ordinal-authority.md` 子项 2 + 服务端保证 5（拟入 `contracts/profile-sync.md` §4/§5、`purchase.md` §6）。按跨库纪律，两库说法不一致 / 一侧零承接时**以后端 `contracts/` 为准**。

- 选项 **(a)** 在 `systems/services/sync-service.md` 的购买段补一条**承接句**（只回链、不复述后端语义）：上行组装 `entitlement` 键时必须**原样回声** pull 下来的 `bundleGrantOrdinal`（客户端永不自行赋值）；收到该情形的 `sync.conflict` 时**复用既有 Conflict 处置**（以云端为准、丢弃本地缓冲、重新 pull），不新增分支。后果：客户端侧闭合，改动面一句话 + 一条回链。
- 选项 **(b)** 不写，认为「客户端本就只写 `BundleRedeemedOrdinal`，回声是序列化的自然结果」。后果：一条**每次兑现都会走**的拒绝条件在客户端侧无任何记载，实现者不会知道 `sync.conflict` 有第三种来源，也没有「不得自行赋值 `bundleGrantOrdinal`」的落点。
- **推荐：(a)** —— 「不允许只改一侧就宣称收口」；且本条正是后端 Q1 取 A 的直接前提。

## 🟠 含糊

### 🟠-1 兑现结果屏的落点：新增一屏，还是 Store 屏的一个结果态？
Q5 定了「设立一屏」，但**没定它登记在哪**。`ux/screen-flow.md` 是屏清单的权威（主菜单入口表已含 `Store(礼包)`），而草稿的 `targets` 里**没有 `screen-flow.md`**。
- (a) 作为 **Store 屏的一个结果态**（同屏切态，文案走 `STORE_`）：屏数不变，`screen-flow.md` 只在 Store 行补一句。
- (b) 新增一屏 `BundleGrantResultScreen` 并登记进 `screen-flow.md`：形态独立，但屏清单 +1，且它只在一个流程里出现。
- **推荐：(a)** —— 它发生在 Store 流程内、由同一入口进出；`screen-flow.md` 的既有粒度（一个屏 + 状态说明）足以承载。
- 同一问顺带定：待兑现态存续期间「主菜单可进入但『开始新轮回』禁用 + 说明」这条**灰态**是否写进 `screen-flow.md` 主菜单段（推荐：写，与既有「入口置灰 + 说明、不隐藏」的灰态判据同处）。

### 🟠-2 `BundleRedeemedOrdinal` 的读档校验形态未定
既有分层通则（`player-profile/_index.md`:116）规定规则字段层一律「越界钳制 + 告警；不由历史重建」，`BundleGrantOrdinal` 现有写法是「`< 0` → `PushWarning` + 钳制到 `0`」。草稿只给了不变式 `0 ≤ Redeemed ≤ Grant`，未给读档处置，而**钳制方向是有后果的**：
- (a) `< 0` → 钳到 `0`；`> Grant` → **钳到 `Grant`**（判定为「无待兑现」）。后果：偏向不重复发放；坏档下最坏是少发一次（有后端对账信号可查）。
- (b) `> Grant` → 不钳制、只告警。后果：`Grant > Redeemed` 的比较可能读到负差值，兑现判定分支需额外定义。
- (c) `> Grant` → 反过来抬高 `Grant`。后果：客户端改写了后端唯一写入的字段，与本方案主旨正面相悖，**不可取**。
- **推荐：(a)** —— 与「重复发放是发放侧漏洞」这条本方案反复申明的取向同向，且与既有钳制写法同形。

### 🟠-3 `vision/scope.md` 中商业化两行的改写幅度
「SDK 纳入 MVP」推翻了 `vision/scope.md`:26「**商业化的落地**（支付接入、商店 UI、地区定价）——形态已给出方向…但不属 MVP 切片」，同时「外观预留」牵动 :25「元进程解锁、外观装饰、每日/seeded-轮回分享」这一行。改写幅度未定：
- (a) **整行移入 MVP**：MVP 列表新增一条「premium bundle 端到端（三渠道内购接入 + Store 屏 + 兑现）」，范围外那行**整条删除**；:25 拆行，「外观装饰」单列为「架构预留、首批不做」。
- (b) **只挪一半**：把「支付接入 + 商店 UI」挪进 MVP，「地区定价」留在范围外（定价由平台商店按 SKU 返回，客户端不硬编码金额——`monetization.md` 已如此定）。
- (c) 只改 `monetization.md`，`vision/scope.md` 不动。后果：两份文档对 MVP 边界给出相反答案，正是本方案在治的那类相抵。
- **推荐：(b)** —— 与 `monetization.md`「金额属发行侧、不落客户端」逐字相容，改动最小且不制造新的范围断言。

## 🔵 可推演（无需回答）

1. **`monetization.md` 伪码首行改写**为直接取 pull 下来的序号、客户端不做 `+1`；「序号自增与是否抽中无关 ⇒ `BundleGrantOrdinal` 照常 +1」这条纪律**整体迁移到水位字段**（理由逐字相同：不迁移即幂等键失效）。依据：草稿子项 1/4 + 后端封闭表。
2. **`monetization.md`:55 「类内只有一个字段（承重）」** 改写为「类内只放付费凭证本身与其兑现水位，不放任何派生量」（Q1 已批准松动），并同步 :123 决策项「付费凭证 = `PlayerEntitlement.BundleGrantOrdinal` 单字段」的措辞。
3. **`monetization.md`:115「允许的全部呈现穷举为两处」→ 三处**（补兑现结果屏，并写明它不是推销面：发生在付款之后、内容已定）。
4. **`monetization.md`:87 前置条件表加第 4 条** `BundleGrantOrdinal == BundleRedeemedOrdinal`（不满足 → 置灰 + 「上一笔购买正在发放」）；拦截点数量不变。
5. **`monetization.md`:131 待决问题「平台内购 SDK…落在 MVP 之外」** 改写为已裁决（三渠道纳入 MVP，SDK 选型 / 封装层归后端支付渠道选型 + 一次专门的客户端工程蓝图）；:129「纯外观付费点是否真做」改写为「架构预留、首批不做」。
6. **`profile-service.md`:80 整条 bullet**（「具名 element `BundleGrantOrdinal`：置值语义…」）改写为 `BundleRedeemedOrdinal`，理由逐字沿用（经 pipeline = 一条法则能伪造兑现记录）。
7. **`profile-service.md`:127 `PowerFragmentWinOrdinal` 行的依据列**引用了「与 `BundleGrantOrdinal` 同理」——该行撤下后成为悬空引用，须改写为自足表述（序号被修正即掷骰序列漂移）。
8. **`sync-service.md`:263** 「`PlayerEntitlement`，1 字段」→ 2 字段；「后端唯一会写入的第二个字段」措辞保留（`bundleGrantOrdinal` 仍是），并补 `/entitlement/bundleRedeemedOrdinal` 一条透明路径（**只写客户端侧承接的稳定性纪律，白名单与后端只读语义回链后端库**）。存档 schema bump 并入既有同一次 bump、空迁移。
9. **`sync-service.md` 购买段**：「`receiptId` 随待兑现态持久化」补定位——它是**加速补查的优化**，正确性由 `/entitlement` 两字段之差承载；跨启动补入口改为「每次启动 pull 后比较 `Grant > Redeemed`，不依赖本地待兑现态」。
10. **时序表 10 步与逐步失败语义**可原样落入 `monetization.md` / `sync-service.md`（除 🔴-2 的伪码修正与 🔴-1 的载体待定外，无与既有设计冲突处）。
11. **`Ordinal` 后缀合规**：`BundleRedeemedOrdinal` 是位置 / 幂等键 ⇒ 规则字段层，符合 `player-profile/_index.md`:122 的命名硬约定；类内仍禁用 `Total` / `Count`。
12. **闸 ③ 处置**：该项计未兑现、不补发、`PushError` + 上报，但水位**照常置为 `ordinal`**（否则每次启动重掷同一 ordinal、抽空池、反复报错）。
13. **备选否决记录**（尤其「靠重掷同一 `(域, ordinal)` 实现幂等」不成立——取池已排除已持有，第一次授予后池子变了）应作为**正面理由**写入活文档，不写「否决了谁 / 哪一天」（溯源三条②）。

## 拟改动文档清单与各自新增要点

| 文档 | 新增 / 修改要点（供跨草稿核对） |
|---|---|
| `systems/monetization.md` | 伪码改写（取 pull 序号、循环按序）· 序号自增纪律迁移到水位字段 · 「类内只有一个字段」表述改写 · 呈现穷举两处→三处 · 前置条件表加第 4 条 · 决策项措辞 · 两条待决问题改写为已裁决（SDK 纳入 MVP / 外观预留） |
| `systems/services/profile-service.md` | `ResourceElements` 表：删 `BundleGrantOrdinal` 行、增 `BundleRedeemedOrdinal` 行（`0` / 无 / 无 / `null` / `null` / `Set`）· :80 bullet 改写 · :127 悬空引用修正 |
| `systems/player-profile/_index.md` | 字段表第 14 行（类型 2 字段 + 写入通道，见 🔴-3）· `PlayerEntitlement` 类加第二字段与字段表行 · 「不设第二个字段」段落改写 · 新字段读档校验（见 🟠-2）· 透明路径一句 |
| `systems/services/sync-service.md` | :263 schema 段（1→2 字段、新透明路径、并入同批 bump）· 购买段：`receiptId` 定位降级为优化 · 跨启动补入口改为水位比较 · **回声校验承接句**（🔴-4）· 阻塞屏载体指向（随 🔴-1） |
| `ux/error-and-blocking-ux.md` | 购买处理态的载体与文案分区（随 🔴-1；(a) 则补一句「不进变体表」的判据，(b) 则改变体表 + `BlockingNoticeKind` + `BlockingNoticeSpec`） |
| `ux/screen-flow.md`（草稿 targets 未列，**新增**） | 兑现结果屏落点（随 🟠-1）· 待兑现期主菜单「开始新轮回」禁用的灰态 · 若取 🔴-1(b) 则同改「三个变体不等于三处硬阻塞」一句 |
| `systems/architecture.md`（草稿 targets 未列，**仅当 🔴-1 取 (b)**） | 总则 7 :288「硬阻塞仍然只有两处，且只由已知 `code` 触发」须改写 |
| `vision/scope.md`（草稿 targets 未列，**新增**） | :26 商业化落地行 · :25 外观装饰行（随 🟠-3） |
| **台账（orchestrator 代笔）** | `open-questions/05-service-contracts.md` 移出第 24 行（`BundleGrantOrdinal` 谁施加）· `answer-logs/log-bundle-grant-ordinal-authority.md`（新建）· `answer-logs/_index.md` 追加一行 · `open-questions/update-log.md` · `handoffs/_index.md` · `inbox/_index.md`（归档本草稿）· `open-questions.md` 顶部一行 |

**新建 handoff：** `handoffs/2026-08-19-<slug>-bundle-grant-ordinal-authority.md`（本 worker 的独占文件，Phase B 写）。

## 越界发现

1. **写入面撞车（orchestrator 必读 · 铁律 ③）。** 本分片与同批其他 `inbox/` 草稿在下列文件上重叠，**不得并行**：
   - `systems/services/profile-service.md` — 与 `solution-draft-costkey-statkey-registry.md`（同改 `ResourceElements` 表）、`solution-draft-codex-entry-schema.md`、`solution-draft-game-setting-schema.md`、`solution-draft-profile-change-spec-gaps.md`、`solution-draft-pickmany-shortfall-handling.md`
   - `systems/player-profile/_index.md` — 与 `costkey`、`codex`、`game-setting`、`device-id-provisioning`
   - `systems/services/sync-service.md` — 与 `costkey`、`codex`、`game-setting`、`architecture-structural-residuals`
   - `ux/error-and-blocking-ux.md` — 与 `game-setting`、`translation-english-placeholder`
   - `ux/screen-flow.md` / `systems/architecture.md` / `vision/scope.md` — 与 `game-setting`、`costkey`、`architecture-structural-residuals`
2. **`costkey` 分片存在语义依赖。** `solution-draft-costkey-statkey-registry.md`（`status: decided`）已照录本方案的结论：账号层第 8 个成员由 `BundleGrantOrdinal` 换为 `BundleRedeemedOrdinal`（总数仍 15），其「决定 3」自动消解。**两份必须给出同一张 `ResourceElements` 表**——建议由同一个 Phase B worker 串行落笔，或明确指定 `ResourceElements` 表的唯一写者。
3. **`/accountInfo` 是同形的第二处（后端草稿已登记为新待答项）。** `accountInfo` 顶层键同时含后端写（`accountSeed` / `createdAtUtc` / `identities`）与客户端写（`nickname`），客户端同样做整键替换 ⇒ 回声校验的客户端义务不止 `entitlement` 一处。后端侧已明确「本方案不改 `open-questions`，交由 `/analyze-new-ideas` 落笔」。**客户端侧是否也新增一条待答项**（「哪些顶层键的哪些路径受回声校验约束、客户端上行组装的回声纪律」）不在本分片草稿范围内 —— 交 orchestrator 裁量，不由本 worker 处理。
4. **本分片一个文件都未写**（只读 + 本产出文件）。后端库未做任何写入。

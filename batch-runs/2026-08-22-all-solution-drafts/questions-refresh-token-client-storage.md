# Phase A — refresh-token-client-storage

分片：`game-design-documents/inbox/solution-draft-refresh-token-client-storage.md`
目标库：`game-design-documents/`（主库）· **对侧库 `backend-design-documents/` 必须落一条承接项**（见 🔴-2）

## 一句话意图

把后端已定的「refresh token 不进 `Session`、落 `user://cache/`」在客户端侧落到具体形态：文件 `user://cache/refresh-token.json`、字段 `{ schemaVersion, accountId, refreshToken }`、六条失效路径、归属 `AuthManager` 私有；并补上它唯一的消费者——**启动期静默续期**。

## 已裁决（不进 interview）

| 项 | 裁决 | 状态 |
|---|---|---|
| 取向 3 —— 是否落地启动期静默续期 | **A · 落地** | **用户当面拍板**，按定案处理 |
| 取向 1 —— 是否存 `refreshExpiresAtUtc` | A · 不存 | `[采纳推荐 — 待复核]` ⇒ **按批量铁律 ① 不当作拍板**，见 🟠-1 |
| 取向 2 —— 凭据落盘保护强度 | A · 明文 `user://cache/` | `[采纳推荐 — 待复核]` ⇒ 同上，见 🟠-2 |

落点 / 字段面 / 六条失效路径 / `AuthManager` 私有归属 / 不与四份既有文件合并 —— 逐条与 `systems/services/account-service.md`「`deviceId` 的生成与持久化」、`systems/architecture.md` 第 95 行版本判据、`backend-design-documents/contracts/auth.md` §2 §4 §4a 核对**一致**，无冲突（详见 🔵）。

---

## 🔴 冲突

### 🔴-1 静默续期与既定启动链的顺序直接相抵；改哪一处、怎么改，草稿未交代

- **[问题陈述]** 草稿子项 5 要求「启动链第二步（当前 = LoginScreen → SignInAsync）改为：先读凭据文件 → 有效则 `RefreshTokenAsync()` 跳过 LoginScreen」。
  ✗ `systems/architecture.md` 总则 4（L164）把启动链写死为 **`ContentService.InitializeAsync` → `LoginScreen` → `AccountService.SignInAsync` → `ContentService.RefreshFlagsAsync` → `SyncService.InitializeAsync` → `ProfileService.Hydrate` → `MainMenu`**。
  ✗ `systems/services/account-service.md` L77：「本服务实现 `IBootstrappable`（**启动链第二步，`LoginScreen` 之后**）」。
  凭据探测 + `RefreshTokenAsync` 必须发生在 `LoginScreen` **之前**，而 account-service 的初始化点被明写在 `LoginScreen` **之后** —— 谁在服务尚未 `InitializeAsync` 时读那个文件、调那个方法？草稿没有回答，且**它的 `targets:` 里根本没有 `architecture.md` 总则 4 与 account-service 的 L77**（只列了 architecture 的 `user://cache/` 版本判据回链）。照草稿原样落笔 ⇒ 两份文档当场互相矛盾。
- **选项**
  - **(a) `AccountService.InitializeAsync` 上提到 `LoginScreen` 之前**，其内部做「读文件 → 尝试刷新」；`LoginScreen` 降为**条件步**（刷新未成功才呈现）。后果：总则 4 的序列改写为 `Content.Init → Account.Init（含静默续期）→ [LoginScreen 条件呈现]→ Content.RefreshFlags → Sync.Init → …`；account-service L77 改为「启动链第二步，`LoginScreen` **之前**」；`deviceId` 那一节「时机 = 惰性 …… 登录屏之前没有降级落点」的措辞需一并复核（降级落点现在有了 = 回落登录屏）。
  - **(b) 新增一个独立的「凭据探测」启动步**，夹在 `Content.Init` 与 `LoginScreen` 之间，account-service 的 `IBootstrappable` 位置不动。后果：启动链多一步（草稿宣称「阻塞点数量不变」仍成立，但**步数变了**）；探测步必须能调 account-service 的方法，等于 account-service 事实上已可用 —— 与 (a) 的差别只是叙述，实现上更绕。
  - **(c) 保持 `LoginScreen` 恒为首屏**，在其上做「静默续期中…」的过场态，成功即自动前进。后果：`ux/screen-flow.md`「登录屏 = 应用首屏」**一字不改**，UX 改写面归零；代价是首屏必然渲染一次（含循环视频加载），回头客每次启动多看一眼登录屏。
- **推荐 (a)**，理由：`IBootstrappable` 的既有语义就是「Bootstrap 屏幕按固定顺序驱动各服务的 I/O」，静默续期正是 account-service 自己的 I/O，放进它自己的 `InitializeAsync` 不新增任何结构；(b) 是同一件事多包一层；(c) 与取向 3 已裁决的意图（跳过 LoginScreen）实质相反 —— 它把「跳过」降级成「快速掠过」，但玩家仍会看见首屏闪一下，这正是取向 3 要消掉的东西。

### 🔴-2 「静默续期绕过强更闸门」——本库对闸门位置的记载与后端契约**互相矛盾**，缺口比草稿说的更大

- **[问题陈述]** 草稿子项 5 末条 + 张力 3 称「闸门仍只在 `signin` 判定一次」，并把该缺口登记为「供用户决定是否作后端待答项」。**实地核实的结果是：本库三处明写闸门在「登录 / 启动 pull」两点触发，而后端契约明写 pull 不判闸门。**
  - ✗ `systems/architecture.md` L291：「硬阻塞仍然只有两处 …… `auth.session_revoked`（被挤下线）与**登录 / 启动 pull 点**的 `client.version_unsupported`」
  - ✗ `ux/error-and-blocking-ux.md` L247 三档表 ③ 强更：触发 = 「`client.version_unsupported`（**登录 / 启动 pull**）」；L286 阻塞屏变体表同款措辞
  - ✗ `systems/services/sync-service.md` L99 不变式 ①：「阻塞点是穷举的四处：**登录 / 启动 pull 的版本闸门** …」
  - ✓ **权威（跨库判据以 `contracts/` 为准）**：`backend-design-documents/contracts/profile-sync.md` §2 L50 **「pull 侧不做版本闸门。…… 后端 pull 原样返回、不判定、不拒绝 …… 由 `signin` 的 `client.version_unsupported` 独占；让 pull 也判一次即出现两个闸门、两套阈值。」**；`contracts/auth.md` §5 L192–193 佐证（`signin` 是 auth 域唯一落地点，`refresh` 永不返回）。
  - **后果**：本库那三处「启动 pull 也会拦」的记载**是错的**。启动 pull 上唯一会走「需更新」变体的是**本地迁移器**发现「云端 `schemaVersion` 高于客户端支持上界」——那是**存档 schema 维度**，与协议维度的 `minAppVersion` 提升**完全无关**。于是：静默续期落地后，一个吃着 30 天滑动续期的旧客户端，**在协议维度上永久不经过任何闸门**，直到它主动登出或 token 被吊销。草稿把这条缺口说小了。
- **选项（两个决定，须一并裁）**
  - **② 客户端侧是否自己收口**
    - **(a) 不收口，纯登记**（草稿原意）：客户端不做任何周期性强制 re-signin；收口手段全在后端（滑动续期上限、强制 re-signin 周期）。后果：`open-questions/cross-boundary.md` 加一条，**并在 `backend-design-documents/` 落一条对称承接项**（铁律：不允许只改一侧就宣称收口）。
    - (b) 客户端自加一条「距上次 `signin` 超过 N 天则不走静默续期、强制回登录屏」。后果：新增一个客户端本地时间判断——**与「设备时钟不可信」既定纪律正面相抵**（同一条理由已被草稿用来否决 `refreshExpiresAtUtc`），且客户端擅自定 N 会与后端的 TTL 策略漂移。
    - (c) 暂缓落地静默续期直到后端给出收口手段。后果：推翻取向 3 的已裁决，「跨启动保留」重回零消费者。
  - **推荐 ①-(a) + ②-(a)**：①-(a) 是跨库纪律的机械结论（契约为准，本库跟改）；②-(a) 因为 (b) 撞既定纪律、(c) 推翻已拍板项，而 (a) 恰是「客户端语义已定、只剩服务端如何兑现 ⇒ 归后端库」这条归属判据的标准形态。

---

## 🟠 含糊

### 🟠-1 取向 1（不存 `refreshExpiresAtUtc`）是 `[采纳推荐 — 待复核]`，未经用户当面拍板
按批量编排铁律 ①，`[采纳推荐 — 待复核]` **不当作用户拍板**，须进合并 interview。
- (a) 不存（推荐 · 现状）：客户端无任何一处可合法据它分支（设备时钟不可信），存一个不许读的字段只会等着被人读。后果：`auth.md` §8 signin 应答里的 `refreshExpiresAtUtc` 客户端**读取即丢弃**，这一句要在文档里明写，否则读者以为漏了。
- (b) 存但标注「仅诊断」：设置屏可展示「登录有效期至 …」。后果：第一个把它当判据用的人不会知道自己踩了时钟线。
- (c) 存并据它跳过必然失败的刷新：省一次请求，快钟设备凭空强制重登。**草稿自己明确不推荐。**
- **推荐 (a)**，理由同草稿：与「不存 access token」「`deviceId` 文件里刻意没有 `accountId` 这一格」同一手法——**让错误在结构上写不出来**。

### 🟠-2 取向 2（明文落盘）同为 `[采纳推荐 — 待复核]`，且草稿引用的依据存在**威胁模型换轨**
- **[问题陈述]** 草稿以「本作客户端侧已明确不承诺防作弊（`content-manifest.md` 信任根一节的同一条威胁模型）」为明文落盘背书。核实：该边界的客户端权威在 `systems/services/content-service.md` L176–178 ——「信任根是固定公钥（pinned）…… **威胁模型只到『防误 / 防随手改』**」「不承诺防作弊（改内存 / 改二进制不在防御范围）。**纯 PvE + PlayerPower 已被接受为轻度提升、影响平衡可容忍，反作弊无收益**」。
  该论证的成立前提是**「作弊者只损害自己的体验」**。refresh token 的泄漏面不是这一类：被窃取的是**别人的账号**（云端权威主档 + 已购权益 `entitlement`），受害者不是作弊者本人。**把「不承诺防作弊」外推到「不承诺凭据保密」是一次跨类别外推，被引用的那段文字不支持它。** 草稿未讨论这一点。
  另注：草稿写的 `content-manifest.md` 是**后端库**的文件名，本库对应文档是 `systems/services/content-service.md` —— 落笔时不要照抄这个路径。
- (a) 明文 `user://cache/`（草稿推荐 · 现状）：依托各平台应用沙箱；泄漏面由后端 rotation + 窗口外重放即吊销全部会话兜住；不改契约，日后可换实现而无需两侧配合。**但须在文档里把理由改写为「依托沙箱 + 后端 rotation 兜底」，不得再挂靠「不承诺防作弊」那条。**
- (b) 明文 + 在文档里显式登记一条**已知残余风险**（root / 越狱设备、备份提取、共享设备），并在 `open-questions/` 留一条「平台密钥库后置评估」。后果：与 (a) 实现完全相同，只多一条留痕。
- (c) 现在就上平台密钥库（Android Keystore / iOS Keychain）：需平台插件、四端导出（含 Web）行为不一致。
- **推荐 (b)**：实现成本与 (a) 相同，但把「为什么明文是可接受的」写在正确的理由上，并让「后置而非否决」这句话有一个真实的承接点（草稿只在正文里说了一句，没给落点）。

### 🟠-3 草稿宣称「硬阻塞只有既定两处」，而本库对这「两处」有**三种互不相同的枚举**
- 草稿 L29 / L113：「既定两处 = **启动 pull 失败、被后端明确挤下线**」
- `systems/architecture.md` L291：「两处 = **`auth.session_revoked`、登录 / 启动 pull 点的 `client.version_unsupported`**」（迁移失败落在 pull 那一处之内）
- `systems/services/sync-service.md` L99：「阻塞点是**穷举的四处**：登录 / 启动 pull 的版本闸门、被挤下线、启动 pull 失败本身、购后 pull 的主菜单内重试」
- **问题**：草稿子项 5「因此不新增任何硬阻塞点」这句话的可核对性，取决于以哪一份枚举为准。落笔时若照抄草稿的措辞，等于在 account-service 里固化第三种读法。
- (a) 落笔时不复述枚举，只写「本节不新增阻塞点」并回链 `sync-service.md` 不变式 ①（推荐）。(b) 顺手统一三处枚举 —— 改动面外溢到三份文档，且与 🔴-2 的改写耦合。(c) 照草稿原样写。
- **推荐 (a)**：单一权威 + 回链，符合「回链而非复述」；(b) 是一次独立的收口 session 的事。

---

## 🔵 可推演（无需回答）

1. **落点 `user://cache/refresh-token.json` 与四条不合并的否决**：逐条核对 `account-service.md` L33–41（`deviceId` 一节）与 `sync-service.md`、`content-service.md` 的归属，全部成立。其中「不与 `device-id.json` 合并」在 `account-service.md` L39 已是既定硬约束、措辞一致。
2. **带 `schemaVersion` 而 `device-id.json` 不带**：`systems/architecture.md` L95 判据原文「**判据是这份文件的结构会不会增长到需要逐版迁移**」+「单字段的设备维度小文件不带版本 …… 丢弃 = 一次假换设备」。本文件多字段 + 丢弃代价仅「多登一次」⇒ 带版本成立。草稿要求把这条**对照**明写进文档，依据充分。
3. **`accountId` 必须在**：与 `sync-envelope.json` / `flags.json` 同纪律（`sync-service.md`、`content-service.md`），且与 `device-id.json` 刻意没有这一格**并不矛盾**（两者失效口径相反）——`account-service.md` L34 已把那一侧的理由写全。
4. **六条失效路径**逐条有据：#4 #5 对位 `contracts/auth.md` §4（rotation，旧的立即失效）与 §4a（同设备重登原地替换）；#2 对位 `account-service.md` L11–22 的两条分流。
5. **落盘失败不沿用 `deviceId` 的「先落盘成功、内存里才认」**：`account-service.md` L43 那条的理由原文是「**这个症状永不自愈**」，判据本就是自愈性而非「是不是凭据」，故不同处置不构成不一致。草稿要求把这条判据与规则同处明写，正确。
6. **归属 `AuthManager` 私有、不出 API 面、文件 I/O 不沉进 `HttpAccountBackend`**：`account-service.md` L52 的理由（离线实现也要能拿到、文件 I/O 不该在传输层）逐字适用；与 `contracts/auth.md` §2 的措辞差异属客户端内部分层，不改任何报文语义 ⇒ 不构成契约变更，不要求后端改写（草稿张力 2 判断正确）。
7. **API 面零改动、`Session` 一字不改、存档 schema 零影响** ✓（`account-service.md` L91、`contracts/auth.md` §2 L78）。
8. **`ux/onboarding.md` 无需任何改动**（**已实地核实**）。该文全篇未出现「登录屏 = 首屏」这类陈述；L7 只写「首次进入需先登录账号方可游玩」，L8–10 讲渠道入口与绑定落点，首玩者必然无凭据 ⇒ 静默续期路径对它零影响。**草稿 `targets:` 里的「`ux/onboarding.md`（仅当取向 3 取 A）」可以直接划掉。**
9. **`refresh` 端点错误码只有两条**（`auth.session_revoked` · `server.unavailable`，`contracts/auth.md` §8 L304），故草稿子项 5 的启动期三分支（成功 / revoked / 网络失败）**在报文层面是穷举的**，不存在第四条路径。

---

## 拟改动文档清单（供跨草稿核对）

| 路径 | 要点 | 与其他草稿撞车风险 |
|---|---|---|
| `systems/services/account-service.md` | 新增一节「refresh token 的持有与失效」（与「`deviceId` 的生成与持久化」并列）：落点 · 字段表 · 带版本的对照理由 · 六条失效路径表 · 读写失败处置三行表 · 「判据是失败症状是否自愈」· `AuthManager` 私有；**划掉「待决问题」第 2 条**；**L77 的「启动链第二步，`LoginScreen` 之后」按 🔴-1 裁决改写**；L42 `deviceId`「登录屏之前没有降级落点」措辞复核 | **中** —— `solution-draft-echo-validation-scope.md` 触及 `account-info.md` 而非本文件，但同批若有草稿动 account-service 需并给同一 worker |
| `systems/architecture.md` | **两处，务必分清**：① L95 `user://cache/` 版本判据的**逐份落点回链**追加 `refresh-token.json`（草稿原 target）；② **L164 总则 4 的启动链序列**按 🔴-1 裁决改写（草稿未列，但不改就与 account-service 矛盾）；③ 若 🔴-2 取 ①-(a)，**L291「登录 / 启动 pull 点的 `client.version_unsupported`」须改为只在登录点** | **高** —— 本文件是全批最可能被多个草稿同时写的一份（`flags-fetch-throttle` 触及启动链与 flags 步、`echo-validation-scope` 触及总则 7 一带）。**建议由 orchestrator 划为串行 / 单 worker 独占** |
| `ux/screen-flow.md` | L7「完整前置流程:登录屏 → 主菜单 → …」与 **L9「登录屏(应用首屏)」两句**改写为「**未持有有效凭据时**的首屏」（取向 3 取 A 的连带，已裁决）。**是两句不是一句**——L7 的流程行同样把登录屏写成无条件首步 | 中 |
| `ux/error-and-blocking-ux.md` | 若 🔴-2 取 ①-(a)：L247 三档表 ③ 与 L286 阻塞屏变体表的「（登录 / **启动 pull**）」改为只写登录点；「存档读取失败 / 需更新（迁移路径）」一行保持不动（那是 schema 维度，与协议闸门无关，须在改写时明确区分） | 中 |
| `systems/services/sync-service.md` | 若 🔴-2 取 ①-(a)：L99 不变式 ①「登录 / 启动 pull 的版本闸门」改为「登录点的版本闸门」；L332 迁移表不动 | **高** —— 其他草稿（`echo-validation-scope`、`combat-runtime-counter-persistence`）大概率也写这份 |
| `vision/scope.md` | L12「前置屏幕外壳：登录屏（…）→ 主菜单」是同一事实的**第三处复述**。建议随 screen-flow 一并轻改或改为回链；不改则留下一处与新设计不符的陈述 | 低 |
| `ux/onboarding.md` | **不改**（见 🔵-8） | — |
| **对侧库** `backend-design-documents/` | 🔴-2 的对称承接项：一条「静默续期使旧客户端可长期不经协议维度闸门，收口手段（滑动续期上限 / 强制 re-signin 周期）待定」，落 `open-questions/01-contracts.md` 或 `contracts/auth.md` §5 的待办段，**回链本库 account-service 的新一节**。铁律：不允许只改一侧就宣称收口 | — |

> **不得触碰**：`open-questions.md` 的「derive 就绪度」小节（`/assess-derive-readiness` 独占）。

## 待移出的 open-questions 条目

- `open-questions/05-service-contracts.md` **L26 整条**：「**refresh token 的客户端持有形态未落笔（本次归集 · 此前未进清单）**」→ 本次答定，归档去向 `systems/services/account-service.md` 新增节。
- `systems/services/account-service.md`「待决问题」**第 2 条**（同一问题在主题文档中的登记）→ 划掉。
- **新增（非移出）**：`open-questions/cross-boundary.md` 一条 —— 「静默续期绕过协议维度强更闸门」，指向 `systems/services/account-service.md` 与对侧 `backend-design-documents/contracts/auth.md` §5。
- answer log 文件名（供 orchestrator 统一建档）：`answer-logs/log-refresh-token-client-storage.md`。
- 台账行（orchestrator 代笔）：
  - `inbox/_index.md` 已归档表：`solution-draft-refresh-token-client-storage.md | solution-draft | 2026-08-22 | handoffs/2026-08-22-<slug>.md | answer-logs/log-refresh-token-client-storage.md`
  - `answer-logs/_index.md`：`log-refresh-token-client-storage.md | 2026-08-22 | inbox/solution-draft-refresh-token-client-storage.md | 1`
  - `handoffs/_index.md`：新行，`topic` = `systems/services/account-service` · `ux/screen-flow` · `systems/architecture`

## 越界发现（不在本分片处理）

1. **本库三处对「强更闸门在哪触发」的记载与后端契约相冲突**（🔴-2 详列）。这是**先于本草稿就存在**的跨库漂移；本草稿只是第一个踩到它的。若用户裁定不随本批修正，须单独登记为一条待答项——**不要静默留着**，因为它让本库文本对一个并不存在的安全网做出承诺。
2. **「硬阻塞只有两处」在本库有三种枚举**（🟠-3）。全库收口是独立 session 的事，本分片只做「不复述、回链」的规避。
3. `systems/services/account-service.md` L127 待决项正文中夹带的一大段「硬约束 + 落点形态」复述，在本次答定后会与新增节重复；按「活文档只保留最新设计」应随划掉待决项一并删净，不要留半句。

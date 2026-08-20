# Phase A — device-id

- 输入：`game-design-documents/inbox/solution-draft-device-id-provisioning.md`（`status: decided`）
- 目标库：`game-design-documents/`（orchestrator 已定）
- 本文件只读产出，未写入任何设计库文件。

## 一句话摘要

`deviceId` 由客户端生成 `Guid.NewGuid().ToString("N")`（32 位小写 hex），惰性落 `user://cache/device-id.json`（单字段、**刻意不带 `accountId`**），归 `account-service.AuthManager` 私有、不出任何 API 面、不进 `SignInAsync` 签名，三处失败一律 `PushWarning` 且**先落盘成功再上行**；五种情形（清缓存 / 重装 / 多设备 / 同设备多账号 / 同设备重登）的语义逐行与后端 `contracts/auth.md` §4a 对位。

已逐字核对的既有权威：`systems/services/account-service.md`（API 表 · 待决问题）· `systems/architecture.md`（总则 3/4 · 纪律的可执行化 · L92 `user://cache` 纪律）· `systems/player-profile/_index.md` · `systems/services/sync-service.md` L197 · `systems/services/content-service.md` L126 · `ux/error-and-blocking-ux.md` L214 · `systems/common-properties.md` §存档版本化与原子写入 · `decisions/ADR-0003` · `.claude/rules/null-check-rules.md` · `backend-design-documents/contracts/auth.md` §4a（L137–186 · L273 · L494）。

## 已定案项（用户已裁决，不进 interview）

| # | 项 | 定案 |
|---|---|---|
| ① | 是否提供只读 `deviceId` 展示口 | **不提供**。`AuthManager` 私有，无公开 getter。代价照录：客服排障无法让玩家直接报设备号 |
| ② | 取值形态 | **`Guid.NewGuid().ToString("N")`**，32 位小写 hex 无连字符，校验式 `^[0-9a-f]{32}$` |
| ③ | `user://` 原子写实现的归属 | **抽成不属任何服务的共享静态工具**（如 `AtomicJsonFile.TryRead<T>/TryWrite<T>`），现存五处写入方同用一份；`device-id.json` 照此落地、不自带实现 |
| 跨草稿 | `deviceId` 与 `locale` 是否共用一份 `user://cache/` 文件 | **各自一份，不合并**（`device-id.json` 独立成立） |
| 越界 | refresh token 是否与 `deviceId` 同文件 | **不得同文件**（失效口径恰好相反） |

以下建议项均已被草稿正文定死、无待决点，落笔时**照写**：客户端生成而非后端下发 · 落点 `user://cache/device-id.json` 单字段无 `accountId` · `AuthManager` 私有唯一读写方 · 惰性时机 · 先落盘再上行 · 三处失败 `PushWarning` · `SignInAsync` 签名逐字不变 · 五情形表 · 存档 schema 零影响 · 后端零新增义务。

## 🔴 冲突

### 🔴-1 `device-id.json` 明写「无 `schemaVersion`」✗ 库内三处「`user://cache/` 一律带 schema 版本 + 迁移路径」的全称纪律

- 草稿「具体形态」：`schema` = `{ "deviceId": string }`，**仅此一字段（无 `accountId`、无 `schemaVersion` —— 单字段无迁移面）**；而草稿自己的「约束」一节又把「schema 版本」列进 `user://cache/` 的既有纪律，**同一份草稿内前后不一致**。
- 既有权威原话要点：
  - `systems/architecture.md` L92：「本地 `user://cache/` 仅缓存，**原子写 + schema 版本 + 迁移路径**。归属 sync-service。」
  - `systems/common-properties.md` §「存档版本化与原子写入」：对本地缓存与上行负载**都原子、带版本**。
  - `.claude/rules/state-save-rules.md`：「**给存档加版本**：带一个 schema 版本字段和一条迁移路径。」
- 反向先例：`ux/error-and-blocking-ux.md` L214 的 `dismissed-recommended-version.json` **确实是单字段、未提 `schemaVersion`** —— 即该全称纪律已有一处未被兑现，本方案会成为第二处。
- 同批张力：并行分片 `game-setting` 已为 `device-settings.json` 定下「**不认识的 `schemaVersion` 整份丢弃**」；若 `device-id.json` 也带版本并沿用该口径，一次版本不认 = **重新生成 = 一次假换设备 = 后端假挤下线**，正是两份草稿共同要防的事。

选项：

- **(a) 不带 `schemaVersion`，并同批修订 `architecture.md` L92 的全称措辞**（改为「原子写；**带版本的缓存**须有迁移路径」，`common-properties.md` 同源一句同改）。后果：`device-id.json` / `dismissed-recommended-version.json` 两处单字段文件不再是纪律的反例；改动面 +2 份文档（其中 `architecture.md` 与 W1/W5 分片撞面）。
- **(b) 带 `schemaVersion`，但明写「版本不认识时保留 `deviceId`、只重置其余」**。后果：`user://cache/` 下出现两条相反的版本处置口径（设置文件整份丢弃 vs 本文件保留），须在两份文档各写一句解释差异；且单字段文件的迁移面为空，这一格纯属仪式。
- **(c) 不带，且不动 `architecture.md`。** 后果：留下第三处「文档写全称、实现各写各的」漂移 —— 与 08-17 那次「刷新失败视同断线」三处同源措辞漂移同型（教训已记进 `open-questions/update-log.md` L103）。

**推荐：(a)。** 理由：既有先例已经这么做了（`dismissed-recommended-version.json`），(b) 会把一条已知会造成「假换设备」的口径引进本文件，(c) 明确违反本库刚刚吃过亏的「同源措辞同批改齐」。

### 🔴-2 裁决③ 的落笔面与本分片的写入分区不符（跨分片写入面冲突，须 orchestrator 裁定）

- 裁决③（抽 `AtomicJsonFile` 共享静态工具）**同时被 `device-id` 与 `game-setting` 两份草稿写作已定案**，两份草稿都写着「落笔时须一并更新」牵动的既有文档。
- 实际落笔面：`systems/services/sync-service.md` L197（`LocalCacheManager` 职责表那一行「`user://` 原子写」）· `systems/services/content-service.md` L126（`flags.json`）· `ux/error-and-blocking-ux.md` L214（`dismissed-recommended-version.json`）· `systems/services/account-service.md`（本方案）· `player-profile/game-setting.md`（`device-settings.json`），并**很可能须在 `systems/architecture.md` 新增一条「不属任何服务的共享静态工具」的形态条目**（总则 3 只规定了服务门面骨架，库内目前没有这一类构件的落点）。
- 而 `plan.md` 给 device-id 分片登记的写入面只有 `services/account-service · player-profile/_index`，**漏了上述五处**；这五处分散在 W1 / W2 / W5 三个波次里 ⇒ 按铁律③「绝不让两个并行 worker 写同一份文件」，当前波次划分不成立。

选项：

- **(a) 指定单一 owner 分片承接工具本体**（建议给 `game-setting`，它的既定写入面已含 `sync-service` / `error-and-blocking-ux` / `architecture`），device-id 与其余分片只在各自文档里写一句「原子读写走共享静态工具（回链）」，不重复定义形态。
- **(b) 单独排一个收尾波次**由 orchestrator 亲自落工具本体，各分片只留回链。
- **(c) device-id 分片承接。** 后果：本分片被迫写 4–5 份不属于它的文档，且与 W1/W2/W5 全面撞面。

**推荐：(a)，其次 (b)。** 同时需用户/orchestrator 裁一件事：**工具本体写进哪份文档**（`architecture.md` 新增条目 / `sync-service.md` 附段 / 新建 `systems/local-cache-io.md`）与**是否改写 `sync-service.md` L197 那行 manager 职责**（`LocalCacheManager` 从「实现原子写」降为「调用工具」）。

## 🟠 含糊

### 🟠-1 `systems/player-profile/_index.md` 的「不进 `PlayerProfile` 的三样」是否补成四样

- 草稿「后果」明写此项**留给 `/analyze-new-ideas` 判断**（「本草稿倾向补上」），**不在用户已裁的三项之内** ⇒ 仍是待决取向。
- 现状原话（该文档 L29）：「**不进 `PlayerProfile` 的三样：** `baseRevision` / `revision`（传输层元数据）· `schemaVersion`（存档 / 传输的信封字段）。**三者进 Profile 都会自指。**」
- 张力：现有三样的排除判据是「**进 Profile 会自指**」；`deviceId` 不自指，它的排除判据是「账号级云端主档 ⇒ A 设备读到 B 设备写的值 ⇒ 多设备裁决失效」。补第四样即**放宽该小节的判据**（从「自指」放宽为「传输层 / 设备维度元数据一律不进」）。
- (a) 补成四样并把小节判据改写为两条并列（自指 · 设备维度）；(b) 不补，只留在 `account-service.md`；(c) 补成四样但只加一句「设备维度，非账号数据」不动判据措辞。
- **推荐 (a)** —— 那张表的价值在于被后来者当排除清单读，判据说清比条目多一条更重要。
- **写入面警告：** `player-profile/_index.md` 同时是 `costkey` / `codex` / `game-setting` / `bundle` 四个分片的写入面（`plan.md` 已登记），本项若取 (a)/(c) 须并进 W2 的同一 worker，或由 orchestrator 统一落笔。

### 🟠-2 首次生成（文件不存在）是否留一行日志

- 草稿定：「文件不存在 → 生成 → 落盘 → 使用（首次运行的正常态，**不告警**）」。
- 张力：`.claude/rules/null-check-rules.md` 写「对缺失情况既不报错也不警告的查找是一处缺陷」「绝不静默通过」；`Context.md` 要求在关键状态转换处做有意义的日志。而「首次运行生成设备号」恰是一次不可回溯的一次性事件 —— 它静默发生，日后排查「玩家为什么被判成新设备」时无任何痕迹。
- (a) 首次生成走 `GD.Print("[Auth-DeviceId] generated new device id")`（信息级，不是 warning，不违反「正常态不告警」）；(b) 完全静默（照草稿）；(c) 首次生成也 `PushWarning`。
- **推荐 (a)** —— 它同时满足「正常态不该 warning」与「关键状态转换要留痕」，成本一行。

### 🟠-3 是否同批更新对侧库 `backend-design-documents/contracts/auth.md` 的收尾一句

- 该文件 L494 现写：「余下两点仍在客户端侧待落：**`deviceId` 的生成与持久化落点** · refresh token 的客户端持有形态……**本库不催办** —— 它们登记在客户端库自己的 `open-questions/cross-boundary.md`。」
- 本次落笔后这句话有两处失真：① `deviceId` 那一半**已落**；② 客户端 `open-questions/cross-boundary.md` L27 明写这两条**不是**跨边界承接项、登记在 `account-service.md`（该句从写下起就与客户端库不符）。
- 草稿判定「后端零改动、不开对侧库草稿」——就**协议义务**而言正确（契约规则一字不改）；但 `.claude/rules/design-library-routing.md`「对称落笔」要求跨边界改动在两侧都留痕。
- (a) 只改 L494 那半句为「`deviceId` 落点已由客户端落定，见 `game-design-documents/systems/services/account-service.md`（回链，不复述）」，`refresh token` 那半保留并改指 `account-service.md`；(b) 完全不动后端库（照草稿）；(c) 在后端库另开一份 handoff。
- **推荐 (a)** —— 一行回链、零规则复述，代价最小且消除两侧互指错位；(c) 对一句状态陈述明显过重。

## 🔵 可推演（无需回答）

1. **客户端生成、不由后端下发。** 依据：`backend-design-documents/contracts/auth.md` L182 明写「生成与持久化落点归客户端」；且 `deviceId` 是 `signin` 请求本身的必填字段（同文件 L273），首次 signin 前无会话，后端下发须新开无鉴权端点并把同一持久化问题原样推后一步。
2. **五情形表逐行与后端契约对位无误。** 已逐条比对 `contracts/auth.md` L156–172（写入 `(accountId, deviceId)` · 吊销其余会话标 `SignedInElsewhere` · 同 `deviceId` 重登原地替换 · 60 秒幂等回放窗口）。草稿只列对位、不复述规则，符合「回链而非复述」。
3. **`SignInAsync` 签名逐字不变。** 已与 `account-service.md` API 表第 2 行逐字比对：`Task<OpResult<Session>> SignInAsync(LoginChannel channel, LoginCredential credential, CancellationToken ct)` 一致；`Session` / `ChallengeInfo` / `LoginChannel` / `ChallengePurpose` 四型不动。
4. **`AuthManager` 私有 + 无公开 getter = 纪律阶梯第 1 级。** 依据 `systems/architecture.md`「纪律的可执行化」两条选级判据：「不得把本地判断挂在 `deviceId` 上」属「能上线且线上不可见」，必须做到第 1/2 级；`internal sealed` manager 是既有同款手法。
5. **三处失败一律 `PushWarning` 而非 `PushError` + 抛。** 依据 `.claude/rules/null-check-rules.md` 的「可选（可优雅降级）→ 警告 + 安全默认值」：`deviceId` 永不参与鉴权（契约 L178），缺它不阻断任何流程。
6. **落点与 `dismissed-recommended-version.json` 逐条同形。** 已核 `ux/error-and-blocking-ux.md` L214：单字段 · 原子写 · 跨启动保留 · 不进存档 / 不进 Profile / 不上云 · **不按 `accountId` 分区**（「它是设备维度的呈现状态，不是账号数据」）。
7. **不落 `sync-service.LocalCacheManager` 的两条理由成立。** 边界纪律见 `systems/architecture.md` 总则 3；启动顺序见总则 4 的链：`ContentService.InitializeAsync → LoginScreen → AccountService.SignInAsync → ContentService.RefreshFlagsAsync → SyncService.InitializeAsync → ProfileService.Hydrate → MainMenu` —— 签名那一刻 sync-service 确未初始化。
8. **落笔时不要写启动链序号。** `account-service.md` 现有 API 面小节写「启动链**第二步**，`LoginScreen` 之后」（只数服务），草稿写「**第三步**」（数上 `LoginScreen`）—— 两种数法都自洽，但新小节再引入一个序号会出现第三种读法。**写相对位置**：「在 `LoginScreen` 之后、`ContentService.RefreshFlagsAsync` 之前」。
9. **草稿「不进 `GameSetting`」的第一条理由已在本批内失效，落笔须换掉。** 草稿写「该层设备本地 vs 账号级的切分本身是未答定的待决问题」，而并行分片 `game-setting` 已裁定 `locale` 归设备本地、`device-settings.json` 成立 ⇒ 该前提不再成立。结论不变，改写为两条仍成立的理由：**它不是玩家可见的设置项** · **两者失效口径不同（已裁各自一份文件）**。
10. **PIPL / 渠道审核这条排除依据成立。** `decisions/ADR-0003` Consequences 原话含「须正面处理实名 / 防沉迷 / **PIPL** / 渠道审核 / 账号注销 / 数据导出」。
11. **存档 schema 零影响、零迁移**，不进 `PlayerProfile` / `CharacterProfile`（除 🟠-1 那张排除清单可能加一行外，无字段变更）。
12. **溯源三条自查项（落笔前必守）：** 活文档正文不得出现「2026-08-18 已裁 / 跨草稿裁决 / 本草稿倾向 / 越界发现 / 取 A」等过程坐标，也不得出现日期戳与 `handoffs/*.md` 路径（`Source:` 行除外）；「备选方案已否决」的八条中，**理由仍承重的**（硬件标识的合规成本、由 `accountId`/`AccountSeed` 派生会让唯一键退化、与 `sync-envelope.json` 合并会被连坐清掉、与 refresh token 同文件会逼出「清一半留一半」）改写成**正面陈述**保留，不写它推翻了谁。

## 拟改动文档清单与各自新增要点

| 文档 | 新增 / 修改要点（供跨草稿核对） | 归属 |
|---|---|---|
| `handoffs/2026-08-19-device-id-provisioning.md`（新建） | 本分片独占。Intent = 生成方 / 取值形态 / 落点 / 归属 / 时机 / 失败语义 / 五情形表；Clarifications 记 interview 裁决 | worker 独占 |
| `systems/services/account-service.md` | ①「意图」新增小节「`deviceId` 的生成与持久化」（七项 + 校验失败三行表 + 五情形表 + `AuthManager` 私有、不出 API 面、不进 `SignInAsync` 签名）；②「待决问题」删除「`deviceId` 的生成与持久化落点」整条，**保留 refresh token 半条**并追加硬约束「不得与 `device-id.json` 合进同一文件 —— 两者失效口径相反」；③ API 面小节不改任何签名 | worker 独占（本分片） |
| `systems/player-profile/_index.md` | ⟨待 🟠-1⟩ 「不进 `PlayerProfile` 的三样」→ 四样 + 判据改写 | **与 costkey / codex / game-setting / bundle 分片撞面** |
| `systems/architecture.md` | ⟨待 🔴-1⟩ L92「`user://cache` … 原子写 + schema 版本 + 迁移路径 …… 归属 sync-service」两处措辞（全称版本要求 + 归属，现已有四处非 sync-service 写入方）；⟨待 🔴-2(a)⟩ 可能新增「共享静态工具」形态条目 | **与 costkey / profile-change / game-setting / arch-residuals 分片撞面** |
| `systems/common-properties.md` | ⟨待 🔴-1(a)⟩ §存档版本化与原子写入 的同源一句同批改齐 | **与 costkey 分片撞面** |
| `systems/services/sync-service.md` | ⟨待 🔴-2⟩ L197 `LocalCacheManager` 职责行改为「调用共享原子读写工具」 | **与 codex / game-setting / bundle / arch-residuals 分片撞面** |
| `systems/services/content-service.md` | ⟨待 🔴-2⟩ `flags.json` 一句改指共享工具 | **与 pickmany / arch-residuals / translation 分片撞面** |
| `ux/error-and-blocking-ux.md` | ⟨待 🔴-2⟩ `dismissed-recommended-version.json` 一句改指共享工具 | **与 game-setting / bundle / translation 分片撞面** |
| `backend-design-documents/contracts/auth.md` | ⟨待 🟠-3⟩ 收尾「余下两点仍在客户端侧待落」半句更新为回链 | 对侧库；与 bundle 分片的跨库面相邻 |

**明确剔除（本技能第 10 步禁止触碰）：** 草稿 `targets` 与「后果」列的 **`open-questions.md`（derive 就绪度表 `account-service.md` 一行的卡点减一 · 「建议的 derive 顺序」第 8 项的 signin 上行待填口关闭）**。已核实：该表在 L65、derive 顺序第 8 项在 L117，**两者同属 `## derive 就绪度` 小节**（`### 建议的 derive 顺序` 是其子节），由 `/assess-derive-readiness` 独占写入。**本次一律不动**，就绪度重估由用户在时机成熟时手动跑那个技能。

**交给 orchestrator 代笔的台账行（worker 不写）：**

- `handoffs/_index.md` 置顶一行：`2026-08-19-device-id-provisioning | 2026-08-19 | systems/services/account-service | distilled | systems/services/account-service.md（+ 视裁决 systems/player-profile/_index.md）`
- `inbox/_index.md`：待处理表删 `solution-draft-device-id-provisioning.md` 一行；已归档表加 `solution-draft-device-id-provisioning.md | solution-draft | 2026-08-19 | handoffs/2026-08-19-device-id-provisioning.md | answer-logs/log-device-id-provisioning.md`
- `answer-logs/log-device-id-provisioning.md`（新建，1 条）：`**deviceId 的生成与持久化落点** → 客户端生成 32 位小写 hex（Guid "N"），落 user://cache/device-id.json 单字段无 accountId，归 AuthManager 私有、不出 API 面、不进 SignInAsync 签名，三处失败一律 PushWarning 且先落盘再上行（归档去向：systems/services/account-service.md）。同一待决项中 refresh token 的客户端持有形态**仍留在待答清单**，并新增硬约束「不得与 device-id.json 同文件」。`
- `answer-logs/_index.md` 台账追加一行。
- `open-questions/update-log.md` 顶部本次摘要中的 device-id 段。
- **`open-questions/` 分片无需删条目** —— 已逐份核查（`01`–`07` · `cross-boundary` · `deferred-content`），`deviceId` 落点**从未作为条目进入任何分片**，它只登记在 `systems/services/account-service.md` 的「待决问题」里（`cross-boundary.md` L27 明写它「不是跨边界承接项」）。answer log 仍应建（问题确被答定）。

## 越界发现

1. **`sync-service.md` L197 与现实的漂移（非本次引入）。** manager 表把「`user://` 原子写」独家写给 `LocalCacheManager`，而 `flags.json`（content-service）与 `dismissed-recommended-version.json`（UI 层）已各写各的；本方案是第三处、`device-settings.json` 是第四处。裁决③ 正是为此而生 —— 修复归 🔴-2 指定的 owner 分片，本分片不顺手动。
2. **`backend-design-documents/contracts/auth.md` L494 与客户端 `open-questions/cross-boundary.md` L27 互相矛盾**：前者说这两条登记在客户端的 `cross-boundary.md`，后者明写「**不是**跨边界承接项，登记在 `account-service.md`」。属两侧台账错位（本次落笔前就已存在），处置见 🟠-3。
3. **`account-service.md` API 面小节的「启动链第二步」与 `architecture.md` 总则 4 的链条数法不一致**（只数服务 vs 数上 `LoginScreen`）。本分片会触及该文档但**不触及那个小节**，故不顺手改；建议由 orchestrator 记一笔，或在 arch-residuals 分片一并处理。
4. **`plan.md` 给 device-id 登记的写入面偏小**（漏了裁决③ 牵动的 5 份文档），W3 波次（bundle + device-id）在采纳 🔴-2(c) 之外的任何选项前都成立；若采纳 (c) 则 W1/W2/W5 全面撞面。已在 🔴-2 展开。
5. **`refresh token 的客户端持有形态`** 是同一条待决项的另一半，本次**不处理、不关闭**；本方案向它交付一条硬约束（不得同文件）与一份可直接复用的落点形态。它不在本批 10 份草稿的任何一份里 —— 提请 orchestrator 在总报告中点名它仍未办。

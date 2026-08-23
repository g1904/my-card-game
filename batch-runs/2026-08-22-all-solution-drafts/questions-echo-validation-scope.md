# Phase A — echo-validation-scope（跨库）

主库：`game-design-documents/`　对侧库：`backend-design-documents/`
分片草稿：`game-design-documents/inbox/solution-draft-echo-validation-scope.md`（status `awaiting-review`，3 项取向已于 08-22 批量评审全部裁决）
对侧草稿：`backend-design-documents/inbox/solution-draft-echo-validation-scope.md`（同上，3 项已裁决，其中 2 项标 `[采纳推荐 — 待复核]`）

## 一句话意图

把「上行时后端写入字段只能原样回声」从 `entitlement` 一处特例升为**通则**：本库登记受约束的**顶层键**（`accountInfo` · `entitlement`，由后端写入封闭表机械导出）、定死回声值只能取自最近一次 pull 的权威快照、**回声路径不参与读档钳制 / 缺省补齐 / 格式归一化**，并在 `ProfileSyncManager` 组装出口加一处 push 前自检；逐条 JSON path 清单与比较口径的权威留在后端库，本库只回链。

## 跨库前置状态（实地核实结论）

**结论：草稿自称的前置**已经解除**，草稿的「前置依赖」一节内容已过时（stale），若原样提炼会写入一句事实错误。**

| 草稿的断言 | 实地核实 | 判定 |
|---|---|---|
| 「`solution-draft-bundle-grant-ordinal-authority.md`（status `decided`）尚未经 `/analyze-new-ideas` 提炼」 | 该文件已不在 `backend-design-documents/inbox/` 顶层，已在 `inbox/archive/`（mtime 2026-08-22 08:54） | **已提炼** |
| 「`contracts/profile-sync.md` 当前**没有**任何回声校验条款」 | `contracts/profile-sync.md` 已有 **§5c「后端写入路径的回声校验：封闭表的执行点（承重）」**（第 187–201 行），mtime 08-22 08:54；`Source:` 行已登记 `handoffs/2026-08-22-entitlement-echo-and-receipt-idempotency.md` | **已落笔** |
| 「本库 `sync-service.md` 的回链目前指向一处不存在的内容」 | `systems/services/sync-service.md:143` 回链 `backend-design-documents/contracts/profile-sync.md` → §5c 现已存在 | **回链已有效，两侧不再不一致** |
| 后端草稿另称「`bundleRedeemedOrdinal` 白名单行 / `receiptId` 幂等窗口 / 读己所写至今没有一条落进契约」 | 白名单第 156 行已有 `/entitlement/bundleRedeemedOrdinal` 行（含「不受 §5c 约束」）；`receiptId` 幂等见 §7 尾注回链 `purchase.md` §7；§8 读路径要求已登记 | **均已落笔** |
| 后端 `inbox/_index.md` 在办行 | 已自行写明「**前置已解除**（2026-08-22）：…本稿可直接 `/analyze-new-ideas`——它是在那之上的**通则化**」 | **与核实一致** |

**§5c 目前明确留白、且明写「不得先实现」的那一块，正是本对草稿要填的**（`contracts/profile-sync.md:199`）：

> **`/accountInfo` 是同形的第二处**（…由**改昵称**触发）。它的受约束路径清单与非整数路径的比较口径（时间串按时刻还是按字面 · 数组按序还是按集合）**尚未落笔**，见 `open-questions/01-contracts.md`——**在落笔之前不得按字节相等实现**。

⇒ **任务派单里给的三个处置选项（a 只写客户端半 / b 一并提炼后端那份 / c 整份押后）的前提已不成立**：不存在「后端那份未提炼」，也不存在「回链指向不存在的内容」。真正的选择退化为下方 🔴-1（本批谁写对侧半）。

## 已裁决（不进 interview）

草稿「仍需用户决定」三项已于 08-22 批量评审全部裁决，Phase B 按此落笔，不重开：

1. **push 前自检发现不一致时的处置 → A · 强制回声改写 + `PushError` 上报，本批照常发出。**
2. **批准松动 `account-info.md`「老档缺字段以默认值补齐」** → 改写为「客户端写入的字段补默认值；回声路径缺失走必需缺失处置 + 重新 pull」，并明写「该窗口在实践中不存在（pull 是启动链硬阻塞第三步）」。
3. **新刚性「向受约束顶层键内的对象追加字段 = 两侧同批变更」→ 接受**（对侧同项同裁）。

对侧草稿另有两项裁决（`createdAtUtc` 按时刻相等 · `identities` 有序逐元素），均标 `[采纳推荐 — 待复核]`；**它们是对侧库的内容，本库不复述**（本库只承接「不得再加工」这条义务，草稿子项 4 已明写在两种口径下都成立，不阻塞）。

## 🔴 冲突

### 🔴-1 本批由谁落笔对侧（后端）那一半 —— 「成对采纳」的执行安排

- **[问题陈述]** 两份草稿都明写「**须同时采纳**」，且逐条给出单侧采纳的后果：只采纳本侧 ⇒ 客户端老实回声但无人校验（口子仍开着）；只采纳对侧 ⇒ 客户端的补默认值 / 往返归一化**会在正常老档上稳定把 push 打成整批拒绝 ⇒ 按 `Conflict` 丢弃本地缓冲 ⇒ 丢玩家进度**。
  ✗ 与 `.claude/rules/batch-orchestration.md` 铁律 ③「绝不让两个并行 worker 写同一份文件」正面相关：对侧的写入面 `contracts/profile-sync.md` §4/§5/§5c/§7a、`contracts/purchase.md` §5、`contracts/envelope.md` §8 若同时被后端分片的 worker 认领，即为写入面冲突。
  ✗ 同时与 `.claude/rules/design-library-routing.md`「对称落笔 —— **不允许只改一侧就宣称收口**」相关。
  - **选项 (a)** 本分片只写主库半，对侧半交给**同批的后端分片**（若 orchestrator 已把 `backend-design-documents/inbox/solution-draft-echo-validation-scope.md` 单独派为一个分片）→ 后果：写入面天然分离、无冲突；但两半分属两个 worker，**必须由 orchestrator 在收尾核对「两侧措辞是否互相回链、是否同批落笔」**，否则退化为只改一侧。
  - **选项 (b)** 本分片一并写两侧（本库 + 对侧 3 份 contracts 文件）→ 后果：成对采纳由单一 worker 保证、最不易脱钩；但**若后端同名草稿也在本批被派出，即两个 worker 写同一批文件 ⇒ 违反铁律 ③**，必须先确认后端那份未被单独派单。
  - **选项 (c)** 本批整份押后 → 后果：`contracts/profile-sync.md:199` 的「尚未落笔 / 不得按字节相等实现」留白继续存在，`open-questions/05-service-contracts.md` 的承重待答项不移出。**不推荐**——前置已解除，押后无收益。
  - **推荐：(a)，若且仅若后端同名草稿已在本批被派为独立分片；否则 (b)。** 理由：铁律 ③「写入面先分区」优先于「单 worker 保成对」，而成对性可由 orchestrator 在合并阶段核对兑现（这正是批量相对逐次运行的独有价值）。**此题须 orchestrator 先答「后端同名草稿在不在本批」，才能定路由。**

### 🔴-2 `BundleGrantOrdinal` 的读档钳制是一条**在库的、作用于回声路径的钳制**，草稿的改动清单漏了它

- **[问题陈述]** 草稿子项 3 定「**回声路径不参与读档钳制**」，并特地澄清「`BundleRedeemedOrdinal` 的 `< 0 → 0`、`> Grant → Grant` 钳制不受影响」——但它**没有处理 `BundleGrantOrdinal` 自己那条钳制**。
  ✗ `game-design-documents/systems/player-profile/_index.md:174` 原话：「**读档校验**：`BundleGrantOrdinal` `< 0` → `GD.PushWarning` + **钳制到 `0`**」。`/entitlement/bundleGrantOrdinal` 是**后端写入封闭表第 4 行**（`backend-design-documents/contracts/profile-sync.md:121`）⇒ 按草稿子项 1 的恒等式，它**恰是**受回声约束的路径。
  ✗ 后果具体且严重：坏档下 `BundleGrantOrdinal` 被钳到 `0` ⇒ 下次兑现 push 提交 `entitlement` 整键 ⇒ 回声值是客户端造的 `0` ≠ 云端值 ⇒ §5c 整批拒绝 ⇒ `Conflict` ⇒ 丢弃本地缓冲。**这正是草稿子项 3 自己论证的那个缺陷面，却漏在了 `entitlement` 这一半。**
  ✗ 同段还写着「**不把 `BundleGrantOrdinal` 反过来抬高**——那是客户端改写一个只由后端写入的字段」——精神一致，但 `< 0 → 0` 这一向**仍然是写**。措辞自相矛盾。
  - **选项 (a)** 把该句改为「`BundleGrantOrdinal` `< 0` → `GD.PushError` + 该顶层键本次不进 diff + 触发一次 pull（回声路径必需缺失处置），**不钳制**」→ 后果：与子项 3 的通则完全一致，`_index.md` 进入本次改动清单（草稿只列了「第 1 行写入通道列补标注」，须扩到第 174 行）。
  - **选项 (b)** 保留钳制，只在旁边加一句「钳制后的值不得进入回声组装」→ 后果：内存态与回声值分叉，出现**两个 `BundleGrantOrdinal`**；与草稿子项 2「不为回声值另存一份缓存 / 第二权威」直接相抵。**不推荐。**
  - **选项 (c)** 判定它不是本次范围，留作待答项 → 后果：通则落笔但库内留着一条与它相抵的既有句，是本项目已踩过的「两份各自漂移」形态。**不推荐。**
  - **推荐：(a)。** 理由：草稿子项 3 的论证逐字适用于这一条；且它与既有的「不把 `BundleGrantOrdinal` 反过来抬高」在意图上本就同向，(a) 只是把该句的另一向补齐。

### 🔴-3 `AccountSeed` 的「老档缺字段以默认值补齐」在库内有**第二处**表述，草稿只松动了其中一处

- **[问题陈述]** 草稿的松动只点名 `account-info.md` 那一句。但同一口径在 `player-profile/_index.md` 另有一处，且它**点名了 `AccountSeed`**（一条回声路径）。
  ✗ `game-design-documents/systems/player-profile/_index.md:115` 原话：「**schema 影响：** 本类 7 个字段 + **`AccountInfo.AccountSeed`** ⇒ 存档 schema 版本 bump，迁移 = **老档缺字段以默认值补齐**（无损）」。
  ✗ 与 `account-info.md:13` 已有的**相反**语义并存：「解析失败按**必需缺失**处置：`GD.PushError` + 定位上下文，**拒绝进入需要它的流程**」。⇒ 库内对 `AccountSeed` 缺失已有两种处置，本次松动若只改一处，第二处留存即第二权威。
  - **选项 (a)** 松动同批覆盖 `_index.md:115`，改为「客户端写入字段缺 → 补默认；回声路径（含 `AccountSeed`）缺 → 必需缺失处置 + 重新 pull」，与 `account-info.md:13` 的既有措辞对齐 → 后果：`_index.md` 的改动面从「字段表一列」扩到「字段表一列 + 第 115 行 + 第 174 行」。
  - **选项 (b)** 只改 `account-info.md`，`_index.md:115` 不动 → 后果：两处口径分叉，本库无机制发现。**不推荐。**
  - **推荐：(a)。** 理由：裁决 2 批准的是「口径本身」的松动，不是「某一行文字」的松动；口径在库内出现几处就改几处。

## 🟠 含糊

### 🟠-1 松动后的 `account-info.md:37` 具体保留哪几项默认值

- **[原文表述]** 现句为「老档缺字段以默认值补齐（**空列表 / 默认时间 / 空昵称**）」。三项分别对应 `Identities` / `CreatedAtUtc` / `Nickname`。按裁决 2「客户端写入的字段补默认值；回声路径缺失走必需缺失处置」逐项映射：
  - `Identities` → 后端写（`account-info.md:26` 加粗「**后端**」，`:35` 明写只读投影）⇒ **回声路径，默认值取消**；
  - `CreatedAtUtc` → 后端写（`:25`）⇒ **回声路径，默认值取消**；
  - `Nickname` → 客户端写（`:27`、`:36`）⇒ **保留空昵称默认**。
  ⇒ 三项里**两项被删、只剩一项**。可解读为 (a) 该句改写成「客户端写入的字段补默认值（空昵称）；回声路径缺失走必需缺失处置 + 重新 pull」；(b) 保留三项括号但逐项标注例外。两者会写出可读性差别很大的文档段。
  - **推荐 (a)**：依据溯源三条②「正文不写过程坐标」与本库「不保留被替换内容」，逐项标注例外等于把删除动作写在正文里。
  - **另需确认：`AccountId`（第 23 行，写入方「后端」）是否也进回声约束？** 它**不在**后端写入封闭表四行内（表内只有 `accountSeed` / `createdAtUtc` / `identities`），按草稿子项 1 的恒等式**不受约束**；但字段表把它标为「后端」写入方，读者会按「后端写的都受约束」误推。**建议本次一并在字段表点明「`AccountId` 不在后端写入封闭表内，不受回声约束」**——否则恒等式的机械导出规则在本库读者手里会导出错误的四项。请确认是否接受这处顺手澄清（它不改任何机制，只消歧）。

### 🟠-2 裁决 A（强制回声改写 + 照常发出）与子项 3「缺失时该键不进 diff」的合成顺序未明写

- **[原文表述]** 裁决 1 取 A =「用权威快照的值覆盖组装值，本批照常发出」；但子项 3 定「快照中该路径**缺失 / 不合法** → `PushError` + 该键不进 diff + 触发一次 pull」。**快照里没有值时，A 的「覆盖」无值可用**。草稿伪码事实上已分层（组装期处理缺失、出口期处理不一致），但**正文没有一句把这个顺序写死**，实现者可能在出口断言处再次遇到缺失而无处置。
  - 可解读为 (a) 两条按阶段分工：组装期先判缺失（缺失即剔键，该键根本进不到出口断言）；出口断言只处理「两值都在但不等」→ 强制改写 + `PushError` + 照常发出。
  - 或 (b) 出口断言也需覆盖缺失分支，缺失时退化为剔键（即出口处同时存在 A 与「剔键」两种处置）。
  - **推荐 (a)**，理由：草稿子项 5 明写断言点「落在组装出口**一处**」，(b) 会让这一处出口承担两种处置、与「多于一处必然出现半配置态」的同构论证相冲；且 (a) 下缺失键根本不进 diff，断言的前置条件天然成立。**请确认按 (a) 写死顺序。**

### 🟠-3 松动后「回声路径缺失 ⇒ `accountInfo` 键不可提交 ⇒ 改昵称失败」这一窗口，UI 侧要不要有表现

- **[原文表述]** 张力 1 明写代价：「老档在拿到一次成功 pull 之前，`accountInfo` 顶层键不可提交 ⇒ **改昵称在那一刻会失败**」，并论证「pull 是启动链的硬阻塞第三步、成功 pull 是进入主菜单的前提，**该窗口在实践中不存在**」。裁决 2 已批准并要求明写这句。
  但**「实践中不存在」不等于「代码里不会走到」**：子项 3 的处置明写要 `GD.PushError` + 触发一次 pull，说明该分支是被实现的。玩家侧此刻点了「确认改昵称」会看到什么？
  - 可解读为 (a) 纯内部分支，不进 UI —— 玩家侧无表现，仅 `PushError` 台账（与「客户端侧不新增任何分支」最贴合）；
  - 或 (b) 需要一条 UI 表现（沿用既有的「操作失败 / 请重试」通用错误位），归 `ux/error-and-blocking-ux.md` 的翻译键面。
  - **推荐 (a)**，理由：草稿子项 6 明写「不新增 `OpError` 取值、不新增 `SyncState` 值、不新增错误码映射行」；引入 UI 表现即需要一个键，与该条相抵。**但这条须由用户确认**——它决定 `ux/` 是否进入本次改动面（草稿的改动清单里没有 `ux/`）。

## 🔵 可推演

- **🔵-1 张力 2（与「客户端侧不新增任何分支」的表面张力）在裁决 A 之下自行消解。** `sync-service.md:143` 的原话是「**收到该情形的 `Conflict`** 一律走既有处置…客户端侧不新增任何分支」——它约束的是**应答之后**。裁决 A 的处置是「覆盖组装值 + `PushError` + **本批照常发出**」⇒ 出口断言既不改变发出与否、也不产生新的应答分支。⇒ 该句一字不改即可与自检共存。**但草稿要求「须在改写时把这条判据一并写入」仍然成立**（否则两句读起来互抵），Phase B 按此写一句判据。依据：`systems/services/sync-service.md:143`、草稿张力 2 与子项 6。
- **🔵-2 「受约束顶层键 = 恰好两个（`accountInfo` · `entitlement`）」可由既有封闭表机械导出，本库无需自行判定。** 后端写入封闭表四行（`contracts/profile-sync.md:118–121`）的 path 前缀集合 = {`/accountInfo`, `/entitlement`}。两库草稿对此逐字一致（本库子项 1、对侧子项 1 的表），无分歧。依据：恒等式 + 封闭表原文。
- **🔵-3 本方案零 schema 影响、零迁移，无需进 `sync-service.md` 的 bump 清单。** 不增删任何字段，只改组装路径与读档处置；`sync-service.md:299–314` 的 bump 清单与「老档补默认值口径」列表（第 314 行）**不含 `accountInfo` 的任何字段**，故该行不受本次松动影响、不必改。依据：`systems/services/sync-service.md:314` 原文逐项核对（集合 / `DefeatReason?` / `ChapterRetry` / `eventOption` / `activeEvent` / `gameSetting`，无 `accountInfo` 项）。
- **🔵-4 本次松动**不触及任何 ADR**（任务第 3 条的核实结论）。** 全库 `decisions/` 中只有 `ADR-0023-premium-entitlement-and-redemption.md` 提及 `BundleGrantOrdinal`，其内容为「谁有权推进序号」与「客户端置位当场失败」（第 13 / 15 / 45 / 53 行），**不含读档钳制、不含补默认值口径**，与本方案同向、无需松动。`ADR-0003-online-cloud-authority`（`account-info.md` / `sync-service.md` 的挂链 ADR）讲云端权威，本方案是其加强而非削弱。⇒ **无 ADR 改写项，`decisions/` 本次零改动。**
- **🔵-5 与 `.claude/rules/state-save-rules.md` 相容。** 该规则要求「读取时校验存档：未知的内容 id、版本不匹配或缺失字段必须以清晰的错误 / 迁移来处理，而非静默的 null」——本方案把回声路径的缺失从「静默补默认」抬为「`PushError` + 显式重取」，是该规则的更严实现，不构成冲突。同规则的「绝不在较旧的存档上崩溃」也满足（处置是剔键 + 重 pull，不抛不崩）。
- **🔵-6 push 前自检的落点与既有单点纪律同构，无需新判据。** 断言点收敛到 `ProfileSyncManager` 组装出口一处，与既有「请求头组装与应答头解析收敛到 `src/Core/` 的一处」同形；且它兑现 `systems/architecture.md` 纪律可执行化四级阶梯中「不停在评审清单」的要求（先例：`deviceId` 私有化、`AccountSeed` 不出 API 面）。依据：草稿子项 5 + `systems/architecture.md` 阶梯节。
- **🔵-7 `ProfileChangeSpec` 对回声路径无写入通道这一条已在库内兑现，本次只是通则化。** `systems/player-profile/_index.md:26`（字段表第 14 行）已写「`BundleGrantOrdinal` 由后端写、经 pull 下行，**无客户端通道**」；第 13 行（`accountInfo`）当前只写「—（后端写三项 / 客户端写 `Nickname`）」，缺「受回声约束」标注。⇒ 草稿所说「覆盖第 1 行」属实且必要。

## 拟改动文档清单（供跨草稿核对，逐库分区）

### 主库 `game-design-documents/`

| 路径 | 要点 |
|---|---|
| `systems/services/sync-service.md`（「后端主动写入的唯一情形」节，约第 143 行） | 把该节末条由 `entitlement` **单例**改写为**通则**：① 受约束顶层键的**机械导出规则**（某顶层键受约束 ⟺ 后端写入封闭表中存在以该键开头的 path；当前恰为 `accountInfo` · `entitlement`）；② 组装规则（回声值唯一来源 = 最近一次 pull 的权威快照，永不自行赋值 / 不由本地历史推算 / 不沿用上次 push 值；**不另存缓存 = 不造第二权威**）；③ **回声路径不参与读档钳制 · 缺省补齐 · 格式归一化**（含缺失 / 越界 / 需归一化三情形的处置表）；④ **push 前自检**（`ProfileSyncManager` 组装出口一处；不一致 → **强制回声改写 + `PushError`（带 path / 快照值 / 组装值）+ 本批照常发出**；明写它不替代后端校验、防的是客户端自身 bug）；⑤ **判据一句**：「不新增分支」约束的是**收到 `Conflict` 之后**，自检发生在**发出之前**，两者不同层（消解张力 2）；⑥ 回链 `backend-design-documents/contracts/profile-sync.md` §5c，**不复述**逐条 path / 比较口径 / 拒绝语义 |
| `systems/services/sync-service.md`（「透明路径的稳定性纪律」节，约第 196–198 行） | 加一条**新刚性**：现措辞只覆盖「移动或重命名」；追加「**向受约束顶层键内的对象追加字段 = 两侧同批落笔的破坏性变更**」，理由写成正面陈述（客户端强类型往返会静默丢掉未知字段 ⇒ 回声当场失败），与「重命名跨边界枚举值」同档 |
| `systems/services/sync-service.md`（`## 待决问题`） | 删除「上行整键回声校验的适用面未穷举（承重）」整条（约第 352 行）——本次答定 |
| `systems/player-profile/_index.md`（字段表第 1 行 `accountInfo`） | 「写入通道」列补「**受回声约束**」标注，措辞与第 14 行对齐；**并点明 `AccountId` 不在后端写入封闭表内、不受约束**（待 🟠-1 确认） |
| `systems/player-profile/_index.md`（约第 115 行） | **（待 🔴-3 裁定）** 「`AccountInfo.AccountSeed` ⇒ …迁移 = 老档缺字段以默认值补齐」改为分路式：客户端写入字段补默认；回声路径（含 `AccountSeed`）缺失走必需缺失处置 + 重新 pull |
| `systems/player-profile/_index.md`（约第 174 行） | **（待 🔴-2 裁定）** 「`BundleGrantOrdinal` `< 0` → `GD.PushWarning` + 钳制到 `0`」改为「→ `GD.PushError` + 该顶层键本次不进 diff + 触发一次 pull，**不钳制**」；`BundleRedeemedOrdinal` 的两向钳制**原样保留**（它是客户端写入路径，且读 `Grant` 只读不写回） |
| `systems/player-profile/account-info.md`（第 37 行） | **（裁决 2 已批准）** 「老档缺字段以默认值补齐（空列表 / 默认时间 / 空昵称）」→ 分路式改写（形态待 🟠-1 定）；并明写「该窗口在实践中不存在——pull 是启动链的硬阻塞第三步、成功 pull 是进入主菜单的前提」 |
| `systems/player-profile/account-info.md`（新增一条，`Identities` 段附近） | **（裁决 3 已接受）** 「**向 `identities` 元素追加字段是两侧同批变更**」——客户端强类型 `BoundIdentity` 会静默丢掉未知字段 ⇒ 回声当场失败 |
| `systems/player-profile/account-info.md`（`## 待决问题`） | 无本次可移出项（该节现有的「合规字段归属」与本次无关，保留） |
| `handoffs/2026-08-22-<slug>.md`（新建） | 承载本次意图 + `## Clarifications`（合并 interview 的逐条裁决）+ `## Open questions`。**注意：本库 `handoffs/` 最新为 08-19，尚无 08-22 条目，slug 由 orchestrator 统一定名以免与同批其他分片撞名** |

> **不改动**：`systems/services/sync-service.md:299–314`（bump 清单与老档补默认值口径列表 —— 见 🔵-3）· `decisions/*`（见 🔵-4）· `ux/*`（除非 🟠-3 裁定要 UI 表现）· `.claude/knowledge/*`（引用层，本技能不写）。

### 对侧库 `backend-design-documents/`（仅在 🔴-1 裁定由本分片落笔时才写）

| 路径 | 要点 |
|---|---|
| `contracts/profile-sync.md` §5c | 用**恒等式**替换现第 198–199 行的「当前的执行面 / 尚未落笔」两条：受约束 path ≡ §5 后端写入封闭表行集合 + 三条推论；补**比较口径表**（整数数值相等 · `accountSeed` 逐字 · `createdAtUtc` **按时刻相等** · `identities` **有序逐元素**）；补「追加字段 = 两侧同批」 |
| `contracts/profile-sync.md` §4 | 拒绝清单计数订正：现第 95 行已写「**共四类**」且表已四行 ⇒ **该项实际已落笔**，仅需核对与 §5c 新节的回链 |
| `contracts/profile-sync.md` §7a | 判据边界（所有权 vs 复算）—— 现第 310 行**已有**该段，仅需回链 §5c 新节 |
| `contracts/purchase.md` §5 | 「不为购买单开更严的处置」补同一条所有权判据（后端草稿登记的连带；需实地核对是否已随 08-22 提炼落笔） |
| `contracts/envelope.md` §8 | 留一句指路：「客户端加字段零配合」不适用于**受约束顶层键内的对象**（后端加字段需客户端配合） |
| `open-questions/01-contracts.md` | 移出 §5c:199 指向的那条待答项（比较口径） |

> 对侧的**逐条取值语义与拒绝形态是后端库的权威，本库一字不复述**；上表仅为写入面推算，供 orchestrator 做铁律 ③ 的分区判断。

## 待移出的 open-questions 条目

| 库 | 分片 | 条目 | 处置 |
|---|---|---|---|
| 主库 | `open-questions/05-service-contracts.md:24` | 「**上行整键回声校验的适用面未穷举（08-19 新增 · 承重）**」 | **整条移出**（本对草稿完整答定：封闭清单来源、组装规则、钳制/补默认例外、push 前自检、新刚性）→ 记入 `answer-logs/log-echo-validation-scope.md` |
| 主库 | `systems/services/sync-service.md` `## 待决问题` | 同一条的主题文档副本（约第 352 行） | 同批删除（清单与主题文档须一致） |
| 对侧库 | `backend-design-documents/open-questions/01-contracts.md` | `profile-sync.md:199` 指向的「非整数路径比较口径」条 | **仅在 🔴-1 裁定由本分片写对侧时**移出；否则交后端分片 |

**answer log 命名（供 orchestrator 代笔）：** 输入是 `inbox/solution-draft-echo-validation-scope.md` ⇒ `answer-logs/log-echo-validation-scope.md`（取 slug，不加日期）。

**台账行（worker 不写，随报告交回）：**
- `handoffs/_index.md`：新增一行（置顶）`2026-08-22-<slug> | 2026-08-22 | 回声校验通则（客户端半） | distilled | systems/services/sync-service.md · systems/player-profile/_index.md · systems/player-profile/account-info.md`
- `inbox/_index.md`：待处理表删 `solution-draft-echo-validation-scope.md` 行；已归档表补 `solution-draft-echo-validation-scope.md | solution-draft | 2026-08-22 | 2026-08-22-<slug>.md | log-echo-validation-scope.md`
- `answer-logs/_index.md`：追加 `log-echo-validation-scope.md | 2026-08-22 | inbox/solution-draft-echo-validation-scope.md | 1`
- `open-questions/update-log.md`：顶部追加本次摘要（答结 1 条承重项 · 松动 `account-info.md` 补默认值口径 · 新增两侧同批刚性 · 订正 `BundleGrantOrdinal` 读档钳制）
- `open-questions.md` 索引顶部：`最近更新：2026-08-22 — 回声校验通则落笔（详见 …）`

## 越界发现

1. **`inbox/_index.md`（主库）疑似漏登记本草稿的裁决状态。** 本草稿 front matter 仍是 `status: awaiting-review`，但正文「仍需用户决定」已改写为「**已全部裁决（2026-08-22 · 批量评审）**」。对侧库的 `inbox/_index.md` 在办行已详细登记裁决与前置解除，**主库侧未实地核对**（本分片未读主库 `inbox/_index.md` 的在办表，避免越界）。请 orchestrator 在 Phase B 一并核对主库在办行是否同样需要更新。**归档前置条件之一是 front matter 改 `distilled` 并补 `reviewed:` 行**（技能第 9 步），Phase B 须补。
2. **两份草稿的「前置依赖」小节均已过时**，且**对侧草稿的过时面更大**（它多断言了 `bundleRedeemedOrdinal` 白名单行 / `receiptId` 幂等 / 读己所写「至今没有一条落进契约」，实地核实**三项均已落笔**）。若后端同名草稿由另一 worker 处理，**该 worker 可能据过时前提判定「无处附着」而搁置整份**。建议 orchestrator 把本节「跨库前置状态」表转达给该分片。
3. **`contracts/profile-sync.md:199` 是一处带有效期的**留白**，且明写「在落笔之前不得按字节相等实现」。** 它指向 `backend-design-documents/open-questions/01-contracts.md`。本对草稿一旦落笔，该留白与那条待答项须同批清除，否则契约里会留下一句「尚未落笔」而实际已落笔——本库不处理，记此。
4. **后端草稿称「§4 拒绝清单由三类扩为四类，§4 现有表述失真，须同批改」——该项实地核实**已完成****（`contracts/profile-sync.md:95` 已写「共四类」，第 97–102 行表已四行，第 104 行判定顺序已写）。若后端 worker 照草稿再改一次，会重复劳动或改坏已正确的内容。已记，供跨分片核对。
5. **未处理（非本分片）**：主库 `inbox/` 顶层另有 9 份 `solution-draft-*.md`，均未触碰。

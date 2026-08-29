# Codex 顶层键的计数措辞去计数化

- id: 2026-08-25-codex-key-count-neutralization
- date: 2026-08-25
- topic: contracts/profile-sync（§5 排除清单去计数化 + 回链客户端族清单）
- status: distilled
- distilled-to: contracts/profile-sync.md

## Intent（distilled）

**一句话：** `profile-sync.md` §5 的排除清单用**计数**指代图鉴族顶层键，而计数是客户端设计的函数；把它改成按顶层键后缀恒定覆盖全族并回链客户端族清单，从根上消除下一次族成员变动再漂移。

### 1. 病因

排除清单里写「无后端规则用途」的那一行，把图鉴族顶层键**以数量列举**。这个数量的真值在客户端库，客户端族成员一变、本库这句即失真，而**本库没有任何机制会发现**——它不是白名单条目（不参与复算、不进回声校验），没有任何断言或校验会踩到它。

这与本库已经反复立过护栏的那一类病同源：把另一侧的设计事实**复制**到本库，两份各自漂移而无处对账。区别只在于这次复制的是一个数字，而不是一张表。

### 2. 处置：换判据，不换数字

改动落在一行：

- 由**计数指代**改为按顶层键后缀恒定覆盖全族（`*Codex`）；
- 补一句正面判据，说明为什么这里不列举也不计数；
- **回链客户端族清单权威** `game-design-documents/systems/player-profile/codex/_index.md`，**本库不复述族内任何设计**。

把数字改成新值是**错误的处置**——那只把同一处漂移推迟到下一次族成员变动。选后缀判据的理由：它使这一行的正确性不再依赖客户端的族成员数，而只依赖顶层键命名形态（后者本就受本库 §5b 的字段命名通则约束）。

回链**取族清单 `_index.md`、不取字段面文档**：本行要防的是族**成员数**漂移，族清单才是这件事的发生地；字段面形态（顶层键的 JSON 形状）另有权威，与本行无关。

### 3. 本次触发源

客户端图鉴族发生一次扩员（新增一个同族顶层键）并随之 bump `schemaVersion`。客户端侧意图见
`game-design-documents/handoffs/2026-08-25-info-economy-and-codex-expansion.md`。

**本库不复述该扩员的任何设计**——族成员是什么、词条深度、解锁规则、可查阅时机一概不抄；本 handoff 只处理边界这一侧的措辞与结论。

### 4. 契约面结论：字段面零配合成立

新增的同族顶层键落**不透明段**（§5「未在下表出现的一切字段都是不透明段——白名单的补集即是」），由此逐条推出：

- 不进透明路径白名单 ⇒ 不背 §5 的路径稳定性约束；
- 按 §5c 的适用面恒等式（受回声校验约束的 path 集合 ≡ 后端写入字段封闭表的行集合）⇒ **结构性地**不受回声校验约束，且**不需要在 §5c 增加任何一行**（该节已明确否决第二份清单）；
- 不触发 §5c 的「追加字段刚性」——刚性只覆盖受约束顶层键（`accountInfo` · `entitlement`）**内部**的对象追加，本次是平级新顶层键；
- §3a 的顶层键浅合并对顶层键集合本就开放，无需改动；
- 打不到 §4 四类拒绝面中的任何一类（`sync.payload_invalid` 明写「不透明段内部的任何结构问题都不得触发这一条」）。

**契约报文形态一字未变**，故本次不 bump URL 主版本，也不 bump spec 的 `info.version`。

### 5. 唯一一条非零义务：兼容矩阵登记

`schemaVersion` bump 之后，新值须进 `envelope.md` §7e 的兼容矩阵，否则该版本的全量 push 会被 §4 的版本闸门以
`sync.payload_schema_unsupported` 拒绝。如实记下这一条，并同时记下它的三条边界：

- 它是**每一次** bump 都存在的既有机械义务，不是本次扩员新增的；
- 它由 §7e 的通则唯一承接，无设计自由度；
- 兼容矩阵落 `operations/`，栈未落定故当前空置 ⇒ **本次无可落之处**。

**这条义务不写进 `profile-sync.md` 正文。** §7e 已是它的单点权威，在契约本体复述即制造第二权威，且会逼得每次 bump 都回来改一句。

`schemaVersion` 的结构权威与 bump 决定权都在客户端（`envelope.md` §8），本库不参与该裁决、也不催办。

## Open questions

无。

## Notes / triage

- 落笔面：`contracts/profile-sync.md` 两处——§5 排除清单该行、文档头部 `Source:` 行。全文其余部分一字未改。
- 全库扫描确认：活文档中带计数的图鉴族措辞**仅此一处**。其余命中均为「第六份契约 / 六个端点」（与图鉴无关）或过程档案（`handoffs/` · `inbox/archive/` · `open-questions/update-log.md`，按根约定不受活文档纪律约束）。
- `contracts/_index.md` 的 `profile-sync.md` 摘要行不提图鉴，无需改动；契约面份数不变。

## 客户端侧影响

**本 handoff 不改动客户端 ↔ 后端边界的任何语义**——报文形态、Profile 三段可见性分段、后端拒绝面、回声校验适用面均未变，`sync-service` 无需为本次做任何对位改动。

客户端侧的对位内容（族扩员、`PlayerProfileDiff` 的顶层键面、`schemaVersion` bump 的归批）在客户端库落笔，权威回链
`game-design-documents/handoffs/2026-08-25-info-economy-and-codex-expansion.md` 与
`game-design-documents/systems/player-profile/codex/_index.md`。**本库不复述、不催办。**

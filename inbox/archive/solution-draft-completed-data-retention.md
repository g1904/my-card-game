---
type: solution-draft
date: 2026-09-06
question: 篇章通关（`completed`）时是否清理角色数据？库内两处措辞与另外三处设计正面矛盾，须择一收口。
source: open-questions/06-meta-progression.md → 「`completed` 是否清理角色数据（09-05 新增）」
targets: systems/services/life-cycle-service.md · systems/character-profile/_index.md · program-overview.md（阶段 5）· decisions/ADR-0004-realm-checkpoint-retry-model.md（措辞澄清）· systems/services/profile-schema-versions.md（v1 清单补行）
status: distilled
reviewed: 2026-09-06 · 批量评审（/batch-analyze-new-ideas · 合并 interview）——全部取向项已由用户当面裁决，逐条见 handoff 的 Clarifications
distilled-to: handoffs/2026-09-06-completed-data-retention.md
---

# 方案草稿 —— `completed` 是否清理角色数据

## 问题

库内对「轮回结束时角色数据怎么处置」有**两种互斥的写法**，且两边都不是顺笔，都被下游设计承重引用。

**A 侧（写「两条出口都清理」）——恰两处，措辞逐字相同：**

- `systems/character-profile/_index.md:354`：
  > 「**角色状态是终态收敛的状态机。** `status` 收敛为 `ongoing | defeated | completed`（…）；`defeated` 与 `completed` 数据都会在轮回结束时被清理。」
- `systems/services/life-cycle-service.md:11`：
  > 「**角色状态分类法。** `status` 收敛为单一终态集 `ongoing | defeated | completed`：`discarded`（主动弃置）是 `defeated` 的一个**原因子类型**。`defeated` 与 `completed` 数据都会在轮回结束时被清理。」

**B 侧（要求 `completed` 不被清理）——至少五处，分布在三份文档，且各自是别的机制的承重前提：**

- `systems/services/life-cycle-service.md:28`：
  > 「**篇章存档 · 读档续章 · 重试模型。** 篇章通关即在所达境界落一个**存档点**（如打通炼气→筑基得到筑基存档）；可读档从该境界起始下一篇章。（…）而**落过境界存档的角色，在后续篇章有有限的重试次数**——存档角色是一种会被耗尽的有限资源。」
- `systems/services/life-cycle-service.md:25`：
  > 「**篇章继承：全部继承。** 读档续章时，角色带入下一篇章的是**上一篇章的全部信息**（deck、法宝、**神通**、属性、叙事标记等），无逐项筛选。」
- `systems/services/life-cycle-service.md:27` / `ux/onboarding.md:14`：
  > 「解锁触发 = **角色通关上一篇章**，随即成为下一篇章的**可挑战角色**；若某篇章没有可重试 / 可挑战的角色，该篇章**重新进入锁定（隐藏）**状态。」
- `program-overview.md:229`（阶段 5 的 `completed` 分支）：
  > 「`completed` ─▶ ChapterManager：在所达境界落存档点 / 解锁下一篇章的可挑战角色」
  > ——与紧邻的 `defeated` 分支「清理该角色数据；扣减该篇章重试次数」形成**明确对照**：清理二字只写在 `defeated` 那一支。
- `program-overview.md:147`（阶段 3）：
  > 「玩家选『炼气 · 新角色』或『**筑基存档角色 · 续章**』」——续章的入参就是一个仍然存在的、已通关 ch1 的角色档。
- `systems/services/life-cycle-service.md:75-76`（`CycleStartSpec`）：
  > `string SourceCharacterId,   // 空 = 炼气新角色`
  > ——它是一个**按 id 的引用**，被引用的那份档必须还在。

**判定：B 侧成立，A 侧的措辞失准。** 若 `completed` 的角色数据真被清理，`SourceCharacterId`、「可挑战角色」、「篇章继承 = 全部继承」、「从该篇章起始存档重试」四项**同时失去数据源**——没有任何一处给出过替代载体。反向则一处都不破：A 侧那句话有一个**仍然为真的窄读法**（清理的是**轮回运行态**，不是角色实体状态），下面的方案就是把这个窄读法钉死。

**但收口不能只写「不清理」三个字。** 「`completed` 保留」立刻牵出三个必须同时给出答案的形态问题，否则下游无法 derive：

1. 到底**清什么、留什么**——`activeCombat` / `rng` 子流 / `pastEvent` 这些明显属于「这一遍」的东西，在 `completed` 上显然不该原样留着。
2. `completed` 档如何回到 `ongoing`——**原地翻回**还是**新建一条**？两者对「从该篇章起始存档重试」的兑现方式完全不同。
3. **`defeated` 那一半同样含糊**（同一句话覆盖两条出口）：`RetryChapter(string characterId)` 的入参与 `chapterRetry`「通关后保留计数、不清零，故计数同时是一份历史」都要求**被清理的角色档不能立刻整条消失**。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| C1 | 篇章通关即在所达境界落**持久存档点**，可读档从该境界起始下一篇章；三个篇章边界是持久存档点，元婴为奖杯 | `decisions/ADR-0004:13` |
| C2 | 篇章途中死亡 → **从该篇章起始存档重试**；ch1 ∞ / ch2 3 / ch3 1（持礼包 ∞ / 9 / 3） | `decisions/ADR-0004:15` |
| C3 | 篇章继承 = **全部继承**，无逐项筛选 | `decisions/ADR-0004:14`、`life-cycle-service.md:25` |
| C4 | 「重开一局」说的是**随机流，不是角色**——重试拿回的是篇章起始那份角色状态 | `life-cycle-service.md:35` |
| C5 | 篇章解锁是**动态状态**（「有可挑战角色」），不是一次性永久标志 | `ADR-0004:21`、`ux/onboarding.md:14` |
| C6 | `PlayerProfile.characterProfile : IReadOnlyList<CharacterProfile>` 是持有一组角色档的顶层键 | `systems/player-profile/_index.md:14`、`profile-schema-versions.md` #31 |
| C7 | **一切 Profile 写入经 `profile-service.ProfileManager.TryApply(spec)`**，全有或全无 | `life-cycle-service.md:57` |
| C8 | `TeardownCycle()` 的既有内容是**运行时拆解**：「断开信号、QueueFree 实例化节点、清空集合（防跨轮回残留：静态字段、未清集合、遗留卡牌 / 敌人节点）」 | `program-overview.md:235-237` |
| C9 | 篇章结束屏 / 轮回结束屏的摘要**在 `TeardownCycle()` 与任何角色数据处置之前组装**，零新增存档字段 / 存档点 | `life-cycle-service.md:164`、`:169-170` |
| C10 | 账号级残卷 `Accumulated` 的累加**必须在角色终结提交之前完成**（终结会走角色终态数据清理） | `life-cycle-service.md:177`、`ADR-0004:19` |
| C11 | **首发前的一切改动全部归入 `schemaVersion = 1`，不拆成多版**；补齐工作是往 v1 清单里补条目，**不产生任何新的 bump** | `profile-schema-versions.md:19` |
| C12 | `CurrentLocationId`「**跨篇章持久**，仅由 Travel 结算改写；**篇章重试时随该篇章起始存档一并回滚**」 | `character-profile/_index.md:298`、`game-progression.md:178` |
| C13 | `ChapterLifeSpanBudget` 在篇章边界被冻结，**篇章重试时随该篇章起始存档一并带回** | `handoffs/2026-08-12d-…:91` |
| C14 | `chapterRetry` 是 `CharacterProfile` 上的一个类，三个具名字段，**通关后保留计数、不清零，故计数同时是一份历史**；**ch1 的角色级计数恒为 0** | `life-cycle-service.md:29-33` |
| C15 | `TotalCyclesCompleted` **只在 ch3 的 `CompleteChapter` 那一笔 +1**；ch1 / ch2 的 `completed` 只落境界存档点 | `life-cycle-service.md:251` |
| C16 | 元婴通关证书 = `ChapterEndScreen` 的 ch3 变体，**不做独立回看**（两个账号级数字在玩家档案屏常驻可读即为回看通道） | `answer-logs/log-run-end-and-chapter-completion-screens.md:23` |

## 建议方案

### 1 · 收口方向：`completed` **不清理角色实体状态**；A 侧两处措辞改写

`[既有推演]`

B 侧四项机制（`SourceCharacterId` 引用、可挑战角色判定、篇章继承、从起始存档重试）**全部以「通关档仍然存在」为唯一数据源**，库内没有任何一处给过替代载体；A 侧那句话则在窄读法下仍然为真。故**改 A 不改 B**。

建议把两处逐字改写为（措辞供评审，落笔归 `/analyze-new-ideas`）：

> **轮回运行态在两条出口上都被清理；角色实体状态只在 `defeated` 上被处置，`completed` 保留下来即「境界存档」。**

同步需要澄清措辞的还有两处（**本技能不改，登记给下一步**）：

- `decisions/ADR-0004:16` 结尾的「终态数据清理。」——它紧跟在整段状态机之后，读起来像覆盖三个值；建议改为「**`defeated` 的终态数据清理**」（不推翻任何决定，只是把主语补上）。
- `program-overview.md` 阶段 5 的 `completed` 分支可加一行「运行态清空（不清理角色实体状态）」，使两支的对照从「一支写了、一支没写」变成「两支都写明」。

### 2 · 「清理」是三层，不是一件事

`[既有推演]` `[通行做法]`

矛盾的根源是「清理」这个词同时被用在三个层上。建议把它拆开，逐层写明每条出口的行为——**三层都落在既有时点，不新增任何存档点**（C9 的「任何角色数据处置」逐字对应第 2 层与第 3 层）。

| 层 | 内容 | `completed` | `defeated` | 时点 |
|---|---|---|---|---|
| **L1 运行时拆解** | 断开信号、`QueueFree` 实例化节点、清空内存集合、静态字段（C8 原文） | **做** | **做** | `TeardownCycle()`（既有） |
| **L2 轮回运行态字段清空** | 见下方分区表「运行态」列 | **做** | **做** | 并入 `CompleteChapter` / `DefeatCharacter` 那一次 `TryApply`（既有事务） |
| **L3 角色实体状态处置** | 见下方分区表「实体状态」列 | **不做**（保留 = 境界存档） | 做（形态见 §4） | 同 L2 那一次 `TryApply` |

L1 与 L2 对两条出口一视同仁——这就是 A 侧那句话**可以保住的那一半**：`completed` 的角色确实「有东西被清理」，只是被清的不是它的实体状态。

### 3 · 字段分区表（L2 清 / L3 留）

`[既有推演]`

分区判据一句话：**「这一格描述的是这一遍怎么走的」→ 运行态；「这一格描述的是这个角色是谁」→ 实体状态。** C3 的「全部继承」列举的四类（deck、法宝、神通、属性、叙事标记）**没有一项落在运行态列**，两者不冲突。

| 字段 | 归类 | 依据 |
|---|---|---|
| `rng`（`cycleSeed` + `stream[]` 四条子流） | **运行态** | 重试「换一套随机流」（C4）⇒ 这一遍的 `State` / `DrawCount` 对下一篇章零意义 |
| `activeEvent` · `activeCombat` | **运行态** | 收口即置空（`life-cycle-service.md:205,209`）；跨出口留存即是脏态 |
| `eventOption`（当前批） | **运行态** | 每次 `RefreshAfterEvent` 整块替换（`character-profile/_index.md:209`）；下一篇章由 `StartCycle` 重写第一批 |
| `pastEvent`（修行历程） | **运行态**（篇章边界清空） | `ChapterEndSummary.PastEventCount` 的口径是 `pastEvent.Count`（`life-cycle-service.md:167`），而那一屏呈现的是**本篇章**的结果三行 ⇒ 跨篇章累积会让 ch2 / ch3 变体显示一个累计值。`future-event-service.md:115` 的开局构筑判定式取 `chapter == 1` **与** `pastEvent` 为空的**合取**，正是为了在 ch2 起手同样为空时不误判 |
| `pastItemUse` | **运行态**（同上） | 与 `pastEvent` 同性质的本篇章痕迹 |
| `disabledAbility` | 实体状态，但 `Duration == ThisChapter` 的条目**在篇章边界剔除** | 既有到期剔除表（`life-cycle-service.md:242-246`），无需为本方案新增动作 |
| `deck`（功法 / 卡组）· `magicPack`（法宝）· `characterPower`（神通） | **实体状态** | C3 逐字列举 |
| `Status`（`lifeSpan` · `mana` / `manaLimit` · `experiencePoint` · 道心 / 煞气 + 两个 band） | **实体状态** | C3「属性」；剩余寿元跨篇章结转是 ChapterManager 既有职责（`life-cycle-service.md:13`） |
| `Status.ChapterLifeSpanBudget` | **实体状态**，篇章边界重新冻结 | C13 |
| `CurrentLocationId` · `LocationEventCount` | **实体状态** | C12 逐字「跨篇章持久」 |
| `plotKeyPoint` | **实体状态** | C3「叙事标记」 |
| `spiritStone` · `immortalJade` | **实体状态** | 「两种货币与寿元同形，也跨篇章结转；篇章边界**不做任何清零动作**」（`life-cycle-service.md:15`）——**这一条是分区表的独立佐证**：库内已明写篇章边界有字段被点名「不清零」 |
| `chapterRetry` | **实体状态** | C14「通关后保留计数、不清零」 |
| `id` · `characterDataId` · `chapter` / `realm` / `level` · `startContentVersion` / `lastContentVersion` · `defeatReason` | **实体状态** | 身份与进度坐标 |

> **`pastEvent` / `pastItemUse` 的篇章边界处置是本方案唯一一处新判断**——库内此前没有明文。上表给了它的推演依据（`ChapterEndSummary` 的口径 + `future-event-service` 的合取判定式）与反面代价（ch2 / ch3 的结果三行显示累计值）。若评审认为该保留，则 `ChapterEndSummary.PastEventCount` 需要改成「本篇章计数」的另一种取法，**两者只能选一个**。

### 4 · `defeated` 那一半：清理 ≠ 立刻整条删除

`[既有推演]`

同一句措辞覆盖两条出口，收口时必须一并说清，否则改完 `completed` 那一半，`defeated` 仍然含糊。三条既有设计要求 `defeated` 的档**不能在终结那一刻整条消失**：

- `RetryChapter(string characterId)` 的**入参是一个 id**（`life-cycle-service.md:66`）——重试发起时被引用的对象必须可解析；
- C14「`chapterRetry` 通关后保留计数、不清零，**故计数同时是一份历史**」——历史需要一个持久载体；
- C2「从该篇章起始存档重试」——ch3 途中死亡后仍有 1 次重试，**金丹存档必须活过这次死亡**。

建议形态：`defeated` 时**保留该角色档的身份与元进程格**（`id` · `characterDataId` · `chapter` · `status = defeated` · `defeatReason` · `chapterRetry`），**清空 L2 全部运行态 + L3 的可继承实体状态**（deck / 法宝 / 神通 / `Status` / 货币 / `plotKeyPoint`）——后者正是「这个角色没了」的实质。这样：

- 「`defeated` 清理数据并消耗重试次数」（`life-cycle-service.md:254`）逐字成立；
- 玩家档案里留下的是一条**没有实体状态的墓碑**，而不是一份完整角色；
- **`defeated` 档不是任何篇章的「可挑战角色」**（C5 的判定只认 `completed`），故它不会让一个本该锁定的篇章保持解锁。

**该角色的下一次重试从哪里读回状态**，取决于 §5 的取向选择：选 A 读它自己的篇章起始快照，选 B 读它的源档（上一篇章的 `completed` 档）。

### 5 · `completed` 档如何回到 `ongoing`：两种存档表达

`[取向选择]` —— 见 `## 仍需用户决定` 第 1 项。两案都兑现 §1–§4 的全部结论，差别在存档形状、体积与「终态收敛」这句既有措辞是否保得住。

### 6 · 不新增存档点、不 bump schema

`[既有推演]`

- L2 / L3 的写入**并入 `CompleteChapter` / `DefeatCharacter` 那一次既有的 `TryApply`**（C7），落在既定的篇章边界 / 轮回结束存档点上，**不新增存档点**——与 `disabledAbility` 到期剔除「不新增存档点，两个时点本就是既定的存档边界」（`life-cycle-service.md:248`）同款。
- C9 的时点纪律**原样成立且不需要重述**：两屏的摘要在「`TeardownCycle()` 与任何角色数据处置之前」组装，本方案把 L2 / L3 明确归入「角色数据处置」，该句因此从中性措辞变成有确指的措辞，一格不用改。
- C10 的顺序纪律同样原样成立：残卷 `Accumulated` 的账号级累加在角色终结提交之前——本方案不动 `DefeatCharacter` 的时点。
- 两案各自需要的**新字段在首发前不产生任何 schema bump**，只往 `profile-schema-versions.md` 的 v1 清单补一行（C11 逐字）。**推论：本题不触发跨边界承接**——该文件 `:90` 把「本表新增一行 = 一次 bump 定案」列为跨边界触发源，而 v1 补条目明写「不产生任何新的 bump」，故后端零配合，本次单库落笔。

## 具体形态（可 derive 的落地面）

### 服务面（两案共用）

```csharp
// life-cycle-service —— 既有方法，语义补全，签名不变
OpResult CompleteChapter();                    // L1 + L2；不做 L3
OpResult DefeatCharacter(DefeatReason reason); // L1 + L2 + L3（§4 的墓碑形态）
void     TeardownCycle();                      // 只做 L1（运行时拆解），零存档语义
```

- **`TeardownCycle()` 的语义收窄为纯运行时拆解**，与存档处置解耦。理由：它当前被两条出口共用（`program-overview.md:235`），塞进存档语义就必须在方法内分支 `status`，而 C9 已经把「呈现层快照」钉在它之前——三件事挤在一个方法里是把顺序纪律往回退。
- **`CompleteChapter` 与 `DefeatCharacter` 各自组装一次 `ProfileChangeSpec` 并 `TryApply`**（C7）；L2 的清空走既有的 `EventStateChanges` / `RngElements` / 绝对置值通道，**不新开写入面**。

### 判定面（两案共用，字段级口径）

```
某篇章 N 的「可挑战角色」集合
  = { c ∈ PlayerProfile.characterProfile
      | c.status == completed && c.chapter == N - 1 && 该档尚未产生成功后继 }
篇章 N 解锁 ⟺ 该集合非空 或 存在 c.status == defeated && c.chapter == N && 该档尚有重试余量
剩余重试次数 = ChapterRetryLimitsData[HasPremiumBundle 选行][N] − chapterRetry.ChN
```

- 三处读取上限**一律不得硬编码常量**（`ADR-0004:26`、`monetization.md:23`），本式照此写。
- 「该档尚未产生成功后继」这一条**关掉「从同一个筑基存档反复开 ch2 刷通关」的通道**——ch2 重试上限 3 约束的是失败后重来，不是成功后重刷。它的表达方式随 §5 的选案不同（A：`status` 已离开 `completed`；B：存在一条 `sourceCharacterId` 指向它且已 `completed` 的后继档）。

### 选案 A —— 单记录 + 篇章起始快照（推荐）

一个角色恒为 `characterProfile` 列表里的**一条**记录，原地跨三篇章推进。

| 项 | 形态 |
|---|---|
| 新增字段 | `CharacterProfile.chapterStartSnapshot`（本篇章起始那一刻**实体状态列**的冻结拷贝；不含运行态列，故不自嵌套） |
| 写入时点 | `StartCycle` 与 `CompleteChapter` 各写一次（都是既有存档点） |
| 续章 | `StartCycle(SourceCharacterId = 自身 id)` → `status: completed → ongoing`、`chapter += 1`、新 `cycleSeed` 与四条子流、写新的 `chapterStartSnapshot` |
| 重试 | `RetryChapter(id)` → 用 `chapterStartSnapshot` **整份回滚**实体状态列、`chapterRetry.ChN += 1`、`status: defeated → ongoing`、换一套随机流 |
| 状态机 | `completed` **不再是吸收态**（`completed → ongoing` 是一条合法转移，由 `StartCycle` 触发）；只有 `defeated` 是吸收态（重试后角色本身仍是同一条档） |
| 体积 | 每角色一条记录 + 一份实体状态拷贝（≈ ×2，且不含 `pastEvent` 这类大列） |
| 措辞代价 | `character-profile/_index.md:354`「终态收敛的状态机」这句**必须一并改写** |

`chapterStartSnapshot` 的存在使 C12 / C13 两处「**随该篇章起始存档一并回滚 / 带回**」的现成措辞获得逐字对应的载体——这两句目前指向的对象在库内是无名的。

### 选案 B —— 每篇章一条记录 + 血统引用

每次进入一个篇章都新建一条 `CharacterProfile`，源档冻结在 `completed`。

| 项 | 形态 |
|---|---|
| 新增字段 | `CharacterProfile.sourceCharacterId`（空 = 炼气新角色，与 `CycleStartSpec` 同名同义） |
| 续章 | `StartCycle(SourceCharacterId = 源档 id)` → **新建**一条档（新 `id`、`chapter = N+1`、`status = ongoing`），实体状态列自源档整份复制；源档保持 `completed` 冻结 |
| 重试 | `RetryChapter(id)` → 该 `defeated` 档的 `sourceCharacterId` 回溯一跳到源档，从源档**再复制一份新档**；`chapterRetry.ChN += 1` 写在**源档**上 |
| `chapterRetry` 权威副本 | 落**源档**（被重试的那份存档）。**推论：这直接解释了 C14 的「ch1 的角色级计数恒为 0」**——ch1 没有源档，无处可记 |
| 状态机 | `completed` / `defeated` **都保持吸收态**，`_index.md:354`「终态收敛」一字不改 |
| 体积 | 一次成功轮回最多 3 条 + 每次失败一条墓碑；随游玩时长线性增长，需要一条回收规则（见下） |
| 附带代价 | 「每个 `CharacterProfile` 是一次轮回 / 一个角色的状态与历史」（`life-cycle-service.md:8`）需改口径——一次轮回会有多条记录 |

选 B 时**必须同时定一条回收规则**（否则 `characterProfile` 列表无界增长，而它是云端权威主档的一部分）。建议：**一条 `completed` 档在其成功后继也 `completed` 之后即可回收实体状态列，只留墓碑**（此时它既不是可挑战角色、也不再是任何重试的输入）。

## 后果

- **受影响文档**：`systems/services/life-cycle-service.md`（`:11` 措辞、`:254` 状态机行、新增「清理三层 + 字段分区表」）· `systems/character-profile/_index.md`（`:354` 措辞；选 A 时另需改「终态收敛」）· `program-overview.md` 阶段 5（`completed` 分支补一行）· `decisions/ADR-0004:16`（补主语，不推翻决定）· `systems/services/profile-schema-versions.md`（v1 清单补一行新字段）。
- **不受影响**：`ux/screen-flow.md` 的轮回收尾族两屏一字不改——C9 的「在任何角色数据处置之前」在两种读法下均成立，这也正是原待答项写明「不阻塞篇章结束屏」的原因。
- **存档迁移**：无。首发前一切改动归 `schemaVersion = 1`（C11），不产生 bump。
- **后端**：零配合（推导见 §6 末条）。本次单库落笔。
- **新增的可 derive 面**：篇章解锁 / 重新锁定的判定式此前只有散文描述，本方案给出字段级表达；`RetryChapter` 的「从起始存档回滚」此前没有载体，两案各给一个。

## 备选方案（已考虑并否决）

- **改 B 侧、保 A 侧**（即真的清理 `completed` 数据，另造一套「境界存档」对象承载续章）——否决：等于把 `CharacterProfile` 的实体状态列**原样复制**进一个新类型，制造第二权威且两份必然漂移；而 C3「全部继承、无逐项筛选」意味着新类型的字段面与 `CharacterProfile` 逐格相同，纯属换名字。
- **把 L2 / L3 的清空拆成独立的一次提交**——否决：与「一个事件的收口是一次事务、一个存档点」（`life-cycle-service.md:171`）反向，且会在轮回结束处凭空多出一个存档点。
- **`TeardownCycle()` 内按 `status` 分支处理存档**——否决：C9 已把呈现层快照钉在它之前，再往里塞存档语义就要在一个方法里同时管顺序、分支与拆解。
- **用 `PlayerStatistics` 承载「历史角色」以便回收全部终态档**——否决：`player-profile/_index.md:78` 明写统计计数是**纯读数、不参与任何规则判定**，而 `chapterRetry` 是闸门输入，混进去会让「统计可走宽松同步口径」这条便利判断失效。
- **ch3 `completed` 档做成可回看的通关证书档**——否决：C16 已裁定「不做独立回看」，两个账号级数字在玩家档案屏常驻可读即为回看通道。

## 与既有决策的张力

- **`ADR-0004:16`「终态数据清理。」** 这句话紧跟整段状态机之后、无主语，是 A 侧措辞的上游。本方案不推翻 ADR 的任何决定，只主张**补上主语**（`defeated` 的终态数据清理）。若评审认为 ADR 原意确实覆盖 `completed`，则 ADR 自身的 `:13`（境界存档点 · 可读档从该境界起始下一篇章）与 `:15`（从该篇章起始存档重试）会与之互相矛盾——**矛盾在 ADR 内部就已存在**，无论如何都要裁一次。ADR 的改笔归 `/analyze-new-ideas` 或 `/write-adr`，本技能不改。
- **选案 A 与 `character-profile/_index.md:354`「终态收敛的状态机」正面冲突**（A 允许 `completed → ongoing`）。松动的代价：状态机不再是纯收敛图，读者需要知道 `completed` 是「可离开的存档态」。不松动的替代即选案 B。**这条张力是 §5 取向选择的实质内容，已并入下方第 1 题。**

## 前置依赖

- **无阻塞项。** 本方案不依赖任何仍待答的问题。
- **同分片相邻项「主动弃置的发起入口」（09-02）** 与本题共用 `defeated` 出口，但那条问的是**从哪一屏发起**，与本题的**数据处置**互不覆盖；原文亦已写明弃置经 `DefeatCharacter(Discarded)` 落到同一屏的同一变体。
- **`pastEvent` / `pastItemUse` 的篇章边界处置**（§3 分区表末条）是本方案内部提出的新判断，随本草稿一并评审；若否决，`ChapterEndSummary.PastEventCount` 的取法需同时改。

## 仍需用户决定

### 1 · `completed` 档回到 `ongoing` 的存档表达：单记录 + 起始快照，还是每篇章一条记录？

> 术语说明：**「起始快照」**＝把角色在篇章开始那一刻的实体状态另存一份，重试时整份读回；**「每篇章一条记录」**＝续章时新建一条角色档，上一篇章那条冻结在 `completed` 不再改动。

- **选项 A（推荐）· 单记录 + `chapterStartSnapshot`。**
  - **后果**：`characterProfile` 列表恒为「一个角色一条」，体积可控；C12 / C13 现成的「随该篇章起始存档一并回滚 / 带回」两句获得逐字对应的载体；`life-cycle-service.md:8`「每个 `CharacterProfile` 是一次轮回 / 一个角色」的口径一字不改。
  - **代价**：`character-profile/_index.md:354`「**终态收敛**的状态机」必须改写——`completed → ongoing` 成为一条合法转移。
- **选项 B · 每篇章一条记录 + `sourceCharacterId`。**
  - **后果**：`completed` / `defeated` 都保持吸收态，「终态收敛」一字不改；`chapterRetry` 落源档，**顺带解释了既有推论「ch1 的角色级计数恒为 0」**。
  - **代价**：`characterProfile` 列表随游玩时长线性增长，**必须同时定一条回收规则**（否则云端权威主档无界膨胀）；且「一个 `CharacterProfile` = 一次轮回」的口径要改（一次轮回会有多条记录）。
- **→ 已裁决（2026-09-06 · 批量评审）：选 A —— 单记录 + `chapterStartSnapshot`。** `character-profile/_index.md:354` 的「终态收敛的状态机」随之改写：`completed → ongoing` 是一条合法转移。
- **推荐 A 的理由**：本题的成本主要在存档体积与规则数量。A 用一个已被两处措辞暗示（C12 / C13 的「起始存档」）却始终无名的对象把问题关掉，且**不需要新增任何回收规则**；B 省下的是一句措辞，换来的是一条必须新写、且随时间失效即静默膨胀的回收规则。改一句「终态收敛」的成本低于新增一条回收规则。

### 2 · ch3 `completed`（元婴通关档）是否随之回收实体状态？

- **选项 A · 永久保留完整档。** 后果：玩家档案里留着每一个通关过的角色。**代价**：它**零消费方**——没有 ch4，C16 已裁定不做独立回看，`TotalCyclesCompleted`（C15）已承载「通关过几次」；每通关一次即在云端权威主档上永久多留一份完整角色状态。
- **选项 B（推荐）· 与 `defeated` 同档处置**：`TotalCyclesCompleted +1` 提交后回收实体状态列，只留墓碑（`id` · `characterDataId` · `chapter = 3` · `status = completed` · `chapterRetry`）。后果：`ChapterEndScreen` 的 ch3 变体**不受影响**——C9 的摘要在任何角色数据处置之前组装，且它读的两个账号级数字来自 `PlayerProfile`。
- **推荐 B 的理由**：ch3 `completed` 与 `defeated` 在「这一次轮回真正结束、这个角色不会再被任何流程读取」这一点上逐字同性；为它单开一条永久保留的特例，需要一个消费方，而 C16 恰好裁掉了唯一的候选消费方（回看）。
- **反向考量（请一并权衡）**：这是**唯一一处会让玩家「通关后角色消失」**的地方，情感上可能与「元婴为奖杯」（`ADR-0004:13`）的措辞相抵。若取向上希望留住奖杯感，选 A 并接受体积代价是完全正当的——本条因此不按推演直接落笔。
- **→ 已裁决（2026-09-06 · 批量评审）：选 A —— 永久保留完整档，不回收 ch3 `completed` 的实体状态。** 未采纳草稿推荐的 B；用户在明知「当前零消费方、每通关一次即在云端权威主档永久多留一份完整角色状态」的代价下，选择留住奖杯感（与 `ADR-0004:13` 的措辞一致）。

### 3 · 范围裁决（合并 interview 中由 orchestrator 追加的问题）

引发本条矛盾的那一句（`character-profile/_index.md:354` 与 `life-cycle-service.md:11`）一句同时覆盖 `defeated` 与 `completed` 两条出口，而 worker 在 §4 指出 `defeated` 那一半同样失准。

- **→ 已裁决（2026-09-06 · 批量评审）：两条出口一并收口。** `defeated` 侧按 §4 的提案落笔——清理 ≠ 立刻整条删除，保留身份与元进程格的「墓碑」、清空可继承实体状态。理由：两条出口写在同一句话里，分开收会留下第二次矛盾。
- 连带后果（与上方第 2 条的裁决合看）：ch3 `completed` 永久保留完整档，而 `defeated` 只留墓碑——两条出口的处置**自此不再对称**，§4 与 §3 字段分区表落笔时须按此区分，不得再复用「两条出口同档处置」的表述。

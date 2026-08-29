---
type: solution-draft
date: 2026-08-28
question: 角色模板池的形态 —— 池中有几个角色、是否账号级逐步解锁、能否重抽或指定
source: open-questions/06-meta-progression.md → 「角色模板池的形态（08-12f 新增 · 承重）」
targets: systems/character-profile/_index.md · terminology.md · content/_index.md · decisions/ADR-0055-character-as-content-template.md · systems/services/life-cycle-service.md（仅取向 B/C）· ux/screen-flow.md（仅取向 B/C）
status: decided
---

# 方案草稿 — 角色模板池的形态

## 问题

`ADR-0055` 已把角色升格为有身份的内容条目 `CharacterData`（自带一个神通 + 两门绑定功法，每局一致），
`CharacterProfile.characterDataId` 的**字段形态也已答定**（`string`，指向 `CharacterData.Id`，轮回创建时写一次不变，解析不到 → `PushError`）。
剩下的是**内容侧取值面 + 选取机制**三问，它们紧耦合、必须一起答：

1. **池中有几个角色**（首批规模）；
2. **是否账号级逐步解锁**；
3. **能否重抽或指定**。

它悬着卡住了三件事：`content/character/` 无法 `/scaffold-content-type` 开张（类型登记表就绪度 🟠）；
ch1 内容排期算不出「要写几个神通、几门绑定功法」的工作量；
以及**元进程压力模型的形状**——既定的「炼气可无限重试」在「重开就换一个角色」下与在「可指定角色」下是两种手感。

## 约束（来自既有设计）

**角色本体**

- **角色 = 有身份的模板，自带一个神通 + 两门绑定功法，每一局都相同；绑定功法可弃置。**
  → `decisions/ADR-0055-character-as-content-template.md`、`systems/character-profile/_index.md`「角色是有身份的模板」、`terminology.md` 角色（模板）一行。
- **开局底盘 = 2 门角色绑定功法 + 1 门选来的功法 + 1 件选来的法宝**，后两者由开局的强制 buff 事件三选一给出（两槽 `AllowDecline = false`）。
  → `systems/character-profile/deck/_index.md`、`systems/adventure-event/research/_index.md`。
- **内容成本明写：每门功法 × 每层各一套卡牌定义**（`ADR-0054`）⇒ 一个角色的边际内容成本 ≈ 1 个神通 + 2 门功法 × `MaxTier` 套卡牌定义。
- **`CharacterData` 至今没有字段表。** 全库已定的只有：一个绑定神通 + 两门绑定功法、稳定 `Id` + `ContentEnabled` + `.tres` 编写、可挂 `Artwork`。
  没有 `Rarity`、没有 `ExclusiveSource`、没有解锁条件字段、没有任何加载期校验。
  → `handoffs/2026-08-12f-cultivation-technique-deck-building.md`、`systems/common-properties.md`「`Artwork` 挂载面」。

**既定的选取语义**

- **「开局随机分配一个角色」是明文**（`systems/character-profile/_index.md`、`terminology.md`），承自 `handoffs/2026-07-15b`「炼气起手 = 随机角色，可无限重试」。
- **`CycleStartSpec` 目前没有模板参数**：`record struct CycleStartSpec(ulong Seed, int Chapter, string SourceCharacterId /* 空 = 炼气新角色 */)`。
  → `systems/services/life-cycle-service.md`。
- **UX 侧没有任何选角位置**：主菜单的核心操作是「在已解锁篇章中择一开始一次轮回」，五个入口里没有角色相关项，也没有角色选择屏。
  → `ux/screen-flow.md`、`ux/onboarding.md`。
- **ch1 重试 = 随机生成新角色**（故 `chapterRetry.Ch1RetryUsed` 对每个新角色恒为 0）；**ch2 / ch3 重试角色继承**，只换一套随机流。
  → `systems/character-profile/_index.md`、`systems/services/life-cycle-service.md`、`ADR-0004`。

**元进程与商业化的硬边界**

- **「元进程解锁」明确在范围之外（暂时）。** → `vision/scope.md`「范围之外」。
- **炼气可无门槛随机角色起手并无限重试；门禁只落在篇章层，不落在角色层。** → `ux/onboarding.md`。
- **首玩者「单一入口、零选择负担」是明写的收束。** → `ux/onboarding.md`。
- **付费面五项排除 + 唯一预留方向 = 纯外观；本作没有账号级可支配货币。** → `systems/monetization.md`、`ADR-0023`。
- **`PlayerEntitlement` 类内只放付费凭证本身与其兑现水位，不放任何派生量**；`Achievement` 的奖励形态已定为「指定的法则 / 古宝条目 + 成就限定」；Codex 只记「已解锁 = 见过」，是知识资产不是准入。
  → `systems/player-profile/_index.md`、`systems/player-profile/achievement/_index.md`。

**工程侧**

- **从内容集合抽取一律经 `AllEnabled()` 取池；读取侧 `Get(id)` 不过滤。** → `systems/services/content-service.md`、`.claude/rules/data-resource-rules.md`。
- **一切玩法随机从 `CycleSeed` 派生的具名子流取；子流清单是 `SeedManager` 内的常量（map / combat / shop / reward）。**
  判据：**结果写 `PlayerProfile` 的随机绝不可从 `CycleSeed` 派生**（角色分配结果写 `CharacterProfile`，不触此禁）。
  → `systems/common-properties.md`、`.claude/rules/state-save-rules.md`。
- **`StartCycle` 的子流初始化不走 `RngElements` 列**，故 `DrawCount` 单调不减的入口校验没有例外口子。→ `systems/services/life-cycle-service.md`。
- **条目 `Id` 两段式 `<内容类型>.<snake_case_slug>`。** → `content/_index.md`。

## 建议方案

### 1. 角色是「被抽取的内容」，照常参与 `AllEnabled()`；读取侧 `Get(id)` 不过滤

`[既有推演]`

判据用现成的那一条——**「能被抽取的才配有开关」**（`PlotArcData` 与 `LocationData` 的分野即此，见 `systems/services/plot-manager.md`、`systems/game-progression.md`）。
角色**是被抽取 / 被选取的产出侧对象**（每次新轮回从池里取一个），不是被查表定位的结构顶点 ⇒ 与 `PlotArcData` 同款：

- `CharacterData` 带 `ContentEnabled`，**照常参与 `AllEnabled()` 与 flags 通道**——关一个角色只让它**不再被新轮回选中**；
- **已写进 `characterDataId` 的角色照常经 `Get(id)` 解析**（读取侧不过滤），进行中的轮回不会因线上关闭而坏档。
  这正是既有的「解析不到 → `PushError`」与「线上可秒关一个问题角色」两条**不冲突**的原因，须在落笔时写明。

**推论：池规模不是一格数值旋钮，而是 `content/character/` 里 `ContentEnabled == true` 的条目数。**
新增一个角色 = 新增一份 `.tres` + 一个神通条目 + 两门功法条目，可加性成立；**本条不进 `systems/balance.md`**（角色池的归属已明确在 `systems/character-profile/`，且 `balance.md` 全文无角色池相关表）。

### 2. 加载期校验：五条（角色是启动期必须大声失败的一类）

`[既有推演]`（判据 = `.claude/rules/data-resource-rules.md`「坏数据必须在启动期大声失败」+ 既有交叉引用校验形态）

| # | 违规 | 处置 | 理由 |
|---|---|---|---|
| 1 | `AllEnabled<CharacterData>()` 条数 `== 0` | `PushError` | 无角色可分配 ⇒ 开不了任何轮回，是最硬的一条 |
| 2 | 条数 `< K`（仅取向 B：候选批规模） | `PushError` | 与礼包闸 ① 同款——内容侧硬保证的机械化 |
| 3 | 绑定的 `PowerId` / 两个 `TechniqueId` 解析不到 | `PushError` + 带 `characterId` | 悬空引用，走既有交叉引用校验 |
| 4 | 绑定的神通 / 功法 `ContentEnabled == false` | `PushWarning` + **该角色退出抽取池** | overlay 秒关一门坏功法是既定运营手段，不该让引用它的角色把整个启动打崩；但一个残缺角色不能被分配出去 |
| 5 | 绑定的 `PowerData.Scope != Character` | `PushError` | 角色自带的是**神通**不是法则，两层不得串写 |

**推论（承重）：角色的可抽取性 = 自身 `ContentEnabled` ∧ 全部绑定条目 `ContentEnabled`。**
它使第 4 条不需要任何运行时特判——取池时多一层过滤即可，与 `AllEnabled()` 的过滤位置完全同构。

### 3. `Id` 形态与「角色不带 `Rarity`」

`[既有推演]`

- `Id` 照两段式：**`character.<snake_case_slug>`**（例 `character.ling_yun`）。前缀 `character` 与既有主类型前缀词表（`character_item.` / `player_item.` / `character_power.` / `player_power.`）不撞车。
- **角色不带 `Rarity`，池内等权。** `Rarity` 在本库的两个消费点是**抽取加权**与**定价档**；角色既不进任何授予池、也不被定价，加一格 `Rarity` 会立刻引出「稀有角色抽不到」这条与「无门槛起手」正面冲突的语义。
- **角色不带 `ExclusiveSource`。** 该字段只覆盖 `PowerData` / `ItemData`，且语义是「不进抽取池」，与角色的取池方式无关。

### 4. 账号级逐步解锁：**建议首批不做**，全部角色恒可用

`[既有推演]`（三条依据，任一条单独成立即足以否决首批做）

1. **`vision/scope.md` 的「范围之外（暂时）」明写「元进程解锁」。**
2. **`ux/onboarding.md` 明写「炼气可无门槛随机角色起手」**——门禁只落篇章层。角色层再加一道门 = 把「无门槛」这四个字改掉。
3. **没有现成载体，做它必须扩 `PlayerProfile` 的字段面。** 三条既有通道都装不下：
   `PlayerEntitlement` 类内纪律明写「只放付费凭证本身与其兑现水位，不放任何派生量」；
   `Achievement` 的奖励形态已答定为「**指定的法则 / 古宝条目** + 成就限定」，角色不是那两类；
   Codex 记的是「见过」这一知识态，不是准入。
   ⇒ 做它 = `PlayerProfile` 第 17 个字段 + 一次 `schemaVersion` bump + 一条新的透明段 JSON path + 后端同批改，
   而它服务的是一个**明确出范围**的目标。
   （旁证：既定的**篇章**解锁同样没有一张解锁表——它的数据源是 `CharacterProfile.status` + `chapterRetry`，是一个**动态推导态**。
   本库至今不存在任何「解锁表」形态的载体，角色解锁会是第一个。）
4. **唯一「按账号过滤内容条目」的既有通道是 flags，而它在设计上不可复用于此。**
   flags 端点按账号解析、只下发 `disabledIds`，硬边界明写「只能覆盖 `ContentEnabled` 这一个布尔」，
   且**分桶规则不在客户端**——客户端没有任何按账号 / 按进度的判定输入，`AllEnabled()` 的签名被明确拒绝接受 `bucketContext`。
   → `systems/services/content-service.md`。**它是运营灰度通道，不是玩家进度通道，两者不得合流。**

**并且：解锁绝不可做成付费点。** `systems/monetization.md` 的负面边界五项 + 唯一预留方向（纯外观）已把它关死；
「付费解锁角色」既不是 ③ ④ 那种「有档、有上限的宽松化」，也不在纯外观内。这一条在落笔时应作为**明确的负面边界**写下，以免日后被当成一个自然的付费面重新提出。

**日后要做时的最小路径（写下来，使今天的不做不构成明天的债）：**
`PlayerProfile` 加一个具名集合字段（元素用 `readonly record struct` 包一层，照 `CodexEntry` 的**加法窗口**纪律，日后加一格是零迁移）
+ 一条取池过滤（`AllEnabled()` ∩ 已解锁集合）+ 一次 bump。**不需要任何新机制。**

### 5. 能否重抽或指定：**主轴取向**，推荐**取向 B（随机 K 选 1，K = 3）**

`[取向选择]` —— 三个选项、各自后果与落地形态见下节，推荐项与理由在此：

**推荐 B（开局从随机 3 个候选中择一），理由四条：**

1. **它兑现 `ADR-0055` 自己的理由句**——「玩家的选择从『随机拿到了什么』变成『这次我玩谁』」。取向 A 下这句话只兑现了一半（有身份，但没有选择）。
2. **它与既定的开局构筑形态逐字同构**：开局强制 buff 事件已经是「功法三选一 + 法宝三选一」。角色三选一不引入新的呈现语言，只是把同一个手感前移一步。
3. **它避开取向 C 的两个真实退化**：ch1 无限重试 + 完全指定 ⇒ 玩家锁定最强角色反复刷，角色间强度差立刻塌缩为「只有一个角色被玩」，
   而**跨轮回熟悉感只覆盖那一个**，`ADR-0055` 的「可辨认身份 + 内容扩展面」两个理由同时落空。
4. **它避开取向 A 的隐性 grind**：纯随机下「我想练某个角色」的唯一途径是反复重开刷角色，
   而 `systems/monetization.md` 明写「本作无体力、无 grind、无等待」。三选一把「刷」压成一次局内决策。

**不设重抽通道**（三个取向下均如此）：取向 B 的三选一本身就是那次选择，再叠一层重抽等于给一个免费 reroll，
与「候选预先算定、退出重进得到同一组、封死 reroll」这条既定纪律同向否决；且本作**没有账号级可支配货币**，重抽也无从定价。

## 具体形态（可 derive 的落地面）

### 池规模：**首批 4 个角色**（形状锚点 + 待校准初值）

`[通行做法]` + 推导：

| 边界 | 推导 |
|---|---|
| **下界 ≥ 3** | `N = 1` 时「随机分配」无语义、`PlotArcData.CharacterIds` 的角色专属剧本线没有对象；`N = 2` 时连续两局同角色的概率 50%，撑不住 ch1 的无限重试节奏 |
| **上界 ≤ 5** | MVP 只做 ch1；`content/character/` 尚未开张，功法与卡牌条目为零。`N = 6` 起需 ≥ 12 门绑定功法 × `MaxTier` 套卡牌定义，已超过 ch1 通用池的量级 |
| **取 4** | 连续两局同角色 25%；4 个神通 + 8 门绑定功法与既定切入点「优先打磨 ch1 内容，切入点是设计起始角色的 starter deck」体量匹配。取向 B 下 `N = 4`、`K = 3` 意味着**每局都有一个角色不在候选里**——候选仍是一次真实的随机 |

**同类作品口径**（`[通行做法]`）：Slay the Spire 首发 3 个角色、Balatro 起手牌组族群十余个但**逐步解锁**、月圆之夜 8 职业**逐步解锁**。
本作因「元进程解锁」出范围而走**首批小而全开**的路线，与 StS 首发形态最接近。

**旋钮位置：** 条目数本身（`content/character/` 的 `.tres` 数量），线上收缩用 `ContentEnabled` / flags。
**它是待实测校准的初值**——实际取值随 ch1 starter deck 打磨与功法条目规模一并定标（`vision/scope.md` 的既定顺序：先定形状、后定数值）。

### 选取机制：三个取向的落地形态

| | **A 纯随机分配** | **B 随机 K 选 1（推荐，K = 3）** | **C 全池指定** |
|---|---|---|---|
| **服务面** | `CycleStartSpec` **不变**；`StartCycle` 内部掷定 | `CycleStartSpec` 增一格 `string CharacterDataId`（空 = 由服务掷定，保 ch2/ch3 的 `SourceCharacterId` 路径不变）+ 新增前置方法 `OpResult<CycleStartDraft> PrepareCycleStart(int chapter)` | 同 B，但 `PrepareCycleStart` 只返回全池、不掷骰 |
| **RNG** | `Hash64(CycleSeed, "character")` 一次性派生，**不新增子流、不进 `RngElements`** | 同左：`PrepareCycleStart` 先生成 `Seed`，用 `Hash64(Seed, "character")` 掷出 K 个候选；玩家择一后 `StartCycle` **用同一个 `Seed`** | **零随机** |
| **入参校验** | — | `CharacterDataId` 必须落在该 `Seed` 掷出的候选集合内，否则 `OpResult.Fail`（否则候选只是装饰，UI 可越权指定） | `CharacterDataId ∈ AllEnabled()`，否则 `OpResult.Fail` |
| **UX** | 无新屏 | **新增角色选择屏**（主菜单 → 选炼气 → 角色选择 → 开始） | 同 B，卡片数 = 池规模 |
| **存档 schema** | **零增量** | **零增量** | **零增量** |

**RNG 形态的三条依据（`[既有推演]`，三个取向共用）：**

- **不新开第五条 RNG 子流。** 它每个轮回只掷一次、`DrawCount` 恒为 1，是一条死子流；
  而 `StartCycle` 的子流初始化**本就不走 `RngElements` 列**，为它开列会给「凡消耗了子流随机的提交必须同批带 `State`」这条不变式开一个例外口子。
  建议形态：`SeedManager` 内部以 `Hash64(<seed>, "character")` 造一个**临时** `RandomNumberGenerator`，**不进 `Stream(RngStream)` 的枚举、不进 `rng.stream[]`**。
- **不落存档、也不需要落。** 结果已由 `characterDataId`（写一次不变）承载，恢复路径**读结果、绝不重走取池链**——与「奖励候选预先算定、恢复时读结果不重抽」是同一条纪律的又一个实例。
- **合规于「账号级随机与轮回随机不相交」，且不走 `AccountRng`。** 该判据只禁「结果写 `PlayerProfile` 的随机从 `CycleSeed` 派生」；
  角色分配结果写 `CharacterProfile` ⇒ **应当**从 `CycleSeed` 派生。
  `AccountRng` 虽然正是「一次性派生、不落 RNG 状态」的明写先例（残卷 / 礼包两个用例），但它的域是账号级，且 `AccountStream` 的成员序**已冻结、只能追加**——
  给一个轮回级随机占一个账号域，会让「两条线不相交」这条判据本身失去可机械判定性。

**取向 B 的「退出选择屏再进 = 换一批候选」窗口：建议不封。** `[通行做法]`
此刻轮回尚未创建、`CycleSeed` 从未落存档、没有任何 `TryApply` 发生——它与「奖励预先算定所封的那个窗口」性质不同（后者封的是**局内已发生的结算**）；
StS / Balatro 的角色选择屏同样可退出重进。封它反而要引入一个「已掷未用的 seed」持久化态，为零收益付一次 schema 增量。

### 角色选择屏（仅取向 B / C）

`[通行做法]` + `[既有推演]`（约束来自 `.claude/rules/ui-input-rules.md` 与 `ux/` 既有形态）

- **位置**：主菜单 → 「切换篇章」选中炼气 → **角色选择屏** → 确认即 `StartCycle`。它是主菜单的一个子步骤，**不新增主菜单入口**（五项入口表不动）。
- **布局**：竖屏、K 张角色卡**横向滑动选择区**——沿用 eventOptions 已定的同款手感，不发明第二种选择语言。
- **每张卡呈现**：`Artwork`（角色形象，`CharacterData` 已定的唯一一格）+ 神通名与一行简述 + 两门绑定功法名与各一行简述。
  **不展示数值**，与「给方向不给数字」一致。
- **触控**：点选 + 独立确认按钮（防误触即开局）；**无 hover-only 可供性**。
- **文案**：全部走 `res://text/` 的 `MENU_` 分区（该分区已在 `ux/error-and-blocking-ux.md` 登记）。
- **既有灰态照常适用**：有待兑现购买时「开始新轮回」置灰的判据落在进入本屏**之前**，本屏不新增拦截点。

### 元进程压力模型：每个取向下「重开一次」意味着什么

| | ch1 重开（无限重试）意味着 | ch2 / ch3 重试 | 跨轮回熟悉感 | 已知风险 |
|---|---|---|---|---|
| **A 纯随机** | **命运换一个人**——你不选，你被分配。压力全在「适应手上这个角色」 | 角色继承，**不受影响**（三个取向皆然） | 被动累积：玩得多自然见得多 | 「想练某个角色」只能刷重开 = 隐性 grind，与「无 grind」明文相抵 |
| **B 随机 3 选 1（推荐）** | **命运给三张牌，你出一张**。压力从「适应」变成「读三个起手形状并挑一个」，且每局都有一次小构筑决策 | 同上 | 半主动：想练谁就在它出现时选它，不必刷 | 给首玩者加了一次选择，与 onboarding「零选择负担」有张力（见下） |
| **C 全池指定** | **完全同一个起点**——角色维度上重开零变化，压力线只剩「这一遍的随机流」 | 同上 | 只覆盖玩家自选的那一个 | 角色间强度差立刻塌缩为「只有一个角色被玩」；`ADR-0055` 的两条理由同时落空 |
| **（备选）逐步解锁** | 在**已解锁子池**内随机/择一，池随账号年龄增长 | 同上 | 与 B 同，但早期池更小 | 出范围（`vision/scope.md`）+ 需 `PlayerProfile` 扩字段 + 与「无门槛起手」相抵 |

## 后果

- **存档 schema 增量 = 0。** `PlayerProfile` 字段数不变（仍 16）、`CharacterProfile` 字段数不变（仍 25）、**不需要 bump `schemaVersion`**，
  因为 `characterDataId` 这一格早已存在且形态已答定。**这是本方案最重要的一条收益，三个取向皆然。**
- **后端零影响**：无新透明段 JSON path、无新报文、无回声约束字段。**不构成跨库改动。**
- **文档改动面：**
  - `systems/character-profile/_index.md` —— 「角色是有身份的模板」段追加池形态三问的答案；**移出「待决问题」的那一条**（由 `/analyze-new-ideas` 执行）。
  - `terminology.md` 角色（模板）一行 —— **仅取向 B / C 需改**：「开局随机分配一个角色」→ 相应措辞。
  - `content/_index.md` —— 类型登记表 `character/` 行的就绪度**维持 🟠**（仍阻于功法与神通条目），本方案不解除它；依赖链不变。
  - `decisions/ADR-0055` 的「后果」首条（「角色模板池的形态仍是未决项」）随之收口；**是否为本决策另立一份 ADR，建议由 `/write-adr` 在裁决后一并判定**，本草稿不预设。
  - **仅取向 B / C**：`systems/services/life-cycle-service.md`（`CycleStartSpec` 加一格 + `PrepareCycleStart`）与 `ux/screen-flow.md`（主菜单流程加一步 + 新屏）。
- **内容侧工作量随之可算**：4 个角色 ⇒ 4 个 `character-power/` 条目 + 8 门 `cultivation-technique/` 条目 × `MaxTier` 套卡牌定义。
  这是 ch1 排期必须正视的那一笔（`ADR-0054` 的「内容成本明写」在角色数上的乘法）。

## 备选方案（已考虑并否决）

- **首批就做账号级逐步解锁** — 出范围（`vision/scope.md`）+ 与「炼气无门槛起手」相抵 + 无现成载体（需 `PlayerProfile` 扩字段 + schema bump + 后端同批改）。日后最小路径已在建议方案 4 写下。
- **付费解锁 / 付费指定角色** — `systems/monetization.md` 的负面边界五项 + 唯一预留方向（纯外观）已关死；它既非「有档有上限的宽松化」，也非外观。
- **给角色开一条重抽通道**（局内消耗资源重抽 / 局外重抽券） — 本作无账号级可支配货币；且重抽等于免费 reroll，与「候选预先算定、封死 reroll」同向否决。取向 B 的三选一已经承担了那次选择。
- **把角色选择并进既定的开局强制 buff 事件** — `characterDataId` **轮回创建时写一次不变**，而强制 buff 事件发生在轮回创建**之后**；并进去就得引入一个「角色未定」的中间态，且要给 `CharacterProfile` 加一格可空——为省一屏付一次 schema 增量，不划算。
- **为角色新开第五条 RNG 子流** — 每轮回只掷一次的死子流，且会给 `RngElements` 的不变式开例外口子。
- **给 `CharacterData` 加 `Rarity` / 让角色按稀有度加权抽取** — `Rarity` 的两个消费点（抽取加权、定价档）角色都不参与；加权会造出「稀有角色抽不到」，与「无门槛起手」正面冲突。
- **把池规模写进 `systems/balance.md`** — 归属已明确在 `systems/character-profile/`；`balance.md` 全文无角色池相关表，新开一行即制造第二权威。
- **用 `CapabilityFlag` 的 `Unlock` 词表承载角色解锁** — 否决：`CapabilityFlag` 是**由内容条目聚合出的派生态、且受轮回级禁用截断**，
  `systems/monetization.md` 已用同一条判据否决它承载付费凭证（「派生态不能承载原始事实」）。账号级准入同属原始事实。
- **复用 flags 通道做「按玩家进度解锁角色」** — 否决：flags 是后端灰度通道（只覆盖一个布尔、分桶规则不在客户端、`AllEnabled()` 拒绝接受 `bucketContext`）。让运营灰度与玩家进度合流，等于把两种完全不同的失效语义写进同一个开关。
- **首批只做 1–2 个角色，其余随内容滚动追加** — `N ≤ 2` 让「随机分配」几乎无语义，且 `PlotArcData.CharacterIds` 的角色专属剧本线无对象；**可加性本就成立**（加角色 = 加 `.tres`），首批小到 2 只是把问题推迟，不省事。

## 与既有决策的张力

1. **「开局随机分配一个角色」是明文，取向 B / C 需要松动它。** 冲突的是 `ADR-0055` 的决策正文引用句 + `systems/character-profile/_index.md` + `terminology.md`，
   源头是 `handoffs/2026-07-15b`「炼气起手 = 随机角色」。
   **为什么需要松动**：`ADR-0055` 自己的理由句是「玩家的选择从『随机拿到了什么』变成『这次我玩谁』」，取向 A 只兑现了前半句。
   **松动的代价**：改一份 Accepted ADR 的引用句 + 两处主题文档措辞（本库明写 ADR 可直接改写，不必新开 ADR 取代）。
   **不松动时的替代**：落取向 A —— **本方案的其余部分（池规模 4、不做解锁、五条加载期校验、`Id` 形态、RNG 落点、零 schema 增量）完全不受影响**，只是不新增屏与服务方法。
2. **`ux/onboarding.md` 的「炼气可无门槛随机角色起手」+ 首玩者「单一入口、零选择负担」。** 取向 B / C 给首玩者加一次选择。
   **建议的缓解**：在选择屏对首玩局标注一个推荐项（内容侧一格标记），**不做「首局跳过选择」的特判**——特判会造出两条起手路径，而两条路径必然各自漂移。取向 A 无此张力。
3. **`CycleStartSpec` 与 `StartCycle` 的既定形态**：取向 B / C 要加一格入参 + 一个前置方法，是一次服务契约扩张。
   **代价明写**：`life-cycle-service` 的「不收 `character` 参数」纪律不受影响（那条约束的是 `AdvanceEventAsync`，且 `StartCycle` 本就是明写的例外）。

## 前置依赖

- **`CharacterData` 尚无字段表。** 本方案给出的加载期校验（五条）与取池语义在 `CharacterData` 的字段面成文之前**无法定稿到条目级**；
  建议随 `/scaffold-content-type character` 一并落——那一步本就要核对「字段是否已定案到能写实条目」。
- **内容依赖链：卡牌 → 功法 → 角色**（`content/_index.md`），而卡牌与功法条目当前均为零。
  ⇒ **池规模 4 是形状锚点，实际取值须待 ch1 starter deck 打磨与功法条目规模明朗后校准**（`deck/_index.md` 的三条待决：功法规模参数 / `MaxTier` / starter deck 内容）。
- **「死亡 / 轮回结束屏尚无设计」**（同分片 08-22 条）：取向 B / C 的角色选择屏若要展示「你用这个角色打到过哪」这类履历信息，依赖那一屏与「角色履历」的落点先定。**不阻塞本方案的主体**——首批选择屏只呈现静态模板信息。

## 仍需用户决定

### ① 开局角色的给出方式（主轴 · 阻断后续全部落笔）

| 选项 | 后果 |
|---|---|
| **A 纯随机分配一个**（保持既定明文不动） | 零新屏、零服务契约变更、零文档松动。代价：「想练某个角色」只能刷重开（隐性 grind），`ADR-0055` 的理由句只兑现一半 |
| **B 随机 K 选 1（K = 3）** ← **推荐** | 与既定的开局三选一形态同构；保住「随机」骨架的同时让「这次我玩谁」成为真实决策。代价：松动「随机分配」明文 + 新增一屏 + `CycleStartSpec` 加一格 + 首玩者多一次选择 |
| **C 全池指定** | 玩家完全掌控。代价：ch1 无限重试下角色强度差塌缩为「只有一个角色被玩」，跨轮回熟悉感只覆盖一个，`ADR-0055` 的两条理由同时落空 |

**推荐 B，理由：** 它是唯一同时满足「兑现 `ADR-0055` 的理由句」「不制造刷角色的隐性 grind」「不让角色池塌缩成单一最优解」三者的选项，
且它的呈现语言（三选一 + 横滑选择区）在本库已经存在，不是新机制。
**若选 B，请一并确认 `K = 3`**（`N = 4` / `K = 3` 意味着每局恰有一个角色不在候选内，随机性仍真实存在）。

→ **已裁决（2026-08-28 · 批量评审）：选项 C —— 全池指定。** 用户原话：**「改为全角色池供玩家选择，首批四个。」**

> 裁决过程如实记录：合并 interview 第一轮用户选 B（随机 3 选 1），第二轮在池规模一题上**改判为「全角色池供玩家选择」**。按「以最新的用户意图为准」，**C 是现行结论**，第一轮的 B 作废。

裁决口径（写给 `/analyze-new-ideas`，优先级高于本草稿正文的推荐项）：

- **玩家在开局从全部 4 个角色中自行选择一个**，无随机候选集、无重抽通道。
- **形态相对草稿 §「取向 B」的三处简化**（C 比 B 少三件事）：
  1. **不需要 `PrepareCycleStart(chapter)` 掷候选**——没有候选集可掷；若仍需一个前置方法用于「取可选角色列表」，它是**纯只读查询**（返回可抽取池），不消耗任何随机、不产生需要保序的状态。
  2. **完全不涉及 RNG**——草稿中「临时 `RandomNumberGenerator`、不进 `Stream(RngStream)`、不落存档」那一段整段作废（C 连临时 RNG 都不需要）。四条子流不变，`AccountStream` 不动。
  3. **校验由「所选 ∈ 候选集」改为「所选 ∈ 可抽取池」**（可抽取性 = 自身 `ContentEnabled` ∧ 全部绑定条目 `ContentEnabled`），仍须在服务侧校验以防 UI 越权指定一个被 flags 关掉的角色。
- **保留不变**：`CycleStartSpec` 加一格 `CharacterDataId` · 五条加载期校验（其中「条数 < K → `PushError`」改为「池为空 → `PushError`」，K 已不存在）· `Id` 形态 `character.<snake_case_slug>` · 角色不带 `Rarity` / `ExclusiveSource` · **首批不做账号级解锁**（含「解锁不得做成付费点」的负面边界）· 存档 schema 零增量 · 后端零影响。
- **随裁决被接受的代价**（草稿已如实列出，用户在知悉后仍选 C）：**ch1 无限重试下，角色强度差会塌缩为「只有一个角色被玩」**，跨轮回熟悉感只覆盖一个角色，`ADR-0055` 的两条理由句因此只兑现一部分。**提炼时不得把这条代价删掉**——它是日后重估角色池设计的判据起点。
- **张力 1 确认为「需松动」**：`ADR-0055` 决策正文的「开局随机分配一个角色」引用句、`systems/character-profile/_index.md` 与 `terminology.md` 的对应措辞，须一并改写为「开局由玩家从角色池中指定」。本库明写 ADR 可直接改写，**改的是那份 ADR 本身，不新开一份取代它**。
- **张力 2 的缓解照旧采纳**：首玩局在选择屏标注推荐项，**不做「首局跳过选择」的特判**。

### ② 首批池规模

| 选项 | 后果 |
|---|---|
| **4** ← **推荐** | 连续两局同角色 25%；内容量 = 4 神通 + 8 门绑定功法 × `MaxTier`，与 ch1 排期匹配 |
| **3** | 内容量最省（对齐 StS 首发）；但取向 B 下 `N = 3` / `K = 3` ⇒ 候选恒为全池，「随机候选」退化为「全池指定」，B 与 C 无差别 |
| **5–6** | 辨识度与重玩新鲜度更好；内容量翻倍，压 ch1 排期 |
| **随 ch1 内容排期一并定** | 不在此刻拍板，`content/character/` 的开张随之推迟 |

**推荐 4，理由：** 它是唯一能让取向 B 真正成立的下界（`N > K`），同时把内容成本压在 ch1 可承受的量级内。
**它是待实测校准的初值**，日后增减角色是纯加法（加一份 `.tres`），不改任何结构。

→ **已裁决（2026-08-28 · 批量评审）：4。**

- 取向 ① 既已改判为 C（全池指定），`N > K` 这条下界理由不再适用——**4 在 C 下的成立理由改为**：内容量（4 神通 + 8 门绑定功法 × `MaxTier`）与 ch1 排期匹配，且全池选择时 4 个选项在竖屏一屏内可完整呈现、无须滑动分页。
- **仍是待校准初值**，增减角色是纯加法。
- **连带**：同批 `solution-draft-realm-progression-artwork-basis.md` 裁定「玩家角色随境界换形象」⇒ 角色立绘全量 **4 × 4 = 16 张**、**MVP（炼气 → 筑基）8 张**、首发下限 4 张（稀疏数组允许先只出基础一套）。这条资产账须随本裁决一并交给 `art/` 侧。

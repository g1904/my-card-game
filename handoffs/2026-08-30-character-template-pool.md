# 角色模板池：全池指定 · 首批 5 个 · 不做账号级解锁

- id: 2026-08-30-character-template-pool
- date: 2026-08-30
- topic: systems/character-profile/_index.md · systems/services/life-cycle-service.md · ux/screen-flow.md · ux/onboarding.md · terminology.md · decisions/ADR-0055
- status: distilled
- distilled-to: systems/character-profile/_index.md、systems/services/life-cycle-service.md、ux/screen-flow.md、ux/onboarding.md、terminology.md、decisions/ADR-0055-character-as-content-template.md、decisions/ADR-0101-chapter-retry-counter-carrier.md

> 与 `2026-08-30-affinity-and-technique-attributes.md` 是同一批的两半：本份定角色池的**取用方式与规模**，那份定角色之间的**第二条辨识轴（灵根）**。池规模 5 由灵根一侧推出（五行各一），两份必须一起读。

## Intent（distilled）

`ADR-0055` 已把角色升格为有身份的内容条目 `CharacterData`（自带一个神通 + 两门绑定功法，每局一致），但**内容侧取值面 + 选取机制**三问一直悬着：池中有几个角色、是否账号级逐步解锁、能否重抽或指定。它卡住三件事：`content/character/` 无法开张；ch1 内容排期算不出「要写几个神通、几门绑定功法」；元进程压力模型的形状没有定论。

三问同时答齐：

### 1. 选取机制 = 开局由玩家从全池指定

**取代既定明文「开局随机分配一个角色」。** 无随机候选集、**无重抽通道**（重抽等于免费 reroll，与「候选预先算定、封死 reroll」同向否决；且本作没有账号级可支配货币，重抽也无从定价）。

- **完全不涉及 RNG。** 不新开第五条子流、四条既有子流不变、`AccountStream` 不动、`StartCycle` 的子流初始化照旧不走 `RngElements` 列——「凡消耗了子流随机的提交必须同批带 `State`」这条不变式一个例外口子都不开。
- **服务面 = `CycleStartSpec` 加一格 `CharacterDataId` + 一个纯只读查询 `GetSelectableCharacters()`。** 后者返回可抽取池，不消耗随机、不产生需保序的状态、不落存档。`StartCycle` 校验「所选 ∈ 可抽取池」——防的是 UI 越权指定一个被 flags 关掉的角色。
- **UX = 新增一屏角色选择屏**，它是主菜单的一个子步骤，**不新增主菜单入口**。

### 2. 池规模 = 5（首批）

**它不是一格数值旋钮，而是 `content/character/` 里 `ContentEnabled == true` 的条目数**；线上收缩用 `ContentEnabled` / flags。增减角色是纯加法。**不进 `systems/balance.md`**——归属在 `systems/character-profile/`，`balance.md` 全文无角色维度数值表，新开一行即制造第二权威。

**内容量账：** 5 个 `character-power/` 条目 + 10 门 `cultivation-technique/` 条目 × `MaxTier` 套卡牌定义。

### 3. 首批不做账号级逐步解锁，全部角色恒可用

三条依据任一单独成立即足以否决首批做：「元进程解锁」明确在范围之外 · 炼气无门槛起手、门禁只落篇章层 · 没有现成载体（三条既有通道 `PlayerEntitlement` / `Achievement` / Codex 都装不下，flags 是运营灰度通道而非玩家进度通道）。

**负面边界（承重）：解锁绝不可做成付费点。** 付费面五项排除 + 唯一预留方向（纯外观）已把它关死。**日后要做时的最小路径已写下**（`PlayerProfile` 加一个具名集合字段 + 一条取池过滤 + 一次 bump），使今天的不做不构成明天的债。

### 4. 角色是「被选取的产出侧对象」，故配有 `ContentEnabled`

判据用现成的那一条——「能被抽取 / 被选取的才配有开关」。关一个角色只让它不再被新轮回选中；已写进 `characterDataId` 的角色照常经 `Get(id)` 解析，**进行中的轮回不因线上关闭而坏档**。

**可抽取性 = 自身 `ContentEnabled` ∧ 全部绑定条目 `ContentEnabled`** ——它使「绑定条目被关掉」不需要任何运行时特判。

### 5. `CharacterData` 的字段面就此成文

`Id`（`character.<snake_case_slug>`）· `ContentEnabled` · `Artwork` · `PowerId` · `TechniqueIds`（长度恒 2）· `Affinities`（来自同批的灵根一份）· 绑定功法的初始层数（⟨待定⟩）。**明确不带** `Rarity` / `ExclusiveSource` / 任何解锁条件字段。

**存档 schema 增量 = 0**（`characterDataId` 早已存在且形态已定），**不 bump `schemaVersion`、后端零影响、不构成跨库改动**。

## 已接受的代价（承重，不得删）

ch1 无限重试 + 全池指定下，**角色强度差有可能塌缩为「只有一个角色被玩」**，跨轮回熟悉感因此只覆盖玩家自选的那一个。灵根把角色差异从「谁更强」推向「能修哪一路功法」，已**部分**缓解这条代价，但**仍可能存在一个综合最优的属性池**——待实测。这条代价是日后重估角色池设计的判据起点。

对 onboarding「零选择负担」的张力同样被接受，缓解 = 首玩局在选择屏**标注推荐项**，**不做「首局跳过选择」的特判**（特判会造出两条起手路径，而两条路径必然各自漂移）。

## Clarifications（interview 产物）

- **主轴取向（纯随机 / 随机 K 选 1 / 全池指定）→ 用户裁决：全池指定。** 原话「改为全角色池供玩家选择」。推翻了草稿推荐的「随机 3 选 1」，也推翻了既定明文「开局随机分配一个角色」。
- **首批池规模 → 4 → 被同批的灵根裁决覆盖为 5。** 按「以最新的用户意图为准」，以 5 落笔；`4 神通 + 8 门功法` 的量账随之改为 `5 + 10`。
- **`ADR-0055` 的改写落点 → 「后果」首条。** 草稿称要改「决策正文的『开局随机分配一个角色』引用句」，逐字核对后该句在 ADR-0055 中并不存在；真正需要收口的是「后果」里「角色模板池的形态仍是未决项」那一条。明文松动落在 `systems/character-profile/_index.md` 与 `terminology.md`。
- **角色选择屏是否承诺「5 张一屏无滑动」→ 不承诺。** 保留横滑选择区（不发明第二种选择语言），同屏容纳度写为**待实测**，不写成设计断言。
- **`CharacterData` 字段表是否本次就地建起 → 是。** 六格里五格已定，一次写齐；两份草稿合计十一条加载期校验因此能定稿到条目级。「绑定功法的初始层数」一格挂 ⟨待定⟩。

## Open questions

- **两门绑定功法的初始层数**（全库无明文）—— `content/character/` 条目写到 `ready` 的前置。
- **全池指定下角色强度差是否仍塌缩为单一最优** —— 待实测。

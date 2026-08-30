# ADR-0123 — 灵根与功法属性：唯一的规则后果是硬性修习准入

- **状态：** Accepted
- **日期：** 2026-08-30
- **来源：** handoffs/2026-08-30-affinity-and-technique-attributes.md

## 背景

修仙题材最基本的两个分类轴——角色的先天资质（灵根）与一门功法走哪一路（属性）——在本库一格都没有。同时角色之间除「神通 + 两门绑定功法」外没有第二条辨识轴，功法也没有任何与角色身份挂钩的构筑条件。

补这两轴的加法窗口现在敞开：`content/cultivation-technique/` 与 `content/character/` 均未开张；第一批 `.tres` 落下那一刻，成本从「加两个字段」转为「重扫全部条目」。

## 决策

新增封闭枚举 `Affinity`：`Unspecified = 0` 哨兵 + 五行 `Metal` / `Wood` / `Water` / `Fire` / `Earth`。**五行之间不设相生相克、无契合度、无品级说法。**

字段分两层，卡牌侧一格不加：

- `CharacterData.Affinities : Affinity[]` —— 角色的先天灵根，首批五个角色各为单灵根（长度为 1 是内容编排口径，不是字段约束）。
- `CultivationTechniqueData.RequiredAffinities : Affinity[]` —— 允许为空数组 = 无属性要求的通用功法。
- `CultivationTechniqueData.MaxCharacterAffinityCount : int` —— `1` = 单灵根专属，`0` = 不限。

**唯一的规则后果是一条布尔式硬性修习准入** `CanLearn(character, technique)`（两个合取项：要求的属性是角色灵根的子集，且角色灵根总数不超过上限）。不满足即不进入该角色的任何玩家侧候选。判定式与逐条落点见 `systems/character-profile/deck/_index.md`；枚举、角色侧字段面与全部加载期校验见 `systems/character-profile/_index.md`。

配套：AI 评分项 `KeyCardAffinity` 改名 `KeyCardBias`，把 `Affinity` 让给灵根。角色池规模定为 **5**（五行各一）。

## 理由

- **卡牌不加属性是结构性的，不是取舍。** 一张卡可被多门功法引用 ⇒ 卡级属性与功法级属性必然打架，而本库没有机制发现两者不一致；且战斗内不感知功法 ⇒ 卡级属性无法与角色灵根建立任何战斗内关系，剩下的只是没有规则后果的风味标记。
- **准入不进 `DrawPool<T>`。** 按既定的分界判据「这道过滤需不需要读 `Profile`」（`decisions/ADR-0068-draw-primitives-two-levels.md`），准入要经 `characterDataId` 读到 `Affinities`，故落在调用方侧——与四处已有的 `Pool != Enemy` 同址同形，零新原语、零签名变更。
- **敌人侧不做准入**：`EnemyData` 逐条引用功法 `Id`，走读取侧 `Get(id)` 而非取池，准入对它无处作用。
- **灵根只接这一处。** 它不影响 mana、道念、寿元、商店价格、隐藏属性、经验值、`baseMomentum`、敌人赋级与任何战斗内规则——每一项都已有指定的唯一旋钮，往上叠第二个输入正是本库反复否决的「第二条强度曲线」。
- **不落在 `vision/scope.md` 的「范围之外：完整属性模型」内**：灵根不产生运行时状态、不进 `CharacterProfile`，与 `Rarity` / `Pool` 同族而非与 `faith` / `bloodlust` 同族。

## 备选方案

- **属性挂到卡牌上（`CardData` 加一格）** — 与功法级属性必然不一致且本库无从发现；战斗内不感知功法使它无法产生规则后果。
- **功法侧沿用 `Affinities` / `MaxAffinityCount` 命名** — 与 `CharacterData.Affinities` 同名不同义；`MaxAffinityCount` 与同类上的 `MaxTier` 主语不一致。改为 `RequiredAffinities` / `MaxCharacterAffinityCount` 后判定式主语自明。
- **改名灵根侧以避开 `KeyCardAffinity`** — 按本库三处同型先例（`Tier` / `RarityTier` 等），给成本低的那侧加区分；冲突的另一侧只是尚未落代码的枚举成员名。
- **灵根轮回内可变** — 首批不做；固定在 `CharacterData` 上，日后可变的最小路径已写下。
- **不开通用功法档（`RequiredAffinities` 必填）** — 会把首批内容量抬到五份互不相通的小池；开通用档后池形状为「五份小池 + 一份共享池」。

## 后果

- **存档 schema 增量 = 0，后端零影响，不构成跨库改动。** 新增结构面仅一个封闭枚举 + 三个 `[Export]` 字段；零新增服务 / manager / element 列 / `Op` / 决策点 / RNG 子流 / 屏 / 平衡资源。
- **硬收缩带来三条必须一起落笔的账单**（真正的成本所在）：三格取池余量须按收缩后的池（按可修条目最少的那个灵根）重估 · `decisions/ADR-0073-pickmany-shortfall-three-gates.md` 的三段处置须按新口径复核 · 内容编排从建议升格为硬约束（每个在册角色的可修功法条目数 ≥ 取池余量阈值，低于即加载期 `PushError`），并在 `/audit-content` 另加一条 🔴 级核对项。
- 呈现三处全部落在既有屏内（角色选择屏 / 功法候选卡 / 功法图鉴词条），**卡面上不加任何属性标记**；不可修的功法本就不出现，故无灰显态。
- 追加枚举成员（雷 / 冰 / 风）成本为零：不落存档、不进上行负载，不 bump `schemaVersion`。
- **仍未答**：多灵根角色的强度对齐换算（首批全单灵根故不发生，引入第一个多灵根角色时必须先答）· 通用功法占比口径 · 三格取池余量的新取值。
- 因此必须这么写的文档：`systems/character-profile/_index.md`（枚举 + 字段表第 7 格 + 校验 6~9）· `systems/character-profile/deck/_index.md`（判定式与四处取池点）· `systems/adventure-event/research/common-properties.md` · `systems/services/future-event-service.md` · `systems/player-profile/codex/technique-codex.md`（词条增「属性」一行）· `terminology.md`。

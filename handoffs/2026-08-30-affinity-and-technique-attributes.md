# 灵根 `Affinity` 与功法属性：硬性修习准入

- id: 2026-08-30-affinity-and-technique-attributes
- date: 2026-08-30
- topic: systems/character-profile/_index.md · systems/character-profile/deck/_index.md · systems/adventure-event/research/common-properties.md · systems/adventure-event/exchange/common-properties.md · systems/services/combat-service.md · systems/services/future-event-service.md · systems/balance.md · systems/enemies/_index.md · systems/player-profile/codex/technique-codex.md · ux/screen-flow.md · terminology.md
- status: distilled
- distilled-to: systems/character-profile/_index.md、systems/character-profile/deck/_index.md、systems/adventure-event/research/common-properties.md、systems/adventure-event/exchange/common-properties.md、systems/services/combat-service.md、systems/services/future-event-service.md、systems/balance.md、systems/enemies/_index.md、systems/player-profile/codex/technique-codex.md、ux/screen-flow.md、terminology.md、.claude/skills/audit-content/SKILL.md

> 与 `2026-08-30-character-template-pool.md` 是同一批的两半：那份定角色池的取用方式与规模，本份定角色之间的第二条辨识轴。池规模 5 由本份推出（五行各一）。

## Intent（distilled）

修仙题材里，**灵根**（角色的先天资质）与**功法属性**（一门功法走的是哪一路）是这个世界观最基本的两个分类轴，而本库一格都没有。补上它们，同时给角色池一条「除神通 + 两门绑定功法之外」的辨识轴，给功法一条与角色身份挂钩的构筑条件。

**加法窗口现在敞开**：`content/cultivation-technique/` 与 `content/character/` 均未开张，第一批 `.tres` 写下那一刻成本转为「重扫全部条目」。

### 1. 两层：灵根挂角色、属性挂功法；卡牌侧一格不加

| 层 | 载体 | 形态 |
|---|---|---|
| **灵根** | `CharacterData.Affinities` | `Affinity[]`，首批长度恰为 1（五个角色各一个单灵根） |
| **功法的属性要求** | `CultivationTechniqueData.RequiredAffinities` | `Affinity[]`，功法要求角色**具备的**灵根属性；**允许为空 = 无属性要求的通用功法** |
| **功法对角色灵根数的要求** | `CultivationTechniqueData.MaxCharacterAffinityCount` | `int`；`1` = 单灵根专属，`0` = 不限 |
| **卡牌** | `CardData` | **不加任何格** |

**卡牌不加属性是结构性的、不是取舍：** 一张卡可被多门功法引用 ⇒ 卡级属性与功法级属性必然打架，而本库没有机制发现它们不一致；且战斗内不感知功法 ⇒ 卡级属性无法与角色灵根建立任何战斗内关系，剩下的只是一个风味标记，而没有规则后果的分类维度本库连概念占位都不给。**负面边界随之落笔**：日后要做战斗内五行相克，载体只能是既有次类型 `CardSubtypeData` + `EntryFilter.RequiredSubtypes`，且须照常过准入判据。

### 2. `Affinity` = 五行五值 + 一个哨兵

`Unspecified = 0`（防御性哨兵，照 `Source.Unknown = 0` 先例）· `Metal` · `Wood` · `Water` · `Fire` · `Earth`。

**首批不做相生相克、无契合度、无「天灵根」品级说法**——五行之间没有任何规则关系。**追加成员（雷 / 冰 / 风）成本为零**：不落存档、不进上行负载 ⇒ 不 bump `schemaVersion`、无迁移、后端零影响。

### 3. 唯一的规则后果 = 硬性修习准入

```
CanLearn(character, technique) :=
      technique.RequiredAffinities ⊆ character.Affinities
  && (technique.MaxCharacterAffinityCount == 0
      || character.Affinities.Length <= technique.MaxCharacterAffinityCount)
```

不满足 ⇒ 该功法不进入该角色的任何玩家侧候选（四个取池点 + `UpgradeTechnique` 候选一律过滤掉）。

- **实现为单点纯函数**，各调用方各调一次；实际的抽取代码落点是**三段**（开局构筑与闭关共用同一条链），不是四段。
- **不进 `DrawPool<T>`**：这道过滤需要读 `Profile`，按既定分界判据它落在调用方侧——与四处已有的 `Pool != Enemy` 同址同形，**零新原语、零签名变更**。
- **敌人侧一律不做准入**：`EnemyData` 走读取侧 `Get(id)` 而非取池；敌方功法照常带属性，纯作图鉴价值。
- **`MaxTier` 一律不折减**：灵根表达「能不能修」，不表达「能修多深」——`MaxTier` 就是这门功法已写了几套卡牌定义。

### 4. 硬收缩带来三条必须一起落笔的后果

1. **三格取池余量须按收缩后的池重估**（按可修条目最少的那个灵根定阈值）；
2. **`ADR-0073` 候选短缺三段处置的边界须按新口径复核**；
3. **内容编排从建议升格为硬约束**：每个在册角色的可修功法条目数 ≥ 取池余量阈值，低于即加载期 `PushError`。

**这是整份方案的真正成本所在**，不是缺陷而是这个形态的必然账单。

### 5. 负面边界：灵根只接修习准入这一处

不影响 `mana` / `manaLimit` · 道念 · 寿元与 `lifeSpanCost` · 商店价格 · 隐藏属性 · 经验值 · `baseMomentum` · 敌人赋级 · 任何卡牌数值 · 任何战斗内规则。逐条依据：战斗侧那一批看不见功法；其余每一项都已有指定的唯一旋钮，往上叠第二个输入正是本库反复否决的「第二条强度曲线」。

### 6. 呈现三处，全部落在既有屏内

角色选择屏（每张卡一行灵根图标 + 名称，不写品级标签、不写数值）· 功法候选卡（属性图标 + 「单灵根专属」角标；**不可修的功法本就不出现，故无需灰显态**）· 功法图鉴词条（增「属性」一行）。**卡面上不加任何属性标记。**

### 7. 内容编排口径

**功法池的形状 = 五份小池 + 一份共享池。** 通用功法是压低首批内容量的主要手段，但**占比须控制**——占比过高会把灵根辨识度稀释回「五个角色抽到的东西差不多」。取向：底盘共享、亮点分化。

**`MaxCharacterAffinityCount = 1` 的单灵根专属功法首批可以为空**（五个角色全是单灵根，不需要对冲）；它的内容义务在引入第一个多灵根角色的同一批产生。

## 成本与边界

- **存档 schema 增量 = 0 · 后端零影响 · 不构成跨库改动。**
- **新增结构面共两项**：一个封闭枚举 `Affinity`、三个 `[Export]` 字段。零新增服务 / manager / element 列 / `Op` / 决策点 / RNG 子流 / 屏 / 平衡资源。
- **边界情形：** overlay 中途改了灵根或功法属性 ⇒ 已持有的功法**读档不拒绝、不没收、不告警**，只是此后不进 `UpgradeTechnique` 候选。落在既有的「不承诺跨内容版本复现」之内。
- **空数组与漏填不可区分，接受该风险**（`RequiredAffinities` 与 `MaxCharacterAffinityCount == 0` 同理）：漏填的后果是可见性放宽而非越界，`Pool` 仍在独立把关；收紧路径是加一格显式的 `NoAffinityRequired` 布尔标记，而不是把空数组重新变成非法。

## Clarifications（interview 产物）

- **`Affinity` 与既有 `KeyCardAffinity` 撞名 → 保住灵根的 `Affinity`，改名 AI 侧那一格为 `KeyCardBias`。** 草稿 front-matter 宣称的「全库零命中」不成立：`Affinity` 已作为 `KeyCardAffinity`（敌人 AI 评分项）出现在三份文档四处。按本库三处同型先例（`Tier` / `RarityTier`、`level` / `TechniqueTier`、`LevelBand` / `EnemyLevelRange`）的处置——给两者中成本低的那个加区分——冲突的另一侧只是一个尚未落代码的枚举成员名。
- **功法侧两格的标识符 → `RequiredAffinities` + `MaxCharacterAffinityCount`。** 草稿原定 `Affinities` + `MaxAffinityCount`，与 `CharacterData.Affinities` 同名不同义、且 `MaxAffinityCount` 与同类上的 `MaxTier` 主语不一致。判定式写作 `technique.RequiredAffinities ⊆ character.Affinities` 时主语自明。
- **「可修功法数不足」的核对落在哪里 → 两个落点都要。** ① 加载期校验（`PushError` + 抛，带 `characterId` 与实际条数）是运行期硬阻断的唯一落点；② `/audit-content` 另加一条 🔴 级核对项作为内容编排期的提前发现。草稿写的「`/audit-content` 加一条阻断级核对」在该技能里无处安放——它没有阻断语义，只有三档报告严重度；故技能侧只加 🔴 级报告项、不宣称阻断。
- **角色池规模 → 5**（对应五个单灵根），**本条覆盖同批 `character-template-pool` 草稿的 4**。
- **灵根是否落在 `vision/scope.md`「范围之外：完整属性模型」内 → 不落在排除项内，整套做。** 依据：灵根不产生运行时状态、不进 `CharacterProfile`，与 `Rarity` / `Pool` 同族而非与 `faith` / `bloodlust` 同族。`scope.md` 原文未点名灵根，**不改该文件**；改为在 `systems/character-profile/_index.md` 写一句正面陈述，使日后无人拿那行否决它。
- **灵根固定还是轮回内可变 → 固定在 `CharacterData` 上，一局不变**，并写下日后可变的最小路径（首批不做）。
- **是否开一档「无属性要求」的通用功法 → 开**，`RequiredAffinities` 允许为空数组；池形状因此是「五份小池 + 一份共享池」，内容量显著下降。
- **`character-template-pool` 的「已接受的代价」→ 改写而非删除**：改为「已由灵根部分缓解，仍待实测」的正面陈述。
- **顺手补齐的既有不齐处**：`exchange/common-properties.md` 的取池链伪代码与 `future-event-service.md` 的复述都漏写了 `Pool != Enemy`，本次一并补齐（限本次改动触及的小节）。

## Open questions

- **多灵根角色的强度对齐换算尚无解法。** 对冲手段结构已就位，但「多宽的可修池 = 多强的专属功法」这条换算没有答案，且依赖尚未定的道念量纲。首批全为单灵根，故在首批不发生；引入第一个多灵根角色时必须先答。
- **通用功法（无属性要求）的占比口径。** 编排取向已定，取值随 ch1 starter deck 打磨定。
- **三格取池余量在新口径下的取值** —— 结构不被它阻塞（可先填 0）。

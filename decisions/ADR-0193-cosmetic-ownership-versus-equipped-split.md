# ADR-0193 — 外观「持有」落 `PlayerEntitlement.Cosmetic`、「选用」落 `GameSetting` 账号级具名字段

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07b-cosmetic-monetization-shape.md · answer-logs/log-cosmetic-monetization-shape.md

## 背景

「一个具名字段」的具体形状不定，预留就没有可核对的兑现物。而既有判据「`PlayerEntitlement` 用具名字段而非集合」按字面禁止集合字段，与所需形态直接抵触。

## 决策

**持有** → `PlayerEntitlement.Cosmetic : IReadOnlyList<CosmeticEntry>`，元素 `readonly record struct CosmeticEntry(string Id)`；只由后端写、不配兑现水位、不加 `Status` / `Charges` / `SourceCode`。

**选用** → `GameSetting` 的账号级逐品类具名字段（形如 `EquippedCharacterSkin : string?`）；`null` = 默认外观、不设伴生布尔；未持有 id → `PushWarning` + 回落 `null`，**不改写字段、不上行纠正**。它**进 `GameSetting` 这个类但不进设置屏**，换装的呈现落点是角色选择屏。

**同批把既有判据收口为：禁的是以付费点种类为 key 的开放容器；内容条目实例的持有集仍是 id 集合。**该句已就地改写在 `systems/player-profile/_index.md`，不新开取代条目。

## 理由

`systems/player-profile/_index.md`：**一个具名字段的类型可以是列表**——当元素是 `ContentRegistry` 可解析的内容 `Id`（不是自由 key）时，合法性校验由注册表接管。

`systems/player-profile/game-setting.md`：按 `decisions/ADR-0072-setting-scope-criterion.md` 的自检反问——玩家换新手机登录同一账号，会觉得这一项理应还是上次调好的样子 ⇒ 账号级。**持有校验不落在读档钳制里**：`entitlement` 侧是后端权威，客户端拿本地判断去覆写选用值，只会在权益尚未 pull 到时误清玩家的选择。

## 备选方案

- **裸 `string[]` 而非包 record** — 否决：裸 `string` 则元素形状从标量变对象，是一次真实的破坏性变更。
- **加伴生布尔「是否使用默认外观」** — 否决：与不设 `IsMuted` 逐字同判据。
- **选用项落 `PlayerEntitlement`** — 否决：那里只放凭证与兑现水位。
- **新开取代条目而非就地改写判据** — 否决：本库治理原则是直接改原句。

## 后果

- 落地时须一次 schema bump（持有 + 选用两格同批）+ 一次跨边界成对落笔（`/entitlement/cosmetic` 受回声约束）。
- 放弃了「设置屏 = `gameSetting` 字段一一对应」的直觉读法。
- 约束 `systems/services/profile-schema-versions.md` 与 `systems/services/sync-service.md` 按此形态登记。

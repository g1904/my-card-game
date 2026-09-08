# Answer log cosmetic-monetization-shape

- 日期：2026-09-07
- 来源：`inbox/solution-draft-cosmetic-monetization-shape.md` → `handoffs/2026-09-07b-cosmetic-monetization-shape.md`
- 移出条数：1

**纯外观付费点做成什么** → 两半均答定。

**① 品类与顺序**：**角色皮肤为首个品类**（`CharacterData.Artwork` + `RealmArtworks` 稀疏覆写已成形，零新机制）· **卡背为第二品类**（单套 1 张图，但须先确认牌堆背面在竖屏战斗屏上有稳定可见面——该确认仍开放，见下）· **界面主题明确不做**（对未来每一个新屏永久征税，且 UI 元件不走既有资产产出流水线；将来若要做须先答「主题覆盖到哪一层」）。

**② 字段形状**：
- **「架构预留」的兑现物 = 三个加法窗口保持开启**（`PlayerEntitlement` 可加具名字段 · `GameSetting` 可加账号级具名字段 · Store 屏可容纳新结果态），**首批不为外观增加任何字段、屏、内容类型或资产类目**。**明确否决占位字段**——它会把一个永远为空的结构固化进 golden 快照与后端回声封闭表，而加法窗口本就开着。
- **持有** = `PlayerEntitlement.Cosmetic : IReadOnlyList<CosmeticEntry>`（元素 `record struct CosmeticEntry(string Id)`），**只由后端写**、**不配兑现水位**（无随机、无内容抽取 ⇒ 三道空池闸与 `GrantPoolMargin` / `K` 一概不适用），不加 `Status` / `Charges` / `SourceCode`。
- **选用** = `GameSetting` 的账号级具名字段（逐品类一格，形如 `EquippedCharacterSkin : string?`，`null` = 默认外观）；**不进 `PlayerEntitlement`**，**不进设置屏**（换装落角色选择屏）。
- **外观条目 = 一个内容类型**，落地时才开张（首批不建文件夹、不进登记表）；`Artwork` 一格够用。
- **呈现落点 = Store 屏内**，不新增屏、不新增主菜单入口。
- **上新节奏**：二进制资产随发版 ⇒ 每上一套外观 = 一次客户端发版 ⇒ 外观是低频成套发布的付费面，赛季式高频上新在本作**结构上就不成立**。

（`systems/monetization.md` · `systems/player-profile/_index.md` · `systems/player-profile/game-setting.md` · `vision/scope.md`）

## interview 裁决（两项）

**Q1 品类与顺序** → **选 A**（角色皮肤首个 · 卡背第二 · 界面主题不做），如上。

**Q2 是否松动「`PlayerEntitlement` 用具名字段而非集合」这条既定判据？** → **选 A：松动。** 该判据收口为「**禁的是以付费点种类为 key 的开放容器；内容条目实例的持有集仍是 id 集合，与四类持有条目、七个 Codex 同形**」，`Cosmetic : IReadOnlyList<CosmeticEntry>` 因此成立。依据：原判据的理由是「付费点在本作被刻意限窄」，它拦的是把付费点种类做成运行时可拼错的字符串枚举；而外观条目实例的持有集元素是 `ContentRegistry` 可解析的内容 `Id`，本库已有两处同形先例。**该判据的原文已就地改写**（`systems/player-profile/_index.md`）。

## 仍开放（未随本条移出）

- **牌背在竖屏战斗屏上是否有稳定可见面**——卡背排入首批前的事实确认，`ux/` 当前未描述牌堆呈现形态；归入既已排期的竖屏分区 UX 专场。已在 `systems/monetization.md` 待决问题与 `open-questions/07-codex-monetization.md` 各留一条。

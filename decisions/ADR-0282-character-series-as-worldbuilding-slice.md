# ADR-0282 — 角色系列 = 世界观的切片，对成员零规则强制；名与概述落新内容类型 `CharacterSeriesData`

- **状态：** Accepted
- **日期：** 2026-09-12
- **来源：** handoffs/2026-09-12-series-packaging-and-narrative.md · answer-logs/log-monetization-packaging-and-narrative.md

## 背景

`decisions/ADR-0255-paid-character-series-track.md` 把系列定为推出与商业化的单元，但没答「系列凭什么成为一个系列」。这一问同时卡住两件事：商店详情页讲什么，以及系列这个实体要不要在内容层有个对象。`systems/character-profile/_index.md` 此前以「主题包装未定」为由悬置了后者。

## 决策

**角色系列是世界观的切片，不是难度的梯队。**

- 一个系列有一个与世界观兼容的**有意境的名称**（地域、宗门一类）与**一段简要概述**；细节不写在这里，散进轮回内的叙事。
- **系列对成员角色没有任何规则上的强制要求** —— 不存在系列加成、系列共鸣，也不存在系列层面的规则字段。
- 五行对称仍是**内容编排纪律**，约束的是每批怎么排，不是系列这个实体持有什么。
- 商店详情页讲的是一段世界观概述，**不是一组机制卖点**。

**建内容类型 `CharacterSeriesData`**：`Id`（`character_series.<snake_case_slug>`）+ `LocalizedText` 名称 + `LocalizedText` 简要概述 + 可空 `Artwork`（商店插图），**不带任何规则字段**；走 `ContentRegistry`、带 `ContentEnabled`，与其余内容类型同构。

配套加载期校验一条：`CharacterData.SeriesId` 指向不存在的 `CharacterSeriesData.Id` → `PushError`。

## 理由

`systems/character-profile/_index.md`：**不带规则字段是承重的** —— 系列是**叙事单位与记账单位，不是机制单位**。分组既然没有原则（不按复杂度、不按母题、不按组织），类型上就不该存在任何供机制读取的格。

`SeriesId` 的两段式前缀 `character_series.<slug>` 本就是为引用它而留的（`decisions/ADR-0269-character-series-id-and-track-fields.md`），此刻只是把「日后真建」兑现。

不把系列名只当 `STORE_` 翻译键：系列名只活在商店里，别处想提就没有可引用的条目。

## 备选方案

- **按复杂度梯队命名系列** — 否决：把难度写进商品名，容易被读成「贵的那批更强」，正是严格横向要避的观感。
- **按叙事母题分组** — 否决：母题维度没有天然供给上限，出到第六批会开始重复。
- **同门五弟子（组织归属）** — 否决：组织归属感与「独自求生」的压力线有张力，且一旦给了宗门，玩家会期待它在事件与剧本里持续出现。
- **给系列加成 / 系列共鸣** — 否决：系列是记账单位，机制字段会让「买整系列」产生强度理由，冲击严格横向。
- **系列名只当 `STORE_` 翻译键，不建类型** — 否决：别处无可引用的条目。

## 后果

- `content/_index.md` 类型登记表加一行 `character-series/`（🟢 字段面已定、未开张），依赖链加一支；**开张仍需一轮 `/scaffold-content-type character-series`**。
- `systems/character-profile/_index.md` 原「现在不建该内容类型」的悬置理由**已解除**，那处改写为字段面与校验。
- 系列名与角色名**不进翻译键**：它们是内容层 `LocalizedText`，呈现层作格式参数插入。
- **仍未定：** 各系列的具体名字与主题（含第一个付费系列取哪个世界观实体）—— 属内容阶段，需先有 `narrative/` 的世界观底稿。

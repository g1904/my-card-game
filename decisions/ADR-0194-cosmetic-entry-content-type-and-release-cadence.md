# ADR-0194 — 一套外观 = 一条内容条目，落地时才开张；每上一套外观 = 一次客户端发版

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07b-cosmetic-monetization-shape.md · answer-logs/log-cosmetic-monetization-shape.md

## 背景

外观条目是不是一个内容类型、以及它能不能作为持续运营面，两问都未定；后者直接决定「赛季 / 通行证」这类形态在本作是否成立。

## 决策

**一套外观 = 一条内容条目**（`Id` + `LocalizedText` 名称 / 描述 + `Artwork`），走 `ContentRegistry`，id 形态 `<品类>.<snake_case_slug>`。

**首批不建文件夹、不进类型登记表**——落地时走一次 `/scaffold-content-type`，并在 `art/visuals/_index.md` 的资产类目表加一行。

**上新节奏受硬约束：每上一套外观 = 一次客户端发版。**外观是低频成套发布的付费面，SKU 与条目须同批发版；**赛季式高频上新在本作结构上就不成立**，不只是产能问题。

## 理由

`systems/monetization.md`：`Artwork` 一格直接够用，角色皮肤另可复用 `RealmArtworks` 的稀疏覆写 ⇒ 一套皮肤 = 1 张基础 + 至多 3 张境界覆写，不需要任何新资产字段。

发版节奏的承重前提是 `decisions/ADR-0125-no-binary-over-overlay.md`：二进制资产不经 overlay 下发，故资产必须随版本发布。

## 备选方案

未权衡其他方案（该项在 handoff 中记为标准默认、直接采纳）。

## 后果

- 与「通行证 / 赛季当前不做」互相加固：两条现在有同一个结构性依据。
- 放弃了周更式外观运营。
- 约束 `content/_index.md` 与 `art/visuals/_index.md` 在落地时各加一行，此前不加。

# ADR-0064 — 付费角色系列取系列级 SKU，`seriesId` 由 `productId` 机械变换，后端零内容知识

- **状态：** Accepted
- **日期：** 2026-09-11
- **来源：** handoffs/2026-09-12-premium-character-series-unlock.md

## 背景

客户端把「付费解锁角色系列」定为商业化第三支（`game-design-documents/decisions/ADR-0255-*`），后端因此要接住第二类 SKU。第二类 SKU 一进来就带出两个必须当场选定的问题：**可购商品的粒度**（整系列还是单个角色），以及**后端如何从收据里的 `productId` 知道这次该解锁哪个系列**。后者尤其危险——最直觉的做法是给 SKU 表加一列手工维护的 `seriesId`，或让后端持一张「系列 → 角色 id 列表」表，而那等于把内容编排知识抄进后端库，制造第二权威，且两库都没有机制能发现它漂移。

## 决策

**可购商品只有整系列礼包一种，不存在角色级 SKU** —— 一个角色系列 = 一个 SKU。定价上的「几个单解之价」是记账用的定价锚，不对应任何可购商品。

**`seriesId` 由 `productId` 机械变换得出，不建第二张手写表**：`productId = "series_" + <seriesId 的 slug 段>`。后端校验的是**形态而非存在性** —— 只要求 `productId` 能反解出符合 `character_series.<snake_case_slug>` 形态的 `seriesId`；反解失败 → `purchase.receipt_invalid` + 风控事件，与「`productId` 不在 SKU 表」逐字同一处置。存在性的真实防线在发版前的商店配置核对。

**后端不持有「这个系列包含哪几个角色」的任何知识。** 推论：**零新增下发面、零新增端点** —— 商店该列哪些系列由客户端内容层自行归组，不需要 catalog 端点，也不经 manifest / flags 通道下发。

→ `contracts/purchase.md` §3a「SKU 类别与 `productId ↔ seriesId` 的机械变换」· `operations/purchase-ops.md` §1a

## 理由

- **「能机械变换的绝不建第二张手写表」是本域已行使过一次的判据** —— `receiptId` = 渠道前缀 + 平台 id 同理（`purchase.md` §3a）。给 SKU 表加一列手工维护的 `seriesId` 会让同一事实有两个落点。
- **内容编排知识归客户端内容层。** 后端一旦持有系列成员表，它就成了内容编排的第二权威，而跨库漂移在本项目没有任何机制能发现（同 `game-design-documents/decisions/ADR-0005` 的副本判据）。
- **形态校验 + 发版前核对**这一分工，使后端在零内容知识的前提下仍能拒掉伪造的 `productId`，且不为此引入任何内容同步通道。
- 角色级 SKU 已由对侧 Accepted 的决策否决（破坏系列的五行对称、把「买哪个最强」变成事实上的强度选择），后端无权单方面改它。

## 备选方案

- **角色级 SKU（单个角色零售）** — 对侧已 Accepted 的否决，后端无权单方面改。
- **后端持一张「系列 → 角色 id 列表」表** — 内容编排知识的第二权威，两库都没有机制能发现它漂移。
- **SKU 表加一列手工维护的 `seriesId`** — 能机械变换的绝不建第二张手写表。
- **新开 catalog 端点下发可售系列清单** — 客户端内容层本就持有归组，新增下发面换零收益。

## 后果

- `contracts/purchase.md` §3a 必须写「后端校验形态而非存在性」，且反解失败与「不在 SKU 表」共用 `purchase.receipt_invalid` —— **失败 `code` 零新增**。
- `operations/purchase-ops.md` §1a 的 SKU 表列形态与「发版前核对清单」承担存在性防线，运行时不承担。
- `contracts/envelope.md` §3 端点全集表与 §6 错误码台账**均不加行**，P-1 / P-3 两条护栏不被触碰。
- 放弃了「后端能自查这个系列到底有哪些角色」的能力 —— 客户端读到一个解析不到内容条目的 `seriesId` 时的降级处置归对侧（`game-design-documents/systems/monetization.md`）。
- 首批系列的 `seriesId` / `productId` 具体取值不由本决策给出，取决于对侧的推出时点与主题包装。

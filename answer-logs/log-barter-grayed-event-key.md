# Answer log barter-grayed-event-key

- 日期：2026-09-05
- 来源：`inbox/solution-draft-barter-grayed-event-key.md`（已评审 · 用户裁定一项范围取向）→ `handoffs/2026-09-05-barter-grayed-state-keys.md`
- 移出条数：1

## 移出

**barter 灰显的 `EVENT_` 说明键在权威文档零承接（原 `open-questions.md` 索引「本次新识别的台账 / 投影缺口」）** → 在灰态判据的权威文档里一次补位，不改任何已定判据、不新增机制：

- **判据表补两行。** ① **Exchange 商店买不起 → 灰显但价格与币种保持可见**，说明由 `ApplyResult.MissingElement` 机械映射到币种，**零新增键、不手写第二张文案表**（用户裁定：与 barter 行同批补，原选项 A）。② **Exchange 的 barter 格：不持有 `PayItemId`，或产出目标已持有（能力族）** → 置灰 + 支付要求保持可见 + 点按一行说明，不隐藏、不按持有面过滤呈现；判据同「恒真 vs 可变」。两条触发条件**写成一行**（呈现 / 判据 / 驱动源 / 通道四项全同，只有说明句不同），逐条的键分开给。
- **键清单补两个 `EVENT_` 普通键**：`EVENT_BARTER_UNAVAILABLE_NOT_HELD` / `EVENT_BARTER_UNAVAILABLE_ALREADY_OWNED`，与库内四个既有灰态说明键共同的 `..._UNAVAILABLE_<原因>` 像同形；`<CONTEXT>` 取 `BARTER`（与 `REROLL` 同层级），**不占 `ERR_` 前缀**。
- **新增一条落地纪律：灰态是视觉降级不是禁用，灰格必须继续接收触控。** 做成引擎级 disabled 会让「点按给一条说明」被静默取消，症状是「点了没反应」——线上不可见的失败。该纪律对表内全部灰态项成立。

（归档去向：`ux/error-and-blocking-ux.md`「灰态判据」小节。）

**否决记录：** 键取 `EVENT_BARTER_REQUIRES_ITEM`（打破既有 `UNAVAILABLE_<原因>` 像，且第二条触发条件无法用 `REQUIRES_` 表达）· 键取 `EVENT_EXCHANGE_BARTER_*`（与 `EVENT_REROLL_*` 形成两种嵌套深度）· 复用通用「不可用」键（说明句要点名「你需要哪一样」）· 判据表拆两行 · 只在 `screen-flow.md` 就地补键名（制造第二权威）· 按 `Holds` 结果过滤掉不可换的格（`ADR-0126` 已否决）。

## 仍开放（不阻塞结构落地）

两个键的实际中文措辞待文案定稿；「已换」/「已售」占位标签键随 Exchange 屏的 FR 落地时补齐。

# Answer log combat-substream-arbitration

- 日期：2026-08-26
- 来源：`inbox/solution-draft-combat-substream-arbitration.md`（去向 handoff：`handoffs/2026-08-26b-combat-substream-arbitration.md`）
- 移出条数：1

---

**「`combat` 子流的三句互相矛盾」（`combat-service.md`『敌人抽牌走与玩家抽牌不同的子流』 vs 同文件『战斗内随机不在 `combat` 子流上再派生一层』 vs `life-cycle-service.md` 的子流常量清单只有四条）** → **统一为单一 `combat` 子流，其上不派生任何层**（连带删除 `Hash64(combatStreamSeed, eventId)` 派生层）。`RngStream` 枚举与 `rng.stream[]` schema 四条一字不改，零迁移、不 bump 版本。**台账登记的代价（「放弃『玩家额外抽牌不打乱敌人牌序』」）订正为零**——该性质由「抽牌堆不重洗 + 参战方组装时一次初洗」提供，与子流数量无关。同批新增洗牌顺序规则（按 `sides[]` 序初洗、`sides[0]` = 玩家侧，先后手掷点排其后）与确定性验收断言三条。（归档去向：`systems/services/combat-service.md`、`systems/character-profile/deck/_index.md`、`systems/enemies/common-properties.md`）

> 同批**新增**一条待答项「卡牌效果重洗牌库是否开口、以何形态开」，落 `open-questions/01-combat.md`——它与本条正交，不属本次答定范围。

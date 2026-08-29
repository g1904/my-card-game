# Answer log activate-ability-contract

- 日期：2026-08-26
- 来源：`inbox/archive/solution-draft-activate-ability-contract.md` → `handoffs/2026-08-26d-activate-ability-contract.md`
- 移出条数：1

---

**启动式异能没有 API 方法（08-25f 新增）—— 待定其完整签名与拒绝语义（启动的代价形态、每场次数限制）。** → 全部答定：

- **签名** = `ActionResult ActivateAbility(string entryId, string abilityId, IReadOnlyList<TargetRef> targets)`（形态 A，按战场条目寻址而非按 `Power`；`targets` 与 `PlayCard` 逐字同构、入栈即 `Resolved`）。
- **代价形态** = `AbilityData.ManaCost`（`int`，独立整数格，由 combat-service 直接扣 `sides[controllerSide].currentMana`、不经 `ProfileManager`）。**首版不开 Profile 侧代价列**——日后补开是加字段、零存档迁移。
- **每场次数限制** = `AbilityData.MaxActivationsPerCombat`（`int`，`-1` = 不限、`0` 非法），运行期落既有 `entry.counters[<abilityId>]`，`ActiveCombat` 零新增字段、空迁移；语义为每载体条目每场。
- **拒绝语义** = 三条通用（`NotYourTurn` / `NotActionStep` / `StackNotEmpty`）+ `InsufficientMana` + `IllegalTarget` + 新增 `AbilityNotAvailable` / `AbilityQuotaExceeded`，全部走 `ActionResult`、绝不抛；`abilityId` 解析不到属坏数据档（`PushError` + 抛）。
- **连带定案**：加载期校验由「`Activated` ⇒ 有费用」放宽为「须存在一条有限性闸」；`CombatActionKind` 增 `ActivateAbility`、`CombatFeedKind` 增 `AbilityActivation`；灰态预判由 `BattlefieldEntryView.ActivatableAbilities` 承载、只填 `ViewerSide` 己方条目；决策点清单不加行。

归档去向：`systems/services/combat-service.md` · `systems/character-profile/deck/common-properties.md`（另有回链落 `systems/character-profile/power/_index.md` 与 `ux/combat-ux.md`）。

**仍开放（未随本条移出）**：阵法（`Enchantment`）上启动式异能的 UI 宿主未定，归已排期的竖屏分区专场。

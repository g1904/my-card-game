# Answer log card-counters-api-and-key-space

- 日期：2026-08-22
- 来源：`inbox/solution-draft-card-counters-api-and-key-space.md` → `handoffs/2026-08-22-card-counters-api-and-key-space.md`
- 移出条数：3（另新答定 1 条本批新发现的缺口，此前不在清单上）

## 移出（`open-questions/01-combat.md`）

- **非异能计数器往哪放（08-22 新增 · 轻）** → **`counters` 键空间维持单一形态 `<abilityId>[#<子名>]`，本条关闭。** 依据换为两条不随关键字清单重建而过期的结构理由：叠加层数是可重算的派生量（层数 = 同 `keywordId` + 同 `ownerSide` 的条目计数），依「可重算的东西不进存档」不该有独立落点；合并成「单条 + 层数」则强制多次施加共享同一个过期时刻，是语义损失。连带定下零成本语法护栏：内容条目 `Id` 字符集排除 `#` 与 `:`，`:` 前缀保留为未来非异能键的命名空间。（归档去向：`systems/services/combat-service.md`「`counters` 的键约定」、`systems/common-properties.md`「稳定 Id 键」、`systems/character-profile/deck/common-properties.md`「效果关键字体系」）

- **`CardInstanceSave.Counters` 的读写 API（08-22 新增）** → **对称补两个方法，落参战方接口（CharacterManager / EnemyManager 共享）**：`int GetCardCounter(string, string)` / `void BumpCardCounter(string, string, int)`，形态 A。不与 `GetCounter` / `BumpCounter` 同名重载（签名相同、编译期无法区分）；不落 BattlefieldManager（战场不持有不在场的牌）；寻址复用栈条目自带的 `controllerSide` / `sourceInstanceId`，不新增状态。**计数时机与配额计数完全同规则：弹栈结算成功后 +1，fizzle 不计**，不另开「压栈即 +1」的第二时机。两个计数器空间的归属沿用既有判据（有过期时刻 → 战场条目；无过期时刻且属牌本体 → `CardInstance`）。（归档去向：`systems/services/combat-service.md`「管理器」）

- **子计数器名的字符集与登记（08-22 新增 · 轻）** → **正则 `^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*$`，长度 ≤ 32，允许下划线**；**权威落 `systems/services/combat-service.md` 的键约定小节，不落 `content/_index.md`**（触该库「不承载校验语义」的硬边界，且子名不是内容条目 id）。**登记面补 `AbilityData.CounterNames : string[]`**（可空，静态字段不落存档），加载期三条校验（正则 / 重复 / 未被使用 `PushWarning`），运行期读写两侧都拦未登记的 `#` 段。**「内容条目 `Id` 不含 `#` / `:`」上提到 `systems/common-properties.md`「稳定 Id 键」，`combat-service.md` 改回链。**（归档去向：`systems/services/combat-service.md`、`systems/character-profile/deck/common-properties.md`、`systems/common-properties.md`）

## 本批新答定（此前不在任何待答清单上）

- **`KeywordRef.Amount` 在 `Transient` 战场条目上的承载** → **战场条目增一格 `amount : int`（默认 `-1`）**。正式拍板。不用 `counters` 第二类键承载（计数语义与参数语义不混住一个键空间）。连带松动 `combat-service.md`「本块不新增字段」一句，补量级说明（≤ 4 字节 / `Transient` 条目，当前无线上存档 ⇒ 空迁移）。（归档去向：`systems/services/combat-service.md` 战场条目字段表、`systems/character-profile/deck/common-properties.md`）

- **`EncounterSpec.FirstSide` 的「剧情指定」措辞对账** → **「剧情指定先手」= 内容侧在事件模板（`AdventureEventData`）上直接编排**，由 future-event-service 物化时写入；`PlotModulation` 不承担这一项，也不为此新增字段；`combat-service.md` 中「剧情意图经其下的 plot-manager 调制」一句删除。（归档去向：`systems/services/combat-service.md`）

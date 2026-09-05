# 神通 CharacterPower 的机制细节收口

- id: 2026-09-03-character-power-mechanics
- date: 2026-09-03
- topic: systems/character-profile/power, systems/character-profile/item, systems/character-profile/deck, systems/services/life-cycle-service, systems/balance
- status: distilled
- distilled-to: systems/character-profile/power/_index.md, systems/character-profile/power/common-properties.md, systems/character-profile/item/_index.md, systems/character-profile/deck/_index.md, systems/services/life-cycle-service.md, systems/balance.md, systems/player-profile/player-power/_index.md

## Intent（distilled）

**神通（`CharacterPower`）的机制细节整条收口，且零结构增量。** 本次不新增任何字段、element 列、枚举成员、EventBus 事件或存档格，不 bump `schemaVersion`、无迁移、后端零影响——全部落在「把既有结构的取值口径写死」这一层，外加两条加载期校验与一条强度刻度的形状。

### 一、与 PlayerPower 的分界只在生命周期层，无剩余待决面

内容定义（共用一个 `PowerData`，`Scope` 声明层级）· 战斗内生效路径 · 战斗外注册面（`CapabilityManager` 两层同遍历）· 禁用表（共用 `CharacterProfile.disabledAbility`）四面均已成文；本次补齐剩下的两点：

- **持有列表不共用**：账号级落 `PlayerProfile.playerPower`，轮回级落 `CharacterProfile.characterPower`。
- **不需要任何清理代码**：神通随 `CharacterProfile` 在 `defeated` / `completed` 时整体拆解，角色级 flag / modifier 随 `CapabilityManager` 重新聚合自然消失。

### 二、获取通道：机制面已闭合，本次只给内容口径

`(Power, Character)` 域的四个合法 `Source` 已把四条通道逐一命名，每条都有现成的组装者与施加链路（`InitialGrant` / `CombatReward` / `ExchangePurchase` / `EventOutcome`）。模板侧授予只能走 `OutcomeRule.Kind == GrantFromPool`（`PoolKind` 已收窄），取池走既有 `GrantPoolManager` 的 `reward` 子流。**故本子项不需要任何新机制、新字段、新 element、新存档格。**

首批内容口径：开 `InitialGrant`（每局恰一条）· `CombatReward`（收窄到 `Standard` / `Finale` 两档，`Practice` 不产神通）· `ExchangePurchase`（定价表已有 `CharacterPower` 行，不新增旋钮）；`EventOutcome` 保留机制、首批零条目；Research 维持「暂不放」；Travel / Explore 恒不产出。

### 三、失去通道：三种形态，无第四种

三级严重度阶梯**本场移除 < 本轮回禁用 < 账号移除**逐档落到神通上；`DisableDuration` 的三档时长（下一事件 / 本篇章 / 本轮回）是与严重度正交的另一维。**不开「无同意的永久剥夺」**：在轮回级上它与 `ThisCycle` 档禁用的可玩后果逐格相同，差别只剩持有列表与置换池排重两处次要语义，而开它要打破 `AbilityChangeSlot` 的 `Op ↔ AllowDecline` 既有约定。

失去事件计入与法则**共用的**那一份频次预算，不另立一套。

### 四、篇章继承：带入，不为它单列规则

「读档续章带入全部信息、无逐项筛选」这条条款就是答案——需要论证的是「不带入」而非「带入」，`CurrentLocationId`（跨篇章不清零）与剩余寿元（跨篇章结转）是同一条条款推出的两个先例。**推论必须明写：`disabledAbility` 中 `Duration == ThisChapter` 的条目在篇章边界被剔除 ⇒ ch1 被禁用的神通进 ch2 自动恢复生效**，内容侧不需要任何恢复动作。ChapterManager 的篇章边界职责表不增行，`TeardownCycle()` 不新增步骤。

### 五、跨载体边界判据：三条既有事实合成一张表

按「这个效果要付什么代价才能生效」排序，第一条命中即定型：需要**每次生效都重新付一次代价**（mana + 按次打出）→ 卡牌；需要**明确的使用次数上限、由玩家主动花掉** → 法宝；**存在即生效、无代价、一局内不消耗** → 神通。四条推论把这张表钉死：无节流阀是神通的定义性约束（故累积型效果一律不得写成神通）· 战斗外的改写只能写成神通 · 回寿恒不得写成神通 · 三者共享 `RarityTier` 五档与折价换算体系。

判据表归 `power/_index.md`，`deck/_index.md` 与 `item/_index.md` 各留一行回链、不复述。

### 六、数量与强度：定性可答，定量留内容

- **单条神通的强度应显著高于单条法则。** 法则「轻度提升」的成因是它跨轮回单调累积、不可被针对、须按老账号全开校准；神通三条一条都不成立。
- **法则的「ch1 前段只能是纯信息 / 便利类」那条不适用于神通**（它不是账号级内容，起手绑定神通本就是 ch1 第一分钟就在手里的东西）；但**「不得随对局延长而累积」必须照搬且更硬**——神通没有配额闸。
- **不设持有数量硬上限**，由内容编排天然封顶，与法宝 / 法则 / `pastItemUse` 同款纪律。
- 战斗内强度上沿取 `baseMomentum` 比例刻度（形状定、取值待内容），**不设合计总闸**。

## Clarifications（interview 产物）

**本批合并 interview 的裁决：**

- **绑定神通是否填 `ExclusiveSource`？** → **不填**（当前默认）。首批 5 条即可让 `CombatReward` / `ExchangePurchase` / 置换换入三条通道非空，「条目数下限 ≥ 5」因此成立。**已知代价如实写入内容编排口径、不掩饰**：一个角色的标志性神通会作为战利品 / 商品出现在另一个角色的轮回里，辨识度在内容侧被稀释。原始草稿完全未涉及这一格。
- **神通的战斗内强度上沿取哪把刻度？** → 取 **`baseMomentum` 比例刻度**：单条神通的道念净贡献 / 本方 `baseMomentum` ≤ X%，X 显著高于法则的 10%，取值属【待内容】、本次不编数字；**不设合计总闸**（总闸是为「跨轮回单调累积 + 不可被针对」设的，神通随轮回清理 · 可被禁用 / 置换 · 每局从零起，三条都不成立）。这**推翻了草稿原文**「本方案不给任何数字，`balance.md` 只留一行占位」的处置——纯占位与「先定形状、后定数值」的承重纪律相抵，且 `balance.md` 现有的「留待校准」项无一是纯占位。
- **加载期校验 P-b 的形态？** → **改写为 `PowerId` 唯一性硬规则**：在册 `CharacterData` 的 `PowerId` 出现重复 → `PushError` + 抛，报出两个 `characterId`。草稿原文的「全库 `ContentEnabled` 条目数 < 在册角色数 → `PushError` + 抛」**不得沿用**：它与既有校验「绑定条目 `ContentEnabled == false` → `PushWarning` + 该角色退池」正面相抵（overlay 秒关一条绑定神通即打崩启动），且在「每个角色的 `PowerId` 都解析得到」的前提下恒真、永不触发。「条目数下限 ≥ 5」成为新校验的直接推论，不再另立断言。
- **表 C 的内容口径写在哪？** → **本次不碰 `content/`**：`character-power` 类型尚未开张（全库零已开张类型），开张归 `/scaffold-content-type` 独占。六条内容口径**全部落 `power/_index.md`** 的「内容编排口径」子块。草稿 `targets:` 与「后果」段列的 `content/character-power/_index.md` 因此**不是本次的写入目标**。
- **加载期校验 P-a 的挂载面？** → **改挂 `Abilities` 侧**：`Scope == Character` 且 `Abilities` 中存在 `Kind == Triggered` 且触发时点属「每回合」族 → `PushWarning` + 条目 `Id` + 时点名。草稿原文挂 `ModifierEntry.Op == Scale` **不得照抄**：`ModifierKey` 当前恰两个成员且均为战斗外全局数值，`Modifiers` 在结构上就不是战斗内通道 ⇒ 该校验恒不触发，正是「不设检查不存在对象的校验」明文警告的那一类。

**草稿评审阶段已裁决、原样生效的三条：**

- 神通**不设持有数量硬上限**（不采槽位制）——零结构增量，与全库同类集合同款纪律；只读层条目数无上限这一点随竖屏分区专场一并承接。
- **绑定神通可被置换换走**（即当前默认行为，零新增规则）。
- **「失去能力」的频次预算配平本批不裁决**，原样登记为 ch1 内容编排时的待处理项。

**本次核实后推翻草稿自述的六条（按实况写，不按草稿原文写）：**

- 草稿「后果」段的待决问题**编号**用的是它自己「问题」小节的顺序，与 `power/_index.md` 的实际条目顺序对不上；照编号执行会误改「`status` 开关的存档表达」那条——而草稿明说该条不在本方案范围内。**落笔按对象名执行，该条的待决内容一字不动。**
- 「`CapabilitiesChanged` 的触发源分散记在三处、无集中清单」**不属实**：`profile-service.md` 已有一份五项的集中清单。草稿的「顺带记一笔」整段**落笔时删除**，不作为台账缺口上报。
- 「绑定不等于不可动摇」这条论据**只对绑定功法成立**，`ADR-0055` 对神通从未表态；「跨轮回熟悉感有了载体」也不出自该 ADR。**结论（可换走）不变，理由改用**：① 置换是玩家点头 + 拿回同 `Rarity` 等价物的正向决策点；② 不换走要主动加规则。
- 「`Power` 一律受保护」的权威是 **`ADR-0019`**，不是 `ADR-0106`；后者只管 `IgnoresProtection` 的两条硬准入与 ≈5% 频次。**两条 ADR 各回各的。**
- 「起手神通授予机制现成」**部分不属实**：`life-cycle-service` 的 `StartCycle` 附带写入当前只有三项，全文「神通」零次出现。**须在该服务补一句**（授予通道 = `AbilityElements` 的 `Grant`，`SourceCode = Source.InitialGrant`）——这不是臆造，是把已定案的通道写到它的服务落点上。
- 判据表第一问的第三项「可在一局里被重复触发多次」对神通与阵法**都成立、不是区分项**，照抄会把神通误判成卡牌。**改写为「每次生效都要重新付一次代价」**——判据表按代价面排序，代价才是承重条件。

**本次采纳的标准默认（不占 interview）：**

- `CombatReward` 收窄到 `Standard` / `Finale` 两档 · `EventOutcome` 保留机制零条目 · Research 维持「暂不放」· Travel / Explore 恒不产出 · 失去形态恰三种 · 失去事件计入与法则共用的同一份频次预算——六条均属通行做法、零结构、日后纯加法即可改口。
- 三级严重度阶梯沿用既有措辞「本场移除 < 本轮回禁用 < 账号移除」，`DisableDuration` 三档时长**另起一句**，不与严重度混写。
- `Op ↔ AllowDecline` 的对应关系措辞**降级为「既有约定」**：它目前只是字段注释，未落成物化断言清单里的任何一条，称之为「机械保证」属过度陈述。
- `power/_index.md` 中「`CharacterProfile.characterPower`（字段 13）……见 23 字段表」订正为**字段 14 / 25 字段表**（`magicPack` 占第 13 格）。

## Open questions

- **`status`（启用 / 禁用）与「拥有 / 失去」两个正交维度如何编码进 schema。** 与本次收口并列的另一条，权威归 `systems/services/profile-service.md` 的同名待决项，本次明确不覆盖——本次的每一项都只读 `status` 的语义、不依赖它的编码形态。
- **神通的定量三格**：一次轮回预期获得几条 · 单条相对同 `ManaCost` 法术的效果量系数 · 各 `RarityTier` 档应有多少条目。三者互相咬合，需 starter deck 与功法条目规模先落地才有分母，归 ch1 平衡打磨。
- **「失去能力」四类合计的频次预算重新配平**（神通侧的置换 / 禁用挤进的是同一份预算），归 ch1 内容编排一并定。
- **战斗屏只读层的形状**：神通数量无上限 ⇒ 只读层的条目数无上限，已排期的竖屏分区专场须给出能容纳 N 条的形状。
- **四类事件的各自专场**（Exchange / Research / Explore / Travel）：本次给的是内容口径而非机制；若某场专场改变了该类事件的产出面结构，第二节的通道口径需随之复核。

## Notes / triage

- 内容层的 `character-power` 类型**尚未开张**：开张动作归 `/scaffold-content-type character-power`，届时其字段核对清单从 `power/_index.md` 的「内容编排口径」子块回链取用（`content/` 只写填了什么值 + 回链，不复述规则）。
- 本次顺带核出、**不在本次范围**的五处：`ADR-0017` 与 `ADR-0116` 主题重叠且 0017 决策段仍只写一层 · `Op ↔ AllowDecline` 在 `future-event-service.md` 的物化断言清单里缺一行 · 该文件「能力族商品经第二级取池」仍带 `[采纳推荐 — 待复核]` 且未登记 · `ADR-0004` 与 `currency.md` 的「每章重置」例外未对称登记 · `ADR-0019` 后果段仍引用一份已随 `ADR-0106` 删除的核对表。

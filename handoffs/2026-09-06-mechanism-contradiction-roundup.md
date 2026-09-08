# 五条机制 / 数值口径矛盾的逐条收口

- id: 2026-09-06-mechanism-contradiction-roundup
- date: 2026-09-06
- topic: systems/adventure-event/exchange · systems/services/combat-service · systems/balance · systems/character-profile/life-span · systems/services/life-cycle-service · systems/_index · systems/character-profile/deck · vision/references
- status: distilled
- distilled-to: systems/adventure-event/exchange/common-properties.md, systems/services/combat-service.md, systems/balance.md, systems/character-profile/life-span.md, systems/services/life-cycle-service.md, systems/_index.md, systems/character-profile/deck/_index.md, vision/references.md

## Intent（distilled）

一句话：对五条登记在案的「文档间机制 / 数值口径矛盾」逐条直读源文件裁定，**四条成立（① ② ④ ⑤）按权威侧收口，一条不成立（③）仅做措辞对齐**；另顺带对齐一处同型残留（balance.md 的 Exchange 待决措辞）。零字段 / 零签名 / 零 schema / 零存档迁移 / 零代码。

来源草稿：`inbox/archive/solution-draft-mechanism-contradiction-roundup.md`（status: decided，用户已评审）。

### ① Exchange 待决措辞同批两份打架 —— `_index.md` / `balance.md` 一侧成立

`exchange/common-properties.md` 的待决条仍写「四组数值全欠」（定价表每格、刷新价参数、两档回收率、槽位上界），而同批的 `exchange/_index.md` 与 `balance.md` 已按 09-05 货币落笔批收窄为「两组」（刷新价参数 · 槽位上界），定价表 25 格与两档回收率**已有初值**。裁定依据：数值权威在 `systems/balance.md`（两份 exchange 文档的待决项都指向它），转发链终点已给出取值 ⇒ 转发措辞必须跟上；`common-properties.md` 的 `Source:` 行漏登 09-05 handoff，证实是同批落笔的机械遗漏而非另一派主张。

**落笔：** `common-properties.md` 待决条整条替换为「两组待定 + 定价表与回收率已有初值」（保留本文件的落点视角、不复述取值）；`Source:` 行补登 `handoffs/2026-09-05-currency-acquisition-and-pricing.md`。**顺带（同型残留，批内授权）：** `balance.md` 自己的转发条「Exchange 的三组待定数值格……回收率两档（见下条）……只欠取值」同步对齐为「两组待定 + 回收率两档已有初值（见下条）」。

### ② 战后奖励候选池 vs 神通获取通道 —— `power/_index.md` 一侧成立，combat-service 追平

`combat-service.md` 的可选奖励候选池写「三类混合（Card / Item / CultivationTechnique）」，而 `power/_index.md` 的内容编排口径已开 `CombatReward` 通道（收窄到 `combatTier ∈ { Standard, Finale }`，`Practice` 档不产神通——最轻一档也掉神通会把这条获取面稀释成常规掉落），且明确把落点指派到战斗奖励「可选逐项领取」一类（`Source.CombatReward` 的神通只能出自 combat-service 的战利品组装；走 outcome 的授予按「谁组装出这条 element」判据记 `EventOutcome`，不是本条的落点）。裁定依据：ADR-0152 / ADR-0153（Accepted）与 09-03 神通机制 handoff。

**落笔（四处）：** 候选池改**四类混合（+ `PowerData`）**并加档位闸（`Practice` 整族排除）；新增「神通候选的两条口径」子条（档位闸 · 已持有直接排除——神通无层数维度、置换是独立通道 · 选中 = 一条 `AbilityChangeElement(Grant, Power, Character, id, Source.CombatReward)`，与功法侧逐格同构）；「三档共用同一条生成路径」句补上 `Practice` 对 `PowerData` 的整族排除这一差异；`balance.md` 待决区的战后奖励池族维度同批改四类（神通列只在 Standard / Finale 两张表上非空）。

**这是五条中唯一有实质 derive 结构后果的一条**：战后奖励的候选生成器是四族 + 一个档位闸，不是三族。内容侧指示：`content/character-power/` 开张时其条目须编入 Standard / Finale 档的 `RewardPoolId` 池；`Practice` 档由生成侧的族级排除机械兜底，不依赖编排纪律。

### ③ `lossPerMomentum` ch2 / ch3「三种口径」—— **矛盾不成立**

`life-span.md` 待决条、`balance.md` 系数表与 `balance.md` 待决条三处的实质结论逐格一致：ch1 = 10 已锁定 · ch2 / ch3 候选值 5 / 10 · 两格尚未定案 · 形状锚已逐格校验通过。定案被「典型道念差的实际分布」阻塞（其又被卡牌道念产 / 削量纲基准阻塞），09-03 寿元成本 handoff 自己的 Open questions 即如此登记。**不收口、不填死候选值。**

**落笔（仅措辞对齐）：** `life-span.md` 待决条的「定案待反推」改为「定案待『典型道念差的实际分布』实测」——原措辞会让读者以为坐下来解析反推即可定案，实际是待实测分布的统计校准。不改任何取值、不改排除面。

### ④ `experiencePoint` 待决条四项均已定 —— 整条删除

`life-cycle-service.md` 待决区仍列「各级阈值曲线、单次给予量、事件池分布、失败折算」四项待定，而其转发链的两个终点均已给出答案：阈值曲线三章齐全、`ExperienceGrade` 四档给予量、事件池覆盖率初值、失败 = 同档 50%（下限 1），权威在 `systems/balance.md` 与 `systems/game-progression.md`。life-cycle-service 是消费方（走 `ProfileChangeSpec` → `TryApply`），不持有取值。

**落笔：** 整条删除。「反推链是脆的」风险提示不在本文件留副本——`balance.md` 的经验曲线条目已独占且更完整地承载它（含「供给 / 需求比校验表」缓解），在消费方文档留一份即制造第二权威。

### ⑤ `systems/_index.md` 残留「敌人 AI 与意图（三档揭示）」—— 按 ADR-0059 收口

服务导航表的 combat-service 行仍写「意图（三档揭示）」与「抽/弃/洗」，而意图机制已由 ADR-0059（Accepted）整条移除（不设揭示档位、不设行动类别标注、不生成回合级行动描述、不设探查通道），洗牌口径也已定为「不重洗，抽空即疲劳」；`combat-service.md` 与 `ux/combat-ux.md` 正文均早已改完，索引这一跳还指着一个不存在的机制。

**落笔（五处）：** `systems/_index.md:45` 描述格沿 `terminology.md` 的战斗服务行口径整格替换（删三档揭示 · 抽/弃改不重洗 · 补 BattlefieldManager / StackManager 两个漏登的 manager）；`deck/_index.md` 三处以「意图机制存在」为前提的论据修正——「level 是意图揭示档的判据」删去该理由（改由术语表登记独立承担）、推论 ② 收窄为「`CardType` 不兼作任何展示 / 行为分类」（原正交对象已不存在，收窄版防止日后有人重提共用枚举）、敌人牌设计目标删去「被意图汇总成一条结果值」分句（图鉴关键卡牌一条独立支撑结论）；`vision/references.md` 的 Slay the Spire 借鉴清单改为「回合制战斗（其意图预告一族本作不采用 → ADR-0059）」（用户已确认——references 位于 vision/，被误读为设计意图的代价比正文更远）。`deck/_index.md:242` 的否定式表述与 ADR-0059 一致，不动。

## Clarifications

- 批量运行合并 interview：本分片零 🔴 / 🟠，全部按 decided 草稿与既有推演落笔（orchestrator 授权：`balance.md` 的 Exchange「三组待定」同型残留作为第 14 处改动顺带对齐）。
- 🔵（标准默认 / 既有推演，自动采纳）：改动 8 取「整条删除」形态（草稿倾向项，risk 提示由 balance.md 独占）；改动 7（life-span 措辞对齐，草稿标可选）采纳执行（成本一行、有 09-03 handoff 逐字背书）；条目 ② 落笔文本不引用 `power/_index.md` 的「本表是三者边界的唯一权威」句（该句实挂在跨载体边界判据表上，非内容编排口径表——裁定不受影响，另有五处独立佐证）。

## Open questions

无新增。ch2 / ch3 `lossPerMomentum` 定案、战后奖励池各档权重（含新增的神通列）等既有待决项均已在 `systems/balance.md` 待决区登记，本次不重复登记。

## Notes / triage

五条矛盾原登记于 `open-questions.md`「derive 就绪度」小节（09-06 全量评估产出）；该小节归 `/assess-derive-readiness` 独占，本次不改，五条登记随下一次全量评估自然消失。

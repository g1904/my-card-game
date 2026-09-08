# ① 战斗机制（焦点之首 · 08-06d 后的残留）

> 本分片属 `../open-questions.md` 的当前焦点区。焦点判据见索引文件。

> 本片区历次答结问题的逐条移出记录见 `../answer-logs/`（归档权威在那里，本处不复述）。

> **⚠ 治理提示（08-15d 更新）：** **敌人意图机制已整条移除**（三档揭示 · `IntentCategory` · 快照语义 · 探查通道全部作废），敌人回合的可读性改由逐步执行呈现 + 敌人图鉴 + 战场承担。凡在别处读到「意图三档 / 越阶黑箱 / 仅类别 / 探查」的表述，一律以 `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` 为准；`±2` 赋级带**保留**（其消费点是 `baseMomentum` 起跑线）。

## 能力剥夺与统计计数的残留（08-10c 后）

> 「本轮回禁用」与置换型剥夺片区的**四条并列待答已全部答结**（承载字段 `disabledAbility` · 三档时长与生效判据 · 置换候选池与对价 · `ProfileChangeSpec` 三列表 element 形态 · `PlayerStatistics` 与首批两项 · 宽松同步口径五条 · `PushWarning` 对称落点归内容加载侧），见 `../answer-logs/log-ability-deprivation-and-player-statistics.md`。

- **`RarityTier` 的分布与权重表（08-10c 新增）。** 五档已定名并挂上 `PowerData` / `ItemData` / `CardData` / `CultivationTechniqueData`（功法整体标稀有度）；**结构面已答定**——授予池权重表已给出结构与初值，置换候选池不需要权重表（同档等概率），分表维度按**用途**（授予 / 战后奖励）而非渠道、亦非 `(Kind, Scope)`。仍待定：**战后奖励池**各档权重（按优势档 `Tier` 三档各一张表；该池现为 `CardData` / `ItemData` / `CultivationTechniqueData` / `PowerData` 四类混合（09-06 追平神通通道；`Practice` 档整族排除 `PowerData`），权重表的族维度须相应覆盖功法与神通；**该表同时覆盖事件产出侧 `OutcomeRule.DeckOperation` 的 `AddLooseCard` 池抽，事件侧固定取一档、不按优势档选表**）、内容侧「每档应有多少条目」的编排口径、**三格取池余量**（`GrantPoolMargin` / `ResearchPoolMargin` / `ExchangePoolMargin`）与 `K` 的取值（结构已定，可先填 0 而不阻塞落地）。**功法这一维的分母按灵根收缩后的最小可修子集重估；`ADR-0073` 三段处置的边界同按新口径复核。**→ `systems/balance.md`、`systems/services/combat-service.md`。
  - **同批处理（08-30 由「呈现的残留」并入 · 08-23g 新增）：逐项领取后的奖励厚度重估。** 择一改为三项各自可领，使单场可选奖励的期望价值上移；`Tier` 三档的质量落差与 `BaseReward` 的相对分量需随之重估。`systems/balance.md` 已明写它与战后奖励池各档权重「同批处理」，故不再并列为独立条目。→ `systems/balance.md`、`systems/services/combat-service.md`。

## 结构与配置的残留

- **`EncounterTighten` 三格牌流量的六个界常量取值（08-22 新增）。** `MaxInitialDrawTighten` / `MaxDrawPerTurnTighten` / `MaxHandLimitTighten` 与 `MinInitialDraw` / `MinDrawPerTurn` / `MinHandLimit`。**结构已定**——每格必有一个内容侧上界与一条物化期下界钳制，且两条硬性约束先于取值成立（`MinDrawPerTurn >= 1`、`MinHandLimit >= MinInitialDraw`），否则剧本能把每回合抽牌压到 0；只欠数字。**基准值 4 / 2 / 7 已校准并维持，该阻塞已解除**，取值可随首批遭遇编排定出。**只约束标定，不约束结构。** → `systems/balance.md`、`systems/services/plot-manager.md`。
- **`EnemyManaLimit` 初值 5 的校准（08-22 新增）。** 玩家侧 `manaLimit` 随大境界 +1，第三章差距达 4~7 点（玩家约 9~12 / 敌人 5），敌人的行动空间是否仍够用需实测——**代价现已可算：ch3 敌方摆幅约为玩家的 44%**（`systems/balance.md` 规模口径末条）；**参战方对称在 mana 这一项已被明写打破**，该「已知例外」的措辞同待复核。校准顺位已定：先逐条 `EncounterSpec.EnemyManaLimit` 覆写，改全局常量是第二顺位。→ `systems/balance.md`、`systems/services/combat-service.md`、`systems/character-profile/mana.md`。

## 内容与数值的残留（多数留待内容扩充后的统计校准）

- **起始卡组的具体内容。** `CardData` 的字段清单已收口（类型五分、异能三分、次类型、`Pool`、`Subtypes`、目标声明与效果引用、`ManaCost`、`OnPlay`）；**starter deck 装哪些牌**未设计——**它正是内容扩充后统计校准的切入点**。规模与量纲的分母已就位（起始 15 张 = 3 门 × 5 · 兑换率 1 · 平均费用 2 · 一份 ch1 费用分布样例见 `handoffs/2026-09-07-combat-scale-baseline.md`）。→ `systems/character-profile/deck/`。
- **关键字与次类型的首批清单（08-16c 新增）。** 两套机制均已完整定案、两套清单均为空；填什么条目要从「哪些组合真的重复了 ≥3 次」倒推，切入点同为 starter deck 的设计过程。→ `systems/character-profile/deck/common-properties.md`、`systems/balance.md`。
- **神通（角色级 `Power`）的强度尺度剩余定量格与获取侧内容口径（09-07 归集 · 09-07 收窄）。** 定性面已答（单条显著强于法则 · 不得累积 · 不设持有数量硬上限）、**战斗内强度闸门已给出初值 25%**、机制面已闭合（四个合法 `Source` · `AbilityChangeSlot` 三种失去形态 · 失去侧频次份额已归 `player-power/_index.md` 的四支目标频次表）。仍欠三个数字：**一次轮回预期获得几条** · **单条相对同 `ManaCost` 法术的效果量系数** · **各 `RarityTier` 应有多少条目**；另欠「各开放通道每轮回出产几条」的 ch1 编排口径。前置是 starter deck 与功法规模落地，故与本片其余数值项同属一次校准。→ `systems/character-profile/power/_index.md`、`systems/balance.md`。
- **回寿法宝的总量护栏在内容编排面的口径未定（08-26 改写 · 承重）。** 储物袋不设容量上限后，回寿法宝能囤多少完全交给内容编排面承接——**出现频率 / 商店库存深度 / 定价**三者的口径都还空着。合并后寿元是角色**唯一的那条命**，这条护栏因而是它的**唯一剩余数量闸**：另两道加载期校验（`Scope == Player` 且产出 `LifeSpan` → 拒；`LifeSpan` 产出 + `UsableScene` 含 `InCombat` → 拒，后者的理由已改挂「战斗内不得读写这条命」）管的是条目合法性，不约束持有量。连带需一并评估的还有道具整体的获取频率、商店库存深度与置换对价。→ `systems/character-profile/item/_index.md`、`systems/adventure-event/exchange/`、`systems/balance.md`。
- **量纲基准落笔牵出的三条复核项（09-07 新增 · 均为标定复核，不阻塞结构）。** ① `itemPowerRatio` 的「不占手牌位 ×1.10」偏低，建议校准时上调至 **1.15–1.20**（分母已就位、该项首次可校验，改它会让四档折价整体下移约 0.03–0.06）；② 以 `baseMomentum` 计的战斗内法则 10% / 25% 两道闸门**在产出面上逐章加重约 3 倍**（`P/base` 由 2.4 降到 0.7），**刻度当前不动**（两个数不可机械校验、按纪律阶梯第 4 级处置），要改的正确形态是加第二把以摆幅计的闸（双闸取小），须独立决策；③ `advantage` 三档分布随篇章右偏 ch1（碾压档在 ch1 常见、ch3 罕见），战后奖励品质因此在 ch1 偏厚——按篇章分格三档边界属新开一条分格轴，须先立 ADR。→ `systems/balance.md`。
- **`E[道念差]` ch3 的 35% 偏高（09-07 新增）。** 代入本次摆幅口径后，三章的 `E[道念差]` 占一方摆幅 17% / 30% / 35%，ch3 一格偏高。它与 `lossPerMomentum` ch2 / ch3 系数、λ 反推式共用同一格输入，**实测改写它须按同一条式子重算兑换率**（改的是一个数，不是形状）。→ `systems/balance.md`。

## 呈现的残留

- **合并后敌人赋级带 `±2` 与层数散布 `±1 档` 是否可放宽（08-30 新增）。** 两条护栏的取值当前一律不变，其依据已由「`lifeTotal` 境界基线推导」改挂难度曲线可控性与 `ADR-0044` 自身的「不给覆盖参数」硬规则。一次带内最坏落差的失败只占本章可用预算的 8%–12% ⇒「一次惨败打穿」这条约束自动且过度成立，带宽是否仍需这么窄要等有内容样本与遭遇编排后再判；在零内容条目的当下放宽是拍脑袋。→ `systems/enemies/_index.md`、`decisions/ADR-0044-enemy-leveling-band.md`、`systems/balance.md`。
- **战斗屏形态的实测校准项（09-08 新增 · 轻）。** 竖屏分区与叠加元素的形态已整体定案（见 `ux/combat-ux.md` 的两个子块）；仍为初值、须在 18:9 / 19.5:9 / 平板三档竖屏上实测的有：分区总表的各档屏高百分比 · 手牌重叠扇的 40% 露出宽度 · 只读层图标条的 `K = 5` · 己方战场带两侧同挂时的净可用宽度（约 84%，退让位已定）· 台词气泡 ≈1.5 s · 详情 sheet 上界屏高 60% · 见底预警阈值 `DrawPerTurn × 2`。`vision/scope.md` 未给目标分辨率或宽高比，故当前只能给比例。→ `ux/combat-ux.md`。
- **五类卡框色的色相与两枚战报符号的字形（09-08 新增 · 轻）。** 约束已定且可机械核对（缩略尺寸下两两可辨 · 灰度化后仍两两可辨 · 不与呼吸描边 / 上浮描边 / 灰态降饱和三套状态视觉相撞；符号须非数字 · 单字宽 · 两枚互不相似），取值待美术基调定稿。→ `art/`、`ux/combat-ux.md`。

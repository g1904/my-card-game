# ⑦ 图鉴族与商业化（08-01b 新增焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

- **`CharacterPower`（神通）的机制细节（概念已定，待专场）。** 「轮回级角色能力、对标 PlayerPower（法则）」已定案并建档，**08-03 追加：神通可承载战斗内的触发式效果**；**08-12f 追加：每个角色自带一个绑定神通**（起手那一份的获取渠道已定，见 `../answer-logs/log-0812a.md`）；仍待定：与法则的**复用边界**（是否共用同一份 `PowerData` 定义与 modifier pipeline）、**事件侧的**获取 / 失去触发、篇章突破是否随「全部继承」带入、与卡牌 / 法宝的边界、数量与强度尺度。→ `systems/character-profile/power/`。
- **其余四个图鉴的解锁触发与词条深度。** EnemyCodex = 遭遇即记、五项文案；能力 / 道具类是「获得即记」「见到即记（含商店中见到）」还是「使用过即记」？词条该写什么？→ `systems/player-profile/codex/`。
- **图鉴的入口与浏览形态。** 六本图鉴在主菜单如何组织、是否与成就 / 奖励挂钩、战斗内能否查阅（EnemyCodex 尤其相关）。→ `ux/screen-flow.md`、`ux/combat-ux.md`。
- **纯外观付费点是否真做、做成什么（08-15b 新增 · 轻）。** 付费面的负面边界已定（五项明确排除），**纯外观是唯一被标为「不排除」的预留方向**——但它是否真做、做成角色皮肤 / 卡背 / 界面主题的哪些、落成 `PlayerEntitlement` 的第二个具名字段还是一个外观 id 集合，均未定。通行证 / 赛季已明确「当前不做」。→ `systems/monetization.md`。
- **成就奖励的具体条目目录（08-10b 收窄 · 08-12e 再收窄）。** **「能给什么」已答结**：法则 / 古宝（`Source.AchievementReward`），不计入残卷的 `x`。**「怎么给」也已答结**：**指定条目 + 成就限定**（`ExclusiveSource == AchievementReward`，不进任何抽取池 ⇒ 成就奖励恒不落空），故原问的「抽取是否走 `AllEnabled()` 池并排除已拥有」已消解。仍待定：**两档各给什么、奖励条目清单**、是否还有其他形态的账号级奖励。**⚠ 内容侧编排纪律**：每条成就奖励需要一个专属条目，成就目录与内容目录一一对应地一起增长。→ `systems/player-profile/achievement/`。
- **授予池编排余量 `GrantPoolMargin` 与 `K` 的取值（08-12e 新增 · 08-15b 改写口径）。** 闸 ① 的结构已定，且口径已由「礼包所需（1/2）+ 余量」改写为「**支撑 K 次重复购买 + 留给第 K+1 次的缓冲**」（礼包为可重复购买）；**`K` 与余量的具体数值待内容侧条目规模明朗后给**，随第一批内容一并定。→ `systems/balance.md`、`systems/monetization.md`。
- **`Elements` 是否一律走 modifier pipeline 的通则（08-15b 新增 · 承重）。** 统计层已明确豁免、`BundleGrantOrdinal` 本次也定为豁免，但**通则未收口**：建议一并答定「序号 / 幂等键 / 权益类 element 一律不经 pipeline」（残卷的 `PowerFragmentAccumulated` / `PowerFragmentWinOrdinal` 大概率也应豁免），否则「一条法则能改写它」这个洞会随每条新 element 复现。与「cost element 清单未定」同处答。→ `systems/services/profile-service.md`。

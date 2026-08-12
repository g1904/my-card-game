# ⑦ 图鉴族与商业化（08-01b 新增焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

- **`CharacterPower`（神通）的机制细节（概念已定，待专场）。** 「轮回级角色能力、对标 PlayerPower（法则）」已定案并建档，**08-03 追加：神通可承载战斗内的触发式效果**；仍待定：与法则的**复用边界**（是否共用同一份 `PowerData` 定义与 modifier pipeline）、获取 / 失去触发、篇章突破是否随「全部继承」带入、与卡牌 / 法宝的边界、数量与强度尺度。→ `systems/character-profile/power/`。
- **其余四个图鉴的解锁触发与词条深度。** EnemyCodex = 遭遇即记、五项文案；能力 / 道具类是「获得即记」「见到即记（含商店中见到）」还是「使用过即记」？词条该写什么？→ `systems/player-profile/codex/`。
- **图鉴的入口与浏览形态。** 六本图鉴在主菜单如何组织、是否与成就 / 奖励挂钩、战斗内能否查阅（EnemyCodex 尤其相关）。→ `ux/screen-flow.md`、`ux/combat-ux.md`。
- **premium bundle 的其余细则。** 一次性还是可重复购买（可重复则重试上限如何叠加）？定价与地区？是否还有其他付费点、以及明确排除哪些（抽卡 / 消耗型货币）？→ `systems/monetization.md`。
- **礼包持有状态的存档表达与服务端权威（08-12e 追加连带项）。** 落成 `CapabilityFlag`、modifier pipeline 的具名修正，还是独立的 `Entitlement` 字段？付费凭证不能只信客户端，故它同时是一条**客户端 ↔ 后端协议契约**，应同步登记进 `backend-design-documents/open-questions.md`。**连带：礼包授予序号 `BundleGrantOrdinal` 的落点挂在本条上**——它的**形状已定**（账号级、单调递增、不清零、随授予事务同一次持久化，形态同 `FinaleWinOrdinal`），存档 schema 仅在本条答定后 bump。→ `systems/services/profile-service.md`、`sync-service.md`、`systems/monetization.md`。
- **成就奖励的具体条目目录（08-10b 收窄 · 08-12e 再收窄）。** **「能给什么」已答结**：法则 / 古宝（`Source.AchievementReward`），不计入残卷的 `x`。**「怎么给」也已答结**：**指定条目 + 成就限定**（`ExclusiveSource == AchievementReward`，不进任何抽取池 ⇒ 成就奖励恒不落空），故原问的「抽取是否走 `AllEnabled()` 池并排除已拥有」已消解。仍待定：**两档各给什么、奖励条目清单**、是否还有其他形态的账号级奖励。**⚠ 内容侧编排纪律**：每条成就奖励需要一个专属条目，成就目录与内容目录一一对应地一起增长。→ `systems/player-profile/achievement/`。
- **授予池编排余量 `GrantPoolMargin` 的取值（08-12e 新增）。** 闸 ① 的结构已定（通用池条目数 ≥ 礼包所需 1/2 + 余量，不足 → `PushError`），**余量的具体数值待内容侧条目规模明朗后给**，随第一批内容一并定。→ `systems/balance.md`、`systems/monetization.md`。
- **商业化的 UX 观感。** 礼包入口放在哪、是否在重试次数耗尽时提示购买——这直接决定观感是「增值」还是「付费才玩得下去」。→ `ux/screen-flow.md`。

# ⑦ 图鉴族与商业化（08-01b 新增焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

- **`CharacterPower`（神通）的机制细节（概念已定，待专场）。** 「轮回级角色能力、对标 PlayerPower（法则）」已定案并建档，**08-03 追加：神通可承载战斗内的触发式效果**；仍待定：与法则的**复用边界**（是否共用同一份 `PowerData` 定义与 modifier pipeline）、获取 / 失去触发、篇章突破是否随「全部继承」带入、与卡牌 / 法宝的边界、数量与强度尺度。→ `systems/character-profile/power/`。
- **`CharacterItem` 的标识符单复数不一致（08-03 新增）。** 中文定名「法宝」对应 `CharacterItem`（单数），但全库既有写法是 `List<CharacterItems>`（复数）。是否统一未定。→ `terminology.md`、`systems/character-profile/item/`。
- **其余四个图鉴的解锁触发与词条深度。** EnemyCodex = 遭遇即记、五项文案；能力 / 道具类是「获得即记」「见到即记（含商店中见到）」还是「使用过即记」？词条该写什么？→ `systems/player-profile/codex/`。
- **图鉴的入口与浏览形态。** 六本图鉴在主菜单如何组织、是否与成就 / 奖励挂钩、战斗内能否查阅（EnemyCodex 尤其相关）。→ `ux/screen-flow.md`、`ux/combat-ux.md`。
- **premium bundle 的其余细则。** 一次性还是可重复购买（可重复则重试上限如何叠加）？定价与地区？是否还有其他付费点、以及明确排除哪些（抽卡 / 消耗型货币）？→ `systems/monetization.md`。
- **两条 PlayerPower 获取渠道的候选池与排重规则（08-09b 收窄，只剩「抽哪一条」）。** **交互已答结**：礼包**不重置**残卷的 `Accumulated`，但使 `x` +1 从而可能压低上限档位（有意的负反馈）。**RNG 也已答结**：账号级掷骰走 `Hash64(AccountSeed, <账号级序号>)`，与 `CycleSeed` 不相交、不污染轮回确定性。**仍待定的是抽取本身**——从哪个池抽（`AllEnabled()` 全池 / 排除已拥有 / 按稀有度）、抽到重复怎么办；它是残卷伪码里 `pickedPowerId` 与 `HasGrantable()` 的**前置依赖**（残卷其余部分不依赖它）。→ `systems/player-profile/player-power/`、`systems/monetization.md`。
- **礼包持有状态的存档表达与服务端权威。** 落成 `CapabilityFlag`、modifier pipeline 的具名修正，还是独立的 `Entitlement` 字段？付费凭证不能只信客户端，故它同时是一条**客户端 ↔ 后端协议契约**，应同步登记进 `backend-design-documents/open-questions.md`。→ `systems/services/profile-service.md`、`sync-service.md`。
- **商业化的 UX 观感。** 礼包入口放在哪、是否在重试次数耗尽时提示购买——这直接决定观感是「增值」还是「付费才玩得下去」。→ `ux/screen-flow.md`。

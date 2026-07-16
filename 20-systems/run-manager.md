# run-manager

> Run 生命周期:开始(seed)、推进、胜/负、清理。

## 意图
> _设计意图,从 handoffs 中提炼。保持更新。_

- **两层持有模型(大局骨架,细节未定)。** 账号级的 **PlayerProfile** 跨 run 持久,持有一组 **CharacterProfile**;每个 CharacterProfile 是一次 run / 一个角色的状态与历史,对齐既有 RunState 概念。
  - **PlayerProfile(元进程层):** `List<CharacterProfile>`、`GameSetting`、`List<PlayerPower>`、`List<PlayerItem>`、`List<Achievements>`、`AccountInfo` 等。`PlayerPower` / `PlayerItem` / `Achievements` 是**独立于任何单次 run** 的账号级解锁与成就。
  - **CharacterProfile(单次 run):** `status`(defeated | ongoing | discarded | completed)、`chapter`(当前篇章)、`Status`(currentHealth / healthLimit、currentMana / manaLimit、`faith` 等即时属性)、`List<AdventureEvent>`、`List<CharacterItems>` 等。
- **多角色并存(已确认)。** 玩家可同时持有多个角色(CharacterProfile);但**每个篇章内至多一个 `ongoing`** ——同一时刻一个篇章推进只有一个进行中的角色态。Source: `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。
- **篇章存档 · 读档续章 · 重试模型。** 篇章通关即在所达境界落一个**存档点**(如打通炼气→筑基得到筑基存档);可读档从该境界起始下一篇章(筑基存档 → 开始筑基→金丹)。**炼气起手为随机角色,失败可无限重试**;而**落过境界存档的角色,在后续篇章有有限的重试次数**——存档角色是一种会被耗尽的有限资源。Source: 同上。
- `faith`(信仰)是一个**新的角色即时属性**,落在既有「类 Reigns 属性平衡」的待决属性模型内。
- Source: `10-handoffs/2026-07-15-adventure-event-profiles.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决,需要一次 handoff/决策。_

- **CharacterProfile 状态机:** `ongoing → defeated / completed / discarded` 的转移规则?`discarded`(主动弃置)与 `defeated`(战败)在元进程后果上有何区别?
- **CharacterProfile 状态机(部分解答):** 多角色并行已确认、每篇章至多一个 ongoing 已确认;尚待——`discarded`(主动弃置)vs `defeated`(战败)在元进程后果上有何区别?重试耗尽后角色转入何种终态?
- **重试上限数值:** 存档后角色的重试次数是多少、是否随境界递减——属平衡待调项。→ `30-content/balance.md`(未来)。
- **「每篇章至多一个 ongoing」精确语义:** 解读为同一角色谱系不可并行两个同篇章尝试,但不同角色谱系可各自并行推进——待确认。
- **元进程持久化范围:** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 各自字段与解锁规则待定;账号级 meta 或许值得单独一份系统文档。
  - **账号 / 在线同步维度(方向已定,实现待决):** 已确认采用**离线可玩 + 云同步混合模型**并纳入 MVP——本地 `user://` 权威,登录后同步至服务器,游客纯本地(见 `00-vision/scope.md`)。**仍待决:** 后端 / 账号系统选型、本地↔云端**同步冲突解决**、**游客→登录的进度迁移**(合并 / 覆盖 / 提示)、登录渠道的平台边界与合规。Source: `10-handoffs/2026-07-16-ux-flow-login-and-dev-order.md`(混合模型已由用户确认)。
- **篇章继承什么(读档续章):** 读档续入下一篇章时,从上一篇章带入的具体内容(deck / 法宝 / 属性 / 叙事标记)尚未逐项敲定——这是解锁 run-manager / map-progression 走向 `/derive-requirements` 的关键一环。Source: `open-questions.md`(2026-07-15 session 遗留)。
- **属性模型:** `faith` 之外,`Status` 还要平衡哪些属性?(沿用 vision 的「类 Reigns 属性平衡」待决项。)
- Source: `10-handoffs/2026-07-15-adventure-event-profiles.md`。

## 对应
提炼至:`.claude/knowledge/systems/run-manager.md`

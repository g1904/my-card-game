# codex（图鉴族）

> **图鉴 = 账号级的知识收集面**，共**五个**：敌人 / **神通**（CharacterPower）/ **法则**（PlayerPower）/ **法宝**（CharacterItem）/ **古宝**（PlayerItem）。跨轮回持久，归 PlayerProfile。它是元进程的**第三条积累线**（与法则、Achievements 的「成就」并列）。中文定名见 `terminology.md`（08-03 改写）。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 五个图鉴（已定案）

| 图鉴 | 收录对象 | 详述 |
|------|---------|------|
| **EnemyCodex** | 已遭遇的敌人（`EnemyTemplate` 条目） | [enemy-codex](enemy-codex.md) |
| **CharacterPowerCodex** | 角色（轮回级）能力 `CharacterPower` | ⟨待播种；对象定义见 `../../character-profile/power/`⟩ |
| **PlayerPowerCodex** | 账号级能力 `PlayerPower` | ⟨待播种；对象定义见 `../player-power/`⟩ |
| **CharacterItemCodex** | 角色（轮回级）道具 `CharacterItems` | ⟨待播种；对象定义见 `../../character-profile/item/`⟩ |
| **PlayerItemCodex** | 账号级道具 `PlayerItem` | ⟨待播种；对象定义见 `../player-item/`⟩ |

Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

### 共同形状（已定案）

- **账号级、跨轮回持久，归 PlayerProfile。** 图鉴**不随轮回清理**——这正是它作为「知识资产」的意义：一次失败的轮回同样往图鉴里写了东西。
- **条目按对象的稳定 `Id` 索引。** 与全库「稳定 `Id` 是一切引用的键」一致。
- **条目内容是静态文案，挂在对应的内容 `Resource` 上；存档只记解锁状态。** 图鉴的存档负担因此**接近于一个 id 集合**——文案改版不触发存档迁移，也不撑大增量 push。
- **写入经 `profile-service.ProfileManager`。** 解锁与计数更新是 `ProfileChangeSpec` 的变更目标，不绕过唯一写入面。
- **给静态知识，不给动态情报。** 这条分层由 EnemyCodex 确立（图鉴说「这个敌人会做哪些事」，不说「它这回合做什么」），对整族适用：图鉴是**场外的知识面**，不是场内的情报面。

### 为何是一族而不是一个

- 五个图鉴形状相同、语义相同、存档形态相同——**差别只在收录对象**。把它们做成一族（共有属性一份、各自一份文档）避免五套并行的解锁 / 计数逻辑。
- **它也给「收集」这条动机一个统一的落点：** 玩得越多，五本图鉴越厚；这与成就的「完成度」是两种不同的满足感（成就衡量做到了什么，图鉴衡量见过什么）。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **图鉴共五个，构成一族；账号级、静态文案、存档只记解锁状态** —— 已定案。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **其余四个图鉴的解锁触发。** EnemyCodex = 遭遇即记；能力 / 道具类是「获得即记」「见过即记（含商店里见到）」还是「使用过即记」？→ `common-properties.md`。Source: 同上。
- **五个图鉴的词条深度是否一致。** EnemyCodex 已定为五项文案；能力 / 道具类的词条该写什么（效果说明？获取途径？出处传说？）未定。
- **是否与成就 / 奖励挂钩。** 收集完成度是否发放 PlayerPower / PlayerItem 等奖励未定。→ `../achievements/`。
- **入口与浏览形态。** 五本图鉴在主菜单如何组织（一个「图鉴」入口下分五页？）、战斗内能否查阅（EnemyCodex 尤其相关）。→ `ux/screen-flow.md`、`ux/combat-ux.md`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/codex/_index.md`（待建）。

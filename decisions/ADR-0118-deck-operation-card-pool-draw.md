# ADR-0118 — `DeckOperation` 走池抽只对 `AddLooseCard` 开放，取池链沿用商店 `Card` 族、物化时掷定

- **状态：** Accepted
- **日期：** 2026-08-27
- **来源：** handoffs/2026-08-27-card-pool-and-reshuffle.md

## 背景

`OutcomeRule.DeckOperation` 的 `TargetId` 留空意为「从该 `Op` 对应的池里抽」，但「对应的池」从未定义——这是一个静默口子：留空即无从物化。

## 决策

**走池抽收窄为仅 `AddLooseCard` 一个 `Op`**，其余四个 `Op` 的 `TargetId` **必填非空**。

**取池链逐字沿用商店 `Card` 族那一条**：`AllEnabled()` → `Pool != Enemy` → 排除功法成员卡 → `CardTypeFilter` → `RarityFilter` → 按 `RarityTier` 权重表 `PickMany` 无放回。**子流复用 `RngStream.Reward`，不新开。**

**只新增一格 `CardTypeFilter : CardType[]`**；`RarityFilter` / `Count` 与 `GrantFromPool` 共用既有两格。

**掷定时点 = 物化时，不是结算时**：抽取结果随定稿实例落存档、**绝不重抽**。

权重表**挂战后奖励池那一张**，事件产出侧**固定取一档、不按战斗优势档选表**。池容量校验降为清单式 `PushWarning`、不拒绝加载；短缺仍走物化期降级。

取池链全文与短缺处置 → `systems/adventure-event/common-properties.md`。

## 理由

**四个 `Op` 各自有独立的排除理由**：`UpgradeTechnique` 的 `Tier` 是目标层数，一次抽取给不出两个量；`ForgetTechnique` / `RemoveLooseCard` 的「池」是玩家当前卡组即运行期状态；`LearnTechnique` 会造出唯一「随机塞给你、不给选」的功法获取路径，且功法池抽需排除已持有 ⇒ 需读 `Profile` ⇒ 撞 `ADR-0068` 的两级边界，而内容侧已有等价出口（多条定值 `TargetId` + 模板分支 / Research 三选一）。

**`CardTypeFilter` 使「随机塞两张业障」写得出来。** 对走池抽的原反对意见（「业障从通用卡牌池抽讲不通」）反对的是**通用池**、不是走池抽——收窄后即成立。

**物化时掷定**是自动且强制的：Combat 类的产出在战斗之后结算，其间隔着多个决策点，结算时才掷等于开出一个可被退出重进反复摇的口子。

**池容量校验降为 `PushWarning`**：两侧承重点都不放弃——作者仍能在启动期看到池有多大，而「事件产出没付过钱 ⇒ 短缺不构成空面板」的既定分界不被推翻。

## 备选方案

- **五个 `Op` 都开走池抽** — 否决：四个各有独立排除理由，见上。
- **`LearnTechnique` 也开池抽** — 否决：撞 `ADR-0068` 的两级边界，且内容侧已有等价出口。
- **另开一条事件侧专用的取池链** — 否决：商店 `Card` 族那条已是同一件事，两条链必然漂移。
- **新开一条 RNG 子流** — 否决：`RngStream.Reward` 已是既有明文的落点。
- **池容量校验保留为加载期硬闸** — 否决：与「事件产出侧不加加载期池断言」的既定分界相反。
- **按战斗优势档选权重表** — 否决：事件产出侧没有优势档这个概念。

## 后果

- `systems/adventure-event/common-properties.md` 是取池链的权威；`systems/services/future-event-service.md` 与 `systems/character-profile/deck/_index.md` 与之对位。
- 战后奖励池三张权重表的**取值**仍待定（结构已挂靠）→ `systems/balance.md`。
- 候选短缺的三道闸 → `ADR-0073`；抽取原语的两级边界 → `ADR-0068`。
- `GrantFromPool` 的取池链在事件侧同样没有落点，须跳到 `future-event-service.md` 才读得到——既有的不对称，宜补一句回链。

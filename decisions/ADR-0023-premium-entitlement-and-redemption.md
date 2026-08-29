# ADR-0023 — 付费凭证 = `PlayerEntitlement` 两字段；购买段后端权威、兑现段客户端演算

- **状态：** Accepted
- **日期：** 2026-08-19
- **来源：** handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md · handoffs/2026-08-19-bundle-grant-ordinal-authority.md

## 背景

premium bundle 是本作唯一的付费点，每次购买给随机 1 法则 + 2 古宝，并（首次）放宽第二 / 三篇章的重试上限。它触到三条已定纪律的交界：付费凭证不能被事件拿走、云端权威、以及「谁有权说这笔钱到账了」。**静默少发一条法则 = 收了钱没给货**，是客诉与退款级别的问题。

## 决策

**① 持有状态 = `PlayerProfile.entitlement: PlayerEntitlement`，类内只放付费凭证本身与其兑现水位，不放任何派生量。** 两字段：**后端写的授予序号 `BundleGrantOrdinal`** 与**客户端写的兑现水位 `BundleRedeemedOrdinal`**。

**② 段划分：购买段后端权威、兑现段客户端演算（后端复算）。**「谁有权把 `BundleGrantOrdinal` 从 n 推到 n+1」**只能是后端**（验票事务内）；客户端**从不推进**它，只把 `BundleRedeemedOrdinal` **一格一格逐一按序**推到与之追平：

```
while (Grant > Redeemed) { ordinal = Redeemed + 1; rng = AccountRng.For(PremiumBundle, ordinal);
                           抽 1 法则 + 2 古宝 → 一次 TryApply（水位与授予同批） }
```

**③ 整条流程只在主菜单发起**，且购买入口有**四条前置条件**（在主菜单 · 待发队列为空 · 可授予池够 · 无待兑现）。

**④ 空池 = 三道闸 + 不补发**：内容加载期硬校验 · **购买入口拦截**（真正的防线，把失败点挪到掏钱之前）· 兑现结算（理论不可达，真发生则计未兑现、不补发不折价不降级替代，但**水位照常推进**）。

**⑤ 可重复购买；随机 1 法则 + 2 古宝每次都给，两项重试上限只在首次生效、不叠加**；付费面**五项明确排除**（付费续命 / 抽卡扭蛋 / 消耗型货币 / 体力加速 / 广告变现），唯一预留方向 = 纯外观。

兑现事务、取池链、诚实性纪律与呈现穷举见 `systems/monetization.md`；字段形态与读档校验见 `systems/player-profile/_index.md`。

## 理由

- **付费凭证必须是硬状态**（不参与 pipeline、后端可复算）。**capability / modifier 都是由内容条目聚合出的派生态，付费凭证是账号上的原始事实——派生态不能承载原始事实**（见 `decisions/ADR-0017-capability-flag-and-modifier-pipeline.md`）。致命的一条：生效能力集受轮回级禁用截断，把付费凭证放进一个设计上就允许被截断的聚合面，等于在结构上给「花钱买的东西被事件拿走」留后门。
- **客户端置位 = 客户端有权发货**，整套防篡改归零；事后发现不一致时玩家已拿到东西，**回收比不发更糟**。
- **兑现放客户端**是因为 `AccountRng` / `GrantPoolPicker` 若两侧各实现一遍，就与既定的「客户端掷、后端复算」分裂成两条路径。
- **为什么是循环而不是一次追平到 `Grant`**：差值恒 ≤ 1 只在单设备下成立（那条前置读的是本地 pull 快照，挡不住两台设备各自付款）。一次跳到 `Grant` 会让中间那个序号**永不被兑现**——玩家付了两次钱只拿一份货。差值为 1 时循环体只跑一次，与直接取 `Grant` 逐字等价。
- **幂等靠水位字段，不靠「重掷同一 `(域, ordinal)` 得到相同结果」**——后者是最诱人的错误答案且**不成立**：取池已排除已持有，第一次授予后池子就变了，同一 rng 会抽到**不同**条目 ⇒ 重兑 = 多发。也不靠数 `Source.PremiumBundle` 的条目数反推（置换会移除、古宝可被消耗，派生量不可靠）。
- **序号推进与「是否抽中」无关**：否则客户端会永远认为自己欠一次兑现，每次启动重掷同一 `ordinal`、抽空池、反复报错。
- **闸 ② 是真正的防线**：把失败从「退款争议」降级为「暂不可购买」。
- **③ ④ 不叠加**：重试上限是元进程难度的主要旋钮，两档（免费 ∞/3/1 与付费 ∞/9/3）是有意的口径变化，第三档就不是了；花钱买接近无限的重试会抹平 `decisions/ADR-0004-realm-checkpoint-retry-model.md` 唯一的失败压力线。

## 备选方案

- **用 `CapabilityFlag` 承载付费凭证** — 否决三条：唯一授予源是 PlayerPower 条目而礼包没有宿主条目 · 它是布尔而两项重试上限要数值 · 受轮回级禁用截断（致命）。
- **用 modifier pipeline 的具名修正承载** — 否决：同受同一条截断；且让一条法则与一份付费凭证写同一张表，等于承认法则可以改写付费权益。
- **客户端自行置位 `BundleGrantOrdinal` + 后端事后校验** — 否决：见理由第二条。
- **兑现也放后端做** — 否决：`AccountRng` / `GrantPoolPicker` 两侧各实现一遍。
- **一次性不可重复购买** — 否决：与「重账号 + 强制在线 + 长期运营」路线不匹配，且让闸 ② 几乎永无用武之地。
- **为残卷设账号级硬上限**（作为空池的替代兜底） — 否决：新机制，且与「池取尽 → 静默停摆」重复承担同一职责。
- **以灵石 / 其他资源折价补偿未兑现项** — 否决：本作没有账号级可支配货币，为兜底引入一条等于新开一套经济。

## 后果

- **`BundleGrantOrdinal` 在 `ResourceElements` 表中没有行，也不是 `CostKey` 成员**：表里的行只为客户端施加路径存在，缺行即命中既有失败语义「`Key` 无对应行 → `PushError` + 整批拒绝」，**任何日后误写的客户端置位当场在施加时大声失败**。
- **它引入同步模型此前没有的第四种情形：后端主动写入**——时机纪律与冲突窗口的关闭机理归 `systems/services/sync-service.md`。
- **购后 pull 失败 ⇒ 阻塞在主菜单重试直到成功，无硬超时、永不放弃**；等待期呈现是 Store 流程内的全屏模态进度态，不是阻塞屏的第四个变体。
- **诚实性纪律**：第二次及以后的购买，UI 必须在**付款前**如实标注本次仅含随机 1 法则 + 2 古宝。
- 商业化落地时条件编译清单由 **5 → 6**（新增 `IPurchaseBackend`），这是一次已预告的、有边界的扩张。
- 影响文档：`systems/monetization.md`（权威）· `systems/player-profile/_index.md` · `systems/services/sync-service.md` · `systems/services/profile-service.md` · `systems/common-properties.md`（账号级 RNG 与 `Source`）· `ux/screen-flow.md` · `ux/error-and-blocking-ux.md`。跨库：`backend-design-documents/contracts/purchase.md`（验票报文与幂等口径）。

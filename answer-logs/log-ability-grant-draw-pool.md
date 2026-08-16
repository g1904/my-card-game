# Answer log ability-grant-draw-pool

- 日期：2026-08-12
- 来源：`inbox/solution-draft-ability-grant-draw-pool.md`（`status: decided`，§A / §B / §C 三项取向已裁决）→ `handoffs/2026-08-12e-ability-grant-draw-pool.md`
- 移出条数：**2 条完整答结 + 2 条部分答结**

## 完整移出

**两条 PlayerPower 获取渠道的候选池与排重规则（08-09b 收窄，只剩「抽哪一条」）** → **残卷 · 礼包 · 置换共用同一段抽取**：`AllEnabled()` → 同 `(Kind, Scope)` → 去成就限定（`ExclusiveSource == null`）→ 排除已持有 → [仅置换：锚定 `Rarity`] → 按 `RarityTier` 单张共用权重表加权 seeded 抽；多条走**无放回**。

- **「抽到重复怎么办」在结构上被消解**——排重发生在**取池阶段而非掷骰之后**，池 = 未持有集合 ⇒ 抽不出重复。这不是本次的选择，而是既有设计已隐含的答案：08-09b 的全局前置「尚未拥有的法则数 > 0 才掷骰」**只有在「池 = 未持有集合」时才自洽**。
- 由此 **`HasGrantable()` ⟺ 池非空**（与全局前置是同一个判断，不是两个），`pickedPowerId` 亦有定义 ⇒ **08-09b 的残卷伪码完整可执行**。
- 三条不过滤的维度各有理由：不按 `UsableScene`（那是内容侧条目比例纪律，抽取侧再加一道等于把同一条闸门做成两处）· 不按 `status` / `disabledAbility`（生效维度与持有维度正交，被禁用的照常算已持有）· `ContentEnabled` 语义天然吃进来（关闭的退出池，已持有的照常解析、照常计入 `x`）。
- 宿主 = profile-service 内的 internal `GrantPoolPicker`（抽取需要内容池 + 已持有集合，后者是本服务自有状态；反向放 content-service 会让它读 `PlayerProfile`）；置换复用同一 picker ⇒ 全库只有一处抽取能力条目的代码。
- 归档去向：`systems/player-profile/player-power/_index.md`（权威）· `systems/services/profile-service.md`（四个门面方法 + `GrantPoolPicker`）· `systems/services/content-service.md`（`DrawPool<T>` 第四调用方）。

**premium bundle「随机的口径」（08-09b 收窄）** → 同上一段抽取。① 取 `(Power, Player)` 抽 1、② 取 `(Item, Player)` **无放回**抽 2，均已排除已持有与成就限定条目、按 `RarityTier` 加权（**与残卷共用同一张表**——分表等于让付费直接买到更高档强度）；掷骰走账号级 RNG 的 `PremiumBundle` 域，整次授予由 `(域, 序号)` 完全确定。**空池走三道闸 + 不补发**：加载期 `PushError` / **购买入口前置拦截**（把失败点挪到掏钱之前，从「退款争议」降级为「暂不可购买」）/ 兑现处 `PushError` + 上报 + 计未兑现。归档去向：`systems/monetization.md`。

## 部分移出（剩余部分仍在待答清单）

**`RarityTier` 的分布与权重表未定（08-10c 立）** → **授予池那张表已定**（Tier1–5 = 40 / 27 / 18 / 10 / 5，相邻档约 ×0.6、五档跨度 8:1；权重按剩余池即时归一；任一档为 0 → `PushError`），且**置换候选池不需要权重表**（锚定稀有度后同档等概率）。**仍待定：战后奖励池的三张表（按优势档 `Tier` 选表）与内容侧「每档应有多少条目」的编排口径。** 归档去向：`systems/balance.md`。

**成就奖励的具体条目目录（08-10b 收窄）** → **「怎么给」已答结**：**指定条目 + 成就限定**（`ExclusiveSource == Source.AchievementReward`，不进任何抽取池），原问的「抽取是否走 `AllEnabled()` 池并排除已拥有」**随之消解**（成就根本不抽取）。**仍待定：两档各给什么、奖励条目清单、是否还有其他形态的账号级奖励。** 归档去向：`systems/player-profile/achievement/_index.md`。

## interview 追加裁定（三项，非草稿既有取向）

| 项 | 冲突 / 含糊 | 裁决 |
|---|---|---|
| 账号级 RNG 形态 | 🔴 草稿 §4 改写既定的两参数 `Hash64(AccountSeed, ordinal)`，草稿自陈为待裁定的松动 | **加具名域 `AccountStream`（三参数）**。否决「序号区间隔离」（更脆、不可机械校验）与「接受相关性」。⚠ 后端 `AccountSeed` 复算契约需同步 |
| 闸 ① 的判据 | 🔴 草稿写「残卷分档上限 + 礼包之和」，但 `balance.md` 三表在 `x ≥ 15` 档仍有增量、**残卷无上限**，且「池取尽 → 静默停摆」是既定终局 ⇒ 该判据不可定义 | **收窄为「礼包所需（1/2）+ 可调余量 `GrantPoolMargin`」**。否决「给残卷设硬上限」与「删掉闸 ①」 |
| 准入字段命名 | 🟠 与 `SourceCode` 名字相邻、方向相反，草稿自陈为唯一易混点并给出替代 | **保留 `ExclusiveSource: Source?`**；缓解手段 = `common-properties.md` 并排写出四行对照表 |

## 新增待答

- **`GrantPoolMargin` 的具体取值**（闸 ① 的编排余量；结构已定、数值待内容规模明朗）→ `open-questions/07-codex-monetization.md`。

并入既有待答的两条连带：`BundleGrantOrdinal` 的落点挂在「礼包持有状态的存档表达与服务端权威」上（形状已定：账号级 · 单调递增 · 不清零 · 随授予事务同一次持久化）；购买入口的可用性呈现挂在「商业化的 UX 观感」上。

## 台账原记（自 `_index.md` 归并）

> 台账瘦身前，`answer-logs/_index.md` 本行记有以下内容，原样保留于此。

已裁决）→ ：**账号级能力授予的候选池与排重规则** —— **残卷 · 礼包 · 置换共用一段抽取**（`AllEnabled()` → `(Kind, Scope)` → 去成就限定 → 排除已持有 → 按 `RarityTier` **单张共用权重表**加权；多条**无放回**）。**「抽到重复怎么办」在结构上被消解**：排重在**取池阶段**而非掷骰之后 ⇒ 池 = 未持有集合 ⇒ 抽不出重复——而这不是新选择，08-09b 的全局前置「尚未拥有的法则数 > 0 才掷骰」**只有在此读法下才自洽** ⇒ **`HasGrantable()` ⟺ 池非空**、`pickedPowerId` 有定义、**残卷伪码补完**。宿主 = profile-service 的 internal `GrantPoolPicker`（内容池 + 已持有集合的归属决定了方向），置换复用同一 picker ⇒ 全库只有一处抽取代码。**⚠ interview 三项裁定**：**账号级 RNG 加具名域 `AccountStream`**（修订既定两参数形态；否决序号区间隔离）· **闸 ① 收窄为「礼包所需 + 可调余量」**（原判据「残卷分档上限」在既有设计中**不存在**——残卷无上限、池取尽是既定终局）· 准入字段保留 **`ExclusiveSource: Source?`**。礼包空池 = **三道闸 + 不补发**（加载期 `PushError` / **购买入口前置拦截** / 兑现处报错）。**成就奖励改为指定条目 + 成就限定** ⇒ **恒不落空**（一条可断言的不变式 + 三条 `PushError` 校验）。`Rarity` 消费点 2 → 3；`DrawPool<T>` 调用方 3 → 4，**无放回 + 加权**入契约。不 bump schema。**⚠ 后端侧需一份对应 handoff**（`AccountSeed` 复算多一参数　｜移出条数原记：2（另 2 条部分答结、新增待答 1 条）

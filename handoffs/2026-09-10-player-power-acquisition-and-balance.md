# PlayerPower（法则）的获取 / 失去触发与平衡边界 —— 五投影一次收口

- id: 2026-09-10-player-power-acquisition-and-balance
- date: 2026-09-10
- topic: systems/player-profile/player-power/_index.md（唯一权威） · systems/player-profile/_index.md · systems/services/profile-service.md · systems/services/life-cycle-service.md · ux/screen-flow.md · systems/common-properties.md · systems/balance.md
- status: distilled
- distilled-to: systems/player-profile/player-power/_index.md, systems/player-profile/_index.md, systems/services/profile-service.md, systems/services/life-cycle-service.md, ux/screen-flow.md, systems/common-properties.md, systems/balance.md

## Intent（distilled）

**一句话：** 「PlayerPower 的获取 / 失去触发与平衡边界」这一条长期未决，在五份文档上留下了五个措辞各异的投影；其五个组成部分中**四个早已在库内别处答定**，真正开着的只有一项取向（是否开放第三条获取渠道）加一处 UX 版式缺口。本次一次合成收口：定「不开第三渠道」，把四份答案回链到位，收敛为**单一权威（`systems/player-profile/player-power/_index.md`）+ 四处回链**。

### 一、获取通道已闭合，本层只余内容口径

`(Power, Player)` 域的合法 `Source` 恰三个，逐条已有组装者与施加链路，**不需要任何新机制、新字段、新 element、新存档格**：

| # | 渠道 | `SourceCode` | 组装者 | 施加时机 | 随机源 |
|---|---|---|---|---|---|
| ① | 道统残卷（Finale 通过掷中） | `FinaleWin` | `CombatEventResolver` → `CombatResult.Spoils` 的一个 element | Finale 的 `eventEnd` 那一次 `TryApply` | `AccountRng.For(AccountStream.PowerFragment, FinaleWinOrdinal + 1)` |
| ② | premium bundle（付费礼包，随机 1 条） | `PremiumBundle` | 兑现事务（读 `BundleGrantOrdinal` 水位） | 兑现事务内一次 `TryApply` | `AccountRng.For(AccountStream.PremiumBundle, 本次 ordinal)` |
| ③ | 成就 90% 档一次性奖励（指定条目，非抽取） | `AchievementReward` | `AchievementManager` 采集 → `ProfileManager` 单点提交 | 达标那一次 `TryApply`，零新增存档点 | 无随机（`AccountStream` 刻意不设成员） |

- ① ② 共用同一段抽取与同一张 `GrantPoolWeights`；③ 走 `ExclusiveSource == AchievementReward` 的专属条目、按定义不进任何抽取池 ⇒ 三者互不撞车，成就奖励恒不落空是机械保证。
- **`x` 只被 ① 推动**：② ③ 不计入，这是有意的——把付费与成就奖励算进自变量等于让玩家买到的东西反过来掐死自己的残卷线。
- `EventOutcome` / `ExchangePurchase` 两格由「暂不开放」改判为**规则层封死**（见 Clarifications 第 1 条）。

### 二、失去触发已闭合，「在哪些 AdventureEvent」按定义是内容编排的产物

失去恰三形态（本场移除 < 本轮回禁用 < 账号移除），逐形态的触发点、是否写 Profile、element 形态、是否需玩家同意、目标频次全部已定；频次的旋钮全落内容侧、零字段零校验零状态位。答案形态是「每支 1–2 条 `Rare` 档条目」，具体条目随内容阶段落地——**不是设计层的待决**。

### 三、cycle seed 与计分公平：两者不相交 / 刻度已有且是评审参考

- **cycle seed 侧结构性不相交：** 账号级掷骰不派生自 `CycleSeed`、不消耗任何子流 `State`；反向也不成立（取池链只读「已持有集合」做排重，`status` / `disabledAbility` 不参与取池过滤）。`FinaleWinOrdinal` 同时是幂等键。
- **计分公平侧：** 刻度 = 道念净贡献占本方 `baseMomentum` 的比例（单条 ≤ 10%、老账号全开合计 ≤ 25%、不得随对局延长而累积）。两个百分比落纪律阶梯**第 4 级（零保证）**，不得被引为承重依据，且**不为它补代理指标**；承重的是那条定性定位。

### 四、防 pay-grind-to-win：已有七道护栏，整理成表，不新增机制

七行逐条只回链、不复述对方设计：付费战斗价值由古宝承载 · 战斗内法则 ≤ 1/5 条目（启动期机械检查）· 礼包与残卷共用同一张权重表 · 付费面五项排除 + 礼包两池不得产出寿元 · 重试两档且免费档是可通关基准 · 残卷的递减供给曲线 + 篇章闸门 + 全局前置 · `FinaleWinOrdinal` 幂等键 + 两个中间值供后端逐位复算。

**两条已被接受的代价如实并列：** 礼包是一份净强度增益；账号级法则总量无硬上限而「≤ 25%」是零保证的评审参考。**本次不提出任何新机械闸**，改为补一个可算的分母。

### 五、「老账号全开」的分母：账号级法则获取速率的派生量

由残卷分档表（六档 + 首胜硬置行）与「一篇章一个 Finale」算出的派生量落 `systems/balance.md`（不是第四张配置表、不落任何字段、不得被当作独立锚引用）。三条读法：

1. **现实分母是 `x ≈ 9–12`，不是「池被取尽」。** `x ≥ 15` 是渐近线而非可达点（≈74 次完整通关）；校准 ≤ 25% 时按 `x ≈ 12` + 礼包所得 + 成就 90% 档所得取分母。累计里程碑：`x = 5` ≈第 6 个 · `x = 9` ≈第 14 个 · `x = 12` ≈第 34 个 · `x = 15` ≈第 74 个完整轮回。
2. **两个方向相反的偏差同时存在：** 分母取完整轮回而多数轮回中途身死 ⇒ 真实速率**更低**；表把 `0 → 3` 档整体写成由三次首胜占满、未计入 `0 < x < 3` 档常规掷骰 ⇒ 在该档上估算**偏慢**。两条一起写，才不会让这张派生表被当成单向上界引用。
3. **旋钮位置与调整方向已在权威处给出**（下调阈值、表结构不变），本表只是它的量化底稿。

### 六、`status` 开关 UI：形态已有，本次把操作控件的落层定下

一屏一列表、不新增主菜单入口、不做分页 / 分类 tab（法则总数量级是个位到十几条）。开关落**候选项列表语言的第七位「行尾操作控件」（仅纵向侧）**；`status == false` 时整行弱化但不移出列表；本轮回禁用的行灰态 + 徽标 + 三档时长文案 + 长按查看来源事件，且**开关在该行上仍可操作**（`status` 与 `disabledAbility` 是两个正交维度）。零 hover；框架文案归 `PROFILE_` 分区，法则名 / 描述仍是内容层 `LocalizedText`。零新增存档字段、零新增服务方法。

## Clarifications

1. **法则是否开放第三条获取渠道（事件 outcome 直接给予）？** → **不开。** `(Power, Player)` 域的 `EventOutcome` / `ExchangePurchase` 两格由「※ 暂不开放」改判为**规则层封死**。⇒ 「后端零改动、不落 counterpart」这一条件性判定的条件随之满足，本次不写后端库。
2. **法宝置换的频次口径（跨分片转交句）。** → **并入上层 ≈1.0 合计。** 落笔为「法宝置换与法宝 / 古宝禁用一并计入上层 ≈1.0 的分子；具体份额归 `character-profile/item/` 侧裁定并回链四支频次表」。**不写「自持口径」「不进上层合计」**；`ADR-0161` 的四支枚举不扩为五支、该 ADR 不改写。依据：自持判据首条为「它不写 Profile」而法宝置换写 `CharacterProfile` ⇒ 判据失败；同层的神通置换（同为轮回级 build 损失、同写 Profile）在上层合计内占 ≈0.5；古宝禁用事件已明写一并计入该分子。
3. **法则列表屏的开关控件落在哪一层？** → **给候选项列表语言的构件加第七位「行尾操作控件」（仅纵向侧）。** 「触控目标 = 整个条目」改写为「纵向侧允许行尾一个独立操作热区，其余区域仍为整行」。**外溢判据同批写明：第七位仅当该行的操作是幂等的账号级开关时开放**；其余七个决策面不因此开放。理由：行尾操作控件在库内已有先例（战斗启动区的逐行列表每行带启动键），本次只是把它并进构件表；而把一屏的核心操作降到长按第二层与移动优先纪律方向相反。
4. **是否与 `GrantPoolMargin` / `K` 的取值合场？** → **不合场。** 本次只收通道 / 边界口径；三格取池余量与 `K` 的取值原样留在各自的待决条目里。依据：那条待决明写「可先填 0：结构与断言不依赖取值」⇒ 不阻塞任何落地，且两条的解锁条件不同。

**本次自动采纳的标准默认（改变了草稿写法的几处，逐条列出以备核对）：**

5. **累计轮回数取更正值。** 草稿的累计漏加了 `3 ≤ x < 5` 档的 2.7：正确值 `x = 5` ≈5.7 · `x = 9` ≈13.7 · `x = 12` ≈33.7 · `x = 15` ≈73.7 ⇒ 落笔取 ≈6 / ≈14 / ≈34 / ≈74（草稿写的 11 / 31 / 71 一律 −2.7）。读法 1 的「校准按 `x ≈ 12`」= ≈34 个完整轮回处；「`x ≥ 15` 需 70+ 次」= ≈74 次。
6. **残卷分档表实为 6 档 + 首胜硬置行，不是 4 档。** 草稿的「50/30 → 30/20 → 10/5 → 5/3」漏了两档重复（`3 ≤ x < 5` 与 `5 ≤ x < 9` 同为 30/20；`9 ≤ x < 12` 与 `12 ≤ x < 15` 同为 10/5）。派生表按 6 档落笔。
7. **`profile-service.md` 的待决行是 `:515`，不是草稿沿用的 `:517`**（`:517` 是 `Source:` 行）；四项排除清单在 `:514`。
8. **列表屏框架文案归 `PROFILE_` 分区，不是草稿写的 `MENU_`**（`MENU_` = 主菜单、篇章切换、更新横幅；`PROFILE_` = PlayerProfile / CharacterProfile 面板、图鉴族、成就）。
9. **`player-profile/_index.md:208` 收窄而非整条删除。** 该条的 `PlayerItem` 那半确未闭合（Exchange 购买、事件产出在 PlayerItem 侧仍是方向而非定案），整条删除会静默丢掉那条待决。
10. **分域校验表上的 ※ 是三格不是两格**（`EventOutcome × (Power, Player)` · `EventOutcome × (Item, Player)` · `ExchangePurchase × (Power, Player)`），三格一并改判为 ❌ 规则层封死，`※` 脚注整段删除。第三格（古宝域）早已被「事件产出不能给账号级古宝（承重）· `GrantFromPool` 的 `PoolKind` 拒绝 `PlayerItem`」封死，那格 ※ 是陈旧副本，改判属修正而非新决策。
11. **后端零改动已直读印证：** 上行白名单已含相关路径、校验只有 `lastRoll` 逐位比对与「命中自洽」两条、契约明写其客户端对位改动已在客户端库落笔；本次不改 `x` 口径、不新增会被后端读到的取值、不移动任何透明路径 ⇒ 零后端义务、不 bump `schemaVersion`、不落 counterpart。
12. **护栏表只回链「文件路径 + 条目题头」，不写行号**——本次已在两份文件上各查出一组漂移的行号，而护栏表是要长期被引用的活文档内容。
13. **两个百分比在护栏表与承重句里必须显式标「第 4 级（零保证）」，且不为它补代理指标**（草稿的备选方案节已按此否决过一个代理指标提案，保留）。

## Open questions

- **成就组数（⇒ `AchievementReward` 渠道的法则供给量）尚未定。** 90% 档每组发一条法则 ⇒ 该渠道总供给 = 成就组数。这个数没定，「老账号分母」就只能给出残卷 + 礼包两条的量。归内容阶段（专属奖励条目目录依赖法则 / 古宝条目先行）。本次其余部分不受它阻塞。
- **派生表待实测校准。** 它建立在「生效概率取该档 `[Base, Cap]` 中值」这一个假设上（真实值取决于失败频次推动的 `Accumulated`），且分母取完整轮回。

# 道统残卷 / `PlayerPowerFragment` —— 焊到 Finale 上的失败侧掉落概率

- id: 2026-08-09b-player-power-fragment-finale-bound-drop-chance
- date: 2026-08-09
- topic: systems/player-profile/player-power, systems/player-profile, systems/adventure-event/finale, systems/services/life-cycle-service, systems/services/profile-service, systems/game-progression, systems/monetization, systems/common-properties, systems/balance, terminology
- status: distilled
- distilled-to: terminology.md, systems/player-profile/（_index.md, player-power/_index.md, account-info.md）, systems/adventure-event/finale/_index.md, systems/services/（life-cycle-service.md, profile-service.md）, systems/game-progression.md, systems/monetization.md, systems/common-properties.md, systems/balance.md, systems/scoring.md, systems/services/future-event-service.md, open-questions.md, open-questions/（06-meta-progression.md, 07-codex-monetization.md, deferred-content.md, update-log.md）, answer-logs/log-legacy-fragment-chance.md, backend-design-documents/open-questions.md

## Intent（distilled）

**一句话：** 08-01 只给了方向的「道统残卷」（失败累积的 PlayerPower 掉落概率）在本次被整条焊死到 **Finale（天劫）** 上——**在天劫下失败积攒、在渡劫成功的那一刻兑现**；定名 **道统残卷 / `PlayerPowerFragment`**；上限、基础概率与适格篇章按**账号已拥有法则数 `x`** 分档；掷骰走一条**与 `CycleSeed` 完全解耦的账号级 RNG**，客户端掷、后端可复算。方向的代价是**口径收窄**：「失败侧有产出」这条对绝大多数失败不再成立。

### 0 · 定名

**中文 = 道统残卷；标识符 = `PlayerPowerFragment`。** 与 `PlayerPower` 同族，读即知它是「法则的碎片」，无需额外解释它属于账号级。类名、字段前缀、平衡表键、element key 一律沿用此名。`terminology.md` 中「—（标识符待定）」由此填实。

### 1 · 三个时刻全部落在 Finale 上

- **累积触发 = Finale 战斗失败**（不论角色是否因此 `defeated`）。其余一切失败——普通 Combat / Practice 失败、寿元耗尽、`lifeTotal` 耗尽、主动弃置——**一律不累积**。
- **掷骰触发 = Finale 战斗胜利**，一次胜利掷一次。
- **发放时刻 = 该 Finale 的 eventReward 界面**（同一场 Finale 的奖励结算），掷中的法则与战斗奖励一并呈现。
- **每个篇章只有一个 Finale，失败后不可在同一篇章内再次挑战。**
- **例外分支（约 1%）：Finale 失败但 `lifeTotal` 未被打穿 ⇒ 角色存活并顺利完成该篇章。** 这种情况**照常累积、但不掷骰、不发放**——发放只认胜利。

**由此得到的四条结构性简化：**

- **不需要跨轮回的待发放字段。** 掷骰与发放同刻同事务，`PendingPowerId` 一类的中间态不存在。**残卷因此是一个纯粹的单值状态**（一个概率 + 三个首胜标记 + 一个序号）。
- **整条机制落在既有的 Finale 结算链路上**：`CombatEventResolver` → `CombatResult.Spoils` → `eventEnd` 的那一次 `TryApply`。**授予法则成为 Spoils 的一个 element**，不新增结算阶段、不新增存档点；Finale 结算本就是篇章边界的 `Immediate` flush 点。
- **累积天然有界、刷取成本极高。** 「一篇章一个 Finale + 败后不可重战」⇒ **每个角色每篇章至多累积一次或掷骰一次，且二者互斥**。要多累积一次就得重走一整个篇章（30–55 分钟），且 ch2 / ch3 另有重试上限（3 / 1，付费 9 / 3）封顶。**残卷不需要任何额外的防刷规则。**
- **叙事自洽**：在天劫下失败积攒残卷，在渡劫成功的那一刻兑现——「获得」与「突破」同刻。

### 2 · 上限、基础概率与适格篇章按已拥有法则数 `x` 分档

`x` = 账号当前**已拥有**的 PlayerPower 数量（`PlayerProfile.List<PlayerPower>` 的元素数）。`status` 开关与「本轮回禁用」**不影响计数**——它们是生效维度，不是持有维度。

| `x` | 适格 Finale（掷骰 + 发放） | 概率上限 | 基础概率 |
|---|---|---|---|
| **每个篇章的首次 Finale 胜利** | 该篇章（**优先于闸门**） | **100%（硬置）** | — |
| `0 < x < 3` | ch1 · ch2 · ch3 | **50%** | **30%** |
| `3 ≤ x < 5` | ch1 · ch2 · ch3 | **30%** | **20%** |
| `5 ≤ x < 9` | ch2 · ch3（**移除 ch1**） | **30%** | **20%** |
| `9 ≤ x < 12` | ch2 · ch3 | **10%** | **5%** |
| `12 ≤ x < 15` | ch3（**再移除 ch2**） | **10%** | **5%** |
| `x ≥ 15` | ch3 | **5%** | **3%** |

- **全局前置**：**仅当「尚未拥有的法则数 > 0」时**才累积、才掷骰、才发放。池已取尽 → 整条线静默停摆，概率停在原值。
- **上限是硬上限**；**基础概率是该档的地板**：进入该档即至少有此概率。
- **篇章闸门是逐档累加地移除**，不是「限定到某一章」：`x ≥ 5` 移除 ch1，`x ≥ 12` 再移除 ch2。
- **首胜规则优先于闸门**：某篇章的**首次 Finale 胜利**一律硬置 100%，**即使该篇章在当前档已不适格**。理由：三次首胜是账号生命周期里三份确定的里程碑，被闸门吃掉会造成「第一次渡劫成功却空手」。冲突面只有一种——`x ≥ 12` 且 ch2 从未首胜（长期只刷 ch1 的账号）。
- **`x = 0` 不需要单独档位**：首胜 100% 必中（池非空前提下），故 ch1 首胜后 `x ≥ 1` 恒成立。
- **`x` 单调不减**：法则不被强制剥夺、置换是等价交换 ⇒ **档位只会下降、不会回跳**。

### 3 · 累积增量按 `x` 与失败所在篇章双重分档

| `x` | ch1 Finale 失败 | ch2 Finale 失败 | ch3 Finale 失败 |
|---|---|---|---|
| `x < 5` | **+1%** | **+2%** | **+5%** |
| `5 ≤ x < 12` | **0**（不再累积） | **+1%** | **+3%** |
| `x ≥ 12` | **0** | **0**（不再累积） | **+1%** |

**两张表是同一条闸门的两面（承重的简化）：**

> **适格 Finale ⟺ 该档增量 > 0 的篇章。**

`x ≥ 5` 移除 ch1 与「ch1 失败不再累积」是同一条；`x ≥ 12` 移除 ch2 与「ch2 失败不再累积」是同一条。**实现侧因此只需一张按 `(x, chapter)` 索引的表，`gain == 0` 即表示该篇章在该档整体退出残卷系统**（既不累积也不兑现，首胜例外），不需要两套独立判定。这条一致性使「在某章输了却只能在别章兑现」的错位不可能出现。

### 4 · 生效概率的合成与重置

```
若 该篇章尚无 Finale 胜利记录            → 生效概率 = 100%（首胜优先，忽略闸门）
否则若 Gain(x, chapter) == 0            → 不掷骰（该篇章在本档不适格）
否则                                    → 生效概率 = clamp(Accumulated, Base(x), Cap(x))
```

- **`Accumulated`** = 历次 Finale 失败按 §3 累加的值（持久、跨角色、跨轮回）。
- **发放后重置为新档基础概率**：掷中并授予后，`Accumulated` **置为 `Base(x + 1)`**（授予后的新档地板），而非归 0——归 0 会让分档表给出的地板形同虚设。
- **`x` 跨档时不清空 `Accumulated`，只在读取时被新档的 `Base` / `Cap` 钳制**——跨档不吞掉玩家已积累的失败。

### 5 · 掷骰的 RNG：账号级、与 `CycleSeed` 完全解耦；客户端掷、后端可复算

**绝不能走 `SeedManager` 的四条子流。** 四条全部由 `Hash64(CycleSeed, streamName)` 派生，而**篇章重试会生成全新的 `CycleSeed`**——把账号级掉落挂上去，等于让玩家靠重试换一次掷骰结果。

```
roll = Hash64(AccountSeed, FinaleWinOrdinal) mod 10000     // 0..9999，万分比精度
命中 ⟺ roll < 生效概率（万分比整数）
```

- **`AccountSeed`**：账号创建时由后端下发、落 `AccountInfo` 的 `ulong`，跨设备一致。**不进 `SeedManager`、不进子流清单**，故不触及「增删子流不 bump schema 版本」那条纪律。
- **`FinaleWinOrdinal`**：账号级的 Finale **胜利**序号，单调递增、不清零（失败与「失败但存活」都不自增）。它同时是**幂等键**——同一序号重复结算得同一结果，退出重进 / push 重放都不改变掉落，与决策点存档的防重掷同一条纪律。
- **对轮回可复现性零影响**：不从 `CycleSeed` 派生、不消耗任何子流的 `State`。**「与 seed 公平性的关系」的答案因此是：两者不相交。**
- **执行方 = 客户端掷骰，后端可复算。** 后端尚未开工，客户端因此可先端到端跑通（与三个边界服务的离线 stub 策略一致）；`AccountSeed` 在后端、`FinaleWinOrdinal` 与命中结果随 profile 上行，**后端可离线复算任一次掷骰**，防篡改能力不因客户端执行而丢失。**Finale 的奖励结算因此不引入任何新的网络往返**，也不需要为它扩写断线降级路径。

**「持有的法则不同 ⇒ 同一 seed 的轮回体验不同」不构成公平性问题**：账号状态本就是轮回的输入（deck、法则、古宝皆然），既定的确定性承诺只覆盖「同一存档恢复后能正确继续」。

### 6 · 与 premium bundle 的关系：不重置概率，但压低上限

- 礼包给予的随机 1 个 PlayerPower **不重置** `Accumulated`——重置只发生在残卷自己掷中并发放时。
- 但礼包使 `x` +1，**可能把账号推进上限更低的档位**（例如 `x` 由 2 变 3 ⇒ 上限 50% → 30%）。**这是有意的**：`x` 分档的本意就是「拥有得越多，后续越难再得」，获取渠道是打还是买不改变这条曲线。
- **推论：付费不会吞掉玩家已积累的失败，只会让下一条法则来得更慢。** 与「付费是增值而非必需」的既定口径同向——礼包立刻给出一条法则，代价是后续掉率下降，**净收益仍为正，但不叠加**。

### 7 · 状态落点 = `PlayerProfile` 上一个具名小类，不进统计计数

在 `PlayerProfile` 上新增具名小类 **`PlayerPowerFragment`**，**不**并入 08-06b 的账号级统计计数容器。理由：08-06b 已立判据——**参与规则判定的字段与纯读数的统计计数分属两层**。残卷概率直接决定「发不发一条法则」，是规则输入，与 `chapterRetry` 同性质；混进统计计数会让「统计可走宽松同步口径」这条便利判断失效。

**篇章首胜标记落三个具名布尔**，沿用 `chapterRetry` 的既定形态（「篇章数是固定的游戏结构，不是可扩展列表」，不用字典 / 索引数组）。

| 字段 | 类型 | 语义 | 默认 |
|------|------|------|------|
| `Accumulated` | `int` | 累积概率，**万分比整数** 0–10000（不用 `float`：存档 / 跨端一致性 + 后端可复算，且避免浮点比较） | `0` |
| `FinaleWinOrdinal` | `int` | 账号级 Finale **胜利**序号，单调递增、不清零；掷骰的幂等键 | `0` |
| `Ch1FirstWinDone` | `bool` | 第一篇章 Finale 是否已首胜（**失败但存活不置位**） | `false` |
| `Ch2FirstWinDone` | `bool` | 同上，第二篇章 | `false` |
| `Ch3FirstWinDone` | `bool` | 同上，第三篇章 | `false` |

`AccountSeed`（`ulong`）落 `AccountInfo`，由后端在账号创建时下发。**`x` 不落字段**——它是 `List<PlayerPower>.Count` 的派生量，落字段即制造第二份真值（与「`CapabilitiesChanged` 空负载、订阅者自行重查」同一条纪律）。

### 8 · 写入通道 = 并入 Finale 的那一次 `TryApply`

- **累积**（Finale 失败 / 失败但存活）：并入该 Finale 的 `eventEnd` 事务——与 `baseReward`、`lifeTotal` 扣减、`lifeSpanCost` 同一次 `TryApply`。
- **掷骰 + 发放**（Finale 胜利）：并入该 Finale 的 `eventEnd` 事务——`Spoils` 内含「授予法则」element + `Accumulated` 重置 element + `FinaleWinOrdinal` 自增 element + 首胜标记置位 element。
- 二者都不新增结算阶段、不新增存档点。**授予仍走既有的 `ProfileManager.GrantPower(powerId)` 语义**，只是这次由 Spoils 触发。

判定形态（伪码，`x = profile.PlayerPowers.Count`）：

```csharp
if (!_powerPool.HasGrantable()) return;                        // 池已取尽：静默停摆
int gain = _balance.PowerFragmentGain(x, chapter);             // §3 表；gain == 0 ⇒ 本档该篇章整体不参与

if (!won)                                                      // 失败（含「失败但存活」的 1% 分支）
{
    if (gain > 0) spec.Add(PowerFragmentAccumulated, +gain);   // 钳制到 10000
    return;                                                    // 不掷骰、不发放
}

bool firstWin = !profile.PlayerPowerFragment.FirstWinDone(chapter);
if (!firstWin && gain == 0) return;                            // §2/§3 合一的适格闸门；首胜优先于它

int effective = firstWin
    ? 10000
    : Math.Clamp(accumulated, _balance.PowerFragmentBase(x), _balance.PowerFragmentCap(x));

int roll = (int)(Hash64(accountSeed, ordinal + 1) % 10000UL);
spec.Add(PowerFragmentWinOrdinal, +1);
if (firstWin) spec.Set(PowerFragmentFirstWin(chapter), true);

if (roll < effective)
{
    spec.Add(GrantPower, pickedPowerId);                                   // 候选池抽取规则见 Open questions
    spec.Set(PowerFragmentAccumulated, _balance.PowerFragmentBase(x + 1)); // §4 重置为新档地板
}
```

### 9 · 玩家侧呈现：彻底隐含，失败侧不给任何提示

- **Finale 失败结算不给任何文案、不给暗示、不给进度条、不给百分比。** 残卷对玩家是完全不可见的账号级状态。
- **唯一的可见面是命中时的那一次发放**：在 Finale 的 eventReward 界面上作为一项奖励呈现（呈现措辞归 `ux/screen-flow.md`）。
- **推论**：本条比既定的「隐含状态」更彻底——**连隐藏属性的跨档定性叙事都不复用**。

### 10 · 数值与校验

分档阈值（3 / 5 / 9 / 12 / 15）与各档取值**均为可调数值**，归 `systems/balance.md` / `.tres`，随内容 overlay 可调；代码侧只读「当前档的上限 / 基础 / 增量」三个概念，**不为分档写分支**（与赋级带「不为分章写分支」同款）。

- 读档时 `Accumulated` 落在 `[0, 10000]` 外 → `GD.PushWarning` + 钳制；三个首胜布尔与通关史不一致时**以布尔为准**（它是权威，不由通关史重建）。
- 掷骰点日志：`[LifeCycle-FinaleResolve] powerFragment x={x} ch={n} ordinal={o} eff={e}‱ roll={r} hit={bool}`；累积点：`[LifeCycle-FinaleResolve] powerFragment gain={g}‱ acc={a}‱`。

## 后果

- **`PlayerProfile` schema 新增 `PlayerPowerFragment`（5 个字段）+ `AccountInfo` 新增 `AccountSeed`** ⇒ 存档 schema 版本 bump，迁移 = 老档缺字段以默认值补齐（无损）。
- **`SeedManager` 不受影响**（不新增子流）；**断线降级路径不受影响**（客户端掷骰，无新增网络往返）。
- **新增若干 `ChangeElement`**（累积 / 序号 / 首胜标记 / 授予法则）⇒ 与 `profile-service.md` 的「cost element 清单未定」接壤，本次为它添了具体条目。
- **`AccountSeed` 是一条客户端 ↔ 后端契约**（下发 + 掷骰复算校验），已登记进 `backend-design-documents/open-questions.md`。
- **Finale 的语义被扩写了两条**：**每个篇章只有一个 Finale，失败后不可在同一篇章内再次挑战**（推翻 08-06d 的「失败后可再挑战」）；**Finale 失败但存活（约 1%）⇒ 篇章照常完成、境界照常突破**。**承重：这使渡劫的胜负不再是篇章推进的闸门**——它只决定 `lifeTotal` 损失与残卷是否兑现，叙事侧需一句补白（「侥幸捱过天劫者亦得突破，只是无所得」量级）。
- **Finale 成为残卷的唯一累积源与唯一兑现点** ⇒ 一条账号级机制被焊到一个事件子类型上。可刷性已由「一篇章一个 Finale + 败后不可重战 + 重试上限」三重封住。
- **付费与残卷之间存在一条有意的负反馈**：礼包 +1 法则 ⇒ `x` 上升 ⇒ 后续上限下降。`monetization.md` 的「与道统残卷的交互」由此答结。

## 与既有决策的张力

**① 措辞级张力（本次已改写，不构成推翻）：** `terminology.md`、`player-power/_index.md`、`open-questions/deferred-content.md` 三处原写作「**下一次轮回**获得新 PlayerPower」「轮回开始时的概率掉落」。掷骰与发放现**同刻发生在 Finale 胜利的 eventReward 界面**，跨轮回时序整个消失，三处已统一改写为「**在 Finale（天劫）胜利时掷定并即时发放**」。

**② 需要正视的口径收窄：** 原定案的「**失败**累积」现收窄为「**Finale 失败**累积」。**普通战斗失败、寿元耗尽、`lifeTotal` 耗尽都不再有残卷产出**——即「失败侧首次有产出」（08-01）这条对**绝大多数失败**不再成立，失败侧的常规产出只剩 EnemyCodex 遭遇即记与失败经验两条。这是有意的收窄（把产出点集中到篇章收口处）；`systems/scoring.md` 与 `systems/services/future-event-service.md` 中「失败不是零产出」的论证链已相应改写，不再把残卷当作普遍适用的论据。

**③ Finale 胜负不再是篇章闸门。** `finale/_index.md` 的「Finale 失败常常等于死」仍成立（走 `LifeTotalExhausted` 通道），但补上了 1% 的存活分支及其推进语义；同处「失败后可再次挑战 Finale」**被推翻**。

其余无张力：ADR-0003 / ADR-0004 未被触及；`SeedManager` 四条子流常量与确定性边界的既定措辞原样成立。

## Open questions

- **候选池与排重规则（前置依赖 · 归 `open-questions/07-codex-monetization.md`）。** 伪码里的 `pickedPowerId` 与 `HasGrantable()` 依赖它——「从哪个池抽（`AllEnabled()` 全池 / 排除已拥有 / 按稀有度）」「抽到重复怎么办」。**本方案其余部分不依赖它**：累积、上限、闸门、RNG、字段落点均已定稿。
- **`FinaleWinOrdinal` 与账号级统计计数的边界。** 本次主张残卷**不并入**统计计数；但 `FinaleWinOrdinal` 与统计侧未来可能出现的「总通关数」口径相近而不同（前者参与判定、后者纯读数），届时应明写区别，避免被当成重复字段合并掉。→ `systems/player-profile/`。
- **`AccountSeed` 的下发与复算协议形态。** 何时下发、随哪条响应返回、后端复算不一致时的处置（拒绝上行 / 以云端为准改写 / 上报）。→ `backend-design-documents/`。
- **1% 存活分支的叙事补白落点。** 「渡劫 = 突破到下一境界」需要一句让「失败也能突破」读起来不像笔误的文案，归 `ux/` 还是 `plot-manager`？

## Notes / triage

来源：`inbox/solution-draft-legacy-fragment-chance.md`（`/provide-solution-draft` 产出，经用户 08-09 三轮直接裁定，无剩余待决项）。草稿已移入 `inbox/archive/`。

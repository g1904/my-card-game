# 授予来源 `SourceCode` / `Source` 枚举，与道统残卷 `x` 的口径收窄到 `FinaleWin`

- id: 2026-08-10b-grant-source-and-fragment-source-scoping
- date: 2026-08-10
- topic: systems/common-properties, systems/player-profile/（player-power, player-item）, systems/character-profile/（power, item）, systems/balance, systems/monetization, systems/services/（profile-service, life-cycle-service, plot-manager）, systems/adventure-event/finale, terminology
- status: distilled
- distilled-to: terminology.md, systems/common-properties.md, systems/player-profile/（_index.md, player-power/_index.md, player-power/common-properties.md, player-item/_index.md, player-item/common-properties.md）, systems/character-profile/（power/_index.md, power/common-properties.md, item/_index.md, item/common-properties.md）, systems/（balance.md, monetization.md）, systems/services/（profile-service.md, life-cycle-service.md, plot-manager.md）, systems/adventure-event/finale/_index.md, open-questions.md, open-questions/（06-meta-progression.md, 07-codex-monetization.md, update-log.md）, answer-logs/log-0810b.md

## Intent（distilled）

**一句话：** 给**神通 / 法宝 / 法则 / 古宝**四类持有条目统一加一个**授予来源**字段 `SourceCode`（类型 = 新枚举 `Source`，成员带稳定 code + 展示 value），并用它把**道统残卷的分档自变量 `x` 收窄为「`SourceCode == FinaleWin` 的法则数」**——礼包与成就奖励拿到的法则**不再压低残卷档位**（推翻 08-09b §6）。附带答结 08-09b 遗留的「1% 存活分支叙事补白落点」= **plot-manager 的叙事层**，文案两版已给。

### 1 · `SourceCode`：四类持有条目的共有字段

**凡「可被授予并持有」的条目都带 `SourceCode`**，记录**它是被哪条渠道给到玩家的**：

| 层 | 条目 | 持久层 |
|---|---|---|
| 账号级 | **法则 PlayerPower** · **古宝 PlayerItem** | `PlayerProfile` |
| 轮回级 | **神通 CharacterPower** · **法宝 CharacterItem** | `CharacterProfile` |

- **落在持有条目上，不落在 `PowerData` / `ItemData` 上。** 这是既定物化模型的直接推论：`XxxData : Resource` 是 ContentRegistry 里的**共享只读单例**，而**同一条法则可以由不同渠道获得**——来源是「这一次获取」的属性，不是内容定义的属性。它与 `status` 同层，正是 `character-profile/power/common-properties.md` 中「持有条目的运行态字段 ⟨待定⟩」里已经预留的那一格。
- **写入时刻 = 授予时刻**，此后不变。条目被移除后再次获得 = **一次新的获取**，写新的 `SourceCode`（因为那是一个新条目）。

### 2 · `Source` 枚举：带 code 与 value

`Source` 是一个 **C# 枚举**，穷举全部可能的授予渠道，每个成员带两样东西：

- **code** —— **显式的稳定整数**，是存档 / 上行负载里实际序列化的东西。重命名成员不破坏存档；**已删成员的 code 永不复用**。
- **value** —— **展示文案**（「渡劫所得」「礼包」「成就」……），与 code 分离、可本地化，**不落存档**。

这与既定纪律同构：capability flag 的载体是 `enum CapabilityFlag` 而非字符串 key（拼错要在编译期暴露）；显示字符串一律与键分离（`systems/common-properties.md`「稳定 Id 键」）。

**成员清单已穷举、封闭三值：**

| 成员 | 语义 | 是否计入残卷的 `x` |
|---|---|---|
| `FinaleWin` | 渡劫成功时由道统残卷掷中并发放 | **是（唯一计入者）** |
| `PremiumBundle` | 付费礼包给予 | 否 |
| `AchievementReward` | 成就奖励给予 | 否 |
| `Unknown = 0` | 防御性成员：老档缺字段 / 未知 code 的归入处 | 否 |

**只有这三条途径**，不为「事件 outcome 授予 / 战斗奖励 / Exchange 购买 / 置换所得 / 开局初始」预留成员。`Unknown` 是**迁移与读档校验的兜底**，不是一条真实渠道：读档遇缺失字段或无法识别的 code → `GD.PushWarning` + 归入 `Unknown`，不阻塞。**当前无线上账号，迁移成本为零。**

**⚠ 三值封闭带来一处需确认的冲突：** 三条全是**账号级**授予途径，而本 handoff 同时要求神通 / 法宝也带 `SourceCode`——**轮回级两类的常规来路在清单里无合法取值**，只能一律落 `Unknown`。见 Open questions。

**置换不改变来源：置换所得条目继承被换出条目的 `SourceCode`。** 目的是**关死「用置换刷回高掉率」的通道**——若置换产物记为新来源，换掉一条 `FinaleWin` 法则即使 `x` 下降、档位回跳。**推论：置换对 `x` 完全中性，08-09b 的「`x` 单调不减 ⇒ 档位只降不回跳」原样保住**；代价是来源记的是「这条能力最初从哪条途径进入账号」而非「上一次易手的方式」，这是有意的取舍。

**唯一消费点 = 残卷的概率计算。** `SourceCode` 存在的全部理由就是算出 `x`：**不对玩家可见**（法则列表 / 储物袋不标注来源）、**不进图鉴词条**、不参与任何其他判定。它因此是一个**纯规则字段**（严格同步 · 后端可复算）。

### 3 · 残卷的 `x` 收窄为「靠打拿到的法则数」（推翻 08-09b §6）

**`x` = 账号已拥有且 `SourceCode == Source.FinaleWin` 的 PlayerPower 数量。** 08-09b 的三张分档表（上限 `Cap(x)` / 基础概率 `Base(x)` / 累积增量 `Gain(x, chapter)`）**全部**改用这个口径——原文点的是「odds increase 与 upper limit」，而**两表本就是同一条闸门的两面**（适格 Finale ⟺ 该档 `Gain > 0`），故适格篇章闸门必须同步收窄，否则那条已定案的一致性被破坏。

- **分档自变量的含义由此反转：** 不再是「**拥有**得越多，后续越难再得」，而是「**靠渡劫拿**得越多，后续越难再从渡劫拿到」。
- **全局前置不变**：「尚未拥有的法则数 > 0」这条**仍按全部持有计**（池是否取尽与来源无关）。故存在一个合法状态——`x = 0` 但池已被礼包 / 成就取尽 ⇒ 整条线静默停摆。
- **`x` 单调不减仍然成立**：礼包 / 成就不推动 `x`，法则不被强制剥夺，**置换继承来源故对 `x` 中性** ⇒ 档位只降不回跳，08-09b 的这条推论原样保住。
- **不落字段这条不变**：`x` 仍是派生量（对 `List<PlayerPower>` 的一次带过滤计数），落字段即第二份真值。

### 4 · 与 premium bundle 的关系：完全解耦（08-09b §6 整条推翻）

| | 08-09b（作废） | 本次 |
|---|---|---|
| 礼包重置 `Accumulated` | 否 | **否**（不变） |
| 礼包使 `x` +1、可能压低上限 | **是（有意的负反馈）** | **否——礼包与残卷完全解耦** |

- **「获取渠道是打还是买不改变这条曲线」这句被推翻。** 现在渠道**确实**改变曲线，而这是本次有意为之：分档的用途是给**失败侧产出**一条递减曲线，把付费与成就奖励算进自变量，等于让玩家买到的东西反过来掐死自己的残卷线。
- **付费收益变为纯净收益，这是设计意图（已确认）。** 不再附带「下一条法则来得更慢」的代价，付费与元进程之间那条**有意的负反馈整条消失**；仍与「付费是增值而非必需」同向（礼包不改变失败侧的推进速度），而**礼包净强度较 08-09b 上升是被接受的**，平衡按此校准。
- **对成就奖励同理**：成就给的法则不压低残卷档位。**成就的两档奖励可以是法则 / 古宝——这是本次确立的新设计意图**（此前 `achievements/` 的奖励内容完全未定），奖励目录本身仍待设计。

### 5 · Finale「失败但存活」的叙事补白（答结 08-09b 的遗留待答）

- **落点 = `systems/services/plot-manager.md` 的叙事层**（不是 `ux/screen-flow.md`）。它与既定的「隐藏属性跨档定性叙事」是同一类东西——**一句由状态转换触发的定性文案**，走同一条落点（`ResolveOutcome` → `eventEnd` 阶段），不新增结构。
- **文案两版：**

  ```
  「劫败而身存，破境亦有缺。」
  「以败换境，以伤换生。」
  ```

- **择取规则 = 等概率随机二选一**，不按篇章 / 隐藏属性分化。
- **文案属内容层**（`res://content/` 基线 + overlay，可热更），**不随剧本服务下发**。这在 PlotManager 内部划出一条分界：**剧本正文**按 key points 向云端请求、不落存档不进 ContentRegistry；**由状态转换触发的定性文案**是内容条目（有稳定 `Id`、需启动期校验）。
- **推论：随机源不必带种子。** 二选一只影响呈现、不产生任何玩法结果，故不在「不用未加种子的随机决定玩法结果」的约束面内，也不占用 `SeedManager` 的子流。
- **承重的边界：这句补白讲的是「失败也能突破」，绝不能暗示道统残卷。** 08-09b §9 定的「失败侧不给任何文案 / 暗示 / 进度条 / 百分比」对残卷仍然成立——两条文案里没有任何一个字指向掉落概率，这是它们能落地的前提。

### 6 · 授予通道要带上来源

- **凡授予 power / item 的 `ChangeElement` 必须携带 `Source`**，不设默认值——省略即产生来源未知的条目，而 `x` 直接读这个字段。
- `ProfileManager` 的授予签名相应带上来源：`GrantPower(string powerId, Source source)`；item 侧的对应方法在其 API 面成形时同办。
- 残卷发放这一路取 `Source.FinaleWin`（即 08-09b 伪码里 `spec.Add(GrantPower, pickedPowerId)` 那一行）。

## 后果

- **`PlayerPower` / `PlayerItem` / `CharacterPower` / `CharacterItem` 四类持有条目各新增一个字段** ⇒ 存档 schema 版本 bump，迁移 = 老档补 `Unknown`（当前无线上账号，无实际迁移）。
- **`systems/balance.md` 的三张分档表数值不变，但自变量口径变了。** 同一玩家的新 `x` 恒 ≤ 旧 `x` ⇒ 档位只会更高（更宽松）。**阈值 3 / 5 / 9 / 12 / 15 是按旧口径（总持有）给的初值，改口径后整体偏松**——这是一条留给实测的复核提示，不是待答项：若上线后残卷掉率偏高，调整方向是**下调阈值**，表结构不变。
- **`monetization.md` 的「随机 PlayerPower 与道统残卷的交互」整条改写**；`07-codex-monetization.md` 里那条「交互已答结」的措辞跟改。
- **`Source` 是一条会被后端读到的字段**（profile 上行负载的一部分、且 `x` 是后端可复算掷骰的输入）⇒ code 的稳定性纪律同时是一条客户端 ↔ 后端契约。
- **`06-meta-progression.md` 少一条待答**（1% 存活分支的叙事补白落点）。

## 与既有决策的张力

**① 推翻 08-09b §6（礼包压低上限）。** 已在 §4 明写为有意的口径反转，`player-power/_index.md`、`monetization.md`、`terminology.md`、`balance.md` 四处的相应措辞已改写，不留旧表述。

**② 08-09b「`x` 单调不减 ⇒ 档位只降不回跳」原样保住**，但保住它的理由换了一条：旧口径靠「法则不被强制剥夺、置换是等价交换」，新口径下还需要**置换继承来源**这一条——否则换掉一条 `FinaleWin` 法则即可压低 `x`、刷回高掉率。该缺口已在本次同时补上。

**③ 与「失败侧彻底隐含」不冲突。** §5 的补白文案是「失败但存活仍突破」的叙事，与残卷无关，已明写边界。

其余无张力：残卷的三个时刻、RNG 形态、幂等键、字段落点、首胜 100% 规则均原样成立。

## Open questions

- **⚠ `Source` 三值封闭清单与轮回级两类的取值冲突（唯一剩余项 · 待用户确认）。** 封闭三值全是**账号级**授予途径，而本 handoff 要求**神通 / 法宝**也带 `SourceCode`；它们的常规来路（事件 outcome / 战斗奖励 / Exchange 购买 / 开局初始持有）**在清单里没有合法取值**，只能一律落 `Unknown`，字段在轮回级两类上不承载信息。收口两选：
  - ① **把 `SourceCode` 收窄到账号级两类**（法则 PlayerPower / 古宝 PlayerItem），轮回级不带此字段。**倾向此项**——唯一消费点是残卷的 `x`、而 `x` 只数法则，一个恒为兜底值的存档字段不该存在。
  - ② **四类照带**，轮回级恒为 `Unknown`，作为日后扩清单的占位。

  原始意图明写「character or player's power and item」四类都带，故不自行收窄。→ `systems/common-properties.md`、`systems/character-profile/`。

## Notes / triage

来源：`inbox/draft-0810b.md`（手写草稿，四条）+ 同 session 用户对六个待确认项的逐条裁定。原文 `archievementReward` 为 `AchievementReward` 的笔误，已订正。同批的 `inbox/draft-0810a.md`（「本轮回禁用」与置换型剥夺专场）**尚未处理**，仍留在收件箱顶层。

# Answer log element-carrier-gaps

- 日期：2026-08-17
- 来源：`inbox/solution-draft-element-carrier-gaps.md` → `handoffs/2026-08-17g-element-carrier-gaps.md`
- 移出条数：4

**`ResourceElements` 是否增一列 `ApplyOp { Add, Set }`** → 原建议形态（表里逐行配一个单值）被推翻：`Op` **逐条带在 `ChangeElement` 上**（第三字段，缺省 `Add`），表里增的是一列 **`ApplyOps AllowedOps`**（`[Flags]`）。理由：`PowerFragmentAccumulated` 在同一个 key 上真的需要两种（每次 Finale 累加、发放法则后重置为 `Base(x+1)`），逐行单值表达不了。三条连带规则：`Set` 恒不经 modifier pipeline · 含 `Set` 的行两个修正列恒为 `null`（启动期断言）· `Op ∉ AllowedOps` → `PushError` + 整批拒绝；另明写 `Set` 不参与 `CanAfford`。（`systems/architecture.md`、`systems/services/profile-service.md`）

**游离散牌入组的 element 载体** → `DeckChangeOp` 增第五值 **`AddLooseCard`**：`Id` = 卡牌 `Id`、`Tier = -1`、零字段增量、不设 count（同名多张 = 多条 element）、目标已在卡组则正常追加一张（不是空操作）、不带 `Source`、新增 `Pool == Enemy → PushError + 整批拒绝` 一道闸。三条通道（事件负向奖励塞业障 / 战斗奖励单卡入组 / 商店 `Card` 族购买）就此落地。（`systems/character-profile/deck/_index.md`、`systems/services/profile-service.md`、`systems/adventure-event/exchange/_index.md` 与 `common-properties.md`）

**`plotKeyPoint` 的 element 形态** → `ProfileChangeSpec` 增列 **`PlotElements`**，条目类型 **`PlotKeyPointAssignment`**（`PlotKeyPoint` 的镜像，按 `ArcId` 整条 upsert、零 `Op`、恒不经 pipeline、`SelectCost` 内恒空），并新增八行写严的施加侧失败语义；拓扑校验留在 PlotManager 的 `#if DEBUG` 断言。连带：`PlotArcState` 登记进共享核心类型的枚举清单。（`systems/architecture.md`、`systems/services/profile-service.md`、`systems/services/plot-manager.md`、`systems/character-profile/_index.md`）

**道心 `Faith` / 煞气 `Bloodlust` 是否列入 `CostKey`** → **列入**，与 `Experience` 同批登记为 `CostKey` 成员。`ResourceElements` 三行：`Experience → (0, null, null, null, null, Add)` · `Faith` / `Bloodlust → (0, 100, null, null, null, Add)`；两个修正列留空——一条法则能伪造隐藏属性，即等于伪造整条剧本线的触发条件。（`systems/architecture.md`、`systems/services/profile-service.md`）

**部分答定的说明：** `PowerFragmentFirstWin(chapter)` 的参数化 `CostKey` 形态、`BundleGrantOrdinal` 由谁施加两项仍留在待答清单；本次只定了它们各自那一行的 `AllowedOps` 取值形态。

# S4 报告 — element 层三缺口

> worker 的报告文件写入被 harness 拦截，内容由 orchestrator 代为落盘（原文照录）。
> 草稿文件本身已由 worker 成功写入。

- library: `game-design-documents`（客户端库，单库）。本分片**不横跨后端边界**——三条缺口全在客户端进程内的 `ProfileChangeSpec` 类型面上，无报文、无后端义务，故**不在对侧库落配套草稿**。

## 草稿文件

`game-design-documents/inbox/solution-draft-element-carrier-gaps.md`（`status: awaiting-review`，含 5 项待裁决取向）

未写任何共享台账、主题文档、ADR、handoff、`open-questions*`、代码。

## inbox/_index.md 待处理表应追加的行

⚠ 实际表头是 `文件 | status | 说明`（三列），**不是**技能正文写的五列形态。当前该表是 `| *（空）* | | |` 占位行，用本行替换：

```markdown
| `solution-draft-element-carrier-gaps.md` | awaiting-review | element 层三缺口（`Elements` 的 Add/Set · 游离散牌入组 `Op` · `plotKeyPoint` 载体）；先给统一分列判据再逐条落形态。评审 5 项取向后 `/analyze-new-ideas` |
```

## 依据构成

- `[既有推演]` **7** 项（统一三级判据 · `Op` 逐条带 · `AllowedOps` 配表 · `Set` 不经 pipeline · `AddLooseCard` · `Pool != Enemy` 闸 · `PlotElements` 分列与零 `Op`）
- `[通行做法]` **0** 项——三条缺口全部由本库既有先例闭合，无需外部实践支撑（这本身是个结论：本库 element 分层已成熟到可自洽推演）
- `[取向选择]` **5** 项

## 建议要点（逐条对应三个缺口）

**先给统一判据（草稿的承重部分）。** 把五处既有先例归纳为自上而下三问，建议写进 `systems/architecture.md`「共享核心类型」，作为日后所有 element 形态问题的答法：
① **分列** ⟺ 施加语义在六个面（钳制 / pipeline / 失败是否阻断 / 幂等 / 量纲 / 键与载荷形状）上与既有各列**根本不同**；② **同列加 `Op`** ⟺ 语义同族（共用配表、校验链、钳制与失败语义）但动作方向或形式不同；③ **配表加一列** ⟺ 该性质是 **element 类型的属性**。**反判据：** 同一 key 不同次变更可能不同 ⇒ 必须逐条带；**唯一恒定例外 = 「谁有权改写它」永远配表**（`ModifierKey?` 被否决的那条理由）。三条缺口按此分别落在 **②+③ / ② / ①**——三个不同形状，出自同一条判据。

**缺口 ① `ApplyOp`（推翻原待答项的建议形态）。** 原问建议「在表中增一列逐行配」，但 `PowerFragmentAccumulated` **同一个 key 上真的需要两种**：每次 Finale 累加 `x`、发放法则后**重置为 `Base(x+1)`**（`answer-logs/log-legacy-fragment-chance.md`）。逐行单值表达不了 ⇒ **`Op` 必须逐条带**。写成 `Add` 的负值同样不行（要读当前值算差，`AppliedChange` 的直接重放当场失效——与 `Tier` 取目标层数、`StatusAssignment` 取绝对值同一条纪律的第三次应用）。形态 = `ChangeElement(CostKey, int, ApplyOp)` + `ElementSpec` 增第六列 `ApplyOps AllowedOps`（`[Flags]`）。三条连带规则缺一即漏：**`Set` 恒不经 pipeline**（`Set` 下符号不表达方向，「按符号分向」无从判断）· **含 `Set` 的行两个修正列须恒为 `null`**（启动期断言）· **`Op` 不在 `AllowedOps` 内 → `PushError` + 整批拒绝**。附首批四行 + 四个待登记 key 的逐行取值表（`ManaLimit` 恒不开 `Set`：一条 `Set` 即可跳档，直接推翻「单次变动幅度恒为 1」）。另明写：**`Set` 不参与 `CanAfford`**。

**缺口 ② `DeckChangeOp` 增第五值 `AddLooseCard`。** 与 `RemoveLooseCard` 六面同族、方向相反 ⇒ 加 `Op`，**`DeckChangeElement` 零字段增量**（`Id` = 卡牌 `Id`，`Tier = -1`）。「同名多张」由既有纪律直接回答：**提交多条 element、不设 count**。必须明写：**目标已在卡组 → 正常追加一张，不是空操作**（套用 `LearnTechnique` 那一行会静默吞掉第二张，正是原问点出的风险）。新增一道闸 `Pool == Enemy → PushError + 整批拒绝`（既定校验只管取池侧，element 层是敌方专用牌进玩家卡组前的最后一道闸）。`exchange/common-properties.md` 商品族表「⟨待定⟩」一格填为 `AddLooseCard`。`DeckElements` 在 `SelectCost` 内恒空不变（业障入组是 outcome 侧负向奖励，不是成本）。

**缺口 ③ 新增第六列 `PlotElements`（`PlotKeyPointAssignment` 列表）。** 前两面（键与载荷形状 = **带载荷的键值 upsert** · 幂等 = 按 `ArcId` **整条替换**）与现有五列全部不同 ⇒ 真的要分列。形态 = `PlotKeyPoint` record 的镜像，语义「已算好的绝对状态」（PlotManager 算，ProfileManager 只 upsert、**不认识剧本图**）。**零 `Op`**——既定「保留惰性条目而非删除」+ 四态由 `State` 表达 ⇒ 无 `Remove` 向。恒不经 pipeline、`SelectCost` 内恒空、五行写严的失败语义 + 一条可追溯性日志。**写严读宽的不对称明写理由**（施加侧悬空 = 组装缺陷，此刻拒绝救得回来；读档侧悬空 = overlay / 版本回退，拒绝等于让一次内容更新废掉玩家轮回），先例是 `(Kind, Scope, Source)` 合法子集表。

**存档面：** 三条合起来 **bump schema 版本一次**（`AppliedChange` 形状变；当前无线上存档 ⇒ 空迁移）。**Profile 字段一个不增减**——全在变更规格（spec）一侧。

## 仍需用户决定（5 项）

1. **`Set` 落「同列带 `Op`」还是「新开一列 `ResourceAssignments`」（承重 · 最需点头）。** A（**推荐**）`ChangeElement` 增 `Op` + 表增 `AllowedOps`——一列覆盖加与赋、同一 `CostKey` 全部语义留在同一行；代价 = 资源列上第一次出现「逐条带一个决定施加方式的字段」。B `Elements` 保持纯加法、另开 `ResourceAssignments(CostKey, int)`——`ChangeElement` 一字不改；代价 = `PowerFragmentAccumulated` 在两列各出现一次、两列共用同一张表却各走一条校验链，正是本库明写要避免的「分表必然漏行」的另一形态。理由：判据 ① 在此不成立（`Add`/`Set` 共用钳制、取值域、终态判定、失败语义），既有两列都已用 `Op` 表达同族内不同动作；B 会让分列判据从「按施加语义」滑向「按施加动作」。
2. **`ApplyOp` 现在就落还是与 `CostKey` 清单同批。** A（**推荐**）现在落结构、逐行取值随成员登记补齐——`BundleGrantOrdinal` 的置值语义**今天已在 `monetization.md` 写定并被三道闸依赖**、类型层却表达不出来，是一处活着的「散文与类型不一致」；结构本身不依赖清单。B 整条推迟。
3. **散牌增向定名。** A（**推荐**）`AddLooseCard`（与 `RemoveLooseCard` 严格对称）· B `GainLooseCard`（"Gain" 与「塞业障」相左）· C `AcquireLooseCard`（与既有四个短动词风格不齐）。
4. **第六列列名 / 类型名。** A（**推荐**）`PlotElements` + `PlotKeyPointAssignment`（列名同 `DeckElements`；类型名沿用 `StatusAssignment` 的「置值」词根）· B `PlotKeyPoints` + `PlotKeyPointChange`（`Change` 在本库已被用于「带 `Op` 的变更」，本条无 `Op`）。
5. **「单步推进」的拓扑校验落哪一侧。** A（**推荐**）`ProfileManager` 只校验 `Id` 可解析 / 不串线 / 同批不重复，拓扑由 **PlotManager `#if DEBUG` 断言**（唯一写入面不持有剧本图知识，符合纪律可执行化阶梯第 3 级；代价 = Release 下越级推进不被拦，但只能由唯一组装方自身缺陷产生）· B `ProfileManager` 读出边强校验（拦得住，但唯一写入面开始认识剧本图拓扑，与既定分层相左 + 每次 upsert 多一次图查询）。

## 与既有决策的张力

1. **「修正与否是 element 类型的属性，不是单次变更的属性」vs 逐条带 `Op`。** 表面同类，实质两回事：`Op` = 这一次发生了什么（事实，逐次不同，归反判据）；`ModifierKey` = 谁有权改写它（纪律，恒定）。方案用 `AllowedOps` 把纪律仍留在表里 ⇒ 「不把纪律降级为调用方选项」**未松动**。不接受这条区分 ⇒ 唯一自洽替代是取向 1 的选项 B。
2. **「按符号分向」在 `Set` 下无定义。** 不是松动，而是**补一条互补规则**（`Set` 恒不经 pipeline + 断言把两个修正列锁为 `null`），把分向的适用域限定在 `Add`。
3. **`ProfileChangeSpec` 涨到六列。** 与「列表数不进承重表述」相容（该纪律正是为此写的），但代价明写：每加一列，校验链 / `AppliedChange` 序列化 / diff 面各加一段。
4. **`AddLooseCard` 不带 `Source`。** 沿用整列既定形态、不破例；代价 = 「这张业障哪来的」在卡组侧查不出，只能从 `PastEventEntry.AppliedChange` 逆查。

## 前置依赖

- **`CostKey` 资源族完整清单**（承重待决，另案）：`AllowedOps` 后四行取值随各 key 登记生效；**表结构与三条连带规则不依赖它**，可先落。
- **`PowerFragmentFirstWin(chapter)` 的 key 形态未定**（参数化 key 如何进 `CostKey`）——那一行的 `AllowedOps = Set` 待形态定后才落。
- **`Faith` / `MaleficQi` 是否列入 `CostKey`**（不在本批）：若列入需一并裁 `AllowedOps`；草稿只给一句「届时建议 `Add`」，**不预设**。
- **`plotKeyPoint` 内容侧逐条映射**归 ch1 / plot 专场，与载体形态无关。

## 与 S1 的交界（对 Profile 字段做了哪些假设）

只改 spec 一侧，**未自行决定任何 Profile 字段形状**。三处形状须与 S1 的 schema 一致（已在草稿 `## 前置依赖` 标 ⚠）：

1. **`PlotKeyPointAssignment` 是 `PlotKeyPoint` record 的镜像。** S1 若增删该 record 字段 / 改名 / 改 `PlotArcState` 值域 ⇒ `PlotElements` 载荷须同步。
2. **`AddLooseCard` 假定游离散牌是「卡牌 `Id` 的多重集」**（`deck/_index.md` 推论 ③）。S1 若改为带附加运行态的结构 ⇒ 需第二个载荷字段。
3. **`ApplyOp = Set` 假定 `PowerFragmentAccumulated` / `BundleGrantOrdinal` 是可整体赋值的标量字段**（`PlayerPowerFragment.Accumulated` / `PlayerEntitlement.BundleGrantOrdinal`）。

## 越界发现

1. **`inbox/_index.md` 实际表头与技能正文不符。** 技能第 6b 步写五列 `文件 | 类型 | 日期 | 主题 | 下一步`，实际是三列 `文件 | status | 说明`，且该文件另定了 `solution-draft` 的 front-matter `status` 生命周期（`awaiting-review → reviewed / decided → distilled`）。建议 orchestrator 按实际表头落笔并把不一致记入总报告。
2. **`deck/_index.md` 第 20 / 27–28 / 33 行有孤立的 `-` 空列表项**（编辑残留）。未改。
3. **`profile-service.md` 第 36 行写「累加 / 置值」，`ResourceElements` 表第 89 行依据列只写「万分比累计」**——同一 key 的置值向在表侧无痕；`AllowedOps` 一列正好使它显形，提炼时两处措辞宜同改（已列入 targets）。
4. **`exchange/_index.md` 第 19 行「一笔交易的 spec 形状」采纳后须同改**（`ChangeElement(Jade, -ListPrice)` 增第三实参 `Add`；`Card` 族补 `AddLooseCard`）。已列 targets，未自行改动。
5. **潜在批内交叉点（提请核对）：** 若同批有 worker 触碰 `ProfileChangeSpec` / `ResourceElements` / `architecture.md`「共享核心类型」，其结论须与本草稿的三处类型改动（`ChangeElement` 增第三字段 · `ElementSpec` 增第六列 · `ProfileChangeSpec` 增第六列）对齐——这三处在同一段代码块内。

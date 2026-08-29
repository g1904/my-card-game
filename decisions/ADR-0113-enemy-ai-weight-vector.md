# ADR-0113 — 敌人定制 AI 策略 = 权重向量的重新加权：只给权重不给代码，全流程零随机零记忆

- **状态：** Accepted
- **日期：** 2026-08-26
- **来源：** handoffs/2026-08-26c-enemy-ai-strategy-shape.md · handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md

## 背景

`ADR-0092` 已把敌人 AI 的归属与约束定死（两层结构 · 可空即回落兜底 · 只表达打法风格 · 决策是纯函数 · 输入面限对称可见信息），但形态列只写着「表达形态待定」。字段类型写不出 ⇒ `systems/enemies/` 无法 derive，连带具体算法、决策粒度、多回合倾向、兜底与定制的强弱差口径四项同样悬着。

## 决策

**定制策略 = `EnemyAiProfileData`**：一条独立可复用 `Resource`，`EnemyData.AiProfile` 是对它的直接类型引用（可空 = 走通用兜底）；profile **只列它要覆写的 `AiWeight{Term, Value}`**，未列项取兜底默认值；不挂 `Rarity`；`Id` 形态 `enemy_ai.<snake_case_slug>`；**profile 内无第二类结构位**。

**兜底算法 = 单层（1-ply）加权效用评分 + 确定性 argmax**，`score(EndTurn) ≡ 0` 为绝对零点；决策粒度逐张、每次重算候选集；**1-ply 试算不展开连锁——这是规则，不是实现细节**。

**全流程零随机、零记忆**：平手取确定性字典序，一切倾向写成局面函数，`ActiveCombat` 一格不加，`ChooseAction` 是 `static` 纯函数。

**强弱差 = 三条结构性上界**（只给权重不给代码 · 深度恒 1-ply · `Value` 钳在 `[AiWeightMin, AiWeightMax]`，越界 `PushError` + 抛），不另加带数字的胜率口径。

**`AiWeightVector` 是加载期的展开产物，不是内容形态**：内容侧写稀疏的 `CombatRulesData.AiFallbackWeights`，ContentRegistry 在 `LoadAll()` 内一次性展开为定长向量、落派生索引、不写回条目、不落 `.tres` / 存档 / 上行。有效权重合并语义只写一处：`w_k = profile 列了 term_k ? 该条 Value : fallback[term_k]`。

**读取面 = `CombatSnapshot` 双视角化（`ViewerSide`）**，AI 与 UI 共用同一投影、不新增 `AiCombatView`。

类定义、`AiTerm` 十项、五条加载期校验 → `systems/enemies/_index.md`、`systems/enemies/common-properties.md`；兜底默认向量与取值域 → `systems/balance.md`；profile 逐条取值 → `content/enemy-ai/<id>.md`。

## 理由

**独立资源而非内联，判据是「是否需跨条目复用」：** 需要，且是常态——定制策略表达的是**打法风格原型**（守势 / 抢攻 / 消耗 / 埋伏），一种风格天然被一批敌人共享；内联意味着「把守势打法调一档」要逐个敌人条目改一遍，漏一个即得到一条半改的风格。反面判据同样成立：`PoolScope` / `TechniqueRef` 取内联，正因为它们逐条目独有。

**只列要覆写的项**：兜底调参自动惠及全部 profile，且 profile 文件短到一眼能读出「这个敌人偏在哪」。**无第二类结构位**：多开一格结构就是多开一条与权重并行的表达通道，此后每条策略都要回答「这件事该写在哪一格」。

**逐张决策是必然而非偏好**：栈结算会改变局面（连锁触发、道念被下限 0 截断、条目落场 / 离场），一次性规划出的第 2、3 个动作在执行到时的合法性与价值都可能已经变了。

**1-ply 写成规则**：不写成规则，日后有人顺手加一层，「定制不强于兜底」的上界当场失效。

**取值域越界取 `PushError` + 抛**：一条写成 `Value = 999` 的 profile **能上线且线上不可见**，按 `ADR-0013` 的选级判据正是必须做到第 1 / 2 级的那一档。

**推论：定制策略「不强于兜底」在结构上已近乎自动成立**——它是兜底在同一搜索空间内的一次重新加权。

## 备选方案

- **把定制策略内联进 `EnemyData`** — 否决：风格需跨条目复用，内联会产出半改的风格。
- **profile 内另开一格结构位表达偏好** — 否决：制造与权重并行的第二条表达通道。
- **新增 `AiCombatView` 作为 AI 专用读取面** — 否决：与「读侧统一读 `CombatSnapshot`」正面打架，且两份视图必然漂移。
- **AI 引入随机化** — 否决：全确定性使 AI 与 `combat` 子流形态完全解耦，可确定性重放。
- **另加带数字的胜率口径（如「定制不超过兜底胜率 N%」）** — 否决：该数字在量纲基准与 starter deck 成型之前无法测量，此刻写下即是一条无人执行的第 4 级条款。
- **把 `AiWeightVector` 的展开挪到评分时逐项查表** — 未取：同一决定的实现位移，热路径上多一次分支；加载期一次展开落在零分配纪律内。

## 后果

- `systems/enemies/_index.md` 是形态与算法的权威；`systems/services/combat-service.md` 承载 `ChooseAction` / `CombatSnapshot` / `AiWeightVector` 的 API 面。
- `ADR-0092` 本体不改——本条只给它的软约束补上三条结构性上界，并把「表达形态待定」落实。
- 三层分工写死：`systems/enemies/*` 只写类定义与形态 · `systems/balance.md` 只写兜底默认向量与取值域 · `content/enemy-ai/` 只写「填了什么值」。
- **兜底权重的数字初值待校准**，被「卡牌产 / 削道念的量纲基准」阻塞，随首批 starter deck 一并校准——结构可定，数字待定。
- `content/enemy-ai/` 尚未开张，开张动作归 `/scaffold-content-type enemy-ai`。

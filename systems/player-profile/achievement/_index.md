# achievement

> 成就 / **Achievement** —— 账号级、分组的成就与其两档一次性奖励。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **Achievement = 账号级成就，独立于任何单次轮回。** 由 PlayerProfile 持有（字段 `achievement: List<Achievement>`），跨轮回持久，随账号存于云端权威主档。
- **标识符恒单数。** 元素类型 `Achievement`、集合字段 `achievement`，与 `PlayerPower` / `PlayerItem` / `CharacterItem` 同族——**类型名恒为单数，复数只属于集合字段名**。成就没有「储物袋」那样的已定名容器概念可供字段借名，故字段沿用单数风格（`pastEvent` / `disabledAbility`）。**集合字段名恒为单数是全库通则**（跨边界，见 `../_index.md`），本字段合规、不是例外。**这是纯标识符收口，分组结构与两档奖励语义零改动。**
- **两档奖励可以是法则 / 古宝。** 成就奖励是 `Source` 的一个成员（`AchievementReward`），与道统残卷、premium bundle 并列为**账号级内容的第三条授予途径**。**已定的边界：成就所得的法则不计入残卷的分档自变量 `x`**（`x` 只数 `SourceCode == FinaleWin` 的法则），故成就奖励**不压低残卷掉率**——与礼包同款处理。授予时须带 `Source.AchievementReward`（授予 element 强制携带来源，见 `systems/common-properties.md`）。**奖励目录本身仍未设计**，见待决问题。
- **奖励形态 = 指定条目 + 成就限定，不进任何抽取池（承重）。** 成就奖励**不走**残卷 / 礼包 / 置换共用的那段抽取（见 `../player-power/_index.md`）：每条成就奖励**指定**具体条目 `Id`；且这些条目是**成就限定**的——**除该成就外没有任何其他获取途径**（不进残卷池、不进礼包池、不进置换的**换入**侧）。
  - **「成就限定」的目的是保证成就奖励恒不落空。** 若成就指定的条目同时躺在通用池里，玩家完全可能在达成成就之前就从残卷 / 礼包 / 置换拿到它；等成就达成时，`spec` 里那条 `Grant` 指向一个**已持有**的条目——按既定的排重语义（池 = 未持有集合），这一发就是空的。**成就是一次性的确定回报，没有第二次机会补发**，所以这条不能靠概率侥幸，必须由准入规则从结构上排除。
  - **由此得到一条不变式：成就限定条目在其成就发放的那一刻，玩家必然尚未持有。** 它是可断言的——发放时若目标条目已在持有集合 → `PushError`（说明限定被破坏，或该成就被重复发放，两者都是缺陷）。**这条断言正是「不落空」从口头保证变成机械保证的那一步。**
  - **承载形态 = 内容定义上的可空共有字段 `ExclusiveSource: Source?`**（默认 `null` = 通用；成就限定条目填 `Source.AchievementReward`）。它与 `SourceCode` 名字相近、方向相反（准入 vs 记账），并排对照表见 `systems/common-properties.md`。选 `Source?` 而非新开一个布尔，是因为同一诉求日后必然重演（活动限定、剧情限定）。
  - **三条校验，合起来才等于「不落空」（全部 `PushError`）：** 加载期——每条成就奖励指定的 `Id` **存在**（走既有交叉引用校验），漏掉则发放时授予一个不存在的条目；加载期——该条目 **`ExclusiveSource == Source.AchievementReward`**，漏掉则条目仍在通用池里、可被提前拿到、空发；发放时——目标条目**不在**玩家持有集合中（上述不变式的断言），漏掉则空发已经发生、只是没人看见。
  - **两条推论：** ① **账号级 RNG 的 `AccountStream` 不需要 `AchievementReward` 成员**——无随机 ⇒ 无掷骰 ⇒ 无序号；授予路径退化为「读成就配置的 `Id` → `spec.Add(GrantPower, id, Source.AchievementReward)`」，比抽取路径短得多。② **置换的两侧不对称：换入侧永不出现成就限定条目；换出侧不禁止**——玩家自愿把成就条目换掉是既定三形态表里的正向决策，且「置换所得继承 `SourceCode`」原样成立。**不落空管的是发放那一刻，不是此后玩家自己的取舍。**
  - **指定条目被 `ContentEnabled = false` 关闭时照常发放**——读取侧 `Get(id)` 不过滤是既定语义，且成就奖励是承诺给玩家的确定回报，不该被放量开关吞掉；`ContentEnabled` 对成就限定条目实际影响不到任何抽取池（它本就不在池里），故关它没有意义，可在内容评审口径里提一句。
  - **⚠ 内容侧编排纪律：每条成就奖励都需要一个专属条目**，成就目录与内容目录由此**一一对应地一起增长**——内容侧应正视这条工作量。
  - **否决的替代：** 成就奖励也走随机抽取（成就是**确定性的里程碑回报**，随机会让「达成同一个成就却拿到不同东西」，与里程碑语义相悖；指定条目还让成就设计能与奖励内容互相呼应）；成就指定通用条目 + 「已持有则改发别的」兜底（那正是「落空」的另一种形态——玩家拿到的不是成就设计好的那件东西，且要为它设计一套替补规则；准入侧一刀切断则零运行时分支）。
  - **本条只定「怎么给」，不定「给哪些条目」**——后者仍见待决问题。
- **分组 + 两档一次性奖励。** 成就按类别分组；每组按**组内加权进度**分两档一次性奖励：达 **60%** 发一次、达 **90%** 再发一次，两档奖励不同。**目录 80% 条目可见、20% 为隐藏成就**（达成后才显示）。玩家只能查看进度 / 领取奖励。详见 `ux/screen-flow.md`。
- **服务归属：profile-service 的 AchievementManager。** 成就进度采集与奖励发放归 `systems/services/profile-service.md`；写入仍经 ProfileManager 单点提交。
- **本子系统成文件夹。** 与 `player-item/` / `player-power/` 并列成文件夹（有子结构）；`account-info` / `game-setting` 结构轻，各为独立 markdown。

> 具体的成就条目字段、进度模型等共有属性见 `common-properties.md`。

Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` · `handoffs/2026-08-12c-identifier-singular-collapse.md` · `handoffs/2026-08-12e-ability-grant-draw-pool.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **奖励目录未定：** 阈值（60% / 90%）、一次性、80/20 可见比例已定；**「能给什么」已答结——法则 / 古宝**；**「怎么给」也已答结——指定条目 + 成就限定，不抽取**（见「意图」，故「抽取是否走 `AllEnabled()` 池 / 是否排除已拥有」这一问随之消解）。仍待定：**具体奖励条目清单**、两档各给什么、是否还有其他形态的账号级奖励。→ `ux/screen-flow.md`、`systems/player-profile/player-power/`。
- **AchievementManager 的触发采集面未定：** 成就进度靠订阅 EventBus 被动采集（解耦但易漏）还是各服务主动上报（可靠但反向依赖）？→ `systems/services/profile-service.md`。
- **成就条目 schema 与进度模型未定：** 分组结构、加权进度的权重来源、条目触发条件、隐藏成就的揭示时机均未设计。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/achievement/`（待建）。

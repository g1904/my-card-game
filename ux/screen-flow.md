# screen-flow

> 屏幕流程:菜单 -> 轮回 -> 地图 -> 战斗 -> shop -> 设置。

## 意图

完整前置流程:**登录屏 → 主菜单 → (切换篇章) → 轮回**。

- **登录屏(应用首屏)。** 含**服务条款(T&S)**;背景是一段 **live2d 风格循环动画视频**(氛围演出,美术 TBA,先留空占位)。登录入口用于**在线存档**:**微信 / QQ / 邮箱 / 手机号**。**强制账号登录——已移除游客(Guest)入口**,不再支持不登录直接进入。Source: `handoffs/2026-07-16-ux-flow-login-and-dev-order.md`;去游客 `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **主菜单(登录后)。** 核心操作是**切换篇章以开始一次轮回**——在**已解锁**篇章中择一作为该次轮回的起始篇章。首玩者**只能从炼气(第一篇章)开始**,其余篇章选项**隐藏**,后续解锁后才出现(门禁细节见 `onboarding.md`)。
- **主菜单入口按钮**(各自是 PlayerProfile 数据模型的视图层,对应 `systems/services/life-cycle-service.md` 的账号级字段):

  | 按钮 | 内容 | 对应 PlayerProfile 字段 |
  |------|------|------------------------|
  | PlayerProfile(玩家档案) | 状态与账号信息(`AccountInfo`) | `AccountInfo` |
  | PlayerPower(法则) | always-available 能力,带**开关(默认开启)**;QoL 或影响公平性的全局加强,不与角色绑定 | `List<PlayerPower>` |
  | Achievements(成就) | 分组成就;玩家**只能查看进度 / 领取奖励**;奖励按**组内加权进度**发放,分 **60% / 90% 两档一次性奖励**(见下) | `List<Achievements>` |
  | Settings(设置) | 音量等常规系统设置;**外加一行只读的「同步版本 #N」**(见下) | `GameSetting` |

  Source(能力 / 成就语义、加权发放):`handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。

- **成就发放细化(已定案)。** 每个类别按**组内加权进度**分**两档一次性奖励**:加权进度达 **60%** 发一次、达 **90%** 再发一次;**两档奖励不同,且都为一次性**。**成就目录 80% 条目可见、20% 为隐藏成就**,达成后才显示。(发放**何种**奖励 —— PlayerPower / PlayerItem / 账号级 —— 仍待定。)Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **登录渠道优先级。** 移动端优先(手机 / 邮箱)→ 微信 / QQ 其次 → 海外 / 跨平台最后。**已移除游客**入口。Source: `handoffs/2026-07-22-...`;去游客 `handoffs/2026-07-23-...`。
- **登录屏循环视频 = `VideoStreamPlayer`(已定)。** 用 `VideoStreamPlayer` 实现循环视频背景。Source: 同上。
- **元婴界面 = 终局展示面(通关证书)(已定案)。** 抵达元婴 = 第三篇章通关 = 游戏终点;此时呈现一块**类似「通关证书」的终局界面**。它正是**寿元 +500 这次最终数值更新的读者**——该界面需读到最终寿元值并正确显示,因此终点处的寿元更新不是死写入(见 `systems/balance.md`)。界面的具体字段与形态待定,见待解问题。Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **寿元告警 = 两段式(已定案 · 取代「只有 10% 红字」)。** 寿元(lifeSpan)初始隐藏,随余量下降分两段升级告警:

  | 余量 | 呈现 | 给玩家什么 |
  |------|------|-----------|
  | 100% ~ 30% | 无 | 数值完全隐藏 |
  | **进入 30%** | **一条定性的叙事提示**(不给数字),例:「鬓角新添的白发,你已数不清是第几根。」 | **可行动的提前量**,不破坏数值隐藏 |
  | **进入 10%** | **标红的数值倒数**(red count-down numeral)——递减的红色数字传达紧迫感,**而非常驻进度条** | 精确余量,最后阶段的硬告警 |

  **为何加 30% 这一段:** 对第一篇章 100 点的预算而言,10% 才告警**太晚,来不及做战略调整**。30% 的定性提示复用隐藏属性的**跨档叙事**机制(见 `systems/services/plot-manager.md`),寿元只是其中一个属性。Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **EventOption 选择界面上有一条常驻的角色状态条(已定案)。** 寿元告警的静态标注就落在这里,本次把它明确化为一条**角色状态条 + 一行进度 / 入口**:

  ```
  ┌─────────────────────────────────────┐
  │ [安全区]                             │
  │ 炼气七层 · ❤10 · ✦5/5 · 灵玉 120     │  ← 角色状态条（含寿元告警的静态标注）
  │ ▓▓▓▓▓▓▓░░░ 经验 5/7   [袋]37 [卡组]  │  ← 经验条 + 储物袋 + 卡组入口
  ├─────────────────────────────────────┤
  │  ← ← ←   eventOptions 横向滑动选择区  │
  └─────────────────────────────────────┘
  ```

  - **经验条常驻(承重)**:显示 `当前 / 本级阈值`。它在 ch1 是锦上添花,**在 ch2 · ch3 是唯一的连续进度感来源**——那两章每 9–11 个事件才升一级,中段会出现连续十几分钟毫无等级反馈;玩家读到「还差 12 点到筑基中期」,就有了跨越十来个事件的中期目标。**这同时是「中长期规划感的来源」那条长期待答的一个答复**(时间那一半;地理那一半由 `LocationCodex` 承担)。**与寿元隐藏纪律不冲突——经验从未被定为隐藏属性**,它是明面的成长量。
  - **配套纪律:eventOption 卡片上不标注该事件的经验产出档位**(与「给方向不给数字、不可电子表格化优化」一致)。**玩家看得到自己的进度,看不到单个事件的标价。** 已知风险:新手可能困惑「怎样才能升级」——**若实测确有困惑,「标档位不给数字」是预留的退让位**(属实测调整,不是重新裁决)。
  Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **储物袋不进主菜单,它是轮回内的角色面板(已定案)。** 主菜单入口全是 **PlayerProfile 级**,而储物袋持有的 `List<CharacterItems>` 是 **CharacterProfile 级、随轮回清理**——入口因此挂在**角色状态条**上(点按「袋」图标)。
  - **形态 = 全屏面板**(不是抽屉:元进程界面空间充裕,且 99 项需要纵深)· **纵向滚动网格,不分页**(窄屏 4 列、平板 6 列,由 `GridContainer` 的 `columns` 随宽度调整;分页在触控上多一次操作、需要页码控件,且「第几页」对无位置语义的道具毫无意义;99 项 = 约 25 行,滚动完全可接受)。
  - **筛选 = 顶部一排 chip(单选)**:`全部` / `战斗可用` / `战斗外` / `已耗尽` —— 全部基于既有字段(前三项读 `UsableScene`,末项读 `Charges == 0`),**不新增字段**。**排序 = 右上图标按钮 → 弹出单选**,默认**「获得时间倒序」**(刚拿到的想看看,是最高频意图),备选类型 / 剩余次数升序 / `ManaCost`。
  - **同 `Id` 堆叠显示 `×N`**(同一 `Id` 的道具**可以持有多份**,见 `systems/character-profile/item/`):既让 99 的上限实质上更宽裕,也消除「同名道具满屏」的视觉噪音。
  - **不做拖拽整理 / 手动排序**(99 格在手机上手动排列是纯负担,且道具无位置语义,不像装备栏)。**长按查看详情**(半屏卡片:全名 / 描述 / `ManaCost` / `Charges` / `UsableScene`)——禁 hover-only 可供性,长按是触控等价物。
  - **战斗外可用的道具在此面板内可直接使用**(详情卡片上一个「使用」键);战斗内可用的**在此只能查看**,标注「须在战斗中使用」。
  - **实现注意**:99 项需虚拟化 / 节点复用,**不能实例化 99 个场景节点**。
  - 战斗内那一份筛选视图称**「随身」**(角标 + 底部抽屉),见 `ux/combat-ux.md`。
  Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **两段告警的呈现细节 = 静态标注于 EventOption 选择界面(已定案)。** 形态是**静态标注**(static annotation):数值 / 文案随事件结算而变,**平时静止**,不做持续跳动 / 计时器感的动画。位置**只在 EventOption 选择界面**——即玩家做抉择、也正是寿元被消耗的那个界面;**不做全局 HUD、不进战斗内**(见 `ux/combat-ux.md`)。Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。
- **「渡劫成功次数」与「总通关数」是两个数,并列展示且允许不相等(已定案 · 08-09d)。** 数据源分属两层:**渡劫成功次数**读 `PlayerProfile.PlayerPowerFragment.FinaleWinOrdinal`(规则字段层,统计侧刻意不另设 Finale 胜利数字段);**总通关数**读统计计数层的 `TotalCyclesCompleted`(完成整个轮回 = 三篇章全通 · 抵达元婴)。一次通关贡献 3 次 Finale 参与、至多 3 次胜利,而 Finale 胜利可完全不伴随通关,故**二者在任何账号上都不相等**。**呈现纪律:措辞不得暗示二者应当一致**;渡劫成功次数不计入 1% 的「失败但存活」,因此它可能小于已完成的篇章数——**该差值是有味道的信息,不是 bug**。落点为玩家档案与元婴界面(通关证书)的统计区。Source: `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md`。
- **隐藏属性跨档时给一条定性叙事(已定案)。** 道心 / 煞气 / 寿元的**数值继续完全隐藏**,但**跨过一个隐藏档位时**在事件收口处给一条定性描述(「你于静室枯坐三日,心念澄明。」「你的指节泛起一层洗不去的暗红。」)。**只在跨档时触发**,不是每次结算都播——稀缺才有分量。玩家学到**方向与因果**,学不到精确数值,因而无法做电子表格式优化。规则与档位归 `systems/services/plot-manager.md`;它复用既有的 `eventEnd` 阶段,无新结构。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **同步状态的两处呈现(已定案 · 08-09)。**
  - **常驻「离线 · 待同步 N」指示。** `sync-service` 的既定指示:UI 收到 `SyncStateChanged` 后单点查询 `PendingCount` 渲染。**它在战斗屏内同样必须可见**——这是「进入战斗前同步失败不额外提示」那条纪律成立的前提;若战斗屏隐藏了它,静默就变成了失联。见 `ux/combat-ux.md`。
  - **设置屏的「同步版本 #1337」。** 只读一行小字,与版本号 / 账号 ID 同区,取值 `SyncService.Instance.BaseRevision`;`0` 显示为**「尚未同步」**而非 `#0`。理由:强制在线 + 云端权威下,线上问题几乎都是「这台设备停在哪个版本」,让玩家与客服**对上同一个数字**的成本近乎为零,而替代方案(导出日志)在移动端基本不可行。**纪律:它是诊断展示,不是玩法数据**——ViewModel 只在设置屏读一次,不进任何玩法路径、不参与判断。
  Source: `handoffs/2026-08-09-sync-revision-cas-and-immediate-flush-nonblocking.md`。
- **美术挂点占位。** 循环视频、图标、卡面等 TBA;组合场景时为其保留可轻松替换的挂点,先用占位 / 免费资源。Source: `handoffs/2026-07-16-ux-flow-login-and-dev-order.md`。

## 决策(-> ADR)
> _已敲定的决定链接到 decisions/ADR-####。_

## 待解问题

- **元婴界面(通关证书)的具体形态:** 展示哪些字段(最终寿元、用时、修行历程摘要、成就?)、何时弹出、是否可回看 / 分享——均未定。Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **寿元告警是否伴随音效 / 震动:** 视觉形态已定(两段式 · 静态标注于 EventOption 选择界面);**是否附加听觉 / 触觉反馈**未陈述——「静态标注」的措辞倾向于「无强调反馈」,但未明确排除。Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。
- **跨档叙事的呈现位置与形态:** 已定「跨档才播、复用 `eventEnd`」;仍待定**播在哪里**(事件结算面板内的一行?独立的小弹层?)、**同一次结算多个属性同时跨档**如何呈现(逐条?合并?)、以及**寿元 30% 提示与其他属性跨档提示是否同一形态**。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **成就发放的奖励内容:** 阈值(60% / 90%)、一次性、80/20 可见比例**已定**(见「意图」);仅剩**两档各发放何种奖励**(PlayerPower / PlayerItem / 账号级)待定。
- **PlayerPower 细化:** 语义已定(全局、可开关、可获取 / 失去);但**获取 / 失去的具体触发**、是否影响 cycle seed / 计分公平性、平衡边界仍待定。→ `systems/player-profile/player-power/`。
- Source(未决项):`handoffs/2026-07-16-...`;语义裁定 `handoffs/2026-07-22-...`。

## 提供给
提炼进:`.claude/knowledge/scenes/_index.md`

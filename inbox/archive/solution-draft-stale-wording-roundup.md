---
type: solution-draft
date: 2026-09-06
question: 六条「过时措辞 / 台账失真」的逐条直读裁定与建议改写（derive 就绪度小节点名的 🟡 项）
source: open-questions.md「derive 就绪度」小节（`:69` · `:70` · `:71` · `:72` · `:73` · `:74`）
targets: systems/game-progression.md · systems/character-profile/item/_index.md · systems/character-profile/item/common-properties.md · systems/adventure-event/exchange/_index.md · systems/player-profile/account-info.md · ux/combat-ux.md · art/visuals/animations/_index.md · systems/services/profile-schema-versions.md · open-questions.md（derive 就绪度小节的台账更正）
status: distilled
reviewed: 2026-09-06 批量评审——六条裁定全部照准（条 1、2「不成立（已修）」不落笔）；唯一取向题「战斗外演出是否可跳过」裁选项 A（战斗外默认允许跳过 / 快进，仅战斗内结算演出不可跳过）；条 5 承接项并入 animations/_index.md、不提前新建 animation-direction.md
distilled-to: handoffs/2026-09-06-stale-wording-roundup.md
---

# 方案草稿 — 六条过时措辞 / 台账失真的直读裁定

## 问题

`open-questions.md`「derive 就绪度」小节（2026-09-06 全量评估）点名了一组 🟡「文档措辞与已定事实脱节」的失真项。它们不阻塞 derive，但会让下游读者（`/derive-requirements` 与分区开工者）以一条已被推翻的前提为起点。本草稿对其中六条**逐条直读源文件、引用原句后裁定**，并给出可直接落笔的替换文本。

**本草稿只做一件事：把「文档写的」对齐到「本库已定的」。它不裁决任何设计取向**（唯一的例外是第 5 条尾部的一条边界取向，列在 `## 仍需用户决定`）。

**方法纪律：** 每条先出示文件 + 行号 + 原句；凡直读后发现该失真**已被修好**或**讲的不是同一件事**，如实写「不成立」并给证据，不为凑齐六条而制造改动。

---

## 一、`game-progression.md:195` 与 `:57` 自相矛盾 —— **不成立（已修）**

### 直读证据

评估条目（`open-questions.md:69`）：

> **🟡 `game-progression.md:195` 与同文件 `:57` 自相矛盾**（前者把「进度感那一半」整条记为未决，后者已判给常驻经验条并称其为 ch2/ch3 唯一连续进度来源）。**08-30 已点名，第二次报告。**

**当前工作树中的 `systems/game-progression.md` 已无此矛盾。** `:195` 是 `## 待决问题` 的标题行，其下四条完整为：

```
195  ## 待决问题
198  - **「可用结束点」已明确**：到达下一境界所落的**存档点**即结束点…
199  - **选择区的呈现与导航手感**…
200  - **eventOptions 的五类配比未定。**…
201  - **blind / ante 缩放（未陈述）：**…
```

全文检索 `进度感` 在本文件**只命中 1 处**，即 `:57` 那条已定案的正面陈述：

> `:57` **在 ch2 / ch3 是唯一的连续进度感来源**。**经验从未被定为隐藏属性**。

失真的那条待决项曾经存在，但已在 HEAD（`7db3383`，2026-09-06）被删除。上一版（`e71351e`）的 `:195` 原文是：

> **中长期规划感的来源。** …**仍待定的是进度感那一半**：图鉴不回答「还有几步到 Finale」，是否还需轮回内的补充（篇章进度条？前瞻提示？）。

同批还把 `:57` 里指向该待答项的那半句（「这直接撞上『中长期规划感的来源』那条长期待答」）改写为现在的「而轮回内除等级外没有第二个量能表达中长期进度」，并新增 `:58` / `:59` / `:60` 三条把「不显示还需走多远」明写为**被接受的取向**（`handoffs/2026-09-06-finale-trigger-and-foresight-declined.md`）。

### 裁定

**不成立 —— 主题文档侧已修，失真只剩在台账里。** 评估小节写于同一天但显然早于该批落笔，故它仍在报告一个已经消失的矛盾。

### 建议改写文本

**不改 `systems/game-progression.md`。** 只更正台账：`open-questions.md`「derive 就绪度」小节删掉 `:69` 那一条（🟡 `game-progression.md:195` 与 `:57` 自相矛盾），并把同小节 `:125` 表格行 `systems/game-progression.md` 的**失真**尾注

> **失真：`:195` 与 `:57` 自相矛盾（第二次报告）**

整句删除（该行的 `partial` 判定与三条卡点其余部分不变——它们卡在 `blind / ante` 无形态、选择区手感、`BaseTypeWeights` 取值上，与本条无关）。

> 台账文件由 `/analyze-new-ideas` / `/summarize-open-questions` 落笔，本草稿只给文本。

### 顺带发现（同一个 `## 待决问题` 面，同族失真）

`game-progression.md:198` 的首条以「**已明确**」开头，通篇陈述的是一条**已定案的结论**（结束点 = 存档点 · 途中死亡从章首重试 · 重试次数见 `life-cycle-service.md`），却坐在 `## 待决问题` 里。它与本组失真同族（答定项未撤），且会被机械汇总当成待答项数进去。建议一并处理：

- **删除 `:198` 整条**，其内容已由 `:20` 一带的篇章 / 重试正文与 `decisions/ADR-0004-realm-checkpoint-retry-model.md`（`:192` 已回链）承载，删掉不丢任何事实；
- 若担心丢失导航，替代形态是把它降为 `## 意图` 内的一句回链，而非留在待决面上。

---

## 二、`item/_index.md:3` 与 `item/common-properties.md:3` 的「占位结构，细节待定」 —— **不成立（已修）**

### 直读证据

评估条目（`open-questions.md:70`）：

> **🟡 `item/_index.md:3` 与 `item/common-properties.md:3` 抬头均仍写「占位结构，细节待定」**，与两份已成文的字段面 / I-1~I-13 校验 / 跨载体判据回链直接矛盾。**08-28 首次点名，第三次报告。**

**两份文件的当前抬头均已无该措辞。** 全目录检索 `占位结构` / `细节待定` 在 `systems/character-profile/item/` 下**零命中**。当前原句：

- `systems/character-profile/item/_index.md:3`
  > **法宝 / CharacterItem** —— CharacterProfile 持有的、随单次轮回存在的道具（字段 `magicPack: List<CharacterItem>`），含内容定义 `ItemData` 的完整字段面、两格使用效果面与加载期校验。**三层分工（`ItemData` / `CharacterItem` / `magicPack`）见下表。**
- `systems/character-profile/item/common-properties.md:3`
  > 角色级道具（`CharacterItem` 持有条目）的共有字段与共有机制。**内容定义侧（`ItemData`）的字段清单、两格使用效果面与加载期校验的权威在 `_index.md`**，本文件只写持有条目侧。

上一版（`e71351e`）确实两处都带该措辞（`_index.md`：「含道具设计内容。占位结构，细节待定。」；`common-properties.md`：「共有字段与共有机制。占位结构，细节待定。」），HEAD（`7db3383`）已把两处替换为上引的实质抬头。

### 裁定

**不成立 —— 已在 2026-09-06 那批落笔中修好。** 与第 1 条同因：评估小节的这一行写于该批之前。

### 建议改写文本

**不改两份 item 文档。** 台账更正：`open-questions.md`「derive 就绪度」小节删掉 `:70` 整条。`:107` 的 `item/_index.md` 表格行**保持不变**（它的 `partial` 判定卡在回寿法宝总量护栏 / 道具目录 / 三条获取通道口径三条真卡点上，与抬头措辞无关）。

---

## 三、`exchange/_index.md:165` 仍标「ADR 候选，待 `/write-adr` 立档」 —— **成立**

### 直读证据

- `systems/adventure-event/exchange/_index.md:165`（在 `## 决策(-> ADR)` 节内，`:155` 起）
  > - **支付侧二选一：一条货币 element，或一件点名的轮回级法宝（定值以物易物）** —— ADR 候选，待 `/write-adr` 立档。
- `decisions/ADR-0126-exchange-barter-payment.md:1`–`:4`
  > # ADR-0126 — Exchange 支付侧二选一：货币，或一件点名的轮回级法宝
  > - **状态：** Accepted
  > - **日期：** 2026-08-30
  > - **来源：** handoffs/2026-08-30-exchange-barter-support.md

同文件 `:26`（`## 意图` 内）已把该决定写成正面陈述（「两种形态**并存，一种不排除另一种**」），故本条纯粹是 `## 决策(-> ADR)` 节里一行**未回填的候选标记**，不涉及任何事实分歧。

### 裁定

**成立，且是纯机械修正（零决策）。** ADR 已 Accepted 七天，候选标记必须换成回链——这一节的既定形态就是「已定案的决定链接到 `decisions/ADR-####`」（`:156` 的模板注释），一条不带链接的条目在这一节里是缺陷。

顺带：本条的兑现物同时被 `profile-schema-versions.md:47`（v1 清单 #25，`EventOption` 的 `ExchangeStock` / `BarterStock` / `RerolledCount`）以 `decisions/ADR-0126-exchange-barter-payment.md` 回链，两处口径届时一致。

### 建议改写文本

把 `systems/adventure-event/exchange/_index.md:165` 整行替换为（形态对齐同节 `:158` / `:159` 两行的既有写法）：

```markdown
- **支付侧二选一：一条货币 element，或一件点名的轮回级法宝（定值以物易物 / barter）** → `decisions/ADR-0126-exchange-barter-payment.md`（Accepted；含 `Holds(...)` 门面级前置拒绝与「不扩 `CanAfford`」）。
```

台账侧：`open-questions.md` 删 `:71` 整条。**不动**同文件 `## 待决问题`（`:167` 起）—— `common-properties.md:213` 与 `_index.md:170` 的待决区对齐归另一分片，本条不触碰。

---

## 四、`account-info.md` 的唯一待决问题已被跨边界答死 —— **成立**

### 直读证据

**客户端侧（待撤的那条）**——`systems/player-profile/account-info.md:51`–`:54`：

```
51  ## 待决问题
52  > _尚未解决，需要一次 handoff/决策。_
53
54  - **合规字段的归属：** 实名 / 未成年人限制等合规要求落在客户端还是纯后端，权威在 `backend-design-documents/open-questions.md`。字段表因此仍可能增行。
```

**对侧证据一**——`backend-design-documents/contracts/compliance.md:202`（`GET /v1/compliance/status` 应答表之后的「不下发」行）：

> - **不下发**：`account.status`（`auth.md` §1a）· 时段表与规则本身（§6）· 出生日期 · 最近一次导出任务的 `taskId`（客户端持有；丢失即重新 `POST export`）。

**对侧证据二**——`backend-design-documents/contracts/auth.md:55`：

> - **`status`（`active` · `restricted` · `banned` · `pendingDeletion`）同样不跨边界。** 它的客户端表现全部由 `signin` 应答分支与 `compliance.*` 承载；下发一份副本没有消费点，且会在会话中途过期（封禁发生时客户端那份仍写着 `active`）。

**对侧证据三（最直接的一条，评估未引）**——`backend-design-documents/contracts/compliance.md:337`，在该文件的「已考虑并否决」面上逐字否决了本条所担心的那个形态：

> - **合规态随 `AccountInfo` 下行** — 与 `account.status` 被否的理由逐字相同（会话中途过期的第二真值），且实名状态含个人信息，进 profile 即进玩家可导出的存档。

配套 `compliance.md:35`：

> **而合规态没有任何下行通道**：`account.status` 不跨边界（`auth.md` §1a）、实名状态含个人信息不得进玩家可导出的 profile、时段剩余会在会话中途变化。**没有第一份真值，就谈不上第二份。**

**客户端侧已吸收该结论（本文件之外）**——`systems/services/account-service.md:230`：

> - **调用点唯一：`ComplianceManager`。** 合规态没有任何下行通道（不随 `AccountInfo` 下行，理由见对侧契约）⇒ 必须有这一次请求。

### 裁定

**成立 —— 该待决问题已被对侧答死，且答案是「一格也不落 `AccountInfo`」，应当撤销而非改写。**

三条证据合起来是穷尽的：① 合规态**没有任何**下行通道（`compliance.md:35`）；② 唯一的合规读取面是 `GET /v1/compliance/status` 的**独立应答**，其字段（`realnameStatus` / `isMinor` / `playtimeRemainingSeconds` / `playtimeResumeAtUtc` / `deletionEffectiveAtUtc` / `nicknameChangeRequired`）落在**该端点的应答体**里，不进 profile；③「随 `AccountInfo` 下行」这一形态被显式否决并给了理由（第二真值 + 个人信息进可导出存档）。⇒ `AccountInfo` 的字段表**不再有因合规而增行的风险**，本条的存在前提消失。

补充：客户端侧的合规承载形态也已成文（`account-service.md:175` 起的「合规域的客户端覆盖面」四域切分 + `ComplianceManager` + `:194` 的「客户端不做任何判定」+ `:223` 的「只在内存持有、不落盘」），即「合规要求落在客户端还是纯后端」这个问句本身也已被答：**强制力全在后端，客户端只呈现，且呈现态不落存档。**

### 建议改写文本

**删除 `systems/player-profile/account-info.md:54` 整条**，`## 待决问题` 节随之为空。按本库既有形态，空的待决节保留标题 + 引言并补一句「无」即可：

```markdown
## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- 无。
```

并在 `## 意图` 末尾（`:44` 那段跨边界回链之后）补一句正面陈述，把撤销的依据留在文档里（**只回链、不复述对侧内容**）：

```markdown
- **合规域一格也不落 `AccountInfo`（已收口）。** 合规态没有任何下行通道，「随 `AccountInfo` 下行」这一形态被对侧显式否决（`backend-design-documents/contracts/compliance.md`「不下发」与被否决项 · `contracts/auth.md` §1a）；客户端侧的承载是 `ComplianceManager` 的独立 status 读取且**只在内存持有**（见 `systems/services/account-service.md`「合规域的客户端覆盖面」）。⇒ **本字段表不因合规增行。**
```

台账侧：`open-questions.md` 删 `:72` 整条；`:112` 的 `account-info.md` 表格行把「判 partial 而非 ready 的理由只剩两条」收窄为一条——保留「单独不构成可独立成立的 FR 面 ⇒ 须随 `account-service` / 登录切片同批」，删去「本文件尚未吸收该结论（`:51` 未撤）」。同小节 `:151` 的零决策修正清单第 ⑤ 项（`account-info.md:51` 撤掉已被跨边界答死的待决问题）在落笔后一并删除。

> 本条**不触碰对侧库**：证据只作引用，`backend-design-documents/` 一字不改（它那侧已经写全了，没有承接项）。

---

## 五、`combat-ux.md:22`「只能加速不能跳过」 vs `animations/_index.md:20`「须可跳过 / 可加速」 —— **成立，按上游定案裁给 combat-ux 侧**

### 直读证据

- `ux/combat-ux.md:22`（`## 意图` 内，「结算演出的节奏（双方回合通用）」）
  > 单步节拍 **0.35–0.5 s** · **超过 4 步后压到 0.2 s** 并**合并同来源、同类型、同符号的连续增量**（跨来源不合并——跨来源正是玩家需要区分的）· 点按屏幕任意处 **3× 加速**（**只能加速不能跳过**，「逐步可见」是硬要求）· 永久快速演出为设置项（默认关，开启后基线节拍 0.2 s）。
- `art/visuals/animations/_index.md:20`（`## 待决问题` 内）
  > - **与战斗节奏的关系：** 动画时长直接影响一局 10 回合的实际时长（`vision/scope.md` 的篇章目标时长是硬预算），须可跳过 / 可加速。

**一侧有已 Accepted 的 ADR，另一侧自陈未设计。**

- `decisions/ADR-0086-lifo-resolution-and-combat-log.md:1`–`:3`
  > # ADR-0086 — 结算呈现 = 逐层 LIFO 弹栈 + 短暂强调；战报 `combatLog` 是同一份数据的两个视图，不上提为 `eventLog`
  > - **状态：** Accepted
  > - **日期：** 2026-08-25

  同文件 `:13`：
  > **结算呈现 = 逐层弹栈 + 短暂强调，不做滚动播报流（承重）。** …**「不可暂停」读作「无玩家侧的暂停 / 跳过控件」。**
- 上游 handoff `handoffs/2026-08-25-combat-presentation-and-action-result.md:35`
  > 节奏参数复用既有那套，并提为双方回合通用：单步 0.35–0.5 s · 超过 4 步压到 0.2 s… · 点按任意处 3× 加速（只能加速不能跳过）· 永久快速演出为设置项。
- `ux/combat-ux.md:16`（「不能跳过」的承重理由）
  > **敌人回合的逐步执行呈现是硬要求（承重）。** **敌人回合是玩家获取动态情报的唯一时刻**——看不清就完全不可读。
- 对照 `art/visuals/animations/_index.md:1` / `:5`
  > # 动画（Animations）—— 占位
  > **本节尚未设计。** 会有一些动画，但**先咨询专业人士，再充实本节**——不预设形态…

  且该句所在的 `## 待决问题` 有一行总括（`:18`）：
  > 本节全部条目**待咨询专业人士后确定**——不预设形态。

### 裁定

**combat-ux 侧成立，animations 侧应让步并改写。** 依据是明确的上游定案而非并列主张：

1. `ADR-0086`（Accepted）把「无玩家侧的暂停 / 跳过控件」写进了决策本体；`animations/_index.md` 自陈**整节尚未设计**、其条目**全部待外部输入**——一侧是已固化决策，另一侧是占位期的顺手一笔，不构成对称的两个主张。
2. combat-ux 侧带承重论证（敌人回合是唯一情报通道，`:16`），animations 侧那句是从**时长预算**推来的手段建议，而时长预算在战斗内**已有另一套兑现**：3× 加速 + 超 4 步压到 0.2 s + 敌人回合总时长 **≤ 4 s** 硬上界（`combat-ux.md:22`、`:23`）。⇒ 删掉「可跳过」不会让时长预算失去护栏。
3. `combat-ux.md:22` 尾句「**演出中没有不可跳过的节拍**」讲的是**加速手势在任何一步都生效**（不设加速无效的强制停留），与「无跳过控件」不冲突——改写时须小心不要把这句读反。

**但裁定须带作用域。** `ADR-0086` 的射程是**战斗内的结算演出**；animations 分区的范围是四类（`:19`：卡牌打出 / 结算特效、立绘动效、UI 转场、战斗反馈动画），其中 UI 转场与立绘动效**不在** `ADR-0086` 射程内。⇒ 改写不是简单地把「须可跳过」删成「不可跳过」，而是**按类分档**。分档本身的一条边界留给用户（见 `## 仍需用户决定`）。

### 建议改写文本

把 `art/visuals/animations/_index.md:20` 整条替换为：

```markdown
- **与战斗节奏的关系：** 动画时长直接影响一局 10 回合的实际时长（`vision/scope.md` 的篇章目标时长是硬预算）。**战斗内的结算演出没有玩家侧的跳过控件**——「逐步可见」是硬要求，时长由「3× 加速 + 超 4 步压到 0.2 s + 敌人回合总时长 ≤ 4 s」三重护栏收敛（权威：`decisions/ADR-0086-lifo-resolution-and-combat-log.md` 与 `ux/combat-ux.md`「结算演出的节奏」，**本节不重复陈述、也不得与之相抵**）。⇒ 本节待定的是**在该护栏内**每类动画的时长上界与缓动，不是「能否跳过」。
```

并把同文件 `:24`（`## 结构（待本节开工时立起）`）中的「动效原则：时长、缓动、**可跳过策略**」改为：

```markdown
预计需要一份 `animation-direction.md`（动效原则：时长、缓动、**战斗外演出的跳过策略**；战斗内不可跳过是既定边界，见上）与逐条动画的规格；
```

**不改 `ux/combat-ux.md`。** 它是权威侧，一字不动。

台账侧：`open-questions.md` 删 `:73` 整条；`:142` 的 `animations/_index.md` 表格行删去尾句「**`:20`「须可跳过 / 可加速」与 `ux/combat-ux.md:22`「只能加速不能跳过」两侧相抵，无一方标注让步**」（`blocked` 判定与「待咨询专业人士」的理由不变）；`:191` 的「其『须可跳过』与 `combat-ux.md`『只能加速不能跳过』的相抵需在第 2 条那场会上一并裁掉」一句删除——本条不必再占那场战斗 / 事件 UX 专场的议程（专场的两条承重议题不受影响）。

---

## 六、`profile-schema-versions.md` 结构与全库不同构 —— **成立**

### 直读证据

- 该文件的全部二级标题（直读 `systems/services/profile-schema-versions.md`）：`## 登记表`（`:9`）· `## 形态纪律`（`:62`）· `## 登记时点与责任人`（`:86`）· `## `ProfileShapeCheck`：把漏 bump 抬到纪律阶梯第 2 级`（`:93`）· `## 对应`（`:110`）。**无 `## 意图` / `## 决策(-> ADR)` / `## 待决问题`。**
- 两处已知空缺确实只以散文形式散落在正文里，落不到任何 `## 待决问题` 面上：
  - `:60`
    > **`PlayerProfile.achievement` 尚未进清单。** 它的条目结构待 `Achievement` schema 答定后补入本清单，届时仍属 `schemaVersion` 1、不产生新的 bump。
  - `:15`（登记表 v1 行的「golden 形状快照」格）
    > `profile-shape-v1.json`（待建，见下方「`ProfileShapeCheck`」）

    配套 `:106`
    > - **落地时点：** `game-feature-branch/` 尚无 `.csproj`，本护栏宜与那批既有实测项同批落地（`open-questions/05-service-contracts.md`），**不单独排期；设计形态不依赖实测结果**。
- 该文件**已被当作主题文档对待**：`open-questions.md:43` 把它计入「主题文档 76 份」（明写「含新文件 `services/profile-schema-versions.md`」），`:101` 给了它一行 derive 判定（`partial`），`:159` 给了它一个 derive 步骤（第 7 步，与 `sync-service.md` 同批）。⇒ 它不在「导航索引 / 登记表**非 derive 对象**」那一族里（对照 `:136` 对 `systems/_index.md` 等的处置）。
- 它同时被 `open-questions.md:63` 的系统性 🟠 点名为「`## 决策(-> ADR)` 整节空白」的 10 处之一以外的另一类——本文件是**连标题都没有**，故那条 grep 也扫不到它。

### 裁定

**成立，且应按「补齐三小节」处理，不宜标为显式例外。** 三条依据：

1. **它已被判为 derive 对象**（`:101` / `:159`），而 derive 就绪度与待答项汇总这两套机械扫描都以 `## 待决问题` 为落点。少这一节 ⇒ 两处真实空缺对机械汇总**不可见**，正是本条要修的病。
2. **它确实有 ADR 落点**：`ADR-0145` / `ADR-0158`（`open-questions.md:50` 记「逐版登记新立独立文件 `systems/services/profile-schema-versions.md`（`ADR-0145` / `ADR-0158`）」）。既有落点却无 `## 决策(-> ADR)` 节，正是 `:63` 那条系统性缺口在本文件上的极端形态。
3. **标为显式例外的代价更大：** 例外要求另立一个「机械汇总可见的登记位」，而那等于为一份文档新造一套扫描口径——违反本库「不为一份文档另造工具」的取舍（该文件自己 `:108` 就用这条口径否决过为对账另造工具）。补三个标题是零成本、零第二权威的做法。

**但补的方式有纪律：三节都只写回链与承接，不得复述任何字段规格。** 该文件 `:58` / `:72` / `:83` 自己定了三条硬边界（不复述类型 / 取值域 / 校验语义 · 老档默认值口径留在字段所在处 · 不写任何计数）；补节时若把 `achievement` 的形状或 golden 文件的内容写进来，当场违反它自己的纪律。

### 建议改写文本

**① 在 `Source:` 行（`:7`）之后、`## 登记表`（`:9`）之前插入 `## 意图`**（三条，全部是已在文内的事实的提要，不新增任何主张）：

```markdown
## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **本文件是两层 Profile 每一版序列化形状的唯一登记面。** 宿主服务是 `sync-service`（`MigrationManager` 在那里），服务本体的设计见 `systems/services/sync-service.md`；**别处一律回链本表、不得就地宣布 bump**（口径见「形态纪律」②）。
- **登记是变更内原子的：** 任何改动两层 Profile 及其可达对象序列化形态的设计落笔，未登记进本表即视为未完成（见「登记时点与责任人」）。
- **漏 bump 由 `ProfileShapeCheck` 抬到纪律阶梯第 2 级**（打包管线不通过即不产包 + `#if DEBUG` 启动期同一份校验），载体是签入 `game-feature-branch/` 的 golden 形状快照（见该节）。
```

**② 在 `## 登记时点与责任人` 与 `## `ProfileShapeCheck`…` 之间（即 `:92` 之后）插入 `## 决策(-> ADR)`**：

```markdown
## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **存档 `schemaVersion` 的登记权威 = 独立成文的逐版登记表 + `ProfileShapeCheck` 护栏**（`sync-service.md` 只留执行面） → `decisions/ADR-0158-schema-version-ledger-authority.md`（Accepted）。
- **本表不写任何计数（形态纪律第 ⑥ 条）** → `decisions/ADR-0145-schema-ledger-no-counts.md`（Accepted）。
```

> 两行的 ADR 编号 · 文件名 · 标题均已逐字直读核对（`decisions/ADR-0158-schema-version-ledger-authority.md` 与 `decisions/ADR-0145-schema-ledger-no-counts.md`，两份状态皆 `Accepted`）。**注意 `open-questions.md:50` 把这两份并列记作「逐版登记新立独立文件（`ADR-0145` / `ADR-0158`）」，措辞使人误以为 `ADR-0145` 也讲权威外移——实际它讲的是「不写计数」。** 本节按直读结果落笔。「v1 首发形状归一版、不拆多版」**没有独立 ADR**（它写在本文件 `:19`，由 `ADR-0158` 覆盖），故不为它编造一行。

**③ 在 `## 对应`（`:110`）之前插入 `## 待决问题`**，把两处空缺抬到机械可见面上（**均只写承接与回链**）：

```markdown
## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`PlayerProfile.achievement` 尚未进 v1 清单。** 前置 = `Achievement` 的条目 schema 与进度模型（权威在 `systems/player-profile/achievement/`，该分区整体未设计）。答定后**补条目进 v1 清单，仍属 `schemaVersion` 1、不产生新的 bump**；在此之前**不得写入推测形状**（理由见「v1 —— 首发形状」末段）。本条是**承接项**，不是本文件自身的设计缺口。
- **v1 的 golden 形状快照 `profile-shape-v1.json` 待建。** 设计形态已完整（见「`ProfileShapeCheck`」节），卡的是落地时点——`game-feature-branch/` 尚无 `.csproj`，宜与那批既有实测项同批落地（`open-questions/05-service-contracts.md`），**不单独排期**。本条是**落地排期项**，不阻塞任何 derive。
```

**④ `:60` 与 `:15` / `:106` 三处原文保持不变**——新增的待决条目是**投影**，权威仍在原处；两侧措辞已一致（本草稿的建议文本逐句取自原文），不构成第二权威。

台账侧：`open-questions.md` 删 `:74` 整条；`:101` 的表格行删去开头「无三个标准小节，但抬头（`:1`）载有真实定位；已知空缺明写在文内」，改为「三个标准小节已补齐，两处空缺落在 `## 待决问题` 上」，其余（就绪切片三条 · 两条卡点 · 须与 `sync-service.md` 同批）不变。

---

## 具体形态（可 derive 的落地面）

本草稿不产生任何新的设计面。改动逐条汇总（**六条中四条落笔、两条只改台账**）：

| # | 文件 | 行 | 动作 | 决策成分 |
|---|---|---|---|---|
| 1 | `systems/game-progression.md` | — | **不改**（`:198` 的顺带项另计） | 无（不成立） |
| 1+ | `systems/game-progression.md` | `:198` | 删除已答定的「可用结束点」条 | 零决策（顺带发现） |
| 2 | `systems/character-profile/item/_index.md` · `common-properties.md` | — | **不改** | 无（不成立） |
| 3 | `systems/adventure-event/exchange/_index.md` | `:165` | 候选标记 → `ADR-0126` 回链 | 零决策 |
| 4 | `systems/player-profile/account-info.md` | `:54` 删 · `## 意图` 末补一句 | 撤销已被答死的待决项 + 留下依据回链 | 零决策 |
| 5 | `art/visuals/animations/_index.md` | `:20` · `:24` | 改写为「战斗内不可跳过」+ 回链，跳过策略收窄到战斗外 | 按 `ADR-0086` 裁；边界一条见下 |
| 6 | `systems/services/profile-schema-versions.md` | 新增三节 | 补 `## 意图` / `## 决策(-> ADR)` / `## 待决问题` | 零决策 |
| 台账 | `open-questions.md`「derive 就绪度」 | `:69`–`:74` · `:101` · `:112` · `:125` · `:142` · `:151`⑤ · `:191` | 逐条更正 | 零决策 |

## 后果

- **六条全部落笔后，`open-questions.md`「derive 就绪度」小节的 🟡 面减少六条**；其中 `account-info.md` 由 `partial` 的两条理由收窄为一条（仍不单独 derive，随登录切片同批），`profile-schema-versions.md` 的空缺由「散在正文里」变为「机械可见」。
- **无存档 schema 影响、无迁移。** 第 6 条只增标题与回链，不触碰登记表任何一行，`ProfileShapeCheck` 的 golden 快照不受影响。
- **第 5 条会让 animations 分区开工时的起点从一条被否决的前提变为一条正确的边界**；该分区仍 `blocked`（待外部输入），本改动不改变其判定。
- **不产生任何新的 FR 面**，也不改变任何文档的 derive 判定（`ready` / `partial` / `blocked` 全部维持）。

## 备选方案（已考虑并否决）

- **第 3 条改为在 `## 意图` 里加一句「已由 ADR-0126 固化」而不动 `:165`** — 否决：`## 决策(-> ADR)` 节的既定形态就是承载回链，把回链放到别处等于让这一节继续失真。
- **第 4 条改为把待决项改写成「已答定，见对侧」保留在 `## 待决问题` 里** — 否决：待决面上留一条已答定的条目，正是本轮六条失真的共同病因（对照第 1 条的 `:198`）。答定即移出，是本库的既定纪律。
- **第 5 条改为在 `ux/combat-ux.md` 上标注让步（允许跳过）** — 否决：与 `ADR-0086`（Accepted）正面冲突，且要推翻「敌人回合是唯一情报通道」这条承重论证；art 侧那句写于占位期、无论证。
- **第 5 条改为两侧都加一句「以另一侧为准」** — 否决：制造循环回链，读者仍读不到结论。
- **第 6 条改为「标注为显式例外 + 另立机械汇总可见的登记位」** — 否决：为一份文档新造扫描口径，成本高于补三个标题，且该文件自己 `:108` 用同一条口径否决过「为对账另造工具」。
- **第 6 条改为只补 `## 待决问题`、不补另外两节** — 否决：`## 决策(-> ADR)` 缺失正是 `open-questions.md:63` 那条系统性缺口（本文件是其中最极端的一例，连标题都没有，连 grep 都扫不到）；一次补齐比日后再被点名一次便宜。

## 与既有决策的张力

**无。** 六条全部是把文档措辞对齐到已 Accepted 的决策（`ADR-0086` · `ADR-0126` · `ADR-0145` / `ADR-0158`）与已成文的跨边界契约（`contracts/compliance.md` · `contracts/auth.md`），无一条要求任何既有决策松动。

## 前置依赖

- **无。** 六条均可立即落笔（第 6 条 ② 的两行 ADR 回链已逐字核对实际文件名与标题）。
- **第 3 条与另一分片有相邻关系但不重叠**：本条只动 `exchange/_index.md:165`（`## 决策(-> ADR)` 节内）；`common-properties.md:213` 与 `_index.md:170` 的待决区对齐归另一分片，两者写入面不相交。

## 仍需用户决定

1. **战斗**外**的演出是否允许玩家跳过（第 5 条的作用域边界）。**

   **→ 已裁决（2026-09-06 · 批量评审）：选项 A —— 战斗外的演出默认允许跳过 / 快进，只有战斗内结算演出不可跳过。** ⇒ 第 5 条的 `:24` 改写文本（「战斗外演出的跳过策略」）原样成立；另需在 `animation-direction.md` 写一条「战斗外跳过控件的统一形态」（触点、是否记忆偏好）的承接项。

   `ADR-0086` 的射程只到**战斗内的结算演出**，而 animations 分区的范围是四类（卡牌打出 / 结算特效、立绘动效、UI 转场、战斗反馈动画，`animations/_index.md:19`）。裁掉「战斗内可跳过」之后，另外那半边（立绘动效、UI 转场，以及日后可能出现的篇章过场 / 结算大演出）**尚无任何一侧定过**。
   - **选项 A（推荐）：战斗外的演出默认允许跳过 / 快进，只有战斗内结算演出不可跳过。** 理由：`ADR-0086` 的论证前提是「敌人回合是玩家获取动态情报的唯一时刻」，该前提在战斗外**不成立**——UI 转场与立绘动效不承载任何玩家需要读取的动态情报；且强制在线 + roguelike 轮回意味着同一段转场会被重复观看数十次，不可跳过会直接吃掉 30–40 分钟的篇章预算（`vision/scope.md`）。后果：`animation-direction.md` 需要写一条「战斗外跳过控件的统一形态」（触点、是否记忆偏好）。
   - **选项 B：全库统一「只能加速不能跳过」。** 理由：演出语言一致、玩家不需要学两套规则。后果：重复观看的转场只能靠「永久快速演出」设置项缓解，且该设置项目前只定义在战斗内（`combat-ux.md:22`）；须扩它的作用域。
   - **推荐 A。** 若采 A，第 5 条的 `:24` 改写文本（「战斗外演出的跳过策略」）原样成立；若采 B，把 `:24` 改回「可跳过策略」并删去「战斗外」限定，同时在 `animations/_index.md` 记一条「永久快速演出设置项须扩到战斗外」的承接项。
   - **本条不阻塞第 5 条的主改动**（`:20` 那句的裁定与 A / B 无关，两种取向下都成立）。

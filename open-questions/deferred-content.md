# 已搁置：内容充实（07-30 起暂不推进）

> 本分片属 `../open-questions.md`，与焦点区并列。
>
> **搁置的是「具体条目目录与数值」**——卡牌 / 敌人 / 道具 / 各类事件的清单、平衡数值、奖励内容。它们归开发路线的第 ② ③ 阶段（内容 → 平衡与体验），当前不作为待答焦点。**下列条目不删除、不作废**，只是不再优先拾取；机制先行、内容随后填充。
>
> **交叠地带需确认：** 部分条目既是机制也带数值（例：`lifeSpanCost` 哪些事件类型覆写基准；`EventOption` 完整物化字段清单此前明确标注为「需要一次**内容侧** handoff」）。本区收的是**目录 / 数值性的一半**，**规则性的一半留在焦点区各分片**；若解读有偏差请指出。

## 内容目录与数值

- **内容目录整体未编写：** 卡牌定义与起始卡组、**敌人目录（含其等级、招式与定制卡组）**、意图目录、遭遇战（encounter）编排、道具目录、各类型 AdventureEvent 的具体条目。→ `20-systems/character-profile/deck/`、`item/`、`20-systems/adventure-event/**`。
- **成就两档奖励内容：** 阈值（60% / 90%）、一次性、80/20 可见已定；仅剩**两档各发放何种奖励**（PlayerPower / PlayerItem / 账号级）待定。→ `40-ux/screen-flow.md`、`20-systems/player-profile/achievements/`。
- **ch1 数值标杆专场（08-02 定归宿 · 由焦点区移入）：** **卡牌产 / 削道念的量纲基准**（一张牌该产多少、一场内总产出相对 `baseMomentum` 的倍数、是否有道念相关的状态与倍率）与 **`lifeTotal` 的回复幅度**，**明确推迟到内容横向扩展阶段的一场专门「ch1 数值模型」session**，切入点是设计起始角色 starter deck 的过程。**并且优先打磨 ch1 内容。** 已给的定性结论：**越级追分可能但很难，境界差越大越难**。→ `20-systems/balance.md`、`20-systems/character-profile/deck/`、`life-total.md`、`00-vision/scope.md`。
- **平衡数值整体：** ante / 篇章缩放、掉落权重、成本档位、奖励曲线。→ `20-systems/balance.md`。

## 元进程持久化与内容开关

- **元进程持久化字段结构：** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 语义已澄清、服务归属已定（profile-service）、文档落位已定；但**各自字段 schema 与解锁 / 获取 / 失去触发**待定；`status`（启用 / 禁用）与「拥有 / 失去」两态的存档表达未定。→ `20-systems/services/profile-service.md`、`20-systems/player-profile/`。
- **PlayerPower 获取 / 失去触发与公平性：** 方向已定为**轻度提升、PvE-only 可容忍**，且**道统残卷已给出一条获取渠道**（轮回开始时的概率掉落，规则见焦点区 ⑥）；具体在哪些 AdventureEvent 获取 / 失去、是否影响 cycle seed / 计分公平仍待定。→ `20-systems/player-profile/player-power/`。
- **capability flag 的叠加 / 冲突规则：** 两个 power 授予同一 flag 如何处理；多个 modifier 作用于同一 key 的**运算顺序**（加法先于乘法？声明序？优先级字段？）。→ `20-systems/player-profile/player-power/common-properties.md`。
- **AchievementManager 的触发采集面：** 成就进度靠订阅 EventBus 被动采集（解耦但易漏）还是各服务主动上报（可靠但反向依赖）？→ `20-systems/services/profile-service.md`。
- **AccountInfo 字段 schema：** 账号 id / 绑定渠道 / 昵称头像 / 注册时间 / 封禁实名状态等未设计；多渠道绑定同一账号的模型未定。→ `20-systems/player-profile/account-info.md`。
- **GameSetting 的设备本地项 vs 账号级项切分：** 画质 / 震动等设备强相关设置是否应留在本地 `user://` 而不上行云端。→ `20-systems/player-profile/game-setting.md`。
- **disabled 条目被存档引用时的 UX：** 读取侧不过滤故存档能正确解析；但玩家手中一张「已被线上关闭」的卡 / 道具是否应有提示，还是完全静默照常可用？→ `20-systems/services/content-service.md`、`40-ux/`。
- **`ContentEnabled` 的粒度是否够用：** 单一布尔只支持「全开 / 全关」；**灰度与分批放量**需要按玩家分桶（百分比 / 白名单 / 篇章档位），分桶信息放哪（overlay 的另一层配置？后端下发的 bucket 列表？）未定。→ 同上。

## UX 呈现细节（随内容一同搁置）

- **元婴界面（通关证书）的具体形态：** 用途已定（读取并显示最终寿元）；展示哪些字段（最终寿元、用时、修行历程摘要、成就？）、何时弹出、能否回看 / 分享未定。→ `40-ux/screen-flow.md`。
- **寿元告警是否伴随音效 / 震动：** 视觉形态已定（**静态标注于 EventOption 选择界面**）；是否附加听觉 / 触觉反馈未陈述。→ `40-ux/screen-flow.md`。
- **战斗屏幕的其余形态：** 出牌手势（拖拽 vs 点按）、目标指定、手牌布局、回合节奏与动画时长、竖屏下的敌我分区、**敌方出牌的呈现方式**（敌人也持有卡组）、**战后奖励面板的形态**（强制项与可选项如何同屏区分、候选数量与竖屏排布、能否反悔）、**stack 是否需要进入呈现层**（响应窗口移除后读栈不再是决策必需，与「栈深何时 > 1」绑定）、**三步结构的呈现细节**（起始步的 mana 刷满 / 抽牌节拍、结束步的回合内状态消散、"轮到谁"的常驻指示）——待后续战斗 UX 专场。→ `40-ux/combat-ux.md`。（注：**信息面**已在 07-30b 定案为「意图三档 + 探查 + 图鉴」三通道；**主视觉**已在 08-01 定案为「双方道念对比」、lifeTotal 退居次要。二者的残留细节留在焦点区 ①。）
- **道念对比的视觉形态与 lifeTotal 在战斗屏的位置：** 主视觉地位已定；用什么形态（左右对比条 / 双数值 / 天平隐喻）、道念变化的反馈、「道念差」是否显式呈现、以及 lifeTotal 是否仍常驻显示（作为「失败会掉多少」的参照）均未定；**「还剩几回合」的呈现**（定长 10 回合的连带）亦未定。→ `40-ux/combat-ux.md`。

## 尚未设计（占位，暂无具体问题）

- 以下主题文档仍是空占位或仅有骨架，尚无成形问题，待各自专场 handoff 播种：
  - 角色档案：`20-systems/character-profile/item/`（`deck/` 已有骨架，具体卡牌机制仍空）。
  - 玩家档案：`20-systems/player-profile/player-item/`、`account-info.md`、`game-setting.md`（`codex/` 已于 07-30b 播种，问题见焦点区 ①）。
  - 事件内容：`20-systems/adventure-event/` 除 combat 之外的八类子类型（combat 已于 07-30b 开过第一场）。

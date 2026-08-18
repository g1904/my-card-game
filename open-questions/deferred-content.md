# 已搁置：内容充实（07-30 起暂不推进）

> 本分片属 `../open-questions.md`，与焦点区并列。
>
> **搁置的是「具体条目目录与数值」**——卡牌 / 敌人 / 道具 / 各类事件的清单、平衡数值、奖励内容，**以及美术 / 音频资产（`art/`，08-04 加入）**。它们归开发路线的第 ② ③ 阶段（内容 → 平衡与体验），当前不作为待答焦点。**下列条目不删除、不作废**，只是不再优先拾取；机制先行、内容随后填充。
>
> **交叠地带需确认：** 部分条目既是机制也带数值（例：`lifeSpanCost` 哪些事件类型覆写基准；`EventOption` 完整物化字段清单此前明确标注为「需要一次**内容侧** handoff」）。本区收的是**目录 / 数值性的一半**，**规则性的一半留在焦点区各分片**；若解读有偏差请指出。

## 内容目录与数值

- **内容目录整体未编写：** 卡牌定义与起始卡组、**敌人目录（含其等级、招式与定制卡组）**、遭遇战（encounter）编排、道具目录、各类型 AdventureEvent 的具体条目。→ `systems/character-profile/deck/`、`item/`、`systems/adventure-event/**`。（原列的「意图目录」随 08-15d 意图机制整条移除而作废。）
- **敌人条目的叙事一致性编写口径（08-16b 采集 · 此前未进清单）：** 标为 `[Practice, Standard]` 的敌人条目，其图鉴词条与台词须**同时说得通「切磋」与「厮杀」两种语境**——具体口径归 `enemy-codex.md` 的写作规格，属内容编写阶段。→ `systems/player-profile/codex/enemy-codex.md`、`systems/adventure-event/combat/_index.md`。
- **成就两档奖励内容：** 阈值（60% / 90%）、一次性、80/20 可见已定；仅剩**两档各发放何种奖励**（PlayerPower / PlayerItem / 账号级）待定。→ `ux/screen-flow.md`、`systems/player-profile/achievement/`。
- **ch1 数值标杆专场（08-02 定归宿 · 由焦点区移入）：** **卡牌产 / 削道念的量纲基准**（一张牌该产多少、一场内总产出相对 `baseMomentum` 的倍数、是否有道念相关的状态与倍率）与 **`lifeTotal` 的回复幅度**，**明确推迟到内容横向扩展阶段的一场专门「ch1 数值模型」session**，切入点是设计起始角色 starter deck 的过程。**并且优先打磨 ch1 内容。** 已给的定性结论：**越级追分可能但很难，境界差越大越难**。→ `systems/balance.md`、`systems/character-profile/deck/`、`life-total.md`、`vision/scope.md`。
- **平衡数值整体：** ante / 篇章缩放、掉落权重、成本档位、奖励曲线。**blind / ante 缩放曲线本身尚未陈述**（进程语义见 `systems/game-progression.md`，一旦落定数值归此）。→ `systems/balance.md`。
- **重试上限两档数值是否随实测再调（08-16b 采集 · 轻）：** **落点已定**——两行住在平衡资源、由 `HasPremiumBundle` 选行，故它已是可调平衡项；待定的只有**数值本身**。→ `systems/balance.md`、`systems/services/life-cycle-service.md`。
- **事件出现概率与地域配额的具体数值（08-05b 明确归内容阶段）：** 各 location 的**事件类型出现概率修正取值**、**敌人模板清单**、**`eventCountLimit` 数字**，以及一个篇章途经几个 location。**结构已定案**（location 携带这三组字段，见 `systems/game-progression.md`）；**用户明确「details of event odds will be defined during content making phase」**。注意 `eventCountLimit` 与 `lifeSpanCost` 是篇章时长的两个互相约束的旋钮，须一同反推。→ `systems/balance.md`、`systems/game-progression.md`。

## 元进程持久化与内容开关

- **元进程持久化字段结构：** `PlayerPower` / `PlayerItem` / `Achievement` / `GameSetting` 语义已澄清、服务归属已定（profile-service）、文档落位已定；但**各自字段 schema 与解锁 / 获取 / 失去触发**待定（`AccountInfo` 已于 08-16 收口，见 `systems/player-profile/account-info.md`，仅余合规字段待后端）；`status`（启用 / 禁用）与「拥有 / 失去」两态的存档表达未定。→ `systems/services/profile-service.md`、`systems/player-profile/`。
- **PlayerPower 获取 / 失去触发与公平性：** 方向已定为**轻度提升、PvE-only 可容忍**，且**道统残卷已给出一条获取渠道**（Finale 胜利时掷定并即时发放的概率掉落，规则已定案，见 `systems/player-profile/player-power/_index.md`）；具体在哪些 AdventureEvent 获取 / 失去、是否影响 cycle seed / 计分公平仍待定。→ `systems/player-profile/player-power/`。
- **capability flag 的叠加 / 冲突规则：** 两个 power 授予同一 flag 如何处理；多个 modifier 作用于同一 key 的**运算顺序**（加法先于乘法？声明序？优先级字段？）。→ `systems/player-profile/player-power/common-properties.md`。
- **AchievementManager 的触发采集面：** 成就进度靠订阅 EventBus 被动采集（解耦但易漏）还是各服务主动上报（可靠但反向依赖）？→ `systems/services/profile-service.md`。
- **GameSetting 的设备本地项 vs 账号级项切分：** 画质 / 震动等设备强相关设置是否应留在本地 `user://` 而不上行云端。→ `systems/player-profile/game-setting.md`。
- **disabled 条目被存档引用时的 UX：** 读取侧不过滤故存档能正确解析；但玩家手中一张「已被线上关闭」的卡 / 道具是否应有提示，还是完全静默照常可用？→ `systems/services/content-service.md`、`ux/`。

## UX 呈现细节（随内容一同搁置）

- **英文占位符的具体形态与错误文案的实际措辞（08-12 新增 · 08-13 缩范围）：** 「全库 UI 文案走翻译键、中文为默认与优先制作列、**英文列全部预设占位符**」已定；占位符取键名本身、`TODO` 还是机翻初稿未陈述，各 `ERR_*` 与四条兜底文案的**逐条中文措辞**同属文案定稿。**范围仅剩 `res://text/` 的 CSV 一侧**——内容层一侧已于 08-13 答定为「**缺 `en` 键即未翻译**」，由静默回落承接。定下来时须回看覆盖率审计：**若取键名本身，`AuditTranslations()` 得能识别它，否则英文覆盖率恒读作 100%。** → `ux/error-and-blocking-ux.md`。
- **元婴界面（通关证书）的具体形态：** 用途已定（读取并显示最终寿元）；展示哪些字段（最终寿元、用时、修行历程摘要、成就？）、何时弹出、能否回看 / 分享未定。→ `ux/screen-flow.md`。
- **寿元告警是否伴随音效 / 震动：** 视觉形态已定（**静态标注于 EventOption 选择界面**）；是否附加听觉 / 触觉反馈未陈述。→ `ux/screen-flow.md`。
- **战斗屏幕的其余形态：** 出牌手势（拖拽 vs 点按）、目标指定、手牌布局、回合节奏与动画时长、竖屏下的敌我分区、**敌方出牌的呈现方式**（敌人也持有卡组）、**战后奖励面板的形态**（强制项与可选项如何同屏区分、候选数量与竖屏排布、能否反悔）、**stack 是否需要进入呈现层**（响应窗口移除后读栈不再是决策必需，与「栈深何时 > 1」绑定）、**三步结构的呈现细节**（开始阶段的 mana 刷满 / 抽牌节拍、结束阶段的回合内状态消散、"轮到谁"的常驻指示）——待后续战斗 UX 专场。→ `ux/combat-ux.md`。（注：**信息面**在 08-15d 意图机制整条移除后收敛为**敌人图鉴（事前）+ 结算 ticker / 战场（战斗内）**，「意图三档 + 探查 + 图鉴」三通道的旧表述作废；**主视觉**已在 08-01 定案为「双方道念对比」、lifeTotal 退居次要。二者的残留细节留在焦点区 ①。）
- **道念对比的视觉形态与 lifeTotal 在战斗屏的位置：** 主视觉地位已定；用什么形态（左右对比条 / 双数值 / 天平隐喻）、道念变化的反馈、「道念差」是否显式呈现、以及 lifeTotal 是否仍常驻显示（作为「失败会掉多少」的参照）均未定；**「还剩几回合」的呈现**（定长 10 回合的连带）亦未定。→ `ux/combat-ux.md`。

## 美术与音频（`art/` · 08-04 立起脚手架，内容待填）

> 结构已立（**两个一级分区** `art/visuals`（含子分区 `animations/`）· `soundtracks`），流水线已定（vision + 参考 → AI 写 guide → 投喂生成工具）。以下为随之而来的待答项；美术推进归开发路线的靠后阶段，故与内容充实一同搁置。Source: `../handoffs/2026-08-04-art-audio-library-scaffold.md`。

- **音频生成工具的最终定案：** 方向**倾向 Suno**（08-04 给出）但**未拍板**。定案前 audio guide 可暂按 Suno 形态组织，但**工具专属语法不写死进模板**，prompt 正文保持工具无关。→ `art/soundtracks/_index.md`。
- **guide 的粒度：** 一个内容条目一份 guide，还是一个类目一份 guide + 逐条目只填变量？后者风格更稳、表达力更弱。→ `art/visuals/_index.md`。
- **生成资产落地 `game-feature-branch/` 的命名与导入规则：** 文件名如何与内容条目的 `Id` 对齐、目录如何划分、是否需要 asset 清单做「内容条目 ↔ 资产」完备性校验。→ `art/*/guides/_TEMPLATE.md` 的「交付」栏。
- **参考素材的二进制是否入库：** 本库是纯文档孤儿分支；图片 / 音频文件放进 `art/**/references/` 会让分支变重且 git 历史不可压缩。暂定「只登记来源与描述」。→ `art/*/references/_index.md`。
- **`visuals/animations/` 的范围与技术载体：** 卡牌特效 / 立绘动效 / UI 转场 / 战斗反馈分属不同技术路径（`AnimationPlayer` / 骨骼 / 粒子 / shader，后者受 GL Compatibility 限制）；且**动画时长直接吃篇章目标时长预算**，须可跳过 / 可加速。待咨询专业人士；其内部结构（是否需要 `animation-direction.md` 等）亦待彼时设计。→ `art/visuals/animations/_index.md`。
- **AI 生成资产的商用授权与参考素材来源合规口径：** 生成工具的商用条款、参考素材的版权边界。游戏是要发行的产品，迟早需要明确立场。→ `art/_index.md`、`vision/scope.md`。
- **各方向文档的实质内容整体待写：** `art-direction.md` 的色彩 / 光照 / 构图 / 尺寸格式、`audio-direction.md` 的配器 / 调式 / 混音 / 预算、两侧的禁用清单——目前均为 `> _..._` 占位。
- **UI 元件是否走 AI 生成：** 九宫格拉伸、状态变体、图标一致性与整图生成的特性冲突，可能需另一条制作路径。→ `art/visuals/_index.md`。
- **境界晋升是否改变角色 / 敌人外观：** 直接决定同一角色需要 1 套还是 4 套资产，影响总资产量级。→ 同上。

## 尚未设计（占位，暂无具体问题）

- 以下主题文档仍是空占位或仅有骨架，尚无成形问题，待各自专场 handoff 播种：
  - 角色档案：`systems/character-profile/item/`（`deck/` 已有骨架，具体卡牌机制仍空）。
  - 玩家档案：`systems/player-profile/player-item/`、`account-info.md`、`game-setting.md`（`codex/` 已于 07-30b 播种，问题见焦点区 ①）。
  - 事件内容：`systems/adventure-event/` 除 combat 之外的四类子类型（Exchange / Research / Explore / Travel；combat 已于 07-30b 开过第一场）。

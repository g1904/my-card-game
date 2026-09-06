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
- **数值标杆的取值（08-02 定归宿 · 由焦点区移入）：** **卡牌产 / 削道念的量纲基准**（一张牌该产多少、一场内总产出相对 `baseMomentum` 的倍数、是否有道念相关的状态与倍率）与**回寿量三档的绝对点数**（标定口径 5% / 10% / 20% 已定，ch1 折算为 50 / 100 / 200，ch2 / ch3 随本章可用预算浮动；**折算不构成定案**，三档点数与每章回寿事件次数仍欠取值），**留待内容扩充后的统计校准**——内容铺开且游戏可运行后由实测样本定出，归开发路线第 ③ 阶段；切入点是设计起始角色 starter deck 的过程。**并且优先打磨 ch1 内容。** **形状先于数值**：越级追分的量化形状已由 `systems/balance.md` 的形状锚点框住（一档层数差的产出差 ≈ 一档 `diff` 的 `baseMomentum` 落差，粒度为整副卡组），本条只欠取值、不欠形状。**卡牌产 / 削道念的量纲基准同时是 `lossPerMomentum` 的 ch2 / ch3 系数反推的前置**——典型道念差的分布定不下来，那两个系数就无从标定。→ `systems/balance.md`、`systems/character-profile/deck/`、`systems/character-profile/life-span.md`、`vision/scope.md`。
- **平衡数值整体：** ante / 篇章缩放、掉落权重、成本档位、奖励曲线。**blind / ante 缩放曲线本身尚未陈述**（进程语义见 `systems/game-progression.md`，一旦落定数值归此）。→ `systems/balance.md`。
- **重试上限两档数值是否随实测再调（08-16b 采集 · 轻）：** **落点已定**——两行住在平衡资源、由 `HasPremiumBundle` 选行，故它已是可调平衡项；待定的只有**数值本身**。→ `systems/balance.md`、`systems/services/life-cycle-service.md`。
- **事件出现概率与地域配额的具体数值（08-05b 明确归内容阶段）：** 各 location 的**事件类型出现概率修正取值**、**敌人模板清单**、**`eventCountLimit` 数字**，以及一个篇章途经几个 location。**结构已定案**（location 携带这三组字段，见 `systems/game-progression.md`）；**用户明确「details of event odds will be defined during content making phase」**。注意 `eventCountLimit` 与 `lifeSpanCost` 是篇章时长的两个互相约束的旋钮，须一同反推——**ch1 已有反推产出：一章途经 4–5 个 location、每个 `eventCountLimit` ≈ 4–5**（25 个批次中 4 个是不占配额的 Travel ⇒ 计入配额 21 个，见 `systems/balance.md`）；ch2 / ch3 仍归内容制作阶段。→ `systems/balance.md`、`systems/game-progression.md`。

## 元进程持久化与内容开关

- **元进程持久化字段结构：** `PlayerPower` / `PlayerItem` / `Achievement` 语义已澄清、服务归属已定（profile-service）、文档落位已定；但**各自字段 schema 与解锁 / 获取 / 失去触发**待定（`AccountInfo` 已于 08-16 收口，见 `systems/player-profile/account-info.md`，仅余合规字段待后端；`GameSetting` 与图鉴族的字段 schema 已各自收口，见 `systems/player-profile/game-setting.md` 与 `systems/player-profile/codex/common-properties.md`）；`status`（启用 / 禁用）与「拥有 / 失去」两态的存档表达未定。**⚠ 本次对账查出一处矛盾，待用户确认：** `systems/character-profile/power/_index.md`、`systems/character-profile/item/common-properties.md`、`systems/player-profile/player-power/common-properties.md`、`systems/player-profile/codex/common-properties.md` **四处**都把这一格登记为未决并回链「`profile-service.md` 的同名待决项」，而 `systems/services/profile-service.md` 的待决小节里**没有该条**、反而在同一小节明写「`PlayerPower` / `PlayerItem` 的持有条目形态——含 `status` 与「拥有 / 失去」两个正交维度的存档编码——**均已成文**」。⇒ 四处悬空回链对一处「已成文」宣告。若确已成文，本条应整条移出；若未成文，`profile-service.md` 的那句括注须改。→ `systems/services/profile-service.md`、`systems/player-profile/`。
- **PlayerPower 获取 / 失去触发与公平性：** 方向已定为**轻度提升、PvE-only 可容忍**，且**道统残卷已给出一条获取渠道**（Finale 胜利时掷定并即时发放的概率掉落，规则已定案，见 `systems/player-profile/player-power/_index.md`）；具体在哪些 AdventureEvent 获取 / 失去、是否影响 cycle seed / 计分公平仍待定。→ `systems/player-profile/player-power/`。
- **`PlayerItem` 的种类目录、次数补充机制与可购价格 / 库存：** 战斗内形态（`CardType.Item`）、`Charges > 0` 硬约束、次数即时写 PlayerProfile、**战斗外的效果形态**（内容侧 `ProfileChangeSpec` 模板 `OutOfCombatUseOutcome`，权威在 `systems/character-profile/item/_index.md`）均已定；**目录、次数如何补充、价格 / 库存权重**仍未设计。→ `systems/player-profile/player-item/`。
- **AchievementManager 的触发采集面：** 成就进度靠订阅 EventBus 被动采集（解耦但易漏）还是各服务主动上报（可靠但反向依赖）？→ `systems/services/profile-service.md`。
- **disabled 条目被存档引用时的 UX：** 读取侧不过滤故存档能正确解析；但玩家手中一张「已被线上关闭」的卡 / 道具是否应有提示，还是完全静默照常可用？→ `systems/services/content-service.md`、`ux/`。

## UX 呈现细节（随内容一同搁置）

- **各 `ERR_*`、四条兜底文案与 `reasonKey` 二级措辞的逐条中文文案（08-12 新增 · 08-19 缩范围 · 本次并入 `reasonKey` 一条）：** 三者结构、键形态、机械变换与兜底规则均已定，三处 `reasonKey` 的取值集合也已由后端契约填表；**仅剩逐条中文措辞待文案定稿**，属内容充实，不阻塞结构落地。（未翻译的英文形态已答定为「`en` 单元格留空 + `fallback = "zh"` 回落」，覆盖率由 `TranslationAudit.AuditCoverage()` 独立入口审计。）→ `ux/error-and-blocking-ux.md`。
- **寿元余量跌破低位时是否伴随音效 / 震动：** 视觉形态已定（余量明文常驻于 EventOption 选择界面的角色状态条、恒精确）；是否在跌破低位时附加听觉 / 触觉反馈未陈述。→ `ux/screen-flow.md`。
- **战斗屏幕的其余形态：** 手牌布局、回合节奏与动画时长、竖屏下的敌我分区、**敌方出牌的呈现方式**（敌人也持有卡组）、**战后奖励面板的形态**（强制项与可选项如何同屏区分、逐项列表的竖屏排布、已领取 / 已跳过两态的视觉处置；交互已定为逐项领取 / 跳过且不可反悔）、**stack 是否需要进入呈现层**（响应窗口移除后读栈不再是决策必需，与「栈深何时 > 1」绑定）、**三步结构的呈现细节**（开始阶段的 mana 刷满 / 抽牌节拍、结束阶段的回合内状态消散、"轮到谁"的常驻指示）——待后续战斗 UX 专场。→ `ux/combat-ux.md`。（注：**信息面**在 08-15d 意图机制整条移除后收敛为**敌人图鉴（事前）+ 战报 / 战场（战斗内）**，「意图三档 + 探查 + 图鉴」三通道的旧表述作废；**主视觉**已定案为「双方道念对比」，寿元不常驻战斗屏。二者的残留细节留在焦点区 ①。）
- **道念对比的视觉形态：** 主视觉地位已定；用什么形态（左右对比条 / 双数值 / 天平隐喻）、道念变化的反馈、「道念差」是否显式呈现均未定（后者的支持论据因 `lossPerMomentum` 而弱于逐点对应——各章需乘一个不同的篇章系数，**ch1 = 10 已锁定、ch2 / ch3 的候选值 5 / 10 尚未定案**）；**「还剩几回合」的呈现**（定长 10 回合的连带）亦未定。（寿元不常驻战斗屏、结算面板如实展示扣减量与扣后余量，已答结。）→ `ux/combat-ux.md`。

## 美术与音频（`art/` · 08-04 立起脚手架，内容待填）

> 结构已立（**两个一级分区** `art/visuals`（含子分区 `animations/`）· `soundtracks`），流水线已定（vision + 参考 → AI 写 guide → 投喂生成工具）。以下为随之而来的待答项；美术推进归开发路线的靠后阶段，故与内容充实一同搁置。Source: `../handoffs/2026-08-04-art-audio-library-scaffold.md`。

- **BGM 时长与码率的包体预算（本次归集 · 此前只在「移动端约束」里作为一句「预算未定」存在）：** 六个音频类目各需多少条、单条多长、以什么码率打包，须与初装包体预算一同定；**预算本身尚未给出**。→ `art/soundtracks/_index.md`、`vision/scope.md`。
- **三条音量轨默认值的实测校准（本次归集 · 此前未进清单 · 轻）：** `100 / 80 / 100` 的**相对关系有依据**，绝对值待真机与响度目标定稿后校准。形态已定，只欠取值。→ `systems/player-profile/game-setting.md`、`art/soundtracks/_index.md`。
- **音频生成工具的最终定案：** 方向**倾向 Suno**（08-04 给出）但**未拍板**。定案前 audio guide 可暂按 Suno 形态组织，但**工具专属语法不写死进模板**，prompt 正文保持工具无关。→ `art/soundtracks/_index.md`。
- **guide 的粒度：** 一个内容条目一份 guide，还是一个类目一份 guide + 逐条目只填变量？后者风格更稳、表达力更弱。→ `art/visuals/_index.md`。
- **生成资产落地 `game-feature-branch/` 的目录划分与完备性校验：** 目录如何划分、是否需要一份 asset 清单做「内容条目 ↔ 资产」的完备性校验。**资产寻址不在此列**——内容条目经共有字段 `Artwork : Texture2D` 直接引用资源，寻址不依赖文件名与 `Id` 的命名对齐，故本条已不阻塞字段落地。→ `art/*/guides/_TEMPLATE.md` 的「交付」栏、`systems/common-properties.md`。
- **参考素材的二进制是否入库：** 本库是纯文档孤儿分支；图片 / 音频文件放进 `art/**/references/` 会让分支变重且 git 历史不可压缩。暂定「只登记来源与描述」。→ `art/*/references/_index.md`。
- **`visuals/animations/` 的范围与技术载体：** 卡牌特效 / 立绘动效 / UI 转场 / 战斗反馈分属不同技术路径（`AnimationPlayer` / 骨骼 / 粒子 / shader，后者受 GL Compatibility 限制）；且**动画时长直接吃篇章目标时长预算**，须可跳过 / 可加速。待咨询专业人士；其内部结构（是否需要 `animation-direction.md` 等）亦待彼时设计。→ `art/visuals/animations/_index.md`。
- **AI 生成资产的商用授权与参考素材来源合规口径：** 生成工具的商用条款、参考素材的版权边界。游戏是要发行的产品，迟早需要明确立场。→ `art/_index.md`、`vision/scope.md`。
- **各方向文档的实质内容整体待写：** `art-direction.md` 的色彩 / 光照 / 构图 / 尺寸格式、`audio-direction.md` 的配器 / 调式 / 混音 / 预算、两侧的禁用清单——目前均为 `> _..._` 占位。
- **UI 元件是否走 AI 生成：** 九宫格拉伸、状态变体、图标一致性与整图生成的特性冲突，可能需另一条制作路径。→ `art/visuals/_index.md`。

## 尚未设计（占位，暂无具体问题）

- **仍有一处「空占位」文档（09-05 核对，推翻 08-30 的「已不再有」措辞）。** 原登记的两处中，`achievement/` 确已成文、欠的是具体子项；`player-item/common-properties.md` 则仍是占位：
  - `systems/player-profile/player-item/common-properties.md`：**⚠ 本次对账订正（此前本条写的是「已写出机制面、仅欠 `status` 编码」，与该文件自陈不符）。** 该文件的待决小节自陈「共有字段未定案……目前均为占位，无实质设计」——写出 `ItemId` / `Charges` / `SourceCode` 三格的是**角色层**的 `systems/character-profile/item/common-properties.md`，两份此前被混为一谈。账号层这份欠的是**整份共有字段面**（稳定 `Id` / 显示字段 / 次数上限 / 效果定义 / 价格与库存权重），不止 `status` 一格。
  - `systems/player-profile/achievement/`：`_index.md` 与 `common-properties.md` 均已成文（分组、两档奖励机制、成就限定条目防落空）；**仍待定的是条目 schema 与进度模型**。
- **本区已不再适用的占位登记（本次清理）：** `account-info.md`（08-16 收口，仅余合规字段待后端分级）· `game-setting.md` 与 `codex/common-properties.md`（08-19 双双收口）· `systems/adventure-event/` 的四类非战斗子类型（Exchange / Research / Explore / Travel **机制面已于 08-17 全部收口**）——它们均已有成形设计，欠的是**条目目录与数值**，见上方「内容目录与数值」。

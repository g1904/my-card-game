# 待答清单更新日志

> 每次 `/analyze-new-ideas` / `/summarize-open-questions` 运行后，在此**顶部**追加一条更新摘要：本次答结了什么、推翻了什么、新增待答落在哪个分片。问题条目本身在 `../open-questions.md` 的各分片里；已答定问题的逐条移出记录在 `../answer-logs/`。
>
> 本文件只记「发生了什么变化」，不承载问题条目本身。

## 2026-08-16（体检 12 项逐条裁决 · 手牌上限 9 → 7）

输入 `inbox/draft-0815c.md`；产出 `handoffs/2026-08-16-design-audit-adjudication-and-hand-limit.md`。移出记录见 `../answer-logs/log-0815c.md`。

**① 08-15d 体检遗留的 12 条待答项由用户逐条裁决**：8 条答结移出 · 1 条部分答结 · 1 条确认排期后留在清单（**竖屏分区与「栈是否必须常驻」，确认单开一场专门 session**）· 2 条未触及（processor/handler 五级层级词、其余非体检项）。**新增待答 1 条**（`IgnoresProtection` 频次上调牵出的「失去法则」三支频次预算配平，落 `06-meta-progression.md`）。

**② 六条判「不是过度设计」，原样保留并补写此前未落纸的设计初衷。** 这是本次最有价值的产出——这些结构此前之所以显得可疑，是因为**它们的设计意图从未被写下来**，而不是因为它们真的过度：

- **道统残卷** = **分发账户级加强的核心算法**，「不给玩家任何提示」是设计初衷而非疏漏；「玩家学不到 ⇒ 设计失败」这一前提不适用，因为**它本就不打算被学到**。⇒ 不减档、**不做任何形式的进度可感化**（可感化会把它变成可优化对象，直接抵消设计目的）。
- **隐藏属性 12 档** 有真实消费者：**所有事件都有可能推拉这三个属性，不限事件类型**。另裁定硬度 = **允许携带，不强制**（不填 = 不推）。「文案只挂四档」同样是正面的设计意图——它**依赖玩家对修仙题材的基础设定认知**（道心低了会入魔、煞气高了会反噬），**中间档的沉默不是信息缺口，是常识已经填上的部分**。
- **D2 决策点保留**：预写的「第一刀砍 D2 的 push」作废——它兑现的是「退出重进得到同一局面」，在强制在线 · 云端权威下是玩家对存档的基本信任，不是可牺牲的性能余量。
- **挂起态 / 选目标态 UX 整套保留**：它服务的是本作少数几个真正的战斗内交互时刻，**密度低正是它有分量的原因，不是削减理由**。
- **`itemPowerRatio` 四档折价**与战斗内法则的强度上沿同属**暂定平衡机制的软标准**——本就不声称是精算结果，作用是在量纲出现之前给内容侧一个相对刻度。
- **meta 层**：设计密度远超实现进度是**已知且接受**的状态，**不中断设计去先落最小可跑的战斗回路**。

**③ 两条判「确有问题」，当场改掉。**

- **战斗内法则 ≤10% / ≤25% 闸门降格**：两个数保留，但从「难度曲线按老账号全开校准的**可执行形态**」改写为**内容评审参考上沿**，并明写**不得被引用为任何设计的承重依据**；承重的只剩定性定位那一条。**不补代理指标**——代理量与真实量之间的偏差同样不可验证，等于用一个新的不可验证换掉旧的。
- **`IgnoresProtection` 两侧都动**：编排规则 **R1–R5 五条砍到 2 条**（只留两条硬准入：仅挂 boss 档载体 · 绝不挂玩家可主动获取的内容）+ 目标频次 **1% → ≈5%**。**承重连带：随 R3 删掉 `CycleState` 上那个轮回级 bool ⇒ 该机制在代码侧再无落点，完全退回内容编排层。**

**④ 顺带简化：带内分布权重表三段合并为一张 5 档表。** 意图移除后早 / 中 / 末段的分辨率没有消费面，且分段在 ch2 · ch3 本就天然粗、承诺的「分布右移」从未兑现；**删掉分段同时删掉一处状态读取**（赋级不再需要知道角色在本境界内的等级位置）。`±2` 带 / 批内去重 / 截断重分配 / PlotManager 调制修正**全部保留**，「篇章尾部变险」改由规则单独承载。

**⑤ ⚠ 非体检项的连带定案：手牌上限 9 → 7。** 它**推翻了 `balance.md` 原写下的否决论据**「取 7 会让上限成为常态惩罚」——否决理由不是错了，而是**那个后果本身被接受为新的设计取向**。08-03 推论 ③ 的承重语义随之改写：手牌上限由「逼玩家出牌腾位的**节奏约束，不是惩罚**」改为「**会真实咬合的紧约束**」（起手 4 + 每回合抽 2 ⇒ 第 2 回合即 8 > 7）。**满手抽不进 / 纯上界 / 不产生弃牌堆流量三条规则形态完全不变**，变的只是咬合频率。连带复检 `itemPowerRatio` 中「不占手牌位 ×1.10」这项溢价（占位在紧约束下是更真实的成本）。

**⑥ 两处死结构确认已删**（`DrawCountsAsLoss` / `CombatOutcome.Fled`，08-15d 已执行），本次只清掉三处残留的「已于 08-15d 删除」考古注释。

**⚠ interview 五项**（手牌上限 7 的承重语义 / 法则闸门改法 / `IgnoresProtection` 精简侧 / 赋级简化范围 / 「所有事件都可推拉」的编排硬度），全部由用户裁决。**不 bump schema · 对后端库零影响。**

**⑦ 顺带修正两处台账漂移**：`inbox/_index.md` 仍把 `draft-0815c.md` 记为「空白，与 `_TEMPLATE.md` 逐字相同」（实际已写入内容）· 08-15d 声明法则闸门那条去向 `07-codex-monetization.md`，但**从未真正落进该分片**（只留了 `balance.md` 的行内标记，本次随答结一并清理）。

## 2026-08-15d（敌人意图整条移除 · 寿元成本按告警档展示 · 全库过度设计体检）

输入 `inbox/draft-0815b.md`；产出 `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md`。移出记录见 `../answer-logs/log-0815b.md`。

**① 敌人意图机制整条移除（承重 · 推翻意图族全部定案）。** 三档揭示与 `IntentRevealTier` · `IntentCategory` 枚举与 `AbilityData` 上的必填标注 · 20% 贡献阈值归桶 · 主类别并行陈列 · 回合级综合描述 · 快照语义（公布不重算 / 不保证与执行一致）· 全套「预估 vs 实际」呈现装置（`≈` 前置 + 虚线底纹 + `≈12 → 8` 对照 + 那一拍 0.4 s 不可加速）· 意图区（≈ 屏高 8%）· **探查 probe 通道**，**全部作废**。
**依据不是新论点，是把库内已分散写下的五条自述放在一起读**：ch2 · ch3 约五分之二的同阶遭遇完全无信息 · `diff = 0`（分布众数）三章恒为最低档 · 「意图揭示不再承担教学职能」已是既定推论 · 完整档在 ch1 玩家未必读得出因果 · `Special` 是有膨胀风险的兜底桶。**即它在中后期给出的信息与移除后相差无几，而成本需完整支付。**

**② 可读性的六条替代通道（承重）。** 逐步执行呈现（飘字 + ticker）· 敌人图鉴 · 战场 · 埋伏计数 · 敌人精确等级 → `baseMomentum` 起跑线 · 道念对比 + 剩余回合数。其中两条**升格**：**逐步执行呈现由辅助手段升为硬要求**（原理由「偏差必须可解释」换成「敌人回合是玩家获取动态情报的唯一时刻」）· **敌人图鉴由补充通道升为事前知识的主通道**。
**⚠ 已知代价明写接受：** 本作已于 08-02b 移除交互与优先权，故敌人回合是**信息与交互双零**的一段观看——**与 MTG 的差别正在此处**（MTG 里「打出的牌就是足够信息」成立的前提是玩家能响应）。该点已在 interview 中向用户点明，用户仍裁定移除。

**③ 三处承重论据改挂，定案全部不变。** 精确标注敌人等级 → 改挂「**看到等级即看到起跑线**」（原「玩家因此理解意图为何被遮蔽」作废）· 境界名展示措辞 → 改挂「**境界名让 `baseMomentum` 的跨度断层可读**」（32 → 45 是量级跳变，「17 vs 18」看不出来）· `EncounterScopes` 共享池 → 论据**不但不作废反而加强**（图鉴成主通道后「先遇见、再对上」更值钱）。

**④ 四处连带修正。** **EnemyManager 的「回合级一次性规划」约束解除**（其唯一存在理由是「呈现意图时整套出牌必须已定」；AI 可逐张决策，**不重新引入交互**——敌人回合在玩家回合之后，玩家无输入窗口）· **Finale 压迫由四重降三重** ⇒ 实际难度下降一档 ⇒ `WinMargin` 成为**双向**第一旋钮（获得上调余量）· 埋伏的「双向对称」去掉对照物 · `systems/architecture.md` 的 processor 校准样本删掉「意图生成」一项。**竖屏因此释放约 8% 屏高，并少一处每回合两次的意图区切换动画。**
**⚠ 一处自我订正：`MomentumDelta` 四字段一个不动。** `Declared` 在 `combat-service.md` 的定义是**单次结算的效果标称量**（`Declared − Actual` = 被下限 0 吞掉的溢出量），与 `combat-ux.md` 曾挂上去的「意图声明值」**同名不同物**；作废的是那句挂错对象的呈现要求，不是字段——且它随逐步呈现升为硬要求而**更重要**。两处文档已写明防再次误读。

**⑤ `selectCost` 改为只在寿元 Band 2（< 10%）如实展示精确扣减量**，Band 0 / Band 1 完全不显示。**推翻 08-06c 推论 ③ 的「必须如实展示」。**
形态上**不是新机制**：给 08-12d 的隐藏属性档位表**加第五个消费方**（原有四个：eventOptions 调制 / 剧情线触发 / 跨档叙事 / 寿元红字标注），判据同为「寿元 Band == 2」，**与红字数值倒数同一个开关、同时开启** ⇒ 不新增字段、不新增流程、不 bump schema。
**起因是草稿的前提在寿元上本就有例外**——「隐藏属性只给方向不给数字」这条纪律，寿元 Band 2 的「标红精确数值倒数」早已是明写的例外，寿元是三个隐藏属性里**唯一有精确显示通道**的那个。故问题不是「显不显示」而是「从哪一档开始显示」，而这张表现成可挂。
**08-06c「明知是死路仍然走」不作废，只收窄到它真正起作用的区间**（真正的死路判断只发生在寿元濒尽时）。**已知代价**：「省着花有跨篇章回报」在常态档不可被精细执行——与既定的「eventOption 卡片不标经验数字、给方向不给数字、不可电子表格化优化」是同一条纪律的第二个实例。**退让位**（实测调整，非重新裁决）：给 Band 1 补定性档位标签，仍不给数字。

**⑥ 全库过度设计体检 14 项（草稿第三项的产出）。** **两处可确证的死结构本次直接删除**：`DrawCountsAsLoss`（三档取值恒 `false`，按库内既有判据「**单一取值的维度不是维度**」）⇒ `VictoryRule` 收为单字段 `(int WinMargin)`；`CombatOutcome.Fled`（全库无任何逃跑 / 撤退机制，是 07-27b 契约草稿的残留）⇒ 收为三值——**两者行为完全等价**。
**其余 12 项一律登记为待答项、不裁决其设计取向**：道统残卷的可验证性（不可见 + 高复杂度）· 隐藏属性 12 档当前没有消费者（定案时序，**不主张砍档**）· 决策点密度 ≈ 31 / 场 · 挂起态整套 UX 与其频次（≤ 10% 异能、1~2 次 / 场）· `itemPowerRatio` 四档折价（三个凭空系数相乘，前置尚无量纲）· 战斗内法则 10% / 25% 闸门（自承不可机械校验，落纪律阶梯第 4 级却被当承重结论）· `IgnoresProtection` ≈1%（五条编排规则 + 一个存档 bool，换来每 3 轮回撞 1 次）· 竖屏分区（根子是 MTG 分区模型；**栈在零交互下玩家只能看**，是否必须常驻）· ±2 带的分布权重表可否简化（`diff` 消费点已减为一个）· processor / handler 两级是否过早 · **meta 层：190 余份文档 · 91 份 handoff · 0 行代码 · 0 份 FR，大量精算结论在跑起来之前无法证伪**。

**⚠ interview 四项**（意图去留 / `selectCost` 分档 / 体检产出落点 / 探查处置），全部由用户裁决。
**答结 4 条 · 收窄或因前提消失 5 条 · 新增待答 12 条**（`01-combat.md` 6 · `04` 1 · `05` 2 · `06` 1 · `combat/_index.md` 2）。**不 bump 存档 schema · 对后端库零影响。**



## 2026-08-15c（事件类型收为五类 · 批次形状 · Travel 80/20 · 寿元定价归属）

- **整条答结 6 条**：
  - **九类分类法是否重构 / ADR-0002 补订**（③）→ 整体收为**五类**（Combat / Exchange / Research / Explore / Travel）；Explore / Travel 随重写正式入枚举，「补订」这条待办消失。归档去向：`decisions/ADR-0002`（整份重写）、`systems/adventure-event/_index.md`、`terminology.md`
  - **Mystery 可被遮罩的子类型范围**（③）→ Explore 继承元类型语义，真身取值域 = Combat / Travel / Exchange（不含 Research、不嵌套自身）。归档去向：`systems/adventure-event/explore/_index.md`
  - **每批 eventOptions 的数量**（②）→ 常态 3、区间 1–5。归档去向：`systems/adventure-event/common-properties.md`、`systems/services/future-event-service.md`
  - **Travel 闸门给几个候选、怎么选**（②）→ 80 / 20 掷定，常规与闸门一律适用，Explore 揭示出的必为随机。归档去向：`systems/adventure-event/travel/_index.md`、`systems/game-progression.md`
  - **成本类型的 element 清单 / `CostKey` 其余成员**（②）→ 成本侧只有 `lifeSpanCost`；复合形态保留不塌缩。归档去向：`systems/adventure-event/common-properties.md`
  - **开局强制构筑事件归哪一类**（② · 标记「阻断内容编排」）→ 归 Research，不需要第六类。归档去向：`systems/adventure-event/research/_index.md`
- **部分答结 / 收窄 5 条**：生成 / 加权规则（数量与重算依据已定）· `lifeSpanCost` 分档表（表的形态已定、取值待定）· 资源打穿（收窄为纯寿元的钳制规则）· 「余额不足即拒」（收窄为只剩 Exchange 商店购买）· `EventOption` 物化字段清单（新增两个待定项）。
- **因前提消失而作废 3 条**（非答结）：Practice 的风险 / 回报差异 · Finale 的独立胜负条件 · Mystery 的揭示权重——三条的措辞都建立在「它们是独立 `eventType`」之上；实质内容已在 08-02 / 08-06d / 08-09b 定案并原样保留（改挂 `combatTier`），剩余未定部分改写为「`Practice` / `Finale` 档的奖励厚薄」与「Explore 揭示池的权重」。
- **新增待答 6 条**：`02-event-options.md` **4**（Explore 揭示池权重 · 遮罩下的 `selectCost` 呈现 · Travel 常规出场概率与 80/20 可否被剧本调制 · 五类配比与 `combatTier` 三档配比）· `03-adventure-event-types.md` **2**（NPC / 势力模型是否仍需要 · `manaLimit` 下降的承载点）。
- **⚠ 承重连带：`pastEvent` 从历史记录升为产出侧的一等输入。** schema 不变，但每批 eventOptions 都要读它 ⇒「痕迹必须完整可靠」的重要性再抬一级；同时坐实 future-event-service 是**无记忆的纯产出侧**（不持有跨批次状态）。
- **⚠ 顺带修正一处既有漂移：** `adventure-event/common-properties.md` 的目标时长仍写 15–30 / 15–30 / 20–40，与 `balance.md` 的 08-01b 值不一致，已对齐为 30–40 / 35–45 / 45–55。
- **Practice / Finale 降格为 `combatTier { Practice, Standard, Finale }`**（对位 small / big / boss blind）：既有定案**全部原样保留**（8 / 10 / 12 回合 · `WinMargin` · 天劫 Enemy · `±2` 带 · 一篇章一个 Finale · 残卷规则），只是挂载点从 `eventType` 移到 `combatTier`。**它是必需的锚点不是修饰**——篇章边界 · ADR-0004 重试 · 残卷发放三处都要一个可机械判定的判据，靠内容 `Id` 识别是反模式。
- **另两处收窄**：社交语境归 Exchange · Research 收窄为「调整 / 升阶卡组」。
- **⚠ Travel 80 / 20 的 interview 裁定：两侧都不作废，而是合成一条规则**——`LocationCodex` 的路线规划价值保住、只打了折；连带定案 **Travel 不是常驻可选项**。
- **`selectCost` 复合形态保留、不塌缩为 `int` 的理由**：保留成本为零，塌缩要连改三处。
- **寿元定价改为「`eventType` × 篇章」统一定价表**（Combat 行按 `combatTier` 细分），条目默认不填——它同时缓解了既有那条「反推链是脆的」。
- **⚠ 草稿的一处前提已失效**：「余额扣减与确保可选 is messy」的前提已在 08-06c 整体消解。
- **不 bump 存档 schema；对后端库零影响。** 见 `../answer-logs/log-0815a.md`。
## 2026-08-15b（商业化整体收口：付费凭证的存档表达 · 购买形态 · 付费面边界 · UX 观感）

- **整条答结 3 条**（全部在 ⑦ 图鉴族与商业化）：
  - **premium bundle 的其余细则** → 可重复购买；① ② 每次都给、③ ④ 只在首次生效不叠加；起步单一 SKU、金额不落客户端；付费面五项明确排除 + 唯一预留纯外观 + 通行证赛季当前不做。归档去向：`systems/monetization.md`（`## 意图` + `## 决策`）、`systems/balance.md`（重试两档表）
  - **礼包持有状态的存档表达与服务端权威** → `PlayerProfile.entitlement: PlayerEntitlement`，类内只有 `BundleGrantOrdinal` 一个字段；购买段后端权威 + 兑现段客户端掷骰后端复算 + 「只在主菜单发起、待发队列为空」的时机纪律。归档去向：`systems/player-profile/_index.md`、`systems/services/profile-service.md`、`sync-service.md`、`life-cycle-service.md`
  - **商业化的 UX 观感** → 主菜单一等入口排末位 + 三条纪律；重试耗尽时提示购买明确否决；不可用置灰不隐藏 + 新立灰态判据；新增 `STORE_` 分区。归档去向：`ux/screen-flow.md`、`ux/error-and-blocking-ux.md`
- **推翻 0 条。** 不推翻任何既有决策：CAS 三分支表、「冲突以云端为准」、ADR-0003 / ADR-0004、总则 7 的本意全部原样成立。**「后端主动写入」这一新情形靠时机纪律吸收，不为它开任何机制例外**（否决为购买设计字段级三路合并）；总则 7 的「清单不得扩张」也**未被松动**，只是**预先声明**了商业化落地时 5 → 6 的一次有边界扩张，实际裁决留到那时。
- **口径收窄 1 条**：`GrantPoolMargin` 的闸 ① 由「礼包所需（1/2）+ 余量」改写为「**支撑 K 次重复购买 + 留给第 K+1 次的缓冲**」；`K` 与数值仍开放。
- **新增待答 2 条**（均落 `07-codex-monetization.md`）：`Elements` 是否一律走 modifier pipeline 的**通则**（本次只定下 `BundleGrantOrdinal` 的个案豁免）· 纯外观付费点是否真做、做成什么。
- **未触发 interview**：输入是 `/provide-solution-draft` 的产物，五处取向与一处「与既有决策的张力」已由用户于 08-15 全部按推荐裁决；本次交叉核对未发现 🔴 / 🟠。
- **存档 schema bump 一次、空迁移**（`PlayerProfile.entitlement`，老档缺字段 → `0`）。**⚠ 后端侧需另跑一次**：验票与订单幂等 · 后端主动 +1 的写入语义 · `PremiumBundle` 域复算白名单（`contracts/profile-sync.md` §5 已预留一行）· 跨设备重复到账 · 实名与退款。
- **否决 `CapabilityFlag` / modifier pipeline 承载付费凭证，判据一句话：两者都是由内容条目聚合出的派生态，而付费凭证是账号上的原始事实——派生态不能承载原始事实**（同 `FinaleWinOrdinal` 先例，故 `PlayerEntitlement` 类内只有 `BundleGrantOrdinal` 一个字段，`> 0 ⟺ 已购买`、它本身就是购买次数）。且两条通道都受 08-10c 的轮回级禁用截断 ⇒ 放进去等于在结构上给「花钱买的东西被事件拿走」留后门。
- **「后端主动写入」是同步模型此前没有的第四种情形**，它会踩中 CAS 的 `Conflict` 分支丢掉玩家刚打完的战斗。解法不需要任何新机制，只需一条时机纪律「购买只能在主菜单发起且待发队列为空」并入既有闸 ② 的前置条件表 ⇒ 冲突窗口在结构上关闭，**并使「重试耗尽时推销」在结构上不可行**。
- **③ ④ 只在首次生效、不叠加的理由：叠加 = 抹平 ADR-0004 唯一的失败压力线**；且 08-12e 的闸 ② 只有在可重复购买形态下才有真实意义 ⇒ 既有设计本就在为重复购买铺路。
- **UX 排在主菜单一等入口末位而非藏进二级面板**：藏起来会诱导出弹窗红点，那才是「付费才玩得下去」观感的真正来源；安静、永不带红点。
- 移出记录：`../answer-logs/log-monetization-entitlement-and-scope.md`。

## 2026-08-14b（`.claude/rules/*` 中设计性表述的边界判据：阈值 + 执行者）

- **整条答结 1 条**（⑤ 服务契约 / 工程侧残留）：
  - **`.claude/rules/*` 中夹带的设计性表述如何处理** → **形态合法，不瘦身到纯链接**（依据 = `knowledge/*` 主动读 vs `rules/*` 前置注入的加载模型差异），改为补上 ADR-0005 缺的第三样东西：**阈值**（投影四件套 + 七条硬边界 + 三条机械规则）与**执行者**（扩 `/sync-knowledge` 对账范围到 `rules/`，技能不更名）。归档去向：`decisions/ADR-0005-knowledge-thin-reference-layer.md`（Decision 新增「### 2. 规则层的具体形态」= 判据的**完整定义** + Consequences 两条）、`systems/common-properties.md`（「与 `.claude` 的主从关系」小节追加一段 ≤5 行**投影**，`## 待决问题` 移出该条）。
- **推翻 0 条。** 不推翻任何既有决策——ADR-0005 对 knowledge 的「只留链接」与对 rules 的「一句话 + 回链」经核是**同一条判据在两种加载模型下的两个刻度**，本次是量化而非放宽；该对照已明写入 ADR 新节节首，避免日后误读为 rules 被网开一面。
- **新增待答 1 条**（`IgnoresProtection` 频次上调牵出的「失去法则」三支频次预算配平，落 `06-meta-progression.md`）。
- **⚠ interview 一项：判据定义的落点。** 草稿步骤 1（`common-properties.md` 追加 ~10 行判据卡）与步骤 2（定义与投影二选一、两处不得各写一遍硬边界清单）自相矛盾。裁定：**定义写 ADR-0005，`common-properties.md` 只写投影 + 回链**——ADR 是这条判据的最小公共祖先（它已持有总纲那句待量化的话），且该小节现状本就是「摘要 + 完整论证见 ADR-0005」的投影形态。
- **工程层落地不在本次范围**（用户已裁定自行排期）：瘦身 6 份 `.claude/rules/*`（净减 15~20 行，含修正 `state-save-rules.md` 的 `relic` / `ante` / `楼层` 三处术语漂移与 `CycleStateManager` 归属）· 扩 `/sync-knowledge` · 空跑验证。清单见 `../inbox/archive/solution-draft-claude-rules-design-content-thinning.md`。
- **阈值的两个组成**：**投影四件套**（一句祈使 + 标识符名 + **一句代价说明** + 一条回链，缺一不可、多一即越界）+ **硬边界七条（可机械检查）**（代码块 · 表格 · 枚举 / 字段清单 · 具体数值 / 默认值 · 分支穷举 · ≥3 步流程 · 超 3 行）+ **三条机械规则**（回链直指设计库、不经 `knowledge/` 中转 · 已被纪律阶梯第 1 / 2 级强制的只留一句「由 X 强制」· 无回链即违规）。归属分类先行：讲「游戏是什么」→ 受约束；讲「代码怎么写」→ **rules 自身即权威，写多长都不算副本**；引擎 / 语言实践 → 设计库无权威。
- **纯链接为何在注入层失效**：写错代码的那一刻，往往正是「没觉得需要查」的那一刻。
- **唯一显式例外**：`design-library-routing.md` 的两库结构表标注为「路由用副本」。
- 移出记录：`../answer-logs/log-claude-rules-design-content-thinning.md`。

## 2026-08-14（共有属性的分层判据：定义在最小公共祖先，投影在各落点）

- **整条答结 1 条**（⑤ 服务契约 / 工程侧残留）：
  - **共有属性提炼粒度** → 定为一条判据而非一张归属表：定义恰好写在最小公共祖先一层，每个落点写四项投影 + 回链、不得复述定义；上移需语义同一、下沉后顶层不留摘要、单一落点的字段不进 `common-properties.md`；某层是否建档**按内容建不按对称建**。归档去向：`systems/common-properties.md`（重排为 `## 通用约定` / `## 内容共有字段` 两大节 + 判据卡 + 全量自检表）、`systems/_index.md`（收尾约定新增建档判据）。
- **推翻 0 条。** 不触及任何 ADR；07-24 那句「每一层的共有字段抽到 `common-properties.md`」经核为**措辞张力而非决策冲突**，读法定为「共有字段要显式化」而非「每层必须建档」。
- **新增待答 1 条**（`IgnoresProtection` 频次上调牵出的「失去法则」三支频次预算配平，落 `06-meta-progression.md`）。
- **连带执行**（判据的第一个执行样例）：四份 `SourceCode` 投影段压回模板——`player-profile/player-power/` · `player-profile/player-item/` · `character-profile/power/` · `character-profile/item/`。其中 `player-power/` 那段删掉的是 08-10b 的**过时表述**「没有第二个消费点：不对玩家可见 / 不进图鉴」（08-12b 已改写为「规则消费点唯一 + 非规则用途两处」），压缩顺带清掉一处漂移。
- **判据细则**：定义写在**按挂载面算**的最小公共祖先（不按「感觉有多通用」算）；**上移需「语义同一」为硬前置**（`RarityTier` vs `Tier` 不上移）· **下沉后顶层不留摘要** · **单一落点的字段不进任何 `common-properties.md`**。投影不得复述定义——两份表会各自漂移，而本库没有任何机制能发现不一致。
- **`character-profile/` 与 `player-profile/` 有意不建中间层 `common-properties.md`——结构不对称是判据的正确产物**；空壳会把本属顶层的字段吸下来复述一遍。
- **全量自检表：五个字段无一需要迁移** ⇒ 这条判据是对既成事实的追认，不是一次重构。
- **⚠ interview 一项**：草稿写「三份 `SourceCode` 投影段」实为**四份**（漏了古宝 `player-item/`），裁定四份一并压回模板；硬边界 =「本层无规则消费点」那句必须保留，删的只能是顶层已有的复述。
- 移出记录：`../answer-logs/log-common-properties-layering.md`。

## 2026-08-13（翻译键的铺开纪律；内容条目的多语言形态 `LocalizedText`）

- **整条答结 2 条**（均在 ⑤ 服务契约 / 工程侧残留）：
  - **翻译键的铺开节奏** → 没有改造期，只有一条起手纪律 + 一份横切基建 FR + 键命名规范三条 + 开放分区表十项 + `ERR_` 禁令。归档去向：`ux/error-and-blocking-ux.md`（三节新增）、`system-overview.md`（目录树展开）。
  - **内容条目自己的多语言表达形态**（该条的邻域小项） → 条目内嵌 `LocalizedText`，locale 封闭二值、overlay 可热更、缺 `en` 键即未翻译。归档去向：`systems/common-properties.md`（新增小节 + 「展示字段的归属」类型订正 `string` → `LocalizedText`）、`systems/services/content-service.md`（校验与覆盖率审计）、`ux/_index.md`（四问判据的两层对照表）。
- **推翻 0 条。** 与 08-12 / 08-12d 的既有定案全部同向；`vision/scope.md` 那处张力经核为**澄清而非冲突**（那条软约束自己写明的落法就是「让展示字符串与 id 分离」）。
- **缩范围 1 条**（`deferred-content.md`）：**英文占位符的具体形态**——内容层一侧已答定（缺键即未翻译），**范围仅剩 `res://text/` CSV 一侧**，并附一条约束（若取键名本身，覆盖率审计须能识别它）。
- **解除牵连 1 条**（④ 隐藏属性 / 剧本机制）：**剧本内容的体积与分发粒度**——语言维度已答定为不按语言分包，该条回归其原本形态「剧本树该不该按篇章分包」。
- **新增待答 1 条**（⑤）：**Godot 4.7 上 `Control` 自动翻译的默认行为**，挂在 `#if DEBUG` 实测项下同批实测，不阻塞任何定案。
- **边界：分区划的是界面，不是内容域。** `ERR_` 前缀**保留给后端 `code` 的机械像、人不得手写**（否则日后新增的 `code` 会与手写键撞进同一个键、静默显示为别处的文案），`AuditTranslations()` 相应改为**双向**。
- **否决「每语言一套 `Id`」**：撞「只改不增」· 污染抽取池权重 · 切语言使存档引用悬空。**失败语义分方向**：默认语言缺失 → `PushError`；非默认语言缺失 → 静默回落 + 一次性覆盖率审计。
- **语言范围封顶中英双语**（不设 `zh_TW`，繁体走简繁转换）⇒ locale 拼写校验可写、体积上限固定 ×2。
- **⚠ interview 两项落地裁定**：**locale 启动期单点归一到二值**（否则真机的 `zh_CN` / `en_US` 与封闭键域对不上，每条内容文案全部命中静默回落且毫无症状）· **CJK 字面量审计以 `OS.HasFeature("editor")` 守卫**（导出包里源文件扫不到）。**排期与 `DrawPool<T>` 同批。**
- 移出记录：`../answer-logs/log-translation-key-rollout-and-content-localization.md`。

## 2026-08-12f（功法 = 卡组的构筑单位；角色升格为有身份的模板）

- **整条答结 0 条。** 本次输入是一份全新概念的草稿，产出的是新设计而非对既有待答项的回答。
- **部分移出 1 条**（⑦ 图鉴族与商业化）：「`CharacterPower` 的机制细节」中的**「获取 / 失去触发」** → **起手那一份已定**（每个角色自带一个绑定神通，随开局随机角色分配给出）；**事件侧**的获取 / 失去触发与其余四项仍留在清单上。见 `../answer-logs/log-0812a.md`。
- **新增待答 7 条**：
  - `01-combat.md` **5 条** —— 功法的规模参数（一门几张 / 层数上限 / 每层替换幅度，归 ch1 数值标杆专场）· 候选里出现已持有功法怎么办 · 卡组被弃空的内容侧态度 · 功法 / 法宝三选一的 RNG 子流归属 · 敌人是否也以功法构筑卡组。
  - `02-event-options.md` **1 条** —— 开局强制构筑事件归九类中的哪一类（承载机制已定，**分类归属未定**，归 ADR-0002）。
  - `06-meta-progression.md` **1 条** —— 角色模板池的形态（池中几个 / 是否账号级解锁 / 能否重抽或指定，直接改写元进程压力模型）。
- **⚠ 推翻一处草稿原文**（非既有设计）：草稿第 1 行的「炉石竞技场式多轮择一构筑起始卡组」经 interview 作废；附带查证 —— 该说法虽写作「As said before」，但**全库检索不到任何既有记载**，它从来不是设计库中的定案。
- **本次确立的设计要点**：**功法 = 一组必须整组入组的卡牌**，卡组由若干功法构成、数量不限；带**层数 `TechniqueTier`**，**层数提升 = 整组替换为更强的一版** ⇒ 卡组规模不随层数增长，与疲劳那条压力互不干涉。**功法不是卡组的完全划分**——业障与单卡奖励作为游离散牌照常入组，既有推论 ④ 不动。
- **角色升格为有身份的模板 `CharacterData`**：开局随机分配、自带一个神通 + 两门绑定功法、每局一致。**开局构筑 = 一个强制 buff 事件**（选一门功法 + 一件法宝，各三选一，取 StS 第一章的味道；复用既有 `eventPriority = 1` + `ifMandatory`，**不新增机制**）。**弃置不设限**（绑定的两门也能弃）⇒ 卡组可被弃空，由既有疲劳规则承接。
- **定名三裁**：新概念占「功法」· `power.technique` → **`power.mystic_art`（秘术）** · 功法的等级叫**层数**而非 level。
- **不推翻任何既有 ADR 或定案。** 唯一的既有内容改写是次类型 `power.technique` → `power.mystic_art`（纯定名，不动语义与结构）。

## 2026-08-12e（账号级能力授予的候选池与排重规则）

- **答结 2 条**（⑦ 图鉴族与商业化）：
  - 「两条 PlayerPower 获取渠道的候选池与排重规则」 → **三条渠道（残卷 · 礼包 · 置换）共用一段抽取**：`AllEnabled()` → `(Kind, Scope)` → 去成就限定 → 排除已持有 → [仅置换：锚定 `Rarity`] → 按 `RarityTier` **单张共用权重表**加权抽（多条**无放回**）。**本次最大的结构性收获：「抽到重复怎么办」不是被回答的，而是被消解的**——排重发生在**取池阶段**而非掷骰之后 ⇒ 池 = 未持有集合 ⇒ 抽不出重复。而这不是本次的新选择：08-09b 的全局前置写的就是「尚未拥有的法则数 > 0 才掷骰」，它**只有在「池 = 未持有集合」时才自洽** ⇒ 既有设计早已隐含答案，本次只是把它写出来。**`HasGrantable()` ⟺ 池非空**（与全局前置是同一个判断，不是两个），`pickedPowerId` 随之有定义，**08-09b 残卷伪码就此完整可执行**。
  - 「premium bundle 随机的口径」 → 同上一段抽取；① 取 `(Power, Player)` 抽 1、② 取 `(Item, Player)` 无放回抽 2；掷骰走账号级 RNG 的 `PremiumBundle` 域。
- **部分移出 2 条**：「`RarityTier` 的分布与权重表」（**授予池那张表已定**：40/27/18/10/5；**置换池不需要权重表**；战后奖励池的三张表仍待定）· 「成就奖励的具体条目目录」（**「怎么给」已答结**——指定条目 + 成就限定，原问的「抽取是否走 `AllEnabled()` 并排除已拥有」随之消解；**条目清单仍待定**）。
- **⚠ interview 三项裁定**（两项 🔴 冲突 + 一项 🟠 含糊，草稿自陈其二）：
  - **账号级 RNG 加具名域 `AccountStream`** —— 修订 `common-properties.md` 与 `player-power/_index.md` 既定的两参数 `Hash64(AccountSeed, ordinal)` 为三参数。礼包一旦也走账号级掷骰，它必然有自己的序号 ⇒ 同一 `AccountSeed` + 同一整数 ⇒ 两条渠道共享同一随机数。**否决「给各渠道分配不相交的序号区间」**（效果相同但更脆、且区间约定不可机械校验）。
  - **闸 ① 收窄为「礼包所需 + 可调余量 `GrantPoolMargin`」** —— 草稿原写「残卷分档上限 + 礼包之和」，但 `balance.md` 的残卷三表在 `x ≥ 15` 档仍有 `Gain = +1%` / `Cap = 5%`，**残卷没有任何账号级上限**，且「池取尽 → 静默停摆」本就是既定的正常终局 ⇒ 「单账号可获取上限」不是有定义的量，闸 ① 按原写法永远无法成立。收窄后它保住唯一真实的目的（保护付费兑现）且可机械校验。**否决**「给残卷设账号级硬上限」（新机制，与静默停摆重复承担同一职责）与「删掉闸 ①」（失去启动期大声失败的能力）。
  - **准入字段保留 `ExclusiveSource: Source?`**（否决 `GrantChannelLock`）；缓解易混的手段 = `common-properties.md` 并排写出与 `SourceCode` 的四行对照表（落点 / 语义 / 消费点 / 不填的含义）。
- **成就奖励改为「指定条目 + 成就限定」，不进任何抽取池。** 论证链：若成就指定的条目同时躺在通用池里，玩家可能在达成成就之前就从别处拿到它 ⇒ 发放时那条 `Grant` 指向已持有条目 ⇒ 按排重语义**这一发是空的**；而成就是一次性的确定回报、没有补发机会 ⇒ 不能靠概率侥幸，必须由**准入规则**从结构上排除。由此得一条可断言的不变式（发放时目标条目必然未持有，否则 `PushError`）+ 三条 `PushError` 校验，**「不落空」从口头保证变成机械保证**。连带推论：`AccountStream` 不需要 `AchievementReward` 成员；置换两侧不对称（换入侧永不出现、换出侧不禁止）。
- **礼包空池走三道闸**：加载期 `PushError` / **购买入口前置拦截——把失败点挪到掏钱之前** / 兑现处报错且**不补发**。
- **新增待答 1 条**：`GrantPoolMargin` 的具体取值（结构已定、数值待内容规模明朗）→ ⑦。另有两条**并入既有待答**：`BundleGrantOrdinal` 的落点挂在「礼包持有状态的存档表达」上；购买入口的可用性呈现挂在「商业化的 UX 观感」上。
- **不推翻任何 ADR。** 修订了两处既定形态（账号级 RNG 参数、`Rarity` 消费点由两个增为三个），均为扩展而非反转。`DrawPool<T>` 调用方 3 → 4，**无放回**与**加权**成为其契约的一部分——加强了「第二阶段开工前落地」的排期理由。
- **不 bump 存档 schema**（`ExclusiveSource` 落内容定义、不落存档；`BundleGrantOrdinal` 待落点确定后再 bump）。**⚠ 跨库：后端侧需一份对应 handoff**——`AccountSeed` 的复算契约多一个参数，建议与既有的「`AccountSeed` 下发与复算协议形态」那条后端待答合并。

## 2026-08-12d（隐藏属性的档位模型与跨档叙事）

- **答结 2 条**（④ 隐藏属性 / 剧本机制）：
  - 「隐藏属性的档位划分与阈值（承重）」 → **三属性共用一套档位表**：道心 `[0,100]` 起始 50 **5 档**（阈值 20/40/60/80，带符号档号 `-2..+2`，唯一双臂）· 煞气 `[0,100]` 起始 0 **4 档**（25/50/75）· 寿元既定 **3 档**（30% / 10%）。**档号方向定义为「离常态的距离」**——这是本次的承重推演：若把「下行不播」读成「数值下降不播」，寿元既定的 30% 提示（它本就是数值下降触发的）会被字面废掉；改用距离口径后三属性共用一条规则 `|newBand| > |oldBand|`，不需要方向字段、不需要为寿元开特例。每档带**回滞 δ**（4 / 4 / 3 个百分点）⇒ **档位不是当前值的纯函数** ⇒ 三个 band 字段必须落存档。
  - 「跨档叙事文案的归属与呈现」 → **挂档位不挂事件 · 走内容层 · 每档 2–3 条等概率取一（随机源不带种子）· 只挂极值档 · 结算面板内一档一行 · 多属性同跨逐条陈列（寿元 → 煞气 → 道心）**。
- **部分移出 2 条**：`TryApply` 施加负值的钳制规则（**隐藏属性那一半答定**：截断到 `[0,100]`、不构成终态；其余资源仍待定）· 隐藏属性清单（取值域 / 档位 / 剧情线目录答定，**第四项属性与增减触发仍待答**）。
- **本次最大的结构性收获：把「阈值触发剧情线」与「跨过隐藏档位」两套并行说法收敛为同一张表**，四个消费方各取所需且**密度互不绑定**（eventOptions 调制用全部档 · 剧情线 3 档 · 叙事文案 4 档 · 寿元红字 1 档）。**档多 ≠ 文案多**——档位密度服务调制分辨率，文案密度服务「稀缺才有分量」；为收窄文案而砍档就是拿主业迁就点缀。
- **新增待答 2 条**：`HiddenStatGrade` 的三个映射值（初值 2 / 5 / 10，归 ch1 数值标杆专场）→ ④；内容条目自己的多语言表达形态 → ⑤（作为「翻译键的铺开节奏」的邻域备注）。
- **不推翻任何已定决策。** 疑似冲突（08-12「全库 UI 文案走翻译键」vs 跨档叙事走内容层 overlay）经核**不构成冲突**——两条纪律作用于**不同的文本层**，四问判据已显式化并落 `ux/_index.md`。
- **⚠ interview 追加两项裁定**（草稿未覆盖）：**档位条目恒启用**（`ContentEnabled == false` → `PushError`；判据「`AllEnabled()` 只约束抽取，档位判定是查表读取」，立为 content-service 的通则「**能被抽取的才配有开关**」）· **道心下臂 `-2` 挂 `PlotTriggerId`**，剧情线目录由 2 条扩为 **3 条**（它是「下臂不播文案」那条取舍成立的前提）。
- **文案密度定为 ≈ 6–10 条 / 轮回**，依据 = 本作是 **deck building game 不是 visual novel** + 因果的主要载体是事件文案本身；**寿元 10% 的红字倒数是常驻标注而非叙事**，不计入这个预算。**寿元百分比的分母**定为新字段 **`ChapterLifeSpanBudget`**（篇章边界冻结的结转后预算）。
- 新增 4 个存档字段（3 × `sbyte` + `ChapterLifeSpanBudget`）⇒ **bump schema · 空迁移**；新增内容类型 `HiddenStatBandData`（12 条目）+ 8–12 条文案条目。**纯本地，无跨库影响。**

## 2026-08-12c（标识符单数收口：`CharacterItem` / `Achievement` / `magicPack`，与 `pastEvent` 漂移纠正）

- **答结 1 条**（⑦ 图鉴族与商业化）：「`CharacterItem` 的标识符单复数不一致（08-03 新增）」 → **统一为单数，`CharacterItems` 整体作废**。立通则「**类型名恒为单数，复数只属于集合字段名**」，并把法宝的三层分工一次写死：`ItemData`（内容定义，两层共用，**无 `CharacterItemData`**）↔ `CharacterItem`（持有条目，一份实例 = 一个集合元素）↔ `CharacterProfile.magicPack`（集合字段，**借用已定名的容器概念「储物袋」** ⇒ 单复数之争在此形态下直接消失，且「概念 → 字段」少一次翻译）。
- **连带答结 2 条**（本次 interview 追加，原不在待答清单内）：
  - `List<Achievements>` → 元素类型 **`Achievement`** + 字段 **`achievement`**（成就无容器概念可借名，退回库内既有单数字段风格，零张力）；**裸写 `Achievements` 一并单数化**，**文件夹 `systems/player-profile/achievements/` 改名为 `achievement/`** 并同步全库路径引用。分组结构与两档奖励语义不受影响。
  - `pastEvent` 类型漂移 `List<AdventureEvent>` → `IReadOnlyList<PastEventEntry>`，**三处全部纠正**（`life-cycle-service.md` · `program-overview.md` · `decisions/ADR-0004`；ADR 那处为纯类型标注订正，不改变该 ADR 的任何决策语义）。
- **借名的连带收益**：储物袋既有规则（9 格上限 / 按 `ItemId` 堆叠 / `UsableScene` 筛「随身」）与字段名 `magicPack` 就此对齐，「概念 → 字段」少一次翻译。
- **新增待答：0 条。** 原草稿标注的前置依赖（`SourceCode` 是否收窄到账号级两类）已由同日 08-12b 反向答结 —— `CharacterItem` 确定携带 `SourceCode`。
- **不推翻任何已定决策**：纯标识符收口，机制侧零改动、**不 bump 存档 schema、无迁移路径**（无线上账号、`game-feature-branch/` 无对应代码 ⇒ 这是一次改到位的最便宜窗口）。改写范围**只覆盖活文档**，`handoffs/` / `answer-logs/` / `inbox/archive/` 中的复数写法不回改；顺带中性化 `character-profile/_index.md` 中「先前记为 X」的考古式表述。
- 对应 answer log：`answer-logs/log-character-item-singular-naming.md`。

## 2026-08-12b（授予来源 `Source`：封闭三值 → 按 `(Kind, Scope)` 分域的开放清单）

- **答结 1 条**：`06-meta-progression.md` 的 **⚠ `Source` 三值封闭清单与轮回级两类的取值冲突**。原待答给的两个收口（① 收窄 `SourceCode` 到账号级两类 / ② 四类照带、轮回级恒 `Unknown`）**全部否决**——**该扩的是清单，不是字段的覆盖面**。见 `../answer-logs/log-grant-source-per-kind-scope.md`。
- **推翻 1 处既有定案：`systems/common-properties.md` 的「成员清单已穷举、只有三条途径」与「清单是封闭的」（08-10b）。** 三条成员全是账号级法则的授予途径，而神通 / 古宝 / 法宝各有真实存在的来路。扩为**七值 + 兜底**：`Unknown=0` · `FinaleWin=1` · `PremiumBundle=2` · `AchievementReward=3` · `EventOutcome=4` · `CombatReward=5` · `ExchangePurchase=6` · `InitialGrant=7`（来路全部取自既有文档已写死的获取渠道，非新造机制）。**「不为置换所得预留成员」那半句保留并强化为禁令**——新设 `Replacement` 会立刻打破 `x` 单调不减、重开置换刷分通道。
- **结构性判断：分域差异由校验表承载，不由类型系统承载。** 保留**单一** `Source` 枚举（四类共用同一条授予通道，拆成四个会把 `Source` 形参逼成 `object` / `int`，撞「贯穿整条链路的类型一致性」；同型先例 = 08-10c 合并 `AbilityScope`）；合法子集表 `(Kind, Scope) → 允许的 Source 集合` 是一张**代码常量静态查表**，与置换同池判据共用同一个键，**不进 `.tres`、不走 overlay**（它约束代码组装，不约束内容编写）。
- **新立承重规则：授予来源校验取「入口严、读档宽」。** `Op == Grant` 时非法组合或 `Source == Unknown` → `PushError` + **整批拒绝**（与 `PairKey` 同档）；读档遇不合法的**既有条目** → `PushWarning` + **保留原值**。**这是唯一安全的非对称方向**——读档回落 `Unknown` 会把一条 `FinaleWin` 法则改判，压低残卷的 `x` 并让档位回跳，违背单调不减。
- **兼容性核心（明写以防误读）：扩清单没有动残卷。** `x` 仍 = `SourceCode == FinaleWin` 的法则数，新增四个成员没有一个能出现在法则上；单调不减 / 首胜规则 / 全局前置 / 账号级 RNG / 幂等键一概不变。**不 bump 存档 schema、签名不变、无迁移。**
- **新立通则（`player-profile/_index.md` 两层通则）：一个字段不为「部分落点无规则消费点」而拆出第二套同步口径。** `SourceCode` 是首例（法则上被 `x` 读取，另三类无规则消费点）。它约束「同一字段的不同落点」，与既有「合并判据」约束的「两个不同字段」互不削弱。
- **表述改写：「唯一消费点」→「规则消费点唯一 + 非规则用途两处」**（`TryApply` 可追溯性日志 / 客服溯源）。**代价如实写下**：轮回级两类的 `SourceCode` 仍无规则消费点，只是从「字段无意义」降级为「有信息但暂无规则消费者」。
- **新增待答 2 条**：`05-service-contracts.md` 的 **⚠ `Source` 在上行负载里的序列化形态**（本库的「整数 code」与后端 `contracts/envelope.md` 的「字符串枚举名」正面冲突，**收口归后端库**，不阻塞客户端落地）· `06-meta-progression.md` 的 **`EventOutcome` 与 `CombatReward` 是否终将合并**（若合并，`CombatReward = 5` 的 code 作废且永不复用）。
- **⚠ 后端侧承接已就位**：`backend-design-documents/handoffs/2026-08-12-grant-source-code-contract.md`（`status: raw`，待该库自行提炼）。

## 2026-08-12（错误文案归属 / 三档版本提示去重 / 阻塞屏三变体 / `Detail` 收口）

- **答结 3 条**：`05-service-contracts.md` 的 **玩家文案的映射归属**（→ UI 层持有、键 = 后端 `code`、载体 = Godot 翻译键；`code → ERR_*` 是**机械变换**而非第二张手写表 ⇒ 「处置表加了行、文案表忘了加」这个失效面**不存在**；缺翻译条目 → `PushWarning` + 按 `OpError` 回落四条通用文案，并由**启动期审计**一次性扫出）与 **两条「去更新」提示的呈现与去重**（含强更硬阻塞屏形态）· `sync-service.md` 的 **迁移失败的玩家侧表现**。
- **新立承重规则：三条版本提示 = 同一根严重度轴上的三档，同一时刻只呈现最高一档，低档被高档吸收。** 这是 `combat-ux.md`「不在最高频操作上加提示，告知由别处的常驻呈现承担」的**第三个实例**。② 档复用既有常驻同步指示并**必须换掉「离线」二字**（`Upgrade` 态本会话内永不恢复，继续说「离线」是给一个已知为假的承诺）；① 档加频次护栏（每个 `recommendedVersion` 只提示一次，落 `user://cache/dismissed-recommended-version.json`）。
- **结构性收敛：三种终局态 → 一个 `BlockingNoticeScreen` + 数据驱动变体表**（需更新 / 被挤下线 / 存档读取失败）。**⚠ 三个变体 ≠ 三处硬阻塞**——阻塞点仍是既定两处，迁移失败落在「启动 pull」之内，总则 7 那条原样成立。「去更新」地址 = **后端下发 `detail.updateUrl` 为主 + 随包 `ChannelConfig` 兜底 + 两者皆无则按钮置灰**，落地前校验 scheme。**迁移失败分两种情形**：超上界走「需更新」/ 迁移抛错走「存档读取失败」+ 必上报；**否决「提示重装」与「回退到云端旧版存档」**。
- **推翻 1 处既有表述：`OpResult.Detail` 正式收口为诊断串**（07-27b 的「携带面向玩家的原因串」作废，以 08-11b 为准）。理由是可机械检查性——`Detail` 兼两个身份则总则 7 那三条承重纪律**一条也无法机械检查**。连带改写 `account-service.md` 的 `OpError.Compliance` 一行。
- **新定边界（推翻原草稿「本次不裁决」）：全库 UI 文案统一走 `TranslationServer` 翻译键**，中文为默认与优先制作列、**英文列全部预设占位符**；`errors.csv` 只是第一批。与 `scope.md`「本地化打磨在 MVP 外」不冲突——现在做的是**键与结构**。新增随包资源 `res://text/`（不走 overlay / flags 热更）。
- **推论（可机械检查）：客户端总共只在两处做 semver 比较**——`minAppVersion`（内容维度）与 `X-Recommended-App-Version`（软提示），两处都只导致「不做某事」或「说一句话」；协议维度一处也没有。
- **新增待答 2 条：** 翻译键的铺开节奏（→ `05-service-contracts.md`）· 英文占位符的具体形态与各 `ERR_*` 的实际措辞（→ `deferred-content.md`）。
- **⚠ 后端欠账 1 条：** 错误体 `detail` 需增更新地址字段，可与 08-11b 已挂的那笔合并成一份后端 handoff。
- 对应 answer log：`../answer-logs/log-error-copy-and-update-prompts.md`。

## 2026-08-11c（战斗流程收口 · 先后手 / 无重洗与疲劳 / 卡牌侧数值重定 / 卡类型降为五类）

- **答结 2 条**（`01-combat.md`）：**先后手由谁决定** → `EncounterSpec.FirstSide`（可空，future-event-service 物化写入；null → combat 子流掷）· **阵法与灵宠的区分轴** → **问题随灵宠删除而消失**。
- **新立承重规则：抽牌堆不重洗，抽空即疲劳**（每抽一张 −1 道念，下限 0 照常截断）。**这使道念的削减通道从一条变成两条**（卡牌 + 疲劳），并让**卡组规模成为真实的构筑 / 编排取舍**。
- **推翻 5 处既有定案：** ①「抽牌堆空时由弃牌堆重洗补充」（`deck/common-properties.md`）· ②「道念的产出 / 削减不存在第二条结算通道」（08-02b 推论④）· ③ 起始手牌 5 → **4**、手牌上限 10 → **9**（`balance.md` 的推导整段重写）· ④「敌人卡组固定 15、规模不作为物化旋钮」→ **两侧皆不设硬限**（旧理由「保证永不重洗」随重洗删除而失效）· ⑤ 储物袋 99 → **9**（按 `Id` 堆叠后的条目数；`ux/screen-flow.md` 的「99 项需虚拟化」等表述一并清理）。
- **结构性收缩：`CardType` 六值 → 五值**，删 `Creature`；永久物统一归阵法，**「实体 / 非实体永久物」二分整条取消**；原灵宠的三个次类型迁为阵法次类型。连带作废「灵宠是延迟回报型产出通道」这条推论。
- **新增：不设 mulligan**（起始 4 张一次发到位）。
- **新增待答 4 条，全部落在 `01-combat.md`**：疲劳的呈现（→ `ux/combat-ux.md`）· 疲劳量是否可调（→ `balance.md`）· 卡组规模的实际取值（归 ch1 数值标杆专场）· 储物袋 9 格对道具经济的回压（满袋处理 / 获取频率 / 置换对价，→ `item/`、`exchange/`）。
- 对应 answer log：`../answer-logs/log-combat-system.md`。

## 2026-08-11b（契约边界层的客户端侧承接 · 传输信封 / 错误码映射 / Upgrade 处置 / flags 第三层）

- **答结 3 条**：`05-service-contracts.md` 的 **`pushId` 报文字段名与序列化形态**（表达形式 = OpenAPI 3.1 + JSON Schema 单点、两侧各持 DTO；传输信封走 HTTP 头、负载信封留 push body；剩余的**后端记忆窗口**收窄为 `sync-service.md` 的单条并指向后端库）与 **`manifestSchema` 版本化**（三版本号分工；**不受支持 → 跳过更新用基线**，与既有的「不匹配 → 整包重下」分成两种情形）· `deferred-content.md` 的 **`ContentEnabled` 粒度**（答：**分桶规则哪也不放在客户端**，flags 端点按账号解析后只给结果）。
- **新立承重纪律 3 条：** ① **错误处置以 `code` 为键的数据表**（不是 switch），未知 `code` 按 `class` 走四条保守默认路径、未知 `class` 当 `Fatal` + 上报——**硬阻塞仍只有两处且只由已知 `code` 触发，一个未知 `code` 永不新增第三处**；客户端不得靠 HTTP 状态码分支、不得解析 `message`。② **`Upgrade` 类错误只在登录 / 启动 pull 硬阻塞**；非闸门点保留待发队列 + 非模态提示 + 暂停退避（唯一解除条件 = 重新登录成功），**与「缓冲超限 → 软阻塞」的衔接 = 闸门口径完全不变、只换模态文案与选项**（「需更新版本才能同步」/「去更新 · 退出」，无「重试」）。③ **`Retry-After` 是退避下界**（取 `max(本地退避, 服务端值)`），限流绝不映 `Conflict`。
- **结构性新增：flags 成为 `ContentEnabled` 的第三层覆盖来源**（`res://` < overlay < flags），只作用于产出侧 `AllEnabled()` 取池、不参与合并后强校验、轮回中途可热应用；**启动链插入一步 `ContentService.RefreshFlagsAsync`（在 `SignInAsync` 之后、`SyncService.InitializeAsync` 之前——flags 端点需鉴权）**；本地缓存 `user://cache/flags.json`（切账号即失效）。**连带解除 `DrawPool<T>` 的唯一依赖**。
- **推翻 1 处既有表述：**「overlay 是唯一热更层」不再成立（`content-service.md`「存储形态：三层」改写为三层**覆盖来源**）。
- **一处对后端标注缺口的反证：** 后端标注「flags 不缓存则离线开局时被秒关条目复活」——该缺口在客户端**不存在**，因启动 pull 是硬阻塞、强制在线下无权威档即不可玩，根本没有「断网启动并进入轮回」这条路径。缓存的真实收益只在「登录成功但 flags 拉取失败」时的降级值。
- **新增待答 2 条**：两条「去更新」提示的呈现形态与去重 + 强更硬阻塞屏形态（`05-service-contracts.md` → `ux/`）· flags 拉取的频次护栏（`content-service.md` 的待决问题）。**收窄 1 条**：玩家文案的映射键**不能只是 `OpError`**，按后端 `code` 分辨。
- **⚠ 后端侧需要一份对应 handoff**：`contracts/envelope.md` §3 端点表删 `/v1/plot/…`、§6 台账删 `plot.unavailable`（客户端 08-11 已把剧本内容整体本地化）——与下方 08-11 条已记的那笔欠账是同一笔。
- 对应 answer log：`../answer-logs/log-0811_2.md`。

## 2026-08-11（剧本内容本地化 · 撤销云端剧本服务）

- **答结 3 条**（`04-hidden-attributes-plot.md`）：**① 剧本内容归属 → 本地内容层**（`res://` 基线 + overlay，经 ContentRegistry 按 `Id` 读；**没有云端剧本服务、没有逐事件请求**）· **② 剧本是预写式内容库**（非运行时生成——生成式无法本地化）· **③ 剧本服务契约 / 离线降级 / 预取与事务前置的边界整条消失**（它们全是「逐事件向云端请求文本」的派生物）。
- **推翻 1 条既定判据：07-25c 的本地 / 云端内容分界**。原判据「按进度动态请求、一次性呈现、不被存档引用 → 云端剧本服务」是**描述性、近乎循环**的——「动态请求」是那个选择的*结果*，被当成了它的*理由*；而「剧本在云端」本身在 07-23 只是**纯断言，从未被论证**，且**无任何 Accepted ADR 覆盖**（ADR-0003 管存档 / 账号权威，不涉剧本文本）。新口径：**一切内容属本地内容层**；「是否被存档引用」只决定 overlay 能否为它新增 `Id`。
- **新立承重规则 1 条：悬空 key point → `PushWarning` + 叙事降级、不阻塞轮回。** 这是本地化唯一新生的风险——key points 是指向剧本节点的**持久化锚点**，故「剧本不被存档引用」只对**文本**成立、对**节点**不成立，overlay / 客户端版本回退可使其悬空。处置与 content-service「读取侧不过滤」同构；代价明写（静默失去一段剧情与其调制）。**反向约束 key points 的 schema**。
- **连带结构性收敛：** 跨进程边界成分 **4 → 3**（`IPlotBackend` / `HttpPlotBackend` / `OfflinePlotBackend` / `BackendSelector.CreatePlot()` / `PlotRequest` 整套作废）· 总则 7 四接口 → 三接口 · 条件编译清单 6 → 5 处 · PlotManager 全部方法**形态 B → A**（`ResolvePlotAsync` → `TryResolvePlot`、`ChooseBranchAsync` → `ChooseBranch`）· `sync-service` 降级表删「剧本请求」一行 · **「manager 不跨边界」成为无例外的结构性事实**。
- **新增待答 2 条**（`04-hidden-attributes-plot.md`）：剧本内容类型的**数据形态**（含「新增剧本条目不得引用本次 overlay 之外的新 `Id`」的**可执行化**）· 剧本内容的**体积与分发粒度**（本地化后成为真实的包体 / 下载量成本，原云端方案的按需请求天然回避了它）。
- **⚠ 后端侧需要一份对应的 handoff**（本次只写客户端库）：删 `systems/_index.md` 的 `plot.md`、作废整个 `open-questions/05-plot-service.md` 分片、`01-contracts.md` 与 `README.md` 的「跨越这条边界的客户端成分有四个」→ 三个、剧本内容改由 `contracts/content-manifest.md` 通道承载。
- 对应 answer log：`../answer-logs/log-0811.md`。

## 2026-08-10c（solution-draft-ability-deprivation-and-player-statistics · 「本轮回禁用」与置换型剥夺一次收口）

- **答结 4 条**（`01-combat.md` 的「本轮回禁用」与置换型剥夺片区**全部**；同名条目在 `player-power/_index.md`、`character-profile/_index.md`、`player-profile/_index.md`、`life-cycle-service.md` 一并移出）。移出记录见 `../answer-logs/log-ability-deprivation-and-player-statistics.md`。
- **一条上位判据统摄全片区：禁用一律截断在「进入生效面」那一步，而不是在生效面里做例外判断**——与既定的「`status` 关闭 = 不入场，而非入场但不生效」完全同构。分界依据是「神通 / 法则 ≈ 静止式异能，法宝 / 古宝 ≈ 启动式异能」，但**这条类比只用于选截断层，不收窄 `Abilities` 的取值域**（08-04b 不动）。
- **新增字段 `CharacterProfile.disabledAbility`**（与 `pastEvent` / `chapterRetry` / `activeCombat` 平级，**不落 `Status` 内**）：条目 `DisabledAbilityEntry` 7 字段，**存「施加时坐标 + 时长」不存「到期坐标」**（判据同 08-09c），三档 `DisableDuration { NextEvent, ThisChapter, ThisCycle }` 由 life-cycle-service 在两个既有时点纯函数式剔除。**第一档定名 `NextEvent` 而非 `ThisEvent`**——施加只发生在 `eventEnd`，「本事件禁用」是空操作，**枚举成员的名字必须说实话**。
- **`ProfileChangeSpec` 由单列表扩为三个平级只读列表**（`Elements` 资源 / `AbilityElements` 能力 / `Stats` 统计）——三者施加语义根本不同（走不走 modifier pipeline、要不要钳制、失败是否阻断），压进一个带符号 `int` 是让类型说谎。**置换 = `Remove` + `Grant` 两条 element 由 `PairKey` 配对，不是一条 `Replace`**（原子性已由 `TryApply` 免费提供）。**「按 `Id` / 随机 / 按 `Scope`」三选一的旧问就此消解**——element 只承载已定稿的 `Id`，选取规则在 spec 组装前就已掷完。
- **⚠ 推翻「置换作为选择成本似乎合理」：** 能力 element **恒不出现在 `selectCost`**，三种操作只在 outcome / reward 侧。四条理由：成本侧只放可计价的量 · 无条件施加与「先看后决 · 拒绝无代价」正面冲突 · 能力得失是后果不是入场费 · 换来一条可机械检查的不变式。旧措辞已在 `player-power/_index.md` 与本分片直接重写。
- **⚠ 推翻 08-06b「统计计数首项 = 篇章重试的账号级累计」：** `PlayerStatistics` 首批**只有** `TotalCyclesCompleted` + `TotalCyclesDefeated`。**代价明写**——「你在炼气段重开了多少次」目前**没有字段回答**，08-06b 用它化解 ch1 死字段的那条论证就此失效（不是被别的字段覆盖了）；需要时纯加法补一项（统计层新增字段零迁移、零后端配合）。`character-profile/_index.md` 与 `life-cycle-service.md` 的对应表述已重写。
- **新定名 / 合并两个类型：** `RarityTier { Tier1..Tier5 }`（挂 `PowerData` / `ItemData` / `CardData`，缺失 → `PushError`；**与优势档 `Tier { Narrow, Solid, Crushing }` 不得复用、不得换算**，奖励池权重表改按 `RarityTier` 索引）· `PowerScope` / `ItemScope` **合并为 `AbilityScope`**（零迁移）。
- **置换 = outcome 侧的一个决策点**，五条规则：排除已有 · 同稀有度 · 先看后决 · 拒绝无代价 · 四类通用。**`PlayerStatistics` 走宽松同步口径五条**（统计层新增字段零迁移、零后端配合）。
- **`PushWarning` 对称落点定在内容加载侧，形态是「清单列举」而非「比例校验」**——outcome 侧的运行时统计样本量是 1，必然误报；且告警落在玩家进程里等于没人看见。告警文案须明写「这个比例不是 1% 的口径」。
- **新增待答 2 条** → `01-combat.md`：`RarityTier` 的分布与权重表 · `StatKey` 的完整成员清单。另记一条**非阻塞的合并机会**：残卷 / 礼包的候选池与置换候选池是同一形状的问题，宜一次答定。
- **不新增服务 / manager / EventBus 事件 / 存档点 / RNG 子流。** **schema 影响**：bump 一次（`disabledAbility` → 空列表、`statistics` → 全 0、spec 单列表 → 读为 `Elements`），当前无线上存档 ⇒ 空迁移。

## 2026-08-10b（draft-0810b · 授予来源字段 `SourceCode` 与残卷 `x` 的口径收窄）

- **答结 1 条**（`06-meta-progression.md` 的「Finale『失败但存活』分支的叙事补白落点」）：归 **`plot-manager.md` 的叙事层**（不是 `ux/screen-flow.md`）——它与「隐藏属性跨档定性叙事」是同一类东西，走同一落点（`ResolveOutcome` → `eventEnd`），不新增结构；文案两版已给：**「劫败而身存，破境亦有缺。」/「以败换境，以伤换生。」**。承重边界：**两版均不得暗示道统残卷**（失败侧对残卷彻底隐含仍成立）。移出记录见 `../answer-logs/log-0810b.md`。
- **新增共有字段：`SourceCode`（类型 `Source` 枚举）落四类持有条目**（法则 / 古宝 / 神通 / 法宝）。**落持有条目而非 `PowerData` / `ItemData`**（内容定义是共享只读单例，来源是「这一次获取」的属性）；`Source` 成员带**稳定 code**（存档序列化，永不复用）+ **展示 value**（不落存档），与 `CapabilityFlag` 用枚举而非字符串 key 同构；`Unknown = 0` 作迁移兜底；**授予 element 强制携带来源，无默认值**。落 `systems/common-properties.md`。
- **推翻 08-09b §6（礼包压低残卷上限）：** 残卷的分档自变量 **`x` 收窄为「`SourceCode == FinaleWin` 的法则数」** ⇒ 礼包 / 成就奖励**不再推动 `x`**，礼包与残卷**完全解耦**。**「获取渠道是打还是买不改变这条曲线」整句作废**——分档自变量的含义由「拥有得越多越难再得」反转为「**靠渡劫拿得越多，后续越难再从渡劫拿到**」。连带：付费收益变为**纯净收益**（负反馈整条消失，礼包净强度上升）· `x` 的单调性只剩**置换**一条变数 · `balance.md` 三张表数值不变但**口径偏松**（复核提示：偏高则下调阈值，不动表结构）。
- **同 session 追加答结 5 条**（用户对上述结构性变更的六个待确认项逐条裁定）：**① 置换不改变来源**——继承被换出条目的 `SourceCode`，**关死「用置换刷回高掉率」的通道**，`x` 单调不减 ⇒ 档位只降不回跳原样保住（保住它的理由由「置换是等价交换」换成「置换继承来源」）· **② `Source` 封闭三值**（`FinaleWin` / `PremiumBundle` / `AchievementReward` + 兜底 `Unknown`），**不为事件 outcome / 战斗奖励 / Exchange 购买 / 置换所得 / 开局初始预留成员** · **③ 补白文案 = 等概率随机二选一 + 属内容层**（可热更、不随剧本服务下发）⇒ 在 PlotManager 内划出「剧本正文走云端 / 状态转换触发的定性文案走内容层」的分界，**推论：随机源不必带种子**（不产生玩法结果、不占子流），并为「跨档叙事文案归属」那条待答留下同类先例 · **④ 成就奖励可给法则 / 古宝**（新设计意图；不计入 `x` 故不压低掉率，奖励目录本身仍待定 ⇒ 该条收窄不移出）· **⑤ `SourceCode` 无第二个消费点**——不对玩家可见、不进图鉴、不参与其他判定 ⇒ **纯规则字段**（严格同步 · 后端可复算）。另确认**付费收益变为纯净收益是设计意图**（礼包净强度上升被接受，平衡按此校准）。
- **新增待答 1 条** → `06-meta-progression.md`：**⚠ `Source` 三值封闭清单与轮回级两类的取值冲突**——三条全是账号级途径，而神通 / 法宝的常规来路无合法取值、只能落 `Unknown`；收口两选（把 `SourceCode` 收窄到账号级两类 **倾向** ／ 四类照带且轮回级恒 `Unknown`），因原始意图明写四类都带，留待用户确认。
- 对应 answer log：`../answer-logs/log-0810b.md`（叙事补白落点）+ `../answer-logs/log-0810b_2.md`（六个待确认项的裁定）。
- **schema 影响**：持有条目 +1 字段 ⇒ 存档版本 bump，老档补 `Unknown`；当前无线上账号，无实际迁移。（覆盖四类还是仅账号级两类，取决于上面那条待确认项。）

## 2026-08-09e（solution-draft-discipline-enforceability · 三条工程纪律的可执行化一次收口）

- **答结 3 条**（全部来自 `05-service-contracts.md`）：`[Export] bool UseOfflineBackend` 的发布期防护 · EventBus 退订纪律的可执行性 · `AllEnabled()` 纪律的可执行性。移出记录见 `../answer-logs/log-discipline-enforceability.md`。
- **新增上位判据：「纪律的可执行化」四级阶梯**（写不出来 / 编译不过 / 大声失败 / 评审清单）+ 两条选级判据，落 `systems/architecture.md`，与八条 API 契约总则同层，**列为 ADR 候选**。三条待答本是同一问题的三个实例（*正确的写法要作者主动记得，错误的写法既不报错也不显眼*），故一次收口。
- **推翻 / 作废：** `[Export] bool UseOfflineBackend` 这一表述整体作废（autoload 指向 `.cs` 时 `[Export]` 无存储处，技术上本就不成立）→ 改 ProjectSettings；连带**「autoload 直接指向 `.cs`、不为服务建空 `.tscn`」升为无例外约定**，推论「服务级配置一律走 ProjectSettings，`[Export]` 只留给场景组件」。仓储接口上的 **`All()` 被删除**（`content-service.md` / `common-properties.md` / `.claude/rules/data-resource-rules.md` 三处措辞跟改）。
- **`systems/architecture.md` 的待决问题少一条**（EventBus 退订可执行性）；`content-service.md` 的待决问题少一条（`AllEnabled()` 可执行性），另一条（`ContentEnabled` 分桶粒度）**影响面收窄**为仅 `DrawPool<T>` 的构造签名。
- **新增待答 1 条** → `05-service-contracts.md`：`#if DEBUG` 判据需在首次生成 `.csproj` 后实测确认一次。
- **排期性结论（非待答）：** `DrawPool<T>` 类型层加固已采纳，落点 = 第二阶段（内容）开工、第一份内容 FR 之前。

## 2026-08-09d（solution-draft-finale-win-ordinal-vs-statistics · 账号级字段的两层通则与 `Ordinal` 命名硬约定）

- **答结 1 条**（`06-meta-progression.md` 的「`FinaleWinOrdinal` 与账号级统计计数的边界」）：不靠注释、靠**三条结构性纪律**关死 —— **① 分层通则升格**（08-06b / 08-09b 两次就事论事的判据写成 `PlayerProfile` 上账号级字段的通则，判据 = 有没有被**规则**读）**并补上真正缺的合并判据**：**可以合并，当且仅当「语义 + 同步口径 + 篡改后果」三者全同；跨层的两个字段永远不满足**（只写「注意别合并」半年后必然失效，正向判据才可被主动执行）· **② 统计侧不设「Finale 胜利数」字段**，「渡劫成功了几次」展示**直读 `FinaleWinOrdinal`**——**让重复字段从一开始就不存在**是最强的防合并手段 · **③ 统计侧「通关」= 完成整个轮回**（`TotalCyclesCompleted`），一次通关贡献 3 次 Finale 参与而 Finale 胜利可完全不伴随通关 ⇒ **两个数在任何账号上都不相等**，**首批不设 `TotalChaptersCompleted`**（与 ordinal 几近恒等，最易被误合并）· **④ `Ordinal` 后缀立为规则字段层的命名硬约定**（`Total` / `Count` 归统计层，统计层禁用 `Ordinal`，可机械检查、零迁移成本）。
- **连带定案**：两层**同经 `ProfileManager.TryApply`、同在一次 diff 里**，只在校验强度上分开（规则字段严格 · 后端可复算；统计计数宽松 · 可容忍丢失）；**明确不做两层之间的交叉一致性校验**——写一条「`FinaleWinOrdinal` ≈ 统计通关数」等于在实现层承认二者该相等，是把已排除的合并从后门放回来。
- **收窄（仍待答）**：`01-combat.md` 的「账号级统计计数」只剩**容器形态 + 首批统计项完整清单 + 宽松同步的具体形态**三项（边界一问移出，层归属与首批的含 / 不含已定）。
- **新增待答落点**：无新增。（`terminology.md` 侧「通关」的中文定名是否需与修真词表对齐，属术语打磨，不构成结构性待答。）
- 对应 answer log：`../answer-logs/log-finale-win-ordinal-vs-statistics.md`。

## 2026-08-09c（solution-draft-past-event-trace-schema · `pastEvent` 痕迹 schema 四问一次收口）

- **答结 1 条**（`02-event-options.md` 的 `pastEvent` 痕迹 schema，含四个必须一起答的子问题）：**① 快照字段 → 判据先于字段表**（「重算不出来的存，重算得出来的不存」；文本类字段一律留模板侧，快照里一个字符串正文都不存）+ 条目类型 **`PastEventEntry`**（核心是 `AppliedChange` = `eventEnd` 那一次合并 `TryApply` 的最终 spec，复用 `ProfileChangeSpec`；`LifeSpanAfter` **写明为判据的明示例外**；`EventOutcome` 四值，不为 DnD 选分支预留成员）· **② 未选项 → 归档轻摘要**（依据：「定稿实例必须落存档」对未选项**不成立**，它们永不被消费，只需可回溯不需可重建）· **③ 与 key points → 零结构耦合、单向只读**（把 `InstanceId` 塞进 key point 等于让云端剧本服务依赖客户端存档标识空间）· **④ 体积 → 不影响 push 粒度**（~770 B / 事件，落在既有 ~2 KB 预算内）。
- **连带答结**：**「风味文案是否也物化」→ 不物化，跟随模板数据**——它收掉了「`EventOption` 完整物化字段清单」的文本那一半，也使「定稿实例必须落存档」↔「存档态不复制展示文本」的那处**被误认的张力整体消解**（两条管的不是同一类字段，`variantKey` 化解方案随之作废）。
- **砍掉一条依赖边**：`pastEvent` 的 schema **不再被「key points 粒度」阻塞**，两者各自定稿；`plot-manager.md` 的该条待答同步加了一条边界（不得以「key point 引用 `InstanceId`」的形态回答）。
- **新增明文纪律**：`pastEvent` **只追加、不修改既有条目**（不变式，也是体积估算与 diff 友好性的前提）· **软上限告警**（条数 > 500 或序列化 > 512 KB → `GD.PushWarning`，只观测不改行为，因为整聚合 pull 是硬阻塞路径）· **明确否决**分页 / 冷热分离 / 独立存档段。
- **类型修正**：`CharacterProfile` 的修行历程由 `List<AdventureEvent>` 改为 **`IReadOnlyList<PastEventEntry>`**（原标注与既定物化模型不符——存的是定稿快照，不是 `Resource`）；`terminology.md` 同步，并新增 `PastEventEntry` / `EventOutcome` 两个词条。**随本次结构落定 bump 存档 schema 版本（空迁移）。**
- **收窄（仍待答）**：`EventOption` 完整物化字段清单（剩余分叉不含文本类字段）· `CostKey` element 清单（追加一条：与「每批数量」共同决定 ~770 B 估算是否需复核）。
- **新增待答落点**：`02-event-options.md` 新增 1 条（**物化后敌人实例的类型形态**；不阻塞 `pastEvent` 的最小面已定 = `EnemyTemplateId` + 赋级 `Level`）。
- **不受影响**：ADR-0003 / ADR-0004 未被触及；push 粒度、断线降级、`revision` / `pushId` 契约原样成立。
- 对应 answer log：`../answer-logs/log-past-event-trace-schema.md`。

## 2026-08-09b（solution-draft-legacy-fragment-chance · 道统残卷整条焊到 Finale 上）

- **答结 2 条**：**① 道统残卷概率的累积规则与上限**（`06-meta-progression.md` 挂起最久的一条）→ 定名 **道统残卷 / `PlayerPowerFragment`**；**三个时刻全部落在 Finale**（失败累积 · 胜利掷骰 · 该 Finale 的 eventReward 界面即时发放）；上限 / 基础概率 / 适格篇章按已拥有法则数 `x` 分档，**闸门逐档累加地移除**且**适格 Finale ⟺ 该档增量 > 0**（两表合一，实现侧只需一张表）；**首胜 100% 优先于闸门**；发放后重置为**新档地板**而非归 0；掷骰走 `Hash64(AccountSeed, FinaleWinOrdinal) mod 10000`、**与 `CycleSeed` 完全解耦**（子流由 `CycleSeed` 派生 ⇒ 篇章重试即可刷）、序号即幂等键、**客户端掷后端可复算**；状态落 `PlayerProfile.PlayerPowerFragment`（5 字段），**不并入账号级统计计数**。**② 礼包是否重置残卷概率**（`07-codex-monetization.md` / `monetization.md`）→ **不重置，但使 `x` +1 从而可能压低上限档位**，是**有意的负反馈**。
- **推翻**：08-06d 的「**Finale 失败后可再次挑战**」→ 改为**每篇章一个 Finale、败后不可在同一篇章内重战**。可刷性由「一篇章一个 Finale + 败后不可重战 + 重试上限」三重封死，**残卷不需要任何额外防刷规则**。
- **新增承重语义**：**Finale 失败但存活（约 1%）⇒ 篇章照常完成、境界照常突破** ⇒ **渡劫的胜负不再是篇章推进的闸门**，只决定 `lifeTotal` 损失与残卷是否兑现。
- **口径收窄（需正视）**：08-01 的「失败侧首次有产出」现只对 **Finale 失败**成立；常规失败的产出面只剩 **EnemyCodex 遭遇即记 + 失败经验**。`systems/scoring.md` 与 `systems/services/future-event-service.md` 中点名引用残卷的论证链已逐处改写。
- **收窄（仍待答）**：`07` 的「两条获取渠道」只剩**候选池与排重规则**（交互与 RNG 两问已答结）；`player-profile/` 的统计计数形态**追加一条边界要求**——须明写与 `FinaleWinOrdinal` 的区别。
- **新增待答落点**：`06-meta-progression.md` 新增 2 条（`FinaleWinOrdinal` 与统计计数的边界 · 1% 存活分支的叙事补白落点）；`backend-design-documents/open-questions.md` 新增 1 条（`AccountSeed` 的下发与复算协议）。
- **不受影响**：`SeedManager` 四条子流常量与确定性边界的既定措辞原样成立；ADR-0003 / ADR-0004 未被触及；断线降级路径不变（无新增网络往返）。
- 对应 answer log：`../answer-logs/log-legacy-fragment-chance.md`。

## 2026-08-09（solution-draft-sync-revision-and-soft-block · sync 契约两条答结）

- **答结 2 条**（均在 `05-service-contracts.md`）：**① `revision` 的产生方与语义** → 后端分配的账号级单调递增 `long`，客户端只持传输层基线 `baseRevision`（落 `user://cache/sync-envelope.json`，**不进 Profile、不 bump 存档 schema、无迁移**），上行走 **CAS 三分支** + **幂等键 `pushId`**（缺它会在「请求已达、响应丢失」时丢玩家进度）。**② 软阻塞 × 进战斗前 flush** → **不挡**；两者不是先后关系而是不同层——**flush 是一次「尝试」，闸门是一个「状态」**。
- **修订既有文本（补全，非松动）**：`systems/architecture.md` 总则 7 的 `IProfileBackend` 两个返回类型 → `OpResult<ProfileSnapshot>` / `OpResult<PushAck>`（原签名没有为 `revision` 留返回位置）；`sync-service` API 面新增只读诊断属性 `long BaseRevision`。总则 7 的**原则不动**。
- **UX 两项取向签核**：进战斗前 flush 失败**不加任何额外提示**（由常驻「离线 · 待同步 N」承担，**该指示在战斗屏内必须可见**——这是前提）· `BaseRevision` 在**设置屏**显示为只读「同步版本 #N」（`0` → 「尚未同步」；诊断展示，不进玩法路径）。
- **新增待答落点**：`05-service-contracts.md` 新增一条「`pushId` 的后端记忆窗口与报文字段名」（客户端侧语义已定，剩余部分属后端）；同步登记进 `backend-design-documents/open-questions.md` 的「协议契约」与「存档同步 / 冲突」两节。
- **不受影响**：`sync-service.md` 的「迁移失败的玩家侧表现」保留；`05-service-contracts.md` 其余 8 条不变。
- 对应 answer log：`../answer-logs/log-sync-revision-and-soft-block.md`。

## 2026-08-06（combat-solutions · 战斗待答清单一次性收口：38 条全部答结）

- **答结 38 条**（`01-combat.md` 的全部战斗待答），逐条见 `../answer-logs/log-combat-solutions.md`。五组分别覆盖：赋级带与意图（8）· 存档与结构（7）· 卡牌与规则（7）· 奖励与遭遇参数（7）· 数值进程与呈现（9）。
- **推翻（治理）：08-06 / 08-06b 的「ch1 赋级带 `[−4, +2]` + 降阶碾压硬门 + 阈值不动」整体作废**，以更晚的用户裁决取代——**意图三档阈值整体收紧一级，赋级带回退三章统一的对称 `±2`**。连带作废：「ch1 落差只在领先侧拉宽」「ch1 黑箱只集中在炼气末两级」，**及其内容侧补偿之问**（该待答项前提消失，直接删除）。
- **推翻（呈现）：`ux/combat-ux.md` 的「意图区收起后不换成其他指示」** → 改为「收起后该槽位在敌人回合复用为结算日志 ticker」（同一信息槽的两个时态）。
- **删除概念：`lifeTotalLimit`**（只跟踪 `lifeTotal` 单值、无上限截断，境界基线改由一次性跃升承载）；**`attemptIndex` 派生层**（此前已由 08-06 定，本次给出最终派生形态并同步 sync 侧「不 bump schema」）。
- **新增结构：`systems/enemies/`**（与 `adventure-event` 平级的系统，含 `_index.md` + `common-properties.md`）；`combat/`、`practice/`、`finale/`、`future-event-service`、`enemy-codex` 五处改为薄引用。
- **新增待答落点**：本次未新增独立待答项。原有残留按主题重排进 `01-combat.md` 的四个小节（「本轮回禁用」与置换型剥夺 · 结构与配置 · 内容与数值 · 呈现），并把多条明确标注为**已归 ch1 数值标杆专场**。
- 对应 answer log：`../answer-logs/log-combat-solutions.md`。

## 2026-08-06（draft-0806b · eventOptions 专场第二场：跳过通道整体移除）

本次答结 **5 条**（其中 3 条承重），并**以删除机制的方式**一次性消解了一整族残留细节：

**① `LocationCodex` 记连边（承重 · 答结）。** 词条记「它通向哪些地域」，**玩家可跨轮回重建整张 `locationMap`——这是设计目标（知识 = 力量），不是泄露**。推论：`locationMap` 的不可见是**「初见不可见」而非「永远不可见」**（地图长在图鉴里，不在 HUD 上，与「不给俯瞰视图」不冲突）· **「中长期规划感」的地理那一半就此落地**（闸门给多个目的地 + 图鉴告诉你每个目的地又通向哪里 ⇒ **能提前两步规划路线**）· **它是六本图鉴里唯一一本词条之间有拓扑关系的**（存档仍是 id 集合，但呈现必然是一张逐步显影的图）· **图的稳定性升格为对玩家的隐性承诺**（改连边 = 清空一份账号级资产）。**新增待答：显影粒度**（列出全部邻接 vs 只记走过的边，现按前者理解）。

**② `skipCost` 概念整体移除。** 太复杂、不值得，不做保留也不做降级。

**③ 跳过通道与 `ifMandatory` 整体移除（承重 · 推翻既有建制）。** 理由是它本就冗余：**每次选择后 eventOptions 整批重算 ⇒ 选中一个即等价于跳过其余**。**设计意图不但没丢反而更强**——「每批必有不可跳过项、打不过也得打」**升级为结构性事实：本批每一项都是必做项**，回避通道在规则层不存在，**不需要字段来表达它**。**一次删掉五处结构**：`EventOption` 九字段 → **七字段** · `EventOptionBatch` 删 `AnySkippable` 与恒真不变式 · `AdvanceMode` **整个枚举删除** · future-event-service 五方法 → **四方法**（`TryRefill` 删除）· `CapabilityFlag` 删 `ShowSkipCost`。**连带消解一整族待答**：能否整批全跳 · 付不起 `skipCost` 如何表现 · `pastEvent` 区分两种痕迹 · 补位落空判据 · 已定稿批次存续期间资源下降——**全部前提消失**。**`pastEvent` 只剩一种痕迹**（新问题变成：未被选中的选项要不要归档）。

**④ 付不起必做项 `selectCost` 的终态（承重 · 答结 · 推翻明文流程）。** **支付 `selectCost` 是无条件的可推进行为**：照付 → **支付后终态判定** → 判负进失败流程。**推翻「付不起则拒绝、不产生任何写入」**（写在 `architecture.md` 总则 8 / `life-cycle-service.md` / `program-overview.md` 阶段 4 的同一条回路）。推论：**死锁在规则层不成立，且不是靠产出侧保证闭合的** · **终态由支付后的状态给出，而不是由「付不起」这个事实给出**（付寿元才可能死，付灵玉只是穷）· **UI 不需要不可选 / 置灰态，但必须如实展示 `selectCost`**——「明知是死路仍然走」是有意义的玩家决策 · **事务性与可负担性校验被拆开**，只去掉后者。**新增待答（承重）：哪些资源允许被打穿、各自的截断与终态判据。**

**⑤ `eventPriority` = 两档（0 / 1），future-event-service 独占置位、PlotManager 不可改。** **推论（承重 · 边界澄清）：PlotManager 只调内容不调约束**——它不能靠抬优先级强制玩家做某件事，剧本的强制性只能靠**收窄候选池**表达。**连带：选择约束至此只剩一条轴**（`ifMandatory` 已删，全库「两条约束轴」的表述作废）；两档 ⇒ Travel 闸门与剧情强制事件**共用同一档**，同批出现时自由择一。

**新增待答 5 条**（记连边的显影粒度 · 资源打穿的截断与终态判据 · 「余额不足即拒」还剩哪些消费点 · 未被选中的选项是否归档 · `Priority` 是否退化为 `bool`），全部落 `02-event-options.md`。移出记录见 `../answer-logs/log-0806b.md`。

## 2026-08-06（draft-0806 · 08-06 三条 ⚠ 承重裁决项的收口）

本次答结 **5 条**（其中 3 条 ⚠ 承重），是 08-06 上午那批 Open questions 的逐条回应：

**① ch1 赋级带取非对称 `[−4, +2]`，且三章的带边界全部是内容配置。** 放宽的动机全在下界，**上界的 `+4` 才是把最坏落差抬到 17 的元凶**；取非对称即同时拿到「碾压档可达」与「落差有界」，**代价为零**。**最重要的连带：⚠ `lifeTotal` 算术冲突随之消失** —— 上界统一为 `+2`，ch1 最坏落差回到 **9** < 炼气 10/10，**炼气 `lifeTotalLimit` 不必抬基线**，「一次惨败不打穿耐久」三章全部由规则层封住。**结构性推论**：ch1 的落差**只在领先侧被拉宽**（领先至多 6 / 落后至多 9）⇒ 第一篇章是「碾压侧更宽、被压侧不变」的一章，**新手期得到的是更多「打得动」而非更多「被打穿」**；**「越阶只出现在境界末两级」恢复为三章统一的一句话**；**ch1 的「完全无信息」档同境界内不可达**（`+2` < `+3` 门槛）⇒ 黑箱全部集中在炼气十二层之后，**黑箱本身成为「你已站在突破前夜」的信号**，信息曲线更干净、更陡；**带边界是配置 ⇒ 分档退化为一份配置的取值差异**，代码只读「当前篇章的带」、不为分章写分支。**作废上午三条推论**：「ch1 越阶范围 = 末四级」「落差区间 `[−17,+17]`」「ch1 是等级差最富变化的一章」。

**② 降阶碾压不需要独立的呈现语言。** 与境界内碾压**共用同一套完整意图呈现**，不加「不足为惧」式标注。**推论：呈现层只认档位、不认档位的来源** —— 三档是呈现层的全部词汇，「这次为什么是完整意图」是规则层的事；这与「越阶黑箱不给任何替代线索」是同一种克制，**两道硬门在呈现上都不自我声明**；`CombatSnapshot` 因此不需要「碾压来源」字段。

**③ ⚠ 法则不会被强制剥夺（承重）。** 候选③（真的永久剥夺）**否决**；采纳的不是①或②中的任一个，而是**按「玩家是否点头」把通道一分为二**：**真正从账号移除只发生在玩家自愿接受的「置换」中**（有对价，例如换成另一条法则），**其余所有事件一律降级为「本轮回禁用」——不从账号删除**；两类事件的概率**从内容侧限制**。**推论**：**付费内容不会被游戏销毁**（免去一整类客诉与退款争议）· **三级严重度阶梯成形**（本场移除 < 本轮回禁用 < 自愿置换，「失去法则」从二元事件变成有梯度的压力线）· **置换是正向设计不是惩罚**（卡组构筑式取舍，把挫败机制转成有趣的决策点）· **「本轮回禁用」必须落在轮回级状态上**（账号级 `status` 开关不能承载，否则轮回结束忘了恢复即等同永久剥夺）· **1% 的分子现在编排得出** · **`Power` 的「受保护」是三层语义**（战场可针对性 / 本轮回有效性 / 账号持有权）。

**④ `chapterRetry` = 角色级三个具名字段 + 通关后保留计数 + 账号级另有统计计数。** **⚠ ch1 的死字段问题由「两层各司其职」化解** —— 角色级 ch1 计数确实恒为 0，但**它不需要有意义**；「你在炼气段重开了多少次」由账号级统计计数回答，**07-30b 的 ch1 重试语义因此不必改写**（上午的候选②不采用）。**两层口径不同、不是同一个数的两份拷贝**：角色级是闸门输入（与上限相减得「还剩几次」），账号级是纯读数、跨角色累加、不参与任何判定。三个具名字段与「四境三篇章」这条硬事实对齐；**通关后保留 ⇒ 它是历史不只是配额**（可供角色履历展示），且没有清零时机就没有边界情形。

**⑤ 新概念：账号级统计计数。** `PlayerProfile` 上此前没有的一类字段族，与 `Achievements` 相邻但不同——**成就是有奖励的里程碑，统计计数是纯读数**。首项为篇章重试的跨角色累计。

**新增待答 5 条（全部落在 `01-combat.md`）**：「本轮回禁用」的承载字段与生效面（承重）· 置换型剥夺的候选池与对价规则 · 账号级统计计数的字段形态与范围 · 三章带边界作为内容配置的落点 · ch1 黑箱只在末两级是否需内容侧补偿（倾向不补）。**收窄 1 条**：事件侧「移除 `Power`」的 element 形态，从「要不要剥夺」下沉为「怎么写」。移出记录见 `../answer-logs/log-0806_2.md`。

## 2026-08-06（0805b_2 · eventOptions 专场的追加拍板）

本次答结 **4 条**，并**新引入两个概念**，是 08-05b 那批 Open questions 的逐条回应：

**① 连通关系的承载者 = `locationMap`（新概念）** —— 地域之间的连边**既不挂在 Travel 事件的内容条目上，也不在运行时算**，由一份独立的图承载。**它是一份不变的数据、三个篇章共用同一张、future-event-service 高频只读。** 四条推论：**location 不随篇章 / 境界变化**（篇章难度差异由**敌人赋级带**承载，不由换图承载——与「等级序是一把直尺、境界鸿沟归 `baseMomentum`」同一种分工）· **熟悉度成为跨轮回的资产**（同一片世界，越玩越懂）· **工程形态 = 只读静态数据、启动加载一次常驻、服务只读不写、存档只存当前 location 的 `Id`** · **图对玩家不可见**（「进程不给俯瞰地图」这条不变）。

**② `LocationCodex` = 图鉴族第六本（新概念）** —— **它是不可见的 `locationMap` 唯一的显影通道**，「去过即记」，与 EnemyCodex 的「遭遇即记」同构：**世界地图靠多次轮回一格一格拼出来，而非一开始就发下来**。**承重推论：这给「中长期规划感 / 方位感来源」这条长期待答提供了第一个具体候选** —— 方位感来自**跨轮回积累的地理知识**，不来自轮回内的俯瞰视图；配合 ③ 的多目的地闸门，**跨轮回的知识增长直接转化为轮回内的决策质量**。图鉴族由五本扩为六本（`codex/`、`player-profile/_index.md`、`systems/_index.md`、`art/visuals/` 已同步）。**新增关键待答：词条记不记连边**（记 = 玩家可跨轮回重建整张图，是设计目标还是泄露？）。

**③ Travel 闸门给多个目的地**（⚠ 单数措辞的歧义取宽松读法）—— 收窄后剩下的是**若干并列的 Travel 选项**，各指向当前 location 的一个邻接地域，**「去哪」本身是一次真实的玩家决策**；**它是逐批择一的线性进程里唯一一个带地理含义的分岔点**。候选数量与抽取规则仍未定。

**④ `eventCountLimit` 的计数口径**：**只计「选择进入并结算」的事件；跳过不计入，Travel 也不计入。** 推论：配额是「在这个地域做了几件事」的纯计数——**离开的动作不算做事**；三条口径合起来给出跳过的完整定位：**只在 `pastEvent` 的行为轨迹上留痕，在任何资源与进度刻度上都不计。**

**⑤ 「每批必有不可跳过项」是设计意图，不是死锁** —— **不需要**产出侧的可负担 / 可战胜保证：**打不过也得打，没能承压就输掉这局是正常且合意的结果**。推论：与失败侧的既有建制自洽（图鉴遭遇即记 / 道统残卷 / 失败也给经验 / 篇章重试模型）—— **「输」是本作的一个正常出口**；且**反向约束产出侧不要过度保护**，难度的界由赋级带给出已足够。**收窄剩余**：付不起 `selectCost` 是「无法推进」而非「推进后失败」，不产生终态，需一个明确出口（判负 vs 无成本进入）。

**新增待答 1 条**（`LocationCodex` 记不记连边，落 `02-event-options.md`）；**收窄 5 条**（location / `locationMap` 载体 · 闸门候选数量与抽取 · 配额能否被剧本调制 · `selectCost` 终态 · 中长期规划感）。移出记录见 `../answer-logs/log-0805b_2.md`（4 条，另 2 条收窄）。

## 2026-08-06（08-05 遗留待裁决项的收口）

本次答结 **4 条**，全部是 08-05 挂起的裁决项与方案草稿暴露的张力：

**① ⚠ `±2` 带与意图阈值的算术冲突 → 收口取向 = 调赋级带、不调阈值。** 08-05 列的三条候选**均未采用**；实际方案是**ch1 赋级带放宽为 `±4`（ch2 · ch3 仍 `±2`）**＋**新增「降阶 = 碾压」硬门**（敌人境界更低 ⇒ 一律完整意图，与既有的「越阶 ⇒ 完全无信息」对称）。三处 `diff` 门槛原样保留，故「完整意图 = 碾压专属」不必重新定义。**最漂亮的一处自洽：ch2 · ch3 的碾压档由降阶硬门成立**——篇章开头刚突破进新境界时 `−2` 正好探进下一层境界，「刚突破的修士回头看上一境界的对手如同儿戏」规则与叙事自动吻合；而 **ch1 之所以单独放宽，是因为炼气是最低境界、拿不到这道门**，分档不是随意的。**结构性推论**：碾压档自动向篇章头部集中、越阶黑箱向尾部集中，**一个篇章天然有一条「开局看得清 → 收尾看不清」的信息曲线**；ch1 的越阶范围从末两级扩到末四级。**代价（新增待裁决）**：`+4` 那一侧把 ch1 最坏开局落差从 9 抬回 **17** > 炼气 `lifeTotal` 10，而 `±2` 当初正是为封住这条而立的。

**② 1% 的分母 = 全部 event，且失去法则不限于战斗。** 比 08-05 的解读扩面一层，并**带出一条此前没有的结构：移除 `Power` 有两条通道，性质完全不同**——战斗内 `IgnoresProtection` 只作用于**本场**（Profile 不动），事件 outcome 侧的负向条目是**持久的**（写 Profile）。此前只设计了第一条。**连带**：`Power` 的「受保护」语义要分层表述（`IsProtected` 管战场可针对性，持有权保护是另一回事）；1% 的校验面从战斗内容**扩到整个事件池**，落点移到 future-event-service 的物化与加权侧。

**③ sync 缓冲闸门口径 = 事件级存档点。** 答结方案草稿暴露的实质张力（决策点密度 ≈31 点/场，旧口径下一场战斗打到第三个决策点就弹软阻塞）。**推论**：这把「存档点与 push 解耦」贯彻到了闸门口径上（**闸门计 push 单位，不计本地写入单位**）；**决策点存档回归本职** = 纯本地的崩溃恢复手段；**「决策点粒度决定 push 防抖压力」这句表述作废**，该待答的承重程度随之下降。

**④ `attemptIndex` 整层删除，改由 `CharacterProfile.chapterRetry` 承载。** 「篇章重试是否换一套战斗随机」答定为**换**，换法是给这次重试一套**新的随机流**而非再派生一层，故派生层无剩余职责。新增 `chapterRetry`（计数 ch1–3 各自的重试次数，因 ch2 · ch3 有上限），**它是计数器容器、不是上限持有者**。**「重开一局」说的是随机流，不是角色**——ADR-0004 的「篇章继承 = 全部继承」不变。

**新增待答 7 条（全部落在 `01-combat.md`）**，其中三条承重需裁决：**⚠ ch1 的带是对称 `±4` 还是非对称 `[−4, +2]`**（放宽动机全在下界，上界的 `+4` 才是落差元凶）· **⚠ 事件侧移除法则是否真的永久剥夺**（法则部分来自 premium bundle，永久剥夺等于销毁已付费内容；这条不定，1% 的分子无法编排）· **⚠ `chapterRetry` 的 ch1 计数挂在哪**（现状语义下 ch1 重试 = 随机生成新角色，角色级计数恒为 0，是死字段）。其余：降阶碾压是否需要独立呈现语言 · `±4`/`±2` 分档是否写进可调数值 · 事件侧「移除 `Power`」的 element 形态与软检查落点 · `chapterRetry` 的字段形态。移出记录见 `../answer-logs/log-0806.md`。

## 2026-08-05（draft-0805b）

本次是 **eventOptions 专场的第一场**，答结 **2 条**、部分答定 **3 条**，核心是**把 location 从抽象概念升格为带字段的内容条目**：

**① location 携带三组字段** —— **事件类型出现概率修正**（**软**框定：改权重不改可及性，故「按地点分池」这句旧措辞收窄）· **一组特定的 `EnemyTemplate`**（**硬**框定取池）· **`eventCountLimit`**（事件容量上限）。**承重推论：敌人物化的两条轴至此正交** —— **location 决定「派谁来」、角色等级 ±2 决定「有多强」**（答结了「物化时充实 / 改写规则」中取池的那一半）；且 location 已具备内容条目形态（应有稳定 `Id`、进 ContentRegistry、受 `ContentEnabled` 与 overlay 管辖），**载体定名仍待答**。

**② `eventCountLimit` 达成 → 本批收窄为仅剩 Travel。** **承载机制无需新增** —— Travel 以**最高 `eventPriority` + `ifMandatory = true`** 出场即可，**这是「一批可以全部 mandatory」的第一个真实用例**。**推论：Travel 由可选路由升格为结构性闸门**，进程的形状随之清晰（**一次篇章 = 若干 location 的串联，location 之间由 Travel 缝合**）；且 `eventCountLimit` 成为**与 `lifeSpanCost` 互相约束的第二个时长旋钮**，两者须一同反推目标时长。

**③ 跳过语义的两条残留细节由两条产出侧保证一次性闭合**（**答结**）：**不生成付不起 `skipCost` 的事件**（判定在每一次物化，含 `TryRefill` 补位那一次）+ **不生成整批全跳的 eventOptions**（每批至少一个 `IsMandatory`，给 `EventOptionBatch` 添了一条恒真不变式，**批次不可能被跳空**）。**两条都是产出侧约束而非消费侧处理** —— 问题在源头消解，下游不需要任何分支。

**④ 补位落空的判据 = 当前 location 的 `eventCountLimit` 用尽**（**答结**；不是事件池耗尽、也不是剧本约束）。与 ③ 合力使**死局兜底问题不再成立**：任何时刻至少有一个可推进的选项，且它不可被跳过。`TryRefill` 返回 `false` 的语义由「运气不好」变为「本地域已满，该走了」。

**反向抬高 1 条**：**付不起 `selectCost` 的死锁**变得更承重——既然每批必有一个不可跳过的选项，付不起它就直接卡死；`skipCost` 侧已有对称先例，但用户本次只对 `skipCost` 表态。**新增待答 5 条，全部落在 `02-event-options.md`**：location 的数据载体与连通关系 · ⚠ 上限达成时给几个 Travel 选项（原话为**单数**，两种读法的玩法差异不小）· `eventCountLimit` 的计数口径 · 类型修正的运算形态 · 已定稿批次存续期间资源下降的态度。**移入 `deferred-content.md` 1 条**：事件出现概率与地域配额的**具体数值**（用户明确归内容制作阶段）。**流程指示**：`pastEvent` 痕迹 schema 与其余 eventOptions 待答先走 `/provide-solution-draft`。移出记录见 `../answer-logs/log-0805b.md`（2 条，另 3 条部分答定）。

## 2026-08-05（draft-0805）

本次答结 **6 条**（1 条部分答定），其中一条是**挂了两天的承重矛盾**，且以**重定义规则**而非打补丁的方式收口：

**① 敌人赋级重定义为「角色当前等级 ±2」的对称带。** 取代 08-03 的「上界 = 高一个大境界的初期」——从**按境界给的绝对天花板**改为**相对 `diff` 的对称带**，且**首次给出下界**。**这直接答结了 ⚠ 赋级上界与 lifeTotal 的算术冲突**：最坏开局落差从 19 降到境界边界处的 9，落在 `lifeTotal` 10/10 之内，**「一次惨败打穿耐久」由规则层封住**，内容侧纪律退为第二道防线。**推翻**：08-03 的推论 ①「上界档必然越阶 ⇒ 最难即最不可读」作废。**新增的结构性推论**：越阶遭遇只可能出现在**每个境界的最后两级**（12 · 13 / 16 · 17 / 20 · 21），压迫感自动向篇章尾部集中，与 Finale 的位置同向。

**② 天劫同受此约束，连带答结「天劫是否天然大幅越级」。** 天劫只是 Enemy 的一种，无等级例外。自洽性验证漂亮：篇章末角色在境界巅峰（13 / 17 / 21），下一境界初期为 14 / 18 / 22，`diff` **恰为 +1**——**天劫不是大幅越级，但天然越阶 ⇒ Finale 全程无意图信息**，信息面的压迫感完整保留而数值面不失控。**连带**：赋级规则挂 Enemy 不挂事件类型，故 **Practice 同受约束**，其「低风险」由回合数与胜负门槛承担。

**③ 栈必须落存档，08-03 推论 ⑤ 被推翻。** 依据是**触发式异能在栈上若需选择目标，那次选择本身就是决策点**——「栈非空时双方都不能出牌」这条规则没错，错的是把它等同于「唯一的玩家输入时刻」。**承重连带**：结算不是原子的同步过程，`RunCombatAsync` 的结算循环须**可挂起、可从中途恢复**；**08-02b 的「决策点回落到回合 / 出牌这一级」被推回一层**。**不重新引入交互**（目标选择是结算自身的一部分）。**部分答定**——道具与 `Power` 的战斗内运行态字段仍未落定。

**④ 埋伏进敌人卡池，但不计入意图。** 玩家侧的「敌方有一张埋伏」计数指示由条件项**升为必做项**。**连带确立一条判据：凡不在敌人自己回合发生的东西一律不进意图**——它预先答了同类问题，也让埋伏成为与快照偏差性质不同的第二个不确定源（「根本没说」vs「说了没做到」）。

**⑤ `IgnoresProtection` 配额 ≈ 1% 的游戏场景。** 是**出现频次**口径而非条目占比口径，故**无法加载时机械化校验**——`PushWarning` 逐条列举保持不变，1% 落在内容编排与抽取权重侧。**分母口径待确认**，该确认项留在清单。

**⑥ 不会有凭空生成的牌（全局硬约束）。** 以**否定前提**的方式答结 08-03 的「落空时凭空生成的牌去哪」。**承重连带（存档面净减）**：一场战斗内的卡牌集合是**闭集**，存档只需各区 `Id` 序列 + `CardInstance` 运行态，不必为运行时新造的匿名卡分配 id；不借入 MTG 的 token，`CardType` 六分不需要第七类。

**新增待答（全部落在 `01-combat.md`）：** **⚠ `±2` 带与意图揭示阈值的算术冲突（承重 · 需裁决）**——ch1 的完整意图档**不可达**、无信息档只能靠越阶，ch2 · ch3 的完整档只剩 `diff = −2` 一个取值，而完整意图的定位正是「碾压专属」，`±2` 的下界把碾压本身封掉了；`±2` 是硬规则还是默认带（剧本调制能否推出带外）；境界边界处 `diff = +2` 的残余量纲（`lifeTotalLimit` 更高境界基线的硬输入）；挂起态的取消语义；需要选目标的触发式异能的频度；选目标态的呈现形态；「1% 的游戏场景」的分母口径。

移出记录见 `../answer-logs/log-0805.md`。

## 2026-08-04（mtg-loanwords-and-card-types）

本次答结 **5 条**，是战斗侧至今范围最大的一批——**借词定名把四个体系一次拉出水面**：

**① 借入的 MTG 术语第一批全部定名。** `sorcery speed` **不借、整条删除**（**机制原样保留**，改由「出牌时机（唯一）：自己回合的行动阶段、栈为空时」这条全局规则表述——单一取值的维度不是维度）；三步改称 **开始阶段 / 行动阶段 / 结束阶段**（`start step` / `action step` / `end step`，中文统一「阶段」、英文统一 `step`，`main phase` 弃用）；**`resolve` = 结算**（专指栈上对象），**战斗收口那处的「结算」改称「收口」（`settle`）**——一词两义消除；`trigger` = 触发。定名连带落定四个体系：**卡牌类型六分**（法术 / 灵宠 / 阵法 / 法宝·古宝 / 神通·法则 / 业障）· **异能三分**（静止式 / 启动式 / 触发式，与「载体」正交）· **永久物**（战场条目的**子集**，永不被结束阶段清理）· **次类型**（稳定字符串 id + `.tres` 注册表，非 C# 枚举）。**最大的结构变化 = 卡牌不再只有一个来源区**：卡组（受抽牌运）/ 储物袋中的道具（不受抽牌运，需动作）/ 开局入场的 `Power`（不受抽牌运，无需动作）。

**② 触发条件可跨归属方**（时点有归属方、监听方不必是），**埋伏牌（阵法的次类型 = 炉石的奥秘）由此成立** —— 它是本作**唯一一条在对手回合发生作用的通道**，且结算入口不变（StackManager 压栈），**这是移除交互后 stack 仍然承重的又一个证明**；AI 与玩家读到的都只是**埋伏计数**，是本作**第一处双向对称的信息规则**。

**③ 法则（PlayerPower）能承载战斗内触发** —— 作为 `CardType.Power` 开局入场，故 **combat-service 第一次需要读 PlayerProfile**；战斗内异能成为法则的第三条生效通道，**允许但极其稀缺**（`InCombat` 法则 ≤ 1/5、偏体验改善而非抬高道念上限、付费的战斗价值主要由**有次数限制的古宝**承载）。

**④ 意图 = 快照而非承诺，偏差不做处理**（**修正 08-02c 的措辞，非推翻**：「不重算」保留，「结果必然如此」收窄掉）。三个候选解全部不采用，**EnemyManager 因此不需要一致性校验与回退逻辑**——三个候选里唯一不新增状态的解；代价是**呈现层承担解释责任**（意图语气改「预估」+ 敌人回合执行过程逐步可见，这是本次唯一新增的 UX 硬要求）。

**⑤ 战场与两个参战方 manager 的划线判据 = 「是否在场上生效」而非「属于谁」，层级不动** —— 「属于谁」只是条目的一个字段，不是它的住处；单一战场记录 + `OwnerSide`，读侧统一走 `CombatSnapshot`、写侧分权；**BattlefieldManager 不提级**（否则变 god object，并强迫回答尚无判据的「module 以下的下沉判据」）。

**部分答定 1 条**：「回合内状态」的判定边界——永久物二分排除了一半（**永久物永不被结束阶段清理**），非永久条目的标记取值仍待答。**新增待答 6 条，全部落在 `01-combat.md`**：埋伏是否进敌人卡池 / 是否计入意图呈现 · 次类型清单与 id 形态（含阵法与灵宠的区分轴，用户明确留待日后）· `IgnoresProtection` 的内容配额 · 道具折价系数与战斗内法则的强度上沿（归 ch1 数值标杆专场）· 储物袋 UI 形态 · 战斗内道具与 `Power` 运行态的存档字段（并入既有的「战场与栈的存档形态」一条）。顺带把「战斗收口处的结算 → 收口」这条改名同步到 `scoring.md` / `life-total.md` / `combat/_index.md`。移出记录见 `../answer-logs/log-mtg-loanwords-and-card-types.md`（5 条，另 1 条部分答定）。

## 2026-08-04（0804）

本次是一次**结构落位** + **同轮答结 1 条**：新增顶层文件夹 **`art/`**，承载美术与音频的设计意图与生成指导。**一级分区 = 两个**：`visuals/`（已定，内含子分区 **`animations/`**——**动画归视觉**，同属一条视觉线、继承视觉总方向、因不走 AI 流水线故不设 `guides/`）· `soundtracks/`（已定）。定下**人机协作三段流水线**：人给 vision + 参考素材 → AI 写 art / audio guide（= 结构化 prompt）→ 参考 + guide 一并投喂生成工具（视觉为 Midjourney）。由此推出三条承重结构：**① 本库只承载流水线的 ①②，生成出的二进制资产归 `game-feature-branch/`**（design 分支是纯文档孤儿分支）；**② 总方向文档（`art-direction.md` / `audio-direction.md`）是每份 guide 的上游而非可选补充**——分次生成必然风格漂移，一致性只能由共同上游承担；**③ guide 须绑定资产类目并记录迭代结果**，才能与 `systems/` 的内容条目对齐、且下次不必从零试错。本次只立脚手架，内容待填。

**新增待答 9 条，全部落在 `deferred-content.md` 新设的「美术与音频」小节**（美术推进归开发路线靠后阶段，与内容充实一同搁置）。同轮**答结 1 条**：`animations/` 的分区归属 → **归 `visuals/` 之内**（移出记录见 `../answer-logs/log-0804.md`）。**部分答定 1 条**：音频生成工具**倾向 Suno 但未拍板** —— 已可据此定下工程纪律「guide 可暂按 Suno 组织，但工具专属语法不写死进模板、prompt 正文保持工具无关」，最终定案仍留在待答清单。顺带在 `vision/references.md` 与 `pillars.md` 的美术方向处加上指向 `art/` 的展开去处，`terminology.md` 登记 art direction / guide / 参考素材 / 资产类目四个工作流词汇。移出记录见 `../answer-logs/log-0804.md`（1 条，另 1 条部分答定）。

## 2026-08-03（0803）

本次答结 **6 条**，并把战斗的「场上」第一次显式建模：**① 引入 battlefield（战场）并新增 BattlefieldManager 与 StackManager 两个 manager** —— 战场记录场上全部准确数据（生效中的卡牌 / 持续状态 / **触发器注册面**），**栈与战场是两个区**（栈 = 等待结算的队列、战场 = 已结算并正在生效的东西），结算路径补全为「打出 → 入栈 → LIFO 结算 → 效果施加 →（若持续）落到战场」；连带 → **「回合内 / 跨回合状态」有了承载结构**、**TurnManager 回落为纯粹的回合状态机**、combat-service 的 manager 由三增至五、**战场须进入呈现层**；**② 满手时抽牌抽不进**（牌留在抽牌堆，「加入手牌」同理落空；不抽出即弃、不销毁）→ 手牌上限是**纯上界**、弃牌不是被规则强制的动作原语、满手的代价是 tempo 而非资源；**③ 触发式效果的载体开放**（牌上触发器 / 场上持续状态 / **神通 CharacterPower**，清单可再增）→ 需统一的触发注册面（坐在战场上）、压栈者恒为 StackManager、**轮回级能力必须能被战斗内读到**；**④ 道念下限 0 在每一次结算时截断**（溢出量不结转）→ 更保护落后方、**LIFO 顺序对最终结果有实际影响**、`PlayResult` 须带实际削减量；**⑤ 敌人赋级上界 = 高一个大境界的初期**（炼气 → 最高筑基初期）→ 上界档必然越阶 ⇒ **必然完全黑箱**；**⑥ power / item 两层的中文定名整体改写为 法则 / 古宝 / 神通 / 法宝**（**推翻 07-30b 的「`power` 通译 = 能力」**）→ 中文名不再表达层级对称，层级只在英文标识符上成立。

**新增待答 8 条**（`01-combat.md` 7 条、`07-codex-monetization.md` 1 条），其中**一条需用户裁决**：⚠ **赋级上界与 lifeTotal 的算术冲突** —— 上界按境界给而非按 `diff` 给，炼气一层对筑基初期开局落后 19 而 `lifeTotal` 仅 10，一次惨败即打穿耐久，恰是该上界原本要规避的情形。顺手清理两处遗留失真：`balance.md` 的意图分界值仍为 08-01b 旧取值（已按 08-02c 重写）、`architecture.md` 中已于 08-02 答定的「道念差换算归属」待决项（已移除）。移出记录见 `../answer-logs/log-0803.md`（6 条）。

## 2026-08-02（0802c）

本次**推翻意图分档取值**并**当场答结 6 条**：**① 同阶阈值整体下移，篇章分档保留** —— **ch1**：`diff ≤ -3` 完整意图 / `-2 ~ 2` 仅类别 / `≥ 3` 无信息；**ch2 · ch3**：`≤ -2` / `-1 ~ 1` / `≥ 2`（两端各收紧一级 → **后期境界内每一级差在信息面上更值钱**；越阶硬门与三档结构不变）；**② 完整意图 = 碾压专属，「仅类别」成为常态档**，**同级只给类别是有意为之、不做任何可读性补偿**（第二档的视觉语言与类别枚举由此升为承重）；**③ 意图 = 回合级综合描述**（一个回合对手可出多张牌）——**数值 = 计算后合并的最终结果**、**类别 = 主类别并行陈列**，不暴露张数与逐张分解；**④ 意图仅在玩家回合呈现，内容是敌人的下一个回合**（敌人回合内不呈现）。连带推论：**敌人 AI 是回合级一次性规划且规划时点前移到玩家回合开始之前**；**意图数值是声明量，与实际结算量可以不等**。

**同轮追加答结 2 条**：**⑤ 意图即承诺** —— 公布后**不因玩家行动重算、也不刷新显示**（玩家可据它布局；连带：EnemyManager 不走响应式 AI 路径、UI 无需表达「意图已变更」）；**⑥ 敌人回合内意图区收起**（不留占位、不换成其他指示）。

移出记录见 `../answer-logs/log-0802c.md`（6 条）与 `log-0802c_2.md`（2 条）。新增待答 2 条见 `01-combat.md` 的「等级与意图」。

## 2026-08-02（0802b）

同日 08-02 的**范围收窄修订**，答结 **4 条**：**① stack 保留为核心结算模型，但交互（instant / 栈非空时出牌）与优先权传递整体移除**——理由是它们**拉长对局时长、决策点过多、复杂度高而玩法深度收益小**（**推翻 08-02 的「响应窗口一并借入、回合是交互式的」**）；**② 回合结构 = 三步**（起始步：归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌 ／ 主阶段：唯一出牌阶段、只有归属方出牌 ／ 结束步：触发「回合结束时」→ 手牌上限弃牌 → 清理回合内状态），**去掉战斗步骤与双主阶段**；**③ 「定长 = 每场时长可预测」恢复成立**（无须为交互次数另设护栏），**决策点粒度不必覆盖响应窗口**，**EnemyManager 代理面回落**；**④ 所有牌都是 sorcery speed**、`instant` 明确不借、**手牌上限这条规则被确立**（数值未给）。

**同轮追加答结 3 条**：**⑤ 栈深由触发式能力入栈撑起** —— 在栈上的牌可以触发能力，**被触发的能力也进栈**，故即便只打出一张牌栈深也可大于 1（「主阶段连续压栈再统一结算」的候选路线**不采用**，「栈非空不能出牌」对双方都成立）；**⑥ 三步是回合归属方的流程，双方不同时走**（回合开始 / 结束是**有归属方的时点**，非同步公共时刻）；**⑦ 手牌上限是恒定不变式** —— **任何时刻都不得超出**，**没有时间限制、也没有必须弃牌的机制**（**推翻首轮三步表中的「结束步 → 手牌上限弃牌」**，结束步收窄为「触发『回合结束时』→ 清理回合内状态」），数值待定。

移出记录见 `../answer-logs/log-0802b.md` 与 `log-0802b_2.md`（共 4 + 3 条）。

## 2026-08-02（0802）

本次把道念从「规则骨架」推到「可结算」，答结 **7 条**：**① 道念差 → lifeTotal 损失 = 1:1**（不隔系数、不分档；道念差成为通用刻度）；**② 结算量的计算归属 = combat-service**，且**「获取奖励」属于战斗流程的一部分**（分工 = 计算归战斗、施加归生命周期，一次 `TryApply` 不变）；**③ 失败侧仍发 `baseReward`**，少数事件的**额外惩罚以负向条目包在 reward 内**、不另立结构；**④ 奖励分两类** = 强制自动计入（例：经验）+ 可选由玩家择一（参照 StS 战后面板）；**⑤ Practice / Combat / Finale = Balatro 的 small / big / boss blind**——**回合数与胜负条件都是遭遇参数**，标准 Combat = 10 回合 / 道念高者胜，Practice 更简单、Finale 更难；**⑥ 越级追分可能但很难**（境界差越大越难，`baseMomentum` 跨度放大正为此）；**⑦ `momentum` = `>= 0` 的 Integer**（削减为饱和减法）。

**随后又追加答结 4 条**（本次提出的待确认项全部拍板）：**⑧ 1:1 不设上限截断**——「一次惨败打穿耐久」**由内容设计侧规避**（不给出会导致该结果的等级差），约束转移为 future-event-service 的**赋级上界**，`lifeTotalLimit` 无需被迫与 `baseMomentum` 同量级；**⑨ 奖励选择不是决策点**（奖励预先算定，退出重开得到同样选项 → 候选生成须落在战斗的确定性边界内）；**⑩ 经验值 `experiencePoint` 是新字段**（每级一个经验阈值、事件发经验、达阈值才升级 → **推翻「事件 reward 直接给等级」**）；**⑪ stack 连响应窗口一并借入，回合是交互式的**（结算前对方可插牌 → **推翻「双方各 5 回合、我打完换你打」的简单交替**；TurnManager 多一层优先权内循环、EnemyManager 代理面扩大、「定长 = 时长可预测」被削弱）。

另**部分答定 2 条**（卡牌道念量纲基准、`lifeTotal` 回复幅度 → **归宿定为内容横向扩展阶段的「ch1 数值模型」专场**）。新增方向：**card / deck / combat 体系大量借用 MTG 术语**（须在 `terminology.md` 登记）。流程：**优先打磨 ch1 内容**。移出记录见 `../answer-logs/log-0802.md`（共 11 条）。

## 2026-08-01（0801b）

08-01 道念改写的**直接续篇**，把它留下的承重缺口一次性填上，答结 **9 条**：**① 战斗定长 10 个回合**（双方各 5，打满比道念；不设提前终止）；**② 道念产出途径 = 卡牌**（可互相削减、下限 0、**起始道念 = `baseMomentum`**）；**③ 胜利侧也读道念差** → 奖励厚度；**④ `life` 定名 `lifeTotal`**、**归 0 = defeated**、**经 event 恢复**（`DefeatReason.CombatLost` 作废）；**⑤ 意图三档的分界值给全** = **越阶硬门 + 同阶差值门槛**（推翻篇章容差表述）；**⑥ 敌人等级的来源** = `EnemyTemplate` + **future-event-service 物化时充实赋级**；**⑦ 全局等级序基数** = 连续 1–22 **不留跳变**（鸿沟改由 `baseMomentum` 承载）+ `baseMomentum` 表；**⑧ 敌人图鉴的记录深度** = 五项文案、**一次遭遇全解锁**（逐招式解锁否决）；**⑨ 抽象层级放开到五级并各自定名**（service / manager / **module** / processor / handler；`DeckManager` → **`DeckModule`**，「不设第三级」作废）。

另有**三项新增设计**：**图鉴扩为五个成族**（Enemy / CharacterPower / PlayerPower / CharacterItem / PlayerItem）、**篇章目标时长上调**（30–40 / 35–45 / 45–55 分钟，熟练玩家口径）、**首次给出商业化形态**（premium bundle：随机 1 PlayerPower + 2 PlayerItem + 篇章重试 3→9 / 1→3）。

**随后又追加答结 6 条**（本次提出的矛盾与待确认项全部拍板）：**ch1 分档 = `1–2` 仅类别 / `≥ 3` 无信息**；**`baseMomentum` 补齐**（筑基 20/24/28/32、金丹 45/55/65/75，表已完整）；**`CharacterPower` = 轮回级角色能力、对标 PlayerPower**（新建 `character-profile/power/`）；**平局 = 只发基础奖励**（不扣 lifeTotal，`CombatOutcome.Draw`）；**付费改写重试上限是有意的口径变化**（免费档为通关基准）；**`lifeTotal` 连代码字段一并改名**（`lifeTotal / lifeTotalLimit` / `RemainingLifeTotal`）。移出记录见 `../answer-logs/log-0801b.md`（共 15 条）。

## 2026-08-01（0801）

**对整条玩法循环的一次结构性评审 + 逐条裁决**，答结 6 条、部分答结 3 条，并推翻两处既有定案：**① 战斗模型改写**——**计分 = 道念（momentum），且道念就是胜负判据**（道念高者胜），**life 重定位为战斗外耐久**、只在失败结算时按道念差扣减，「life + mana 双资源 / 胜负 = life 归零」**全部推翻**，空白的 `scoring.md` 由此填满；**② 寿元定价 = 时长旋钮**——`lifeSpanCost` 由目标时长（15–30 / 15–30 / 20–40 分钟）反推分档，预算不变、逐篇章上调，**剩余寿元跨篇章结转**，且**内容侧写正数量值、物化时取负**（带符号约定不变）；**③ 隐藏属性跨档给一条定性叙事**（数值仍隐藏，寿元告警改两段式 30% / 10%）；**④ 等级成长 = 事件产出**（不只战斗类、失败也可能给）+ **敌人等级在 eventOptions 上精确标注**（否决模糊危险度档位）；**⑤ 失败侧首次有产出**（EnemyCodex 遭遇即记 + 道统残卷 = 递增的 PlayerPower 掉落概率，不发货币）；**⑥ 两处「不做」**（跳过配额 / 递增 skipCost 不做——前提不成立；`manaLimit` 下界护栏与死牌转化不做——情形罕见）。

移出记录见 `../answer-logs/log-0801.md`；更早的更新见 `../answer-logs/`（07-30b · 07-30 · 07-27b · 07-27 · 07-26b · 07-25c）。

# Open questions — 跨 session 待答清单（索引）

> 本文件是**客户端**（Godot 项目）待答清单的**索引**：问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 后端侧的待答清单在 `backend-design-documents/open-questions.md`（`backend-design` 分支）。
>
> 每次 session 结束时，未答的 Open questions 汇总到对应分片，供下次拾起；一旦答定，就从分片中移除、
> 归档进对应主题文档的 `## 待决问题` / `## 决策`，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> 本清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**。
>
> 最近更新：2026-08-19 — 十份已裁决草稿批量提炼（移出 20 条 · 跨库）
> （逐次变更摘要见 `open-questions/update-log.md`；已答定问题的逐条移出记录见 `answer-logs/`）

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序，**只留最近 10 条**。不含问题条目本身。 |
| `open-questions/update-log-archive.md` | 更早的更新摘要，原样归档、按时间正序。只读，不写新条目。 |
| `open-questions/01-combat.md` | **① 战斗机制**（焦点之首）：能力剥夺与统计计数的残留（片区主体已于 08-10c 答结）、结构与配置、内容与数值（多数已归 ch1 数值标杆专场）、**信息面**（意图移除后图鉴是唯一事前通道）、呈现。 |
| `open-questions/02-event-options.md` | **② eventOptions 生成流程**：生成 / 加权与配比、物化字段、优先级、寿元打穿、Explore 揭示池、Travel 出场、location 与图鉴连边。 |
| `open-questions/03-adventure-event-types.md` | **③ 逐类型 AdventureEvent 机制**（五类各开一场专门 session）。 |
| `open-questions/04-hidden-attributes-plot.md` | **④ 隐藏属性 / 剧本机制**：档位阈值、跨档叙事、`lifeSpanCost` 分档、隐藏属性推拉映射、DnD 选分支的触发点与 UI、剧本内容的分发粒度。 |
| `open-questions/05-service-contracts.md` | **⑤ 服务契约 / 工程侧残留**：`#if DEBUG` 判据与 `Control` 自动翻译的实测、需求流水线形态、`architecture.md` 的三条结构残留、层级词的过早性。 |
| `open-questions/06-meta-progression.md` | **⑥ 元进程的失败侧与中长期规划感**：轮回内的进度感是否需要补充、1% 存活分支的叙事补白落点。 |
| `open-questions/07-codex-monetization.md` | **⑦ 图鉴族与商业化**：`CharacterPower`、六本图鉴、premium bundle。 |
| `open-questions/cross-boundary.md` | **跨边界承接**：对侧（后端）已定案、本库尚未落笔的条目。**不是待答问题**——答案已有，等的只是落笔；形态、关闭条件与维护者分工见分片抬头。 |
| `open-questions/deferred-content.md` | **已搁置：内容充实**（07-30 起暂不推进）＋ **美术与音频（`art/`，08-04 加入）** ＋ 随内容搁置的 UX 呈现细节 ＋ 尚未设计的占位主题。 |

## 当前焦点：各系统机制细节

> **焦点判据（07-30 定）：** **规则、字段语义、流程与算法 = 机制细节 = 焦点**（分片 ①–⑦）；
> **具体条目目录与数值 = 内容充实 = 搁置**（`open-questions/deferred-content.md`）。
> 与既定开发路线「框架 → 内容 → 平衡与体验 → 社交及其他」的第 ① 阶段一致。
> Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。
>
> 焦点顺序即分片编号顺序；**① 战斗机制**优先级最高。

## derive 就绪度

> **本小节由 `/assess-derive-readiness` 独占写入**（`/analyze-new-ideas` 与 `/summarize-open-questions` 均不得改动）。就绪度是全库横切判断，须基于一次性全量扫描才有意义；逐次 handoff 顺带的评估会迅速过时且互相矛盾。

**最近全量评估：2026-08-20（由 `/assess-derive-readiness` 产出）。** 扫描范围：`vision/`（3）· `systems/**`（53）· `art/**`（12）· `ux/`（5）· `decisions/`（25），共 **98 份**。本次重估的触发是 08-19 那一批**十份已裁决草稿的集中提炼**（`CostKey` / `StatKey` 双清单 · `CodexEntry` schema 与六本触发 · `GameSetting` 清单与切分 · `deviceId` 落点 · 英文占位符形态 · `ProfileChangeSpec` 三处载体缺口 · `architecture` 三条结构残留（含新建 `systems/viewmodel.md`）· `PickMany` 短缺处置 · bundle 序号施加权 · 拆解粒度与签核语义）——**上一次评估记录的三处卡点（一处 🟠 承重、一处 🟠 三连、六处 `⟨待定⟩` 占位）全部倒下，全库已无一个 `⟨待定⟩` 占位符**。

**全局结论：ready 5 份 · partial 12 份 · blocked 81 份 —— 可 derive 的面由 12 份增至 17 份，且首次出现「服务骨架 + 写入通道 + 存档 schema + 上行同步」这条自上而下贯通的纵切。** 玩法侧仍未进入可 derive 阶段，剩下的卡点收敛为**两处，且只剩两处**：

- **🔴 ch1 数值标杆专场（唯一的大规模卡点，未动）。** 量纲基准 / `lifeSpanCost` 定价表逐格 / 三档奖励厚薄 / 回复幅度 / 商店四组数值格 / `HiddenStatGrade` 三个映射值 / Explore 真身占比 / 功法层数上限 / 闭关三格 / blind · ante 曲线。`systems/balance.md` 的待决问题仍是 11 条，几乎每条都标着「归 ch1 数值标杆专场」；其中**商店定价被 `currency.md` 的 jade 获取渠道阻塞**（产出侧空白时无从反推消耗侧）。
- **🔴 `future-event-service` 的生成 / 加权运算形态（四个非战斗事件子类型的共同上游，未动）。** 类型修正的算子（乘性 / 加性 / 白名单 + 权重）· 三层框定（location / PlotManager / seeded RNG）的叠加顺序 · **批次规模区间两端由什么驱动**（它同时决定 Travel 槽位数 `k`）。08-19 只答掉了它的 `PickMany` 短缺处置那一条，核心未动。

**本次倒下的三处（逐条对照上次评估）：**

- **✅ `CostKey` 资源族 element 清单**（上次的 🟠 承重）。反向穷举两张字段表得 15 个成员 + `StatKey` 首批 2 项 + 两族三条可机械核对的书写分野，并连带补上 `LastRoll` / `LastEffectiveChance` 两处无写入通道的真实缺口。它直接解锁 `systems/architecture.md`（升 ready）与 `systems/services/profile-service.md`（blocked → partial）。
- **✅ 「有纪律、无通道」三连**（上次的 🟠 新长出）。`activeCombat` 收进 `EventStateChanges` · RNG 子流另开 `RngElements` · `pastEvent` 追加落 `TraceElements`，三条通道全部补齐。
- **✅ 六处 `⟨待定⟩` 占位**。`CodexEntry`（首批一格 `Id` + `CodexElements` 新列 + 六本触发全部搭在既有提交上）与 `GameSetting`（账号级四项 + 设备本地一项 + 切分判据）双双落定，`PlayerProfile` 15 字段表的写入通道列**再无空洞**，`sync-service` 的本地缓存序列化面因此整份闭合（升 ready）。

**跨边界闭合（强制检查项）：维持全闭合，无一份客户端文档卡于「契约缺失」。** 后端六份契约悉数成文；`open-questions/cross-boundary.md` 的「待承接」仍是 **1 条**（`ComplianceManager` 客户端覆盖面的切分，是本库自己的取向，对侧不代为决定）。**一处需在 derive 时显式排除**：后端 `contracts/compliance.md` 的**六端点报文字段表与其自身错误码尚未落笔**，故 `account-service` 的合规呈现面在对侧成文前写不出可验证的验收标准——其就绪切片不含合规拦截的逐端点行为。

| 文档 | 判定 | 卡点 / 就绪切片 |
|------|------|------------------|
| `systems/common-properties.md` | **ready** | 待决问题为空、无占位、依赖闭合。整面 = 稳定 `Id` 与展示字段三层切分 · 物化模型 · `LocalizedText`（封闭二值 locale · `Get()` 纯读 · 不落存档）· `ContentEnabled` + `AllEnabled()` / `AllIncludingDisabled()` 双名与编译闸 · `RarityTier` 五档 · `SourceCode` + `Source` 八值 + 兜底 · `ExclusiveSource` · 两级 seeded RNG（轮回级四子流 + `State` / `DrawCount` 持久化；账号级 SplitMix64 三参数派生，8 组测试向量在 `backend-design-documents/contracts/profile-sync.md` §6a，验收可逐位对表）· API 契约总则三形态 / 三失败语义 · `deviceId` 的 `user://cache/device-id.json` 落点 |
| `systems/architecture.md` | **ready** | **本次由 partial 升级**：`## 待决问题` 明写「当前无未决项」——三条结构残留于 08-19 逐条收口（① 断线降级补上 push 侧退避形态 `2s ×2 / 上限 60s / 只向上抖动 / 无放弃阈值`，其余收为回链；② 热更「只改不增」两问皆已答，纯台账漂移已清；③ ViewModel 单列文档）。整面 = 三层切分 · 七服务边界与 autoload 注册顺序 · EventBus 总则 · API 契约总则 · 边界服务「接口 + Http/Offline 双实现」骨架 · `ElementSpec` 六列 / `ModifierKey` / 钳制表 · **`ProfileChangeSpec` 的完整列集合**（`Elements` / `AbilityElements` / `DeckElements` / `StatusChanges` / `PlotElements` / `EventStateChanges` / `RngElements` / `TraceElements` / `CodexElements` / `Stats`）· 「一个新的施加语义该落在哪一列」三级判据 |
| `systems/viewmodel.md` | **ready** | **本次新建**（08-19 由 `architecture.md` 的第三条残留分出）：`## 待决问题` 明写「当前无未决项」。整面 = 展示层第三层的结构契约（呈现期对象、不落存档 / 不进云端负载 · 单向依赖且服务 API 面永不返回 ViewModel · 组装源三件套 · 三条重组装触发面，含「订阅翻译变更即重组装」这条防「切语言后卡面不变」的承重纪律 · 只读消费与缓存归属 · 永不渲染清单）。**须与 `systems/architecture.md` 同批 derive**：三层切分的**定义**在 architecture、**展开**在本文件，分两次必出两份互相打架的 FR |
| `systems/services/sync-service.md` | **ready** | **本次由 partial 升级**：唯一残留的 `pushId` 后端记忆窗口是**后端侧参数**（客户端语义已定），本库侧无未决项；上次排除的 `CodexEntry` / `GameSetting` 两块子对象 schema 已于 08-19 双双落定，本地缓存序列化面整份闭合。整面 = 存档点 ↔ push 解耦 + 5 秒防抖 + 立即 flush 清单 + `PushPolicy` + 本地缓存原子写 + schema 版本化与迁移 / 拒绝 + `CharacterProfile` 级 diff + `revision` CAS / `pushId` 幂等 + `Source` 上行走成员名 + 后端主动写入后的 pull 时序 + 断线降级与退避阶梯 + 两层 Profile 的完整字段面 |
| `ux/onboarding.md` | **ready** | `## 待解问题` 明写「当前无未决项」，篇章门禁与「解锁 = 有可挑战角色」所读的 schema 已随 08-17h 闭合。整面 = 强制登录无游客 + 首版只呈现已实现渠道 + 手机两步握手 UI（验证码框 + 倒计时始终可见的重发按钮 + 过期重取，无 hover 提示）+ 绑定 / 解绑不落登录屏 + 首玩篇章门禁。**与 `ux/screen-flow.md` 的登录屏切片重叠，须同批 derive、不得出两份 FR** |
| `systems/character-profile/_index.md` | **partial** | 就绪切片 = `CharacterProfile` 完整存档 schema（23 字段逐格标注类型 / 写入通道 / 权威 + `Status` 具名子类 12 格 + `currentMana` 不入 `Status` 的判据 + 集合型 build 状态与 `Status` 平级）+ 角色 = 有身份模板（`CharacterData`、自带一个 `CharacterPower` + 两门绑定功法、绑定可弃置）。其余卡于：**角色模板池的形态**（承重——池规模 / 是否账号级解锁 / 能否重抽或指定，改写元进程压力模型）· 隐藏属性是否有第四项 |
| `systems/player-profile/_index.md` | **partial** | **切片本次扩到整张表**：15 字段表的写入通道列**再无空洞**（六个 Codex → `CodexElements` · `gameSetting` → 通道已定），加上规则层 / 统计层分层判据、三样不进 Profile 的排除项、三个具名子类（`PlayerStatistics` / `PlayerPowerFragment` / `PlayerEntitlement`，后者已含第二字段 `BundleRedeemedOrdinal`）。其余卡于：`Achievement` 条目 schema · 各账号级条目的解锁 / 获取触发 · `PlayerPower` 平衡边界 |
| `systems/services/profile-service.md` | **partial** | **本次由 blocked 升级（`CostKey` 卡点倒下的主受益方）**：就绪切片 = `ProfileChangeSpec` 的**全部十列**与逐列失败语义 + `CostKey` 15 成员 / `StatKey` 首批 2 项 + 两族三条书写分野与成员名冻结 + `ResourceElements` 配表六列 + `TryApply` 的整批原子性与钳制 + 三处新补通道（`ActiveCombat` / `RngElements` / `TraceElements`）+ `CodexElements` 的四行失败语义与 `#if DEBUG` 护栏。其余卡于：capability flag 枚举与叠加 / 冲突规则（承重）· `status` × 拥有 / 失去的存档表达 · 成就采集面（EventBus 被动 vs 主动上报）· 成就两档奖励内容 · `PlayerPower` 平衡边界 |
| `systems/services/account-service.md` | **partial** | **切片本次扩大**（`deviceId` 落点已于 08-19 落定：客户端生成 · `Guid.NewGuid().ToString("N")` · `user://cache/device-id.json` 单字段不带 `accountId` · 排除全部平台硬件标识的合规理由）= 会话生命周期 + 四个账号方法（登录 / 绑定 / 解绑 / 改名）+ refresh 失败拆两条路径（网络失败 → 缓冲通道 / `auth.session_revoked` → 硬阻塞重登 + 暂停退避）+ `AccountInfo` 五字段 + 被挤下线后「先 pull 后 flush」。其余卡于：`ComplianceManager` 客户端覆盖面的切分（唯一在办的跨边界承接项）· **合规呈现面须整体排除**（对侧 `contracts/compliance.md` 六端点报文字段表未落笔，验收断言写不实）· refresh token 客户端持有形态的落笔（硬约束已成立：不得与 `device-id.json` 合进同一文件） |
| `systems/services/content-service.md` | **partial** | 就绪切片 = 启动期 manifest 比对 + blob 内容寻址 + ES256 签名校验 + 文件级事务 + overlay 合并 + 合并后全量校验 + `AllEnabled()` 取池 + 断网降级到随包基线 + 语言覆盖率审计（含 08-19 定的「空单元格即未翻译」判据与 `fallback = "zh"`）+ overlay 剧本例外的 `newIds` 双闸 + 可执行化阶梯四处应用。其余卡于：flags 拉取频次护栏 · disabled 条目被存档引用时的 UX · 剧本树按篇章分包的边界 |
| `systems/player-profile/game-setting.md` | **partial** | **本次由 blocked 升级**：就绪切片 = 切分判据（「取值是否取决于这台机器」+ 换机自检反问 + 拿不准归设备本地 + 一项只落一侧）+ 账号级四项（`MasterVolume` / `MusicVolume` / `SfxVolume` `int [0,100]` · `FastCombatAnimation` `bool`）+ 设备本地一项 + 写入通道与 `PushPolicy` + locale 衔接。唯一残留：三条音量轨默认值 100 / 80 / 100 是**待实测初值**（相对关系有依据，绝对值待真机与响度目标校准）——不阻塞结构，derive 时按初值写入并标注可调 |
| `systems/player-profile/codex/common-properties.md` | **partial** | **本次由 blocked 升级**：本文件自身已无未决项。就绪切片 = **图鉴的存档与写入面** —— `CodexEntry` 首批一格 `Id`（计数与首次解锁元数据两组候选全部不落，附三条依据与「逐条目计数不可得」的代价）+ `CodexKind` 六值 / `CodexUnlock(Kind, Id)` + `CodexElements` 新列与零 `Op` / 恒不经 pipeline + 四行失败语义 + 六本的解锁触发（全部搭在既有提交上，零新增提交点）+ 四本能力 / 道具类的词条深度。其余卡于**呈现面**（`codex/_index.md` 的入口与浏览形态、`LocationCodex` 显影粒度），故 derive 时**只取存档 / 写入切片，不取任何图鉴屏**；建议与 `player-profile/_index.md` 同批 |
| `ux/error-and-blocking-ux.md` | **partial** | **切片本次补齐了唯一带行为面的缺口**（08-19：未翻译 = `en` 单元格留空、不写哨兵 · 两条连带禁令 · `project.godot` 设 `fallback = "zh"` 让回落零分支 · `ErrorText.For` 的 `PushWarning` 判据订正为「默认语言 `zh` 下无条目」）= 翻译键基建（`res://text/` 分区表 + 键命名三条 + `ERR_*` 由 `code` 机械变换 + `reasonKey` 三参 `ErrorText.For` 与静默回落 + 两条审计 + locale 启动期归一）+ 灰态判据 + `BlockingNoticeScreen` 一屏三变体 + 三档版本提示去重。其余卡于：逐条中文措辞（内容充实，不阻塞结构）· `auto_translate_mode` 与 `#if DEBUG` 判据的实测（文档自陈不阻塞任何已定案内容，宜合并到 `.csproj` 生成后的一次实测） |
| `ux/screen-flow.md` | **partial** | 就绪切片 = 登录屏 + 主菜单五入口导航骨架与 Store 三条呈现纪律 + 建议更新横幅去重 + 储物袋全屏面板形态 + 玩家档案屏的绑定 / 解绑列表与两处二次确认 + 各入口读取的两层 Profile 字段逐格可指。其余卡于：元婴证书形态 · 成就两档奖励内容 · 寿元告警是否伴音效 / 震动 · Explore 揭示转场时长与音效实测 · 图鉴入口与浏览形态 |
| `systems/adventure-event/common-properties.md` | **partial** | 就绪切片 = `EventOption` 13 格物化字段（含 `OutcomeSpec` / `Encounter` / `ExchangeStock` / `RerolledCount` / `DestinationLocationId` / `RevealedEventId`）+ 「产出即定稿、不得回查模板重算」+ 事件收口的事务语义（收口是一次事务、一个存档点；事件内部的主动消费即时提交，附两条可判定判据）+ `PastEventEntry` 与 `AppliedChange` = 「本次事件的最终账」+ 成本侧 `LifeSpan` 取值域非负。其余卡于：**可用事件的生成 / 加权运算形态**（🔴 上游）· `lifeSpanCost` 定价表逐格取值（🔴 ch1 专场） |
| `systems/monetization.md` | **partial** | **切片本次补上兑现幂等的最后一环**（08-19：`BundleGrantOrdinal` 施加权收口为「后端唯一 +1」、该行整行撤出 `ResourceElements` 从而白得一条硬闸；客户端侧新增水位字段 `BundleRedeemedOrdinal`，不变式 `0 ≤ Redeemed ≤ Grant`）= 付费凭证 `PlayerEntitlement` + 空池三道闸 + 购买入口三条前置条件与灰态 + 兑现事务（`AccountRng.For(PremiumBundle, ordinal)` 一次派生连抽 3 条 → 一次 `TryApply` → `Immediate` push）+ 五项排除。其余卡于：平台内购 SDK 明确在 MVP 之外（购买段无法落地）· `K` 与 `GrantPoolMargin` 数值待内容规模 · 两个通用池当前条目为零 · 纯外观付费点未定案 |
| `vision/pillars.md` · `vision/references.md` · `vision/scope.md` | blocked | 北极星 / 参考登记，**非 derive 对象**（作为其余文档的挂靠前置；`scope.md` 的美术资源策略与合规立场未定） |
| `decisions/ADR-0002` ~ `ADR-0024`（23 份 Accepted） | blocked | 已采纳的决策记录，**非 derive 对象**（作为其余文档的就绪前置，本身不产 FR） |
| `decisions/ADR-0001-example.md` | blocked | 示例占位，`## Decision` 明写「待定」；status 仍为 Proposed |
| `decisions/_index.md` | blocked | 台账，非 derive 对象 |
| `systems/_index.md` · `systems/services/_index.md` · `ux/_index.md` | blocked | 导航索引，非 derive 对象（各自的待决项已下沉到对应主题文档） |
| `systems/balance.md` | blocked | 🔴 **ch1 数值标杆专场未开——本库唯一的大规模卡点，待决问题 11 条**：`lifeSpanCost` 定价表逐格 · 卡牌道念产 / 削量纲基准 · 敌人各级产出缩放 · 战后奖励池 `RarityTier` 权重 · 商店四组数值格 · 回寿量三档点数 · 闭关三个数值格 · Explore 真身占比校准 · 带边界配置落点 · 重试上限数值 · blind / ante 缩放曲线。**其中商店定价被 jade 获取渠道阻塞**。（注：其「成本类型的 element 清单」一条已由 08-16d 的成本侧收口与 08-19 的 `CostKey` 清单覆盖，属活文档漂移，留待 `/summarize-open-questions` 清理） |
| `systems/game-progression.md` | blocked | 🔴 eventOptions 生成 / 加权的运算形态未定 · 三层框定叠加顺序未定 · `eventCountLimit` 可否被剧本推拉未定 · 中长期进度感那一半未定 · 选择区排布与滑动手感未定 · blind / ante 未陈述 |
| `systems/scoring.md` | blocked | 规则面已定（道念产削 / 下限 0 / 胜负两条支路 + 单价表 / 负侧 1:1），但三档 `BaseReward` / `RewardPoolId` 取值与卡牌量纲基准均归 ch1 专场；且它必须依附一场可运行的战斗，而 `combat-service` 的战斗内容整体为空 |
| `systems/adventure-event/_index.md` | blocked | 五类之间的配比未定 · Combat 内 `combatTier` 三档配比未定 |
| `systems/adventure-event/combat/_index.md` · `combat/common-properties.md` | blocked | 量纲基准与三档奖励厚薄归 ch1 专场 · 敌人 AI 规划形态未定 · 隐藏属性与战斗资源的其余耦合面未定 · 失败后果其余部分未定 · 敌人 schema 其余字段未定。**注：该 `_index.md` 仍把「效果关键字体系与目标规则」列为承重未决，此条已由 08-16c 收口，属活文档漂移**（本技能不改主题文档，留待 `/analyze-new-ideas` 或 `/summarize-open-questions` 清理） |
| `systems/adventure-event/exchange/_index.md` · `exchange/common-properties.md` | blocked | 机制面已于 08-17d 全面收口，短缺处置已于 08-19 补齐（三道闸）；卡于四组数值格全欠（ch1 专场，且被 jade 获取渠道阻塞）· 满袋能否购买（阻于储物袋满袋处理）· 🔴 上游取池 / 物化链路（`future-event-service` 生成规则）未定 ⇒ 无可独立成立的切片 |
| `systems/adventure-event/research/_index.md` · `research/common-properties.md` | blocked | 机制面已于 08-17b 全面收口，候选短缺三道闸已于 08-19 补齐；卡于三个数值格与功法层数上限（ch1 专场）· 风险档的竖屏呈现未设计 · 🔴 上游生成链路未定 |
| `systems/adventure-event/explore/_index.md` · `explore/common-properties.md` | blocked | 机制面已于 08-17c 全面收口，`common-properties.md` 的待决问题明写「无」；卡于两个待实测初值与定价表 Explore 行（ch1 专场）· 🔴 事件类型概率修正的运算形态与上游生成链路未定 ⇒ 无可独立成立的切片 |
| `systems/adventure-event/travel/_index.md` · `travel/common-properties.md` | blocked | 载体与结算已收口（`LocationData` + 单份 `LocationMapData`、恒启用、80/20、`DestinationLocationId` 物化时掷定、两条 `StatusAssignment` 由 life-cycle-service 组装）；卡于 🔴 事件类型概率修正的运算形态 · 🔴 槽位数 `k` 的来源（依赖批次规模区间两端）· Travel 行定价（ch1 专场）· 失去 flags 关地域后的运营替代 |
| `systems/enemies/_index.md` · `enemies/common-properties.md` | blocked | `EnemyData` 其余字段未定 · AI 决策算法未定 · **敌人池的篇章框定载体未定**（`EnemyData` 上无字段表达篇章 ⇒ 空池校验只能按 `EventType` 单维）· 道念产出缩放归 ch1 专场 · 敌人是否也以功法构筑卡组未定 |
| `systems/character-profile/currency.md` | blocked | jade 的获取渠道 / 掉落权重整体未设计（承重）——**它同时卡住商店定价表的全部绝对数字** |
| `systems/character-profile/deck/_index.md` · `deck/common-properties.md` | blocked | 效果三层 + `KeywordData` + target / scope 分离 + `EntryFilter` + `CardType` 五分 + `Subtypes` + `Pool` 已收口；仍卡于：`CardData` 的**费用与触发器两格仍是结构占位** · 效果流水线阶段划分未定 · starter deck 未设计 · 功法规模参数与量纲基准归 ch1 专场 · 关键字与次类型首批清单为空 |
| `systems/character-profile/item/_index.md` · `item/common-properties.md` | blocked | **战斗外道具的使用入口未设计（承重）**——阻塞回寿法宝定稿，连带两问（是否单独构成存档点 · 事件外使用时无 `PastEventEntry` 可挂）· 储物袋满 9 格的处理未定（承重）· 道具种类目录与「什么该做成卡 / 道具 / 神通」的判据未给 · 共有字段无实质设计 |
| `systems/character-profile/life-total.md` | blocked | 规则面已定（境界基线 10 / 25 / 40、归 0 = 角色终结），回复幅度与来源分布归 ch1 专场；且不构成可独立成立的 FR 面 |
| `systems/character-profile/mana.md` | blocked | 更高境界的基线跃升未定（`lifeTotal` 已定为境界跃升，mana 尚未表态） |
| `systems/character-profile/power/_index.md` · `power/common-properties.md` | blocked | 战斗外那一半的复用边界未定（承重——capability flag / modifier pipeline 注册面是否两层共用、持有列表与清理规则落点）· 战斗内运行态计数器的存档形态未定 · 获取 / 失去触发未定 · `common-properties.md` 明写「待定的字段清单」 |
| `systems/player-profile/account-info.md` | blocked | 字段面五项已定，仅剩合规字段归属一条待后端分级 ⇒ 表仍可能增行；**且它单独不构成可独立成立的 FR 面**，应随 `account-service` / 登录切片一并落地 |
| `systems/player-profile/achievement/_index.md` · `achievement/common-properties.md` | blocked | 成就条目 schema 与进度模型未设计 · 触发采集面（EventBus 被动 vs 主动上报）未定 · 两档具体奖励条目清单未定 |
| `systems/player-profile/codex/_index.md` | blocked | `LocationCodex`「记连边」的显影粒度未定（承重）· 其余词条深度未定 · 六本的入口与浏览形态未定（含战斗内能否查阅）⇒ **呈现面整体无可 derive 的切片**；存档 / 写入面已下沉到同目录的 `common-properties.md`（见上方 partial 行） |
| `systems/player-profile/codex/enemy-codex.md` | blocked | 五项词条规格本身已定且无未决项，但词条的数据源逐项落在 `EnemyData` 上，而 `EnemyData` 字段清单未定 ⇒ **依赖未闭合**，写不出可验证的验收标准 |
| `systems/player-profile/player-item/_index.md` · `player-item/common-properties.md` | blocked | 道具目录与次数补充机制未设计 · 战斗内运行态存档形态未定 · 共有字段无实质设计 |
| `systems/player-profile/player-power/_index.md` · `player-power/common-properties.md` | blocked | `RelicData` 字段清单与触发器体系未设计 · capability flag 枚举与叠加 / 冲突规则未定 · 战后奖励池权重表未定 · 平衡边界未定 |
| `systems/services/combat-service.md` | blocked | 战斗内容整体为空（卡牌定义 / 起始卡组 / 敌人目录 / 遭遇编排）· 敌人 AI 决策形态未定 · Finale 奖励加厚幅度归 ch1 专场 |
| `systems/services/future-event-service.md` | blocked | 🔴 生成 / 加权的运算形态未定（承重——**四个非战斗事件子类型 partial 化的共同上游**）· `EventOutcomeSpec` 内部字段面阻于效果关键字那条 · 框定叠加顺序未定 · `Priority = 1` 的其余抬升条件未定。（`PickMany` 抽不足的两个调用侧处置已于 08-19 答结） |
| `systems/services/life-cycle-service.md` | blocked | 非战斗四类的决策点清单未给 · `Project(spec)` 只读投影的语义面未定 · `experiencePoint` 阈值曲线未定 · 隐藏属性增减触发未定 · 重试上限的存档表达未定 · 元进程各字段解锁 / 获取触发未定。（**RNG 状态的写入通道已由 08-19 的 `RngElements` 答结**） |
| `systems/services/plot-manager.md` | blocked | 数据编码已收口（`PlotArcData` + `PlotNodeData` · 正文内嵌 · key points 每 arc 一条 · `PlotModulation` 六字段 + 加载期悬空校验 · 排队 arc 落存档）；仍卡于：多条 `Active` arc 的 `PlotModulation` 合并算法（🔴 阻于框定叠加顺序）· DnD 式选分支的触发点与 UI · 隐藏属性的逐条推拉映射 · 剧本分包边界 · `HiddenStatGrade` 三个映射值待 ch1 专场 |
| `ux/combat-ux.md` | blocked | 竖屏分区整体是否过载（承重，**已排期专门 session**）· 结算 ticker 文案体系（承重，唯一动态情报通道）· 栈与战场同屏呈现（承重）· 出牌手势 / 手牌布局 / 疲劳呈现 / 节奏整体未设计 |
| `art/_index.md` · `art/visuals/_index.md` · `art/soundtracks/_index.md` | blocked | 流水线说明与资产类目表；本库不承载生成产物（归 `game-feature-branch/`），无客户端行为面可 derive。`visuals/_index.md` 另有 4 条未决 |
| `art/visuals/art-direction.md` · `art/soundtracks/audio-direction.md` | blocked | 主体各节仍为 `> _（待写）_` 占位（各 6 处）——**尚无设计意图** |
| `art/visuals/animations/_index.md` | blocked | 明写占位：范围 / 技术载体 / 制作方式 / 与战斗节奏的关系待咨询专业人士后确定，**尚无设计意图** |
| `art/visuals/references/_index.md` · `art/soundtracks/references/_index.md` | blocked | 参考登记表基本为空，且二进制是否入库未定 |
| `art/visuals/guides/_index.md` · `art/soundtracks/guides/_index.md` | blocked | guide 台账为空，**尚无任何 guide** |
| `art/visuals/guides/_TEMPLATE.md` · `art/soundtracks/guides/_TEMPLATE.md` · `content/_TEMPLATE-*.md` | blocked | 模板骨架，非 derive 对象 |

### 建议的 derive 顺序（仅限 ready / partial 项；被依赖者在前）

1. `/derive-requirements systems/common-properties.md` —— **唯一整份就绪且被几乎所有内容与服务代码依赖的地基文档**。共有字段类型与两级 RNG 先落，后面每一份 FR 都能直接引用而不必各自重新约定。账号级 RNG 的验收有现成的 8 组测试向量，是全库当前最硬的验收标准。文档自己也写明排期——`LocalizedText` 与 `DrawPool<T>` 同批、**在写下第一批 `.tres` 之前**，窗口一旦关闭每多一条内容就多一份要改的资产。
2. `/derive-requirements ux/error-and-blocking-ux.md` —— 翻译键基建（文档自己已点名 `FR-ux-translation-foundation`）。**无上游依赖**，是「每屏从第一行起就用键」这条起手纪律的前置，越早越省返工；08-19 补上的空单元格判据与 `fallback = "zh"` 使覆盖率审计第一次可写成可验证断言。
3. `/derive-requirements systems/architecture.md` + `systems/viewmodel.md` —— 服务骨架：七个 autoload 的注册顺序、EventBus、边界服务的接口 + Offline stub 双实现、`ProfileChangeSpec` 的完整列集合。**两份同批处理**：三层切分的定义在前者、展开在后者，分两次必出两份互相打架的 FR。
4. `/derive-requirements systems/services/profile-service.md` —— **本次新解锁**：写入通道这一层地基（十列 spec + `CostKey` 15 成员 / `StatKey` 2 项 + `ResourceElements` 配表 + `TryApply` 原子性与钳制 + 逐列失败语义）。它必须先于任何写 Profile 的系统。**排除 capability flag 的叠加 / 冲突规则与成就采集面。**
5. `/derive-requirements systems/character-profile/_index.md` + `systems/player-profile/_index.md` + `systems/player-profile/codex/common-properties.md` + `systems/player-profile/game-setting.md` —— 两层 Profile 的存档 schema 地基（数据类 + 序列化 + `schemaVersion` 与迁移）。**四份同批处理**：它们互相引用、共用同一个 `schemaVersion` 与同一条迁移路径，分批 derive 必出互相打架的 FR。`codex` 与 `gameSetting` 两块本次首次可指，**但只取存档 / 写入面，不取任何图鉴屏或设置屏的呈现**。
6. `/derive-requirements systems/services/content-service.md` —— 内容加载与校验链路（契约已成文；依赖 1、3）。它被一切内容读取方依赖，应先于任何玩法系统。
7. `/derive-requirements systems/services/sync-service.md` —— **本次由 partial 升 ready，排除项清零**：本地缓存原子写 + push 调度与退避 + CAS / 幂等 + 两层 Profile diff 的完整字段面（依赖 1、3、4、5）。
8. `/derive-requirements ux/screen-flow.md` + `ux/onboarding.md` —— 登录屏 + 主菜单导航骨架（依赖 2、3、5）。**两份同批处理**：登录屏切片在两份文档中重叠。
9. `/derive-requirements systems/services/account-service.md` —— 会话生命周期 + 四个账号方法 + refresh 两条路径 + `deviceId` 落点（依赖 2、3、8）。**合规呈现面整体排除**（对侧报文字段表未落笔）。
10. `/derive-requirements systems/adventure-event/common-properties.md` —— **只取 `EventOption` 的数据形态与事件收口的事务语义**（依赖 1、5）。它是玩法侧唯一具备可独立成立切片的文档，且这一切片是后续全部事件类型 FR 的共同类型地基。**不取生成 / 加权面。**
11. `/derive-requirements systems/monetization.md` —— 兑现段 + 三道闸 + 入口前置条件 + 兑现水位幂等（依赖 1 的账号级 RNG、7 的 push 调度）。**排在最后**：它是唯一一份依赖两个通用内容池的 partial，而池当前为空；**只取兑现与拦截，购买段等平台 SDK（MVP 外）。**

> **仍然不要**对战斗 / 卡组 / 敌人 / 平衡 / 元进程 / 图鉴呈现侧任何文档 derive。四个非战斗事件子类型的机制面早已收口，欠的仍是同两处：**ch1 数值标杆专场**与 **`future-event-service` 的生成 / 加权运算形态**。这两场 session 是解锁整个玩法侧的最短路径，且第二场的门槛比第一场低得多——它是**四个子类型 + `game-progression` + `plot-manager` 合并算法**共六份文档的共同上游，而 ch1 专场只欠取值、不欠结构。

## 下一阶段

- **ADR 状态：** `decisions/` 现有 **23 份 Accepted**（`ADR-0002` ~ `ADR-0024`，`ADR-0001` 为 Proposed 示例占位）。
  台账与逐条影响文档见 `decisions/_index.md`。**当前无待固化的 ADR 候选。**
  （注：ADR 现可自由编辑，改决定直接改 ADR，不再新开取代 ADR。）
- **流水线闭环（07-30）：** design → code 链路补上 `/breakdown-requirements`（一份 FR → 一个文件夹的可执行子需求），完整形态见 `README.md` 与 `requirements/_index.md`。
- **架构闭环缺口：** 8 处**全部闭合**（移出记录见 `answer-logs/log-0725c.md` 与 `log-0726b.md`）；状态表见 `systems/architecture.md` 的「闭环缺口」小节。残留细节已下沉为各焦点分片的普通待决问题。

# Phase A — arch-residuals

输入：`game-design-documents/inbox/solution-draft-architecture-structural-residuals.md`（`status: decided`）
目标库：`game-design-documents/`（草稿 `targets:` 全部落在客户端库；退避为纯客户端行为，**无对侧库承接项**——已复核 `sync-service.md` 的 `Retry-After` / `detail.retryAfterSeconds` 消费语义 C6 确已定，本次不新增契约面）

## 一句话摘要

草稿把 `systems/architecture.md` 待决问题里的三条结构残留收口：①「断线降级」改写为一行回链 + 补 push 退避的参数形态（4 行进 `balance.md`、3 处增补进 `sync-service.md`）、②「热更只改不增的连带项」整条删除（两问在 `content-service.md` 已答定）、③ 新建 `systems/viewmodel.md` 并把三处落点改为回链。**两条「已答定」的说法经逐条核实全部成立**；但草稿用来论证 ③ 的两处事实**不成立**（见 🔴-1 / 🔴-2），另有一处退避公式与既有权威相抵（🔴-3）。

## 已定案项（用户已裁决，不进 interview）

| # | 裁决 | 出处 |
|---|---|---|
| D1 | push 退避 = `2 s · ×2 · cap 60 s · jitter ±20% · 无放弃阈值`，四行进 `balance.md`「同步 / 内容管线旋钮」表 | 草稿「用户裁决」表（2026-08-19） |
| D2 | ViewModel 层**现在**单列 `systems/viewmodel.md`，不等第一份 UI FR；三处落点各留一句回链 | 同上（2026-08-18 已裁，照录） |
| D3 | 「展示层三层切分」ADR 固化时**主落点 = `systems/viewmodel.md`**，`architecture.md` 保留三层定义段 | 同上 |
| D4 | 1a 那张 25 行全景降级表**不落库**；落库的只有三条不变式 + 一行索引 | 同上 |
| D5 | ②「热更只改不增的连带项」在 `architecture.md` 待决问题里**整条删除**（不留回链） | 同上 |
| — | ② 的两个连带项照录为已答定：预埋占位 `Id` → **否决**；存档记 `contentVersion` → **采纳，记两个** | 同上 §2 |

> 上述六项**不重新征询**。🔴-1 / 🔴-2 只推翻草稿为 D2 记录的**承重理由与落点文件名**，不推翻 D2 本身的结论。

## 「已答定」说法的逐条核实

| 条目 | 草稿声称的权威出处 | 核实结果 |
|---|---|---|
| ① 断线降级的具体行为 | `services/sync-service.md`「断线降级」+「`Immediate` flush 的失败语义」+「`Upgrade` 类错误在非闸门点」；`account-service.md` 刷新失败分流；`content-service.md` 两条降级 | **成立。** `sync-service.md` L71–90 有「断线降级」节：总原则「绝不回退存档点」原话在 L73；Push / Pull 两行降级表 L75–78；两个闸门 3 / 180 s 在 L82；软阻塞时机「下一次 AdventureEvent 选择前」L87；`rate.limited → OpError.Network` + `max(本地退避计算值, 服务端给的等待时间)` + 「限流绝不映 `Conflict`」L88；恢复后合并语义 L89；token 刷新失败分流 L90。`Immediate` flush 失败语义整节 L134–151（含「进入战斗前 flush 失败不挡玩家」四条依据、「不产生任何额外提示」L151）。`Upgrade` 类错误整节 L153–163（四条处置 + 暂停退避 + 唯一解除条件 = 重新登录成功）。`account-service.md` L16 有「网络失败 → 视同断线，走 sync-service 同一条缓冲通道」。`content-service.md` 有断网降级（L157 更新流程第 ④ 步）与 flags 拉取失败降级（L130 / L266）。**结论：该条确属过期登记，唯一真实空白就是草稿点出的 push 侧退避参数形态。** |
| ②-a 预埋占位 `Id` → 否决 | `content-service.md`「放量开关 `ContentEnabled`：不预埋占位 `Id`」 | **成立，且逐字吻合。** `content-service.md` L55 小节标题即「### 放量开关 `ContentEnabled`：不预埋占位 Id」；L57 原话：「**否决「预埋空壳 `Id`、日后用 overlay 填充数值文案」。** 两条理由：① 与「合并后强校验」直接冲突——空壳条目要么迫使校验放宽（丢掉启动期早失败这条纪律），要么携带假数值被抽中；② 属应用商店审核灰区（随包发的是不可玩的壳）。」草稿转述的两条理由与原文一致。三层覆盖（`.tres` 默认 → overlay → flags 按账号解析）在 L61 + L112–130，「秒关走 flags」原话在 L61。 |
| ②-b 存档记 `contentVersion` → 记两个 | `content-service.md`「存档记录 `contentVersion`：记两个」 | **成立，且逐字吻合。** L134 小节标题「### 存档记录 `contentVersion`：记两个」；L138–139 两行表即 `CharacterProfile.StartContentVersion`（写一次不再变）/ `CharacterProfile.LastContentVersion`（每个自动存档点更新）；L141 原话「因不冻结 `contentVersion`（见上节），一个版本号无法表达「跨过」，故必须记两个」；L142 push 信封携带 `contentVersion` / `appVersion` / `revision`。旁证：`life-cycle-service.md` L177 明写「每个存档点同时更新 `CharacterProfile.LastContentVersion`」、L178「`StartCycle` 附带写入 `StartContentVersion`（此后不变）」；`sync-service.md` L69 信封字段一致。**存档 schema 零影响的判断成立**（两字段已在册）。 |
| ③ ViewModel 落位「确实未答」 | — | **成立。** `architecture.md` L596 待决问题第四条原文在册；`open-questions/05-service-contracts.md` L31 三条残留一并登记；`open-questions.md` L62 的 derive 就绪度行把这四项列为 `architecture.md` 的卡点，与草稿描述一致。 |

**核实小结：草稿最核心的主张（②纯台账漂移、①主体已答定）完全成立，可照此收口。** 不成立的是草稿用于论证 ③ 的两处支撑事实与一处退避公式，见下。

## 🔴 冲突

### 🔴-1 「纪律 7 至今没有任何主题文档承载它」——不成立

- 草稿 3a 表第 7 行 ✗ `systems/common-properties.md:202` 原话：「切语言后的重绘存在一条真实的不对称，必须写下来：locale 变化会让走翻译键的 `Control` 自动重翻，但 `LocalizedText` **不经 `TranslationServer`**，已组装好的 ViewModel 里那串中文不会自己变。纪律：**ViewModel 层订阅翻译变更通知，收到即重新组装一次**（重建成本就是重取一次 `Id` 对应的内容）；「重进当前屏」是可接受但更粗的兜底。」
- 该条**已在主题文档层**，与草稿「仅存在于 `handoffs/2026-08-13-*`」的断言直接相抵。
- **连带失效的三处论证**：3a 的「九条纪律、**七份**文档、且第 7 条已经掉出了主题文档层」（实际落点是 **9 份**主题文档：`architecture.md` · `systems/common-properties.md` · `adventure-event/common-properties.md` · `future-event-service.md` · `explore/_index.md` · `error-and-blocking-ux.md` · `content-service.md` · `sync-service.md` · `combat-service.md`）；3d 理由 1「纪律 7 已掉出主题文档层，再拖会漏」；D2 裁决表里照录的同一句承重理由。
- **风险点**：按第 6b 条「保留理由，删除坐标」，D2 的承重理由会被改写成正面陈述写进 `systems/viewmodel.md` / handoff。若原样落笔，等于把一句**经核实为假**的事实写进活文档。

  - 选项 (a) **保留 D2 结论、改写理由**：`viewmodel.md` 不提「掉出主题文档层」，改用仍然成立的三条判据（最小公共祖先 / 服务于谁 / 权威在哪一侧）+ 一条先例；纪律 7 按 C11 处理成 `systems/common-properties.md` 保留定义、`viewmodel.md` 作为最小公共祖先持有本体或反向回链。后果：论证少一条但全部为真；需当场定「纪律 7 的本体归哪一侧」。
  - 选项 (b) **保留 D2 结论、理由改为「散在 9 份文档、无最小公共祖先」**：不提掉出与否，只用「散落度」立论。后果：最省改动，且与 C11 同向；代价是丢掉「代价不对称」那一层论证（3d 理由 2 仍在，不影响 D2 成立）。
  - 选项 (c) 照原文落笔。后果：**活文档里出现一句假陈述**，且它正是日后被引用来解释「为什么单列」的那句。
  - **推荐：(a)** —— C11 明写「定义在最小公共祖先、投影在各落点，投影不复述定义」；纪律 7 现在住在 `systems/common-properties.md`（内容文本多语言形态的语境里），而它是**ViewModel 的重组装纪律**，最小公共祖先正是 `viewmodel.md`。取 (a) 顺带把这处投影关系摆正，比 (b) 多做一步但更贴既有判据。**需用户裁定纪律 7 的本体归属：`viewmodel.md` 持本体 + `common-properties.md` 留一句回链（推荐），还是 `common-properties.md` 留原文 + `viewmodel.md` 回链。**

### 🔴-2 「`system-overview.md`「非服务的横切件」表」——该表不在 `system-overview.md`

- 草稿 3b、3c 配套投影第三条、§具体形态 D、§后果 ✗ 全库 grep「横切件」只命中一处：**`program-overview.md:68`**「**非服务的横切件：**」，表在 L70–74，恰列三行 game-progression / EventBus / ViewModel（ViewModel 行现文：`呈现期对象 | Data + 运行时状态 → 屏幕；不落存档、不进云端负载`）。`system-overview.md` 中**不存在**该表（grep「横切件」「game-progression」均无匹配）。
- 影响：拟改动文件清单里的「`system-overview.md`（1 行回链）」是**错的落点**；照单执行会改错文件或改不动。
  - 选项 (a) 把该项改为 **`program-overview.md`「非服务的横切件」表的 ViewModel 行加回链**，`system-overview.md` 不动。后果：落点正确，改动面不变（仍是 1 行）。
  - 选项 (b) 两份都加。后果：`system-overview.md` 的职责是「工程里长什么样」（进程边界 / 文件夹布局 / autoload 注册 / 代码形态），ViewModel 不是 autoload 也无代码形态条目，加进去是新造一处待漂移的投影。
  - **推荐：(a)** —— 依 `architecture.md` L4 的三份总览分工（结构与边界 → `architecture.md`；端到端运行链路 → `program-overview.md`；工程落地形态 → `system-overview.md`），横切件表本就属 `program-overview.md`。

### 🔴-3 退避公式 `max(本地值, Retry-After) × jitter` 会击穿服务端下界

- 草稿 §具体形态 B.1 写「`实际间隔 = max(本地计算值, Retry-After) × jitter`」，D1 定 jitter 为 **±20% 乘性** ✗ `sync-service.md:88` 原话：「**退避间隔取 `max(本地退避计算值, 服务端给的等待时间)`**——`Retry-After` 应答头或 `detail.retryAfterSeconds`；**服务端值是下界不是精确值**，本地抖动（jitter）照常叠加」。
- 冲突：乘性 ±20% 施加在 `max(...)` **之后**，会以 50% 概率产出 `< Retry-After` 的间隔（最坏 0.8×），把一个**下界**变成可被击穿的值——正是限流场景下最不该做的事，且 `rate.limited` 已定「原样重试即可」（`pushId` 保幂等），提前重试只会再吃一次限流。草稿自身在 C6 里也复述了「下界不是精确值」，故这是**草稿内部自相矛盾**，不只是与权威相抵。
  - 选项 (a) **jitter 只向上抖**：`实际间隔 = max(本地值, Retry-After) × (1 + rand[0, 0.2])`。后果：恒 ≥ 下界；错峰效果保留（同批客户端仍散在 20% 窗口内）；`balance.md` 那行写「+0～20%（乘性，只向上）」。
  - 选项 (b) **jitter 只加在本地值上，再取 max**：`max(本地值 × jitter±20%, Retry-After)`。后果：恒 ≥ 下界；但服务端给了大值时全体客户端齐步在同一时刻重试（jitter 被 max 吃掉）——正是 L88 想避免的「同一批客户端齐步重试」。
  - 选项 (c) 保留 ±20% 双向。后果：违反既有权威的「下界」语义，需改写 `sync-service.md:88`。
  - **推荐：(a)** —— 唯一同时满足「≥ 服务端下界」与「限流场景下仍错峰」的形态，且不需要松动任何既有措辞。cap 60 s 在 +20% 后为 72 s，仍远低于滞留闸门 180 s，D1 的硬约束不受影响。

## 🟠 含糊

### 🟠-1 `architecture.md`「展示层契约」第 3 点收束到什么程度

- 草稿 3c 说「保留三层切分的**定义**，第三层展开处改为一句回链」；但该小节现有两段与第三层直接相关：L100 的第 3 条（「组合展示走 UI 层轻量 ViewModel……只存在于呈现期，不落存档、不进云端负载」）与 L102 独立一段（「**ViewModel 层因此是架构中的一个显式层**：位于 services / 核心「类」与屏幕场景之间……单向依赖……不被服务反向依赖，也不参与存档 / 同步」）。
- 可解读为 (a) 两段都保留、只在末尾追加一句回链；(b) L100 第 3 条保留（它是三层定义的第三格，属定义）、L102 整段迁进 `viewmodel.md` 只留一句回链；(c) 两段都压成一句回链。
- 后果差异：(a) 制造复述（L102 的四条纪律会与 `viewmodel.md` 的「意图」段各存一份，正是 C14 要防的）；(c) 让 `architecture.md` 的「三层切分」失去第三格，D3 说的「`architecture.md` 保留三层定义段」落空。
- **推荐：(b)** —— L100 的三条并列项是「定义」（三层各一格，最小公共祖先在此），L102 是第三层的**展开**（依赖方向 / 生命周期 / 不参与存档），按 C11 属于该迁走的投影本体。

### 🟠-2 `ux/_index.md` 那一行指路的形态

- 草稿说「表中加一行指路，说明 ViewModel 是结构契约，归 `systems/`」。但 `ux/_index.md` 的表是「**ux 文档** | 用途」（四行全是 `ux/*.md`），塞一个 `systems/viewmodel.md` 进去会让这张表不再是「ux 有哪些文档」的索引。
- 可解读为 (a) 加进表内；(b) 写成表下的一条引言块（与现有「全库横向纪律」「边界：上一条只管 UI 文案，不管内容文案」两块同形）。
- **推荐：(b)** —— 该文件已有两处「边界 / 归属」引言块的先例，且它们承载的正是「什么归这里、什么不归这里」；加进表内会污染索引语义。

### 🟠-3 `systems/viewmodel.md` 的「## 待决问题」放什么

- 草稿 3c 骨架列了空的 `## 待决问题`。第 7 步禁止臆造，第 8 步要求新增待答项进分片。若确实无待答项，是留空占位（同库内其他 `systems/*.md` 的惯例）还是不建该小节？另：软依赖里那条「Godot 4.7 `auto_translate_mode` 默认行为实测」已登记在 `open-questions/05-service-contracts.md:29`，**不应在新文件里再登记一遍**（会造第二处）。
- **推荐：** 建空的 `## 待决问题` 小节（沿用 `systems/*.md` 模板惯例，其余文档皆有此小节），内容留模板占位；实测那条只在 `05-service-contracts.md` 留一份，`viewmodel.md` 的「重组装触发面」若需提及则写回链。

## 🔵 可推演（无需回答）

1. **② 在 `architecture.md` 整条删除后不留悬空。** `architecture.md`「内容与档案的存储分界」小节（L91）已有指向 `services/content-service.md` 的回链（「overlay 对剧本内容可新增 `Id`（「只改不增」的唯一例外，见 `services/content-service.md`）」），导航路径完整，草稿 2c 的判断成立。
2. **①的收口回链措辞可直接落笔**（草稿 1b 建议 4），且它引用的五处小节名与实际标题逐字一致：`sync-service.md` 的「断线降级」/「`Immediate` flush 的失败语义」/「`Upgrade` 类错误在非闸门点」、`balance.md` 的「同步 / 内容管线旋钮」均已核实存在。
3. **`balance.md` 旋钮表落点无需新造。** L311–319 该表现有 5 行（push 防抖 5 s / 缓冲上限 3 / 滞留 180 s / overlay 重试 3 次 1s·2s·4s / 剧本预取深度），表头已写「初值已给，待实测校准」，追加 4 行同族。**cap 60 s < 滞留闸门 180 s** 与表内第三行自洽。
4. **「只有 overlay 下载那条给了退避参数」成立。** 活文档中「指数退避」共 6 处（`account-service.md:16` · `content-service.md:157` · `life-cycle-service.md:177` · `sync-service.md:77 / 88 / 219`），仅 `content-service.md:157` + `balance.md:318` 给了「最多 3 次 / 1s·2s·4s」。（草稿写「全库出现 5 次」，实为 6 处；结论不受影响，且该计数只活在草稿里、不落库。）
5. **无放弃阈值 = C2 + C5 + C7 的合取，可直接落笔。** 三条依据逐条复核成立：`sync-service.md:73`「绝不回退存档点」+ L77 队列跨启动保留；L82–87 闸门以「次数 / 时长」触发、与重试耗尽无关；L157–158 `Upgrade` 与 `session_revoked` 各自定了**暂停**且唯一解除条件 = 重新登录成功。队列的三条淘汰路径（被接受 / `Conflict` 丢弃 / 切账号清空）分别在 L106、L107、L101 有据。
6. **协议契约零影响、无对侧库承接项**——退避参数是纯客户端行为；`Retry-After` / `detail.retryAfterSeconds` 的消费语义 L88 已定，本次只补本地计算形态。**故本分片不产出任何 `backend-design-documents/` 改动。**
7. **挂起不补偿、不追赶**（草稿建议 3）与 `sync-service.md:148`「滞留计时不因战斗进行而暂停，这是正确行为」同向，可直接落笔。

## 拟改动文档清单与各自新增要点

**worker 独占（Phase B 由本分片写）：**

| 文档 | 新增/修改要点（供跨草稿核对） |
|---|---|
| `systems/architecture.md` | ① 待决问题第 3 条「断线降级」→ 改写为一行回链（指向 `sync-service.md` 三节 + `account-service.md` + `content-service.md` + `balance.md` 旋钮表）；② 待决问题第 2 条「热更只改不增的连带项」→ **整条删除**；③ 待决问题第 4 条「ViewModel 是否单列」→ **删除**；④「展示层契约」小节 L102 那段迁出、留一句「ViewModel 层的完整契约见 `systems/viewmodel.md`」（形态待 🟠-1）；⑤「决策(-> ADR)」的「展示层三层切分 → ADR 候选」行注明**固化落点 = `systems/viewmodel.md`**。**⚠ 与 costkey 分片撞面**：该分片可能同时改「待决问题」第 1 条（`cost element 清单`）与 `ResourceElements` 表。 |
| `systems/viewmodel.md`（**新建**） | `## 意图`：三层第三层本体（是什么 / 不是什么）· 依赖方向（单向；服务不返回 ViewModel；不进存档 / 云端负载）· 组装源三件套（`XxxData` + 运行态实例 + 服务快照 `CombatSnapshot`）· 重组装触发面（翻译变更通知 · `CapabilitiesChanged` 空负载后自查 · EventBus 既成事实广播）· 只读消费纪律（定稿实例不回查模板、`IsRevealed == false` 时不读 `RevealedEventId` / `DestinationLocationId`）· 缓存归属（`LocalizedText.Get()` 的缓存只落这一层，绝不写回 `XxxData`）· 永不渲染清单（`OpResult.Detail` 不赋 `Label.Text`；诊断编号只读一次）。`## 决策(-> ADR)`：展示层三层切分 → ADR 候选，本文件为固化落点。`## 待决问题`（形态待 🟠-3）。**投影不复述定义**（C11）。 |
| `systems/services/sync-service.md` | 「断线降级」节三处增补：(1) 退避形态段——底数 / 因子 / cap / jitter 取 `balance.md`，公式待 🔴-3 裁定，**无放弃阈值**（三条依据），挂起恢复后不补偿 / 不追赶 / 不重置阶梯层级；(2) 一行索引（内容 / flags 侧降级见 `content-service.md`，身份侧刷新失败分流见 `account-service.md`）；(3) 三条不变式（阻塞点穷举 4 处 · 「回退存档点」零次出现 · 降级只有三种形状，新失败态必须归入其一）。 |
| `systems/balance.md` | 「同步 / 内容管线旋钮」表追加 4 行：push 退避底数 / 因子 `2 s · ×2`；cap `60 s`（硬约束 < 滞留闸门 180 s）；jitter `±20%`（措辞待 🔴-3）；放弃阈值 `无`。归属列均写 `systems/services/sync-service.md`。 |
| `program-overview.md`（**非** `system-overview.md`，见 🔴-2） | 「非服务的横切件」表 L74 的 ViewModel 行 → 追加回链 `systems/viewmodel.md`。 |
| `systems/common-properties.md` | **仅当 🔴-1 取 (a)**：L202 纪律 7 改为一句 + 回链 `systems/viewmodel.md`（本体迁入新文件）。取 (b) 则本文件不动。 |
| `handoffs/2026-08-19-architecture-structural-residuals.md`（**新建**） | 按 `_TEMPLATE.md`；Intent 承载三条收口；**Clarifications 段**记录本次 interview 的裁决（🔴-1/2/3 + 🟠-1/2/3）。 |

**orchestrator 代笔（共享台账，铁律 ②）：**

| 台账 | 本分片交回的内容 |
|---|---|
| `systems/_index.md` | 表内追加一行：`| [viewmodel](viewmodel.md) | 展示层第三层的结构契约：依赖方向、组装源、重组装触发面、只读消费与缓存归属、永不渲染清单。 |`（按现有表的字母 / 主题序插入；现表 L11 architecture、L13 balance、L14 game-progression） |
| `ux/_index.md` | 一条边界引言块（形态待 🟠-2）：ViewModel 是结构契约、归 `systems/viewmodel.md`；`ux/` 只管各屏显示什么 |
| `open-questions/05-service-contracts.md` | **删除 L31**「`architecture.md` 的三条结构残留（08-16b 采集 · 此前未进清单）」整条（三条全部答定）；**新增一条**：`architecture.md ↔ services/*` 待决问题与投影表对账（见「越界发现」，草稿末尾已采纳为新待答项） |
| `answer-logs/log-architecture-structural-residuals.md`（新建） | 3 条移出：断线降级具体行为 → 已答定 + 退避形态补齐（`sync-service.md` / `balance.md`）；热更只改不增连带项 → 两问皆已答定（`content-service.md`）；ViewModel 落位 → 单列 `systems/viewmodel.md` |
| `answer-logs/_index.md` | 台账行：`log-architecture-structural-residuals.md \| 2026-08-19 \| inbox/solution-draft-architecture-structural-residuals.md \| 3` |
| `open-questions/update-log.md` | 顶部追加本次摘要 |
| `handoffs/_index.md` | 新行（`status: distilled`，`distilled-to` 列出上表 worker 独占的 5–6 份文档） |
| `inbox/_index.md` + 草稿归档 | 草稿 front matter 加 `reviewed:` / `distilled-to:`、`status: distilled`，`git mv` 进 `inbox/archive/`，台账移行 |

## 越界发现

1. **`open-questions.md`「derive 就绪度」的 `architecture.md` 行会立刻过期**（L62 现列四个卡点，本次清掉其中三个，只剩 `CostKey` 资源族 element 清单）。按技能第 10 步，本分片与 orchestrator **均不得触碰该小节**——归 `/assess-derive-readiness`。**如实记录，不代改。**
2. **草稿末尾已采纳的新待答项**（跨草稿）：立一条「做一次 `architecture.md ↔ services/*` 待决问题与投影表对账」，含两个已知实例——本次三条里两条属过期登记（已证实），以及 `solution-draft-costkey-statkey-registry.md` 报告的 `ResourceElements` 表两份投影漂移（`architecture.md` 7 行 vs `profile-service.md` 11 行，**本分片未独立复核，属该分片范围**）。落笔归 orchestrator。
3. **写入面撞车预警**：`systems/architecture.md` 极可能同时被 **costkey 分片**改动（`ResourceElements` / `CostKey` 枚举 / 待决问题第 1 条）。本分片只动「待决问题」的第 2/3/4 条 + 「展示层契约」小节 + 「决策(-> ADR)」的展示层那一行，**不碰 `ResourceElements` 与 cost element 清单条目**。建议 orchestrator 把这两个分片对 `architecture.md` 的写入**串行成两个波次**（铁律 ③）。
4. **`.claude/knowledge/architecture.md`（引用层）** 在 `architecture.md` 的「## 对应」中被点名；新增 `systems/viewmodel.md` 后引用层可能需补一条导航。归 `/sync-knowledge`，本分片不动。
5. **`update-log.md:103` 已记同类教训**（「刷新失败视同断线」在活文档里有三处复述，只改一处会漏），与本次 🔴-1 的成因同源；orchestrator 落笔后建议按该教训 grep 一次「ViewModel」关键措辞（33 份文件命中）确认无新造第二权威。

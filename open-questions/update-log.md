# 待答清单更新日志

> 每次 `/analyze-new-ideas` / `/summarize-open-questions` 运行后，在此**顶部**追加一条更新摘要：本次答结了什么、推翻了什么、新增待答落在哪个分片。问题条目本身在 `../open-questions.md` 的各分片里；已答定问题的逐条移出记录在 `../answer-logs/`。
>
> 本文件只记「发生了什么变化」，不承载问题条目本身。

> **只保留最近 10 条。** 更早的条目原样移入 [`update-log-archive.md`](update-log-archive.md)（按时间正序），
> 一字未改、仅换了文件——本日志与归档合起来即全部历史（`decisions/ADR-0005`：台账不无限膨胀）。

## 2026-08-23d（`/write-adr --lib=game all` · 批量编排的客户端分片 · 固化 2 条 · 只写 `decisions/` 与「下一阶段」）

- **两条候选全部来自「下一阶段」的候选清单**（08-23 复核会解除建档阻塞的那两条），逐条回主题文档核实事实已落地后建档：
  - **`ADR-0029` 剧本树不按篇章分包**（事实依据 `systems/services/plot-manager.md`「剧本树不按篇章分包」+ `content-service.md` 的零增量结论）。
  - **`ADR-0030` 单例内容走既有泛型仓储进 ContentRegistry：`ISingletonContent` + `Single<T>()`**（事实依据 `systems/services/content-service.md`「单例内容的注册与校验」+ `game-progression.md` 的 `LocationMapData` 并入通用校验）。
- **候选 2 拆出的另一半未建档，留在候选清单**：「不设 `GlobalBalanceData` 兜底大表 + 平衡资源切分三问判据」虽已于 08-22 正式拍板，但 `content-service.md` 把它转手给 `systems/balance.md`，而后者至今零承载（同一处遗漏 `answer-logs/log-0823.md` 末节已留痕）。按「台账绝不领先于事实」不建档；它与 `ADR-0030` 可被单独推翻而不牵动对方，故本就该各自一份。
- **散落定案扫描**：08-22d 那次已逐份筛过截至 08-22 的全部 `distilled` handoff；此后仅新增两份（`2026-08-23-flags-version-client-gate` 补齐一道既有闸的应用面 · `2026-08-23-refresh-lifetime-cap-client-half` 一个文案键 + 一个内存态软信号，明写 API 面 / `Session` / 存档 schema 零改动），**均属参数级 / 文案级收口，低于既有 ADR 的粒度线，不建档**。
- **`update-log.md` 按「只留最近 10 条」把 `2026-08-17h` 原样移入 `update-log-archive.md`**（一字未改）。
- **未动主题文档、未动 handoff、未动 `## derive 就绪度`、未动任何分片的问题条目、未碰后端库。**

## 2026-08-23c（`/analyze-new-ideas` 跨库 · 客户端半 · 移出 1 条 · 新增 0 条）

- **本次是一次跨库运行的客户端一半**（主库为 `backend-design-documents`，那侧同批落了三条契约条款）。本库改动小而窄：两份主题文档 + 一条文案键。
- **答结 1 · 后端契约条款「flags 回滚须以更高 `flagsVersion` 发布」尚未成文**（`05-service-contracts.md`）→ **对侧已成文**（单一全局单调序列 · 回滚即前滚 · 同版本结果恒定），本库「增大即拉」所依赖的那一半到位，**本库既有规则一字未改**。→ `answer-logs/log-refresh-cap-and-flags-gate.md`
- **同批补上本库自己的一处缺口**（此前未登记）：flags 单调闸只挂在观测 `X-Flags-Version` **头**处，**拉回批次 body 的 `flagsVersion` 是否也过闸**没写。定案：> 内存值才应用，否则整批丢弃 + `PushWarning` + 上报一次（复用「观测到更小版本」的同一通道与去重口径）；**等值也丢弃**——后端保证同版本结果恒定，等值那批逐字相同。→ `systems/services/content-service.md`
- **同批定案的两项本库取向**（随对侧 refresh 收口一并裁决，此前不在清单上）：到期重登的措辞基调取**最平淡的例行口吻、不附原因句**（二级键 `ERR_AUTH_SESSION_REVOKED_SESSION_EXPIRED`）· 软信号 `reauthRecommended` 的自然时机取**启动期续期成功即呈现可跳过的登录屏**、失败即忽略。→ `ux/error-and-blocking-ux.md` · `systems/services/account-service.md`
- **顺带消除计数副本**：`error-and-blocking-ux.md` 回链后端 `reasonKey` 取值表时写死的条数（七值 · 三值）改为不带数目的回链——条数与取值一样是会漂移的副本，与该处自己那条「不维护第二份清单」同向。对侧同批消除同形写法。
- **零改动面**：API 面 · `Session` · 存档 schema · 四处阻塞点的穷举清单 · `sync-service.md`（回声校验的客户端半 08-22 已落，本次对侧落笔后成对采纳完成，本库零改动）。

## 2026-08-23b（`/summarize-open-questions game` · 全量对账 · 移出 0 条 · 归集 6 条 · 清理 4 个垃圾文件 · 单库）

- **本次无移出，无 answer log。** 逐条比对九个分片与 45 份主题文档 + 后端库三处承接点：**没有任何待答条目已在主题文档 / ADR 中被答定**。这是 08-23 那场 20 项复核会刚跑完的直接结果——清单与主题文档当前高度同步，本次的产出全在「漏收」一侧。
- **归集 6 条主题文档有登记、分片零覆盖的项**（均为**已存在的登记，非新问题**）：
  - `06-meta-progression.md` +2 —— **`experiencePoint` 的阈值曲线与产出分布**（承重；载体已定，欠曲线 / 单次给予量 / 池内分布 / 失败折扣，**与 `lifeSpanCost` 预算互相约束、必须一同反推**，权威登记在 `life-cycle-service.md` 却从未进过清单）· **重试上限可变后的存档表达**（落成 `CapabilityFlag` / modifier 具名修正 / 独立 `Entitlement` 字段三选一；此前 `deferred-content.md` 只收了「数值是否再调」那半，**结构那半整条漏在清单外**）。
  - `01-combat.md` +1 —— **隐藏属性与战斗资源的共存面**（除「调制遭遇参数」这条间接通道外，三项隐藏属性与 mana / 道念 / lifeTotal 在战斗内是否还有直接耦合。**是边界题不是数值题**：答「无」即关死一整类设计空间）。另在既有的「敌人 AI 决策形态」条上补 `EnemyData` **行为脚本的表达形态**一格（与算法本身是同一未知的两面）。
  - `05-service-contracts.md` +1 —— **location 无法被 flags 秒关时的运营替代通道**（location 恒启用、不参与三层过滤，是 `AllEnabled()` / flags 运营通道在本作**唯一的空洞**；候选方向已有，本次不预设形态）。
  - `deferred-content.md` +2 —— **三条音量轨默认值的实测校准**（轻，`100 / 80 / 100` 相对关系有依据、绝对值待真机）· 在既有 capability flag 条上补 **flag 聚合面的宿主服务**一格（账号级至今无专属服务）。
- **清理 4 个 0 字节垃圾文件**：`open-questions/` 下由某次 shell 重定向误产生的 `**本次全部`、`后端侧的待答清单在`、`本文件是**客户端**（Godot`、以及一条长句文件名。内容为空，无信息损失。
- **跨库承接项逐条核对，三处全部仍在办、无一可关**：`compliance.md` 的 `ComplianceManager` 覆盖面切分（对侧明写「归客户端自己裁决」）· `content-manifest.md` 的 flags 回滚条款（对侧仍列在「待定」）· `auth.md` §5 的静默续期收口手段（对侧仍标「待办」）。回声校验的后端半亦未落笔（其草稿仍在后端 `inbox/` 顶层）。**本次未写对侧库。**
- **未动任何主题文档**（发现的两处一致性问题只报告、不擅改，见下）· **未动 `../open-questions.md` 的「derive 就绪度」小节**（`/assess-derive-readiness` 独占写入）。
- **报告给用户的两处主题文档自身问题，用户当场批准修复**（故本次**确有主题文档改动**，范围仅限这两项，见下条）：① `ux/` 四份文档用 `## 待解问题`，全库其余 45 份用 `## 待决问题`——**机械扫描按后者取小节即整个 ux 分区归零**，本次是靠人工兜住的；② `art/_index.md` 与 `art/soundtracks/_index.md` **没有待决问题小节**，而 `deferred-content.md` 有条目以它们为权威归属——权威侧无登记。
- **主题文档改动（用户批准后执行 · 全部为小节名与登记面，零设计裁决）：**
  - **小节名统一为 `## 待决问题`**：`ux/` 四份（`combat-ux` / `error-and-blocking-ux` / `onboarding` / `screen-flow`，原 `## 待解问题`）+ `screen-flow.md` 正文一处交叉引用同改；**延伸到 art 分区的两处同源写法**——`art/visuals/_index.md`（原 `## Open questions`）· `art/visuals/animations/_index.md`（原 `## 待咨询专业人士后确定的`，其「待咨询专业人士」的语义未丢，移进小节首行引导句）。全库主题文档至此**只有一种小节名**。
  - **补两处缺失的 `## 待决问题` 小节**：`art/_index.md` 收**跨两个一级分区**的 3 条（AI 生成资产的商用授权与参考素材合规口径 · 参考素材二进制是否入库 · 各方向文档实质内容待写）· `art/soundtracks/_index.md` 收 4 条（音频工具定案 · BGM 时长与码率的包体预算 · 三条音量轨默认值 · 寿元告警是否伴音）。**条目全部来自既有登记的回收，未新增任何设计取向。**
  - **顺带修两处 markdown 粘连**：`art/soundtracks/_index.md` 的 `...deferred-content.md。## 导航` 与 `art/visuals/animations/_index.md` 的 `...日后全部返工。## 已知的`——标题被粘在正文行尾，**两处此前都不成其为标题**（不渲染、不可锚点、机械扫描取不到）。
  - **分片同批补 1 条**：`deferred-content.md` +1 —— **BGM 时长与码率的包体预算**（此前只在 `soundtracks/_index.md` 的「移动端约束」里作为一句「预算未定」存在，从未成为待答项）。

## 2026-08-23（复核会 · `[采纳推荐 — 待复核]` 20 项逐条裁决 · 移出 20 条 · 新增 0 条 · 零新增设计）

- **性质是复核而非设计**：不裁决任何其他待答问题、不改判定之外的内容、不生成 FR、不碰后端库与代码。范围 = 08-22 两批批量提炼留下的 20 项，分布 `01-combat.md`（7）· `02-event-options.md`（9）· `04-hidden-attributes-plot.md`（1）· `05-service-contracts.md`（3）。
- **20 项全部维持推荐、零推翻。** 分 5 轮 interview（每轮 4 条，按推翻成本降序：枚举形状与取值域 → 资源 / 注册 / 键空间 → 写入时机 / 凭据 / 运营通道 → 校验条数 / 纪律 / 规则形态 → 命名 / 呈现 / 可逆旋钮）。逐条结论见 `../answer-logs/log-0823.md`。
- **主题文档改动只有两类**：移除 13 处 `[采纳推荐 — 待复核]` 标记（`architecture.md` ×2 · `adventure-event/common-properties.md` ×1 · `game-progression.md` ×2 · `codex/_index.md` ×3 含删去待决问题一条 · `content-service.md` ×4 · `future-event-service.md` ×4 含删去待决问题一条 · `plot-manager.md` ×1 · `ADR-0027` ×1）；以及两处顺带补全（校验 9 那一格补上拒绝理由、`content-service.md` 单例小节抬头由「形态待复核」改为定案陈述）。**未新增、未改写任何设计结论。**
- **两份 ADR 候选的建档阻塞就此解除**：剧本树不按篇章分包 · 单例平衡资源经 ContentRegistry + `ISingletonContent` / `Single<T>()`。本次不建档（超出复核范围），「下一阶段」的措辞已同步。
- **两处如实留痕、未处置**：`future-event-service.md:293`「能力族商品经第二级 `TryPickGrantableMany` 取池」仍标待复核但**不在任何分片登记**（孤儿标记）· `01-combat.md` 的 `EnemyManaLimit` 条目内夹带的「已知例外措辞同待复核」半句（主体是 ch1 数值项）。
- **未动 `../open-questions.md` 的「derive 就绪度」小节**（`/assess-derive-readiness` 独占写入）——但该小节点名的「③ 一次 20 项复核会」已由本次执行完毕，下次全量重估时应据此重判 `architecture.md` 等六份的排除面。

## 2026-08-22d（`/write-adr --lib=game` · 固化 4 条 · 新登记候选 2 条 · 只写 `decisions/` 与「下一阶段」）

- **来源不是候选清单**——`open-questions.md` 的「下一阶段」当时明写「当前无待固化的 ADR 候选」，那句写于 08-19 清账之后。本次候选全部由**扫 `handoffs/` 中 `status: distilled` 的散落定案**得到：08-22 单日新增 22 份 handoff，逐份按「能否被单独推翻而不牵动其余」与既有 ADR 的粒度线筛选。
- **建 4 份 ADR（均已逐条回主题文档核实事实已落地）：** `ADR-0025` Finale 失败即角色终结 · `ADR-0026` eventOptions 十步管线 · `ADR-0027` `LocationCodex` 顶点级显影 · `ADR-0028` 上行整键回声校验通则。
- **2 条够格但暂不建档，改登记进「下一阶段」**：剧本树不分包 · 单例平衡资源进 ContentRegistry。两者的主项或承载机制仍标 `[采纳推荐 — 待复核]`，按铁律「待复核不当作用户拍板」不建 `Accepted` 的 ADR。
- **其余 16 份 08-22 handoff 判为字段级 / 参数级收口**（`EncounterTighten` 字段面 · `HiddenStatDirection` · counters 键空间 · `mana +1` · `eventCountLimit` 不可调制 · 购买次数 `StatKey` · 敌人卡组规模 · `ChapterScope` · 带边界配置落点 · flags 拉取护栏 · `Priority = 1` 判据 · 非战斗决策点清单 · `EventOutcomeSpec` 字段面 · 运行态计数器 · refresh token 落点 · `Practice`/`Standard` 失败后果），低于既有 ADR 的粒度线，不建档。
- **未动主题文档、未动 `## derive 就绪度`、未动任何分片的问题条目。**

## 2026-08-22c（`/batch-analyze-new-ideas game` 补跑 · 11 份草稿 · 移出 15 条 · 新增 10 条 · 修 8 处活文档漂移 · 单库无跨边界）

- **起因是一处阻断发现**：上一轮批量的 `answers.md`（5 轮 interview 全部裁决完毕）已落盘，但**它的 Phase B 从未执行**——11 份草稿仍在 `inbox/` 顶层、无 handoff，三个裁决产物 `EncounterTighten` / `EnemyManaLimit` / `HiddenStatDirection` 在全库主题文档中零承载。用户裁定先补跑 Phase B，再做收尾。
- **写入面高度重叠 ⇒ 切 5 个波次串行**（`balance.md` 被 6 个 worker 争用、`plot-manager.md` 4 个、`combat-service.md` / `content-service.md` 各 2~3 个）。每波内 `balance.md` 与 `plot-manager.md` 各只有一个 owner，无并行写同一文件。
- **移出 15 条**（各记 answer log）：counters 家族三条（非异能计数器 / `CardInstanceSave.Counters` 读写 API / 子名字符集与登记）· 样本卡组规模两处矛盾 · 疲劳量是否可调 · 更高境界的 mana 基线 · `EncounterTighten` 字段面 · `HiddenStatGrant` 推拉方向 · `eventCountLimit` 能否被剧本调制 · `LocationCodex` 显影粒度（部分）· 剧本内容的体积与分发粒度 · 购买次数 `StatKey`（**同题两处登记，主题文档侧与分片侧同批移出**）· 失败后果的其余部分 · 散落平衡旋钮兜底大表 vs 逐份切 · 单例平衡资源如何进 ContentRegistry（降为待复核）。
- **三条逆推荐裁决**：① `manaLimit` **每次大境界 +1**（增量语义、走既有 `CostKey.ManaLimit`）——**显式推翻 `answer-logs/log-0730b.md` 第 4 条**；② `EncounterTighten` **一并覆盖五格**（原推荐两格），新增三格牌流量各需一个上界常量与下界钳制，否则剧本能把每回合抽牌压到 0；③ 内容 / 呈现类轻项只逐项问三条失败后果，其余按推荐。
- **两处本批新发现的真缺口，当场答定**：`KeywordRef.Amount` 展开成 `Transient` 条目后无承载字段（→ 战场条目增 `amount:int`，默认 `-1`）· 敌人侧 `manaLimit` 全库无取值来源（→ `EnemyManaLimit = 5` 住 `CombatRulesData`，可被 `EncounterSpec` 覆写；**参战方对称在 mana 一项被打破，已在 `combat-service.md` 列名为已知例外**）。
- **新增 10 条**：`01-combat.md` +6（`EncounterTighten` 三格界常量取值 · `EnemyManaLimit` 初值校准 · 卡牌费用曲线是否随境界上移 · 三条待复核归并条目）· `02-event-options.md` +6（三条 `HiddenStat*` 待复核 · `LocationCodex` 边缘顶点与半径 · `eventCountLimit` overlay 边界 · 词条深度改写保留）· `04-hidden-attributes-plot.md` +1（剧本树不分包的三项配套裁决）。
- **本批 20 项 `[采纳推荐 — 待复核]` 全部维持待复核**（铁律 ①）：按推荐落笔，但留在待答清单。**后果：11 份草稿中 7 份不满足归档前置条件第三条，留在 `inbox/` 顶层**；4 份（`encounter-tighten-fields` / `purchase-count-statkey` / `mana-baseline-realm-jump` / `combat-defeat-consequences`）全项正式拍板，已归档。
- **修 8 处活文档漂移**：`enemies/common-properties.md`「规模 15」孤例 · `enemy-codex.md` 三处「15 张」· `deck/_index.md` 手牌上限 9→7（**此前未进任何待答清单的纯漏改**）· `character-profile/_index.md` 与 `combat/_index.md` 两处「炼气基线 10/10」· `combat/_index.md` 的 `manaLimit`「不随境界自动成长」· `EncounterSpec.FirstSide`「剧情指定」措辞（`PlotModulation` 六字段无一格能表达先手 ⇒ 改为**内容侧在事件模板上编排**）· `exchange/_index.md` ↔ `03-adventure-event-types.md` 同题两处登记 · 本分片顶部摘要块（单行 1578 字 + 考古段）压成一句回链 `answer-logs/`。
- **两处漂移按用户裁决跳过**：`../open-questions.md` 第 82 / 106 行落在「derive 就绪度」小节内，该小节由 `/assess-derive-readiness` 独占写入，留待下次全量重估。
- **仍欠一步（与本批无关的既有积压）**：上批 14 项 `[采纳推荐 — 待复核]` 已于第 5 轮确认转正，但对应条目尚未移出 `open-questions/`，故上批 7 份草稿仍留顶层。

## 2026-08-22b（`/batch-analyze-new-ideas game 全部 solution draft` · 10 份草稿 + 1 次 interview 新裁决 · 移出 9 条 · 新增 21 条 · 跨库承接 3 条）

- **范围**：`inbox/` 顶层全部 10 份 `solution-draft-*`（均已过用户评审）。Phase A 十个 worker 并行只读校验产出 🔴 31 · 🟠 33 · `[采纳推荐 — 待复核]` 15，去重并追加跨草稿核对后收敛为 20 问，一场合并 interview 全部裁决；Phase B 按写入面分 5 个波次落笔。
- **用户在 interview 中提出一条推翻既有设计的新裁决（不属任何草稿）：Finale 失败必死。** 「移除 finale 结算认定失败后存活的场景，章节立即结束」+ 判定二值化（`d >= 0` 通过 / `d < 0` 失败，`Draw` 归入胜利侧取最低档奖励）。它单独成一个波次、排在全部草稿之前，因为它推翻的正是其余分片要引用的承重前提。
  - **改动面 22 份主题文档 + 3 份 ADR**：`ADR-0004` Decision 第 4 条**实质推翻**（战斗失败不再「不终结角色」——`Finale` 档失败是独立终结原因）· `ADR-0002` 的「整体保留」清单剔除「失败但存活仍完成篇章」· `ADR-0016` 论据自足化。
  - **`game-progression.md` 的承重结论整条反转**：「渡劫的胜负不是篇章推进闸门」→「胜负即闸门」。
  - **`DefeatReason` 三值 → 四值**（新增 `FinaleFailed`），且终态判定从**纯查表驱动**变为「查表 + 一条显式旁路」——Finale 失败不是资源触底、没有对应 `CostKey`，塞不进 `ResourceElements` 表。**这个口子已明写**，否则实现侧会以为照表走就行。
  - **一条差点静默失效的承重机制**：残卷 `PlayerPowerFragment.Accumulated` 是账号级写入，而 `DefeatCharacter` 会清理终态数据。失败恒等于死亡后，若不写死顺序，「Finale 失败累积残卷」会在**每一次**失败上丢 ⇒ 100% 失效。已在 `life-cycle-service.md` 明写「账号级残卷累加先于角色终结提交」。
  - **`WinMargin` 在 Finale 退场**：胜负线固定为 0 后它在该档没有消费者，`VictoryRule` 单字段三档共用故取值恒 0，并明写两条纪律（不是难度旋钮 · `Practice` 与 `Finale` 同取 0 是巧合、不得提共享常量）。Finale 因此**失去唯一的难度旋钮**，`balance.md` 已如实写下这一点并指向三条替代手段。
  - **「奖励最低档」零成本**：代入既定数值验算，`0 <= d < WinMargin` 整个区间的 `advantage` 上界仅 0.13 / 0.125 / 0.093，本就整体落在 `Tier.Narrow`（险胜档），由既有换算规则自动兑现。
  - 通过所需追分 ch1 8→5 / ch2 18→13 / ch3 33→25（降 24–38%）；ch3 重试上限维持 ∞/3/1、不做补偿（用户裁定）。
- **跨草稿交叉核对抓到的东西**（批量相对逐次运行的独有产出）：
  - **一处真矛盾**：`event-outcome-spec` 与 `remaining-decision-points` 各自独立撞上「置换 / 禁用候选的掷定时点」，两个 worker 推荐方向一致但**承载形状不同**（`OutcomeRule` 第四个 Kind vs `EventOption` 定稿字段）。合一为后者，逐次运行时第二个 session 会直接覆盖第一个。
  - **一处误报已拦下**：有 worker 把 `future-event-service.md` 的 `Finale 12 / 0` 判为 Finale 重构的遗留，实为正确（三档共用单字段）；已撤回该修改指令。
  - **三处「同一事实多份副本」**：生成 / 加权规则 5 份 · 硬阻塞枚举 3 种 · 「登录屏 = 应用首屏」3 处。
  - **两份草稿自身的事实错误**：`combat-runtime-counter` 称 `item/_index.md` 未表态（实已明写）· `echo-validation` 与其后端对侧草稿的「前置依赖」双双过时（实已落笔）。若照草稿写会造重复条目或改坏已正确的内容。
  - **`flags-throttle` 自称「张力：无 / API 零改动」被推翻**：存在一处自我递归无限发请求的 bug，且因 flags 无「回滚即前滚」契约，「增大即拉」在版本回滚后会让设备**永久停拉**。
- **移出 9 条**（各记 answer log）：生成 / 加权规则与叠加顺序 · `EventOutcomeSpec` 内部字段面 · `Priority = 1` 抬升条件 · 战斗之外的决策点清单 · 战斗内运行态存档形态 · 敌人池篇章框定载体 · 带边界配置落点 · 上行整键回声校验适用面 · refresh token 客户端持有形态 · flags 拉取频次护栏。
- **新增 21 条**：`01-combat.md` +9（赋级资源三项待复核 · `ChapterScope` 命名待复核 · 单例平衡资源如何进 ContentRegistry · 非异能计数器 · `CardInstanceSave.Counters` API · 子计数器名字符集 · 样本卡组规模两处矛盾 · X0 标记待复核 · 不触发第二次写入口径待复核）· `02-event-options.md` +5 · `05-service-contracts.md` +4 · `06-meta-progression.md` +1（死亡 / 轮回结束屏尚无设计）· `cross-boundary.md` +1（球在对侧的三条）。
- **15 项 `[采纳推荐 — 待复核]` 全部维持待复核状态**（用户裁定）：按推荐落笔，但留在待答清单不随本批移出。**后果：10 份草稿中 7 份不满足归档三前置条件，留在 `inbox/` 顶层。**
- **跨库**：三条承接项写入 `backend-design-documents/`（回声校验后端半 · flags 回滚即前滚条款 · 静默续期闸门收口手段），两侧互相回链。**⚠ 回声校验两侧草稿明写须成对采纳，本批只落客户端半 —— 成对采纳尚未完成。**
- **未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。

## 2026-08-22（`/summarize-open-questions --game` · 全量对账 · 移出 0 条 · 归集 10 条 · 修平主题文档 9 处 · 单库）

- **范围**：客户端库全部主题目录（`vision/` · `systems/**` · `art/**` · `ux/`）的 `## 待决问题` / `## 待解问题` / `## Open questions` 小节，逐条与 `open-questions/` 九个分片对账。不引入新想法、不裁决任何问题。
- **移出 0 条 —— 本次不建 answer log。** 逐条回主题文档核对，**没有任何一条待答项已在 `## 决策` / `## 意图` 或 `decisions/ADR-*` 中获得定论**。合理：上一次大规模收口是 08-19 的十份草稿批量提炼，`/analyze-new-ideas` 当批已把该移的都移了；此后无新的裁决输入。
- **归集 10 条「主题文档里有、分片里没有」的漏网项**（本技能的主要产出）。它们各自在主题文档中登记已久，却从未进过跨 session 清单 —— 也就是说**下一次 session 拾起清单时看不见它们**：
  - `01-combat.md` **+2**：战斗内运行态的决策点存档形态（`Power` 触发计数 + `PlayerItem` 剩余次数，须与战场条目一并落定）· 更高境界的 mana 基线是否跃升（`lifeTotal` 已定为境界跃升，mana 尚未表态，**两者分工不同不能类推**）。
  - `02-event-options.md` **+1**：选择区的呈现与导航手感（批次规模 1–5，两端差 5 倍，竖屏排布未落定）。
  - `03-adventure-event-types.md` **+1**：是否为「购买次数」设一个 `StatKey` 成员（轻，不统计则零依赖）。
  - `05-service-contracts.md` **+2**：refresh token 的客户端持有形态（**硬约束已成立**——不得与 `device-id.json` 合进同一文件）· flags 拉取的频次护栏。
  - `07-codex-monetization.md` **+1**：平台内购 SDK 的选型与封装层（三渠道已纳入 MVP，是客户端唯一必须引入第三方 SDK 处；**购买段在 SDK 落定前无法落地**）。
  - `deferred-content.md` **+3**：jade 获取渠道与掉落权重（**承重**——它卡住商店定价表的全部绝对数字）· `RelicData` 字段清单与触发器体系 · `PlayerItem` 种类目录与次数补充机制。
- **合并 1 条**：`deferred-content.md` 的「各 `ERR_*` 与四条兜底文案的逐条措辞」并入 `reasonKey` 二级措辞 —— 三者同为「结构已定、只欠中文文案」，同一处定稿，分列徒增条目。
- **`deferred-content.md` 的「尚未设计」小节整体重写。** 原表把 `account-info.md`（08-16 收口）· `game-setting.md` 与 `codex/common-properties.md`（08-19 收口）· 四类非战斗事件子类型（08-17 机制面全部收口）仍列为「空占位、尚无成形问题」——四处均已过期。改为只留两处真占位（`character-profile/item/common-properties.md` · `player-profile/player-item/common-properties.md` + `achievement/`），并单列一条「已不再适用的占位登记」说明它们欠的是**条目目录而非设计**。
- **`01-combat.md` 的 `RarityTier` 一条补齐取池余量**：由「`GrantPoolMargin` / `K`」扩为**三格**（另有 `ResearchPoolMargin` / `ExchangePoolMargin`），并带上 `balance.md` 的「可先填 0 而不阻塞落地」。
- **`update-log.md` 溢出裁剪**：本条写入前已有 12 条，超「只留最近 10 条」的上限。最旧三条（`2026-08-16i` · `2026-08-16j` · `2026-08-17`）**一字未改**移入 `update-log-archive.md`（按时间正序追加）。当前 10 条。
- **未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。

### 主题文档的 9 处修平（用户当场授权，覆盖本技能「不改主题文档」的范围守则）

对账查出的 9 处问题逐条报告后，用户裁决「更新过期登记和决策混入 · 问题 8 按慷慨度已定案 · 问题 9 补登回去」，据此改了 **9 份主题文档**：

- **过期登记（答案早已定，只是没回头划掉）—— 5 处：**
  - `systems/adventure-event/combat/_index.md` 删「效果关键字体系与目标规则（承重）」——已于 08-16c 收口。
  - `systems/balance.md` 删「成本类型的 element 清单与数值分档未定」——已由 08-16d 成本侧收口 + 08-19 `CostKey` 15 成员覆盖；两处定价表条目已各自承载剩余的数值面。
  - `systems/enemies/_index.md` 改写「敌人 AI / 意图规划逻辑」——原文写着「**回合级一次性规划已定**」，而该约束早随 08-15d 意图机制整条移除而**解除**。`combat/_index.md` 与 `combat-service.md` 当时都改了，唯独此处漏改，是三处同源表述里最后一处未同步的。
  - `systems/services/life-cycle-service.md` 改写「元进程持久化范围」——`AccountInfo`（08-16）· `GameSetting` 与 `CodexEntry`（08-19）三块字段面均已收口，改为只留 `Achievement` schema、`PlayerPower` / `PlayerItem` 的触发、`PlayerPower` 平衡边界三条。
  - `systems/character-profile/power/_index.md` 改写「写入面与存档形态」——持有列表（`CharacterProfile.characterPower` 字段 13）与写入通道（`AbilityElements` 经 `TryApply`）已于 08-17h 定案，条目收窄为**只剩 `status` 开关的存档表达**，并回链 `profile-service.md` 的同名待决项。
- **决策混入待决区（形式问题）—— 2 处，均为「移到 `## 决策(-> ADR)`」而非删除：**
  - `systems/adventure-event/combat/_index.md` 的「平局」（`CombatOutcome.Draw` 规则 + Practice 档 `Draw` 永不可达的退化）。
  - `systems/character-profile/deck/_index.md` 的「出牌费用 = mana」（每回合恢复至 `manaLimit`、不结转）。
- **问题 8 按「慷慨度已定」定案 —— 2 处：** `combat/_index.md` 删掉「敌人图鉴的慷慨度是否该上调」这条待决项，并在其 `## 决策` 补一行；`codex/enemy-codex.md` 的 `## 决策(-> ADR)` 同批补上**慷慨度 + 退让阶梯**一行。**该文档正文本就完整载有这条裁决**（三条理由 + 「加厚 ③④ → `KeyCardIds` 上界 3→5 → 才考虑全表」的阶梯），只是从未上升到决策清单，于是 `combat/_index.md` 一直照旧把它当未决 —— 典型的「正文已答、台账未同步」。
- **问题 9 补登回主题文档 —— 3 处（权威归属归位）：**
  - `systems/services/sync-service.md` ← **上行整键回声校验的适用面未穷举**（承重；`accountInfo` 是与 `entitlement` 同形的第二处，缺封闭清单则逐键临时判必漏，漏掉的那处即客户端静默改写后端权威字段的口子）。
  - `systems/architecture.md` ← **`architecture.md ↔ services/*` 的对账**。**明写为「台账事项 · 不阻塞 derive」**：本文件设计面无未决项，对账不产出 FR、不构成任何 derive 前置。
  - `systems/player-profile/player-power/_index.md` ← **「失去法则」三支的频次预算需重新配平**（`IgnoresProtection` 由 1% 上调至 ≈5% 后单支已吃掉三类合计的全部预算）。
- **删除「效果关键字体系」一条牵出的悬空引用 —— 顺手修 2 处。** 该条删除后，两处仍写着「阻于它」：`systems/services/future-event-service.md` 与 `open-questions/02-event-options.md` 的 `EventOutcomeSpec` 内部字段面。两处均改为**指向 08-16c 的收口权威**（`KeywordData` + target / scope 分离 + `EntryFilter`）并**明标「阻塞来源待重新确认」**——**没有替用户宣布它已解除**：若确已解除，该条就只欠自身落笔、可单独排专场，这是一个需要用户拍板的排期判断，不是对账能代做的。
- **⚠ 连带影响需 `/assess-derive-readiness` 重估：** `systems/architecture.md` 的 `## 待决问题` 由「当前无未决项」变为一条台账事项，而就绪度表当前判它 **ready**。该条已按不阻塞 derive 的口径落笔，但**判定权归 `/assess-derive-readiness`**，本次未动就绪度小节。

## 2026-08-19b（`/write-adr --game` · 全量固化 · 新建 19 份 ADR · 候选清单清空）

- **范围**：客户端库全量候选——`open-questions.md`「下一阶段」两条 + 散落在七份主题文档 `## 决策(-> ADR)` 小节里的 17 条「ADR 候选（待固化）」。逐条回主题文档核对「事实是否已落地」，**19 条全部查有实据**，无一条判为查无实据或矛盾。
- **新建 `ADR-0006` ~ `ADR-0024`**（19 份）：开发顺序 · 内容载体形态 · 五级层次词表 · 两条唯一入口 + 编排顶点 · 展示层三层切分 · API 契约总则 · 物化模型 · 纪律可执行化阶梯 · PlotManager 隶属 · 剧本树数据形态 · 隐藏属性档位模型 · capability flag + modifier pipeline · 道念计分模型 · 卡牌类型五分与战场划线 · 事件事务纪律 · `pastEvent` 痕迹 schema · Research 构筑面板 · 付费凭证与兑现 · 内购三渠道纳入 MVP。
- **分组上的一处刻意偏离**：`plot-manager.md` 三条候选原注「宜与内容载体形态候选合并固化」。按「能否被单独推翻」判据拆为三份——剧本本地内容层与 overlay 剧本例外并入 `ADR-0007`，档位模型（`ADR-0016`）与剧本树数据形态（`ADR-0015`）各自单列，两者均可在不牵动内容载体形态的前提下被推翻。
- **`decisions/_index.md`**：新增 19 行，全表按日期降序重排（同日按编号降序）；台账 ↔ 文件无不一致需修平。
- **`open-questions.md`「下一阶段」的 ADR 段落改写为一行状态**：候选清单清空，指向 `decisions/_index.md`。该小节其余三条（流水线闭环 / 架构闭环缺口）与其他小节一字未动。
- **主题文档未改**：各 `## 决策(-> ADR)` 小节里的「ADR 候选（待固化）」标注仍在原处，改指到具体 ADR 号属主题文档写入，不在本技能范围内 —— 留给下次 `/analyze-new-ideas` 或 `/summarize-open-questions` 清理。

## 2026-08-19（`/batch-analyze-new-ideas` · 10 份 `decided` 草稿一次清完 · 移出 20 条 · 新增 2 条 · **跨库**）

- **来源**：`inbox/` 顶层全部十份 `status: decided` 的 solution-draft —— `CostKey`/`StatKey` 注册表 · `ProfileChangeSpec` 载体缺口 · `CodexEntry` schema · `GameSetting` schema · `BundleGrantOrdinal` 施加权 · `architecture.md` 结构残留 · `deviceId` 供给 · 拆解粒度与签核 · 英文占位形态 · `PickMany` 短缺处置。产出 `handoffs/2026-08-19-*` 十份 + 后端 `2026-08-19-breakdown-granularity-and-signoff.md`。逐条移出记录见十份 `../answer-logs/log-*.md`。
- **合并 interview 48 项裁决，全部取推荐项。** 十份草稿虽都已由用户逐条评审至「取向零剩余」，Phase A 交叉校验仍查出 21 条与既有权威相抵或草稿自相矛盾的硬冲突。要紧的几条：
  - **兑现循环写错会付两次拿一份** —— `ordinal = BundleGrantOrdinal` 与「差值 > 1 时逐一按序兑现」不可同时成立（差值为 2 时中间序号永不兑现）。改 `ordinal = Redeemed + 1` 循环；「差值 ≤ 1」的不变式只保证单设备，挡不住两台设备各自付款。
  - **`Project` 的签名借错了档** —— `bool TryProject(..., out ...)` 是「可选缺失」的形状配「必需缺失」的严重度，全库无先例。改 `PlayerProfile Project(spec)` + `PushError` + `throw`。
  - **战斗内逐点提交会把约 31 份完整 `ActiveCombat` 块灌进 `AppliedChange`**（2–4 KB/份），与痕迹侧只存轻摘要的体积纪律正面相抵。明写累加时的列剔除清单。
  - **闸③的「另取一条填补批次」就是单项补位**，直接推翻 `future-event-service.md` 明写的「不设单项补位」。整条作废，抽不足即本批少一项。
  - **`SettingAssignment` 的失败语义不可机械检查** —— `bool` 缺省 `false` 与合法 `false` 同形、`int` 缺省 `0` 与合法 `0`（静音）同形。改 `int?` / `bool?`。
  - **退避公式 `±20%` 会以 0.8× 击穿服务端下界**，改为只向上抖 `× (1 + rand[0,0.2])`。
  - **草稿的一条承重理由是假陈述** —— arch 草稿称「纪律 7 至今无主题文档承载」，实则 `common-properties.md:202` 逐字载有。新建 `viewmodel.md` 的结论不变，但该假陈述不得按「保留理由」写进活文档。
- **跨草稿矛盾（逐个跑发现不了，本批独有）**：game-setting 的「`en` 列全部预设占位符」与 translation 的「`en` 留空、不写哨兵值」直接相抵，而两份都要写 `ux/error-and-blocking-ux.md`。统一取留空口径。另有三处共写面按单写者收口：`terminology.md` 的 `ProfileChangeSpec` 列枚举（四列一次加齐）· `sync-service.md` 的 schema bump（**全库只此一句**，涵盖四个新增列与两个子对象 schema）· `AtomicJsonFile` 共享工具（本体登记 `systems/architecture.md`）。
- **新增待答 2 条**（均落 `05-service-contracts.md`）：上行整键回声校验的适用面未穷举（`accountInfo` 是与 `entitlement` 同形的第二处）· 做一次 `architecture.md ↔ services/*` 的待决问题与投影表对账（本批已发现两个过期登记实例）。
- **松动的既有定案两处**（用户知情后批准）：pickmany 的「零 UI 改动、零文案键」为 reroll 前置校验松一格；breakdown 的软下界由「L1~L4 合取」改为「L1 ∨ L2 触发、L3/L4 降为辅助信号」。另按授权直接改写 `decisions/ADR-0005`（归属判据入 ADR，未新开取代 ADR）。
- **`systems/architecture.md` 的「待决问题」现已清空**（本批多个分片各清掉几条）。`user://cache/` 的 schema 版本要求由全称改为判据形态，三处同源措辞（含 `.claude/rules/state-save-rules.md`）同批改齐。

# 合并 interview 答复（2026-08-19）

**用户逐轮当面裁决，全部 48 项取 worker 推荐项。本文件视同用户当面答复，优先级高于草稿原始措辞。**
Phase B worker 遇到草稿与本文件冲突时，一律以本文件为准，并在 handoff 的 `## Clarifications` 中如实记下它推翻了原始输入的哪一句。

---

## A. 跨草稿裁决（本批独有，逐个跑发现不了）

**A1. `en` 占位符形态 —— 统一取 translation 的口径：`en` 单元格留空，不写任何哨兵值。**
game-setting 草稿 C7 的「`en` 列全部预设占位符」作废。两份草稿的结论方向本就一致（都不要假英文），只是措辞不同。
「该 locale 干脆没有这个键」就是占位的形态。与 A2 的 `CodexFlavor` 判据同源。
→ 影响：`ux/error-and-blocking-ux.md`（game-setting 与 translation 两个 worker 都写此文件，措辞必须一致）。

**A2. 可选 `LocalizedText` 的判据（`CodexFlavor`）—— 「缺失」定为字段本身为 `null`，强校验只对非 `null` 的 `LocalizedText` 执行。**
不引入必填/可选分类清单（那是本库反复否决的「要读上下文才能判」形态），不改必填。
零新概念：只把现行校验表里本就隐含的「一条内容的正文」收窄为「一个已存在的 `LocalizedText`」。
→ 影响：`systems/services/content-service.md` 语言校验表（由 **codex worker** 落笔），`systems/common-properties.md`。

**A3. `schemaVersion` bump —— 四份草稿共用同一次 bump，全库只出现一句 bump 表述。**
新增列合计四项（`RngElements` · `TraceElements` · `CodexElements` · `SettingChanges`）加上 `CodexEntry` / `GameSetting` 两个子对象 schema，同属一次 bump。
**写法纪律：一律写「新增一列」，绝不写「第八列」/「第九列」**——`ProfileChangeSpec`「列表数不进承重表述」是既有承重纪律，本批加四列尤其不能写死数字。
→ 落笔分工见 D 节。

**A4. `terminology.md` 的 `ProfileChangeSpec` 列枚举是单行文本，四份草稿都要加列 —— 由 codex worker 一次加齐四列，其余 worker 一律不碰 `terminology.md`。**
同时顺手订正该文件「图鉴族共五个」→ 六个。

**A5. 原子写共享静态工具（`AtomicJsonFile`）—— 本体登记进 `systems/architecture.md` 的共享构件条目，由 game-setting/device-id 合并后的同一个 worker 独占落笔，其余分片只写回链。**
同时把 `sync-service.md` L197 的 `LocalCacheManager` 职责从「实现原子写」改为「调用工具」。
`device-settings.json` 与 `device-id.json` 都走这个工具；删掉 game-setting 草稿 §3.2 那句「经 `LocalCacheManager` 写」（它与同段「不得依赖 sync-service 的任何东西」自相矛盾）。

---

## B. 逐分片裁决

### B1. costkey
1. **三个首胜 key 带 `Done` 后缀**：`PowerFragmentCh1FirstWinDone` / `Ch2FirstWinDone` / `Ch3FirstWinDone`。
   理由（写进依据列）：key 名 = 标的字段路径的 PascalCase 拼接，规则零例外才可机械检查；这与已裁决的 `Experience → ExperiencePoint` 改名同源。成员名落存档与上行契约、只可追加永不改名。
2. **`Elements` 的概括改写为「标量值」**：「资源是标量值：可钳制、`Add` 时可加且带符号分向、`Set` 时为已算好的绝对值」。
   **`architecture.md:436` 与 `profile-service.md:37` 两份副本同改**（只改一份必然漂移）。同时把否决 `FlagChanges` 的六面核对结论写在配表行的依据列。
3. 两项改名照办（`ExperiencePoint` / `PowerFragmentFinaleWinOrdinal` / `TotalCycles*`），`ElementSpec` **不加**第七列 `TargetPath`。（草稿已定案）
4. 事实订正：**补 `LastRoll` / `LastEffectiveChance` 两行 `ResourceElements`**（缺行会让按字面 Finale 收口的 `TryApply` 被自己拒绝）。

### B2. profile-change
1. **`Project` 签名取 `PlayerProfile Project(spec)` + `PushError` + `throw`**（投影失败 = 组装缺陷 = 必需缺失，落总则 2 第一档）。废弃草稿的 `bool TryProject(..., out ...)`。
2. **`AppliedChange` 的「恒不含」断言只覆盖 `TraceElements`，`RngElements` 照入账**（自指防呆成立；RNG 终态入账才使「可直接重放的账」这条已写进活文档的定性成立）。
3. **明写累加进 `AppliedChange` 时的列剔除清单**：`ActiveCombat` 这类「账本本身」的列不累加，只累加变更。
   否则战斗内 D0–D5 逐点提交会把约 31 份完整 `ActiveCombat` 块（2–4 KB/份）灌进 `PastEventEntry.AppliedChange`，与痕迹侧只存 `EnemyId + Level` 轻摘要的体积纪律正面相抵。
4. **`SeedManager` 清账断言 ③ 的检查点移到决策点持久化前的组装方**，不放 `ProfileManager` 入口（那会让 profile-service 反向读 life-cycle-service，违反「服务之间不读写对方字段」）。
5. spec 改 **`sealed record` + `with`**（保持不可变，与 `EventOption` 的现成惯用法同形）。
6. **`Seq` 起始值取 0**，并在 `adventure-event/common-properties.md` 的 `Seq` 条目明写起始值（当前空白）。
7. **`DrawCount` 单调校验只约束轮回进行中的 upsert**；子流初始化随 `StartCycle` 附带写入，不给承重校验开例外口子。
8. **两条一次性纪律分级**：跨 `await` 持有取第 1 级（`ref struct` 包装，只在线上时序下发生）；「`Project` 之后改了 ① 类列」取第 3 级（组装代码的静态形状，开发期必现）。
9. **`Aborted` 那一笔与轮回结束统计同一次提交**（与「一个事件的收口是一次事务、一个存档点」同向）。
10. 五项已定案照办：`RngElements` / `TraceElements` 各自成列 · 收敛 `ActiveCombat.rng` · `TraceElements` 直接复用 `PastEventEntry` · 投影判负照常提交 · 一致性校验落 `ProfileManager` 入口。

### B3. codex
1. **A2 的可选 `LocalizedText` 判据**（见上）。
2. **初始持有也进图鉴**：口径扩为「凡进入持有列表 / 凡 `CurrentLocationId` 被置值即记」。
   否则玩家自带的绑定神通与出生地在图鉴里是空的，而内核是「接触即记」，且 LocationCodex 明写「去过即记」。
3. **EnemyCodex 搭车的那次提交写作「随战斗开始那一次 profile 提交」，不点名 `activeCombat`**（它的列面是别人的待决问题，点名会制造第二权威）。
4. 四项已定案照办：严格「获得即记」· 首批零计数字段（聚合项作为将来方向）· EnemyCodex 维持 3 张关键卡 · `CodexFlavor` 做且可选。
5. **独占 `terminology.md`**（见 A4）。

### B4. game-setting
1. **`SettingAssignment` 改 `int?` / `bool?` 两格皆可空**。`null` = 本次不涉及，与合法值 `0` / `false` 可区分，失败语义才可机械检查。有同库先例 `EventStateAssignment`。
2. **A5 的 `AtomicJsonFile`**（本分片独占落笔）。
3. **A1 的 `en` 留空口径**。
4. 15 字段表第 15 行「层」格填 `—`，**不立第三个层名**（分层通则是判据不是分类学）。
5. **不在后端库留「`gameSetting` 不透明」的承接**（本次未改任何契约，「不进白名单」不构成新增义务）。
6. `SettingFields` 默认值留代码常量表，明写「这些是 UI 初值 / 缺省，不是平衡数值」使 `data-resource-rules.md` 的边界可判。
7. 六项已定案照办：`locale` 归设备本地 · 首批清单取窄 · 语言开关首批隐藏 · 音量默认 100/80/100（待实测）· 三条音量轨归账号级。
8. 事实订正：15 字段表第 15 行**只有「写入通道」一格是 `⟨待定⟩`**（「层」格已是 `—`，草稿称两格皆待定有误）；`ux/screen-flow.md` 第 18 行 Settings 的「数据来源」列补设备本地。

### B5. bundle
1. **购后等待做成 Store 流程内的全屏模态进度态**（`STORE_` 分区文案），**不进阻塞变体表、不碰 `BlockingNoticeKind` 三成员**。
   「硬阻塞只有两处、永不得新增第三处」保持不变；其判据「只由已知 `code` 触发」恰好把这个客户端自愈等待态排除在外。行为定案（不允许提前离开）不变。
2. **兑现循环改为 `ordinal = Redeemed + 1` 循环**，直到追平 `Grant`。
   「差值 ≤ 1」的不变式只保证单设备；两台设备各自付款可使差值为 2，按草稿伪码会付两次拿一份。
3. **字段表第 14 行照 `accountInfo`（第 1 行）的既有写法**：后端写哪几项 / 客户端写哪几项，分开写。不写「无客户端写入通道」（`BundleRedeemedOrdinal` 正是客户端经 `Elements` 写入）。
4. **补上后端「回声校验」的客户端侧承接**：`playerDiff` 含 `entitlement` 时 `bundleGrantOrdinal` 须逐位相同，否则整批拒绝 `sync.conflict` + 风控。
   **只写客户端侧的承接与回链，绝不复述后端语义**（权威在 `backend-design-documents/contracts/profile-sync.md`）。
5. 兑现结果屏 = **Store 屏的一个结果态**（同屏切态，屏数不变）。
6. `BundleRedeemedOrdinal` 读档校验：`< 0` 钳到 `0`，`> Grant` 钳到 `Grant`。
7. `vision/scope.md`：**只把「支付接入 + 商店 UI」移进 MVP，地区定价留在范围外**（与 `monetization.md`「金额属发行侧、不落客户端」逐字相容）。
8. 三项已定案照办：加水位字段 `BundleRedeemedOrdinal` · 设立兑现结果屏 · 不允许提前离开。另记两条相邻定案：平台内购 SDK 纳入 MVP（Google Play Billing / App Store / 微信支付）· 纯外观付费点架构预留、实现推后。
9. **跨库**：后端半在 `backend-design-documents/inbox/` 有同名 counterpart，**本次不写后端库**（那份草稿走它自己的运行）。客户端侧只回链，不复述。

### B6. device-id
1. **`device-id.json` 不带 `schemaVersion`，同批修订三处全称措辞**（`architecture.md` / `common-properties.md` / `.claude/rules/state-save-rules.md`）：把「`user://cache/` 一律带 schema 版本」改为带判据的措辞（多字段结构体才需版本）。库内已有先例 `dismissed-recommended-version.json`。
2. **A5 的 `AtomicJsonFile`**：本分片只写回链，本体由 game-setting 侧落笔。
3. 「不进 `PlayerProfile` 的三样」**不补成四样**，改为把判据说清。
4. 首次生成（文件不存在）**留一行 `GD.Print`**（满足「正常态不该 warning」+「关键状态转换要留痕」）。
5. **同批更新后端 `contracts/auth.md` 那句已失真的「余下两点待落」**——一行回链、零规则复述，消除两侧互指错位。
6. 三项已定案照办：不提供展示口 · 32 位裸 hex · 原子写抽成共享静态工具。
7. **不碰 `open-questions.md` 的「derive 就绪度」小节**（含其子节「建议的 derive 顺序」，L65 与 L117 同属该小节）——归 `/assess-derive-readiness` 独占。
8. `deviceId` 从未作为条目进入任何 `open-questions/` 分片（只在 `account-service.md` 的待决问题里），故分片无条目可删，但 answer log 仍要建。

### B7. pickmany
1. **闸 ③ 的「另取一条填补批次」整条作废**，抽不足就产出更小的批次。`EventOptionBatch` 明写「1 项的批次合法」。
   不松动 `future-event-service.md`「不设单项补位，没有 `TryRefill` 一类的方法」。
2. **闸 ② 穿透进既有的 Explore 壳过滤**：取池期就把「真身是空库存 Exchange」的壳滤掉，与既有「真身须同样 enabled」过滤同形同档。
3. **reroll 前置校验 + 按钮置灰**（与礼包闸 ② 同形，付费前拦截）。
   **这松动了已定案的「零 UI 改动、零文案键」**——需动 `exchange/_index.md` 的 reroll 段与 `ux/error-and-blocking-ux.md` 的灰态判据表（加一行）。用户已知情并同意松这一格。
4. **`GrantableCount` 加一个可选 `rarityFilter` 参数**。「零新增接口」的声称随之作废——闸的判据必须与实际抽取链同口径，这是闸 ② 能声称「闸 ③ 空分支理论不可达」的全部依据。
5. 闸 ① 的聚合口径改为**逐 `RarityTier` 档位核算**（现口径会放过 `RarityFilter` 重叠但不相同的多条规则，而闸 ① 的存在理由就是启动期机械失败）。
6. 闸 ② 过滤后批次不足 / 池空**不新增分支**，写一句推论落在既有三条定案上（1 项批次合法 · Travel 恒可产出 · 池空即坏数据）。
7. 三道闸的**分界判据本体写 `future-event-service.md`** 的闸 ②/③ 小节，`monetization.md` 只补一句回链。
8. **「开局构筑事件可以缺席、首批退化为常规批」写进 `research/_index.md`**（缺席是大声失败的运营事故、不设补发），`future-event-service.md` 闸 ② 段回链。
9. 五项已定案照办；连带答定「开局强制构筑事件缺席时开局流程仍成立」；前置依赖「满袋能否购买道具」已答定（不能买、走购买前置校验拦截，池计数口径不受影响）。

### B8. arch-residuals
1. **纪律 7 的本体迁进 `systems/viewmodel.md`，`systems/common-properties.md` 留一句回链**。
   **注意：草稿称「纪律 7 至今没有任何主题文档承载」是假陈述**（`common-properties.md:202` 逐字载有）——**不得把这句假陈述按「保留理由」写进活文档**。建 `viewmodel.md` 的结论不受影响（另三条判据仍成立）。
2. **横切件表的落点是 `program-overview.md:68-74`，不是 `system-overview.md`**——草稿写错，按前者落笔。
3. **退避抖动改为只向上抖：`× (1 + rand[0,0.2])`**。原式 `±20%` 会以 0.8× 击穿服务端下界，与「服务端值是下界不是精确值」相抵。退避参数其余不变（`2s ×2 cap60s 无放弃阈值`），cap 60s 在 +20% 后为 72s，仍远低于滞留闸门 180s。
4. `architecture.md`「展示层契约」：**L100 的三条并列定义留在原处，L102 的第三层展开**（依赖方向 / 生命周期 / 不参与存档）**迁进 `viewmodel.md`**。
5. `ux/_index.md` 用**引言块**指路，不在表内加行（该文件已有两处「边界/归属」引言块先例；加进表内会污染索引语义）。
6. `viewmodel.md` 建**空的 `## 待决问题`** 小节沿用模板惯例；实测那条只在 `05-service-contracts.md` 留一份。
7. 五项已定案照办：push 退避参数（含 3 的修正）· 现在单列 `systems/viewmodel.md` · ADR 主落点归它 · 全景降级表不进主题文档 · ② 整条删除。
8. **核实结论（已由 worker 逐字核对，成立）**：② 的两问在 `content-service.md` L55/L57（不预埋占位 `Id`）与 L134/L138-141（记两个 `contentVersion`）有逐字原话 ⇒ 纯台账漂移，整条删除成立；① 主体在 `sync-service.md` L71-90/L134-151/L153-163 + `account-service.md:16` + `content-service.md` 两条降级有据 ⇒ 唯一真空白确是 push 侧退避参数。

### B9. translation
1. **三处启动期审计的调用顺序**：`AuditTranslations()` → `AuditCoverage()` → CJK 字面量审计。
   把唯一带编辑器守卫的那条排最后，保证编辑器与发布版的日志前缀一致。
2. **反向审计的数据源统一为消息表**，松动 `ux/error-and-blocking-ux.md` 三处「扫 `errors.csv`」的措辞。
   `.csv` 不随导出包分发 ⇒ 不改则反向审计在发布版静默失效（该文档自己给「能上线且线上不可见」定的最高档）；且不改会反过来推翻已定案的「不加守卫」。
3. 三项已定案照办：新增 `TranslationAudit.AuditCoverage()` 独立入口 · `zh` 缺失只 `PushError` 不 `throw`（不对称须写明理由）· 伪翻译走 `PushWarning`。
4. **`requirements/` 下不得创建或改动任何文件**：`FR-ux-translation-foundation` **不存在**，全库零个 FR，那份「五件事」清单在 `ux/error-and-blocking-ux.md`。草稿 frontmatter 的 `targets` 第三项是错的，以正文为准。
5. **A1 的 `en` 留空口径**。

### B10. breakdown
1. **本次同时在后端库落一份同构的粒度判据**（按 `design-library-routing.md` 2026-08-16b 的跨库纪律：输入本身横跨边界时允许一次运行写两库）。
   客户端库 `requirements/_index.md` **只写客户端指标**，后端库落同构判据，**两侧互相回链、绝不复述对方内容**。不在客户端库写后端列。
2. **签核状态规则表的判定对象改为「签核状态」而非 `status` 字面值**。
   配套：父 FR 的 `broken-down` 只由 `ready` 或 `draft` 迁入，父 FR frontmatter 保留一格记住迁入前的签核状态，使规则可机械判定。
3. 只迁「粒度判据 + 启发式第 2 条」，其余启发式留技能，**并补写分界判据：「阈值与准入闸（可数、是评审面）→ 设计库；切法与顺序（工程手法）→ 技能」**。
4. **归属判据那句写进 `decisions/ADR-0005`**（用户已明确授权本次动 `decisions/`——这是技能第 6 步默认禁止项的显式豁免）。按根约定「决策可被推翻」直接改写那份 ADR，不新开取代 ADR、不动台账排序。
5. U3 读作「**涉及的服务数 ≤ 1**」并把指标名改为「涉及的服务数」消歧。
6. 软下界改为 **`L1 ∨ L2` 成立 ⇒ 应并入，`L3` / `L4` 降为辅助信号**；并入的豁免与上界对称（超界写理由）。
   （用户已知情：这是对已定案阈值卡的结构性调整，超出「原样采纳」的字面授权。）
7. U6 起算点：**从该子需求所属系统的首个可交互屏起算**（不计全局启动链路）。
8. **同批更新 `requirements/_TEMPLATE-sub.md`**（其 `status` 注释与「`## Open questions` 非空不阻塞 blueprint」两处与新例外闸口径相抵）。
9. 技能第 7 步「已知边界 · 签核语义」**改写为一句回链**，不删除（例外闸是新加且反直觉——父 `ready` 却产出 `draft`）。
10. 四项已定案照办：继承 + Open-questions 例外闸 · 判据落 `requirements/_index.md` · 超界写理由 · 阈值原样采纳并标注待校准。
11. ADR-0005 相容性结论：**相容**。其冲突裁决表第一行原文已把「流程」归设计库，故把拆解粒度判给 `requirements/_index.md` 按现有条文即成立，不是外延扩展、更不是推翻。

---

## C. 全批通用订正（用户已批准「全部订正」+「顺手修，限本次触及的小节」）

**事实订正（无取向）：**
| # | 订正 | 落笔方 |
|---|---|---|
| 1 | 横切件表在 `program-overview.md:68-74`，非 `system-overview.md` | arch-residuals |
| 2 | `terminology.md`「图鉴族共五个」→ 六个 | codex |
| 3 | `architecture.md:277` 两参 `ErrorText.For(code, error)` → 三参 | translation |
| 4 | 补 `LastRoll` / `LastEffectiveChance` 两行 `ResourceElements` | costkey |
| 5 | `screen-flow.md` 第 18 行 Settings「数据来源」列补设备本地 | game-setting |

**越界发现顺手修（限本次触及的小节，不为守规矩扩大改动面）：**
- `ux/error-and-blocking-ux.md` 多处小节尾部的孤立 `-` 空 bullet 残留 → translation
- `system-overview.md` 的 `text/` 目录树缺 `store.csv` → translation
- `enemy-codex.md` 仍引用已整条移除的意图机制作论据 → codex

---

## D. 编排指令（Phase B 分工，铁律 ②③）

**波次（严格串行，除 W1 内两片并行）：**

| 波次 | 分片 | 说明 |
|---|---|---|
| W1 | profile-change ‖ breakdown | 两者写入面完全不相交。profile-change 的「三级判据第六面措辞补全」必须最先落 `architecture.md`——codex / game-setting 的分列结论依赖同一条判据的措辞。 |
| W2 | bundle | 先撤下账号层旧第 8 成员、落 `BundleRedeemedOrdinal` |
| W3 | costkey | 15 成员表依赖 W2 已撤下的行、归宿表依赖 W1 的新列名 |
| W4 | game-setting + device-id | 合并同一 worker（`AtomicJsonFile` 单一 owner） |
| W5 | codex | 独占 `terminology.md`（一次加齐四列）与 `sync-service.md` 的 bump 句 |
| W6 | pickmany | |
| W7 | arch-residuals + translation | |

**单写者指派（其余 worker 一律不碰）：**
- `terminology.md` → **codex（W5）**，一次加齐四列 + 图鉴族五→六。
- `sync-service.md` 的 **schema bump 句** → **codex（W5）**，写成一次 bump 涵盖四个新增列 + 两个子对象 schema。其余 worker 可写 `sync-service.md` 的其它小节，但**绝不写 bump 句**。
- `AtomicJsonFile` 本体（`architecture.md` 构件条目 + `sync-service.md` L197 职责改写）→ **game-setting/device-id（W4）**。
- `content-service.md` 的语言校验表字段级判据 → **codex（W5）**。

**worker 一律不写（orchestrator 收尾代笔）：**
`handoffs/_index.md` · `open-questions.md` 索引 · `open-questions/*` 分片 · `open-questions/update-log.md` · `answer-logs/_index.md` · `inbox/_index.md` · 草稿归档（`git mv`）。
台账行以文本形式写进各自的 `report-<分片>.md` 交回。

**全批硬边界：**
- **不碰 `open-questions.md` 的「derive 就绪度」小节**（含子节「建议的 derive 顺序」）——`/assess-derive-readiness` 独占。不在任何文档写「可 derive / 暂缓 derive」，报告里也不给就绪度结论。
- **溯源三条**（技能 6b）逐条自查：`Source:` 挂小节不挂条目、正文不写过程坐标（日期戳 / handoff 路径 / 「推翻 X」）、不写「已定案」。写完每份活文档跑一次自查 grep。
- `decisions/` 只有 breakdown 分片获授权改写 **ADR-0005**；其余分片一律不动 `decisions/`。
- 跨库写入只有两处获授权：breakdown 的后端粒度判据、device-id 的 `contracts/auth.md` 一行回链。**bundle 分片不写后端库。**

# Phase A — translation

- 分片：`translation`
- 输入：`game-design-documents/inbox/solution-draft-translation-english-placeholder.md`（`status: decided`）
- 目标库：`game-design-documents/`（主库，**无对侧库影响**——草稿自陈「不触碰任何后端报文、无跨库影响」，已核实：本次涉及的三份文档均无 `backend-design-documents/` 承接面）
- 结论：**🔴 0 · 🟠 2 · 🔵 7**

## 一句话摘要

`res://text/` CSV 的 `en` 未翻译形态定为**空单元格**（与内容层「缺 `en` 键」同一条判据的第二次兑现），配 `project.godot` 的 `internationalization/locale/fallback = "zh"` 承接运行时回落，并新增 UI 层静态入口 `TranslationAudit.AuditCoverage()` 做全分区 en 覆盖率审计（三判据：未翻译 / 伪翻译含 CJK / 已翻译），三条审计的数据源统一改为 `TranslationServer.GetTranslationObject(locale)` 的消息表。

## 已定案项（用户已裁决，不进 interview）

草稿 `## 用户裁决（2026-08-19 · 全部定案）`：**三项取向全取选项 1，逐条无保留采纳**；并声明 `## 建议方案` 与 `## 具体形态` 各节即最终形态。

| # | 取向 | 定案 |
|---|---|---|
| A | 覆盖率审计落点 | 新增 UI 层静态入口 `TranslationAudit.AuditCoverage()`，与 `ErrorText.AuditTranslations()`、CJK 字面量审计**同处启动期依次调用**（三处） |
| B | `zh` 列为空 | **只 `PushError`（键 + 分区文件），不 `throw`**；与内容层的 `PushError + throw` **刻意不对称，理由须写进文档** |
| C | 伪翻译（`en` 含 CJK） | `PushWarning` + **不计入覆盖率分子** |

另外这些在草稿内被标为 `[既有推演]`、不属取向选择，一并视为已定：
- 占位形态 = `en` 单元格留空，**不写任何哨兵值**；连带两条禁令（`en` 列绝不复制 `zh` 原文 · 绝不写键名本身）。
- `project.godot` 增设 `internationalization/locale/fallback = "zh"`，调用点零分支、**不逐次警告**。
- `ErrorText.For` 的「一级键缺条目才 `PushWarning`」订正为「**一级键在默认语言 `zh` 下无条目**才 `PushWarning`」。
- 三条判据的「缺键 **或** 空值」双判据（刻意不依赖 CSV 导入器空单元格行为的实测）。
- 覆盖率审计覆盖**全部** `res://text/*.csv` 分区；正向 / 反向两条仍只针对 `ERR_` 分区。
- 不加编译期 / 构建期闸；`en` 缺失一律不阻塞；`AuditCoverage` 不加 `OS.HasFeature("editor")` 守卫。
- 五个被否决的备选形态（键名本身 / `TODO` / 机翻初稿 / 复制 `zh` / 自包一层 `UiText.Get` / EditorScript 手动跑）——**否决理由承重，须以正面陈述保留**（溯源三条②：删掉理由，后来者会重新提出同一方案）。

## FR 连带影响核实

**结论：无 FR 连带影响。`FR-ux-translation-foundation` 目前只是一个「被点名但尚未 derive」的计划中 FR，不存在任何文件。**

核实过程：
- `game-design-documents/requirements/` 下**只有** `_TEMPLATE.md` · `_TEMPLATE-sub.md` · `_index.md`，**没有任何 `FR-*.md` 或 `FR-*/` 文件夹**。
- `requirements/_index.md` 的台账表当前是 `| _(暂无)_ | | | | | |` —— **全库零个 FR**。
- 全仓 grep `FR-ux-translation-foundation` 命中的设计库文件只有：`ux/error-and-blocking-ux.md`（「翻译键的铺开」节点名）· `open-questions.md`（derive 就绪度的建议顺序第 2 条）· `open-questions/05-service-contracts.md`（08-13 答结记录）· 08-13 的 handoff 与 answer-log。**无一处是 FR 文件本身。**

由此：
1. **不存在「改动一份已 derive 的 FR」这件事** —— 无状态迁移（`ready`/`broken-down` 皆不适用）、无子需求覆盖核对、无 `requirements/_index.md` 台账行需要改。
2. 草稿 frontmatter 的 `targets` 第三项写作「**requirements/ 中** `FR-ux-translation-foundation` 的第五件事」——**这个路径是错的**。「五件事」清单实际在 `ux/error-and-blocking-ux.md`「翻译键的铺开」节（第 102 行）。草稿正文 `## 后果` 一节写的是对的（「`ux/error-and-blocking-ux.md` …「翻译键的铺开」节里 `FR-ux-translation-foundation` 的第五件事」），frontmatter 与正文不一致，**以正文为准**。Phase B **不得**去 `requirements/` 下创建或改动任何文件。
3. **正向连带**：本条是 `ux/error-and-blocking-ux.md` derive 就绪度中「**唯一带行为面**」的卡点（`open-questions.md` 该行原话）。它消解后，该文档的 derive 面理应扩大——但**就绪度归 `/assess-derive-readiness` 独占**（SKILL 第 10 步 · `open-questions.md` 该小节的显式禁令），**Phase B 与 orchestrator 均不得改写 `open-questions.md` 的「derive 就绪度」小节**，也不得在报告里给就绪度结论。该小节里那句「其余卡于：**英文占位符形态**…」会因此暂时过时，**这是合规的过时**，等下一次全量扫描刷新。

## 🔴 冲突

**无。** 三处重点核对结果：

- 占位形态「空单元格」vs 内容层「缺 `en` 键」（`systems/services/content-service.md` 第 108 行）—— **同构不冲突**，且草稿明写内容层判据一字不改。
- `fallback = "zh"` vs 已定的「locale 启动期单点归一到封闭二值」（`ux/error-and-blocking-ux.md`「语言开关只有一个」）—— **互补不冲突**：归一决定 `GetLocale()` 落在 `zh`/`en`，fallback 决定 `en` 缺值时取哪一列。
- `AuditCoverage` 不加编辑器守卫 vs CJK 字面量审计**必须**加守卫（同文件第 173 行「导出包里 `.tscn` 已编译为 `.scn`、`.cs` 不随包分发」）—— **不冲突**，草稿已给出分界理由（数据源差异：消息表随包 vs 源文件不随包），且该理由必须落笔，否则读者会读成两套纪律。

## 🟠 含糊

### 🟠-1 三处启动期审计的**调用顺序**未在任何地方陈述，但被定案要求「必须写下」

- 草稿裁决 A 明写「调用顺序须在 `FR-ux-translation-foundation` 里明写」，收尾又列为「落笔时必须一并写下的两句」之②。但：① 该 FR 不存在（见上），顺序只能落进 `ux/error-and-blocking-ux.md`「翻译键的铺开」节的五件事里；② **草稿自始至终没有给出这个顺序本身**。
- 既有设计对此无权威：`ux/error-and-blocking-ux.md` 只说三者「同处启动期」「同形」「同为 `PushWarning`」，未定序。
  - 选项 (a) **`AuditTranslations()`（正向+反向）→ `TranslationAudit.AuditCoverage()` → CJK 字面量审计**
    后果：按「先查键在不在、再查值翻没翻、最后查源文件里有没有漏写键」的因果链排；三条告警在日志里由「结构问题」到「进度指标」递进，读日志的人先看到会挡住上线的那类。CJK 审计带编辑器守卫、排最后不影响另两条在导出包内的输出。
  - 选项 (b) **CJK 字面量审计 → `AuditTranslations()` → `AuditCoverage()`**
    后果：先报「压根没走翻译键」这一最根本的违规，再报键与值。代价是编辑器守卫的那条排在最前，导出包里日志的第一条会缺失、三条告警的相对位置在编辑器与发布版不一致。
  - 选项 (c) **不定序，文档只写「三处同处启动期、顺序不承重」**
    后果：省一条约定；代价是裁决 A 明确要求写下顺序，且日后三处被分散到不同 `_Ready` 时无据可依。
  - **推荐：(a)**。依据：`ux/error-and-blocking-ux.md` 自己为审计写下的判据是「**告警要落在能被看见的地方**」，而三条里唯一在发布版也要成立的是前两条（数据源为消息表）；把带守卫的那条排最后，可保证**编辑器与发布版的日志前缀完全一致**，排障时不必先分辨自己在哪个环境。这也与草稿把 CJK 判据描述为「同一条判据的第二次使用（服务于伪翻译检测）」相容——它在覆盖率之后被复用。

### 🟠-2 「与既有决策的张力」那一条（反向审计数据源改为消息表）是否已被「全部定案」覆盖

- 草稿把它单列在 `## 与既有决策的张力`，措辞是「**它是本方案顺带发现的一个既有缺陷，需用户确认订正**」，并给了两条路（松动 = 改消息表 / 不松动 = 双双加 `OS.HasFeature("editor")` 守卫）。
- 但它**不在** A/B/C 三项取向表里；而裁决段的总括句说「`## 建议方案` 与 `## 具体形态` 各节即最终形态」，而这两节**已经**按「松动」写死（建议方案 3 的数据源那条 · 具体形态的审计签名注释 · 对 `ErrorText` 代码块的订正 ②）。
- 之所以要问：这一条**改写的是一句既有已定案文本**（`ux/error-and-blocking-ux.md` 第 43 行 `AuditTranslations` 注释「反向 —— 扫 `errors.csv`」，以及第 137 行 `ERR_` 禁令小节的「**反向扫 `errors.csv`**」）。按 SKILL 3c，推翻既定表述必须由用户确认，不能靠总括句推定。
  - 选项 (a) **确认覆盖：三条审计数据源统一为 `TranslationServer.GetTranslationObject(locale)` 的消息表**，`errors.csv` 三处表述同批改写为「`ERR_` 分区的消息表」，反向审计的判据（前缀匹配）一字不改，不加守卫、不写 CSV 解析器。
    后果：`ux/error-and-blocking-ux.md` 第 43 · 80 · 137 行三处措辞改动；反向审计在发布版内同样成立。
  - 选项 (b) **不松动**：保留「扫 `errors.csv`」，反向审计与 `AuditCoverage` **双双**加 `OS.HasFeature("editor")` 守卫，接受「发布版无审计」，并保留一个 CSV 解析器。
    后果：与裁决 A 的「不加守卫」直接打架（`AuditCoverage` 得加回守卫），且与「不写第二套识别 / 解析设施」的既有偏好相悖。
  - **推荐：(a)**。依据：`.csv` 不随导出包分发这一事实与该文档**自己**为 CJK 审计写下的理由逐字同构（第 173 行）；不改则现状下反向审计在发布版静默失效——正是本文档给「能上线且线上不可见」定的最高档。且 (b) 会反过来推翻用户刚刚定案的 A 项（不加守卫）。

## 🔵 可推演（无需回答）

1. **本次为纯客户端意图，零对侧库影响。** 依据：涉及的三份文档（`ux/error-and-blocking-ux.md` · `systems/services/content-service.md` 的语言小节 · 无 FR）均无后端报文面；`res://text/` 已定为随包分发、不走 overlay / flags。
2. **`en` 空单元格 vs 既有措辞「英文列全部预设占位符」需一句订正，但不是冲突。** `ux/error-and-blocking-ux.md` 第 89 行「英文列全部预设占位符」与第 157 行「短期 `en` 全占位符」在定义「占位符 = 空单元格」之后会读成自相矛盾（空 = 没有占位符）。改为陈述形态本身即可，例：「**`en` 列一律留空 —— 未翻译的形态就是「该列没有值」，不写任何哨兵**」。属措辞收口，不改任何语义。
3. **`errors.csv` 的合法性判据（第 80 行「`errors.csv` 的一行合法当且仅当…」）随 🟠-2 的裁决同批改写为「`ERR_` 分区的消息表」**，判据文本本身不动。（若 🟠-2 取 (b) 则此条不动。）
4. **`ErrorText` 类注释两处订正**为草稿「具体形态」所列的原文，另需在类外补一句指向 `TranslationAudit` 的一行（否则读者会以为覆盖率也在 `ErrorText` 内）。
5. **五件事清单（第 102 行）三处增补**：第二件事补 `fallback = "zh"`；第三件事的类清单补 `TranslationAudit`；「落下方**两条**审计」→「**三条**审计」。
6. **`content-service.md` 第 108 行末尾那句「（`res://text/` CSV 一侧的占位符形态是另一个问题，仍待定，见 `ux/error-and-blocking-ux.md`）」改为已答形态的回链**，内容层判据一字不改；且**不要改**第 106 行「前两个：`ErrorText.AuditTranslations()`、负向条目清单」的枚举——它数的是「告警落在能被看见的地方」这条判据的实例，`AuditCoverage` 是第四个而非替代。
7. **溯源三条（SKILL 6b）在本次的具体落点**：三份活文档均已各有一条小节级 `Source:`（`ux/error-and-blocking-ux.md` 第 280 行是文档尾部的合并行），本次**只在该行追加本次 handoff 路径**，不新增第二条 `Source:`；正文不得出现 `08-19` / handoff 路径 / 「原方案 / 推翻」等坐标——被否决的五个备选一律改写成正面理由陈述。

## 拟改动文档清单与各自新增要点

**worker 独占（Phase B 可直接写）：**

| 文档 | 新增/修改要点（供跨草稿核对） |
|---|---|
| `handoffs/2026-08-19-translation-english-placeholder.md`（新建） | 全文；`topic: ux/error-and-blocking-ux`；`status: distilled`；`distilled-to:` 两份主题文档 |
| `ux/error-and-blocking-ux.md`「翻译资源」节 | 占位形态 = `en` 留空 + 两条连带禁令（不复制 `zh` 原文 · 不写键名本身）+ 五个否决理由的正面化保留；第 89 行「预设占位符」措辞订正 |
| 同上「翻译键的铺开」节（第 102 行五件事） | 第二件事补 `internationalization/locale/fallback = "zh"`；第三件事补 `TranslationAudit`；「两条审计」→「三条审计」；**三处启动期审计的调用顺序**（待 🟠-1） |
| 同上「键命名规范」节 + `ERR_` 禁令小节 | 两条审计 → 三条；第 80 · 137 行的「扫 `errors.csv`」→「扫 `ERR_` 分区的消息表」（待 🟠-2） |
| 同上 `ErrorText` 代码块（第 25–46 行） | ① `For` 注释「一级键缺条目才 `PushWarning`」→「一级键**在默认语言 `zh` 下**无条目才 `PushWarning`」；② `AuditTranslations` 注释「反向 —— 扫 `errors.csv`」→「反向 —— 扫 `ERR_` 分区的消息表」（待 🟠-2）；③ 新增 `TranslationAudit.AuditCoverage()` 签名块 + 三判据表 + CSV 四态行形态表 |
| 同上「语言开关只有一个」节 | 第 157 行「短期 `en` 全占位符」措辞订正；补 `fallback = "zh"` 与启动期归一的分工一句 |
| 同上「UI 文案字面量审计」节 | 补一句**守卫的分界理由**（消息表随包 ⇒ 前两条不需守卫；源文件不随包 ⇒ CJK 那条必须守卫；**这是数据源差异，不是两套纪律**） |
| 同上 `## 待解问题` | 移出「`res://text/` CSV 侧英文占位符的具体形态」整条（第 288 行）；其余三条**不动** |
| 同上文档尾 `Source:` 行（第 280 行） | 追加本次 handoff 路径（不新增第二条 `Source:`） |
| `systems/services/content-service.md`「内容文本的语言校验与覆盖率审计」节 | **仅**改第 108 行末尾括号：「CSV 一侧仍待定」→ 指向 `ux/error-and-blocking-ux.md` 的已定形态回链；**内容层判据一字不改**；B 项「UI 层只 `PushError` 不 `throw`」的**不对称理由**须在此侧或 ux 侧择一处写明（推荐写在 ux 侧、此侧只回链，避免第二权威） |

**共享台账（铁律② — worker 不写，随报告交回给 orchestrator）：**

| 文件 | 要写的内容 |
|---|---|
| `handoffs/_index.md` | 置顶新增一行：`2026-08-19-translation-english-placeholder \| 2026-08-19 \| ux/error-and-blocking-ux \| distilled \| ux/error-and-blocking-ux.md, systems/services/content-service.md` |
| `open-questions/deferred-content.md` | 该条是**复合条目**（「英文占位符的具体形态**与错误文案的实际措辞**」），**不能整条删除**——只移出占位符那一半，剩下的重写为「各 `ERR_*` 与四条兜底文案的逐条中文措辞待文案定稿 → `ux/error-and-blocking-ux.md`」 |
| `open-questions/05-service-contracts.md`（第 29 行） | `auto_translate_mode` 那条里「两种情况下键的形态、分区表、**两条审计**完全相同」→「**三条审计**」 |
| `open-questions.md` 顶部「最近更新」 | 一行：`最近更新：2026-08-19 — 英文占位符形态与覆盖率审计（详见 open-questions/update-log.md · answer-logs/log-translation-english-placeholder.md）` |
| `open-questions.md`「derive 就绪度」小节 | **禁止改动**（`/assess-derive-readiness` 独占）。其中 `ux/error-and-blocking-ux.md` 一行的「其余卡于：英文占位符形态」将暂时过时，属合规过时 |
| `open-questions/update-log.md` | 顶部追加本次摘要（答结 1 条 · 新增 0 条 · 对应 answer log） |
| `answer-logs/log-translation-english-placeholder.md`（新建） | 1 条：**`res://text/` CSV 侧英文占位符的具体形态** → `en` 单元格留空 + `fallback = "zh"` + `TranslationAudit.AuditCoverage()` 三判据（归档去向：`ux/error-and-blocking-ux.md`）。须注明**同源的「逐条中文措辞」一半仍留在待答清单** |
| `answer-logs/_index.md` | 追加一行：`log-translation-english-placeholder.md \| 2026-08-19 \| inbox/solution-draft-translation-english-placeholder.md \| 1` |
| `inbox/_index.md` | 从「待处理」表删该行；「已归档」表补一行（去向 handoff + answer log） |
| 草稿归档 | `inbox/solution-draft-translation-english-placeholder.md` → front matter 加 `reviewed:` / `distilled-to:` 并改 `status: distilled`，`git mv` 进 `inbox/archive/` |

**不改动（明确排除）：** `requirements/` 下任何文件（无 FR 存在）· `systems/common-properties.md`（`LocalizedText` 形态不变）· `decisions/`（无 ADR 被推翻；也不新建——立档归 `/write-adr`）· `backend-design-documents/` 任何文件。

## 越界发现

1. **`systems/architecture.md` 第 277 行仍写 `ErrorText.For(code, error)` 两参**，而 `ux/error-and-blocking-ux.md` 已于 08-17 定为**三参** `For(code, reasonKey, error)`。这是既有漂移，与本分片的占位符问题无关，**本 worker 未改动**。建议 orchestrator 记入总报告，由用户决定是否顺手订正（改动面 = 一行）。
2. **`system-overview.md` 的 `text/` 目录树（第 108–119 行）缺 `store.csv`**，而 `ux/error-and-blocking-ux.md` 的分区表已含 `STORE_` / `store.csv`（08-15b 新增）。同为既有漂移，本分片未处理。
3. `ux/error-and-blocking-ux.md` 多处小节以孤立的 `-` 行结尾（第 60 · 95 · 105 · 139 · 153 · 177 行），疑似历史编辑残留的空 bullet。**本 worker 只在改动触及的小节顺手清理**（SKILL 6b 末条），不扩大改动面。

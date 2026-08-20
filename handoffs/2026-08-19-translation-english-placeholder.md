# 未翻译的英文形态 = 空单元格，配 fallback locale 与一条覆盖率审计

- id: 2026-08-19-translation-english-placeholder
- date: 2026-08-19
- topic: ux/error-and-blocking-ux
- status: distilled
- distilled-to: ux/error-and-blocking-ux.md, ux/_index.md, systems/services/content-service.md, systems/architecture.md（`ErrorText.For` 参数订正）, system-overview.md（`text/` 目录树补 `store.csv`）

## Intent（distilled）

「全库 UI 文案走翻译键、中文为默认与优先制作列」已成文，但**未翻译的英文条目长什么样**从未陈述。这不是措辞问题：若未翻译的形态是一个**非空字符串**，而审计只判「这一行有没有值」，英文覆盖率就**恒读作 100%**，审计等于失效——而它失效时**没有任何症状**（中文玩家看不出差别，做英文版时才整片暴露），正是本库给「能上线且线上不可见」定的最高档。

### 1. 未翻译的形态 = `en` 单元格留空，不写任何哨兵值

一行未翻译时写成 `KEY,"中文文案",`。「未翻译」的判据是**该 locale 下没有可用值**，而不是「该 locale 下有一个约定好的特殊值」——与内容层「`Entries` 只有 `zh` 键」逐字同构，两层载体不同但判据同一条，**覆盖率审计因此不需要第二套「什么算占位符」的识别规则**。

**两条连带禁令：** `en` 列绝不复制 `zh` 原文（覆盖率恒读 100% 最容易发生的路径，且英文玩家看到中文、零症状，由伪翻译告警挡住）；`en` 列绝不写键名本身（它是第 1 列的机械像，手写即违反「能机械变换的绝不建第二张手写表」，且引擎缺值时本就返回键名）。

**同样排除 `TODO` 一类哨兵**（形态必然漂移、审计要为它维护识别规则、相对空单元格零信息增量）、**机翻初稿**（覆盖率恒读 100%，且与人工翻译不可机械区分，要区分就得再加一列打破两列封顶）、**在 `tr()` 外自包一层回落**（引擎已提供该能力，包一层是把零成本配置换成全库调用纪律，且挡不住 `.tscn` 里直接写键的自动翻译路径）。

### 2. 运行时回落靠引擎配置，不在调用点写分支

`project.godot` 设 `internationalization/locale/fallback = "zh"`：`en` 下缺值 → 引擎自动回落 `zh`，**调用点零分支**，与内容层 `LocalizedText.Get()` 的行为完全一致。**不逐次警告**——未翻译期每一条都会命中回落，逐次告警会刷屏并淹掉真告警。**归一与回落各管一半**：归一决定 `GetLocale()` 落在封闭二值的哪一个上，回落决定该 locale 缺值时取哪一列。

配套订正一句既有措辞：`ErrorText.For` 的「一级键缺条目才 `PushWarning`」明确为「一级键**在默认语言 `zh` 下**无条目才 `PushWarning`」——按「当前 locale 解析不出值」判，英文下每个 `code` 都会报一次，那正是「真告警被噪音淹掉」的复现。

### 3. 新增 `TranslationAudit.AuditCoverage()`，三条判据

覆盖率审计要扫**全部分区**，而 `ErrorText` 是错误文案的门面（只服务 `ERR_` 分区），且覆盖率与错误码处置表零耦合。按「按它服务于谁定位，而不是按谁先用到它」，它落成 UI 层的独立静态入口。三条判据：**未翻译**（键不在 `en` 消息表中**或**其值为空 / 全空白，计入分母、不逐条告警）· **伪翻译**（`en` 值含 CJK，不计入分子 + 单列一条 `PushWarning`）· **已翻译**（其余）。「缺键**或**空值」是刻意的双判据，使本形态不依赖 CSV 导入器对空单元格行为的那次实测。

**`zh` 列为空 → `PushError`（键 + 分区文件），但不 `throw`**——与内容层的「`PushError` + `throw`」**刻意不对称**：内容层 `throw` 是因为坏内容会进抽取池、被存档引用，把错误扩散到不可逆处；缺一条 UI 文案只影响一屏的一处显示，回落后仍是一个可操作的界面。

**`en` 缺失一律不阻塞，不加编译期 / 构建期闸**（当前每一条都缺 `en`，任何硬闸门会让游戏起不来；本机验证走 Godot 编辑器运行）；**否决做成 EditorScript 手动跑**——脱离启动链就没人会记得跑。

### 4. 三条审计的数据源统一为消息表，调用顺序写死

`.csv` 是导入源文件、**不随导出包分发**，读源文件的审计在发布版中无从执行。三条审计的数据源统一为 `TranslationServer.GetTranslationObject(locale)` 的**消息表**，判据一字不改（反向仍是前缀匹配），且省掉一个 CSV 解析器。

**调用顺序：`ErrorText.AuditTranslations()` → `TranslationAudit.AuditCoverage()` → CJK 字面量审计。** 前两条按「先查键在不在、再查值翻没翻」的因果链排；**带编辑器守卫的 CJK 那条排最后**，保证编辑器与发布版的日志前缀完全一致。**只有 CJK 那条需要守卫——这是数据源差异，不是两套纪律**：判据一句话，扫源文件的必须守卫，扫消息表的不必。

## Clarifications

- **三处启动期审计的调用顺序在原始输入中被要求「必须写下」，但输入本身没有给出这个顺序。** 裁决取「`AuditTranslations()` → `AuditCoverage()` → CJK」，理由是把唯一带编辑器守卫的那条排最后，可保证编辑器与发布版日志前缀一致。
- **「反向审计扫 `errors.csv`」是既有已成文表述，改动它需明确确认，不能靠「本方案各节即最终形态」这句总括推定。** 裁决：**确认松动**，三处「扫 `errors.csv`」措辞统一改为「`ERR_` 分区的消息表」；不改则反向审计在发布版静默失效，且会反过来推翻「`AuditCoverage` 不加守卫」这条定案。
- **原始输入 frontmatter 把「五件事」清单的落点写成 `requirements/` 下的一份 FR——该路径不成立**（`requirements/` 下目前没有任何 FR 文件）。以正文为准：清单在 `ux/error-and-blocking-ux.md`「翻译键的铺开」节，本次**不创建也不改动 `requirements/` 下任何文件**。
- **两份并行草稿对未翻译形态的措辞不一致**（一侧写「`en` 列全部预设占位符」）。裁决：**统一取「`en` 单元格留空、不写任何哨兵值」**，`ux/` 与 `systems/services/content-service.md` 两侧措辞同批对齐——「该 locale 干脆没有这个值」就是占位的形态。

## Open questions

- 各 `ERR_*` 与四条兜底文案的**逐条中文措辞**仍待文案定稿（填 `zh` 列的内容，与本次定的 `en` 列形态互不牵动）。
- `reasonKey` 二级措辞的逐条中文措辞，同上。
- Godot 4.7 上 `Control` 自动翻译（`auto_translate_mode`）的默认行为待实测；两种情况下键的形态、分区表、三条审计完全相同，不阻塞。

## Notes / triage

- 存档 schema / 协议契约 / 抽取池 / overlay：零影响，无跨库承接项。
- 顺手订正三处既有漂移：`systems/architecture.md` 的 `ErrorText.For` 由两参改三参；`system-overview.md` 的 `text/` 目录树补 `store.csv`；`ux/error-and-blocking-ux.md` 多处小节尾部的孤立空 bullet 残留。

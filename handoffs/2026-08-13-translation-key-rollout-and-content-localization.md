# 翻译键的铺开纪律 与 内容条目的多语言形态 `LocalizedText`

- id: 2026-08-13-translation-key-rollout-and-content-localization
- date: 2026-08-13
- topic: ux/error-and-blocking-ux, ux/_index, systems/common-properties, systems/services/content-service, system-overview
- status: distilled
- distilled-to: `ux/error-and-blocking-ux.md`, `ux/_index.md`, `systems/common-properties.md`, `systems/services/content-service.md`, `system-overview.md`

> 输入 = `inbox/solution-draft-translation-key-rollout-and-content-localization.md`（`status: decided`，四项裁决已由用户定下）+ 本次 interview 两项落地形态裁决。

## Intent（distilled）

**一句话：** 语言在本作分两层承载——**界面走 `res://text/` 翻译键**（随包、发版才改）、**内容走条目内嵌的 `LocalizedText`**（overlay 可热更），**但两层共用同一个语言开关**，且中长期语言范围**封顶为中英双语**。

### 零、贯穿全篇的一条前提

`game-feature-branch/` 当前**没有任何 `.tscn` / `.cs` / `.tres`**（只有 `project.godot` 与 `icon.svg`）。**UI 文案与内容资产的存量都是零**——这是下面每一条「现在改是纯加法」论证的支点，也是这个窗口会在第二阶段写下第一批 `.tres` 时关闭的原因。

### 一、翻译键：没有改造期，只有一条起手纪律

- **「逐屏改造如何排期」这个提法被否掉——它默认了一个不存在的存量迁移场景。** 定案改为一条纪律：**每个屏从写下第一行起就用翻译键，全库不新增任何 UI 文案字面量。** 与 08-12 否决「先用 C# 常量表、待全局 i18n 决策时再迁」是同一条推理在排期维度的落点：连「先写字面量」这一步都不该发生。
- **推论：「随各屏 FR 一并落地」与「集中做一次」不是二选一。** 前者描述纪律的作用方式（每份 UI FR 天然带着它），后者要处理的批量迁移根本不会产生。
- **唯一需要集中做的是一次性基建**，且它是第一份含 UI 文案的 FR 的前置：建 `res://text/` 与首批分区 CSV · 在 `project.godot` 注册翻译资源并设默认 locale `zh` · 落 `ErrorText` · 落键命名规范与分区表 · 落两条审计。**它就是 `FR-ux-translation-foundation`，横切、不挂任何单屏**——挂在某个屏下会让第二个屏的 FR 依赖第一个屏的 FR，凭空造出一条与设计无关的构建顺序（与「`ErrorText` 按『它服务于谁』定位而非『谁先用到它』」同一种归位思路）。

### 二、键命名规范只有三条 + 一条禁令

1. **`SCREAMING_SNAKE_CASE`**，恒 ASCII（既有 `ERR_*` 已是此形态，不另立第二套）。
2. **`<PARTITION>_<CONTEXT>_<NAME>`**，首段是分区前缀。
3. **一个分区 = 一个 CSV 文件**（`res://text/<partition>.csv`，文件名小写）——收益是分工与 diff。

**分区表是开放表，随屏幕落地增补**（首批十个：`ERR_` / `COMMON_` / `BOOT_` / `LOGIN_` / `MENU_` / `SYNC_` / `EVENT_` / `COMBAT_` / `PROFILE_` / `SETTINGS_`）。**边界必须写进规范：分区划的是界面，不是内容域**——`EVENT_` 装的是选项框的按钮与标题，事件正文一个字也不进。

**禁令：`ERR_` 分区保留给机械变换，人不得手写 `ERR_` 开头的键。** `ERR_*` 的键不是人取的，是 `code → ERR_ + 全大写 + `.`→`_`` 的像；允许手写就会与日后新增的后端 `code` 撞进同一个键，使一条后端错误静默显示成为别处写的文案——发版后才显形、现场看不出异常。可执行形态：**`ErrorText.AuditTranslations()` 改为双向**（正向查已知 `code` 缺不缺条目，反向扫 `errors.csv` 里有没有无对应 `code` 的 `ERR_*` 行）。本地业务拒绝（如「储物袋已满」，没有后端 `code`）走所属分区的普通键，不占 `ERR_` 前缀。

### 三、内容多语言：条目内嵌 `LocalizedText`

**同一个 `Id`、同一个 `.tres`，多语言是该条目内部的一个字段结构**（`Entries: Dictionary<locale, 文本>`）。三条采纳理由逐条对上既有纪律：

- **加一门语言 = 在 `.tres` 里加一个键，零代码改动**（落在「新增内容 = 新增 / 编辑 `.tres`，不改 switch」内）。这同时否决了「每语言一个 `[Export]` 字段」——那种写法把语言数焊进 C# 类。
- **它是「改既有条目的字段值」⇒ overlay 可以热更它**，完全落在「只改不增」内：**线上补一段英文文案不必发版**。这是本形态相对全部替代方案的实质收益。
- **给出唯一的语言解析入口**（与 ContentRegistry、`AllEnabled()` 同一种偏好）：回落逻辑只写一处，校验与审计只需遍历这一个类型。

**三个被否决的替代形态：** 每语言一套 `Id`（撞「只改不增」· 抽取池权重被语言数稀释 · 切语言使存档引用悬空）· 内容文案塞进 `res://text/`（08-12d 四问判据已判；且把可热更降级为要发版）· 每语言一个 `[Export]` 字段（同上）。

**两条配套纪律：** `Get()` 必须纯读，**绝不把解析结果写回 `XxxData` / `LocalizedText`**（`XxxData` 是 ContentRegistry 里的共享只读单例，缓存写回会污染注册表；要缓存就缓存在 ViewModel 上）· `LocalizedText` **不落存档、不进上行负载**，不 bump schema、无迁移。

### 四、失败语义分方向

| 情形 | 语义 | 处置 |
|---|---|---|
| **默认语言（`zh`）缺失 / 空串** | 必需缺失——没有正文的内容就是坏数据 | 合并后强校验 `GD.PushError` + `Id` + 字段名 + `throw`，**启动期早失败**（与 `Rarity` 缺失同档） |
| **非默认语言缺失** | 可选缺失——降级完全可用 | **读取侧静默回落 `zh`，不逐次警告**；改由**合并后一次性审计**汇总缺失条目数、覆盖率与前 N 个 `Id`，一条 `GD.PushWarning` |

**方向必须分开的理由：** 英文列既定为「全部占位符」⇒ `en` 下**每一条内容**都会命中回落，逐次警告 = 每帧刷屏并淹掉真正的告警。而审计要有，是因为「告警要落在能被看见的地方」——这是 `content-service.md` 为负向条目清单写下的同一条判据，本条是它的第三个同形实例。**审计同时报覆盖率**（`en: 12 / 840`），使「英文版做到哪一步」成为一个能一眼读到的数。

### 五、语言开关只有一个，locale 标识符两层共用

`res://text/` 的 CSV 列名、`LocalizedText.Entries` 的键、`TranslationServer.GetLocale()` 的返回值**必须是同一套标识符**。`LocalizedText.Get()` **就读 `TranslationServer.GetLocale()`**，不另设一个内容语言设置——否则设置屏会长出两个语言开关，玩家能把界面切成英文而卡面留在中文。

**切语言后的重绘存在一条真实的不对称：** 走翻译键的 `Control` 会随 locale 变化自动重翻，而 `LocalizedText` 不经 `TranslationServer`，已组装好的 ViewModel 不会自己变。纪律：**ViewModel 层订阅翻译变更通知，收到即重新组装一次**（它本就是「按需组装、不落存档」的那一层）；「重进当前屏」是更粗的兜底手段。

### 六、双语封顶（本次追加的约束）及其三条推论

**语言范围封顶为中英双语（`zh` / `en`），不带地区码，短期 `en` 全占位符。**

- **`Entries` 键域是封闭的二值 ⇒ 合并后强校验可以更严**：出现 `zh` / `en` 之外的键 → `PushWarning`。拼错 locale（`En` / `en_US`）是一个真实且完全静默的失败面——整条文案在英文下回落中文而无任何症状；语言域若开放，这条校验根本无从写起。
- **体积翻倍是一个封闭的上限，不是一条增长曲线**（最坏 ×2 且到此为止）⇒「按语言分包」唯一的实质动机消失，**不再作为候选保留**。
- **`en` 的「占位符」在两层的形态不必相同**：内容层最自然的占位形态是**该 locale 干脆没有这个键**，由静默回落承接——它让「缺 `en` 键」= 「未翻译」成为一个干净可判的条件，覆盖率审计因此不需要第二套「什么算占位符」的识别规则。
- **不设 `zh_TW` 分列**：简繁差异是机械的，正确做法是简繁转换而非在 `Entries` 里再开一个键——同一条「能机械变换的绝不建第二张手写表」的判据（`code → ERR_*` 正是它的第一例）。

### 七、可执行化取阶梯第 2 级

「UI 层写了中文字面量」属**能上线且线上不可见**（中文玩家看不出差别，只有做英文版时才整片暴露），该档必须做到第 1 / 2 级。

- **第 1 级代价过高**：要让写字面量在语言层不可能，得禁止 UI 代码直接触碰 `Label.Text` / `Button.Text`，这与 Godot 编辑器内直接编辑 `text` 属性这一最自然的工作方式对着干，且 `.tscn` 里的字面量它一条也挡不住。
- **取第 2 级：一个审计**——扫 `res://scenes/**.tscn` 与 `res://src/UI/**.cs`，命中「文本属性 / 赋给 `.Text` 的字符串字面量**含 CJK 字符**」即 `PushWarning` 列出。CJK 判据在本作特别可靠：键恒为 ASCII 大写，内容文案不经 UI 代码传递（UI 拿到的是 `Id`，正文由 ViewModel 向 ContentRegistry 取）。

### 八、排期

- **`LocalizedText` 与 `DrawPool<T>` 同批**：**第二阶段（内容）开工前、第一份内容 FR 之前**落地。理由完全相同（纯加法窗口，一旦内容写完就退化为「改全部调用方 / 全部资产」），两者也天然是同一次 `XxxData` 面的改动。
- **`FR-ux-translation-foundation`** 在第一份含 UI 文案的 FR 之前。

## Clarifications（interview 产物）

1. **`LocalizedText.Get()` 与 CSV 两层实际吃到的 locale 值如何归一到封闭二值？** → **启动期单点归一**：启动时读系统 locale，取主语言子标签（`zh_CN` / `zh_TW` → `zh`，`en_US` → `en`），非 `zh` / `en` 一律置 `zh`，随即 `TranslationServer.SetLocale` 到该二值；此后两层直接吃已归一的 `GetLocale()`，各自零分支。日后若加游戏内语言设置项，它写入的也是同一个单点。
   - **这一项补的是草稿的一个缺口而非改写它。** 草稿只写了「三者必须是同一套 locale 标识符」与「取值域封闭为 `zh` / `en`」，未写归一规则；而 Godot 默认把 locale 设为系统 locale ⇒ 真机上 `GetLocale()` 很可能返回 `zh_CN` / `en_US`，与封闭二值键域对不上，导致**每一条内容文案在所有真机上都命中「缺键 → 静默回落」**——而静默正是第四节刚定下的读取侧语义，这条失败因此没有任何症状。
2. **CJK 字面量审计跑在哪里？** → **启动期 + 编辑器守卫**：保留在启动期、与 `ErrorText.AuditTranslations()` 同处同形同为 `PushWarning`，但以 `OS.HasFeature("editor")` 守卫，文档写明它只在编辑器内运行。
   - **理由：** 导出包里 `.tscn` 已编译为 `.scn`、`.cs` 不随包分发（编进程序集），源文件扫描在发布版中根本无从执行；不加守卫就是在文档里写下一条生产环境不可能成立的机制。
   - **用 `OS.HasFeature("editor")` 而非 `#if DEBUG`**：后者的成立性本身还是 `open-questions/05-service-contracts.md` 的一条待实测项，不该让一条新纪律压在它上面。
   - 否决「移出运行时做成 EditorScript 手动跑」：脱离启动链就没人会记得跑，与「告警要落在能被看见的地方」相抵。

## Notes / triage

- **与 `vision/scope.md`「本地化打磨在 MVP 范围外」不冲突**（澄清而非张力）：那条软约束要的是「现在不做多语言，但现在就不能挡住多语言」，其括号里自己写明的落法正是「让展示字符串与 id 分离」。`LocalizedText` 做的就是这件事的完整形态，且**不产出一个字的英文文案**（`Entries` 只有 `zh` 一个键完全合法且是默认状态）。真正的本地化打磨——英文措辞、字体、排版回流、地区定价——仍在 MVP 之外。
- **如实记下的代价：** 写 `.tres` 时每个文本字段多一层嵌套 SubResource，中文单语阶段内容编写手感变差一点。已被接受（裁决 ②）。
- **不触及的东西：** 存档 schema（不 bump、无迁移）· 抽取池（一条内容仍是一个 `Id`，权重不被语言数稀释）· 校验 / flags / overlay 事务模型（无一条需要放宽）· 硬阻塞点。
- **不与「剧本内容的体积与分发粒度」合流**：那条问的是剧本树该不该按篇章分包，语言维度已在此答定为不分包，两者各自独立决定。
- **无跨库影响**：纯客户端、纯本地，后端不感知。

## Open questions

- **Godot 4.7 上 `Control` 的自动翻译（`auto_translate_mode`）默认行为。** 若默认即生效，`.tscn` 里把 `text` 直接写成键就够了、UI 代码里连 `tr()` 都不必出现；否则显式 `tr()`。**两种情况下键的形态、分区表、两条审计完全相同**，故不阻塞任何定案；宜与 `#if DEBUG` 判据的实测合并到同一次 `.csproj` 生成后的实测。
- **`res://text/` CSV 侧英文占位符的具体形态**（键名本身 / `TODO` / 机翻初稿）——属文案定稿，留在 `open-questions/deferred-content.md`。**内容层一侧已答定为「缺键即未翻译」，该问题的范围仅剩 CSV 一侧。** 定下来时须回看覆盖率审计：若取键名本身，`AuditTranslations()` 得能识别它，否则英文覆盖率恒读作 100%。

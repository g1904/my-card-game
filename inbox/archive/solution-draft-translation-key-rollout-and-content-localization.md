---
type: solution-draft
date: 2026-08-13
question: 翻译键如何铺开（逐屏排期 + 是否需要集中的键命名规范），以及内容条目自己的多语言走什么表达形态
source: open-questions/05-service-contracts.md → 「翻译键的铺开节奏（08-12 新增）」及其邻域小项「内容条目自己的多语言表达形态（08-12d 标注）」
targets: ux/error-and-blocking-ux.md、ux/_index.md、systems/services/content-service.md、systems/common-properties.md、system-overview.md
status: distilled
decided-date: 2026-08-13
reviewed: 2026-08-13 —— 用户裁定四项：① 全语言内嵌（非按语言分包）· ② `LocalizedText` 现在上（与 `DrawPool<T>` 同批）· ③ 分区表按屏 10 个 · ④ 追加约束「语言范围封顶中英双语」。提炼时另经 interview 定下两项落地形态：locale 启动期单点归一到二值 · CJK 字面量审计以 `OS.HasFeature("editor")` 守卫。
distilled-to: handoffs/2026-08-13-translation-key-rollout-and-content-localization.md
---

> **已裁决（2026-08-13）。** 三项取向选择全部定案（见文末「已裁决」节），并追加一条新约束：**中长期语言范围封顶为中英双语**。本文件可直接喂 `/analyze-new-ideas` 提炼。

# 方案草稿 — 翻译键的铺开节奏 与 内容条目的多语言表达形态

## 问题

两个相邻、必须一起答的子问题——它们共用「同一门语言、同一个开关」这一个运行时事实，分开定会得到两套互不衔接的语言解析路径。

**① 翻译键的铺开节奏。** 08-12 已定「全库 UI 文案统一走 `TranslationServer` 翻译键」，`res://text/errors.csv` 是第一批。未定的是：**逐屏改造如何排期**（随各屏 FR 一并落地？集中做一次？），以及**是否需要一条集中的键命名规范**（`ERR_*` 之外的前缀分区）。

**② 内容条目自己的多语言表达形态。** 08-12d 已用**四问判据**划清 UI 文案 ↔ 内容文案的边界（`ux/_index.md`）：卡面描述、事件正文、跨档叙事、Finale 补白**属内容层**，走 `res://content/` + overlay，**不进 `res://text/` 翻译表**。但那条判据只回答了「不走哪里」，没回答「走什么」——**内容条目出英文版时，同一个 `Id` 的条目内部怎么承载两种语言，尚无定案。**

卡住了什么：`res://text/` 的目录形态已落 `system-overview.md`，但没有第二批键、没有命名规则，第一份 UI FR 一落地就得现场拍板；而 `XxxData` 的展示字段当前形态是裸 `string`（`systems/common-properties.md`「展示字段的归属」），一旦有 `.tres` 写出来再改就从「改类型定义」变成「改全部内容资产」。

## 约束（来自既有设计）

| 约束 | 来源 |
|---|---|
| 全库 UI 文案走 `TranslationServer` 翻译键；中文为默认与优先制作列，英文列全部占位符 | `ux/_index.md`、`ux/error-and-blocking-ux.md`「翻译资源」节 |
| `text/` **不是内容层**：随包分发，不走 overlay / flags 热更；不进抽取池、不被存档引用、无 `Id` | `system-overview.md` 第二节末 |
| 四问判据：有 `Id` 且被按 `Id` 引用 / 进 ContentRegistry 强校验 / 被存档引用 / 需线上可改不发版 —— 皆是 → 内容层；皆否 → 翻译键 | `ux/_index.md`（08-12d） |
| overlay **只改不增**（剧本内容是唯一例外，且新增条目不得引用本次 overlay 之外的新 `Id`） | `systems/services/content-service.md`「热更范围」 |
| 合并后强校验：`Id` 唯一性 + 交叉引用不悬空 → `PushError` 启动期早失败；disabled 条目照常参与 | 同上 |
| `XxxData : Resource` 是 ContentRegistry 里的**共享只读单例**，运行时任何服务都不得写它 | `systems/common-properties.md`「物化模型」 |
| 静态展示文本留在 `XxxData` 上；运行时 / 存档态只带 `Id` + 可变状态，不复制展示文本 | `systems/common-properties.md`「展示字段的归属」 |
| 显示字符串与 `Id` 分离，可改动 / 本地化而不破坏引用 | `systems/common-properties.md`「稳定 Id 键」 |
| 两种失败语义：必需缺失 → `PushError` + 退出；可选缺失 → `PushWarning` + 安全默认值 | `.claude/rules/null-check-rules.md` |
| 「纪律的可执行化」四级阶梯；「能上线且线上不可见」的纪律必须做到第 1 / 2 级 | `systems/architecture.md`、`content-service.md`「`AllEnabled()` 纪律的可执行化」 |
| 工程方法：垂直切片优先、平衡贯穿而非押末段；本地化打磨在 MVP 范围外（要的是「现在不做多语言，但现在就不能挡住多语言」） | `vision/scope.md` |
| 新增内容 = 新增 `.tres`，不改代码 / 不编辑 switch | `.claude/rules/data-resource-rules.md` |
| **语言范围封顶 = 中英双语**（`zh` / `en`）；短期 `en` 全占位符 | **本次裁决（08-13）** |

**一条已核实的事实（本草稿的最强推演支点）：** `game-feature-branch/` 当前**没有任何 `.tscn`、`.cs`、`.csproj`**——只有 `project.godot` 与 `icon.svg`。**UI 文案与内容资产的存量都是零。**

---

## 建议方案

### A. 翻译键的铺开节奏

#### A1 · 「逐屏改造」这个提法本身应被否掉：没有存量要改造 `[既有推演]`

待答项的原措辞（「逐屏改造如何排期」）默认了一个**存量迁移**的场景：先有一批写着中文字面量的屏，再逐屏换成键。**这个存量不存在**——上面已核实，客户端一个 `.tscn` / `.cs` 都还没有。

因此建议把问题重述并如此定案：**没有改造期，只有一条起手纪律——每个屏从写下第一行起就用翻译键，全库不新增任何 UI 文案字面量。** 这与 08-12 已经做过的同型判断完全一致：那次否决「先用 C# 常量表、待全局 i18n 决策时再迁」的理由正是「**晚迁没有任何收益，只多出一次改所有调用点的迁移**」。本条是同一条推理在**排期维度**的落点：连「先写字面量」这一步都不该发生。

**推论：「随各屏 FR 一并落地」与「集中做一次」不是二选一**——前者描述的是**纪律的作用方式**（每份 UI FR 天然带着它），后者要处理的批量迁移根本不会产生。

#### A2 · 唯一需要集中做的是一次性基建，它是第一份 UI FR 的前置 `[既有推演]`

只有五件事必须在**第一份含 UI 文案的 FR 之前**一次做完，此后再不集中：

1. 建 `res://text/` 与首批分区 CSV（至少 `errors.csv` + `common.csv`）；
2. 在 `project.godot` 注册翻译资源，**设默认 locale = `zh`**（中文是默认语言，见既有定案）；
3. 落 `ErrorText`（`For` / `ToTranslationKey` / `AuditTranslations`，形态已定，见 `ux/error-and-blocking-ux.md`）；
4. 落键命名规范（下面 A3）与分区表；
5. 落一次可执行化手段（下面 A5）。

**建议它就是 `FR-ux-translation-foundation`**，不挂在任何一个屏下——它横切所有屏，挂在某个屏下会让第二个屏的 FR 依赖第一个屏的 FR，凭空造出一条与设计无关的构建顺序。这与「`ErrorText` 不放 `src/Core/`、放 UI 层」同一种归位思路：**按「它服务于谁」定位，而不是按「谁先用到它」。**

#### A3 · 需要一条集中的命名规范，但它只有三条 `[通行做法]` + `[既有推演]`

规范越长越没人遵守；下面三条足以覆盖已知的全部情形：

1. **全大写 + 下划线分词**（`SCREAMING_SNAKE_CASE`）。既有 `ERR_*` 已是此形态，不另立第二套。
2. **首段 = 分区前缀**，形如 `<PARTITION>_<CONTEXT>_<NAME>`，例：`COMBAT_BUTTON_END_TURN`、`LOGIN_TITLE`、`SYNC_STATUS_OFFLINE_PENDING`。
3. **一个分区 = 一个 CSV 文件**（`res://text/<partition>.csv`，文件名小写）。收益是分工与 diff：改战斗屏文案只动 `combat.csv`，不与别人在同一个巨型 CSV 上打架。

分区清单（**开放表，随屏幕落地增补，不是封闭枚举**）：

| 分区前缀 | 文件 | 覆盖 |
|---|---|---|
| `ERR_` | `errors.csv` | **机械生成，见 A4** |
| `COMMON_` | `common.csv` | 通用按钮 / 确认 / 取消 / 返回 / 数量单位 |
| `BOOT_` | `boot.csv` | BootstrapScreen、阻塞屏的非 `ERR_` 部分（按钮、诊断行标签） |
| `LOGIN_` | `login.csv` | LoginScreen、T&S、渠道登录 |
| `MENU_` | `menu.csv` | 主菜单、篇章切换、更新横幅 |
| `SYNC_` | `sync.csv` | 常驻同步指示、软阻塞模态、更新引导半屏 |
| `EVENT_` | `event.csv` | EventMenu、事件选项框架文案（**不含事件正文——那是内容层**） |
| `COMBAT_` | `combat.csv` | CombatScreen、出牌 / intent / 结算面板的框架文案 |
| `PROFILE_` | `profile.csv` | PlayerProfile / CharacterProfile 面板、图鉴族、成就 |
| `SETTINGS_` | `settings.csv` | 设置屏（含同步版本 `#N` 的标签） |

**边界必须写在规范里，否则分区表会被误用：** 分区划的是**界面**，不是**内容域**。`EVENT_` 装的是「选项框的按钮与标题」，事件正文一个字也不进——正文归内容层（四问判据）。这条不写清楚，第一个写事件屏的人就会把正文塞进 `event.csv`。

#### A4 · 承重禁令：`ERR_` 分区保留给机械变换，人不得手写 `ERR_` 开头的键 `[既有推演]`

`ERR_*` 与其余分区有一条**本质差别**：它的键**不是人取的**，是 `code → ERR_ + 全大写 + `.`→`_`` 机械变换的像（`ux/error-and-blocking-ux.md`）。若允许有人手写一个 `ERR_LOGIN_FAILED`，而后端某天新增 `code = "login.failed"`，两者会**撞进同一个键**——一条后端错误会静默显示成一句为别处写的文案。这类 bug 发版后才显形，且现场看不出异常。

故建议立为禁令并给出可执行形态：

- **`errors.csv` 的每一行都必须是某个已知 `code` 的像。** `ErrorText.AuditTranslations()`（已定案）当前只查「已知 `code` 缺不缺翻译」，**建议把它做成双向**：反向再扫一遍 `errors.csv`，出现无对应 `code` 的 `ERR_*` 行 → `PushWarning` 列出。成本同样是一个 `foreach`，把撞键挡在开发期。
- 非错误场景要表达失败（如「储物袋已满」这类**本地业务拒绝**，它没有后端 `code`）→ 走所属分区的普通键（`PROFILE_MAGICPACK_FULL`），**不占 `ERR_` 前缀**。

#### A5 · 可执行化：选阶梯第 2 级（启动期审计），不追第 1 级 `[取向选择]`

按「纪律的可执行化」的选级判据，「UI 层写了中文字面量」属于**能上线且线上不可见**——中文玩家完全看不出差别，只有做英文版时才整片暴露。该档必须做到第 1 / 2 级。

- **第 1 级（最短路径即正确）在这里代价过高。** 要让「写字面量」在语言层不可能，得禁止 UI 代码直接触碰 `Label.Text` / `Button.Text`，包一层只吃键的 setter。这会与 Godot 的**编辑器内直接编辑 `text` 属性**这一最自然的工作方式对着干，且 `.tscn` 里的字面量它一条也挡不住。
- **建议取第 2 级：一个开发期审计。** 扫 `res://scenes/**.tscn` 与 `res://src/UI/**.cs`，命中「文本属性 / 赋给 `.Text` 的字符串字面量**含 CJK 字符**」即列出。CJK 判据在本作特别可靠——键恒为 ASCII 大写，内容文案不经 UI 代码传递（UI 拿到的是 `Id`，正文由 ViewModel 向 ContentRegistry 取）。
- **落点建议放在启动期**（与 `ErrorText.AuditTranslations()`、`ContentRegistry` 的负向条目清单告警同处、同形、同为 `PushWarning`），而不是另开一条构建期工具链——`environment-rules.md` 明写本机验证走 Godot 编辑器运行、不假定额外工具在 PATH 上。

> **落地前需确认一次（不阻塞定案）：** Godot 对 `Control` 的文本属性有内置自动翻译（4.3 起为 `auto_translate_mode`）。若在 4.7 上确认默认即生效，则 `.tscn` 里把 `text` 直接写成键就够了，**UI 代码里连 `tr()` 都不必出现**；若不生效则显式 `tr()`。**两种情况下键的形态、分区表、审计手段完全相同**，故不作为前置依赖。

---

### B. 内容条目自己的多语言表达形态

#### B1 · 否决「每语言一套条目」（`card_xxx_zh` / `card_xxx_en`）`[既有推演]`

这是最容易随手采用的做法，但它同时撞三条既有纪律：

- **撞「只改不增」。** 加一门语言 = 新增 N 个 `Id` = 只能发版，且 overlay 永远补不上——恰好抹掉内容层相对 `res://text/` 的**唯一优势**。
- **撞抽取池。** `AllEnabled()` 会同时返回中英两份，抽卡 / 商店 / 奖励掷骰的池子凭空 ×语言数，每条内容的实际权重被语言数稀释。要修就得在取池处按 locale 过滤——那是**在产出侧新开一个过滤维度**，而 `content-service.md` 刚刚花了一整节把「产出侧只有 `AllEnabled()` 一个入口」这件事钉死。
- **撞存档。** 存档存的是 `Id`；玩家切一次语言，手上的卡全部悬空。

#### B2 · 否决「内容文案也塞进 `res://text/`，条目上只放翻译键」`[既有推演]`

08-12d 的四问判据已经判过这一条了（`ux/_index.md`：「叙事塞进 `res://text/` 会失去 `Id`、失去启动期校验、档位定义无从引用它、也失去热更」）。本草稿**不重开这个判断**，只补一句它当时没展开的推论：内容文案**必须能热更**（线上改一句卡面描述不发版），而 `res://text/` 已定案随包分发；把内容文案放进去等于给它判了「改一个字要过审核」——这正是当初把内容做成 overlay 层的全部理由。

#### B3 · 推荐形态：条目内嵌 `LocalizedText`，locale → 文本 `[既有推演]` + `[通行做法]`

**同一个 `Id`、同一个 `.tres`，多语言是那个条目内部的一个字段结构。**

```csharp
/// 一段可本地化的内容文本。内容层专用——UI 文案走 TranslationServer 翻译键，不用本类型。
[GlobalClass]
public partial class LocalizedText : Resource
{
    /// locale → 文本。键与 TranslationServer 的 locale 标识符同一套（zh / en）。
    [Export] public Godot.Collections.Dictionary<string, string> Entries { get; set; } = new();

    /// 按当前 locale 取；缺当前语言 → 静默回落默认语言 zh（见 B4 的失败语义）。
    public string Get();

    /// 指定 locale 取；缺失 → false，调用方降级。审计与图鉴统计用。
    public bool TryGet(string locale, out string text);
}
```

三条采纳理由，逐条对上既有纪律：

- **加一门语言 = 在 `.tres` 里加一个键，零代码改动。** 直接落在「新增内容 = 新增 / 编辑 `.tres`，不改 switch」这条纪律里。这也是**否决「每语言一个 `[Export]` 字段」**（`DescriptionZh` / `DescriptionEn`）的理由：那种写法把「加一门语言」变成「改 C# 类 + 发版」，语言数直接焊死在代码里。
- **它是「改既有条目的字段值」，因此 overlay 可以热更它。** 完全落在「只改不增」内——**线上补一段英文文案不必发版**。这是本形态相对所有替代方案的实质收益。
- **给出唯一解析入口。** 与 `ContentRegistry` 作为「全游戏唯一内容读取入口」、`AllEnabled()` 作为「产出侧唯一取池入口」同一种偏好：语言回落逻辑只写一处，校验与审计只需遍历这一个类型。

**两条配套纪律：**

- **`Get()` 必须是纯读，绝不把解析结果写回 `XxxData` 或 `LocalizedText`。** `XxxData` 是 ContentRegistry 里的共享只读单例（`systems/common-properties.md`「物化模型」），缓存写回会污染注册表。需要缓存就缓存在 **ViewModel** 上——那正是「组合展示由 UI 层 ViewModel 按需组装、不落存档」那一层的职责。
- **`LocalizedText` 不落存档、不进上行负载。** 它是内容定义的属性；存档与云端负载照旧只带 `Id`（「运行时 / 存档态只带 `Id` + 可变状态，不复制展示文本」）。**不 bump schema，无迁移。**

#### B4 · 失败语义：默认语言缺失 → `PushError`；非默认语言缺失 → 静默回落 + 启动期一次性审计 `[既有推演]`

这是 `null-check-rules.md` 两种语义在本处的直接落点，但**方向必须分开**，否则英文占位符阶段会被警告刷屏：

| 情形 | 语义 | 处置 |
|---|---|---|
| **默认语言（`zh`）条目缺失** | 必需缺失——一条没有正文的内容就是坏数据 | 合并后强校验中 `GD.PushError` + `Id` + 字段名，**启动期早失败**（与 `Rarity` 缺失 → `PushError` 同档） |
| **非默认语言缺失** | 可选缺失——降级完全可用 | **读取侧静默回落 `zh`，不逐次警告**；改由**合并后一次性审计**汇总：当前 locale 下缺失的条目数与前 N 个 `Id`，一条 `PushWarning` |

- **为什么读取侧必须静默：** 既定的英文列「**全部预设占位符**」意味着**每一条内容**在 `en` 下都会命中回落。逐次 `PushWarning` = 每帧刷屏的日志噪音，还会把真正的告警淹掉。
- **为什么审计要有：** 「告警要落在能被看见的地方」——这正是 `content-service.md` 为负向能力条目清单告警写下的判据，本条是它的第三个同形实例（前两个：`AuditTranslations()`、负向条目清单）。
- **审计输出建议同时报覆盖率**（`en: 12 / 840 条目已翻译`），使「英文版做到哪一步了」成为一个能一眼读到的数，而不必人工点数。

#### B5 · locale 标识符两层共用，语言开关只有一个 `[既有推演]`

`res://text/` 的 CSV 语言**列名**、`LocalizedText.Entries` 的**键**、`TranslationServer.GetLocale()` 的**返回值**——**三者必须是同一套 locale 标识符**。

**已裁决（08-13）：取值域封闭为 `zh` / `en` 两个，不带地区码。** 中长期语言范围就是中英双语，不预留第三门语言的结构。**推论——不设繁体分列**：若日后确需繁体，正确做法是**简繁转换**（同一套 `zh` 文本经转换呈现），而非在 `Entries` 里再开一个 `zh_TW` 键——那会让每条内容文案凭空多一份需要同步的真值，而简繁之间的差异是机械的。这与本库反复用过的判据同源：**能机械变换的绝不建第二张手写表**（`code → ERR_*` 那条正是它）。

`LocalizedText.Get()` **就读 `TranslationServer.GetLocale()`**，不另设一个内容语言设置。否则设置屏会长出两个语言开关，玩家能把界面切成英文而卡面留在中文——一个没有任何人想要、但只要留两个入口就必然出现的状态。

#### B6 · 切语言后的重绘：UI 自动、内容不自动，需一条纪律 `[通行做法]`

一条真实的不对称，必须写下来否则一定会踩：`TranslationServer` 的 locale 变化会让走翻译键的 `Control` 自动重翻（Godot 会下发翻译变更通知），但 `LocalizedText` **不经 `TranslationServer`**，已经组装好的 ViewModel 里那串中文不会自己变。

建议纪律：**ViewModel 层订阅翻译变更通知，收到即重新组装一次**（它本就是「按需组装、不落存档」的那一层，重建成本就是重取一次 `Id` 对应的内容）。同样地，**语言切换后需要重进当前屏**的做法也可接受，但那是更粗的手段，建议只作为兜底。

#### B7 · 现在改是零成本，晚改是改全部内容资产 `[既有推演]`

`XxxData` 的展示字段当前在文档里是裸 `string`（`systems/common-properties.md`「展示字段的归属」：静态展示文本留在 `XxxData` 上）。换成 `LocalizedText` 是一次**类型变更**，影响面 = 全部 `XxxData` 类 + 全部 `.tres` + 全部 UI 读取点。

**当前这三者的存量都是零**（已核实：无 `.cs`、无 `.tres`、无 `.tscn`）。这与 08-12c 标识符单数收口时用的论证同构——**「无线上账号、无对应代码 ⇒ 最便宜的改到位窗口」**——而本处的窗口更紧：它会在**第二阶段（内容）写下第一批 `.tres` 的那一刻关闭**，此后每多一条内容就多一份要改的资产。

**已裁决（08-13）：与 `DrawPool<T>` 同批，第二阶段开工前、第一份内容 FR 之前落地。** 理由完全相同（纯加法窗口，一旦内容写完就退化为「改全部调用方 / 全部资产」），两者也天然是同一次 `XxxData` 面的改动。

#### B8 · 双语封顶的三条推论（08-13 追加）`[既有推演]`

「中长期只做中英双语」把上面几处的开放度收窄，值得单独记：

- **`Entries` 的键域是封闭的二值 `zh` / `en`。** 因此**合并后强校验可以更严**：出现 `zh` / `en` 之外的键 → `PushWarning`（拼错 locale 是一个真实且静默的失败面——`En` 或 `en_US` 会让整条文案在英文下回落中文，且没有任何症状）。若语言域是开放的，这条校验根本无从写起。
- **体积翻倍是一个封闭的上限，不是一条增长曲线。** 这消掉了「全语言内嵌 vs 按语言分包」（裁决 ①）里唯一的实质顾虑——最坏情况就是 ×2 且到此为止。**「按语言分包」因此不只是暂不采用，而是可以不再作为候选保留。**
- **`en` 的「占位符」在两层的形态不必相同。** CSV 侧的占位符形态归 `deferred-content.md` 的待答项；但 `LocalizedText` 侧最自然的占位形态是**该 locale 干脆没有这个键**（`Entries` 只有 `zh`），由 B4 的静默回落承接。**建议内容层就取这一形态**——它让「缺 `en` 键」= 「未翻译」成为一个干净可判的条件，B4 的覆盖率审计因此不需要第二套「什么算占位符」的识别规则。

---

## 具体形态（可 derive 的落地面）

### 翻译键侧

| 项 | 形态 |
|---|---|
| 目录 | `res://text/<partition>.csv`（小写文件名），Godot CSV → `.translation` |
| CSV 列 | `key, zh, en`（**两列封顶**；`zh` 为默认与优先制作列，`en` 全占位符） |
| 键形态 | `<PARTITION>_<CONTEXT>_<NAME>`，`SCREAMING_SNAKE_CASE`，恒 ASCII |
| 分区表 | 见 A3（开放表，随屏幕增补） |
| `ERR_` 分区 | **只装 `code` 的机械像**；人工键一律进所属分区 |
| 默认 locale | `zh`，在 `project.godot` 设定 |
| 审计 ① | `ErrorText.AuditTranslations()` **双向**：已知 `code` 缺条目 → `PushWarning`；`errors.csv` 中无对应 `code` 的 `ERR_*` 行 → `PushWarning` |
| 审计 ② | 启动期扫 `.tscn` / UI `.cs` 的文本字面量，含 CJK → `PushWarning` 列出（阶梯第 2 级） |
| 基建 FR | `FR-ux-translation-foundation`，横切、不挂任何单屏，为一切含 UI 文案的 FR 的 `depends-on` |

### 内容多语言侧

| 项 | 形态 |
|---|---|
| 类型 | `[GlobalClass] partial class LocalizedText : Resource` |
| 字段 | `Entries: Godot.Collections.Dictionary<string, string>`（locale → 文本） |
| locale 取值域 | **封闭二值 `zh` / `en`**，无地区码；出现其余键 → 合并后 `PushWarning`（拼错 locale 是静默失败面）。不设 `zh_TW`，繁体走简繁转换 |
| `en` 的占位形态 | **缺键**（`Entries` 只有 `zh`），由静默回落承接；「缺 `en` 键 = 未翻译」即覆盖率审计的判据 |
| 方法 | `string Get()`（按 `TranslationServer.GetLocale()`，缺则静默回落 `zh`）· `bool TryGet(string locale, out string text)` |
| 挂载面 | 一切面向玩家的内容文本字段：`CardData` / `AdventureEventData` / `ItemData` / `EnemyData` / `PowerData` 的**显示名 · 描述 · 风味文案**；`HiddenStatBandData` 的档位叙事条目；Finale 补白；AdventurePlot 的剧本正文与分支文本 |
| **不挂载** | `Id`、任何数值、任何枚举、`ContentEnabled` / `Rarity` / `ExclusiveSource` 等结构字段 |
| 校验（合并后） | 默认语言缺失 / 空串 → `GD.PushError` + `Id` + 字段名 + `throw`（走 `AllIncludingDisabled()`，**disabled 条目照常参与**） |
| 审计（合并后） | 当前 locale 的缺失条目数 + 覆盖率 + 前 N 个 `Id` → 一条 `GD.PushWarning` |
| 热更 | 走 overlay（改既有条目字段值，落在「只改不增」内）；**新增语言键不构成新增 `Id`** |
| 存档 | **不落存档、不进上行负载**；不 bump schema，无迁移 |
| 抽取池 | **零影响**——一条内容仍是一个 `Id`、一个池成员，权重不被语言数稀释 |
| 排期 | **已裁决**：与 `DrawPool<T>` 同批，**第二阶段开工前、第一份内容 FR 之前** |

### 一句话对照（建议补进 `ux/_index.md` 的四问判据小节）

> 四问皆否 → **翻译键**（`res://text/`，随包，`TranslationServer` 解析，改一句要发版）；四问皆是 → **内容层**（`res://content/` + overlay，条目内 `LocalizedText`，同样由 `TranslationServer.GetLocale()` 选语言，**改一句可热更**）。**两层不同载体、不同热更权限，但共用同一个语言开关。**

---

## 后果

- **`systems/common-properties.md`**「展示字段的归属」需改写：静态展示文本仍留在 `XxxData` 上，但**类型从 `string` 改为 `LocalizedText`**；同时新增一条「内容文本的多语言形态」小节。
- **`systems/services/content-service.md`** 需增：合并后强校验新增一条（默认语言缺失 → `PushError`）、新增一条加载期审计（当前 locale 覆盖率）、并明确 `LocalizedText` 的 overlay 热更权限。
- **`ux/error-and-blocking-ux.md`** 需增：键命名规范三条 + 分区表 + `ERR_` 禁令 + `AuditTranslations()` 改为双向。
- **`ux/_index.md`** 的四问判据小节补上「尚无定案的交叉点」那句的答案（上面的一句话对照），并删去「尚无定案」的措辞。
- **`system-overview.md`** 的目录树需把 `text/` 一行展开为分区清单。
- **存档 schema：不变，不 bump，无迁移。** 存档只带 `Id`，两侧改动都不触碰它。
- **抽取 / 校验 / flags / overlay 事务模型：全部原样成立**，无一条需要放宽。
- **包体：** 内容文本体积在英文补齐后近似 ×2，**且封顶于此**（双语封顶 + 全语言内嵌，见 B8）。这**不与** `04-hidden-attributes-plot.md` / `plot-manager.md` 的既有待答项「剧本内容的体积与分发粒度」合流——那条问的是**剧本树本身该不该按篇章分包**，语言维度已在此答定为不分包，两者可各自独立决定。

## 备选方案（已考虑并否决）

- **每语言一套条目 `Id`**（`card_xxx_zh` / `card_xxx_en`）— 撞「只改不增」、污染抽取池权重、切语言使存档引用悬空。见 B1。
- **按语言分包下载** — 08-13 裁决为全语言内嵌；双语封顶后体积上限固定为 ×2，分包的唯一实质动机消失，**不再作为候选保留**。见 B8。
- **`zh_TW` 作为 `Entries` 的第三个键** — 简繁差异是机械的，应走转换而非第二份手写真值。见 B5。
- **内容文案也进 `res://text/`，条目上只放翻译键** — 08-12d 四问判据已判；且它会把内容文案从可热更降级为要发版。见 B2。
- **每语言一个 `[Export]` 字段**（`DescriptionZh` / `DescriptionEn`）— 把语言数焊进 C# 类，加一门语言 = 改代码 + 发版，撞「新增内容不改代码」。见 B3。
- **先写中文字面量、日后集中迁移** — 与 08-12 否决「先用 C# 常量表再迁」同一条理由：晚迁零收益，只多一次全量改调用点。见 A1。
- **把「禁止 UI 字面量」做到阶梯第 1 级**（禁止直接触碰 `.Text`）— 与 Godot 编辑器最自然的工作方式对抗，且挡不住 `.tscn` 里的字面量。见 A5。
- **内容语言与界面语言各自一个设置项** — 制造一个没人想要但必然出现的混合态。见 B5。

## 与既有决策的张力

**一处，且是澄清而非冲突。**

`vision/scope.md` 明写「本地化打磨（让展示字符串与 id 分离，以免日后受阻）」在 **MVP 范围之外**。本方案的 B 部分要求在**第二阶段开工前**就把 `XxxData` 的文本字段改成 `LocalizedText`——看起来像是把范围外的事提前做了。

**判断：不构成冲突，理由与 08-12 定案时用过的同一条**——那条软约束要的是「现在不做多语言，但现在就不能挡住多语言」，而它括号里自己写明的落法正是「**让展示字符串与 id 分离**」。`LocalizedText` 做的就是这件事的完整形态，且**不产出一个字的英文文案**（`Entries` 里只有 `zh` 一个键也完全合法且是默认状态）。真正的本地化打磨——英文措辞、字体、排版回流、地区定价——仍在 MVP 之外。

**但代价要如实记：** 写 `.tres` 时每个文本字段多一层嵌套 SubResource，内容编写的手感变差一点。若认为这个手感成本在中文单语阶段不值得，替代路径是「先裸 `string`，加英文时再改」——**本草稿明确不推荐**（那正是 B7 说的窗口关闭后的高成本路径），但它是一个真实的选项，列在下方供裁决。

## 前置依赖

- **英文占位符的具体形态**（键名本身 / `TODO` / 机翻初稿）——在 `open-questions/deferred-content.md`，属文案定稿，**范围仅剩 `res://text/` 的 CSV 一侧**：内容层一侧已由 B8 答定为「缺键即未翻译」。**不阻塞本方案**，但那条定下来时须回看 B4 的覆盖率审计——若 CSV 侧的占位符取键名本身，`AuditTranslations()` 就得能识别它，否则英文覆盖率恒读作 100%。
- **Godot 4.7 上 `Control` 自动翻译的默认行为** —— 不阻塞（A5 已说明两种情况下形态相同），但落地第一份 UI FR 时需实测一次，与 `05-service-contracts.md` 的 `#if DEBUG` 实测项同类，宜合并到同一次 `.csproj` 生成后的实测。

**已解除的依赖：** 「剧本内容的体积与分发粒度」不再是本方案的前置——语言维度已答定为不分包，那条待答项回归它原本的问题（剧本树该不该按篇章分包），两者互不牵动。

## 已裁决（2026-08-13）

**① 全语言内嵌 vs 按语言分包 → 全语言内嵌。** 每个 `.tres` 带全部语言，零新增机制、切语言零延迟、overlay 通道不新增维度。配合双语封顶，包体上限固定为 ×2（B8）。**「按语言分包」不再作为候选保留。**

**② `LocalizedText` 的落地时机 → 现在上**（第二阶段开工前、第一份内容 FR 之前，与 `DrawPool<T>` 同批）。接受的代价：中文单语阶段编写 `.tres` 时每个文本字段多一层嵌套。

**③ 分区表粒度 → 按屏 10 个**（A3 的表原样采用，开放增补）。

**④ 追加约束：语言范围封顶为中英双语（`zh` / `en`），短期 `en` 全占位符。** 三条推论见 B8：`Entries` 键域封闭 ⇒ 可加一条 locale 拼写校验（`PushWarning`）· 体积 ×2 是封闭上限 ⇒ 分包动机消失 · 内容层的「占位符」= **缺键**，由静默回落承接。另见 B5：**不设 `zh_TW` 分列，繁体走简繁转换。**

> 以上四项连同正文全部建议构成本草稿的定案内容，可直接作为 `/analyze-new-ideas` 的输入。

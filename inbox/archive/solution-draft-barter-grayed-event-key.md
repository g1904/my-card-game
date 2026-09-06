---
type: solution-draft
date: 2026-09-05
question: barter（以物易物）格灰显时点按给出的 `EVENT_` 说明键，在灰态判据的权威文档（ux/error-and-blocking-ux.md）里零承接——判据表无 barter 行、键清单无 barter 键
source: open-questions.md 索引「本次新识别的台账 / 投影缺口」→ barter 灰显的 `EVENT_` 说明键在权威文档零承接
targets: ux/error-and-blocking-ux.md（「灰态判据」小节的判据表 + 其下的说明文案键清单一行）
status: distilled
reviewed: 2026-09-05 · 批量评审 —— 「是否一并补『Exchange 商店买不起 → 灰显』那一行」取选项 A（一并补，零新增键）
distilled-to: handoffs/2026-09-05-barter-grayed-state-keys.md
---

# 方案草稿 — barter 灰态在灰态判据表与键清单里的补位

## 问题

`ADR-0126`（Exchange 支付侧二选一：货币，或一件点名的轮回级法宝）的呈现侧只落笔了一半：

- **已落笔**：`ux/screen-flow.md`「Exchange（交易）屏」写明「不持有支付物 → 灰显，支付要求保持可见，点按给一条说明『你需要 <某物>』的提示（走 `EVENT_` 普通分区的翻译键，不占 `ERR_` 前缀）」；`systems/adventure-event/exchange/_index.md` 写明同一句并注「灰态判据见 `ux/error-and-blocking-ux.md`」。
- **零承接**：而灰态的**权威**在 `ux/error-and-blocking-ux.md`「灰态判据」小节——那里的判据表只有四行（事件选项付不起 `selectCost` / 礼包购买入口 / 有购买待兑现时的「开始新轮回」/ Exchange 刷新按钮），**没有 barter 行**；其下那条列举说明文案键的要点也只列了 `STORE_UNAVAILABLE_*` · `MENU_` · `EVENT_REROLL_UNAVAILABLE_POOL`，**没有 barter 键**。

后果有两层：① 按该表自陈的判据（「必然无结果的操作」）barter 明确属于表内情形，缺行使这张**本应可穷举**的表不再穷举；② `/derive-requirements` 第 2 步要写「点按给一条说明」这条验收标准时，**该键无处可查**——`exchange/_index.md` 把它回链到了一份并不持有它的文档。

本草稿建议的是**一次补位落笔**，不改任何已定判据、不新增机制：把 barter 行补进判据表，并把它的键补进键清单。

## 约束（来自既有设计）

- **判据不容重议，只是补一行。** 「灰态禁令适用于『玩家可能有意选择的失败』，不适用于『必然无结果的操作』」——`ux/error-and-blocking-ux.md`「灰态判据」。
- **`ADR-0126` 已定三条呈现纪律，本草稿一字不动：** 不持有支付物 → **灰显**而非不呈现（判据「恒真 vs 可变」）· **支付要求保持可见** · **不按持有面过滤呈现**（否则同一个 `EventOption` 在两次进入之间呈现不同内容，与「产出即定稿、恢复即读结果」正面冲突）。
- **灰显的驱动来源已定为门面级只读 `bool Holds(AbilityCarrierKind kind, AbilityScope scope, string abilityId)`**，与货币格的 `CanAfford` 各管一半（`systems/services/profile-service.md` 门面表）。**不扩 `CanAfford`**，barter 失败**不复用 `ApplyResult.MissingElement`**（它是 `CostKey`，装不下 `AbilityId`；「差哪一样」由格上恒可见的支付要求承载）。
- **键命名规范三条**（`error-and-blocking-ux.md`「键命名规范」）：`SCREAMING_SNAKE_CASE` 恒 ASCII · `<PARTITION>_<CONTEXT>_<NAME>` · 一个分区一个 CSV。
- **`ERR_` 禁令**：本地业务拒绝没有后端 `code`，一律走所属分区的普通键，**不占 `ERR_` 前缀**；`EVENT_` 分区只装事件界面的**框架文案**，**事件正文与条目名一个字也不进**（内容层 `LocalizedText`，`ux/_index.md` 四问）。
- **无 hover-only 可供性**（`.claude/rules/ui-input-rules.md`）；最小触控目标尺寸照既有下限。
- **第二条 barter 灰态已在库内明写、但同样无键**：`exchange/common-properties.md` 的运行期失败表——「barter 产出目标已持有（能力族）→ 可选缺失 + `PushWarning` + 空操作 —— barter 不经取池 ⇒ **没有『已排除已持有』这一层，故 UI 侧须同样灰显**」。任何补位方案若只处理「不持有支付物」，补完这张表**仍然缺一格**。

## 建议方案

### 1. 判据表补一行（含两条触发条件，不是一条）

`[既有推演]` 依据：`ADR-0126` 理由段「不持有支付物 → 灰显而非不呈现」+ `exchange/common-properties.md:182` 的「UI 侧须同样灰显」+ 判据表自陈的准入判据。

建议在「灰态判据」表的 **Exchange 刷新按钮行之后**追加一行（列结构与现表逐列对齐，三列）：

| 情形 | 呈现 | 判据 |
|---|---|---|
| **Exchange 的 barter 格：不持有 `PayItemId`，或产出目标已持有（能力族）** | **置灰 + 支付要求（支付物图标 + 名称）保持可见 + 点按一行说明**，不隐藏、**不按持有面过滤呈现** | 换不成的格子点下去只会撞上一个**必然被门面前置拒绝**的提交（`Holds(...) == false` → `ApplyResult.Fail`），没有任何决策价值。**与「买不起 → 灰显但价格保持可见」逐字同构**，同出于「恒真 vs 可变」：是否持有某件法宝是**可变**状态（可在轮回内买到、由事件产出、或已持有后被卖掉），故落在灰显一侧，而非储物袋「古宝无售出键」那种恒真不可用（`decisions/ADR-0126-exchange-barter-payment.md`；产出侧那条见 `systems/adventure-event/exchange/common-properties.md` 运行期失败表） |

**建议写成一行而不是两行。** 两条触发条件的呈现、判据、驱动源（都只读 `Holds(...)`）、说明通道完全相同，差别只在说明句；分成两行会让这张已经在长的表把「同一个格子的同一种状态」记两遍，而现表既有的写法（礼包入口一行吃掉四条前置）正是同一处理。逐条的键仍分开给（见下）。

### 2. 键：两个 `EVENT_` 普通键，与既有四个灰态说明键同形

`[通行做法]` + `[既有推演]`：形态取自库内**全部四个**既有灰态说明键的共同像 `<分区>_<CONTEXT>_UNAVAILABLE_<原因>`（`STORE_UNAVAILABLE_POOL` / `_SYNC` / `_PENDING`、`EVENT_REROLL_UNAVAILABLE_POOL`），逐条核过键命名规范三条。

| 触发条件 | 建议键 | 分区 / 文件 | 说明句（示意，措辞待文案定稿） |
|---|---|---|---|
| 不持有 `PayItemId` | **`EVENT_BARTER_UNAVAILABLE_NOT_HELD`** | `EVENT_` / `event.csv` | 「你需要「%s」。」 |
| 产出目标已持有（能力族） | **`EVENT_BARTER_UNAVAILABLE_ALREADY_OWNED`** | `EVENT_` / `event.csv` | 「你已拥有「%s」。」 |

- **`<CONTEXT>` 取 `BARTER`**：分区划的是**界面**，`BARTER` 指的是 Exchange 屏内的 barter 格这一界面元素，与 `REROLL` 指刷新按钮同一层级；**不取 `EXCHANGE`**（`EVENT_` 分区已隐含事件界面，再嵌一层事件类型名会让 `EVENT_EXCHANGE_*` 与 `EVENT_REROLL_*` 两种深度并存）。
- **`ERR_` 反向审计不受影响**：它只扫 `ERR_` 分区，`EVENT_*` 从不进入判据面。
- **两个键都只承载框架句**；支付物 / 产出物的**名称是内容层 `LocalizedText`**（`ItemData` 等条目的显示名），由呈现层以**格式参数**插入，绝不写进 `event.csv`（`ux/_index.md` 四问：有 `Id`、被按 `Id` 引用、进 ContentRegistry 强校验、需热更 ⇒ 四问皆是）。CSV 行形如 `EVENT_BARTER_UNAVAILABLE_NOT_HELD,"你需要「%s」",`——**`en` 列留空**（未翻译的既定形态），不写哨兵值、不复制 `zh` 原文。

### 3. 说明通道 = 点按就地提示；灰格必须仍然接收触控

`[既有推演]`：`screen-flow.md` 与 `exchange/_index.md` 两处均已写「**点按**给一条说明」，图鉴屏灰格「点按给一条『尚未收录』提示（`PROFILE_CODEX_LOCKED`），触控等价、非 hover」是同款先例。

- **通道：点按该格 → 就地行内提示**（不开屏、不加弹层，与 Exchange 屏「不新开屏、不新增弹层」的既定克制一致）。**不取长按**：长按在本作已是「查看详情 / 复制诊断编号」的语汇（储物袋、阻塞屏底部编号），把说明挂上去会与详情手势打架。**不取常驻标签**：支付要求本就常驻可见，再常驻一句「你需要 X」会在每个未满足的格子上重复一遍同样的话。
- **零 hover 通道**：说明的全部信息在触控端可达（点按），且支付要求（图标 + 名称）恒常驻——`.claude/rules/ui-input-rules.md`「没有仅悬停的可供性」满足。
- **⚠ 落地纪律（值得写进文档一句）：灰态是视觉降级，不是禁用。** 灰格**必须继续接收触控**，否则「点按给一条说明」这条纪律在实现上会被一个 `Button.Disabled = true` 静默取消（Godot 的 disabled 控件不发 `pressed`，且症状是「点了没反应」——一种线上不可见的失败）。形态建议：降低饱和度 / 透明度表达不可用，触控接收位与可用格完全一致，触控目标尺寸不缩水。同一条对既有的「买不起则灰显」格与 Exchange 刷新按钮同样成立。

### 4. 「支付要求保持可见、不按持有面过滤呈现」在呈现上如何兑现

`[既有推演]`：`ADR-0126` 备选方案已明确否决「按 `Holds` 结果决定 barter 格是否呈现」。

建议把它写成**一句可机械检查的落地纪律**：

> **`Holds(...)` 的返回值只能驱动一格的「灰 / 亮」这一位布尔，不得出现在任何 filter / sort / count 表达式里。** barter 格列表的**唯一输入**是 `EventOption.BarterStock`（物化时定稿、随存档恢复）：格数、次序、每格的支付物与产出物**只读它**；`Holds(...)` 参与的只有该格的可用位与点按时取哪一个说明键。

- 由此「同一个 `EventOption` 在两次进入之间呈现相同内容」是**结构上成立**的，而不是靠实现者记得。
- **重算时机：** 开屏组装一次 + **本屏内每笔交易提交后重算一次**（购买 / 售出 / barter 都可能改变持有面），**不进 `_Process`**——与图鉴屏 ViewModel「随屏出生随屏消亡、开屏组装一次、订阅变更重组装」同款（`systems/viewmodel.md` 的结构契约不受本方案影响，本方案不新增字段、不新增事件）。
- **`SoldOut`（换出后保留占位并标「已换」）与本条正交**：它是**已定稿的存档态**、恒可见，不由 `Holds(...)` 驱动；本方案不动它。

### 5. 附带发现（**不在本条范围内**，仅提请一并处置）

`[既有推演]`，但**属相邻缺口**，建议由用户决定是否同批落笔（见「仍需用户决定」）：

- **「Exchange 商店买不起 → 灰显但价格保持可见」这一行，在同一张判据表里同样缺席。** 本条 barter 行自陈「与它逐字同构」，而被同构的那一行并不在表内——补完 barter 行后，表内会出现一个引用不到的对照物。它的说明文案由 `ApplyResult.MissingElement` **机械映射**（`screen-flow.md`），故它需要的不是一个新键、而是**表内一行 + 一句「说明由 `MissingElement` 机械映射到币种，不手写第二张表」**。
- **「已换」/「已售」占位标签**同样是 `EVENT_` 分区的普通键、库内亦未落名（`EVENT_BARTER_TRADED` / `EVENT_OFFER_SOLD_OUT` 是自然形态）。它们**不是灰态说明**、不进判据表，宜在 Exchange 屏的 FR 落地时随屏补齐，本草稿不建议在灰态小节里落它们。

## 具体形态（可 derive 的落地面）

**改动面仅一份文档、两处：**

1. `ux/error-and-blocking-ux.md`「灰态判据」判据表 → 追加上文第 1 节那一行（三列）。
2. 同小节表下第三条要点（列举说明文案键的那一条）→ 键清单追加：`Exchange barter 格 → EVENT_BARTER_UNAVAILABLE_NOT_HELD / EVENT_BARTER_UNAVAILABLE_ALREADY_OWNED`，仍在「**不占 `ERR_` 前缀**——本地业务拒绝，没有后端 `code`」的同一句里。

**新增翻译键（`res://text/event.csv`，两行）：**

| 键 | `zh`（示意，措辞待文案定稿） | `en` |
|---|---|---|
| `EVENT_BARTER_UNAVAILABLE_NOT_HELD` | `你需要「%s」。` | （留空） |
| `EVENT_BARTER_UNAVAILABLE_ALREADY_OWNED` | `你已拥有「%s」。` | （留空） |

**零增量的面（防止 derive 时被误改）：** `Holds(...)` 签名与语义不动 · `CanAfford` 不动 · `ApplyResult` 不新增字段 · `BarterOffer` / `ExchangeBarterRule` 字段面不动 · 存档 schema 与 `schemaVersion` 不动 · `ERR_` 分区与三条审计不动 · 分区表不新增分区 · 后端零配合。

**验收标准形态（供 derive 直接消费）：** 在 Godot 编辑器里进入一个含 barter 格的 Exchange 事件 → ① 不持有支付物时该格灰显、支付物图标与名称仍可读、点按弹出 `EVENT_BARTER_UNAVAILABLE_NOT_HELD` 的文案且带上支付物名；② 在同店买到该支付物后回到网格，该格转为可用（格数与次序不变）；③ 产出目标为已持有的能力条目时该格灰显并给 `EVENT_BARTER_UNAVAILABLE_ALREADY_OWNED`；④ 全程无任何 `ERR_*` 键出现在屏上。

## 后果

- **文档面：** 只改 `ux/error-and-blocking-ux.md` 一处小节；`screen-flow.md` 与 `exchange/_index.md` 的既有回链（「灰态判据见 …」）在补位后**才真正落到实处**，两处措辞一字不必改（它们不复述键名，不构成第二权威）。
- **需求面：** `/derive-requirements` 处理 Exchange 屏与 `FR-ux-translation-foundation` 时，该键从「无处可查」变为可指。
- **不需要迁移**：无存档字段、无契约、无内容条目受影响。
- **判据表增长一行**，仍满足「可穷举、可机械核对」的初衷；本方案不为它松动任何准入判据。

## 备选方案（已考虑并否决）

- **键取 `EVENT_BARTER_REQUIRES_ITEM`** — 否决：读起来更顺，但打破了库内四个既有灰态说明键共同的 `UNAVAILABLE_<原因>` 像；第二条触发条件（产出目标已持有）也无法用 `REQUIRES_` 表达，一处形态两套命名比一句略生硬的中译更贵。
- **键取 `EVENT_EXCHANGE_BARTER_*`** — 否决：`EVENT_` 分区已隐含事件界面，再嵌事件类型名会与 `EVENT_REROLL_*` 形成两种嵌套深度。
- **复用 `EVENT_REROLL_UNAVAILABLE_POOL` 一类的通用「不可用」键** — 否决：说明句要点名「你需要哪一样」，通用句把这条信息删掉，等于把玩家推回去猜。
- **判据表拆成两行（不持有 / 已持有各一行）** — 否决：呈现、判据、驱动源、通道四项全同，只有说明句不同；逐条键已在键清单里分开给。
- **不改判据表，只在 `screen-flow.md` 就地补键名** — 否决：灰态判据与其键清单的权威已定在 `error-and-blocking-ux.md`，在别处补即制造第二权威，正是本条要修的那种漂移的成因。
- **按 `Holds` 结果过滤掉不可换的格** — 否决：`ADR-0126` 已明确否决（同一 `EventOption` 两次进入呈现不同内容）。本条只作记录，不重议。

## 与既有决策的张力

**无。** 本方案不松动任何既定判据，只把 `ADR-0126` 与 `exchange/common-properties.md` 已定的呈现结论投影到灰态判据的权威文档里。唯一新增的一句约束（灰格必须继续接收触控）是对既有「点按给一条说明」的**实现侧兑现条件**，不改变任何决定。

## 前置依赖

- **无阻塞项。** 两个键的**实际中文措辞**待文案定稿——与 `error-and-blocking-ux.md` 待决区既有的「四条兜底文案与各 `ERR_*` 的实际措辞」同属**内容充实，不阻塞结构落地**。
- 落地时序上依赖 `FR-ux-translation-foundation`（`res://text/` 与首批分区 CSV 的一次性基建）——这是**一切含 UI 文案的 FR 的既定 `depends-on`**，非本条特有。

## 仍需用户决定

- **是否在同一次落笔中一并补上「Exchange 商店买不起 → 灰显」那一行（判据表内同样缺席）。**
  - **选项 A（推荐）· 一并补。** 后果：本条 barter 行自陈的「与买不起逐字同构」在表内有了对照物，表恢复穷举；改动增量为一行 + 一句「说明由 `ApplyResult.MissingElement` 机械映射到币种，不手写第二张表」，**零新增键**。
  - **选项 B · 只补 barter，另立一条待答项跟踪买不起那一行。** 后果：本次改动面最小、严格贴合分派范围；代价是同一处漂移分两次修，且中间态下 barter 行引用了一个表内不存在的对照物。
  - **推荐 A**，理由：两行是同一处漂移的两半（`ADR-0126` 的「逐字同构」措辞本身就假定了对方在表内），成本一行且不新增任何键；分两次修的唯一收益是范围洁癖，而本批另有 worker 触及同一份文档的键分区表，合并落笔反而少一次并发写入。**此项属范围问题，不是设计取向**——若用户希望严守分片边界，选 B 无任何设计损失。
  - → **已裁决（2026-09-05 · 批量评审）：选项 A —— 一并补上「买不起 → 灰显」那一行**（增量 = 一行 + 一句机械映射说明，零新增键）。

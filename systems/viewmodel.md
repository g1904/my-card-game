# viewmodel

> 展示层三层切分（数据 / 运行时·存档 / **ViewModel**）中第三层的结构契约。
> 三层的**定义**在 `systems/architecture.md`「展示层契约」；本文件持有第三层的完整展开——依赖方向、组装源、重组装触发面、只读消费与缓存归属、永不渲染清单。

## 意图

### 它是什么，不是什么

**ViewModel 是「服务 → 屏幕」的数据形态契约**：位于 services / 核心「类」与屏幕场景之间，把 `Data + 运行时状态` 组装成一屏当下要显示的东西。

- **它是呈现期对象**——随屏出生、随屏消亡，**不落存档、不进云端负载**。存档与上行负载照旧只带 `Id` + 可变状态。
- **它不是一个并行的展示模型。** 静态展示文本仍留在 `XxxData` 上，运行时 / 存档态仍只带 `Id` + 可变状态；ViewModel 只做**组合**，不持有第二份真值。
- **它不是服务的一部分。** 它是屏幕侧的组装产物，服务不知道它存在。

### 依赖方向：单向，且服务不返回 ViewModel

- **单向依赖**：ViewModel 读 `XxxData` 与运行时状态，**不被服务反向依赖**。
- **服务的 API 面永不返回 ViewModel。** 服务返回的是核心「类」、快照或 `OpResult`；一旦服务返回屏幕形态的对象，服务层就被绑死在某一屏的布局上，换一屏要改服务。
- **它不参与存档 / 同步。** 判据：一个字段若需要跨启动存在，它属运行时 / 存档层，不属这一层。

### 组装源三件套

| 源 | 提供什么 | 取自 |
|---|---|---|
| `XxxData`（`.tres`） | 静态展示文本（显示名 / 描述 / 图标）与玩法数值 | ContentRegistry，**按 `Id` 取** |
| 运行态实例 | 当前的可变状态（层数、剩余次数、已揭示与否） | 持有它的服务 / CycleState |
| 服务快照 | 整场信息的只读视图（如 combat-service 组装的 `CombatSnapshot`） | 对应服务，**只读、不落存档** |

**内容正文由 ViewModel 向 ContentRegistry 按 `Id` 取，不经 UI 代码传递。** 这条同时是 UI 文案字面量审计的前提——UI 代码里拿到的恒是 `Id` 与翻译键，故「赋给 `.Text` 的字面量含 CJK」可以直接判为违规（判据见 `ux/error-and-blocking-ux.md`）。

### 重组装的触发面

**ViewModel 是被动的：它不订阅玩法状态，只在被明确告知「你手上这份过期了」时重组装一次。**

- **翻译变更通知。** 切语言后存在一条真实的不对称：走翻译键的 `Control` 会自动重翻，但内容层的 `LocalizedText` **不经 `TranslationServer`**，已组装好的 ViewModel 里那串中文不会自己变。纪律：**ViewModel 层订阅翻译变更通知，收到即重新组装一次**（重建成本就是重取一次 `Id` 对应的内容）。「重进当前屏」是可接受但更粗的兜底。
  - **为什么必须写下来：** 漏掉它的症状是「切语言后卡面文字不变」——中文玩家完全看不出差别，只有做英文版时才整片暴露，属「能上线且线上不可见」那一档。`LocalizedText` 的形态与 locale 归一见 `systems/common-properties.md`「内容文本的多语言形态」与 `ux/error-and-blocking-ux.md`「语言开关只有一个」。
- **capability 变更通知。** 收到空负载的变更广播后**自查一次**当前屏依赖的 capability，而不是从广播负载里读值（形态见 `systems/services/profile-service.md`）。
- **EventBus 的既成事实广播。** ViewModel 只消费「已经发生了什么」，**不据此改写任何服务状态**（负载纪律见 `systems/architecture.md` 总则 5）。

### 只读消费纪律

ViewModel 是这些纪律的**消费侧落点**，定义各在其权威文档，此处只登记「这一层要遵守什么」：

- **对 `EventOption` 定稿实例只读**：不得回查模板重算、不得改写其字段（`systems/adventure-event/common-properties.md` · `systems/services/future-event-service.md`）。
- **遮罩期不读被遮罩的字段**：`IsRevealed == false` 时不读 `RevealedEventId` / `DestinationLocationId`（`systems/adventure-event/explore/_index.md`）。
- **快照只读**：`CombatSnapshot` 一类的服务快照不写回、不落存档（`systems/services/combat-service.md`）。

### 缓存归属

**`LocalizedText.Get()` 的解析结果只能缓存在 ViewModel 上，绝不写回 `XxxData` 或 `LocalizedText`。** `XxxData` 是 ContentRegistry 里的共享只读单例，写回即污染注册表（权威见 `systems/common-properties.md`）。ViewModel 是唯一一层「本来就会随屏丢弃」的对象，缓存放在它身上无需失效策略——换屏即失效，切语言即整份重组装。

### 视觉资产的占位回落

**内容条目的 `Artwork` 为 `null` 时的占位回落只写一处：由本层统一提供 `res://art/_placeholder.png`。** 各屏不各自准备一张占位图——那与「回落逻辑只写一处」（`LocalizedText.Get()` 是同一种偏好）相抵，且会让「哪些屏还没接占位」成为一个只能靠人肉巡检的问题。

- 该 `.png` 文件本身归 `game-feature-branch/`，本库只登记这条约定。
- `Artwork` 可空是常态（美术挂点先占位、末段替换），缺失的机械发现归加载期的收口汇总，**不由本层告警**；字段定义与告警形态见 `systems/common-properties.md`。
- **角色形象的回落是两级，占位入口仍只有一处。** 组装角色形象时：① 取 `CharacterData.RealmArtworks` 中 `Realm == CharacterProfile.realm` 的那一条 → ② 无匹配则取共有字段 `CharacterData.Artwork`（基础图）→ ③ 仍为 `null` 则取上面那张唯一的占位资产。**没有当前轮回时（角色选择屏 / 图鉴 / 主菜单等无 `CharacterProfile` 的场合）跳过第 ① 级，直接取基础图。** 字段形态与三条加载期校验见 `systems/character-profile/_index.md`。

### 永不渲染清单

- **`OpResult.Detail` 永不赋给任何 `Label.Text`。** 它是诊断串（`code` + `requestId` + 后端 `message`），玩家可见文案一律经 `ErrorText.For(code, reasonKey, error)`。**可机械检查**：UI 层不出现该赋值写法（`systems/architecture.md` 总则 7 · `ux/error-and-blocking-ux.md`）。
- **诊断编号只读一次、不进玩法路径。** 阻塞屏 / 错误模态底部的 `#requestId` 与设置屏的同步版本 `#N` 都是**诊断展示**，ViewModel 读一次交给标签，不参与任何判断（`ux/error-and-blocking-ux.md`「诊断编号的玩家出口」）。

### 为什么它单列一份文档，而不是留在 `architecture.md` 的一节里

- **它是这批纪律的最小公共祖先。** 上述各条的消费面横跨内容层、事件层、战斗层、同步层与错误呈现层，没有任何一份既有主题文档能容纳全部；按「定义在最小公共祖先、投影在各落点」，它们的公共祖先就是「ViewModel 层」本身。
- **它服务于全部屏 × 全部服务**，不属任何单屏——按「按它服务于谁定位，而不是按谁先用到它」，它既不该塞进 `ux/` 的某一屏文档，也不该寄居在 `architecture.md` 的一节里（那一节由 API 契约总则占满，落地纪律进不去）。
- **它的权威在结构一侧，不在措辞一侧。** 上述各条回答的是依赖方向、生命周期、只读性、缓存归属、重组装时机，**没有一条在回答「怎么说」**——故归 `systems/`，不归 `ux/`（`ux/` 已自我限定为「怎么说、说在哪、说几次」）。
- **先例同向：** 非服务的横切件里，`game-progression` 因有自己的机制面而单列顶层文件，EventBus 因全部内容就是一条 API 契约总则而留在总则表内。判据是「它的内容是不是一条 API 契约总则」；本层的纪律绝大多数是跨屏的落地纪律，形态上属前者。

Source: `handoffs/2026-08-19-architecture-structural-residuals.md` · `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md` · `handoffs/2026-08-30-realm-progression-artwork-basis.md`

## 决策(-> ADR)
> _已敲定的决定链接到 decisions/ADR-####。_

- **展示层三层切分（Data / 运行时·存档 / ViewModel）** → `decisions/ADR-0010-presentation-three-layer-split.md`（Accepted）。**本文件是它的主落点**；`systems/architecture.md`「展示层契约」保留三层的定义段。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

> _（当前无未决项。）_

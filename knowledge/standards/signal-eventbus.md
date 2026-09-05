# 标准 —— 信号与 EventBus（引用层）

`.claude/rules/csharp-godot-rules.md`（信号章节）的配套。**权威：`game-design-documents/systems/architecture.md`**「总则 5」与「EventBus 负载契约」——**事件清单、负载 schema、`Emit` 代码形状去那边看**，此处不复制。

## 何时用什么

| 场合 | 用什么 |
|------|--------|
| 父级驱动自身子级、场景内紧耦合 node | **直接方法调用**（默认） |
| 跨服务、需要返回值 | **直接方法调用** `Xxx.Instance.Method(...)` |
| 子级通知其父 / 所有者，不知道谁在听（`Card` 发 `Played`） | **局部 `[Signal]`**，限场景边界内 |
| 跨系统、跨场景的**既成事实**广播 | **EventBus autoload** |

## 承重纪律

1. **EventBus 用 C# 泛型 `event` + `readonly record struct` 负载，不用 Godot `[Signal]`**——`[Signal]` 的自定义负载须继承 `GodotObject`，每次广播都分配 + 装箱，而核心循环与战斗内每步都在广播。EventBus 本身仍是 autoload `Node`（留在场景树里、可做泄漏检查）。→ `systems/architecture.md`「总则 5」
2. **负载只带 `Id` + 值类型**——绝不带 `CharacterProfile` / `Resource` / `EventOption` 引用（那等于给每个订阅者开一条绕过唯一写入入口的旁路）。需要完整实例的订阅者按 `InstanceId` 去 future-event-service 取。→ `systems/architecture.md`「EventBus 负载契约」
3. **`_Ready` 订阅、`_ExitTree` 退订。** C# 事件上漏退订**不会报错**，直接变成泄漏（且让已释放的 node 被回调）。兜底是 EventBus 的 `#if DEBUG` 订阅审计（切屏后由 game-progression 触发一次，豁免 autoload 订阅）——**它只在开发期生效，不替代退订**。
4. **广播 = 既成事实，不可否决。** EventBus 不承载「请求 / 询问」；需要返回值的一律是直接方法调用。
5. **事件命名为过去时的事实**：`CycleStarted`、`EventResolved`、`CapabilitiesChanged`。命名为事实而非指令，正是这条纪律的体现。**完整事件清单与负载见权威，别在此复制。**
6. **空负载 + 订阅者自查是通用形态，不是能力标记的特例。** `CapabilitiesChanged` 空负载、订阅者自行 `Has(flag)` 重查；同构实例还有 `PendingCount` 与 `UpgradeRequired`（**明确不为它新增 `SyncState` 值**，改为服务上加只读属性由 UI 单点查询）。把生效集塞进负载即制造第二份真值。→ `systems/services/sync-service.md`
7. **战斗呈现事件是一条 `CombatFeedEntry` 流**（卡牌结算 / 触发式异能 / 疲劳 / fizzle 四类共用），**已取代 `CardResolved`——后者不再存在，两者并存的方案被明确否决**。条目自带 `EntryId` / `CauseEntryId` 构成因果树、**不落存档**；三个消费者（飘字 · 战报收起态 · 展开态因果树）读同一条流，不各自组装。**存结构化数据、渲染期才套翻译键**，绝不存已格式化字符串。→ `decisions/ADR-0087-action-result-and-combat-feed.md`

**代价（已接受）：** GDScript 与编辑器信号面板订阅不了 EventBus——本项目纯 C#，不构成损失。

## 陷阱

- **顺序：** 不要假设订阅者的执行顺序。若顺序重要（PlayerPower 触发优先级），显式建模成一份解析出的优先级列表，而不是依赖订阅顺序。
- **反馈回路：** 一个发射同一事件的处理器会递归。在效果可链式触发处（power 响应 power）防范重入。
- **泄漏：** 见纪律 3。兜底是 `#if DEBUG` 订阅审计，**订阅侧无需登记来源、`+=` 惯用形态原样保留**。→ `systems/architecture.md`「纪律的可执行化」

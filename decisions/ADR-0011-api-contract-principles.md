# ADR-0011 — API 契约总则（八条，贯穿七个服务）

- **状态：** Accepted
- **日期：** 2026-07-27
- **来源：** handoffs/2026-07-27b-service-api-contracts.md

## 背景

七个服务各自写 API 面，如果没有全局总则，同一件事会长出七种形状：有的返回 `Task` 有的不返回、有的抛异常有的返回错误码、有的把内部可变集合直接交出去。而 Godot autoload 的 `_Ready` 不能 `await`，「声明顺序 = 依赖顺序」只解决装配顺序、不解决初始化顺序——启动期的异步 I/O 无处安放。

## 决策

**八条总则，各服务文档的「API 面（契约）」小节在其约束下书写：**

1. **三种方法形态，按「它跨什么边界」决定**，不允许混用：**A · 同步直返**（纯内存 / 纯本地事务）· **B · `Task<OpResult<T>>`**（跨客户端 ↔ 后端边界）· **C · `Task<T>` 由信号推进**（跨多帧的玩法长流程）。**形态 B / C 一律带 `Async` 后缀，A 一律不带。**
2. **失败语义三分**，与 null-check 规则一一对应：必需缺失 → `PushError` + `throw`；可选缺失 → `bool TryXxx(out T)` + `PushWarning`；**业务失败 → 返回 `OpResult` / `ApplyResult`，绝不抛**。结果对象一律 `readonly record struct`（零堆分配）。
3. **服务门面的固定骨架**：`static Instance` + `private` manager 字段 + 只暴露方法的 API 面；manager 类型 `internal sealed`；服务间只经 `Xxx.Instance.Method(...)`；**服务不返回内部可变集合**（一律 `IReadOnlyList<T>` / `IReadOnlyDictionary<,>`）。
4. **启动契约：`_Ready` 只装配，`InitializeAsync` 才做 I/O。** 引入 `IBootstrappable` 与 **Bootstrap 屏幕场景**驱动异步初始化，顺序为 `ContentService.InitializeAsync → LoginScreen → AccountService.SignInAsync → ContentService.RefreshFlagsAsync → SyncService.InitializeAsync → ProfileService.Hydrate → MainMenu`。
5. **EventBus 用 C# 泛型事件 + `readonly record struct` 负载**（不用 Godot `[Signal]`）；订阅方 `_Ready` 订阅、`_ExitTree` 退订。
6. **物化模型**（模板 → 唯一物化点 → 定稿实例）—— 单列，见 `decisions/ADR-0012-materialization-model.md`。
7. **后端接口化：三个边界服务各持一个可替换后端**（`IAccountBackend` / `IContentBackend` / `IProfileBackend`），每个两份实现（`HttpXxx` / `OfflineXxx`），**唯一选择点 `BackendSelector`**。
8. **结算阶段名**：`eventStart` / `eventEnd` 是 `AdvanceEventAsync` 内部结算流程的两个阶段名，**不是 `AdventureEventData` 上的方法**；落地为按 `eventType` 注册的 `IEventResolver`（共 2 个实现）。

配套：**后端错误码 → `OpError` 是一张数据表而非 switch**，三条承重纪律（不靠 HTTP 状态码分支 · 不解析 `message` 做分支 · `message` 不进玩家可见弹窗）。逐条全文与共享核心类型见 `systems/architecture.md`「API 契约总则」。

## 理由

- **看签名即知它是否跨边界**：`Async` 后缀承担这一件事，故形态与后缀绑定。形态 A 引入 `Task` 只会给每次查询加一次状态机分配。
- **网络失败是常态而非异常**，故跨边界一律 `OpResult` 而非异常；`Task` 让离线 stub 变成一行 `Task.FromResult`，也让超时 / 取消 / 重试有统一挂点。
- **Godot `[Signal]` 传自定义负载要求负载继承 `GodotObject`** ⇒ 每次广播都分配一个引用对象并经 `Variant` 装箱，直接撞上「层与层之间不做隐式装箱」与「热路径不分配」——而 `EventResolved` / `CardResolved` 正在核心循环与战斗热路径上。
- **`BackendSelector` 唯一选择点**：每个服务各持一个开关字段 = 若干个可能各自出错的点，最糟的失败态是「开了一部分没开另一部分」的**半在线状态**，它比全离线更难诊断。收敛成一个选择点后，这个失败态在结构上不存在。
- **错误码用数据表而非 switch**，与「新增内容 = 新增数据，不编辑 switch」的可加性纪律一致。

## 备选方案

- **一律返回 `Task`（含纯内存查询）** — 否决：每次查询一次状态机分配，且签名不再能区分是否跨边界。
- **业务失败用异常** — 否决：网络不通、token 失效是预期内的拒绝，用异常表达会让每个调用点都要 try/catch。
- **EventBus 用 Godot `[Signal]`** — 否决：负载装箱与堆分配撞热路径纪律。代价（GDScript 与编辑器信号面板订阅不了）在纯 C# 项目里不构成损失。
- **三个服务各持一个离线开关** — 否决：半在线态。
- **事件自带 `eventStart` / `eventEnd` 钩子** — 否决：结算流程的编排权应归 `AdvanceEventAsync`，事件不自带钩子。

## 后果

- 约束了七份服务文档的「API 面（契约）」小节形态：统一四列表（方法 | 形态 | 完整签名 | 失败语义），形状依赖未答问题的写 `⟨待定：链接⟩`，不留空白也不臆造。
- 条件编译的使用清单被钉为穷举的 **5 处**（`BackendSelector` · 三个 `Offline*Backend` · EventBus 审计块），服务与 manager 内部一律不得出现 `#if`；商业化落地时有一次已预告的、有边界的扩张（5 → 6）。
- 三个后端接口是客户端 ↔ 后端**协议契约的客户端一侧投影**；本库只定调用形状，报文字段的权威在 `backend-design-documents/contracts/`。
- 影响文档：`systems/architecture.md`（权威）· `systems/services/*.md`（七份的 API 面）· `system-overview.md` 第四节 · `ux/error-and-blocking-ux.md`（`code` → 文案表）。

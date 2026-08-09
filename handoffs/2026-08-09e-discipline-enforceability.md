# 纪律的可执行化：四级阶梯 + 三条约定各自落到机器可强制的形态

- id: 2026-08-09e-discipline-enforceability
- date: 2026-08-09
- topic: systems/architecture, system-overview, systems/services/content-service, systems/common-properties, .claude/rules/data-resource-rules
- status: distilled
- distilled-to: systems/architecture.md, system-overview.md, systems/services/content-service.md, systems/common-properties.md, .claude/rules/data-resource-rules.md, open-questions.md, open-questions/（05-service-contracts.md, update-log.md）, answer-logs/log-discipline-enforceability.md

## Intent（distilled）

**一句话：** `open-questions/05-service-contracts.md` 里三条独立列着的「靠约定执行」的工程纪律——离线后端开关不上线、抽取必走 `AllEnabled()`、EventBus 订阅必退订——其实是**同一个问题的三个实例**：*正确的写法需要作者主动记得，错误的写法既不报错也不显眼*。本次先立一条**统一的选级判据（四级阶梯）**，再用它把三条各自压到该压的那一级：前两条压到**语言层**（类型不存在 / 方法名不存在），第三条停在**开发期大声失败**。连带修掉一处技术上不成立的既有表述（`[Export] bool UseOfflineBackend`）。

### 0 · 纪律可执行化阶梯（新判据，与八条 API 契约总则同层）

> **一条纪律该做到哪一级，取决于「违反它的代价」。**

| 级 | 手段 | 违反时 | 成本 |
|----|------|--------|------|
| **1 · 写不出来** | 类型 / 可见性 / 命名——错误的写法在语言层不存在或不合法 | 不可能发生 | 设计期一次性 |
| **2 · 编译不过** | `[Obsolete(error: true)]`、`#if` 条件编译、分析器 | 编译期报错 | 低～中 |
| **3 · 大声失败** | 启动期断言、切屏 / 退出期审计（一律 `#if DEBUG`） | 开发期 `PushError` | 低，但只在开发期生效 |
| **4 · 评审清单** | 文档条款 + 人工评审 | 靠人 | 零成本、零保证 |

**两条选级判据：**

- **能上线且线上不可见 → 必须做到第 1 或第 2 级。** 判据是「违反后测试期能不能被发现」。`UseOfflineBackend` 与 `AllEnabled()` 都属于「违反后游戏照常运行、错误只在真实玩家身上显形」，**第 3 级不够**。
- **只在开发期显形、且违反后会累积 → 第 3 级足够。** EventBus 泄漏属此类：不改变玩法结果，只吃内存并制造幽灵订阅者。

这条阶梯是把本库已有的三处实践（`internal sealed` manager、`Async` 后缀、两条唯一入口）归纳成的**显式判据**——它的价值在于日后再出现「这条约定怎么强制」时不必逐条重新讨论。**落在 `systems/architecture.md`**（不落 `.claude/rules/`）：它约束的是设计库里写下的契约形态（接口签名、开关形态），权威在设计侧。

### 1 · `UseOfflineBackend`：单一选择点 + 条件编译删类

**先修一处技术互斥。** `system-overview.md` 第三节写「autoload 可直接指向 `.cs`，无需为每个服务建空 `.tscn`」，第四节又写开关是服务上的 `[Export] bool UseOfflineBackend`、「开发期切换不需要重编译」。**这两条互斥**：autoload 指向 `.cs` 时 Godot 直接实例化脚本，**不存在场景实例，`[Export]` 没有存储处、检视器里也无从编辑**——运行时永远拿到默认值 `true`。这个开关不但发布期无防护，开发期也不好用。

**裁决：松动「`[Export]`」，保留「autoload 直接指向 `.cs`」。** 理由：`[Export]` 的价值是「设计师在检视器里调数值」，而这个开关的读者是工程师。连带**「autoload 直接指向 `.cs`，不为服务建空 `.tscn`」升为无例外约定**——七个服务的 autoload 形态统一，不再有「为承载配置而建空场景」这条后门。**推论：日后任何服务级配置项都走 ProjectSettings，不走 `[Export]`；`[Export]` 保留给真正的场景组件（卡牌、敌人、UI 控件）。**

落地形态四件：

1. **唯一选择点 `BackendSelector`（第 1 级）。** 四个服务不各自持开关，改由 `src/Core/BackendSelector.cs` 的 `CreateAccount()` / `CreateContent()` / `CreateProfile()` / `CreatePlot()` 产出实现。**理由：四个字段 = 四个可能各自出错的点，最糟的失败态是「三个开了一个没开」的半在线状态**——它比全离线更难诊断（登录成功、内容加载正常，只有存档静默写进内存回显）。收敛成一个点后这个失败态在结构上不存在。这与 ContentRegistry / ProfileManager / future-event-service 三处「唯一入口」同源。
2. **主闸：四个 `OfflineXxxBackend` 整类包 `#if DEBUG`（第 1 级）。** Release 构建里离线实现**根本不存在**，问题从「开关会不会配错」降级为「类型存不存在」——配错连编译都不通过。
3. **开发期开关载体：ProjectSettings 自定义项 `mycardgame/backend/use_offline_backend`（第 3 级兜底）。** 值落在 `project.godot`，**进版本控制、可 diff、可在评审中看见**；Godot 原生支持 feature tag override（`....release`），即「按导出预设维度覆盖」的原生实现。
4. **启动期审计（第 3 级）。** BootstrapScreen 在驱动 `InitializeAsync` 前打一行必然位于日志顶部的横幅，并在 `!OS.IsDebugBuild() && IsOffline` 时 `PushError` + `throw`。若第 2 件生效，这个 `throw` 恒不可达——**保留它是为了防「条件编译常量哪天被改错」**，成本一行。

**条件编译使用清单（穷举，不得扩张）：** `BackendSelector.cs`、四个 `Offline*Backend.cs`、`EventBus.cs` 的审计块，**共 6 处**。服务与 manager 内部一律不得出现 `#if`——总则 7「换实现而非插 `if`」在条件编译上同样成立。

### 2 · `AllEnabled()`：删掉中性诱饵名 `All()`

**核心动作是删除 `All()` 本身，而不是给它改名。** 漏写过滤的发生机制是「随手写了那个最短、最中性、看起来最无害的名字」。只要 `All()` 还在，它就是诱饵；两个名字都带修饰语时，作者**必须在两种语义之间做一次显式选择**——写下 `AllIncludingDisabled()` 的人不可能声称没意识到有 disabled 条目这回事。

- **`AllEnabled()`** —— 抽取池，`ContentEnabled == true`，产出侧唯一取池入口。
- **`AllIncludingDisabled()`** —— 全量，用于启动期强校验 / 图鉴统计 / 调试。**合并后强校验正是它的第一个正当调用方**（disabled 条目照常参与 `Id` 唯一性与交叉引用校验），这使「两个显式名」不是多余的对称。
- **过渡期硬闸（第 2 级）：** 保留一个 `[Obsolete(error: true)] All()` 占位，恒抛。任何出于惯性写下 `All()` 的代码（**包括 AI 生成的**）当场编译失败并被指路。保留至少到内容阶段结束。

**`DrawPool<T>`（第 1 级）已采纳，排到第二阶段（内容）开工前落地。** 2a + 2b 让漏写过滤极难，但仍未做到不可能：`Where(...)` 或 `AllIncludingDisabled()` 的结果照样能被拿去抽取。终局形态是把 `AllEnabled()` 的返回类型换成 `readonly struct DrawPool<T>`，并**只在其上定义 seeded 抽取方法**（`PickOne` / `PickMany` / `Filter`），于是「从内容集合抽取」在语言层只能从抽取池发起。排期依据：彼时三个抽取侧（future-event-service 物化、商店库存、奖励掷骰）都已有真实调用方，能验证形状是否够用；此刻定死形状是纸上设计。**落点必须在第二阶段第一份内容 FR 之前**——一旦三个抽取侧写完再改返回类型，就从「纯加法」退化为「改调用方」。

### 3 · EventBus 退订：`#if DEBUG` 订阅审计（第 3 级）

按第 0 节判据定级为第 3 级：漏退订不改变玩法结果（幽灵订阅者收到的是既成事实广播，不可否决），只吃内存并可能对已 `QueueFree` 的节点调方法，**开发期即可显形**。这与总则 5 已埋的「EventBus 仍是 autoload `Node`，可做泄漏检查」一致，本次只补形态。

- **判据：** 遍历 `event` 的 `GetInvocationList()`，`d.Target is GodotObject go && !GodotObject.IsInstanceValid(go)` 即泄漏。
- **定位信息取自 `d.Method`，不取自 `d.Target`。** 泄漏发生时目标实例已释放，`Target.ToString()` 无用；`Method.DeclaringType.Name + "." + Method.Name` 是反射元数据，**不依赖实例存活**，直接给出 `CombatScreen.OnCardResolved` 这样可定位的名字。**因此不需要在订阅时额外登记来源，`+=` 的惯用订阅形态原样保留。**
- **触发时机 = 每次屏幕切换完成后**，由编排顶点 game-progression 调一次。屏幕场景是订阅者的绝大多数，切屏正是它们被释放的边界；频率 = 每次切屏一次，**零热路径成本**。
- **否决「每次 `Emit` 顺带检查」**：`GetInvocationList()` 每次分配数组，`CardResolved` 在战斗热路径上，直接撞「热路径不分配」。
- **`_ExitTree` 只打一条订阅计数摘要，不做泄漏判定**：此时七个 autoload 服务可能正在同步销毁，`IsInstanceValid` 会对它们误报。
- **推论（写进纪律）：泄漏检查豁免 autoload 服务的订阅**——服务与游戏同生命周期，它们的订阅按定义不是泄漏。用 `IsInstanceValid` 在切屏时机作判据天然满足这一点，这也是必须避开 `_ExitTree` 判定的原因。

### 落地成本

**三条改动全在客户端工程形态层：不影响存档 schema、不影响后端协议、不影响任何玩法语义。** 且 `game-feature-branch/` 目前只有 `project.godot` 与 `icon.svg`，**无一行存量 C# 需要迁移**——同样的改动放到内容阶段做，代价是改所有抽取侧调用方。

### 已否决的备选（保留理由供回溯）

- **`All()` 保留但语义改为 enabled-only。** 最短路径确实安全，但一个叫 `All` 却不返回全部的方法**会撒谎**——用错误的名字换安全，只是把 bug 挪到未来（写图鉴统计的人读到 `All()` 会以为拿到了全集）。
- **Roslyn 分析器强制 `AllEnabled()`。** 单独项目要维护、随 Godot 生成的 `.csproj` 走易被覆盖、无 CI 前提下只在本机构建生效；`[Obsolete(error: true)]` 拿到同一份编译期保证，成本低几个数量级。
- **导出预设 / 启动期断言作为 `UseOfflineBackend` 的唯一防护。** 前者是配置，会被漏配、被覆盖、被新建预设时忘记同步；后者只在**跑到那一步**时生效——而离线包的症状恰恰是「一切正常」。二者都只能是第 3 级兜底。
- **为四个边界服务各建一个空 `.tscn` 承载 `[Export]`。** 四个空场景纯为承载一个 bool，autoload 表变成 `.cs` / `.tscn` 混合形态，与「服务形态统一」相悖。
- **EventBus 改为 `Subscribe(...)` 返回 `IDisposable` + `SubscriptionBag`。** 会把 C# `event` 换成方法对，失去 `+=` / `-=` 的惯用性与编译器生成的线程安全访问器，收益仅是「少写一行 `-=`」。
- **`EventBusSubscriber` 自动退订基类。** C# 单继承，屏幕脚本已需继承 `Control` / `Node2D`，塞一个纪律基类会污染整条继承链。

## Open questions

- **`#if DEBUG` 判据需实测确认一次。** 前提是「Godot 的 .NET 集成在 Release 导出配置下不定义 `DEBUG`，编辑器内运行与 Debug 导出定义」。`game-feature-branch/` 当前**尚无 `.csproj`**，无从验证。若不成立，改用显式 `<DefineConstants>MYCARDGAME_OFFLINE_OK</DefineConstants>` 自定义常量，**方案形态不变**。
- **`ContentEnabled` 分桶粒度**（既有待决项，见 `systems/services/content-service.md`）：影响面**限于已排期到第二阶段的 `DrawPool<T>`**——若届时抽取池要按分桶裁剪，构造签名会变成 `AllEnabled(bucketContext)` 一类形态。`AllEnabled()` / `AllIncludingDisabled()` 的命名改造与 `Obsolete` 闸**不受此依赖影响，本阶段即定稿**。

## Notes / triage

来源：`inbox/solution-draft-discipline-enforceability.md`（`/provide-solution-draft` 产出，用户已于 2026-08-09 逐项裁决——四项取向选择与一处「与既有决策的张力」均已选定，草稿正文已按裁定改写）。本 handoff 未新增 ADR；第 0 节的阶梯若日后被反复引用，可作为 ADR 候选与「API 契约总则」并列。

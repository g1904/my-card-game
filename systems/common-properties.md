# common-properties（系统层共有属性）

> systems 顶层的**共有属性 / 约定**，分两大节：**`## 通用约定`**（所有系统文档共享的工程与结构约定）与 **`## 内容共有字段`**（具体的内容共有字段权威定义）。深层子树（adventure-event、enemies、character-profile / player-profile 的各叶子子树）另有各自的 `common-properties.md`；本文件是它们之上的**顶层共有层**。**一个共有属性写在哪一层的判据**见 `## 内容共有字段` 节首的判据卡。


## 通用约定

> _系统层所有「类」共享的工程与结构约定。保持更新。_ 本节条目不谈「挂载面」，也不产生投影段——判据卡只对 `## 内容共有字段` 成立。

### 稳定 Id 键
- 每个内容条目都有一个**稳定、唯一的字符串 `Id`**。Id 是其他一切引用的键（存档文件、注册表查找、跨系统交互）。**绝不用场景路径、数组索引或显示名作为内容的键。** Source: `.claude/rules/data-resource-rules.md`。
- 显示字符串（名称、描述）与 `Id` **分离**，可改动 / 本地化而不破坏引用。
- **`Id` 的字符集不含 `#` 与 `:`**（加载期校验，违规 → `PushError` + 报出 `Id` 与 `.tres` 路径）。这两个字符是**复合键的结构位**：`#` 已被战斗内 `counters` 键用作「异能 id / 子计数器名」的分隔符，`:` 保留为未来非异能键的命名空间前缀。把它们排除在 `Id` 之外，使任何以 `Id` 打头的复合键都能无歧义地切分，且日后开出 `:` 命名空间时与既有 id 天然不相交、无需迁移。条目 `Id` 的形态规范见 `content/_index.md`；`counters` 键的完整语法见 `systems/services/combat-service.md`。

### 字段命名与类型一致性
- 类、方法、属性、信号、导出字段用 `PascalCase`；私有字段 `_camelCase`；与 Godot C# API 大小写一致。Source: `.claude/rules/csharp-godot-rules.md`。
- **贯穿整条链路的类型一致性。** 参数 / 返回类型在 UI/输入 → 系统/管理器 → 数据资源（`.tres`）→ 存档模型 全流程对齐；层与层之间不做隐式装箱 / 转换。Source: `.claude/rules/Context.md`。
- 领域术语的中文 ↔ 英文 / 代码标识符权威在 `terminology.md`（例：修行事件 / AdventureEvent、角色信息 / CharacterProfile）。

### 数据即资源
- 每种内容类型是一个 `[GlobalClass] partial class XxxData : Resource`，带 `[Export]` 字段；实例以 `.tres` 编写，由 `content-service` 的 **ContentRegistry** 在启动时按 `Id` 索引。玩法代码经注册表的**泛型仓储接口**（`Get` / `TryGet` / `AllEnabled` / `AllIncludingDisabled` / `Where`）查找，不散落 `ResourceLoader.Load`。Source: `.claude/rules/data-resource-rules.md`。
- **内容分三层：** `res://content/` 基线（随包发布、只读）+ `user://overlay/` 云端热更增量（按 `Id` 覆盖）→ 合并进 ContentRegistry；**校验点在合并之后**（重复 / 悬空 `Id` → `GD.PushError` 启动期早失败）。详见 `systems/services/content-service.md`。
- **可调平衡数值不硬编码**，归 `systems/balance.md` 或导出字段（见 `data-resource-rules.md`）。

### 展示字段的归属
- 各「类」只携带编码（`Id` / 数值）。展示（充血）字段的归属**按生命周期切分三层**，而非为前端另建一套并行类：**静态展示文本**（显示名 / 描述 / 图标）留在 `XxxData : Resource` 上；**运行时 / 存档态**只带 `Id` + 可变状态，不复制展示文本；**组合展示**（数值代入、条件文案、随 capability flag 变化的可见性）由 UI 层轻量 **ViewModel** 按需组装，不落存档、不进云端负载。完整论证与待确认项见 `systems/architecture.md`。
- **第一层那些静态展示文本的类型是 `LocalizedText`，不是裸 `string`**——见 `## 内容共有字段`。

### 物化模型：内容定义 ↔ 运行时实例

- **凡「内容定义 + 情境 / 轮回内状态」的组合都是两个类型**，服务签名里**传实例，不传 `Resource`**：
  - `AdventureEventData` ↔ **`EventOption`** —— 由 future-event-service **物化（materialize）**产出，**产出即定稿（immutable）**，落存档；
  - `CardData` ↔ **`CardInstance`** —— 运行态**可变**（手牌中的临时增益）。
- **`XxxData : Resource` 是 ContentRegistry 里的共享只读单例，任何服务都不得在运行时写它**——写回会污染注册表，被同一轮回的后续批次与其他角色看到。
- 这与上方「展示字段的归属」三层切分同构：它把**第二层（运行时 / 存档态）的类型形态**明确了。物化模型的完整论证见 `systems/architecture.md`「总则 6」。

### Seeded RNG 派生（确定性）
- 每个轮回存储一个 **seed**；所有玩法随机性（地图 / location 生成、抽卡、商店库存、奖励掷骰、敌人行为）从该 seed 派生，最好通过具名子流（sub-stream）隔离，避免系统间 desync。**不用未加种子的 `GD.Randi()` / `Random` 决定玩法结果。**
- 在存档中持久化足够的 RNG 状态，使恢复的轮回能确定性继续。**持久化形态：**
  - **子流派生 `streamSeed = Hash64(CycleSeed, streamName)`**——子流 seed 可随时从 `CycleSeed` 重算，存档中存它**只为诊断与自校验**。
  - **`State`（u64）是恢复用的权威字段**：重建子流后回填 `RandomNumberGenerator.State`，**O(1)**，不必重放。
  - **`DrawCount`（int）是诊断与迁移保险**：`State` 是引擎实现细节，Godot 升级可能改变其语义；届时用 **`seed + drawCount` fast-forward 重放**恢复（一次轮回抽取数千次，重放成本可忽略）。冗余成本每流 4 字节。
  - **子流清单是 `SeedManager` 内的常量**（map / combat / shop / reward）。读档遇存档中没有的**新子流** → `GD.PushWarning` + 按 `Hash64(CycleSeed, name)` 全新初始化；遇清单里已不存在的**旧子流** → 警告并丢弃。**增删子流不 bump schema 版本。**
  - **战斗内随机直接用 `combat` 子流，不在其上再派生一层。** 「每场按 `(eventId, attemptIndex)` 再派生一次以防 re-roll」这条看似自然的加法**不要做**——它要防的两件事都已被别处从根上关掉：① 「退出重进重掷」由决策点存档 + RNG `State` 持久化关闭；② 篇章重试确实换一套战斗随机，但换法是**给这一次重试一套全新的随机流**，不是在既有流上叠派生。**因此没有 `attemptIndex` 这个字段**；篇章重试次数由 `CharacterProfile.chapterRetry` 承载（它是重试上限的计数器，与 RNG 无关，见 `systems/services/life-cycle-service.md`）。
  - 存档 schema 见 `systems/character-profile/_index.md`；派生方是 `life-cycle-service.SeedManager`。
- **账号级随机与轮回随机是两条不相交的线。** 判据：**结果写 `PlayerProfile` 的随机，绝不可从 `CycleSeed` 派生**——四条子流全由 `Hash64(CycleSeed, streamName)` 得出，而**篇章重试会生成全新的 `CycleSeed`**，把账号级掉落挂上去等于让玩家靠重试换一次结果。
  - **形态 = 具名域 + 单调序号（三参数派生），随机源是契约定义的纯函数 SplitMix64，不是 Godot 的 `RandomNumberGenerator`：**

    ```csharp
    enum AccountStream { PowerFragment = 0, PremiumBundle = 1 }   // 成就奖励无随机，不占域

    // 派生一次、连续抽多条；序列由 (stream, ordinal) 完全确定 ⇒ 幂等
    AccountRandom AccountRng.For(AccountStream stream, int ordinal);

    // 内部（uint64 环上运算，>> 为逻辑右移；两侧逐位一致）
    //   Mix(z): z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9
    //           z = (z ^ (z >> 27)) * 0x94D049BB133111EB
    //           return z ^ (z >> 31)
    //   GOLDEN = 0x9E3779B97F4A7C15
    //   state  = AccountSeed
    //   state  = Mix(state + GOLDEN * (ulong)((int)stream + 1))
    //   state  = Mix(state + GOLDEN * (ulong)(ordinal    + 1))
    ```

    ```csharp
    public interface IRandomSource { ulong NextU64(); }

    public sealed class AccountRandom : IRandomSource
    {
        public ulong NextU64();                       // state += GOLDEN; return Mix(state)
        public int   Roll();                          // (int)(NextU64() % 10000) —— 万分比，不做拒绝采样
    }

    // 轮回级随机走这个薄适配器，Godot RNG 本身不变
    public readonly struct GodotRandomSource : IRandomSource { public ulong NextU64(); }
    ```

    `AccountSeed` 是后端下发、落 `AccountInfo` 的 `ulong`（见 `systems/player-profile/account-info.md`）。**它不进 `SeedManager`、不进子流清单**，故不触及「增删子流不 bump schema 版本」那条纪律。
  - **为什么账号级不用 Godot 的 `RandomNumberGenerator`（承重）：** 跨语言逐位一致是**后端复算成立的前提**，把它押在引擎实现细节上，等于让「Godot 升级」成为一次静默的作弊窗口——这与本文件为 `RandomNumberGenerator.State` 写下的那条迁移警告同源。算法与测试向量的权威在 `backend-design-documents/contracts/profile-sync.md` §6 §6a；**实现后逐位对表**（8 组向量已填，无须等后端动手），**对不上时先复核实现、再复核表，不得单方面改表迁就实现**。
  - **轮回级 RNG 完全不受影响**——地图 / 战斗 / 商店 / 奖励四条子流继续用 Godot 的 `RandomNumberGenerator`，只有账号级掷骰跨边界。
  - **`AccountStream` 的成员序 `PowerFragment = 0` / `PremiumBundle = 1` 自此冻结，只能追加**——它是复算输入的一部分，与 `Source` 的「名与 code 双双永不复用」同一条纪律。
  - **`ordinal` 参数保持 `int`**（两个调用方 `FinaleWinOrdinal` / `BundleGrantOrdinal` 都是 `int`），`(ulong)` 转换在 `For` 内部做一次——链路类型一致优先，且负值在此为程序缺陷（必需缺失处置）。
  - **抽取链的参数类型是泛型约束的 `IRandomSource`**（`PickOne<TRng>(TRng rng, …) where TRng : IRandomSource`），使账号级掷骰与轮回级抽取共用同一段取池代码。**取泛型约束而非裸接口参数**：值类型经泛型特化调用，零装箱、零堆分配，落在既有热路径纪律内。落点见 `systems/services/content-service.md` 的 `DrawPool<T>` 契约与 `systems/services/profile-service.md` 的门面签名。
  - **为什么必须有具名域：** 若只按 `(AccountSeed, ordinal)` 两参数派生，各渠道的序号都从 `1` 起，于是**同一 `AccountSeed` + 同一整数 ⇒ 同一输出**——礼包的第 1 次授予与残卷的第 1 次胜利掷骰会共享同一随机数。两者消费方式不同、玩家不可感知，但这是一条没有理由留着的相关性，且渠道越多越难排查。**否决「给各渠道分配不相交的序号区间」**：效果相同但更脆（区间耗尽 / 新渠道加入需重新分配，且区间约定不可机械校验）。三参数逐级混入的**顺序也是契约的一部分**（先 `stream` 后 `ordinal`，各带 `+1` 的全零防御），写反即整条序列不同——测试向量里有一对专抓它。
  - **账号级授予一律用「本次」的序号掷骰（承重 · 两条渠道同款）：先算 `ordinal = 旧值 + 1`，用它掷骰，再把同一个值随同一次 `TryApply` 写回；绝不用自增前的旧值掷骰。**
    - **理由是一条会稳定误报的缺口，不是文风：** 后端拿到上行 profile 后，用**存档里的**序号（必然是自增后的值）复算 `roll'` 并要求它与 `LastRoll` 相等；客户端若用自增前的值掷骰，两侧永远对不上，而这条校验的用途正是抓种子篡改 / 序号刷 / 换设备重掷——它会在**每一个正常账号上**触发。复算口径见 `backend-design-documents/contracts/profile-sync.md` §7。
    - **序号自增与「是否抽中 / 是否发放」无关**：静默停摆时照常 `+1`，否则下一次复用同一 `ordinal`、掷出完全相同的序列，幂等键当场失效。
  - **单调序号同时是幂等键**——同一 `(stream, ordinal)` 重复结算得同一结果，退出重进 / push 重放都不改变结果，与决策点存档的防重掷同一条纪律。**一次授予要抽多条时（礼包的 1 法则 + 2 古宝）共用同一个 rng 实例连续抽**，故整次授予由 `(stream, ordinal)` 完全确定。
  - **对轮回可复现性零影响**（不派生自 `CycleSeed`、不消耗任何子流 `State`）。两个用例：**道统残卷**（`PowerFragment` 域，序号 = `FinaleWinOrdinal`，见 `systems/player-profile/player-power/_index.md`）与 **premium bundle**（`PremiumBundle` 域，序号 = **本次兑现的 `ordinal`**——`BundleGrantOrdinal` 是它的上界，兑现循环从 `BundleRedeemedOrdinal + 1` 逐个追平；见 `systems/monetization.md`）。**「持有的账号级内容不同 ⇒ 同一 seed 的轮回体验不同」不构成公平性问题**：账号状态本就是轮回的输入（deck、法则、古宝皆然），既定的确定性承诺只覆盖「同一存档恢复后能正确继续」。
- **确定性的边界：同一 `contentVersion` 内。** 内容热更**以 overlay 更新为准**——轮回进行中 overlay 更新时新数值立即生效，**不冻结该轮回的 `contentVersion`**。因此本项目**不承诺「同一 seed 跨内容版本复现同一轮回」**：seeded RNG 的目的是消除未加种子的随机、保证存档恢复后能正确继续，而非提供跨版本的绝对可复现性。数值可随时线上修正的价值高于跨版本复现。详见 `systems/services/content-service.md`。

### 存档版本化与原子写入（强制在线 · 云端权威）
- **强制在线 · 云端权威**：进度实时同步云端，本地↔云端冲突以云端为准；本地 `user://` 仅作缓存 / 离线临时态。Source: `decisions/ADR-0003-online-cloud-authority.md`。
- **原子写入**：先序列化到临时文件，再重命名覆盖；本地缓存与上行云端负载**一律原子**。实现走共享静态工具 `AtomicJsonFile`，见 `systems/architecture.md`。
- **给存档加 schema 版本字段 + 迁移路径**；读取时校验版本 / 内容 id / 字段，未知或不匹配以清晰错误 / 迁移处理，绝不静默 null。Source: `.claude/rules/state-save-rules.md`。
- **带版本是按判据的，不是全称的。** **多字段的结构体（存档聚合、上行 / 缓存信封）必须带版本并有一条迁移路径**——它们的字段面会增长，读到不认识的结构而无版本可判即坏档。**单字段的设备维度小文件不带版本**：迁移面为空，那一格纯属仪式，且配套的「版本不认识就整份丢弃」对某些文件有害。判据是**这份文件的结构会不会增长到需要逐版迁移**。

### Null / 结果校验（强制）
- 每次节点查找、资源加载、注册表 / 字典查找、存档读取之后，使用前**显式校验**：必需但缺失 → `GD.PushError` + 定位上下文（id / 路径）并退出；可选但缺失 → `GD.PushWarning` + 安全默认值。绝不把未检查的 null 向下游传递。Source: `.claude/rules/null-check-rules.md`。

### 日志约定
- 用 `GD.Print` / `GD.PushWarning` / `GD.PushError`，带 `[System-Method]` 标签（例：`[Combat-PlayCard]`）；在关键状态转换（轮回开始 / 结束、遭遇战、卡牌结算、存档 / 读档）做有意义日志。Source: `.claude/rules/Context.md`。

### 服务协作约定（层级 service ⊃ manager ⊃ module ⊃ processor ⊃ handler）
- **service = 进程内模块单例，不是微服务。** 全部服务在同一 Godot 项目 / 同一二进制 / 同一进程内，以 **autoload** 形式存在，彼此为直接 C# 方法调用；manager 是服务持有的普通 C# 对象（非 `Node`）。唯一真实的进程边界是客户端 ↔ 后端。工程落地形态见根级 `system-overview.md`。
- **service = 边界单元**（判据三选一：① 自有状态机 / 长流程；② 事务性跨字段一致写；③ 外部 I/O 边界）；**manager = 服务内部的职能组件**，共享宿主服务的事务边界与生命周期，**不被跨服务直接调用**。服务清单与拆分轴见 `systems/services/_index.md`。
- **拆分轴 = 生命周期层 + 行为边界，不是数据类型。** 不按 power / item / card / resource 各开服务（撕碎事务、横切生命周期层、退化为贫血 CRUD）；不为五类 AdventureEvent 各开服务（只有 Combat 有状态机，其余差异在数据而非代码）。
- **两条唯一入口：** 内容读取经 `content-service.ContentRegistry`（不散落 `ResourceLoader.Load`）；档案写入经 `profile-service.ProfileManager`（全量校验 → 全有或全无 → 单点提交，modifier pipeline 在此生效）。
- **跨服务调用纪律（已定案的准确措辞）：服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用允许**——经对方的服务门面 `Xxx.Instance.Method(...)`，不得触及 `private` manager 字段。**编排顶点 game-progression** 负责「谁在什么时机调谁」的屏幕流程串联，但**不是**一切跨服务调用的必经中转；既成事实经 **EventBus** 广播。

### API 契约总则（摘要）

> 完整八条总则、共享核心类型与 EventBus 负载 schema 的**权威在 `systems/architecture.md`「API 契约总则」**。此处只列所有系统文档书写 API 时必须遵守的约束。

- **三种方法形态，按「它跨什么边界」决定，不允许混用：** **A · 同步直返**（纯内存查询与纯本地事务）／**B · `Task<OpResult<T>> + CancellationToken`**（跨客户端 ↔ 后端边界）／**C · `Task<T>` 由信号推进**（跨多帧的玩法长流程）。**形态 B / C 一律带 `Async` 后缀并返回 `Task`，形态 A 一律不带**——看签名即知它是否跨边界。
- **三种失败语义，与 null-check 规则一一对应：** 必需缺失 = 程序缺陷 → `GD.PushError` + `throw`；可选缺失 = 调用方可降级 → `bool TryXxx(..., out T)` + `GD.PushWarning`；**业务失败 = 预期内的拒绝 → 返回 `OpResult` / `OpResult<T>` / `ApplyResult`，绝不抛**。结果类型一律 `readonly record struct`（零堆分配）。
- **服务门面骨架：** manager 类型 `internal sealed`、服务只暴露方法不暴露 manager 引用、**服务不返回内部可变集合**（一律 `IReadOnlyList<T>` / `IReadOnlyDictionary<,>`）。
- **启动契约：** `_Ready` 只装配，I/O 归 `IBootstrappable.InitializeAsync(ct)`，由 Bootstrap 屏幕按固定顺序驱动。
- **EventBus 用 C# 泛型 `event` + `readonly record struct` 负载**（不用 Godot `[Signal]`——负载须继承 `GodotObject`，每次广播分配 + `Variant` 装箱，撞上本文件「不做隐式装箱 / 转换」与热路径不分配）。**负载只带 `Id` + 值类型，绝不带 `CharacterProfile` / `Resource` / 定稿实例引用**；订阅方 `_Ready` 订阅、`_ExitTree` 退订。
- **`CostSpec` / `RewardSpec` 合并为单一 `ProfileChangeSpec`**（`ChangeElement.BaseValue` 带符号：负 = 消耗，正 = 产出）——「全有或全无、单点提交」本就要求成本与产出在同一事务内。
  - **分列判据补一句：载荷类型不同、且该列的入口校验绑定在载荷类型上时，同样判分列**——即便两列的施加语义同形。合并这样的两列要把载荷改成 sum type、把入口校验改成按载荷类型分支，而那正是分列要消掉的东西。判据本体（三级落点与可机械核对的六个面）在 `systems/architecture.md`「共享核心类型」，本处只补这一条边界。
- **capability flag 的载体是 C# `enum CapabilityFlag`**，不是字符串 key：flag 的消费点必然是一段 UI 代码，字符串只是把「拼错了」从编译期推迟到运行时。可加的是 `.tres` 里**谁授予哪个已定义的 flag**。
- **API 书写规范：** 各服务文档的「API 面（契约）」小节统一为四列表 **方法 | 形态(A/B/C) | 完整签名 | 失败语义**；形状依赖未答问题的写 `⟨待定：链接到待决项⟩`，不留空白也不臆造。

### 与 `.claude` 的主从关系

- **`.claude` 是工程层，只承载两类东西：** ① 工程相关的配置与规则（harness 配置、C#/Godot 互操作与场景 / 数据 / 存档 / UI / null 校验纪律）；② 可复用的技能。**一切设计相关的知识与细节归本库**，在 `.claude` 内只被**引用与轻描述**（指路 + 一句话承重纪律）。
- **冲突裁决：** 设计性内容（机制、数值、字段、契约、流程）冲突 → **以本库为准**，`.claude` 跟着改；工程性约束（命名、生命周期、热路径、工具 / PATH、目录纪律）冲突 → **以 `.claude/rules/*` 为准**（本库对此无权威）。判据即「这句话的权威在哪一侧」：讲**游戏是什么** → 本库；讲**代码怎么写** → `.claude`。
- 因此本文件各条目中的 `Source: .claude/rules/*` 指向的是**工程纪律的权威**；凡属设计结论者，权威在本库、规则文件只留摘要。完整论证见 `decisions/ADR-0005-knowledge-thin-reference-layer.md`。
- **rules 里那份摘要的合法形态 = 一句祈使 + 标识符名 + 一句代价 + 一条直指本库的回链**——**越界清单、归属分类与三条机械规则见 `decisions/ADR-0005` 的「### 2. 规则层的具体形态」，本处不复述**。违反即制造第二权威：两份表会各自漂移，而本库没有任何机制能发现它们不一致。


Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-12e-ability-grant-draw-pool.md` · `handoffs/2026-08-14b-claude-rules-design-content-thinning.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-22-card-counters-api-and-key-space.md`

## 内容共有字段

> **判据卡 —— 一个共有属性写在哪一层**
>
> **定义在其全部挂载面的最小公共祖先，恰好一份；每个实际落点写一段投影（落点 · 本层合法子集 / 默认值 · 本层消费点 · 回链），投影不得复述定义。**
> **上移**：同一字段在 ≥2 个兄弟节点出现**且语义同一**（同名不同义不上移，例 `RarityTier` vs `Tier`）。**下沉**：顶层某条只被单一子树消费 ⇒ 下沉，顶层不留摘要。**只有一个落点的字段不进任何 `common-properties.md`**，留在该类自己的 `_index.md`。
> 某一层是否建 `common-properties.md`：该层有**子节点共有且全库不适用**的内容，**且**篇幅已压过 `_index.md` 的索引职责——**按内容建，不按对称建**（见 `systems/_index.md`）。
> **硬边界（可机械检查）：** 同一个字段名在两份及以上的 `common-properties.md` 中同时出现**枚举成员表 / 数值 code / 完整校验语义**任一者 ⇒ 违规（第二权威）——两份表会各自漂移，而本库没有任何机制能发现它们不一致。
>
> **「最小公共祖先」按挂载面算，不按「感觉有多通用」算。** 例：`ExclusiveSource` 只覆盖 `PowerData` / `ItemData` 两个类，但这两个类的落点横跨 `character-profile/` 与 `player-profile/` 两棵子树 ⇒ 最小公共祖先是顶层。
>
> **投影段模板**（新字段落到某一层时照抄，控制在 5 行以内）：
>
> ```markdown
> - **`<FieldName>`（共有字段 · 类型 `<T>` · <日期>）。** <一句话：本层落在哪个类上>。
>   - **本层合法取值 / 默认值 =** <只抄本层那一列>。
>   - **本层消费点：** <点名，或明写「本层无规则消费点」+ 一句代价说明>。
>   - 类型定义、取值清单、校验语义见 `systems/common-properties.md`。
> ```
>
> **为什么必须明写「本层无规则消费点」而不是省略：** 省略与「还没想」不可区分。

**当前顶层六个共有字段的归属核对（判据的一次全量自检 · 无一需要迁移）：**

| 字段 | 挂载面 | 最小公共祖先 | 结论 |
|---|---|---|---|
| `ContentEnabled` | 一切 `XxxData` | 顶层 | 留顶层 |
| `LocalizedText` | `CardData` / `AdventureEventData` / `ItemData` / `EnemyData` / `PowerData` / 档位条目 / 剧本 | 顶层 | 留顶层 |
| `Rarity: RarityTier` | `PowerData` / `ItemData` / `CardData` / `CultivationTechniqueData` | 顶层 | 留顶层 |
| `Artwork: Texture2D` | `CardData` / `EnemyData` / `PowerData` / `ItemData` / `CharacterData` / `LocationData` / `AdventureEventData` | 顶层（跨多棵子树） | 留顶层 |
| `SourceCode` + `Source` | PlayerPower / PlayerItem / CharacterPower / CharacterItem 四类**持有条目** | 顶层 | 留顶层 |
| `ExclusiveSource: Source?` | `PowerData` / `ItemData` | 顶层（跨两棵子树） | 留顶层 |

### 内容共有字段 `ContentEnabled`
- 每种 `XxxData : Resource` 携带 **`ContentEnabled: bool`，默认 `true`**——线上放量开关，overlay 只改这个既有布尔字段，不触碰「不得新增 `Id`」纪律。
- **过滤只发生在产出侧：** 一切**抽取**（eventOptions、商店库存、奖励掷骰）走 `ContentRegistry` 的 **`AllEnabled()`**；**读取侧 `Get(id)` 不过滤**，故存档引用到被关闭的条目仍能正确解析。**任何从内容集合抽取的代码必须走 `AllEnabled()`**——与「不散落 `ResourceLoader.Load`」同级的纪律。
- **这条纪律由命名强制，不只靠条款：仓储上没有中性名 `All()`**——只有 `AllEnabled()`（抽取池）与 `AllIncludingDisabled()`（全量：启动期校验 / 图鉴统计 / 调试），过渡期保留一个 `[Obsolete(error: true)] All()` 编译闸。选级判据见 `systems/architecture.md`「纪律的可执行化」。
- **合并后强校验对 disabled 条目照常全量执行**（`Id` 唯一性、交叉引用不悬空），走 `AllIncludingDisabled()`。完整论证见 `systems/services/content-service.md`。

### 内容文本的多语言形态 `LocalizedText`

> **UI 文案与内容文案是两条不同的语言链路**：界面走 `res://text/` 翻译键（随包、发版才改，见 `ux/error-and-blocking-ux.md`），内容走本节的 `LocalizedText`（overlay 可热更）。判据是 `ux/_index.md` 的**四问**，两层对照表也在那里。**两层不同载体、不同热更权限，但共用同一个语言开关。**

**同一个 `Id`、同一个 `.tres`，多语言是那个条目内部的一个字段结构。**

```csharp
/// 一段可本地化的内容文本。内容层专用——UI 文案走 TranslationServer 翻译键，不用本类型。
[GlobalClass]
public partial class LocalizedText : Resource
{
    /// locale → 文本。键与 TranslationServer 的 locale 标识符同一套（封闭二值 zh / en）。
    [Export] public Godot.Collections.Dictionary<string, string> Entries { get; set; } = new();

    /// 按当前 locale 取；缺当前语言 → 静默回落默认语言 zh（失败语义见 content-service.md）。
    public string Get();

    /// 指定 locale 取；缺失 → false，调用方降级。审计与图鉴统计用。
    public bool TryGet(string locale, out string text);
}
```

- **挂载面 = 一切面向玩家的内容文本字段：** `CardData` / `AdventureEventData` / `ItemData` / `EnemyData` / `PowerData` 的**显示名 · 描述 · 风味文案**；`PowerData` / `ItemData` 顶层的图鉴风味文案 `CodexFlavor`（可选，见下）；**`EnemyData` 的台词（`EnemyLine.Text`，形态见 `systems/enemies/_index.md`）**；`HiddenStatBandData` 的档位叙事条目；Finale 的渡劫身死文案；AdventurePlot 的剧本正文与分支文本。
- **不挂载：** `Id`、任何数值、任何枚举、`ContentEnabled` / `Rarity` / `ExclusiveSource` 等结构字段。
- **可选的 `LocalizedText` 字段：「缺失」= 字段本身为 `null`（承重）。** 有的展示文本字段本就可以整段不存在（`CodexFlavor` 是第一个：图鉴详情页缺它就不渲染风味段）。**这类字段留空的形态是 `.tres` 里不挂这个子资源**，语言强校验只对**已挂上的 `LocalizedText`** 执行；挂了却默认语言为空串仍是坏数据。
  - **不引入「必填 / 可选字段分类清单」**：那会长出一份要逐字段维护的表，且每加一个展示文本字段都要先回答「它属哪一类」——把一条可机械判定的校验降级为要读上下文。
  - 它与「缺 `en` 键 = 未翻译」是**同一种判据风格**：干脆没有这个键 / 干脆没有这个子资源，都是干净可判的条件。校验口径的权威在 `systems/services/content-service.md`。
- **三条采纳理由，逐条对上既有纪律：**
  - **加一门语言 = 在 `.tres` 里加一个键，零代码改动**——落在「新增内容 = 新增 / 编辑 `.tres`，不改 switch」内。这同时**否决「每语言一个 `[Export]` 字段」**（`DescriptionZh` / `DescriptionEn`）：那种写法把「加一门语言」变成「改 C# 类 + 发版」，语言数直接焊死在代码里。
  - **它是「改既有条目的字段值」⇒ overlay 可以热更它**，完全落在「只改不增」内——**线上补一段英文文案不必发版**。这是本形态相对全部替代方案的实质收益（`res://text/` 已定为随包分发，内容文案放进去等于给它判了「改一个字要过审核」）。
  - **给出唯一的语言解析入口**——与 ContentRegistry 作为「全游戏唯一内容读取入口」、`AllEnabled()` 作为「产出侧唯一取池入口」同一种偏好：回落逻辑只写一处，校验与审计只需遍历这一个类型。
- **两条配套纪律：**
  - **`Get()` 必须纯读，绝不把解析结果写回 `XxxData` 或 `LocalizedText`**——`XxxData` 是 ContentRegistry 里的**共享只读单例**（见「物化模型」），缓存写回会污染注册表。需要缓存就缓存在 **ViewModel** 上，那正是「组合展示由 UI 层按需组装、不落存档」那一层的职责。
  - **`LocalizedText` 不落存档、不进上行负载。** 它是内容定义的属性；存档与云端负载照旧只带 `Id` + 可变状态。**不 bump schema，无迁移。**
- **locale 取值域封闭为二值 `zh` / `en`，无地区码。** 中长期语言范围就是中英双语，不预留第三门语言的结构；**不设 `zh_TW`**，日后确需繁体走简繁转换（同一条「能机械变换的绝不建第二张手写表」）。`Get()` **就读 `TranslationServer.GetLocale()`**，不另设内容语言设置；**归一在启动期做一次**（形态见 `ux/error-and-blocking-ux.md`「语言开关只有一个」）。
- **切语言后已组装的 ViewModel 不会自己变**（`LocalizedText` 不经 `TranslationServer`）——重组装纪律的权威在 `systems/viewmodel.md`「重组装的触发面」。
- **校验与审计的形态、以及「缺 `en` 键 = 未翻译」的占位约定，见 `systems/services/content-service.md`「内容文本的语言校验与覆盖率审计」。**
- **抽取池零影响**——一条内容仍是一个 `Id`、一个池成员，权重不被语言数稀释。这正是**否决「每语言一套条目 `Id`」**（`card_xxx_zh` / `card_xxx_en`）的第二条理由；另两条：撞「只改不增」（加一门语言 = 新增 N 个 `Id`，只能发版且 overlay 永远补不上），以及切语言会让存档里的 `Id` 引用全部悬空。
- **排期：与 `DrawPool<T>` 同批，第二阶段（内容）开工前、第一份内容 FR 之前落地。** 理由相同——`XxxData` 类、`.tres`、UI 读取点当前存量**都是零**，此刻是纯加法窗口；窗口在写下第一批 `.tres` 的那一刻关闭，此后每多一条内容就多一份要改的资产。两者也天然是同一次 `XxxData` 面的改动。
- **与 `vision/scope.md`「本地化打磨在 MVP 范围外」不冲突：** 那条软约束要的是「现在不做多语言，但现在就不能挡住多语言」，其括号里自己写明的落法正是「让展示字符串与 id 分离」——`LocalizedText` 就是这件事的完整形态，且**不产出一个字的英文文案**（`Entries` 只有 `zh` 一个键完全合法且是默认状态）。**如实记下的代价：** 写 `.tres` 时每个文本字段多一层嵌套 SubResource，中文单语阶段编写手感变差一点，已接受。

### 内容共有字段 `Rarity: RarityTier`

- **凡「会被抽取或置换」的内容定义都带 `Rarity`**：`PowerData` · `ItemData` · `CardData` · `CultivationTechniqueData`（功法整体标一个稀有度，组内各卡不各自表达，见 `systems/character-profile/deck/_index.md`）。`AdventureEventData` **不需要**（事件不进抽取池的稀有度维度，它的出现由权重与优先级控制）。
- **`RarityTier { Tier1, Tier2, Tier3, Tier4, Tier5 }`，五档，档号越高越稀有。**
- **落在内容定义上，不落在持有条目上**——与 `SourceCode` 恰好相反：稀有度是**内容本身的属性**（同一条法则无论从哪来都是同一档），来源是**这一次获取的属性**。
- **类型名是 `RarityTier`，不是裸 `Tier`（硬约定）。** `Tier { Narrow, Solid, Crushing }` 已被战后奖励的**优势档**占用（道念差归一化后的碾压程度）。**两者不得复用同一枚举，也不得互相换算**；准确口径是「稀有度权重表按 `RarityTier` 五档索引，由优势档 `Tier` 三档选表」。见 `systems/balance.md`。
- **四个消费点：** ① 战后奖励池的稀有度权重；② **置换候选池的过滤键**（同 `(CarrierKind, Scope)` 且同 `Rarity` 才同池，见 `systems/player-profile/player-power/_index.md`）；③ **账号级授予池的加权键**（残卷 / 礼包共用一张「授予池稀有度权重表」，见 `systems/balance.md`）；④ **功法档的抽取权重与过滤**：战后奖励池的稀有度权重（见 `systems/services/combat-service.md`）· 商店 `CultivationTechnique` 族库存的 `RarityFilter` 与权重表（见 `systems/adventure-event/exchange/common-properties.md`）· 闭关（Research）功法三选一的加权取池（见 `systems/adventure-event/research/common-properties.md`）。
- **被功法引用的成员卡：`CardData.Rarity` 保持必填，但本层无规则消费点。** 该组卡牌的抽取一律看功法档；成员卡从散牌产出侧排除的通则与加载期告警见 `systems/adventure-event/exchange/common-properties.md` 与 `systems/character-profile/deck/_index.md`。**不新增「是否为功法成员」字段**——唯一权威是功法侧的每层卡牌 `Id` 列表，再加一格即第二权威。游离散牌照常携带卡牌级稀有度参与奖励池。
- **加载时校验：** 缺失 → `GD.PushError`。默认值会让漏填条目悄悄落进 `Tier1` 池并污染置换候选；对成员卡同样必填，是因为商店定价表按「商品族 × 稀有度」索引，改成可空会给漏填开一个口子。

### 内容共有字段 `Artwork: Texture2D`

**一条内容一张主视觉资产，字段形态在全库只有这一份定义；各落点写投影段解释「本层是什么图」。**

```csharp
[Export] public Texture2D Artwork { get; set; }   // 可空；null = 尚未产出，呈现层回落占位资产
```

- **挂载面 = 七类内容定义：** `CardData`（卡面插画）· `EnemyData`（敌人立绘）· `PowerData` / `ItemData`（法则 / 神通 / 古宝 / 法宝 图标）· `CharacterData`（角色形象；该类另有一格自有的稀疏境界覆写 `RealmArtworks`，见 `systems/character-profile/_index.md`）· `LocationData`（事件背景板）· `AdventureEventData`（事件插图）。资产规格与关键约束逐类目见 `art/visuals/_index.md`。
- **不挂载：** 任何运行时 / 存档态类型（`CardInstance` / `EnemyInstance` / `EventOption` / `CodexEntry`）——那一层只带 `Id` + 可变状态，见「展示字段的归属」。
- **功法（`CultivationTechniqueData`）不挂：它没有独立的视觉资产。** 资产类目表里没有功法一行，`TechniqueCodex` 的词条构成也不含立绘；图鉴族的功法词条以名称 / 描述 / `Rarity` + 可选风味文案构成。日后确需一张功法图是纯加法。
- **字段名取 `Artwork`（单数、类型中立），不取 `Portrait` / `Icon` / `Illustration`。** 同一格在敌人身上是立绘、在卡牌上是卡面、在法则上是图标；按判据卡上移到顶层的字段必须用**跨落点同义**的名字，落点差异由各层投影段的「本层语义」一行承载（同 `Rarity`）。**不拆成三个按用途分立的字段**：同一敌人在图鉴与战斗屏复用同一张资产，分立会让每个内容类都要回答「我该填哪几格」，且三格中至少两格恒空。
- **取直接资源引用，不取路径字符串、也不取按 `Id` 的约定路径推导。** 三条理由各自自足：
  - 路径形态（`[Export(PropertyHint.File)] string ArtworkPath` + 运行时加载）同时撞本文件两条纪律——「绝不用场景路径作为内容的键」与「不散落 `ResourceLoader.Load`」；按 `Id` 推导路径撞得更狠，它把资产寻址完全建立在文件路径上。
  - 直接引用在 `.tres` 里落为 `ExtResource`，编辑器可拖拽、类型受检，**悬空引用由引擎在资源加载期报出**，本库不另写悬空校验、也不需要一张「前缀 → 去哪查」的约定表（同 `PoolScope` 取具名 `Id` 字段而非 tag 的判据）。
  - **插画内不得烧入承载可翻译语义的文字**（适用全部资产类目，见 `decisions/ADR-0084-no-baked-in-translatable-text.md`）⇒ 视觉资产与 locale 无关 ⇒ 它是裸 `Texture2D`，不需要 `LocalizedText` 那样的多语言结构。
- **可空是常态，缺失不是坏数据。** 美术挂点先占位、末段替换是路线级安排（见 `decisions/ADR-0006-development-phase-order.md` 与 `vision/scope.md`）；若 `Artwork` 必填，第一批 `.tres` 会在美术产出之前全部过不了 `LoadAll()`。判据与 `AiProfile == null` 合法、`PoolScope == null` 合法同款——**漏填的后果是显示一张占位图，不是死内容、不产生静默污染**（对比 `EncounterScopes` 空数组 → 条目永不进池 → `PushError`）。
- **告警形态 = `LoadAll()` 收口的一行汇总，逐条目不告警：** `[Content-LoadAll] Artwork 缺失 N 条（按类型分布：…）`。**逐条目 `PushWarning` 不可取**——在近乎全部条目都为 `null` 的阶段，一条对**全部**条目触发的告警训练出的行为是忽略整个告警通道；纪律选级第 3 级的形态本就是启动期审计，不是逐条目刷屏（见 `decisions/ADR-0013-discipline-enforceability-ladder.md`）。缺失明细的机械核对归 asset 清单完备性校验（尚未答定）。
- **占位资产只有一处**：由 ViewModel 层统一提供 `res://art/_placeholder.png`（该文件归 `game-feature-branch/`，本库只登记这条约定），与 `LocalizedText.Get()` 的回落唯一入口同一种偏好。落点见 `systems/viewmodel.md`。
- **overlay：** overlay 覆盖一条 `.tres` 时，**本节的资产引用格**随之被覆盖；**指向必须落在随包基线内已存在的资产**——overlay 能做的只有改指到另一张已随包的资产，或置空（置空 → ViewModel 占位回落）。**二进制资产本身不经 overlay / blob 通道下发**，换图 / 加图随版本发布：`Artwork` 取的是直接资源引用，落在 `user://` 的裸资产不是导入产物，要让它被条目引用只能退回本节已逐条否决的路径字符串 + 运行时加载形态；且它会让「不做字节级断点续传」那条否决所依赖的 KB 级前提当场失效（见 `systems/services/content-service.md`）。**这条覆盖本节的全部资产引用格**，不止 `Artwork` 一格。报文侧的对位（blob 通道的能力对文件类别中立，限制来自本节的字段形态而非契约）见 `backend-design-documents/contracts/content-manifest.md`。
- **不落存档、不进上行负载**，不 bump schema、无迁移、后端零配合——它是内容定义的属性，同 `LocalizedText` / `ExclusiveSource`。
- **消费点 = ViewModel 组装**（见 `systems/viewmodel.md`）。各层的具体消费屏在该层的投影段点名。
- **基数恒为一条内容一格；境界维度不进本字段。** 七个挂载面里能被境界索引的只有 `CharacterData` 一个（敌人的境界是 `EnemyInstance` 的物化产物、不在模板上，见 `systems/enemies/_index.md` 与 `decisions/ADR-0044-enemy-leveling-band.md`；`LocationData` 三章共用同一张图，见 `decisions/ADR-0042-location-flat-set-and-single-map.md`）——**只有一个落点的字段不进 `common-properties.md`**，故境界覆写按判据卡落 `CharacterData` 自有的一格 `RealmArtworks`，见 `systems/character-profile/_index.md`。
- **已知代价（明写接受 + 退让阶梯）：** `ExtResource` 直引使 `LoadAll()` 把全部条目的贴图一并驻留内存。条目量级 × 移动端压缩贴图，量级上可接受；**若真机实测超包体 / 内存预算，退让阶梯是**：① 先降资产分辨率与压缩格式（纯资产侧，零结构改动）→ ② 才考虑改为路径字符串 + 在 ViewModel 层开**唯一一处**受控的资产加载入口（仍不散落 `ResourceLoader.Load`）。给出阶梯是为了让「内存不够」有一条不必重开本节形态裁决的出路。

### 授予来源共有字段 `SourceCode` + `Source` 枚举

- **凡「可被授予并持有」的条目都带 `SourceCode`**，记录它是被**哪条渠道**给到玩家的。覆盖四类：**法则 PlayerPower** · **古宝 PlayerItem**（账号级，落 `PlayerProfile`）· **神通 CharacterPower** · **法宝 CharacterItem**（轮回级，落 `CharacterProfile`）。
- **落在持有条目上，不落在 `PowerData` / `ItemData` 上。** 这是物化模型的直接推论：`XxxData : Resource` 是 ContentRegistry 里的**共享只读单例**，而同一条法则可由不同渠道获得——**来源是「这一次获取」的属性，不是内容定义的属性**。它与 `status` 同层，属持有条目的运行态 / 存档态字段。
- **写入时刻 = 授予时刻，此后不变。** 条目被移除后再次获得 = 一次新的获取，写新的 `SourceCode`。
- **`Source` 是单一的 C# 枚举，不按类拆成四个。** 四类共用**同一条授予通道**（`AbilityChangeElement` 的 `Op == Grant` 与 `ProfileManager.Grant*`），一个 `Source` 形参贯穿全链；每类各一枚举会把它逼成 `object` / `int` / 泛型，直接撞上本文件「贯穿整条链路的类型一致性」。同型判断的先例是 `AbilityScope`——它同样把按类分裂的枚举合成一个。**分域差异由校验表承载，不由类型系统承载**（见下）。
- **成员带 code 与 value：** **code** = 显式的稳定整数，是**存档**里实际序列化的东西；**value** = 展示文案，与 code 分离、可本地化、**不落存档**（走翻译键；但 `SourceCode` 当前不对玩家可见，翻译键暂不铺开）。与既定纪律同构——capability flag 的载体是 `enum CapabilityFlag` 而非字符串 key，显示字符串一律与键分离（见上方「稳定 Id 键」）。
- **上行负载走字符串成员名（`"FinaleWin"`），映射发生在序列化边界。** 契约侧一律字符串、与 C# 成员名逐字相同（通则不开例外，权威在 `backend-design-documents/contracts/envelope.md` §2 与 `contracts/profile-sync.md` §5a）；存档侧仍是整数 code。
  - **映射只在 `sync-service` 组装上行负载时做一次，不在 `profile-service` 内部做**——存档态与内存态始终是 code，避免同一个值在内存里有两种形态。
  - **连带纪律（承重）：成员名与 code 双双冻结。** 存档侧靠 code、契约侧靠名，**两者各自都是稳定键**：重命名一个成员在**两侧都是**破坏性变更，已删成员的名与 code **同样永不复用**。
  - **未知取值：记录原值、不改写、不拒收。** 归一为 `Unknown` 会压低 `x`、让残卷档位回跳，推翻「`x` 单调不减 ⇒ 档位只降不回跳」这条承重不变式。
  - **`(CarrierKind, Scope) → 允许的 Source 集合` 那张静态表只约束客户端组装，后端不复制**——后端只做取值识别与 `x` 复算。
- **成员清单 = 十值 + 兜底：**

  | 成员 | code | 语义 | 计入残卷的 `x` |
  |---|---|---|---|
  | `Unknown` | 0 | **防御性成员，不是一条途径**：老档缺字段 / 无法识别取值的归入处 | 否 |
  | `FinaleWin` | 1 | 渡劫成功时由道统残卷掷中并发放 | **是（唯一计入者）** |
  | `PremiumBundle` | 2 | 付费礼包给予 | 否 |
  | `AchievementReward` | 3 | 成就奖励给予 | 否 |
  | `EventOutcome` | 4 | 由**通用结算器**从物化后的 `EventOption` 的 outcome / effect 定义算出的授予（Research / Explore / Travel，以及 Exchange 的非购买 outcome） | 否 |
  | `CombatReward` | 5 | 由 **combat-service** 在 `RunCombatAsync` 收口段算定、经 `CombatResult.Spoils` 交出的授予（含强制与可选两类；`Finale` 档的残卷那一路仍走 `FinaleWin`） | 否 |
  | `ExchangePurchase` | 6 | Exchange（交易）事件中购买所得 | 否 |
  | `InitialGrant` | 7 | 开局初始持有（角色创建时随 `CharacterProfile` 初始化的起手配置） | 否 |
  | `ExchangeSell` | 8 | Exchange 中被玩家**卖给**商店（只出现在 `Op == Remove` 上） | 否 |
  | `PackSell` | 9 | 玩家在**储物袋内随手售出**法宝，发生在事件之外（只出现在 `Op == Remove` 上） | 否 |
  | `ExchangeBarter` | 10 | Exchange 中作为**以物易物的支付侧**交出的法宝（只出现在 `Op == Remove` 上） | 否 |

  **清单是开放的，不封闭在账号级那几条途径上**：神通 / 古宝 / 法宝各有真实存在的来路，字段应如实记录它们，否则轮回级两类只能一律落 `Unknown`。**`FinaleWin = 1` / `PremiumBundle = 2` / `AchievementReward = 3` 的 code 已冻结**——后端复算 `x` 依赖它们。
- **成员的分野判据 = 谁组装出这条 element**（承重 · 不看它属于哪类事件、也不看它最后被谁写进去）。出自 `CombatResult.Spoils` → `CombatReward`（`Finale` 胜利的残卷那一路例外，走 `FinaleWin`）；出自通用结算器的 outcome / effect 定义 → `EventOutcome`；出自购买流程 → `ExchangePurchase`。
  - **施加路径不构成判据。** 上述三者今天就已走同一条施加链路——都收敛为 `ProfileChangeSpec`、都在 `eventEnd` 由同一次 `TryApply` 写入；若「施加路径同一 ⇒ 应合并」成立，`InitialGrant` 也该一并合并，而清单不是按这条轴切的。**清单的粒度轴是渠道 / 组装路径**：Exchange 是非战斗类事件而其购买所得单列 `ExchangePurchase`，即是这条轴的直接体现。
  - **按事件类型表述会被两处打穿，故不采用。** ① `EventOption.EventType` 在 Explore 时恒为 `Explore` 本身、真身在 `RevealedEventId`——一个揭示出战斗真身的 Explore 选项按事件类型判会写成 `EventOutcome`，而它实际出自 combat-service 交出的 `Spoils`；② Exchange 的非购买 outcome（对话结果、赠礼）在事件类型轴上无归属，按组装者判则唯一：**只有走购买流程的那一条走 `ExchangePurchase`，其余走 `EventOutcome`**。
  - **`EventOutcome` 与 `CombatReward` 分立，不合并为一个成员。** 合并会让 `TryApply` 的可追溯性日志与客服 / 数据侧的账号溯源同时失去「战斗掉落 vs 事件产出」这条区分，而持有条目上**没有任何字段能事后补出它**（`SourceInstanceId` 是另一个字段，见下）——这个维度一旦不写就永久消失。对价只是一个零维护成本的枚举成员（不进 `.tres`、不走 overlay、后端不复制校验表）。在「名与 code 双双永不复用」的冻结纪律下，粒度选择本就不对称：**细了可以永远不用（成本恒为零），粗了要补回来得追加新成员且老数据无法回填**。
  - **两者在 `(CarrierKind, Scope)` 表中逐格相同（❌ ❌ ✅ ✅）不构成合并理由。** 同表中 `PremiumBundle` 与 `AchievementReward` 同样逐格相同（✅ ✅ ❌ ❌）。**行相同只说明挂载面相同**（能出现在哪类持有条目上），渠道说的是**由哪条路径给出**——两个正交维度。
  - **重开条件（可观察）：** 仅当 combat-service 的奖励计算被并入通用结算器时重新评估两者是否合并——具体即以下任一发生：① `RunCombatAsync` 不再自算 `Spoils`；② 战后可选奖励选择步骤被取消；③ 奖励厚度不再由道念差决定。三者任一都会在 `systems/services/combat-service.md` 的「意图」节留下痕迹，故无须定期主动复核。
- **⚠ 不为「置换所得」设成员（禁令）。** 清单开放不意味着这一条也能加：新设一个 `Replacement` 成员会立刻打破 `x` 的单调不减，重开「用置换刷回高掉率」的通道。
- **合法取值域按 `(CarrierKind, Scope)` 分域。** `(CarrierKind, Scope)` 是全库既有的分类键（置换同池判据即它全同），四类 = 该二元组的四个取值：

  | 成员 | 法则 `(Power, Player)` | 古宝 `(Item, Player)` | 神通 `(Power, Character)` | 法宝 `(Item, Character)` |
  |---|:--:|:--:|:--:|:--:|
  | `FinaleWin` | ✅ | ❌ | ❌ | ❌ |
  | `PremiumBundle` | ✅ | ✅ | ❌ | ❌ |
  | `AchievementReward` | ✅ | ✅ | ❌ | ❌ |
  | `EventOutcome` | ❌ ※ | ❌ ※ | ✅ | ✅ |
  | `CombatReward` | ❌ | ❌ | ✅ | ✅ |
  | `ExchangePurchase` | ❌ ※ | ✅ | ✅ | ✅ |
  | `InitialGrant` | ❌ | ❌ | ✅ | ✅ |
  | `ExchangeSell` | ❌ | ❌ | ❌ | ✅ |
  | `PackSell` | ❌ | ❌ | ❌ | ✅ |
  | `ExchangeBarter` | ❌ | ❌ | ❌ | ✅ |
  | `Unknown` | ✅（仅读档兜底） | ✅（同左） | ✅（同左） | ✅（同左） |

  - **账号级不接 `CombatReward` / `InitialGrant`：** 账号级授予唯一的战斗入口就是残卷，而它已有专用成员 `FinaleWin`；「开局初始持有」是角色创建时的行为，账号级两类不随角色创建发放。
  - **轮回级不接 `PremiumBundle` / `AchievementReward`：** 二者按定义是账号级发放——发一件随轮回清理的东西作为付费 / 成就回报，与「付费内容不会被游戏销毁」正面冲突。
  - **`Unknown` 只作读档兜底，不是授予时的合法入参**（授予侧传 `Unknown` = 调用方漏填，与「不设默认值」同一条纪律）。
  - **※ 三格 ❌ 是「暂不开放」，不是「语义上不可能」。** 它们取决于尚未设计的「法则的第三条获取渠道」（见 `systems/player-profile/player-power/_index.md` 的待决项）；在那条答定前一律 ❌，**日后开放 = 在校验表里翻一格，无任何结构改动**。
  - **清单里有三个成员记的是「怎么没的」而非「怎么来的」，故它们只出现在 `Op == Remove` 上：`ExchangeSell`（在 Exchange 商店里卖给商店）· `PackSell`（在储物袋内随手售出）· `ExchangeBarter`（在 Exchange 里作为以物易物的支付侧交出）。** 买与卖在履历、成就与诊断上是两件事：复用 `ExchangePurchase` 会让「购买次数」这类统计永远算不准，而 `Source` 的既定职责本就是「这件东西怎么来的 / 怎么没的」。**三条通道彼此也不复用同一个成员**：随售发生在事件之外，把它记成 `ExchangeSell` 会让「在商店里卖了几件」同样算不准，且让这条痕迹指向一个不存在的事件；以物易物**一枚货币都不动**，把它记成 `ExchangeSell` 会让同一个维度第二次算不准（换出去的东西被计进「卖了几件」）。**校验相应扩三格**：`Op == Grant` 且 `Source == ExchangeSell`、`Op == Grant` 且 `Source == PackSell`、`Op == Grant` 且 `Source == ExchangeBarter` → 均为**必需缺失**，`PushError` + 整批拒绝（与「`(CarrierKind, Scope, Source)` 不在合法子集表内」同档）。**三者都不落在任何持有条目的 `SourceCode` 上**（那件东西已经不在了）。
    - `ExchangeSell` 出现在 `AppliedChange` 的那条 `Remove` element 里——账里因此读得出「这件法宝是卖掉的，不是被事件剥夺的」。
    - `ExchangeBarter` 同样出现在 `AppliedChange` 的那条 `Remove` element 里。**它是按分野判据单列的**：以物易物由**独立的 barter 提交路径**组装（门面先查一次持有再组装 spec），与售出流程不是同一条组装路径；而在「名与 code 双双永不复用」的冻结纪律下，粒度选择本就不对称——细了可以永远不用（成本恒为零：不进 `.tres`、不走 overlay、后端不复制校验表），粗了要补回来得追加新成员且老数据无法回填。**支付侧单列不影响产出侧**：barter 换来的那件东西照常走 `ExchangePurchase`，如实记账为「从商店取得」。规则权威见 `systems/adventure-event/exchange/_index.md`。
    - **`PackSell` 连这条也没有：随售没有 `PastEventEntry` 可挂**，它只是 `TryApply` 入参上的一个**来源标注**，进可追溯性日志与客服 / 数据侧溯源，**不进存档**。（随售那一次提交的 push reason 是 `SavePointReason.InventoryChanged`，见 `systems/services/sync-service.md`；那是 push 侧的归因维度，不改变本成员不进存档这一条。）**代价明写（被接受的取舍）：「这件法宝是在储物袋里随手卖掉的」事后不可重建**——它与「购买次数没有字段回答且事后无法追溯重建」是同一款取舍，缓解手段只有日志。
    - **交出面仅 `CharacterItem`（法宝）一族开放**，三条通道的规则权威分处两侧：商店内售出与以物易物的支付侧见 `systems/adventure-event/exchange/_index.md`，储物袋随售见 `systems/character-profile/item/_index.md`。三行中其余三格 ❌ 是**规则层的封死**，不是「暂不开放」——账号级持有物（法则 / 古宝）跨轮回，拿它换一次性收益会把账号级资产变成轮回级消耗品；神通不进任何交易面。
  - **`ExchangeSell` / `ExchangeBarter` 本身不单独 bump schema**（字段形状不变，仍是一个整数 code，仅值域扩大——与下方那条通则一致）；但**它随同批的 `EventOption` 两个新物化字段一起落在一次 bump 内**，当前无线上存档 ⇒ **空迁移**。`PackSell` 一个字节也不进存档，与 schema 无关。
  - **合法子集表落为一张静态查表**（`(CarrierKind, Scope) → 允许的 Source 集合`），与置换同池判据共用 `(CarrierKind, Scope)` 键；它是**代码常量，不是内容资源**——它约束的是代码组装而非内容编写，**不进 `.tres`、不走 overlay**。
- **授予通道必须带上来源：** 凡授予 power / item 的 element（`AbilityChangeElement`，`Op == Grant`）**必须携带 `Source`，不设默认值**——省略即产生来源未知的条目，而 `x` 直接读这个字段。`ProfileManager` 的授予签名相应带上来源（`GrantPower(string powerId, Source source)`，见 `systems/services/profile-service.md`）。
- **校验：入口严、读档宽。** `Op == Grant` 且 `(CarrierKind, Scope, Source)` 不在合法表内、或 `Source == Unknown` → **必需缺失**，`GD.PushError` + **整批拒绝**（与 `PairKey` 配对不成立同档）。读档遇不合法的**既有条目** → **可选缺失**，`GD.PushWarning` + **保留原值**，不阻塞、不改写。**这条非对称是唯一安全的方向**：读档回落 `Unknown` 会把一条 `FinaleWin` 法则改判为非 `FinaleWin`，压低 `x` 并让档位回跳，违背单调不减。缺失字段 / 无法识别取值仍归入 `Unknown`（老档迁移即补 `Unknown`，当前无线上账号，迁移成本为零）。
  - **组装者判据另有一条单向校验**，落在 life-cycle-service 合并 `eventEnd` 事务处（未走过 combat-service 的事件出现 `CombatReward` → 整批拒绝；反向不判非法），见 `systems/services/life-cycle-service.md`。
- **不 bump 存档 schema。** 字段形状不变（仍是一个整数 code），仅值域扩大；老档中的 `Unknown` 原样保留，无迁移动作。
- **置换不改变来源：置换所得条目继承被换出条目的 `SourceCode`。** 目的是**关死「用置换刷回高掉率」的通道**——若置换产物记为一条新来源，换掉一条 `FinaleWin` 法则即使 `x` 下降、档位回跳。**推论：置换对 `x` 完全中性，「`x` 单调不减 ⇒ 档位只降不回跳」因此成立**；代价是来源字段记的是「这条能力最初从哪条途径进入账号」而非「上一次易手的方式」，这是有意的取舍。
- **消费点分两层：**
  - **规则消费点仍唯一** = 道统残卷的分档自变量 `x`（= 已拥有且 `SourceCode == Source.FinaleWin` 的法则数，见 `systems/player-profile/player-power/_index.md`），且只看 `FinaleWin`。它因此仍是**纯规则字段**（严格同步口径 · 后端可复算，见 `systems/player-profile/_index.md` 的两层通则），`Source` 也因此是一条**会被后端读到**的字段——取值的稳定性同时是一条客户端 ↔ 后端契约。**除 `FinaleWin` 外没有任何成员能出现在法则上并被计入 `x`**，故清单再扩也对残卷零影响。
  - **非规则用途两处**（现成落点，不新增机制）：① `ProfileManager.TryApply` 的可追溯性日志（来源正是那行最该带的信息）；② 客服 / 数据侧的账号溯源（付费给予 vs 玩法所得的区分是退款与申诉的第一手依据）。
  - **承认的代价：** 轮回级两类的 `SourceCode` **仍没有任何规则消费点**——在那两类上它依然是「只写不读」的字段，只是取值不再恒为兜底值。这条张力真实存在，只是从「字段无意义」降级为「字段有信息但暂无规则消费者」。
- **⚠ 与 `SourceInstanceId` 是两个不同字段。** `SourceCode` = 授予**渠道**，落**持有条目**；`SourceInstanceId` = 施加禁用的那个**来源事件实例**，落 `disabledAbility` 条目、供「长按查看来源事件」反查 `pastEvent`。名字相邻，**不得合并**。

### 内容共有字段 `ExclusiveSource: Source?`（准入标记）

- **凡可被抽取授予的内容定义都带 `ExclusiveSource: Source?`，默认 `null` = 通用。** 覆盖 `PowerData` / `ItemData`。它声明**这条内容只能由哪条渠道给出**：`!= null` 的条目**不进任何抽取池**（残卷 / 礼包 / 置换的换入侧一律排除，见 `systems/player-profile/player-power/_index.md` 的取池链）。
- **⚠ 它与 `SourceCode` 名字相近、方向相反，必须并排读：**

  | | `ExclusiveSource` | `SourceCode` |
  |---|---|---|
  | 落点 | **内容定义**（`PowerData` / `ItemData`） | **持有条目** |
  | 语义 | 这条内容**只能由哪条渠道给出**（准入） | 这一次获取**实际来自哪条渠道**（记账） |
  | 消费点 | 取池过滤（产出侧） | 残卷的 `x` |
  | 不填的含义 | `null` = 通用，任何渠道都能给 | 无「不填」——授予通道强制携带 |

- **首个也是当前唯一的用例 = 成就限定条目**（`ExclusiveSource == Source.AchievementReward`）。成就奖励给的是**指定条目**而非抽取结果，把这些条目挡在全部抽取池之外，才使「成就奖励恒不落空」成为机械保证而非口头约定；完整论证与三条校验见 `systems/player-profile/achievement/_index.md`。
- **选 `Source?` 而非新开一个布尔（如 `AchievementExclusive`）**：同一诉求日后必然重演（活动限定、剧情限定条目），复用既有枚举让「限定给谁」成为一次数据填写，而非每次新增一个布尔字段——与「新增内容 = 新增 `.tres`，不改 switch」同一条纪律。取值域随 `Source` 清单扩张而自然扩大。
- **不落存档**（它是内容定义的属性，不是持有条目的属性），故不 bump schema。

Source: `handoffs/2026-08-09e-discipline-enforceability.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12b-grant-source-per-kind-scope.md` · `handoffs/2026-08-12e-ability-grant-draw-pool.md` · `handoffs/2026-08-13-translation-key-rollout-and-content-localization.md` · `handoffs/2026-08-14-common-properties-layering.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-16h-grant-source-assembler-criterion.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-19-codex-entry-schema.md` · `handoffs/2026-08-19-architecture-structural-residuals.md` · `handoffs/2026-08-25-numeric-philosophy-and-balance-anchors.md` · `handoffs/2026-08-26-storage-pack-two-layer-view-and-combat-holdings.md` · `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md` · `handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md` · `handoffs/2026-08-30-realm-progression-artwork-basis.md` · `handoffs/2026-08-30-exchange-barter-support.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。
- **`.claude` 是工程层、对设计只做薄引用；设计内容以本库为准 / 工程约束以 `.claude/rules` 为准** → `decisions/ADR-0005-knowledge-thin-reference-layer.md`（Accepted；范围覆盖整个 `.claude`，其「### 2. 规则层的具体形态」定义 rules 侧投影的四件套 + 硬边界 + 执行者）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

*（无）*

## 对应
提炼至：`.claude/knowledge/standards/`（ADR-0005：设计投影的三份 `signal-eventbus` / `rng-determinism` / `save-format` 为**薄引用**，回链本库；`csharp-conventions` / `godot-scene-conventions` / `mobile-portrait-ui` 讲 C#/Godot 引擎实践，在本库无权威，**保留实质**）。

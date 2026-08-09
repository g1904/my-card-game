# Answer log discipline-enforceability

- 日期：2026-08-09
- 来源：`inbox/solution-draft-discipline-enforceability.md`（已评审，用户逐项裁决）→ `handoffs/2026-08-09e-discipline-enforceability.md`
- 移出条数：**3**（另新增 1 条）

## 移出的问题

**`[Export] bool UseOfflineBackend` 的发布期防护（`open-questions/05-service-contracts.md`）** → 三层收口：① **先修一处技术互斥**——autoload 指向 `.cs` 时不存在场景实例，`[Export]` 没有存储处也没有检视器落点，「开发期切换不需重编译」在当前形态下本就不成立；**裁决松动 `[Export]`、保留「autoload 直接指向 `.cs`」并升为无例外约定**（推论：服务级配置一律走 ProjectSettings）。② **主闸 = 阶梯第 1 级**：唯一选择点 `BackendSelector` + 四个 `OfflineXxxBackend` 整类包 `#if DEBUG`——Release 构建里离线实现根本不存在，问题从「开关会不会配错」降级为「类型存不存在」。承重理由是**四个字段 = 四个出错点，最糟失败态是「三个开了一个没开」的半在线状态**。③ **第 3 级兜底**：ProjectSettings `mycardgame/backend/use_offline_backend`（进版本控制、可 diff、原生支持 feature override）+ BootstrapScreen 的横幅与 release×offline 断言。否决导出预设 / 启动期断言作**主**闸。（归档去向：`system-overview.md` 第三节与第四节「选择形态」、`systems/architecture.md` 总则 7）

**EventBus 退订纪律的可执行性（`open-questions/05-service-contracts.md` + `systems/architecture.md` 待决问题）** → **定级第 3 级即可**（漏退订不改变玩法结果、开发期即可显形），形态 = `#if DEBUG` 订阅审计：遍历 `GetInvocationList()` 判 `!IsInstanceValid(target)`；**定位信息取自 `d.Method` 而非 `d.Target`**（泄漏时实例已释放，反射元数据不依赖存活）⇒ **订阅时无需登记来源，`+=` 惯用形态原样保留**；**触发时机 = 切屏完成后由 game-progression 调一次**（零热路径成本），否决「每次 `Emit` 顺带检查」（撞热路径不分配），`_ExitTree` 只打订阅计数摘要不做判定（服务同步销毁时会误报）；推论：**泄漏检查豁免 autoload 服务的订阅**。（归档去向：`systems/architecture.md` 总则 5）

**`AllEnabled()` 纪律的可执行性（`open-questions/05-service-contracts.md` + `systems/services/content-service.md` 待决问题）** → **删除中性名 `All()` 本身**，只留 `AllEnabled()`（抽取池）+ `AllIncludingDisabled()`（全量；合并后强校验是它第一个正当调用方），过渡期以 `[Obsolete(error: true)] All()` 占位作第 2 级编译闸。承重理由是**命名诚实性**——否决「`All()` 保留但语义改为 enabled-only」（一个叫 `All` 却不返回全部的方法会撒谎，只是把 bug 挪到未来）；否决 Roslyn 分析器（`[Obsolete(error: true)]` 拿到同一份编译期保证，成本低几个数量级）。**类型层加固 `DrawPool<T>` 已采纳但排期到第二阶段（内容）开工前、第一份内容 FR 之前**——彼时三个抽取侧已有真实调用方可验证形状，且分桶问题大概率已答定。（归档去向：`systems/services/content-service.md`「`AllEnabled()` 纪律的可执行化」、`systems/common-properties.md`、`.claude/rules/data-resource-rules.md`）

## 连带产出的上位判据

三条本是**同一个问题的三个实例**：*正确的写法需要作者主动记得，错误的写法既不报错也不显眼*。因此本次同时立了一条**统一判据**——**「纪律的可执行化」四级阶梯**（写不出来 / 编译不过 / 大声失败 / 评审清单）+ 两条选级判据（**能上线且线上不可见 → 必须第 1 或第 2 级**；**只在开发期显形且会累积 → 第 3 级足够**），落在 `systems/architecture.md`，与八条 API 契约总则同层，列为 **ADR 候选**。附带一条穷举纪律：**条件编译共 6 处，不得扩张**。

## 未移出 / 新增

- **新增：`#if DEBUG` 判据的实测确认**（留在 `open-questions/05-service-contracts.md`）——首次生成 `.csproj` 后需实测一次「Godot 的 Release 导出配置不定义 `DEBUG`」；不成立则改用自定义 `<DefineConstants>`，方案形态不变。
- **仍待答：`ContentEnabled` 分桶粒度**（留在 `systems/services/content-service.md`）——影响面已收窄为**仅 `DrawPool<T>` 的构造签名**，不阻塞本阶段的命名改造与 `Obsolete` 闸。

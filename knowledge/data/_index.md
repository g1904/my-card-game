# 数据索引（引用层）

> **类定义与条目实例分两处**：**「这类内容怎么运作」的权威在 `game-design-documents/systems/`**（各内容类型的字段、schema、平衡数值），**「有哪些条目」的权威在 `game-design-documents/content/`**（一条内容一份文档 + 类型档案）；管线、仓储接口、增量下载与签名的完整形状在 `systems/services/content-service.md`。此处只留导航与承重纪律。规则：`.claude/rules/data-resource-rules.md`。

## 代码现状

**尚未编写任何内容。** `game-feature-branch/` 无 `.tres`、无 `XxxData : Resource` 类、无 `res://content/` 目录。下表是**规划**。

**内容条目的共有字段**（`ContentEnabled` · `LocalizedText` · `Rarity` · `SourceCode` + `Source` · `ExclusiveSource`）**定义只在最小公共祖先一层**，权威见 `systems/common-properties.md`「内容共有字段」——各落点只写投影，此处不复制字段表。

## 内容类型 → 权威位置

| 类型 | Resource 类（规划） | 权威设计位置（`systems/`） |
|------|--------------------|------------------------------|
| Card（卡牌） | `CardData` | `character-profile/deck/` |
| 卡牌次类型 | `CardSubtypeData` | `character-profile/deck/`——**稳定字符串 id 的 `.tres` 注册表，不是 C# 枚举**（须能被效果筛选引用）；id 规范 `<maintype>.<name>` |
| 异能 | `AbilityData` | `character-profile/deck/`——静止式 / 启动式 / 触发式三分，与「载体」正交，抽为可复用条目 |
| 功法 | `CultivationTechniqueData` | `character-profile/deck/`——**卡组的构筑单位**（整组入组 / 逐层整组替换）；逐层的卡牌定义挂在它上面 |
| 角色（模板） | `CharacterData` | `character-profile/`——有身份的角色模板（≠ 轮回态 `CharacterProfile`），自带一个神通与两门绑定功法 |
| 法则 / 神通（Power） | `PlayerPowerData` / `PowerData` | `player-profile/player-power/`、`character-profile/power/` |
| Enemy（敌人） | `EnemyData` ↔ `EnemyInstance` | **`systems/enemies/`**（与 adventure-event 平级）——含样本卡组、`EncounterScopes` / `PoolScope` |
| AdventureEvent（修行事件） | `AdventureEventData` | `adventure-event/`（拆入九个子类型） |
| 可购道具 | `ItemData` / `PlayerItemData` | `player-profile/player-item/`、`character-profile/item/` |
| Location（地域） | ⟨载体待定⟩ | `game-progression.md`——携带三组字段（事件类型概率修正 / 一组 `EnemyData` 取池 / `eventCountLimit`）；**已具备内容条目形态**，载体定名仍待答 |
| `locationMap`（地域图） | ⟨载体待定⟩ | `game-progression.md`——**一张全局不变的连通图**，三篇章共用；只读静态数据、启动加载常驻，存档只存当前 location `Id` |
| 遭遇参数 | `EncounterSpec`（`sealed record`，非 `Resource`） | `adventure-event/combat/`——回合数与胜负判据参数化 |
| 平衡配置 | `BalanceData` | `balance.md` |
| 剧本分支文本 | ⟨载体待定⟩ | `services/plot-manager.md`——**本地内容层**（08-11 撤销云端剧本服务），随 overlay 分发；正文不落存档，`CharacterProfile` 只存 key points |

## 承重纪律

1. **`Id` 是稳定唯一的字符串，也是唯一的交叉引用键。** 绝不按名称、数组下标或场景路径引用内容。
2. **抽取走 `AllEnabled()`。** 每个条目带共有字段 `ContentEnabled: bool`（默认 `true`），是线上灰度 / 分批放量 / 秒关开关——**秒关与灰度走 flags 通道**（按账号、轮回中途可热应用），overlay 只承担随内容一起发布的初值。**关键的不对称**：**产出侧**（eventOptions 物化、商店库存、奖励掷骰）只从 `AllEnabled()` 抽；**读取侧** `Get(id)` / `TryGet` **不过滤**——存档引用到刚被关闭的条目仍须正确解析。**仓储上没有中性名 `All()`**——全量走 `AllIncludingDisabled()`，写下 `All()` 会编译失败（`[Obsolete(error: true)]`）。漏写过滤即线上事故。
3. **`XxxData : Resource` 是模板不是成品，运行时绝不写它。** 它是注册表里的**共享只读单例**、可被 overlay 覆写；写回会污染同一轮回的后续批次与其他角色。
4. **「内容定义 + 情境 / 轮回内状态」= 两个类型：** `AdventureEventData` ↔ `EventOption`（物化定稿，**不可变**，落存档）、`CardData` ↔ `CardInstance`（运行态**可变**）、`EnemyData` ↔ `EnemyInstance`（物化定稿，**不可变**；**敌人等级即物化产物**，嵌 `EventOption` 落存档）。共享纪律：**服务签名里传实例，不传 `Resource`**。
5. **静态展示文案就留在 `XxxData` 上**，且**类型是 `LocalizedText` 而非裸 `string`**（多语言是条目内嵌字段，加一门语言 = 在 `.tres` 里加一个键；裸 `string` 会把语言数焊进 C# 类并让线上补文案必须发版）。**`LocalizedText.Get()` 必须纯读，绝不把解析结果写回 `XxxData` / `LocalizedText`**——它是 ContentRegistry 里的共享只读单例，缓存写回会污染注册表；要缓存就缓存在 ViewModel 上。**`LocalizedText` 不落存档、不进上行负载。** → `systems/common-properties.md`「内容文本的多语言形态」。不为「充血模型」另建并行展示类；动态组合走呈现期 ViewModel。**运行时 / 存档态只带 `Id` + 可变状态**，不复制展示文本——文案变更不触发存档迁移。
6. **校验点在合并之后。** overlay + 基线合并完再统一校验：重复 `Id`、悬空交叉引用 → 启动期 `GD.PushError`，早失败。**`ContentEnabled == false` 的条目照常参与全量校验**——它们是完整内容，只是不进抽取池。
7. **可调数值存导出字段 / `BalanceData`**，绝不硬编码在系统逻辑里。
8. **不散落 `ResourceLoader.Load`** ——一切内容经 ContentRegistry。
9. **敌人与玩家共用 `CardData` 体系，但不共用卡池。** `Pool` 是**必填字段、无默认值**——漏填即坏数据，在启动期校验里报出来。**卡组规模两侧皆不设硬限**（08-11c 推翻「敌人固定 15 张」——旧值的理由「保证永不重洗」随重洗删除而失效），允许重复；规模因此成为可编排的维度，代价由疲劳承接。
10. **本作不存在多敌人场景** ——`EventOption` 上的敌人字段是**单数**。不要预留 `List<EnemyInstance>`。

## 三层覆盖来源与热更边界（形状见 `services/content-service.md`）

```
res://content/**.tres     基线，随包发布，只读（保证首启可用）
user://overlay/**.tres    云端下发的增量，可热更，按 Id 覆盖基线
flags（运行时态，不落盘为 .tres）  按账号解析后的 disabledIds，只覆盖 ContentEnabled
      ↓ 合并（flags > overlay > res://）→ 合并后统一校验（flags 不参与）
ContentRegistry（内存）    按 Id 索引，全游戏唯一读取入口
```

- **热更范围 = 只改不增；剧本内容是唯一例外。** overlay 只改既有条目的数值 / 文案，**不得新增 `Id`**——「存档引用未知内容」的风险从根上消失；代价是新内容只能随版本发布，放量靠翻 `ContentEnabled`。（**已否决**「预埋空壳 `Id` 日后填充」：与合并后强校验冲突，且属商店审核灰区。）
  - **例外只覆盖剧本内容本身**（08-11）：它是唯一不被存档引用的内容类别，故 overlay 对它**可新增 `Id`**，新剧情因此可热更不发版。**新增的剧本条目不得引用本次 overlay 之外的新 `Id`**（保住交叉引用不悬空）。`CardData` / `AdventureEventData` / `ItemData` / `EnemyData` / `PlayerPowerData` / 平衡表 / **状态转换触发的定性文案**照旧只改不增。
  - **随之而来的唯一新风险 + 其处置：** key point 指向的剧本节点在当前合并结果中缺失（overlay 或客户端版本回退）→ **`GD.PushWarning` + 跳过该段叙事及其对 eventOptions 的调制，轮回照常继续**，绝不阻塞、`CharacterProfile` 不进异常态。与「读取侧不过滤」同构。
- **flags 是 `ContentEnabled` 的第三层覆盖来源**（08-11b，「overlay 是唯一热更层」已不成立）。**硬边界不可放宽：只能覆盖这一个布尔，不得携带任何数值 / 文案 / 新 `Id`**——它能秒关正因为被限制得足够窄。**作用点唯一 = `AllEnabled()` 取池**；`Get(id)` 与 `AllIncludingDisabled()` 的强校验都不受它影响。首次拉取由 Bootstrap 在登录之后调用（端点需鉴权），刷新靠应答头 `X-Flags-Version` 搭车、零轮询；拉取失败 → `PushWarning` + 用 `user://cache/flags.json` 缓存 + **绝不阻塞**；缓存**切账号即失效**。
- **不冻结轮回的 `contentVersion`** ——overlay 更新对进行中的轮回立即生效，**放弃跨内容版本的 seed 可复现**。存档记 `StartContentVersion` / `LastContentVersion` 两个版本号以便归因。→ `standards/rng-determinism.md`、`standards/save-format.md`。
- **增量下载 = 文件级事务 + manifest 签名。** `overlay.staging/` 下载落地 → 全集校验通过 → 搬入 `overlay/` → **原子写 `overlay.manifest.json`（rename）= 提交点**；任一步失败即视为本次更新未发生。**永不存在半套 overlay**，与存档原子写同构。完整四步流程、重试退避、`failReason` 分类见 `services/content-service.md`。

## 没有云端内容通道（08-11）

**一切内容——包括 AdventurePlot 的剧本文本与分支——都在本地**（`res://content/` 基线 + `user://overlay/`），经 ContentRegistry 按 `Id` 读取。**运行时内容零网络请求**；网络只在启动期用于 manifest 比对与增量下载。先前那条「按进度动态请求、一次性呈现、不被存档引用 → 云端剧本服务」的分界判据**已被撤销**（它把选择的*结果*当成了*理由*）。理由全文 → `systems/services/plot-manager.md`。

**唯一仍在的分界只决定热更粒度**：被存档引用的内容 → 只改不增；不被存档引用的剧本内容 → 可新增 `Id`（见上）。

> 仍待决（→ `open-questions/deferred-content.md`、`04-hidden-attributes-plot.md`）：disabled 条目被存档引用时是否提示玩家；剧本内容的**数据形态**（是否为一种进 ContentRegistry 的 `XxxData : Resource`）与**分包边界**；「新增剧本条目不得引用本次 overlay 之外的新 `Id`」的可机械检查形态。**分桶配置放哪已答结（08-11b）：分桶规则哪也不放在客户端**——端点按账号计算后只给结果，客户端只看到 `disabledIds`，永远不知道分桶规则存在。
>
> **`AllEnabled()` 的强制形态已定案（08-09e）**：靠**删除中性诱饵名 `All()` 本身**（过渡期 `[Obsolete(error: true)]` 恒抛作编译闸），不靠评审清单——漏写过滤的发生机制是「随手写了那个最短最中性的名字」。已否决「把 `All()` 语义改为 enabled-only」（命名诚实性）与 Roslyn 分析器（同一份编译期保证，成本高几个数量级）。`DrawPool<T>` 已采纳但**排期到第二阶段、第一份内容 FR 之前**（其唯一依赖已随分桶留在服务端而解除——构造签名不必带 `bucketContext`）。→ `systems/services/content-service.md`。

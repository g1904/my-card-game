# capability flag 体系的形态，与重试上限的存档表达

- id: 2026-08-27-capability-flag-and-entitlement
- date: 2026-08-27
- topic: systems/services/profile-service · systems/player-profile/player-power/common-properties · systems/architecture · systems/character-profile/power · systems/services/life-cycle-service · systems/balance
- status: distilled
- distilled-to: systems/services/profile-service.md · systems/player-profile/player-power/common-properties.md · systems/architecture.md · systems/character-profile/power/_index.md · systems/services/life-cycle-service.md · systems/balance.md · decisions/ADR-0017-capability-flag-and-modifier-pipeline.md

## Intent（distilled）

ADR-0017 固化了「数据声明 → 中心聚合 → 单点查询」的两通道模型，但把三项落地细节留在待决：flag 的枚举与命名空间、叠加与冲突规则、聚合面的宿主服务。同一批还有一条相邻的待答项：重试上限由礼包从「无限 / 3 / 1」改写为「无限 / 9 / 3」之后，它落成什么存档形状。两半一起答，因为后者的三个候选之一正是前者。

### 一 · flag 的枚举与命名空间

- **单一扁平 `enum CapabilityFlag`**，不分区、不加前缀、不嵌套——类型名本身就是命名空间；分区只会让每个消费点先答一次「它属于哪个区」。
- **首批成员 = 现有两个**（`RevealHiddenStats` · `ShowExploreType`），**按内容建、不按对称建**，不预铺占位。
- **命名 = 动词 + 宾语，动词取自封闭三词表** `Reveal`（把已存在但被隐藏的信息显出来）· `Show`（把某处 UI 元素显示出来）· `Unlock`（打开一个原本不可用的入口）。
- **禁止否定式 / 关闭式命名**（`Hide*` · `No*` · `Disable*` · `Suppress*` · `Prevent*`）。这不是风格偏好，是下一节那条不变式的可机械检查形态。
- **新增一个 flag 恰好三步：** 枚举加成员 → 消费点加一次 `Has(flag)` 自查 + 订阅 `CapabilitiesChanged` → 某条 `PowerData` 的 `.tres` 声明授予它。不 bump 存档 schema、不改任何服务、不新增事件。

### 二 · 叠加与冲突规则

- **叠加 = 集合并，幂等**：不计数、不叠层、不告警。布尔量没有「两份更强」的语义。
- **冲突在结构上关死**：全部 flag 恒为增益向 ⇒ 不存在互相矛盾的两个 flag，union 就是全部规则，不需要优先级 / 声明序 / 裁决表。禁用词表就是这条不变式的护栏。
- **确需关闭某项默认可见物**时的正确形态：把默认态挪到内容侧 / `GameSetting`，用正向 flag 打开。
- **落地 = `HashSet<CapabilityFlag>`，不加 `[Flags]`**：位掩码焊死 32 / 64 上界并要求手工维护 2 的幂，换来的只是非热路径上的一次按位与。

### 三 · 聚合面的宿主服务

宿主 = **`profile-service.CapabilityManager`**，此前已定，本次只清理三处过期措辞（两处「缺少宿主服务」括注 + 一格待决项）。不新开账号级服务：服务判据三条（有状态机 / 跨进程边界 / 跨字段事务）皆不满足，聚合输入全是 profile-service 的自有状态。

### 四 · 注册面两层共用

`CapabilityManager` 同时遍历 `PlayerProfile.playerPower` 与当前角色的 `CharacterProfile.characterPower`，经同三条与门（拥有 · `status == 启用` · 不在 `disabledAbility` 内）聚合成同一份生效能力集与同一张修正表。

- **推论 ①：轮回内 build 多一条战斗外表达通道**——一个神通可以在这一局里让你看见隐藏属性 / 揭示事件类型。代价是全局可见性成为轮回级可变量、一条轮回级条目可以改写 `ShopPrice` 一类的全局修正；这是被接受的取向。
- **推论 ②：轮回结束后角色级 flag 随重新聚合自然消失，无清理代码。** 无当前角色时（主菜单）只聚合账号级那一份，正常态、不告警。
- **推论 ③：`ItemData` 两类不参与聚合**（带 `Charges`、启动式，效果走 `Abilities`）；生效判据表那两行对道具恒为空集，是自洽而非例外。
- **触发源清单**（全部走同一条 `Recompute()`，不新增机制）：`Hydrate` · 能力得失 · `status` 开关 · `disabledAbility` 写入 / 到期 · 轮回开始 / 拆解。

### 五 · modifier 的叠加与运算顺序

- 形态 `ModifierEntry(ModifierKey Key, ModifierOp Op, int Value)`，`ModifierOp { Add, Scale }`；**`Scale` 的 `Value` 是万分比增量**（`-2000` = −20%），禁 `float`。
- **合并算法 = 同层求和 → 只乘一次 → 只取整一次**，外加两条钳制：`scale` 钳到 `[0, ∞)`（总折扣不得翻号，否则一笔消耗会走到产出向的准入上）；结果与 `baseValue` 同号或为 0。
- 这个形状让「运算顺序」这个问题不存在 ⇒ **不设优先级字段、不设稳定排序、不设声明序约定**。
- 战斗内求值管线的 `ModifierTarget` 是**另一套 key 空间**，两套不合并（合并会让「一个 `ModifierKey` 只能有一个施加点」被战斗内条目撑破），但**量纲与合并算法两侧逐字相同**。

### 六 · 重试上限的存档表达

**三个候选一个都不采纳：正确答案是不新增任何东西，读既有的 `PlayerEntitlement`。**

- `RetryChapter` 的上限判定读 `profile-service.HasPremiumBundle`（`=> Entitlement.BundleGrantOrdinal > 0`，单点查询、不缓存），两档上限表两行住 `systems/balance.md`，life-cycle-service 选行——这条链路已在正文写死。
- 候选 A（`CapabilityFlag`）否决：生效能力集受轮回级禁用截断，把付费凭证放进一个设计上允许被截断的聚合面等于给「花钱买的东西被事件拿走」留后门；且上限是每篇章一格的三元组，布尔承载不了。
- 候选 B（modifier 的一条具名修正）否决：modifier 明写不作用于序号与付费凭证，且上限是**选行**不是**算数**。
- 候选 C（独立 `Entitlement` 字段）否决：`PlayerEntitlement` 只放付费凭证本身与其兑现水位、不放任何派生量；一个 `HasExtendedRetry` 就是 `BundleGrantOrdinal > 0` 的第二份拷贝。
- ⇒ **存档 schema · `CostKey` · `ResourceElements` · 透明路径 · sync-service · 后端契约全部零改动。**
- 唯一新增的是**载体形状** `ChapterRetryLimitsData : Resource, ISingletonContent` + 内嵌 `ChapterRetryRow`（`Chapter1/2/3` 具名字段，`-1` = 无限），经 `Content.Single<T>()` 取、调用方不写 `Id` 字面量，加载期校验两行非 `null` 且各字段 `>= -1`。**数值一格不动。**

## Clarifications（interview 产物）

- **flag / modifier 的注册面是否两层共用（神通能否授予 flag 与具名修正）？** → **共用**。`CapabilityManager` 聚合 `playerPower` + 当前角色 `characterPower`，同三条与门；`profile-service.md` 原文「遍历 `PlayerPower`」按此扩写为两层。用户同时知悉：此裁决**提前定下了「神通 ↔ 法则复用边界」的一半**，其余部分仍待专场。
- **modifier 的量纲与合并算法须与战斗内求值管线对齐（跨草稿）** → **两套 key 空间并存但强制对齐**：`ModifierKey` 管 Profile 侧、`ModifierTarget` 管战斗内，不合并；**量纲统一万分比整数**；**合并算法统一「同层求和 → 只乘一次 → 只取整一次」**。两侧同批落笔。
- **是否就地改写 Accepted 的 `ADR-0017`？** → **授权就地改写**「后果」里那句已失真的现状描述，把「仍未定的落地细节」三项收窄为只剩「`status` 与「拥有 / 失去」两态的存档表达」。决策本体不动、不新增编号、不动 `decisions/_index.md`。

**自行采纳的标准默认（依据）：**

- **`systems/balance.md` 的两行表已经落笔**（草稿称尚未落笔，事实相反）⇒ 本次只在该条目下追加一个「载体形状」子条目，不新建小节、不改任何数值、不动「数值是否再调」那条待决项。依据：既有正文。
- **`ChapterRetryLimitsData` 用具名篇章字段而非长度 3 的索引数组**（草稿建议 `int[]`）。依据：`EnemyLevelingData` 明写「篇章数是固定的游戏结构 ⇒ 具名字段，不用字典 / 索引数组」，且其内嵌行类型一律 `Resource` 派生。
- **`PowerData` 的两个新字段现在就落**（草稿称须并入一次尚未定案的 handoff）。核对后：未定案的是 **`RelicData`** 的字段清单与触发器体系；`PowerData` 的字段清单已存在且已定，落点是 `character-profile/power/_index.md` 的既有字段行。
- **不执行草稿「对 derive 的影响」那一条**（撤销 derive 排除项）。该判定归 `/assess-derive-readiness` 独占，本次不给任何就绪度结论。
- 扁平 `enum` 不分区 · 首批只两个成员 · `ShowSkipCost` 不进枚举 · 命名三词表 + 禁负向 · union 幂等不告警 · `HashSet` 而非 `[Flags]` · 宿主不新开服务 · `ItemData` 不参与 · 万分比整数禁 `float` · 两条钳制 · 不加优先级字段 · 「一个 `ModifierKey` 只能有一个施加点」不放松 · 三候选全否读既有 `PlayerEntitlement` · `life-cycle-service.md` 按正文收口删待决项 · 存档与后端契约零改动——逐条依据见各主题文档正文。

## Open questions

- **`status` 与「拥有 / 失去」两态的存档表达**——同一批待决项里未被本次覆盖的那一条（它已由 `PlayerPower(PowerId, Status, SourceCode)` 的 record 形态事实上答定，但收口措辞不在本次范围）。
- **`RelicData` 的字段清单与触发器体系**仍未定案，不在本次范围。
- **重试上限两档数值是否随实测再调**——落点已定、只欠数值，仍留在待答清单。
- **flag 首批清单会随各 UX 专场增长**——本次定的是规范与新增流程，不是最终清单。

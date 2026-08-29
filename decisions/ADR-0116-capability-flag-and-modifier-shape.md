# ADR-0116 — `CapabilityFlag` 取扁平枚举 + 正向三词表命名，叠加为幂等集合并；modifier 合并「同层求和 → 只乘一次 → 只取整一次」

- **状态：** Accepted
- **日期：** 2026-08-27
- **来源：** handoffs/2026-08-27-capability-flag-and-entitlement.md

## 背景

`ADR-0017` 固化了「数据声明 → 中心聚合 → 单点查询」的两通道模型，但把三项落地细节留在待决：flag 的枚举与命名空间、叠加与冲突规则、聚合面的宿主服务。modifier 侧同样只定了「key + 运算 + 数值」，没有合并算法。

## 决策

**flag 载体 = 单一扁平 `enum CapabilityFlag`**，不分区、不加前缀、不嵌套；首批成员按内容建、不预铺占位。

**命名 = 动词 + 宾语，动词取自封闭三词表 `Reveal` / `Show` / `Unlock`；禁止否定式 / 关闭式命名**（`Hide*` · `No*` · `Disable*` · `Suppress*` · `Prevent*`），配 `#if DEBUG` 反射断言。

**叠加 = 集合并、幂等**（不计数、不叠层、不告警）；**冲突在结构上关死**——全部 flag 恒为增益向 ⇒ 不设优先级 / 声明序 / 裁决表。落地取 **`HashSet<CapabilityFlag>`，不加 `[Flags]`**。

**注册面两层共用**：`CapabilityManager` 同时遍历 `PlayerProfile.playerPower` 与当前角色 `CharacterProfile.characterPower`，经同三条与门聚合成同一份生效能力集与同一张修正表；无当前角色时只聚合账号级、不告警；`ItemData` 两类不参与聚合。

**modifier 形态 `ModifierEntry(Key, Op, int Value)`**，`Scale` 取万分比增量、禁 `float`；**合并算法 = 同层求和 → 只乘一次 → 只取整一次**，外加两条钳制（`scale` 钳 `[0, ∞)`；结果与 `baseValue` 同号或为 0）。`ModifierTarget`（战斗内）与 `ModifierKey`（Profile 侧）两套 key 空间**不合并，但量纲与合并算法逐字相同**。

宿主 = `profile-service.CapabilityManager`，不新开账号级服务。逐条语义、三条与门与触发源清单 → `systems/services/profile-service.md`。

## 理由

**扁平枚举**：类型名本身就是命名空间；分区只会让每个消费点先答一次「它属于哪个区」。

**命名规范是那条不变式的可机械检查护栏**——「union 就是全部规则」只在全部 flag 同向时成立。一旦出现一个 `HideXxx`，两个 flag 就可能互相矛盾，而 union 语义答不了「谁赢」。禁用词表把这件事挡在命名层，不必等到运行期裁决。

**冲突结构上关死（承重）**：确需关闭某项默认可见物时的正确形态是把默认态挪到内容侧 / `GameSetting`，用正向 flag 打开。

**`HashSet` 而非 `[Flags]`**：位掩码焊死 32 / 64 上界并要求手工维护 2 的幂，换来的只是非热路径上的一次按位与。

**合并算法让「运算顺序」这个问题不存在** ⇒ 不需要优先级字段、稳定排序或声明序约定。`scale` 钳到 `[0, ∞)` 是因为总折扣翻号会让一笔消耗走到产出向的准入上。

**两套 key 空间不合并**：合并会让「一个 `ModifierKey` 只能有一个施加点」被战斗内条目撑破。

## 备选方案

- **按用途分区的枚举 / 加前缀 / 嵌套类型** — 否决：制造「它属于哪个区」这个每个消费点都要答一次的问题。
- **允许否定式命名、用运行时裁决表解决冲突** — 否决：把一条结构上可以不存在的问题变成运行期机制。
- **`[Flags]` 位掩码** — 否决：焊死上界 + 手工维护 2 的幂，收益仅一次按位与。
- **只聚合账号级 `PlayerPower`** — 否决：那会让轮回内 build 无法在战斗外表达任何能力面；两层共用的代价（全局可见性成为轮回级可变量）是被接受的取向。
- **合并 `ModifierTarget` 与 `ModifierKey`** — 否决：见理由。
- **给 modifier 设优先级 / 声明序** — 否决：合并算法已使结果与顺序无关。

## 后果

- `systems/services/profile-service.md` 是聚合面与合并算法的权威；`systems/player-profile/player-power/common-properties.md` 承载 flag 声明面。
- **`ADR-0017` 的决策段仍只写「聚合 `PlayerPower` 一层」，与本条的两层聚合不一致**，需要一次就地订正（改写既有决定，不新增编号）。
- 新增一个 flag 恰好三步：枚举加成员 → 消费点加一次 `Has(flag)` 自查 + 订阅 `CapabilitiesChanged` → 某条 `PowerData` 的 `.tres` 声明授予它。不 bump 存档 schema、不改任何服务、不新增事件。
- 轮回结束后角色级 flag 随重新聚合自然消失，无清理代码。
- 本裁决**提前定下了「神通 ↔ 法则复用边界」的一半**，其余部分仍待专场。
- 战斗内 `ModifierTarget` 的形态 → `ADR-0115`。

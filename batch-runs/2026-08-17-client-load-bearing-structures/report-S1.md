# S1 报告 — Profile 字段 schema

> worker 的报告文件写入被 harness 拦截，内容由 orchestrator 代为落盘（原文照录）。草稿文件本身已写入。

- 库：`game-design-documents/`（客户端，单库）。**不触发对侧落笔**——后端契约 `contracts/profile-sync.md` §5 已成文，草稿只**回链**其冻结的透明路径、未复述、未提改契约方案。⚠ 但「仍需用户决定 ④」的选项 C 若被裁定采纳，**即刻变为跨边界改动**，须在后端库落一份承接项。

## 草稿文件
`game-design-documents/inbox/solution-draft-profile-field-schema.md`

## inbox/_index.md 待处理表应追加的行
（worker 按技能正文的五列形态给出；⚠ 实际表头为三列 `文件 | status | 说明`，orchestrator 落笔时改写）
```
| `solution-draft-profile-field-schema.md` | solution-draft | 2026-08-17 | 两层 Profile（`CharacterProfile` / `PlayerProfile`）的完整字段 schema：全量采集既有已定字段 + 按层归位 + 对 9 处空白格给提案 | 评审 6 项取向后 /analyze-new-ideas |
```

## 依据构成
**既有推演 14 项 · 通行做法 1 项 · 取向选择 6 项**

既有推演：`id` 必须存在（四个 EventBus 负载 + diff 键 + 三处读档校验已在消费它）· `characterDataId`（角色模板化 + `PlotNodeData.CharacterIds` 需要）· `defeatReason`（枚举已定、事件负载已带、无字段保存）· `Realm` 枚举需登记 + 存 `realm`+`level`、全局序不存 · 卡组 `technique`+`looseCard` · 四类持有条目 record · `currentEventBatch` 必须有一格 · `chapterRetry` 三字段名 · `contentVersion` 类型统一 · `currentMana` 归属 · `experiencePoint` 需 `CostKey` 成员 · `faith`/`maleficQi` 列入 `CostKey` · `StatusFields` 补 `ChapterLifeSpanBudget` 行 · `schemaVersion` 不进 Profile · JSON camelCase 单点策略 · 六 Codex 具名字段。
通行做法：`GameSetting` 取具名类而非字典（只定形态，清单不填）。

## 建议要点
- **落笔形态 = 两份 `_index.md` 各补一张「只有形态列」的总表**（字段名 / 类型 / 归属层 / 写入通道 / 权威回链），**不含语义列** ⇒ 不触 `common-properties.md` 判据卡的第二权威硬边界。
- **`CharacterProfile` 共 22 个顶层字段 + `Status` 子类 13 个字段**：7 项已完整定案、**5 项新提案**（`id` / `characterDataId` / `defeatReason` / `characterPower` 字段名 / `currentEventBatch` 一格）、3 项标注「形状待 S3 / S4 / S5」。
- **`PlayerProfile` 共 15 个字段**（六 Codex 各占一格）：4 项已完整定案（`accountInfo` / `statistics` / `playerPowerFragment` / `entitlement`）；六 Codex 与三个集合字段名是主要提案面。
- **核心发现判据 = 每个字段必须能对上 `ProfileChangeSpec` 的某一列或明写「不经 spec」**。三处缺口由此暴露：`experiencePoint` / `faith` / `maleficQi` 缺 `CostKey` 成员、`looseCard` 缺增向 `Op`。
- **未被任何待答项阻塞的 9 项可独立采纳**，合起来已把「两层 Profile 有哪些格」补齐；被阻塞的都是「某几格里装什么」。
- 存档影响：**bump 一次、空迁移**；diff 体积预算不变。

## 仍需用户决定

**① `chapterRetry` 三个字段的名字。** A `Ch1RetryUsed/…`（**推荐**）· B `Ch1RetryCount/…` · C 放宽命名约定。
后果：A → 命名硬约定表补一行「规则层的『数量』用 `Used`」；B → **违反可机械检查的既定约定**（`Count` ⇒ 统计计数层），该约定在第一个反例上失效；C → 约定降级为「要读上下文」，失去被写下的全部理由。推荐 A：唯一同时保住可机械检查性与语义准确性者，且逐字对上文档措辞「用掉了几次」。

**② `contentVersion` 的类型统一到哪一侧。🔴** 现状：存档侧两字段 `string`，`content-service.ContentVersion` 与 `ProfilePayload.ContentVersion` 是 `int`。A 统一为 `int`（**推荐**，改存档侧两处字段表）· B 统一为 `string`（改门面属性 + **跨边界的 `ProfilePayload`**，须与后端同批改，manifest 防回放的有序比较要改 semver 解析）。推荐 A：改动面更小、落在本库有权威一侧；semver 那条轴已由 `appVersion` 独占。

**③ `currentMana` 留在 `Status` 还是移入 `activeCombat`。** A 移入（**推荐**）· B 留在 `Status` + 明写「战斗外恒等于 `manaLimit`」。后果：A → 改两处既有措辞，`activeCombat` schema 多一格；B → 零改动但给 `Status` 开纯战斗内字段先例 + 跨服务隐式不变式。推荐 A：`currentMana` 寿命短于一次事件，「重算得出来的不存」逐字相符。

**④ `PlayerProfile` 集合字段的命名风格。🔴 裁决错误的代价是后端复算静默失效。** 现状冲突：契约 §5 已冻结**复数** path `/playerPowers[*]/id`，而库内集合字段风格是**单数**（`pastEvent` / `achievement` / `disabledAbility`）；条目键名 `id` 也与 `ItemId`/`AbilityId` 风格不一致。A 以契约为准（三个新字段复数、既有单数不动，**推荐**）· B 全库统一复数（改 `pastEvent`/`achievement`/`disabledAbility`/`plotKeyPoint`，动到刚定案不久的字段名、连带 bump）· C 改契约为单数（**破坏性契约变更**，两侧同批改 + 对侧库承接项）。推荐 A + 附带动作：把「集合字段名恒为复数」写成通则并明记既有单数字段是被冻结路径挡住的例外。理由：透明路径重命名有硬后果、库内风格没有——两侧硬度不对称。

**⑤ 六个 Codex 的条目类型。** A `CodexEntry` record（首批只一个 `Id`，**推荐**）· B 裸 `IReadOnlyList<string>`。后果：A → 首批每条多一层 JSON 嵌套，日后加计数 / 首解锁元数据零迁移；B → 首批最省，但加字段时六处元素形状标量→对象一起改。推荐 A：`codex/common-properties.md` 的「待定的字段清单」已明确列着两组候选字段，且加法窗口在写下第一批存档时关闭。**反对意见如实记下**：与「不为尚无实例的需求先行造结构」偏好相反，若判定计数字段大概率不做则 B 才对。

**⑥ 是否接受「索引表」落笔形态。** A 两份 `_index.md` 各补一张只有形态列的总表（**推荐**）· B 不建表、并入「意图」节条目流。推荐 A：不触第二权威硬边界；B 会让「两层 Profile 一共有哪些字段」继续无处可答。

## 与既有决策的张力
| # | 张力 | 级别 |
|---|---|---|
| 1 | `contentVersion` 类型链路不一致（`string` vs `int`，三份文档）——无「两侧都不动」的替代方案 | 🔴 |
| 2 | 集合字段名：契约冻结复数 path vs 库内单数风格；条目键名 `id` vs `XxxId` | 🔴 |
| 3 | `Count` 后缀被统计层独占，规则层缺表达「数量」的词缀（`chapterRetry`） | 🟠 |
| 4 | `currentMana` 归属与两处既有措辞相左 | 🟠 |
| 5 | 六 Codex 取 record 是唯一一处「为未答项预留结构」，与本库偏好方向相反 | 🟠 |

## 前置依赖
`Experience` 行 / `Faith`·`MaleficQi` 是否列入 `CostKey` ← cost element 清单（`profile-service.md`）· `looseCard` 写入通道 + `plotKeyPoint` 集合型载体形状 ← **S4** · `currentEventBatch` 形状 ← **S3** · `activeCombat` 内 `EnemyInstance` 形态 ← **S5** · `GameSetting` 字段清单 ← 设置项清单 + 设备本地 vs 账号级切分（`game-setting.md`）· `achievement` 条目 schema ← `achievement/_index.md` · 隐藏属性第四项 ← `character-profile/_index.md` · `characterDataId` 的**取值面**（非字段形态）← 角色模板池形态 · 六 Codex 是否要计数字段 ← `codex/_index.md`。

## 越界发现（未处理）
1. **`life-cycle-service.md` 待决问题最后一条已过期（🟠 文档漂移）。** 「重试上限可变后的存档表达 …… 落成 `CapabilityFlag` / modifier / 独立 `Entitlement` 字段？」**已由 `PlayerEntitlement.BundleGrantOrdinal` 答定**（08-15b），同文件第 18–20 行自己就在读 `HasPremiumBundle`。该条应删除。未改动。
2. **`profile-service.md` 的「`PowerFragmentFirstWin(chapter)` 形态未定」与 `PlayerPowerFragment` 三个具名布尔并存（🔵）。** 一是 element 侧 `CostKey` 形态、一是存档侧形态，不矛盾但易被误读；若 `CostKey` 走「三个成员」则两侧天然对齐。归「cost element 清单」邻域。
3. **六 Codex 缺体积护栏（🔵）。** 它们同样随账号年龄单调增长、落在同一条「整聚合 pull 硬阻塞」路径，却无 `pastEvent` 那样的软上限告警。草稿只提了一句建议沿用同款形态，**阈值未提案**——归 `sync-service.md` 体积护栏专场。
4. **`achievement` 字段名的单数选择将被 ④ 的裁决波及**（该文档已为「随那次统一一并改」留口子）。未改动。

# ADR-0128 — `ProfileChangeSpec` 增 `StatusChanges` 列：Status 规则字段的绝对置值

- **状态：** Accepted
- **日期：** 2026-08-17
- **来源：** handoffs/2026-08-17-travel-destination-and-status-change-elements.md

## 背景

`ProfileChangeSpec` 原有三条列表——`Elements`（带符号的资源量）· `AbilityElements`（按 `Id` 的集合成员操作）· `Stats`（纯自增统计）。但 `Status` 上的一批规则字段一个也装不下：`CurrentLocationId` 是 `string`，`LocationEventCount` 要「归 0」而不是「减 N」，band 字段要写一个已算好的绝对档号。Travel 只是第一个撞上「值不是带符号 int」的实例，band 三字段同样悬着。不落定它，Travel 名义收口而实际不可 blueprint。

## 决策

**`ProfileChangeSpec` 增第四条列表 `StatusChanges : IReadOnlyList<StatusAssignment>`**，语义是**绝对置值**——赋为一个已算好的值，不做加减。

`StatusAssignment(StatusKey Key, int IntValue, string StringValue)` 取**双字段单列表**，有效格由 `StatusFields` 配表（`StatusFieldSpec(StatusValueKind Kind, int Min, int? Max)`）写死并机械校验；`StatusValueKind { Int, Id }`。`Id` 型置值解析不到 → `PushError` + **整批拒绝**。

**`StatusChanges` 恒不走 modifier pipeline**（与 `AbilityElements` / `Stats` 同）。

配套：`EventOption` 增第八个字段 `DestinationLocationId`（非 Travel 为空串，物化时掷定、不得事后算）；两条 `StatusAssignment` 由 **life-cycle-service** 在组装 `eventEnd` 那一次 spec 时置入，resolver 侧恒填空；判据写 `DestinationLocationId != ""` 而非 `EventType == Travel`。

**承重措辞同批改写**：`architecture.md` 与 `profile-service.md` 里「三个平级列表」改为**「逐条按施加语义分列」**——列表数不再进承重表述，日后再增一列不必再改一次标题。逐列字段面与失败语义见 `systems/architecture.md` 与 `systems/services/profile-service.md`。

## 理由

- **分列判据是既有的：施加语义根本不同就分列。** 置值（赋一个已算好的绝对值、不累加、按 key 的声明类型可为 id）与「带符号的量」「集合成员操作」「纯自增」都不同。压进 `Elements` 是让 `ChangeElement.BaseValue` 这个带符号 int 说谎，也会污染 `ApplyResult.MissingElement: CostKey`（它只对资源列表有意义）。
- **恒不经 pipeline 的理由比统计层更重**：`CurrentLocationId` 若可被一条法则改写，等于让内容改写玩家的地图位置；band 若可被改写，等于让法则伪造隐藏属性档位、进而伪造整条剧本线的触发条件。
- **双字段单列表而非两个列表**：拆成两个列表必然出现「加了这张忘了那张」——与 `ResourceElements` 五列合表同一条判据。
- **`Id` 型解析不到取整批拒绝**：跳过该条会产生「寿元扣了但人没走成」的半套状态；与 `CurrentLocationId` 的读档校验口径一致。
- **判据取 `DestinationLocationId != ""`**：一次性覆盖「Explore 揭示出的 Travel 也归 0」（该情形 `EventType == Explore`，按类型判会漏），且不需要在 `EventOption` 上再加 `RevealedEventType`、也不需要回查模板。
- **事务性不受影响**：各列表在同一次 `TryApply` 内提交，「全有或全无、单点提交」原样成立。

## 备选方案

- **压进 `Elements`（复用 `ChangeElement`）** — 否决：`BaseValue` 是带符号 int，装不下 `string`，也表达不了「归 0」与「置为绝对档号」；且污染 `MissingElement` 的语义。
- **拆成 `IntAssignments` / `IdAssignments` 两个列表** — 否决：必然出现「加了这张忘了那张」。
- **给 `ResourceElements` 增一列 `ApplyOp { Add, Set }` 以替代本列** — 否决：即便加了 `ApplyOp`，`CurrentLocationId` 仍是 `string`，`Elements` 仍装不下它。该项另立待答，与本决策无因果关系。
- **`PastEventEntry` 增一格记目的地** — 否决：目的地由下一条痕迹的 `LocationId` 自然给出，三种边界情形核查后结论仍成立；按「重算得出来的不存」，加字段是净负收益。
- **resolver 直接写档** — 否决：破坏「resolver 只描述结果、不自行写档」的边界。

## 后果

- **一次性关掉一组悬空**：两个 location 字段与 band 字段自此都有承载列（`StatusKey` 的成员清单随各专场逐条补，配表不写死）。
- `EventOption` 七字段 → 八字段；Explore 遮罩 Travel 时目的地在物化时一并掷定，且 **`DestinationLocationId` 与 `RevealedEventId` 同属「揭示前不得进入呈现层」**——这是 Explore 泄漏面纪律在字段侧的第二个实例，写在同一处以免被当成两条不同的纪律。
- **不另起一次 bump：** 两个 `Status` 字段、`ProfileChangeSpec.StatusChanges` 列与 `EventOption` 的 `DestinationLocationId` 一格**都属 `schemaVersion` 1**，逐条登记见 `systems/services/profile-schema-versions.md`。
- **仍未答**：`ResourceElements` 是否增 `ApplyOp { Add, Set }`（归 profile-service）· `plotKeyPoint` 的 element 形态（它是集合型、本列装不下，归 plot-manager / profile-service）· `EventOption` 的完整物化字段清单。
- 因此必须这么写的文档：`systems/architecture.md`（`ProfileChangeSpec` 逐列 + `StatusAssignment` / `StatusKey` / `StatusFields` / `StatusValueKind`）· `systems/services/profile-service.md`（施加与失败语义）· `systems/services/life-cycle-service.md`（组装点）· `systems/services/future-event-service.md`（Travel 物化伪码）· `systems/adventure-event/travel/common-properties.md` · `systems/adventure-event/explore/_index.md` · `terminology.md`。

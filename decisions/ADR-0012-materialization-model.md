# ADR-0012 — 物化模型：模板 `Data` → future-event-service 唯一物化点 → 定稿实例

- **状态：** Accepted
- **日期：** 2026-07-27
- **来源：** handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md · handoffs/2026-07-27b-service-api-contracts.md · handoffs/2026-08-17j-event-option-derived-persistence.md

## 背景

一个 AdventureEvent 的多数属性依情境而定（敌人等级、`selectCost`、Explore 真身、商店库存、Research 候选）。若这些属性留在内容模板上、由各消费侧现算，同一个事件在**呈现、结算、记入历程**三处看到的数据可能不一致；若允许消费侧回查模板重算，seeded RNG 与 overlay 热更会让重算结果与当时不同。

## 决策

**AdventureEvent 的多数属性由 future-event-service 依情境物化产出，产出即定稿。**

- **模板侧（`AdventureEventData : Resource`）** 承载稳定 `Id`、`eventType`、静态展示文案、基准数值与可变体的参数空间、数据驱动的 outcome / effect 定义。它是 ContentRegistry 里的**共享只读单例**，**任何服务都不得在运行时写它**。
- **物化侧（future-event-service）是唯一物化点。** 输入 = 模板（经 `AllEnabled()` 取池）+ CharacterProfile + location 框定 + PlotManager 调制 + SeedManager 的 map 子流；输出 = 一批 `EventOption`。**产出 eventOptions ≡ 物化 AdventureEvent。**
- **消费侧定稿（finalized）。** `EventOption` 一经输出即冻结：life-cycle-service / combat-service / ViewModel 一律只读，**不得回查模板重算、不得改写其字段**。
- **落定稿实例的判据：** 由 seeded RNG 掷定 · 由情境代入而定 · 物化时组装或变换而成——命中任一条即落 `EventOption`；三条皆不命中的留模板侧。**文本类字段是反向的硬边界**（一律留模板侧）。
- **`EventOption` 是 `sealed record`**（字段多、要落存档、一批只有个位数个、不在每帧热路径）；**定稿后确需派生用 `with`**（Explore 揭示），派生不取池、不掷物化随机、不改 `InstanceId` / `EventId`，原实例一字未动。
- **通则：** 凡「内容定义 + 情境 / 轮回内状态」的组合都是两个类型——`AdventureEventData ↔ EventOption`（定稿不可变）· `CardData ↔ CardInstance`（运行态可变）· `EnemyData ↔ EnemyInstance`（定稿不可变）。**服务签名里传实例，不传 `Resource`。**

字段面、outcome 的固化时点与物化伪码见 `systems/architecture.md` 总则 6 与 `systems/services/future-event-service.md`。

## 理由

- **「同一个事件在呈现、结算、记入历程三处看到的是同一份数据」**——这是定稿纪律要保住的唯一那件事。
- **定稿实例必须落存档，不能只存 `EventId` 事后重算**：物化用了 seeded RNG、当时的角色状态、以及可被 overlay 热更的模板，而确定性只在同一 `contentVersion` 内成立（见 `decisions/ADR-0007-local-content-layer-and-overlay.md`）。
- **写回模板会污染注册表**：`XxxData` 是共享只读单例，写回的结果会被同一轮回的后续批次与其他角色看到。
- **`InstanceId` 与 `EventId` 不可互相替代**：同一模板可在一次轮回里被物化多次。
- **`with` 派生不违反定稿**：它是纯函数派生，与「定稿后若确需派生就产生一个新实例而非改旧的」这一惯用法同形。

## 备选方案

- **只存 `EventId`、消费时按需重算** — 否决：seeded RNG + 当时角色状态 + 可热更模板 ⇒ 重算不保证同结果。
- **让消费侧直接改写模板上的字段** — 否决：污染 ContentRegistry 的共享只读单例。
- **`EventOption` 用 `readonly record struct`** — 否决：字段多、要落存档、不在每帧热路径，按值拷贝的代价高于一次分配。
- **揭示时原地改写定稿实例** — 否决：破坏定稿纪律；改用 `with` 派生并把派生实例存进 `activeEvent`。

## 后果

- **快照判据是它的孪生条**（「重算不出来的存，重算得出来的不存」）：物化判据答「这一格在不在定稿实例上」，快照判据答「这一格要不要再抄进 `PastEventEntry`」，两者取值可以不同。见 `decisions/ADR-0021-past-event-trace-schema.md`。
- 长出一族「只对某一类型有意义、其余类型填空 / null」的结构性字段：`RevealedEventId` · `DestinationLocationId` · `ResearchSlots` · `ExchangeStock` / `RerolledCount` · `Encounter`，每一个都因「重算不保证同结果」而必须落在定稿实例上。
- 定稿实例的两处住所被钉死：当前批住 `CharacterProfile.eventOption`，结算期间的派生副本住 `CharacterProfile.activeEvent`。
- 影响文档：`systems/architecture.md` 总则 6（权威）· `systems/services/future-event-service.md` · `systems/adventure-event/common-properties.md` · `systems/adventure-event/explore/`、`travel/`、`research/`、`exchange/` · `systems/character-profile/_index.md` · `systems/viewmodel.md`（只读消费纪律）。

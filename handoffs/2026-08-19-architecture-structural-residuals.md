# architecture.md 的三条结构残留：两条收口、一条单列 ViewModel

- id: 2026-08-19-architecture-structural-residuals
- date: 2026-08-19
- topic: systems/architecture · systems/viewmodel · systems/services/sync-service · systems/balance
- status: distilled
- distilled-to: systems/architecture.md, systems/viewmodel.md（新建）, systems/common-properties.md, systems/services/sync-service.md, systems/balance.md, program-overview.md, systems/_index.md, ux/_index.md

## Intent（distilled）

`systems/architecture.md` 的 `## 待决问题` 挂着三条结构残留。逐条核实后它们的性质完全不同：

| # | 条目 | 实际状态 | 残留的是什么 |
|---|---|---|---|
| ① | 断线降级的具体行为 | **主体已答**，权威在 `services/sync-service.md`（断线降级 / `Immediate` flush 的失败语义 / `Upgrade` 类错误在非闸门点）+ `account-service.md` 刷新失败分流 + `content-service.md` 两条降级 | 台账漂移 + 一处真实空白：**push 侧退避的参数形态与「放不放弃」** |
| ② | 热更「只改不增」的连带项 | **两问皆已答**，权威在 `services/content-service.md`（不预埋占位 `Id` → 否决；存档记两个 `contentVersion` → 采纳） | 纯台账漂移，无任何设计空白 |
| ③ | ViewModel 层的文档落位 | **确实未答** | 真问题 |

### ① 断线降级：补上唯一的空白，其余收口为回链

**push 侧退避的形态**（数值进 `balance.md`「同步 / 内容管线旋钮」表，形态进 `sync-service.md`「断线降级」）：

- **底数 / 因子 `2 s · ×2`，上限 `60 s`。** 上限必须小于滞留闸门 180 s，否则「最早一条待发变更滞留 ≥ 180 秒」这个判定可能在一次退避睡眠中途才被发现；60 s 在上限之下留出至少两次窗口内重试。
- **抖动只向上：`× (1 + rand[0, 0.2])`。** 服务端给的等待时间是**下界**，双向抖动会以近半的概率产出低于下界的间隔，把一次限流变成第二次限流；只向上抖仍把同一批客户端散在窗口内，错峰效果不减。上限在 +20% 后为 72 s，仍远低于 180 s 闸门。
- **没有放弃阈值。** 三条依据的合取：放弃一条待发变更 = 丢玩家进度（违反「绝不回退存档点」，与重试次数无关）；「告知玩家 + 拦住继续累积」的职责已由两个闸门承担且以次数 / 时长触发；真正「重试必然失败」的两种态（`Upgrade` / `session_revoked`）各自定的是**暂停**而非放弃。队列的淘汰路径仍只有既定三条。
- **应用挂起期间不补偿、不追赶**，恢复时按那一刻重新起算、不重置阶梯层级。

同批落进 `sync-service.md`「断线降级」的还有**一行索引**（内容 / flags 侧见 `content-service.md`，身份侧见 `account-service.md`）与**三条不变式**（阻塞点穷举四处 · 「回退存档点」零次出现 · 降级只有三种形状，新失败态必须归入其一）。**逐场景的 25 行全景表不落库**——其中大半行的权威在别的文档，抄进主题文档即制造第二权威，且那种表最易漂移；落库的只有三条不变式与一行索引。

`architecture.md` 一侧只留一条导航（挂在「内容与档案的存储分界」的 `user://cache/` 条目下），**不复述任何处置**。

### ② 热更连带项：整条删除

两个子问的答案都在 `content-service.md` 里成文，`architecture.md` 的登记是纯粹的过期条目，留着会让读者以为还有空白。该文件「内容与档案的存储分界」小节已有指向 `content-service.md` 的回链，导航路径完整，故**不留任何替代回链**。

两条结论本身照录：**预埋占位 `Id` 否决**（与合并后强校验冲突 + 应用商店审核灰区，且 `ContentEnabled` 三层覆盖已给出它想要的运营能力的合法部分）；**存档记两个 `contentVersion`**（`StartContentVersion` / `LastContentVersion`；因不冻结 `contentVersion`，一个版本号无法表达「跨过」）。存档 schema 零影响——两字段已在册。

### ③ ViewModel 层：现在单列 `systems/viewmodel.md`

**四路判据同向：**

- **最小公共祖先。** ViewModel 层的横切纪律（依赖方向 / 生命周期 / 组装源 / 重组装触发面 / 只读消费 / 缓存归属 / 永不渲染清单）的消费面横跨内容层、事件层、战斗层、同步层与错误呈现层，没有任何一份既有主题文档能容纳全部。
- **按「它服务于谁」定位。** 它服务于全部屏 × 全部服务，不属任何单屏。
- **权威在结构一侧。** 这些纪律没有一条在回答「怎么说」，故归 `systems/` 而非 `ux/`。
- **先例。** 非服务的横切件里，`game-progression` 因有自己的机制面而单列顶层文件、EventBus 因全部内容就是一条 API 契约总则而留在总则表内；判据是「它的内容是不是一条 API 契约总则」，本层的纪律绝大多数是跨屏落地纪律，属前者。

**现在建、不等第一份 UI FR**：翻译变更后 ViewModel 重组装这条纪律漏掉的症状是「切语言后卡面文字不变」，属「能上线且线上不可见」那一档，第一次写屏时最容易漏；且它与翻译基建的审计直接咬合。

配套三处**投影**（各留一句 + 回链，不复述）：`architecture.md`「展示层契约」保留三层并列定义、第三层的展开迁出；`program-overview.md`「非服务的横切件」表的 ViewModel 行回链；`ux/_index.md` 以一条边界引言块指路。`systems/common-properties.md` 的翻译重组装纪律本体迁入新文件，原处留一句回链。

「展示层三层切分」这条 ADR 候选的**固化主落点定为 `systems/viewmodel.md`**，`architecture.md` 保留三层定义段。

## Clarifications

- **草稿称「重组装纪律至今没有任何主题文档承载，只存在于 handoff」——经逐字核对不成立**，`systems/common-properties.md` 载有原文。裁决：**保留「单列」的结论**（另三条判据仍成立），但**不得把这句假陈述作为理由写进活文档**；`viewmodel.md` 的立论改用「消费面横跨多层、无既有文档能容纳全部」。同时按「定义在最小公共祖先」把该纪律的本体迁入 `viewmodel.md`，`common-properties.md` 留一句回链。
- **草稿把「非服务的横切件」表定位在 `system-overview.md`——落点错误**，该表在 `program-overview.md`。裁决：只改 `program-overview.md` 的 ViewModel 行，`system-overview.md` 不动（它管的是工程落地形态，ViewModel 既不是 autoload 也无代码形态条目，加进去是新造一处待漂移的投影）。
- **草稿的退避公式 `max(本地值, Retry-After) × jitter(±20%)` 与「服务端值是下界不是精确值」相抵**（乘性双向抖动会以 0.8× 击穿下界）。裁决：**抖动改为只向上 `× (1 + rand[0, 0.2])`**，其余参数不变。
- **`architecture.md`「展示层契约」的收束程度**：三条并列定义（三层各一格）**留在原处**，第三层的展开段（依赖方向 / 生命周期 / 不参与存档）**整段迁进** `viewmodel.md`，原处只留一句回链。两段都留会制造复述，两段都压成回链会让「三层切分」失去第三格。
- **`ux/_index.md` 的指路形态**：写成表下的**边界引言块**（该文件已有同形先例），**不在「ux 文档 | 用途」表内加行**——加进表内会让这张表不再是「ux 有哪些文档」的索引。
- **`viewmodel.md` 建空的 `## 待决问题` 小节**（沿用 `systems/*.md` 模板惯例）；`auto_translate_mode` 默认行为的实测项只在既有待答分片留一份，不在新文件里再登记一遍。

## Open questions

- 无。退避参数的**具体数值**待实测校准（与 `balance.md` 该表其余各行同一性质，表头已注明）；**形态**（上限 < 闸门 / 无放弃阈值 / 抖动只向上）是推演结论，不待实测。

## Notes / triage

- 存档 schema、协议契约、抽取池：零影响。退避参数是纯客户端行为，`Retry-After` / `detail.retryAfterSeconds` 的消费语义已定，本次只补本地侧的计算形态；**无对侧库承接项**。
- 新增待答项（跨草稿）：做一次 `architecture.md ↔ services/*` 的待决问题与投影表对账——本次三条里两条属过期登记，另有 `ResourceElements` 表在两份文档间的投影漂移。

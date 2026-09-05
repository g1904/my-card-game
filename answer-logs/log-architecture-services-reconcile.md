# Answer log architecture-services-reconcile

- 日期：2026-09-02
- 来源：`inbox/solution-draft-architecture-services-reconcile.md` → `handoffs/2026-09-02-architecture-services-reconcile.md`
- 移出条数：2

---

**⑤-5 待做一次 `architecture.md ↔ services/*` 的待决问题与投影表对账** → **已执行。** 本次逐条核出 18 处差异并全部处置：D-1 的层级词表裁决、四处过期登记删除、三族投影收口（`ResourceElements` 值 / `SettingFields` 默认值 / `StatusFields` 取值域一律只留下游）、`ResourceElements` 六列与「表驱动的终结原因只有一项」两处计数订正、`PlotThresholdReached` 第三格统一为 `BandIndex`、`## 决策(-> ADR)` 补齐 12 条、存储分界图补 flags 第三层、两张服务 ↔ manager 表补两项。归档去向：`systems/architecture.md`（主落点）· `systems/services/_index.md` · `systems/services/profile-service.md` · `systems/services/life-cycle-service.md` · `systems/services/future-event-service.md` · `systems/services/content-service.md` · `systems/player-profile/game-setting.md` · `systems/balance.md`。
剩余部分仍待办（不属本条的答结面）：`systems/character-profile/_index.md` 的 11 处 schema bump 自称改回链，须与 `sync-service.md` 的 bump 清单补齐同批做。

**第四 / 第五级的层级词（processor / handler）是否定得过早** → **不过早，登记语关闭。** 该条的原登记语是「首次真要拆一个 processor 时回头验证那三条与门判据」——触发条件已经发生：`EffectProcessor`（第四级）与效果 kind handler（第五级）已在三份下游主题文档中落地。回头验证的结论是**判据本身要改一处**：下沉判据 3 的宿主口径由「宿主 module 恰一个」放宽为「宿主恰一个（manager 或 module）」，因为层级链允许跳过中间级，而要求宿主必须是 module 会为凑层数逼出一个撞反判据 ②③ 的空壳 module。归档去向：`systems/architecture.md`「服务层：五级层次」· `systems/services/_index.md`「层级」· `decisions/ADR-0008-service-hierarchy-vocabulary.md`（层级表 · 决策 · 后果三处改写）。

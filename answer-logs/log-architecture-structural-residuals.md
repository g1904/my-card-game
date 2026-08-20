# Answer log architecture-structural-residuals

- 日期：2026-08-19
- 来源：`inbox/solution-draft-architecture-structural-residuals.md` → `handoffs/2026-08-19-architecture-structural-residuals.md`
- 移出条数：3

**断线降级的具体行为（push / pull 失败时阻塞玩家、本地缓冲重试、还是回退存档点）** → 主体本已答定，权威在 `systems/services/sync-service.md`「断线降级」/「`Immediate` flush 的失败语义」/「`Upgrade` 类错误在非闸门点」、`account-service.md`（刷新失败分流）、`content-service.md`（内容与 flags 侧降级）；唯一空白 push 侧退避形态本次补齐：`2 s · ×2 · cap 60 s · 抖动只向上 × (1 + rand[0,0.2]) · 无放弃阈值`，挂起期间不补偿不追赶。（归档去向：`systems/services/sync-service.md` + `systems/balance.md`「同步 / 内容管线旋钮」；`systems/architecture.md` 只留一行导航）

**热更「只改不增」的连带项（是否预埋占位 `Id` · 是否在存档记 `contentVersion`）** → 两问皆已答定：预埋占位 `Id` **否决**；存档**记两个** `contentVersion`（`StartContentVersion` / `LastContentVersion`）。`architecture.md` 的登记属过期条目，整条删除、不留替代回链。（归档去向：`systems/services/content-service.md`）

**ViewModel 层是否单列一份文档（或归 `ux/`）** → **现在单列 `systems/viewmodel.md`**，不等第一份 UI FR；`architecture.md` 保留三层并列定义、第三层展开迁入新文件；`program-overview.md` 横切件表与 `ux/_index.md` 各留一处回链 / 边界引言块；`systems/common-properties.md` 的翻译重组装纪律本体迁入新文件。「展示层三层切分」ADR 候选的固化主落点定为该文件。（归档去向：`systems/viewmodel.md`）

# Answer log translation-key-rollout-and-content-localization

- 日期：2026-08-13
- 来源：`inbox/solution-draft-translation-key-rollout-and-content-localization.md` → `handoffs/2026-08-13-translation-key-rollout-and-content-localization.md`
- 移出条数：**2**（整条答结 2 条；另有 1 条**缩范围**、1 条**解除牵连**，均留在清单内，记于文末）

---

**翻译键的铺开节奏（`open-questions/05-service-contracts.md`，08-12 新增）** → **答结。** 「逐屏改造如何排期」这个提法被**否掉**——它默认了一个不存在的存量迁移场景（`game-feature-branch/` 无任何 `.tscn` / `.cs`，UI 文案存量为零）。定案改为一条起手纪律：**每屏从写下第一行起就用翻译键，全库不新增任何 UI 文案字面量**；「随各屏 FR 一并落地」与「集中做一次」因此**不是二选一**（前者是纪律的作用方式，后者要处理的批量迁移根本不会产生）。唯一集中做的是一次性基建 **`FR-ux-translation-foundation`**（横切、不挂任何单屏，是一切含 UI 文案的 FR 的 `depends-on`）。**键命名规范同批定下**：`SCREAMING_SNAKE_CASE` · `<PARTITION>_<CONTEXT>_<NAME>` · 一个分区一个 CSV，分区表十项且开放增补，边界写死为「分区划的是界面不是内容域」；**新立禁令：`ERR_` 前缀保留给 `code` 的机械像，人不得手写**，可执行形态 = `AuditTranslations()` 改为**双向**。（→ `ux/error-and-blocking-ux.md` 的「翻译键的铺开」「键命名规范」「UI 文案字面量审计」三节；目录树 → `system-overview.md`）

**内容条目自己的多语言表达形态（同分片邻域小项，08-12d 标注）** → **答结。** 形态 = **条目内嵌 `LocalizedText : Resource`**（`Entries: locale → 文本`），同一个 `Id`、同一个 `.tres`。三条采纳理由：加一门语言 = 加一个 `.tres` 键、零代码改动；它是「改既有条目字段值」⇒ **overlay 可热更**（线上补英文不发版）；语言解析只有一个入口。**否决三个替代**：每语言一套 `Id`（撞「只改不增」· 污染抽取池权重 · 切语言使存档引用悬空）· 内容文案塞进 `res://text/`（08-12d 四问判据已判，且把可热更降级为要发版）· 每语言一个 `[Export]` 字段（把语言数焊进 C# 类）。**失败语义分方向**：默认语言缺失 → 合并后 `PushError` + `throw`；非默认语言缺失 → **读取侧静默回落 + 一次性覆盖率审计**。**语言范围封顶中英双语**（无地区码、不设 `zh_TW`，繁体走简繁转换），由此可加一条 locale 拼写校验。**两层共用同一个语言开关**，归一在启动期单点完成。**排期：与 `DrawPool<T>` 同批，第二阶段开工前、第一份内容 FR 之前。** 不 bump 存档 schema、无迁移、抽取池零影响。（→ `systems/common-properties.md`「内容文本的多语言形态」+「展示字段的归属」类型订正；校验与审计 → `systems/services/content-service.md`；两层对照表 → `ux/_index.md`）

---

## 未移出但发生变化的两条

- **英文占位符的具体形态（`open-questions/deferred-content.md`）—— 缩范围，仍待答。** 内容层一侧已答定为「**缺 `en` 键即未翻译**」，问题范围**仅剩 `res://text/` 的 CSV 一侧**；并附一条约束：若占位符取键名本身，`AuditTranslations()` 须能识别它，否则英文覆盖率恒读作 100%。
- **剧本内容的体积与分发粒度（`open-questions/04-hidden-attributes-plot.md` / `plot-manager.md`）—— 解除牵连，仍待答。** 语言维度已答定为**全语言内嵌、不按语言分包**（双语封顶 ⇒ 体积上限固定 ×2，分包动机消失），该问题回归其原本形态「剧本树该不该按篇章分包」，与语言维度互不牵动。

## 新增待答 1 条

- **Godot 4.7 上 `Control` 自动翻译（`auto_translate_mode`）的默认行为**（`open-questions/05-service-contracts.md`，挂在 `#if DEBUG` 实测项下同批）——纯落地写法确认，两种结果下键形态 / 分区表 / 两条审计完全相同，不阻塞任何定案。

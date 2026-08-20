# Answer log translation-english-placeholder

- 日期：2026-08-19
- 来源：`inbox/solution-draft-translation-english-placeholder.md` → `handoffs/2026-08-19-translation-english-placeholder.md`
- 移出条数：1

**`res://text/` CSV 侧英文占位符的具体形态** → **`en` 单元格留空，不写任何哨兵值**（与内容层「缺 `en` 键即未翻译」同一条判据的第二次兑现）；配 `project.godot` 的 `internationalization/locale/fallback = "zh"` 承接运行时回落、调用点零分支；新增 `TranslationAudit.AuditCoverage()` 做全分区覆盖率审计（三判据：未翻译 / 伪翻译含 CJK / 已翻译），三条审计的数据源统一为 `TranslationServer.GetTranslationObject(locale)` 的消息表，调用顺序 `AuditTranslations()` → `AuditCoverage()` → CJK 字面量审计。（归档去向：`ux/error-and-blocking-ux.md`）

> **同源条目只答定了一半。** 该待答项原为复合条目「英文占位符的具体形态**与错误文案的实际措辞**」；**逐条中文措辞仍留在待答清单**（属内容充实，不阻塞结构落地）。

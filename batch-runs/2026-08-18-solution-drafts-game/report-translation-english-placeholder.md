# report — translation-english-placeholder

## 方案草稿：尚未翻译的英文条目该以什么形态存在，才能让覆盖率审计判它为「未翻译」

- library: `game-design-documents`
- file: `game-design-documents/inbox/solution-draft-translation-english-placeholder.md`（**未**登记台账，台账行见下，由 orchestrator 代笔）
- 依据构成：**既有推演 4 项 · 通行做法 1 项 · 取向选择 3 项**

### 建议要点

- **占位形态 = `en` 单元格留空**，不写任何哨兵值（`KEY,"中文",`）。与内容层已答定的「`Entries` 只有 `zh` 键」是同一条判据的两次兑现 ⇒ 覆盖率审计**不需要第二套「什么算占位符」的识别规则**。
- **两条连带禁令**：`en` 列绝不复制 `zh` 原文、绝不写键名本身——这两条正是覆盖率虚高的仅有两条路径，且都零症状。
- **运行时回落靠 `project.godot` 增设 `internationalization/locale/fallback = "zh"`**，调用点零分支；与 `LocalizedText.Get()` 静默回落一致。**不留痕、不逐次警告**（占位阶段每条都会命中）。
- **`AuditTranslations()` 侧加第三条判据（覆盖率）：** 未翻译 = 键不在 `en` 消息表中**或**值为空 / 全空白；伪翻译 = `en` 值含 CJK → `PushWarning` 且不计入分子；其余计入分子。输出与内容层 `en: 12 / 840` 同形。
- **「缺键 或 空值」是刻意的双判据** ⇒ 本方案**不依赖也不被** `auto_translate_mode` / CSV 导入器实测阻塞。
- **闸门只加一条**：`zh` 列为空 → 启动期 `PushError`；`en` 缺失一律不阻塞；不加编译期闸；不加 editor 守卫（改用消息表数据源后导出包内同样成立）。
- **顺带订正 `ErrorText.For`**：「一级键缺条目才 `PushWarning`」须明确为**按默认语言 `zh` 列判**，否则英文 locale 下每个 `code` 都会报一次 `missing translation`。这是落地的必要前提。
- **否决四种占位形态**：键名本身 · `TODO` 哨兵 · 机翻初稿 · 复制中文（理由见草稿「备选方案」）。

### 张力 / 前置依赖

- **张力 1 条：** `ux/error-and-blocking-ux.md` 把反向审计写成「扫 `errors.csv`」，但 `.csv` 是导入源文件、不随导出包分发——与该文档自己为 CJK 字面量审计写下的理由逐字同构。建议三条审计数据源统一改为 `TranslationServer.GetTranslationObject(locale)` 的消息表（反向的前缀匹配判据一字不改）；替代是双双加 editor 守卫。两条路径下占位形态与三条判据均不受影响。
- **前置依赖：无阻塞性前置。** 弱依赖：逐条中文措辞待文案定稿（填 `zh` 列，与 `en` 列形态互不牵动）。
- 不 bump schema、无迁移、不触碰后端报文、**无跨库影响**、overlay 权限不变。

---

## 台账行

`inbox/_index.md` 的「在办清单」表头为 `文件 | status | 说明`，当前是 `| *（空）* | — | — |` 占位行，应被替换。

```
| `solution-draft-translation-english-placeholder.md` | `awaiting-review` | 英文占位符形态：`en` 单元格留空（与内容层「缺 `en` 键」同构）+ 覆盖率审计三条判据 + fallback locale。评审 3 项取向后 `/analyze-new-ideas` |
```

---

## 仍需用户决定（结构化）

### A. 覆盖率审计的落点与命名
- **【问题陈述】** 覆盖率审计要扫全部 `res://text/` 分区，而 `ErrorText` 只服务 `ERR_` 分区。这条新审计放哪里？
- **【选项 + 后果】** 选项 1：新增 UI 层静态入口 `TranslationAudit.AuditCoverage()`，与 `ErrorText.AuditTranslations()` / CJK 字面量审计同处启动期依次调用 → 职责清晰；启动期审计由两处变三处，需明写调用顺序。选项 2：作为第三条塞进 `ErrorText.AuditTranslations()` → 调用点唯一、改动最小；但 `ErrorText` 膨胀为「全库翻译门面」。
- **【推荐 + 理由】** **选项 1。**「按它服务于谁定位」正是文档为「`ErrorText` 不放 `src/Core/`」写下的判据；且覆盖率审计与错误码处置表零耦合。

### B. `zh` 列为空时是否 `throw`
- **【问题陈述】** 内容层默认语言缺失定为 `PushError` + `throw`。UI 键侧要不要完全对称？
- **【选项 + 后果】** 选项 1：只 `PushError` + 键名 + 分区文件 → 与内容层不对称，需写明理由；不打断开发。选项 2：`PushError` + `throw` → 纪律最硬；漏填一条中文即游戏起不来。
- **【推荐 + 理由】** **选项 1。** 内容层 `throw` 是因坏内容会进抽取池 / 被存档引用（不可逆扩散）；缺一条 UI 文案只影响一屏显示，回落后仍可操作——`null-check-rules.md` 两种失败语义的分界所在。

### C. 伪翻译（`en` 含 CJK）的处置档
- **【问题陈述】** `en` 列被填入含中文的值（典型：整列复制），报多重？
- **【选项 + 后果】** 选项 1：`PushWarning` + 不计入分子 → 不打断，覆盖率如实显示未翻译。选项 2：`PushError` → 更硬；但与「`en` 缺失不阻塞」在同一维度给出两种严厉度，纯符号 / 数字条目理论上可误报。
- **【推荐 + 理由】** **选项 1。** 它与「`en` 缺失」本质同一件事，只是形态更隐蔽；处置档理应相同。

---

## 越界发现

1. **`ErrorText.For` 的「一级键缺条目才 `PushWarning`」措辞含糊**（未说明按哪一列判）——订正已写进草稿（属本问题必要前提）；若只采纳占位形态而不采纳订正，落地会立刻踩到。
2. **反向审计的数据源问题**（`.csv` 不随导出包分发）——已作为张力写进草稿，但它**同时影响正向审计**，严格说是独立于本问题的既有缺陷，orchestrator 可考虑是否单列一条待答。
3. **`auto_translate_mode` 实测项** —— 未处理；本方案刻意设计为不依赖它。
4. **逐条中文措辞**（四条兜底 + 各 `ERR_*` + `reasonKey` 二级措辞）—— 未处理，属内容充实。

# Answer log echo-validation-scope

- 日期：2026-08-22
- 来源：`inbox/solution-draft-echo-validation-scope.md` → `handoffs/2026-08-22-echo-validation-scope-client-half.md`
- 移出条数：1

---

**上行整键回声校验的适用面未穷举（承重）——哪些顶层键的哪些路径受回声校验约束，客户端侧如何组装与自检**
→ **答定（客户端半）。** 受约束的顶层键由**机械导出规则**给出：某顶层键受约束 ⟺ 后端写入字段封闭表中存在以该键开头的 path ⇒ 当前恰为 `accountInfo` · `entitlement`；本库只登记顶层键这一层，逐条 path 与比较口径回链后端契约、不复述。组装规则：回声值唯一来源是最近一次 pull 的权威快照，不另存缓存、`ProfileChangeSpec` 无写入通道。回声路径**不参与读档钳制 / 缺省补齐 / 格式归一化**（缺失 / 越界 → `PushError` + 该键不进 diff + 触发一次 pull；需归一化 → 不归一化）。push 前自检落 `ProfileSyncManager` 组装出口一处，不一致 → 强制回声改写 + `PushError` + 本批照常发出；缺失分支在组装期已剔键，出口只处理「两值都在但不等」。新增一条刚性：向受约束顶层键内的对象**追加字段 = 两侧同批变更**。连带订正 `BundleGrantOrdinal` 的读档钳制（改 `PushError` + 不钳制）与「老档补默认值」口径在库内的两处表述。
（归档去向：`systems/services/sync-service.md`「后端主动写入的唯一情形」节 + 「透明路径的稳定性纪律」节 · `systems/player-profile/_index.md` 字段表 / schema 影响句 / `entitlement` 读档校验 · `systems/player-profile/account-info.md` 字段表 + 字段增删句）

**剩余未答部分：** 后端契约半（受约束 path 的恒等式表述、非整数路径的比较口径）**仍留在后端库的待答清单**（`backend-design-documents/open-questions/01-contracts.md`），本次未答定——成对采纳尚未完成。客户端半的纪律在任何一种比较口径下都成立，故不阻塞。

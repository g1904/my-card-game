# 上行整键回声校验的适用面 —— 客户端半（通则化）

- id: 2026-08-22-echo-validation-scope-client-half
- date: 2026-08-22
- topic: systems/services/sync-service.md · systems/player-profile/_index.md · systems/player-profile/account-info.md
- status: distilled
- distilled-to: systems/services/sync-service.md, systems/player-profile/_index.md, systems/player-profile/account-info.md

> ⚠ **这是一次尚未完成的成对采纳。** 本次意图横跨客户端 ↔ 后端边界，两份方案草稿都明写「须同时采纳」。
> **本批只落客户端半 + 后端库的一条承接项**，后端契约半（`contracts/profile-sync.md` §5c 的受约束 path 恒等式、非整数路径的比较口径表、`envelope.md` §8 的指路句）**仍待另跑一批**。
> 在后端半落笔之前：`backend-design-documents/contracts/profile-sync.md` §5c 明写的「`/accountInfo` 的比较口径尚未落笔 ⇒ 不得按字节相等实现」**仍然有效**，客户端侧的「不得再加工」纪律在任何一种口径下都成立，故本半不阻塞、也不预设口径。

## Intent（distilled）

把「上行时后端写入的字段只能原样回声」从 `entitlement` 一处特例升为**通则**。

**问题。** diff 语义是「顶层键出现即整键替换」⇒ 客户端只要改动某顶层键内自己写的那一半，就必然把后端写入的那一半一并提交上去。`entitlement`（兑现时提交 `bundleGrantOrdinal`）已定；`accountInfo` 是**同形的第二处**，且它由**改昵称**触发——是每次都走一遍的常规路径而非异常路径。悬着两件事：① 缺一份「哪些键受约束」的封闭登记，逐键临时判必然漏，漏掉的那一处正是客户端可静默改写后端权威字段的口子；② 客户端侧**没有任何一处**在发出之前检查过这些值，全靠「组装代码恰好没碰它们」这条隐含假设。

**落笔的六条（`sync-service.md`「后端主动写入的唯一情形」节由单例改写为通则）：**

1. **机械导出规则，不另建清单。** 某顶层键受约束 ⟺ 后端写入字段封闭表中存在以该键开头的 path ⇒ 当前恰为 `accountInfo` · `entitlement`。日后写入表加一行，该键自动进入回声约束，不需要第二次决定——两份清单必然各自漂移，而漂移形态正是这条纪律要关掉的口子。本库只登记「顶层键」这一层（`player-profile/_index.md` 字段表的写入通道列），逐条 path 回链后端契约、**一字不复述**。
2. **组装规则。** 回声值的唯一来源是最近一次 pull 的权威快照（`ProfileService` 内存态）；永不自行赋值、永不由本地历史推算、永不沿用上一次 push 的值；**不另存缓存 = 不造第二权威**。`ProfileChangeSpec` 对这些路径不提供写入通道（阶梯第 1 级：代码里根本写不出来）。
3. **回声路径不参与读档钳制 / 缺省补齐 / 格式归一化。** 三情形处置表：缺失 → `PushError` + 该顶层键本次不进 diff + 触发一次 pull；越界 / 不合法 → 同上、**不钳制**；需归一化 → **不归一化**，按原值提交。客户端自己写的那一半照常钳制（`BundleRedeemedOrdinal` 两向不变——它读 `Grant` 只是读、不写回）。
4. **push 前自检**落在 `ProfileSyncManager` 组装出口**一处**：不同 → **用快照值强制改写 + `PushError`（path / 快照值 / 组装值）+ 本批照常发出**。缺失分支不在此处理（组装期已剔键），出口只面对「两值都在但不等」。自检不替代后端校验——它防的是客户端自己的 bug，且客户端无法从一次 `sync.conflict` 分辨「多设备」与「我改写了后端字段」，可观测性只能由本地自检承担。
5. **判据一句消解表面张力：** 「客户端侧不新增任何分支」约束的是**收到 `Conflict` 之后**，自检发生在**发出之前**，两者不在同一层。不新增 `OpError` / `SyncState` / 错误码映射行。
6. **新刚性（「透明路径的稳定性纪律」节追加）：向受约束顶层键内的对象追加字段 = 两侧同批落笔的变更。** 客户端强类型往返（`BoundIdentity`）会静默丢掉未知字段 ⇒ 回声当场失败，故与「移动 / 重命名一条透明路径」同档，不适用「后端加字段零配合」。

**连带订正两处库内相抵的既有句：**

- `player-profile/_index.md` 的 `BundleGrantOrdinal` 读档校验：`< 0` 由「`PushWarning` + 钳制到 `0`」改为「`PushError` + 该顶层键本次不进 diff + 触发一次 pull，**不钳制**」。它是后端写入封闭表内的路径 ⇒ 钳出来的值一旦回声上行就稳定招致整批拒绝；且该段本就写着「不把它反过来抬高」，`< 0 → 0` 这一向同样是写，措辞原本自相矛盾。
- 「老档缺字段以默认值补齐」的口径在库内**两处**：`account-info.md` 的字段增删句、`player-profile/_index.md` 的 schema 影响句（点名 `AccountInfo.AccountSeed`）。**两处一并松动**为分路式，与 `account-info.md` 既有的「解析失败按必需缺失处置」措辞对齐；口径在库内出现几处就改几处，只改一处即留下第二权威。

**零 schema 影响、零迁移**——不增删任何字段，只改组装路径与读档处置。`sync-service.md` 的 bump 清单与老档补默认值列表不含 `accountInfo` 任何字段，不受影响。

## Clarifications（interview 产物）

- **本批由谁落笔对侧（后端）那一半？** → **只写客户端半 + 后端库一条承接项**，不写完整契约半。推翻草稿「本方案与 counterpart 须同时采纳」的执行安排（意图仍成立，执行拆成两批），故本文顶部显式标注成对采纳未完成。
- **`BundleGrantOrdinal` 的读档钳制怎么办？** → 改为 `PushError` + 不进 diff + 触发 pull、**不钳制**；`BundleRedeemedOrdinal` 两向钳制原样保留。细化了草稿子项 3——草稿只澄清了 `Redeemed` 不受影响，漏了 `Grant` 自己那条钳制。
- **`AccountSeed` 的补默认值口径要改几处？** → **两处一并改**（`account-info.md` + `player-profile/_index.md` 的 schema 影响句）。细化了草稿「只点名 `account-info.md` 那一句」的松动面。
- **松动后的措辞形态？** → (a) 整句改写为「客户端写入的字段补默认值（空昵称）；回声路径缺失走必需缺失处置 + 重新 pull」，**不逐项标注例外**。依据：逐项标注例外等于把删除动作写进正文，与「活文档只保留最新设计」相抵。
- **`AccountId` 要不要点明？** → **点明**「不在后端写入封闭表内、不受回声约束」。它写入方是后端却不在表内，读者按「后端写的都受约束」会导出一份多一行的错误清单。纯消歧，不改任何机制。
- **裁决 A 与「缺失即剔键」的合成顺序？** → 按 (a) **写死顺序**：组装期先判缺失（缺失即剔键，根本进不到出口），出口断言只处理「两值都在但不等」。依据：断言点落在出口**一处**，让它承担两种处置就与「多于一处必然出现半配置态」的同构论证相冲。
- **改昵称失败窗口要不要 UI 表现？** → **不进 UI**，纯内部分支 + `PushError` 台账。`ux/` 不进本次改动面。依据：草稿子项 6 明写不新增错误码映射行，引入 UI 表现即需要一个翻译键。
- **草稿「前置依赖」一节已过时（stale），未按原样提炼。** 实地核实：后端 `bundle-grant-ordinal-authority` 已归档、回声规则本体已落 `contracts/profile-sync.md` §5c、本库 `sync-service.md` 的回链现已有效。草稿称「该回链目前指向一处不存在的内容」「本方案无从采纳」两句均已不成立。

## Open questions

- **后端契约半仍待落笔**（受约束 path 的恒等式表述、非整数路径的比较口径：时间串按时刻还是按字面 · 数组按序还是按集合）。它是后端库的取向问题，裁决权在用户；本库的「不得再加工」纪律在两种口径下都成立，故不阻塞客户端半。承接项已落 `backend-design-documents/open-questions/01-contracts.md`。

## Notes / triage

- 来源：`inbox/solution-draft-echo-validation-scope.md`（`/provide-solution-draft` 产物，三项取向已于批量评审全部裁决）。对侧同名草稿仍待处理。
- 本次**不触及任何 ADR**：`ADR-0023` 只讲「谁有权推进序号」与「客户端置位当场失败」，不含读档钳制与补默认值口径，与本方案同向；`ADR-0003`（云端权威）被本方案加强而非削弱。`decisions/` 零改动。
- 与 `.claude/rules/state-save-rules.md` 相容：把回声路径的缺失从「静默补默认」抬为「`PushError` + 显式重取」，是该规则「缺失字段必须以清晰的错误 / 迁移处理」的更严实现；「绝不在较旧的存档上崩溃」也满足（处置是剔键 + 重 pull，不抛不崩）。

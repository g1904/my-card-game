# Answer log enemy-ai-field-shape

- 日期：2026-08-28
- 来源：`inbox/solution-draft-enemy-ai-field-shape.md` → `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md`
- 移出条数：3（均出自 `systems/enemies/common-properties.md`「## 待决问题」的主题文档待决项「敌人数据 schema 的其余字段：立绘 / 台词 / 音效引用……未定义」，不在任何 `open-questions/` 分片中）

---

**敌人条目的立绘引用未定义** → 答定为顶层内容共有字段 **`Artwork : Texture2D`**（`[Export]` 直接资源引用、可空默认 `null`、挂载面七类；本层 = 敌人立绘，投影段落在敌人侧）。（归档去向：`systems/common-properties.md`「### 内容共有字段 `Artwork: Texture2D`」+ `systems/enemies/common-properties.md` 的投影段 + `systems/enemies/_index.md` 字段总表）

**敌人条目的台词引用未定义** → **形态**答定为 `Lines : EnemyLine[]`（稀疏覆写数组 + 内嵌 `Resource`：`LineSlot Slot` + `LocalizedText Text`），三条加载期校验一并落定；**`LineSlot` 的成员清单仍待答**，待一次战斗 UX 专场，故该问题**收窄而非整条关闭**——收窄后的待决项留在 `systems/enemies/common-properties.md`「## 待决问题」。在成员答定前 `Lines` 对任何条目都只能是空数组。（归档去向：`systems/enemies/_index.md`「### 敌人台词 —— `Lines`」+ `systems/enemies/common-properties.md` 的字段表与校验分档）

**敌人条目的音效引用未定义** → 答定为 **不为敌人条目开字段**。依据：音频六类目无一条按敌人条目逐条产出；敌人级独有的只剩「入场吼叫」一类且其存在性在全库无表述；多数玩家静音游玩、音频不得是承载信息的唯一通道 ⇒ 敌人级音效只属演出层。恒无对象的伸缩位会让每个消费点都要处理一个永不发生的分支。日后确有需求是纯加法。（归档去向：`systems/enemies/common-properties.md`「## 待决问题」下的已判定段 + 回链 `art/soundtracks/_index.md`）

---

**同批一并答定、但原不在任何待答清单上的一项（草稿新发现，记录备查）：**

**`AiWeightVector` 在全库只被使用、从未被定义** → 补齐为 `readonly struct`（索引 `(int)AiTerm`、长度恒 == `AiTerm` 成员数），由 ContentRegistry 在 `LoadAll()` 内从 `CombatRulesData.AiFallbackWeights` 一次性展开、落派生索引；有效权重的合并语义只写在 `ChooseAction` 契约旁一处。纯运行时产物，不落 `.tres` / 不落存档 / 不 bump schema。（归档去向：`systems/services/combat-service.md`）

**本次新增、仍待答的项**（不属移出，登记于此便于交叉查阅）：二进制资产是否可经 overlay / blob 通道下发 → `open-questions/deferred-content.md`，对侧承接项见 `backend-design-documents/contracts/content-manifest.md`。

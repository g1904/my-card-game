# Answer log bound-technique-initial-tier

- 日期：2026-09-02
- 来源：`inbox/solution-draft-bound-technique-initial-tier.md` → `handoffs/2026-09-02-bound-technique-initial-tier.md`
- 移出条数：1

## 移出的条目

**两门绑定功法的初始层数（08-30 新增）** → **恒为 1，`CharacterData` 不加字段。** 四条依据：① 「入组」的层数已有唯一既定语义（`LearnTechnique` 明文 `Tier = 1`），绑定功法与闭关 / 商店学到的那门在卡组里是同一种东西；② 开局底盘三门功法（2 绑定 + 1 选来）因此起手层数一致，不出现「同为开局给的两门比第三门强一档」这种卡面可见的落差；③ 逐条编排是一条**纯强度**的角色间差值，与「灵根把差异推向能修哪一路、不推向谁更强」相抵，并与已登记的「角色强度差可能塌缩为单一最优」叠加；④ 起始层数的上界是仍待校准的 `MaxTier`，逐条编排此刻只能定结构、定不出取值，阻塞面不会真正解除。字段面零增量、加载期校验零新增、存档 / 后端零影响。逐条编排（`BoundTechniques : BoundTechnique[]`，元素带 `InitialTier` 默认 1 + 三条加载期校验）作为**纯加法退路**写进文档、本次不实现。（归档去向：`systems/character-profile/_index.md`、`systems/character-profile/deck/_index.md`）

## 同批裁决（本身不在待答清单上，故不计入移出条数）

- **`CharacterData` 字段表第 8 行的处置** → **删行，不留空行占位**；结论改由「明确不带的格」一条承载（同 `Rarity` / `ExclusiveSource` 的既有写法）。
- **`systems/character-profile/_index.md`「待决问题」小节里同条的重复登记** → **一并删除**（同一条不得一边写明文、一边列为待答）。

## 未随本次移出

- **全池指定下角色强度差是否仍塌缩为单一最优** —— 待实测，原样留在 `open-questions/06-meta-progression.md`。本条只是不给它再加一个输入。
- `content/character/` 条目写到 `ready` **仍另阻于**功法条目（10 门）与神通条目（5 个）尚不存在 —— 本条只解除三个前置里的一个。

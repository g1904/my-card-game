# Answer log character-template-pool

- 日期：2026-08-30
- 来源：`inbox/solution-draft-character-template-pool.md`（裁决 2026-08-28）+ `inbox/solution-draft-affinity-and-technique-attributes.md`（裁决 2026-08-29，覆盖池规模一项）
- 移出条数：1

---

**角色模板池的形态（池中有几个角色 / 是否账号级逐步解锁 / 能否重抽或指定）** → 三问全部答定：

- **选取机制 = 开局由玩家从全池指定**，取代既定明文「开局随机分配一个角色」；无随机候选集、无重抽通道、完全不涉及 RNG。服务面 = `CycleStartSpec` 加一格 `CharacterDataId` + 一个纯只读查询；校验「所选 ∈ 可抽取池」。
- **池规模 = 5**（08-28 裁的 4 被 08-29 的灵根裁决覆盖，五行各一）。它不是数值旋钮，而是 `content/character/` 里 `ContentEnabled == true` 的条目数，不进 `systems/balance.md`。内容量账 = 5 神通 + 10 门绑定功法 × `MaxTier`。
- **首批不做账号级逐步解锁**，全部角色恒可用；含负面边界「解锁绝不可做成付费点」与日后要做时的最小路径。

归档去向：`systems/character-profile/_index.md`（池形态段 + `CharacterData` 字段面 + 十一条加载期校验）· `systems/services/life-cycle-service.md`（`CycleStartSpec` 与只读查询）· `ux/screen-flow.md`（角色选择屏）· `ux/onboarding.md`（零选择负担段的例外与缓解）· `terminology.md`（角色（模板）行）· `decisions/ADR-0055-character-as-content-template.md`（「后果」首条收口）。

**同批新增的三条待答项**（不由本次答定）：两门绑定功法的初始层数 · 全池指定下角色强度差是否仍塌缩为单一最优 · 多灵根角色的强度对齐换算。

**灵根主题在待答清单中原本零承载**，故 `solution-draft-affinity-and-technique-attributes.md` 本次从 `open-questions/` 移出 0 条，不单独建 log；它的裁决记录见 `handoffs/2026-08-30-affinity-and-technique-attributes.md` 的 Clarifications。

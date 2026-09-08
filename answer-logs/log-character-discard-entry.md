# Answer log character-discard-entry

- 日期：2026-09-06
- 来源：`inbox/solution-draft-character-discard-entry.md` → `handoffs/2026-09-06-active-discard-entry.md`
- 移出条数：1

## 逐条

**主动弃置的发起入口（09-02 新增）：玩家从哪一屏、以什么形态弃置一个角色（主菜单还是轮回内、是否二次确认、是否有冷静期）** →

- **入口唯一落在主菜单「切换篇章」面上**，挂在该篇章那一行 `ongoing` 角色旁，与主动作「继续」并列的一个次级动作；**不新增屏、不新增主菜单入口**。
- **轮回内不设第二个入口**（用户裁决 A）：轮回内入口在实现上等价于「取消到最近决策点 → `Immediate` flush → 弃置」，与「退出到主菜单再弃置」是同一条链；且全库无暂停屏、设置屏已被明令排除。
- **只对 `ongoing` 开放**（用户裁决 A）：不允许弃置 `completed` 的可挑战角色，**不新增 `completed → defeated` 转移**，状态机一格不动。用户是在已知两条本使天平偏向反向的新前提（ch3 `completed` 永久保留完整档；`completed → ongoing` 已是合法转移）下仍选 A。**被接受的代价：已通关角色档没有任何清理通道，会持续累积。**
- **就地二段确认**，复用本库唯一的确认语言（不新开屏、不新增弹层、不发明第三种）；第二段一行后果含角色名 · 弃置后剩余重试次数 · 不可撤销。ch1 走不含次数的键；**剩余为 0 时走新增的第三条键 `MENU_DISCARD_CONFIRM_DESC_LAST`**，改说「该篇章将不再可挑战」（用户裁决）。`MENU_` 分区由 4 键增为 5 键。
- **无冷静期、无撤销通道**（冷静期内闸仍占着，功能等于没做成）；弃置键恒可用、不置灰，不新增拦截点。
- **中文 UI 措辞用「放弃此角色」**，功法侧「弃置」保留不动，`terminology.md` 补一行区分（用户裁决）；`DefeatReason.Discarded` 与 `MENU_DISCARD_*` 键名不变。
- **`DefeatCharacter` 签名扩为 `(DefeatReason reason, string characterId)`**，两个既有调用点各传当前角色 `Id`；它进入「不收 `character` 参数」通则的显式例外表。一次事务，**零新增字段 / 存档点 / flush 点 / `schemaVersion` bump，后端零配合**。
- **旧签名与已答定的待定项就地订正**（用户裁决）：`decisions/ADR-0148-cycle-end-screen.md` 换新签名 + 其「主动弃置入口全库无明文」待定项改写为已承载；`program-overview.md` 阶段 5 流程图两处签名跟改。**结论一格不动、不新增 ADR 编号、不动 `decisions/_index.md`。**

归档去向：`ux/screen-flow.md`（主菜单段新增「篇章切换面上的主动弃置入口」+ 轮回结束屏触发行与时点 bullet）· `systems/services/life-cycle-service.md`（契约表 + 四点推演例外表 + 新增「主动弃置的调用点与时序」+ 三层处置的方法语义行）· `terminology.md`（新增「放弃（角色）」行）· `program-overview.md` · `decisions/ADR-0148-cycle-end-screen.md`。

**未答定、仍留在待答清单的部分：无**（该条整条答定）。

# Answer log cycle-end-screen

- 日期：2026-09-02
- 来源：`inbox/solution-draft-cycle-end-screen.md` → `handoffs/2026-09-02-cycle-end-screen.md`
- 移出条数：1

**死亡 / 轮回结束屏尚无设计（三因是否分别呈现、呈现在哪一屏、承载什么信息）** → 一屏三变体 `CycleEndScreen`，只承载 `defeated` 三因。载体 = 一屏全屏、不进屏幕栈、无返回路径、非弹层；触发 = `DefeatCharacter(reason)` 提交完成之后；数据源 = 清理之前组装的只读值摘要（不持 `CharacterProfile` 引用）。承载定性文案 + 结果三行（境界 + 篇章 · `pastEvent.Count` · `Status.lifeSpan`）+ 剩余重试行（ch1 走「无限」键）+ 唯一主按钮「返回主菜单」。商业化零入口、残卷零呈现、同步指示常驻可见、无自动跳转 / 倒计时 / 二次确认、不新增存档点。新增 `CYCLE_` 分区 / `cycle.csv`。（归档去向：`ux/screen-flow.md`「轮回结束屏」· `ux/error-and-blocking-ux.md` 分区表 · `systems/services/life-cycle-service.md`）

**本轮回回顾的深度** → 极简三行；寿元曲线不进第一版（数据与算法均已就位，随时可加）。（归档去向：`ux/screen-flow.md`）

**是否在本屏呈现本轮回的账号级收获（图鉴 / 成就）** → 不呈现；阶段 5 的既定编排顺序（成就结算在 `TeardownCycle` 之后）一字不动。（归档去向：`ux/screen-flow.md`）

**「渡劫身死」定性文案的落点** → 由 `ResolveOutcome` 改为按 `DefeatReason` 定位、由轮回结束屏呈现。理由：`ResolveOutcome` 覆盖不到 `Discarded`（不经事件收口）与走终态判定 ① 的 `LifeSpanExhausted`（无 `eventEnd`）。**跨档叙事的 `ResolveOutcome.BandNarrativeIds` 通道原样保留**，`Practice` 档战斗失败的定性文案同样不受影响。（归档去向：`systems/services/plot-manager.md`）

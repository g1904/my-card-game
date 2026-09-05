# Answer log plot-branch-choice-ui

- 日期：2026-09-02
- 来源：`inbox/solution-draft-plot-branch-choice-ui.md` → `handoffs/2026-09-02-plot-branch-choice-ui.md`
- 移出条数：1

**DnD 式选分支的触发点与 UI（何时、哪一屏、可见 / 不可见的边界）** → **触发点** = `eventEnd` 那一次 `TryApply` 提交之后（落进五步组装之内会引入需持久化的中间态，另设时机等于给剧本层开第二个出口）；**屏** = 既有事件结算面板内追加一段「剧本段」，不新增屏、不新增弹层，有分支时「继续」不出现、位置由全宽分支按钮占据（零额外点击），纵向堆叠不横滑、不截断、无二次确认 / 跳过 / 默认选中 / 超时；一次收口至多呈现一条 arc（序 = `Tier`，同 `Tier` 按 `ArcId` 字典序），与跨档叙事同屏时叙事行在上；终态时整段不渲染、直接走轮回结束屏。**可见 / 不可见的边界** = `BranchLabel` 非空 ⟺ `Condition.Kind == BranchChosen`（异或即 `PushError`）+ 三条内容编排判据（当下可理解的承诺 · 调制上真分岔 · 不依赖读出隐藏量），其余一律写成自动边；`BranchLabel` 含属性名 / 数字 / 档位序号 → `PushWarning`。存档 schema 零改动。（归档去向：`ux/screen-flow.md`「事件结算面板的剧本段」· `systems/services/plot-manager.md`）

**分支段是否带「这是一次剧情抉择」的显式标识** → 不标识；与结算面板其余部分同一视觉层级，剧本层继续保持隐匿。（归档去向：`ux/screen-flow.md`）

**剧本正文 `PlotNodeData.Body` 落哪一屏（纯叙事节点是否也落结算面板）** → 一并定：剧本段 = 正文（可空）+ 分支（可空），无分支时正文 + 既有的「继续」。不新增任何呈现面。（归档去向：`ux/screen-flow.md`）

**「一次 `eventEnd`，每条 arc 至多前进一个节点」与 `ChooseBranch` 独立提交的张力** → 重述为「一次 `eventEnd` **之内**至多前进一个节点」，行为零改动；两步之间无 eventOptions 重算且第二步是玩家输入，防自动连跳的承重理由未被削弱。（归档去向：`systems/services/plot-manager.md`）

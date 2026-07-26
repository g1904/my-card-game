# 寿元数值化 · 服务层重命名（+future-event-service）· character-profile 结构定案 · 全库遗留清理

- id: 2026-07-25-lifespan-service-refactor-and-legacy-cleanup
- date: 2026-07-25
- topic: terminology, services/life-cycle-service（原 run-manager 重命名）, services/adventure-plot-service（原 adventure-plot 重命名）, services/future-event-service（新增）, game-progression, character-profile, Context.md/README（治理约定）, open-questions
- status: distilled
- distilled-to: terminology.md, 20-systems/services/life-cycle-service.md, 20-systems/services/adventure-plot-service.md, 20-systems/services/future-event-service.md, 20-systems/adventure-event/common-properties.md, 20-systems/game-progression.md, 20-systems/character-profile/_index.md, 20-systems/architecture.md, 20-systems/balance.md, 20-systems/_index.md, 50-decisions/ADR-0002/0003/0004（重构）, 50-decisions/_index.md, 50-decisions/_TEMPLATE.md, .claude/rules/Context.md, README.md, open-questions.md, 10-handoffs/_index.md, 全库活文档遗留清理

## Intent（distilled）

一次混合意图的草稿：一项新玩法数值（寿元）、一次服务层命名重构、一处结构定案，以及一条改变文档维护方式的治理约定。

### 1. 寿元 / lifeSpan 数值化（计数器模型）
- **寿元是一个计数（count），按境界递增预算：** 炼气起始寿元 = **100**；抵达 **筑基 +100**（累计 200）；抵达 **金丹 +300**（累计 500）。这些增量在境界突破（realm-up / Finale）时授予。
- **可见性阶梯：** 寿元**初始隐藏**；当**低于 10%** 时才在屏上显示；**归 0 → 角色 defeated**。
- **递减机制 = 按 AdventureEvent 扣减 `lifeSpanCost`（默认 -1）。** 每完成一个 AdventureEvent，按该事件的 `lifeSpanCost` 扣减寿元；**基准值为 -1**（推进一个修行事件默认消耗 1 点寿元），个别事件可覆写为更大 / 更小 / 正值（回寿）。`lifeSpanCost` 是 AdventureEvent 的共有字段；基准值为可调平衡数值。
- **这修订了先前表述（矛盾已裁定）：** 旧文写「寿元**增长到阈值**触发『大限将至』」。新模型是**递减到 0** 的寿命预算：0 = 大限将至 = `defeated`。据此解掉了「『大限将至』触发后果（defeated？转 Finale？）」这一 Open question → **defeated**。
- 寿元仍是 `CharacterProfile.Status` 内、独立于血量 `life` 的隐藏属性，由 adventure-plot-service 驱动、被 AdventureEvent 推拉。

### 2. 服务层重命名 + 新服务
为让服务职责更清晰，重命名三个服务并新增一个：
| 旧名 | 新名 | 职责 |
|------|------|------|
| adventurePlot / `services/adventure-plot.md` | **adventure-plot-service** / `services/adventure-plot-service.md` | 隐藏剧本层 API |
| possibleFutureEvent（原 AdventureEvent 上的图字段/概念） | **future-event-service**（新）/ `services/future-event-service.md` | 依据当前 characterProfile **产出 eventOptions**（可选事件集） |
| run-manager / `services/run-manager.md` | **life-cycle-service** / `services/life-cycle-service.md` | Run 生命周期 API |

- **future-event-service = 依当前 characterProfile 计算 eventOptions 的服务。** `eventOptions` = 一组当前可选的 `AdventureEvent`，玩家从中择一以推进游戏。
- **eventOptions 循环：** 每完成一个事件后，future-event-service 依据更新后的 characterProfile **重新计算**一批新的 eventOptions 供玩家再次选择。这把先前「possibleFutureEvent 图字段」正式提升为一个**服务化的生成面**（生成/加权机制仍为 Open question，但架构侧已定为服务）。

### 3. character-profile 结构定案（解一个 Open question）
- **deck 与 item 为文件夹**——因为除规则外，未来还要容纳**内容设计**（起始卡组 starter decks、道具设计 item designs）。
- **life / currency / mana 为扁平 `.md`**——它们是系统性资源（systematic resource），预期规则足够短，暂以单文件承载。
- 据此解掉「character-profile 结构不一致（是否统一升为文件夹）」的 Open question。

### 4. 治理约定变更：一切皆可改 · 只保留最新设计（全库清理 + ADR 重构）
- **一切皆可改：取消全部「仅追加 / 不可变」根约定。** 软件开发尚未开始，本库**没有任何文档是仅追加或一旦定案即不可变的**——`10-handoffs/`、`90-inbox/`、`50-decisions/` ADR 均可自由编辑 / 重写 / 重构。**要改一份 ADR 的决定，就直接改这份 ADR，不必新开一个 ADR 去取代它。** 历史 / 回溯归 git。
- **活文档只保留最新设计与决策；不再保留/提及过时、被替换、legacy 内容，一律重写替换。** 理由：项目由 GitHub 版本控制，legacy 需要时可手动取回，留在文件里只会臃肿。
- **移除的旧约定：** `Context.md` 治理原则里「留溯源（Source / 取代说明）」子句、`README.md` 与 `50-decisions/_index.md` 的「10-handoffs 仅追加」「ADR 一旦 Accepted 即不可变」、ADR `_TEMPLATE.md` 的 immutable 注释——均已删除 / 改写为「可编辑」。
- **ADR 重构（本 session 已执行）：** ADR-0002 从「七类 + 两处 Amendment 追加」重写为**干净的九类枚举**（删除修订历史考古、possibleFutureEvent→eventOptions）；ADR-0003 删除「离线→混合→强制在线」反转叙事，只留当前决定 + 张力；ADR-0004 状态机补入「寿元归 0」为 defeated 原因。
- **落地边界（本 session 已按用户确认执行全库清理）：** 活文档（`20-systems/**`、`40-ux/**`、`00-vision/**`、`50-decisions/` ADR、`terminology.md`、`open-questions.md`、`README.md`、各 `_index.md`）删除考古（「取代 X / 并入 Y / 由 Z 拆出 / 迁入自 / 原 encounter / 重构说明 / 原始文件占位 / 旧文件保留待清理」）与对已删除文件的引用，只留最新设计；保留指向当前 `10-handoffs/*` 的简短 `Source:` 溯源。`10-handoffs/` 与 `90-inbox/` 作为时间线保留（但不再是「仅追加」，可编辑修正）。

## Open questions
- **寿元 `lifeSpanCost` 分档 / 增长途径：** 消耗机制已定（按 AdventureEvent 的 `lifeSpanCost` 扣减，基准 -1）；仍待定：哪些事件应覆写基准、是否有非境界突破的寿元增长途径、元婴阶段是否再加预算。→ `20-systems/adventure-event/`、`20-systems/balance.md`。
- **寿元 <10% 显示的 UX 形态：** 低于 10% 时「在屏上显示」的具体呈现（常驻条？告警？）未定。→ `40-ux/`（combat-ux / screen-flow）。
- **future-event-service 生成/加权：** 服务化已定，但从 characterProfile 生成 eventOptions 的**具体加权/策划规则**、与 location（地域）框定、与 adventure-plot-service 调制的叠加顺序仍未定。→ `20-systems/game-progression.md`、`20-systems/services/future-event-service.md`。
- **eventOptions vs possibleFutureEvent 图：** 服务产出 `eventOptions` 后，`AdventureEvent` 上原 `List<possibleFutureEvent>` / `List<pastEvent>` 的图字段是保留（服务读写它）还是被服务态取代？两者关系待厘清。→ `20-systems/game-progression.md`。

## Notes / triage
- 服务文件重命名：`services/run-manager.md` → `services/life-cycle-service.md`、`services/adventure-plot.md` → `services/adventure-plot-service.md`；新增 `services/future-event-service.md`。全库对旧服务路径的交叉引用已同步更新。
- 全库遗留清理为本 handoff 附带的一次性 pass（用户确认「立即全库清理」）；`Context.md` / `README.md` 的维护约定已改为「只保留最新设计、重写替换」。

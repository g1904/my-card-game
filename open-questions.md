# Open questions — 跨 session 待答清单（索引）

> 本文件是**客户端**（Godot 项目）待答清单的**索引**：问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 后端侧的待答清单在 `backend-design-documents/open-questions.md`（`backend-design` 分支）。
>
> 每次 session 结束时，未答的 Open questions 汇总到对应分片，供下次拾起；一旦答定，就从分片中移除、
> 归档进对应主题文档的 `## 待决问题` / `## 决策`，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> 本清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**。
>
> 最近更新：2026-08-16 — 体检 12 项逐条裁决 · 手牌上限 9 → 7
> （逐次变更摘要见 `open-questions/update-log.md`；已答定问题的逐条移出记录见 `answer-logs/`）

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序，**只留最近 10 条**。不含问题条目本身。 |
| `open-questions/update-log-archive.md` | 更早的更新摘要，原样归档、按时间正序。只读，不写新条目。 |
| `open-questions/01-combat.md` | **① 战斗机制**（焦点之首）：能力剥夺与统计计数的残留（片区主体已于 08-10c 答结）、结构与配置、内容与数值（多数已归 ch1 数值标杆专场）、呈现。 |
| `open-questions/02-event-options.md` | **② eventOptions 生成流程**：生成 / 加权与配比、物化字段、优先级、寿元打穿、Explore 揭示池、Travel 出场、location 与图鉴连边。 |
| `open-questions/03-adventure-event-types.md` | **③ 逐类型 AdventureEvent 机制**（五类各开一场专门 session）。 |
| `open-questions/04-hidden-attributes-plot.md` | **④ 隐藏属性 / 剧本机制**：档位阈值、跨档叙事、`lifeSpanCost` 分档、AdventurePlot 数据编码与 key points 粒度、剧本内容的数据形态与分发粒度。 |
| `open-questions/05-service-contracts.md` | **⑤ 服务契约 / 工程侧残留**：`#if DEBUG` 判据与 `Control` 自动翻译的实测、`.claude/rules/*` 的设计性表述、需求流水线形态、`Source` 在上行负载里的序列化形态。 |
| `open-questions/06-meta-progression.md` | **⑥ 元进程的失败侧与中长期规划感**：轮回内的进度感是否需要补充、1% 存活分支的叙事补白落点。 |
| `open-questions/07-codex-monetization.md` | **⑦ 图鉴族与商业化**：`CharacterPower`、六本图鉴、premium bundle。 |
| `open-questions/deferred-content.md` | **已搁置：内容充实**（07-30 起暂不推进）＋ **美术与音频（`art/`，08-04 加入）** ＋ 随内容搁置的 UX 呈现细节 ＋ 尚未设计的占位主题。 |

## 当前焦点：各系统机制细节

> **焦点判据（07-30 定）：** **规则、字段语义、流程与算法 = 机制细节 = 焦点**（分片 ①–⑦）；
> **具体条目目录与数值 = 内容充实 = 搁置**（`open-questions/deferred-content.md`）。
> 与既定开发路线「框架 → 内容 → 平衡与体验 → 社交及其他」的第 ① 阶段一致。
> Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。
>
> 焦点顺序即分片编号顺序；**① 战斗机制**优先级最高。

## derive 就绪度

> **当前：全量回滚，本库尚未进入可 derive 的阶段。** 先前逐文档的 derive 就绪度判定（07-22 ~ 07-25）已**全部作废**——设计仍在快速演进，逐次 handoff 顺带下的就绪度结论会迅速过时且互相矛盾。
>
> **就绪度不再由 `/analyze-new-ideas` 顺带评估或更新。** 它由专门的 **`/assess-derive-readiness`** 全量扫描产出，**由用户在时机成熟时手动调用**；该技能是本小节的**唯一写入者**。在它跑过之前，本小节保持「尚未就绪」。

## 下一阶段

- **ADR 状态：** 已固化——
  - **ADR-0002**（修行事件**五类**分类，五值枚举 + Combat 的 `combatTier` 三档）
  - **ADR-0003**（强制在线 · 云端权威 · 重账号）
  - **ADR-0004**（境界存档 · 重试模型，含寿元归 0=defeated）
  - **ADR-0005**（**`.claude` 是工程层、对设计只做薄引用**；07-30 由 `knowledge/` 扩到整个 `.claude`，含 rules / skills 与冲突裁决规则）

  ADR 候选：**开发顺序**（框架 → 内容 → 平衡与体验 → 社交及其他，见 `vision/scope.md`）；
  **内容载体形态**（随包基线 + overlay + 版本校验，见 `systems/services/content-service.md`）。
  （注：ADR 现可自由编辑，改决定直接改 ADR，不再新开取代 ADR。）
- **流水线闭环（07-30）：** design → code 链路补上 `/breakdown-requirements`（一份 FR → 一个文件夹的可执行子需求），完整形态见 `README.md` 与 `requirements/_index.md`。
- **架构闭环缺口：** 8 处**全部闭合**（移出记录见 `answer-logs/log-0725c.md` 与 `log-0726b.md`）；状态表见 `systems/architecture.md` 的「闭环缺口」小节。残留细节已下沉为各焦点分片的普通待决问题。

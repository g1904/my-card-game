# FR-\<parent\>-\<NN\>-\<subslug\> — \<short title\>

- id: FR-\<parent\>-\<NN\>-\<subslug\>   # e.g. FR-combat-turn-loop-01-turn-state-machine
- parent: FR-\<parent\>                  # 父 FR（本子需求由它拆出）
- date: \<YYYY-MM-DD\>
- system: \<与父 FR 相同\>
- source-docs:                           # 继承父 FR 的来源，不新增
    - 20-systems/\<doc\>.md
- status: ready                           # 继承父 FR 的签核状态：ready | draft → blueprinted | built
- blueprint:                              # /blueprint 跑过后填入 .claude/blueprints/\<slug\>.md
- depends-on:                             # 同一拆解内的其他子需求 id（构建顺序）

## User story / intent
> _一句话：这一薄切片让玩家 / 系统能做到什么。追溯父 FR，不复述整份文档。_

## Scope
**In scope**
> _本子需求覆盖的具体、可构建行为。小到一次 /blueprint 能一口吃下。_

**Out of scope**
> _明确交给兄弟子需求或后续处理的部分（点名是哪个子需求）。_

## Acceptance criteria
> _1 ~ 5 条。每条都必须能在 Godot 编辑器里运行游戏观察到。Given/When/Then。_
- [ ] Given \<state\>, when \<action\>, then \<observable result\>.

## Covers (parent criteria)
> _本子需求承担父 FR 的哪几条验收标准（引用其原文或编号）。覆盖核对的依据。_

## Data & state touchpoints
> _读/写哪些 CycleState 字段、EventBus 事件、`.tres` id 与存档点。保持在意图层面——/blueprint 负责转成类 / 场景形态。_

## Open questions
> _父 FR 下发的相关问题 + 拆解中新发现的问题。绝不在此杜撰答案。非空不阻塞 /blueprint，但必须在蓝图中被显式处理或标记为 blocked。_

## Traceability
- Broken down by `/breakdown-requirements` from: FR-\<parent\>
- Feeds: `/blueprint` → `/implement`

<!-- 一个子需求 = 一次 /blueprint 能一口吃下的薄纵切片，做完后项目仍可运行。 -->

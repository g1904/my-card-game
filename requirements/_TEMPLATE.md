# FR-<system>-<slug> — <short title>

- id: FR-<system>-<slug>          # e.g. FR-adventure-event-combat-turn-loop
- date: <YYYY-MM-DD>
- system: <systems/adventure-event/combat | systems/character-profile/deck | ux/screen-flow | ...>
- source-docs:                    # design docs this requirement is derived from
    - systems/<doc>.md
    - vision/<doc>.md          # (as applicable)
    - decisions/ADR-####.md    # (if a settled call constrains it)
- status: draft                   # draft | ready | broken-down | blueprinted | built
- signed-off-as:                  # 迁入 broken-down 时填：ready | draft（迁入前的签核状态；子需求签核规则读这一格）
- blueprint:                      # link to .claude/blueprints/<slug>.md once /blueprint runs
- depends-on:                     # other FR ids this one requires first (build order)

## User story / intent
> _一两句话：作为玩家，我能<做 X>，从而<实现 Y>。追溯设计意图，不复述整份文档。_

## Scope
**In scope**
> _本 FR 覆盖的具体、可构建的行为。_

**Out of scope**
> _刻意排除的部分（由另一个 FR 处理，或留待日后）。_

## Acceptance criteria
> _可观察、可测试的条件。每一条都应能通过运行游戏来核验。优先用 Given/When/Then。_
- [ ] Given <state>, when <action>, then <observable result>.
- [ ] ...

## Data & state touchpoints
> _本功能读/写哪些 CycleState 字段、EventBus 信号、数据资源（.tres id）与存档点。保持在意图层面——/blueprint 会把它们转成具体的类/场景形态。_

## Open questions
> _源设计文档尚未回答的任何事项。若非空，则本 FR 不是 `ready`——它需要先有一个 handoff/决定。绝不在此凭空杜撰答案。_

## Traceability
- Derived by `/derive-requirements` from: <source-docs>
- Feeds: `/blueprint` → `/implement`

<!-- One FR = one independently buildable increment with its own acceptance criteria. Split large systems into several FRs linked by depends-on. -->

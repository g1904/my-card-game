# FR-<service>-<slug> — <short title>

- id: FR-<service>-<slug>          # e.g. FR-profile-store-revision-cas
- date: <YYYY-MM-DD>
- service: <systems/profile-store | systems/account | contracts/profile-sync | operations/observability | ...>
- source-docs:                    # design docs this requirement is derived from
    - systems/<doc>.md
    - contracts/<doc>.md       # (边界行为几乎总是要引契约)
    - vision/<doc>.md          # (as applicable)
    - decisions/ADR-####.md    # (if a settled call constrains it)
- client-facing: <yes | no>       # 是否改动客户端可见的报文行为
- status: draft                   # draft | ready | broken-down | blueprinted | built
- blueprint:                      # link to blueprint once it exists
- depends-on:                     # other FR ids this one requires first (build order)

## Intent
> _一两句话：这个能力让客户端 / 运维能做到什么。追溯设计意图，不复述整份文档。_

## Scope
**In scope**
> _本 FR 覆盖的具体、可构建的行为。_

**Out of scope**
> _刻意排除的部分（由另一个 FR 处理，或留待日后）。_

## Acceptance criteria
> _可观察、可测试的条件。边界行为优先写成「给定请求 → 期望应答」。Given/When/Then。_
- [ ] Given <state>, when <request>, then <observable response / stored state>.
- [ ] ...

## Contract touchpoints
> _本功能涉及哪些端点、DTO 字段、错误码与幂等 / CAS 语义。若引入新字段，必须先在 `contracts/` 中定义——不在 FR 里发明报文。_

## Data & state touchpoints
> _读 / 写哪些持久化状态（profile 记录、`revision` 计数器、`pushId` 窗口、manifest）。保持在意图层面。_

## Failure & retry semantics
> _弱网下的行为：重复请求怎么办、部分失败怎么办、超时后客户端会重试什么。**这一段对后端 FR 是强制的**——幂等是承重设计。_

## Open questions
> _源设计文档尚未回答的任何事项。若非空，则本 FR 不是 `ready`。绝不在此凭空杜撰答案。_

## Traceability
- Derived from: <source-docs>
- 客户端侧对应文档（若 `client-facing: yes`）：`game-design-documents/systems/services/<doc>.md`

<!-- One FR = one independently buildable increment with its own acceptance criteria. -->

# Batch run — 2026-08-17 已评审草稿 ×5

## 范围（用户显式给全清单）

| 分片 | 草稿（`game-design-documents/inbox/`） | status |
|---|---|---|
| A | `solution-draft-profile-field-schema.md` | reviewed |
| B | `solution-draft-event-option-materialized-fields.md` | reviewed |
| C | `solution-draft-event-option-derived-persistence.md` | reviewed |
| D | `solution-draft-element-carrier-gaps.md` | reviewed |
| E | `solution-draft-draw-pool-and-instance-shapes.md` | reviewed |

主库：`game-design-documents/`（全部 5 份）。
对侧库牵连：`backend-design-documents/inbox/solution-draft-profile-field-schema.md`（分片 A 的 `counterpart`，`status: awaiting-review`，**不在本批**）→ 进合并 interview 由用户裁决是否同批处理。

## 写入面推算（各草稿 frontmatter `targets`）

| 目标文档 | A | B | C | D | E |
|---|---|---|---|---|---|
| `systems/services/profile-service.md` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `systems/architecture.md` | ✓ | ✓ | | ✓ | |
| `systems/services/future-event-service.md` | | ✓ | ✓ | | ✓ |
| `systems/character-profile/_index.md` | ✓ | | ✓ | ✓ | |
| `systems/adventure-event/common-properties.md` | | ✓ | ✓ | | ✓ |
| `systems/services/plot-manager.md` | | ✓ | | ✓ | ✓ |
| `systems/services/sync-service.md` | ✓ | | ✓ | | |
| `systems/services/life-cycle-service.md` | | ✓ | ✓ | | |
| `systems/player-profile/_index.md` | ✓ | | | | |
| `systems/player-profile/game-setting.md` | ✓ | | | | |
| `systems/adventure-event/combat/_index.md` | | ✓ | | | |
| `systems/balance.md` | | ✓ | | | |
| `systems/adventure-event/explore/_index.md` | | | ✓ | | |
| `systems/adventure-event/exchange/_index.md` | | | ✓ | | |
| `systems/character-profile/deck/_index.md` | | | | ✓ | |
| `systems/adventure-event/exchange/common-properties.md` | | | | ✓ | |
| `systems/services/content-service.md` | | | | | ✓ |
| `systems/player-profile/player-power/_index.md` | | | | | ✓ |
| `systems/monetization.md` | | | | | ✓ |
| `systems/enemies/_index.md` · `systems/enemies/common-properties.md` | | | | | ✓ |
| `systems/game-progression.md` | | | | | ✓ |

**结论：写入面高度相交**（`profile-service.md` 五份全中，`architecture.md` / `future-event-service.md` / `character-profile/_index.md` / `adventure-event/common-properties.md` 各三份）。
⇒ 铁律 ③：**Phase B 无法并行，全部串行波次**（每波一个 worker）。

## 波次

- **Phase A（并行 ×5，只读）**：A · B · C · D · E 同时跑，产出 `questions-<分片>.md`。
- **合并 interview**（orchestrator）：去重 + 跨草稿核对 → `answers.md`。
- **Phase B（串行 5 波）**：顺序按「地基先于依赖方」——
  1. **D**（element 层载体判据 + `ProfileChangeSpec` 新列/新 Op：B/C/E 的写入通道都建立在它之上）
  2. **A**（两层 Profile 字段总表：C 要往 `CharacterProfile` 加 `eventOptions` 字段，须在总表就位后写入）
  3. **B**（`EventOption` 物化字段清单：C 的承载形态对字段面中立，但字段面先定更省返工）
  4. **C**（派生实例承载与落盘）
  5. **E**（抽取原语与物化实例形态）
- **收尾（orchestrator）**：`handoffs/_index.md` · `open-questions/` 分片 + `update-log.md` · `answer-logs/_index.md` · `inbox/_index.md` + 草稿归档。

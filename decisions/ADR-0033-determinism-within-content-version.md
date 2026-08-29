# ADR-0033 — 确定性的边界只到同一 `contentVersion` 内；RNG 以 `State` + `DrawCount` 双字段持久化

- **状态：** Accepted
- **日期：** 2026-07-27
- **来源：** handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md

## 背景

roguelike 的惯例是「同一 seed 复现同一轮回」。但本作的内容层可经 overlay 热更，且热更**在轮回进行中即生效**（→ `ADR-0007`）。抽取池的组成一变，同一个 seed 掷出的结果就不再是同一批条目。把跨版本复现当作承诺，等于承诺一件实现上不可能的事。

## 决策

**放弃「同一 seed 必然复现同一轮回」。** 确定性降级为**同一 `contentVersion` 内的性质**：轮回带 seed，在同一内容版本内可复现，**不承诺跨内容版本复现**。

RNG 状态以**双字段**持久化：`State`（引擎状态）+ `DrawCount`（已消耗次数）。后者是诊断与迁移保险——`State` 因引擎实现变更而不可用时，仍可用 `seed + drawCount` fast-forward 重放恢复。

子流划分 → `systems/services/life-cycle-service.md`；字段形态 → `systems/common-properties.md`。

## 理由

热更与跨版本复现是互斥的，必须放弃一个。放弃热更的代价是「线上改一个数值就得发版」，本作已明确选择相反方向。

`DrawCount` 的存在理由不是冗余而是**逃生口**：`State` 是引擎内部表示，跨引擎版本没有兼容承诺；只有 `seed + 消耗次数` 是纯语义的、永远可重建的。

## 备选方案

- **保证跨版本复现** — 否决：与 overlay 热更在轮回中途生效直接冲突。
- **只存 `State`** — 否决：引擎实现变更即全部存档不可恢复，无逃生口。
- **为每日种子预留冻结结构** — 否决：本作无每日挑战玩法，预留即是负债。

## 后果

- 依赖跨版本复现去做回放 / 排障 / 校验，会得到与线上不一致的结论——这条须在 `.claude/rules/state-save-rules.md` 中明写。
- 后端的掷骰复算（账号级 RNG）因此也须绑定 `contentVersion`，→ `backend-design-documents/contracts/profile-sync.md`。

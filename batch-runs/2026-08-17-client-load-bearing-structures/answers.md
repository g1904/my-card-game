# 合并 interview — 用户裁决（2026-08-17 · 批量评审）

21 问，4 轮，全部答毕。**19 项按推荐，1 项逆推荐（Q2），1 项为打包授权（Q21）。**

## 轮 1 — 🔴 权威归属 / 契约形状 / 硬冲突

| # | 来源 | 问题 | 裁决 |
|---|------|------|------|
| Q1 | S5-1 | `PoolScope` vs `LocationData.EnemyTemplateIds` 权威归属 | **`PoolScope` 单权威，删 `EnemyTemplateIds`**（推荐项） |
| Q2 | S1-④ | `PlayerProfile` 集合字段单复数 | **改契约为单数**（⚠ **逆推荐项**）→ 破坏性契约变更，**触发跨库**：需在 `backend-design-documents/` 落配套承接项，两侧同批改 |
| Q3 | S1-② | `contentVersion` 类型统一 | **统一为 `int`**，改存档侧两处字段表（推荐项） |
| Q4 | S2-1 | outcome 定稿载体 | **加 `EventOutcomeSpec Outcome` 格**，权重物化时固定；松动三处 resolver 注释，不动 `Source` 定义（推荐项） |

## 轮 2 — 机制 / 承载形状

| # | 来源 | 问题 | 裁决 |
|---|------|------|------|
| Q5 | S3-① | 派生实例承载 | **新可空块 `CharacterProfile.activeEvent`**，持派生后整份定稿实例；当批原实例不动；顺带补 `eventOptions` 具名载体（推荐项） |
| Q6 | S5-3 | 战斗类 `EventOption` 敌人承载 | **加可空 `EncounterSpec Encounter`，`EnemyInstance` 嵌其内**（推荐项）。⚠ 与 Q5 叠加 ⇒ `with` 派生连带复制最胖载荷，存档体积上抬，已知悉 |
| Q7 | S3-② + S4-1 | `ProfileChangeSpec` 增列 | **同批两列 + `ApplyOp`**：一次增 `EventStateChanges` 与 `PlotElements`，`ChangeElement` 增第三字段 `Op`，`ElementSpec` 增 `AllowedOps` 列。成本侧恒空断言逐列独立写。**不**把 `activeCombat` 收进新列（不动 `combat-service.md`） |
| Q8 | S2-2 | `combatTier` 落点 | **两处都不加**，走 `EventId` → 模板溯源（推荐项） |

## 轮 3 — 命名 / 形态

| # | 来源 | 问题 | 裁决 |
|---|------|------|------|
| Q9 | S5-4 | `PlotModulation.EnemyPoolScope` | **删**，改为隐式取当前 arc 的 `Id`；六字段收窄为五（推荐项） |
| Q10 | S4-3 + S1 | 散牌增向定名 + `CostKey` 补登 | **`AddLooseCard`**（与 `RemoveLooseCard` 严格对称）+ 同名多张走多条 element 不设 count + 明写「已在卡组 → 正常追加，不是空操作」；**同批把 `Experience` / `Faith` / `MaleficQi` 登记为 `CostKey` 成员**（推荐项） |
| Q11 | S1-① | `chapterRetry` 命名 | **`Ch1RetryUsed` / …**，命名硬约定表补一行「规则层的『数量』用 `Used`」（推荐项） |
| Q12 | S1-⑤ | Codex 条目类型 | **`CodexEntry` record**（首批只一个 `Id`，日后加计数 / 元数据零迁移）（推荐项） |

## 轮 4 — 后果项与打包

| # | 来源 | 问题 | 裁决 |
|---|------|------|------|
| Q13 | S2-4 | Band 2 展示 vs `LifeSpanCost` 修正（🟠 假账） | **展示走只读 `ApplyModifier` 查询**，施加点仍在 `TryApply`；单一施加点不松动（推荐项） |
| Q14 | S5-5 | 残卷侧 `ordinal` 口径 | **补写既有意图**（先算 `ordinal = 旧值+1` → 掷骰 → 同一次 `TryApply` 写回）**+ 通知对侧**：在后端库落承接项请其确认 `profile-sync.md` §7 三条校验与此口径一致，与 Q2 的契约改动同批递过去（推荐项） |
| Q15–Q21 | 打包 | 其余 10 项轻量取向 | **全部按推荐采纳**。按 `batch-orchestration.md` 铁律 ①，这**不算用户拍板**：每项在草稿中标 `[采纳推荐 — 待复核]` 并**留在待决清单**，用户评审草稿时可逐项推翻 |

### 打包的 10 项（逐条）

| 来源 | 项 | 采纳的推荐 |
|------|----|-----------|
| S1-③ | `currentMana` 归属 | 移入 `activeCombat` |
| S1-⑥ | 落笔形态 | 两份 `_index.md` 各补一张只有形态列的总表 |
| S2-3 | `lifeSpanCost` 区间旋钮 | 不留，定值（非负整数，物化取负） |
| S3-③ | Explore 揭示存档点 | 不新增，随后续第一个决策点落盘 |
| S3-④ | RNG 同事务不变式 | 只落一条不变式 + 一条恢复自校验；`Rng` 块纳入 spec 列另轮 |
| S4-2 | `ApplyOp` 落地时机 | 现在就落结构，逐行取值随 `CostKey` 成员登记补齐 |
| S4-4 | 第六列列名 / 类型名 | `PlotElements` + `PlotKeyPointAssignment` |
| S4-5 | 「单步推进」拓扑校验 | `ProfileManager` 只校验 `Id` 可解析 / 不串线 / 同批不重复；拓扑走 PlotManager `#if DEBUG` 断言 |
| S5-2 | `PoolScope` 形态 | 具名可空字段的内嵌 `Resource`；字段定名 `PlotArcId`；剧情线一侧传全部 `Active` arc 的集合 |
| S5-6 | Exchange 能力族排重级别 | 能力族走 `TryPickGrantableMany`，其余三族直用第一级 |

## orchestrator 直接处置（无第二个合理选项，未占 interview 名额）

- **五份草稿各要求的 schema bump 合并为同一次 bump、同一段迁移说明。** 老档缺 `eventOptions` 无法凭空重建（物化不可重算）⇒ 迁移按「无进行中批次」处置，下一次 `RefreshAfterEvent` 重算一批。当前无线上存档 ⇒ 实际为空迁移。

# 标准 —— 存档格式（深入）

`.claude/rules/state-save-rules.md`（存档/读档章节）的配套文档。由 **sync-service** 拥有——其中 ProfileSyncManager 负责上下行与冲突，LocalCacheManager 负责 `user://` 原子写，MigrationManager 负责 schema 版本迁移。

## 位置与范围
- 持久化于 `user://cache/`（Godot 的每用户可写目录）——现仅作**本地缓存 / 断线临时态**。**强制在线 · 云端权威**：启动时全量 Pull 一次，run 内每个自动存档点 Push，冲突一律以云端为准（ADR-0003；见 `game-design-documents/00-vision/scope.md`）。
- 结构：**`PlayerProfile ⊃ List<CharacterProfile>`** —— 账号级主档持有 run 级角色档案。因此**存档提交点唯一**，由单一 profile-service 作为两层的写入面（「扣账号级 PlayerItem 次数 + 扣 run 级金币」天然落在同一事务内）。

## 原子性
- 绝不原地写入。序列化到 `user://save.tmp`，flush/close，然后重命名覆盖 `user://save.dat`。写入中途崩溃会保留之前的完好存档。
- 可选地在成功写入后轮换保留一份备份（`save.bak`）。

## 版本化与迁移
- 每份存档携带一个 `version`（int）。读档时：
  - 相等 → 直接加载；
  - 更旧 → 运行迁移步骤直至当前版本；
  - 更新/未知 → 优雅拒绝（告知用户），而非崩溃。
- 每当序列化形状变化时递增 `version`；并添加对应迁移。

## 内容引用
- 存档通过 **`Id`**（card/relic/enemy 的 id）引用内容，而非下标或序列化的资源。读档时，通过 **ContentRegistry** 解析 id 并校验（见 `null-check-rules.md`）：未知 id → 清晰的报错/迁移，绝不静默为 null。
- **只存 `Id` + 可变状态，不复制展示文本** —— 文案变更不触发存档迁移（展示层三层切分，见 `.claude/knowledge/architecture.md`）。
- 持久化 run 的 **seed 与 RNG 子流状态**（见 `rng-determinism.md`），使恢复的 run 保持确定性。

## 格式选择
- JSON（通过 `System.Text.Json` 或 Godot `JSON`）可读且便于迁移；Godot 资源序列化是另一个选项。选定其一，记录于此，并将序列化集中在 sync-service 中。

## 自动存档点
- 定义明确的存档边界（每次 `AdvanceEvent` 结算之后、`RunStarted`、篇章完成 / 角色失败时）。实现后在此处记录，使恢复点可预测。
- 篇章边界另有**境界存档点**语义（通关后在所达境界落点；失败清理角色并扣减重试次数 ch1 ∞ / ch2 3 / ch3 1）——归 life-cycle-service 的 ChapterManager，权威见 `50-decisions/ADR-0004`。

# sync-service（服务）

> 存档与云同步服务：Profile 上下行、本地缓存原子写、schema 版本迁移。**判据 ②③ —— 事务性写入 + 外部 I/O 边界。**
> Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 同步模型

```
                云端（权威）
                     ↑ Push（每个自动存档点）
                     │ Pull（启动时全量一次）
                     ↓
   PlayerProfile ⊃ List<CharacterProfile>   ← 内存中的运行态
                     ↓ 原子写
   user://cache/     仅缓存 / 断线临时态，非权威
```

- **`PlayerProfile` 持有 `List<CharacterProfile>`**，故同步单位是**整个 PlayerProfile 聚合**；run 内的高频变更以增量 push 提交。
- **启动时全量 pull 一次**（登录成功后）；**run 内每个自动存档点 push**。自动存档点：run 开始、每个 AdventureEvent 结算后、篇章边界、run 结束。
- **冲突一律以云端为准**（`ADR-0003`）。本地 `user://cache/` 不是权威，仅作缓存与断线临时态。
- **原子写**：先序列化到临时文件，再 rename 覆盖真实文件 —— 写入中途崩溃不损坏缓存。对上行云端负载同样带版本。
- **schema 版本 + 迁移路径**：读取时校验版本、所引用的内容 `Id`（经 ContentRegistry）、必需字段；不匹配则**迁移或清晰拒绝**，绝不静默 null，绝不在较旧的存档上崩溃。
- **运行时 / 存档态只带 `Id` + 可变状态**，不复制展示文本 —— 文案变更不触发存档迁移（见 `20-systems/common-properties.md` 的三层切分）。

## 管理器

| manager | 职责 |
|---------|------|
| **ProfileSyncManager** | Pull / Push、冲突以云端为准、断线缓冲与重试 |
| **LocalCacheManager** | `user://` 原子写（临时文件 → rename）、缓存读取与失效 |
| **MigrationManager** | 存档 schema 版本校验、逐版迁移路径、无法迁移时的清晰拒绝 |

## API 面（意图草图 · 签名待定）

- `PullProfile(accountId)` → 从云端取权威 PlayerProfile，经 MigrationManager 校验 / 迁移，写入本地缓存。
- `Push(profile, reason)` → 在自动存档点上行；`reason` 用于日志与重试策略（事件结算 / 篇章边界 / run 结束）。
- `FlushPending()` → 断线期间缓冲的变更在恢复连接后补提交。
- **事件面：** 同步成功 / 失败、进入断线缓冲态、迁移发生 / 迁移拒绝，经 EventBus 广播给 UI（用于「同步中 / 离线」指示）。

## 与其他服务的关系

- **上游：** `account-service` 提供 `accountId` 与 token；`profile-service.ProfileManager` 是内存态的唯一写入面，本服务只负责**持久化与传输**，不改字段语义。
- **触发方：** `life-cycle-service` 在状态机边界触发自动存档点；`game-progression` 在核心循环第 ⑤ 步触发。

## 决策(-> ADR)

- **强制在线 · 云端权威**（冲突以云端为准、本地仅缓存） → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **断线降级的具体行为。** 强制在线下，push 失败 / pull 失败时：阻塞玩家、本地缓冲后重试、还是回退到上一个存档点？缓冲上限与超时策略未定。这是本服务最大的未定项。
- **增量 push 的粒度。** 整个 PlayerProfile 聚合上行，还是按 CharacterProfile / 字段级 diff？影响流量与冲突裁决的粒度。
- **RNG 状态的持久化形态。** 「持久化足够的 RNG 状态使恢复的 run 确定性继续」已是约定，但具名子流的状态如何编码进存档 schema 未定。→ `20-systems/common-properties.md`、`life-cycle-service.md`（SeedManager）。
- **自动存档点清单的最终确定。** 每个 AdventureEvent 后 push 是否过于频繁（移动网络 / 电量），是否需要合并窗口。
- **迁移失败的玩家侧表现。** 「清晰拒绝」在 UX 上是什么（提示重装？联系客服？回退到云端上一个可用版本？）。→ `40-ux/`。

## 对应
提炼至：`.claude/knowledge/systems/sync-service.md`（引用层，待建）。

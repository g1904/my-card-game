# batch-provide-solution-draft — 2026-08-18 · 客户端库

主库：`game-design-documents/`；对侧库：`backend-design-documents/`（仅 W8 触碰）。

用户圈选范围：**批 A（derive 解锁批）+ 批 C（工程细节批）** = 12 个候选问题 → 10 份主库草稿 + 1 份对侧草稿。
未入批：批 B（玩法上游）、批 D（半取向）、全部 ch1 数值项、已排期专场项。

## 分区表（每个 worker 的独占写入面）

| worker | slug | 覆盖候选 | 独占写入文件 |
|---|---|---|---|
| W1 | `translation-english-placeholder` | 1 英文占位符形态 | `game-design-documents/inbox/solution-draft-translation-english-placeholder.md` |
| W2 | `device-id-provisioning` | 2 `deviceId` 生成与持久化落点 | 同上目录 `…-device-id-provisioning.md` |
| W3 | `costkey-statkey-registry` | 3 `CostKey` element 清单 + 12 `StatKey` 成员清单 | `…-costkey-statkey-registry.md` |
| W4 | `profile-change-spec-gaps` | 4 三处「有纪律、无通道」+ 9 `Project(spec)` 语义面 | `…-profile-change-spec-gaps.md` |
| W5 | `codex-entry-schema` | 5 `CodexEntry` schema + 六本图鉴解锁触发/词条深度 | `…-codex-entry-schema.md` |
| W6 | `game-setting-schema` | 6 `GameSetting` 清单 + 设备本地/账号级切分 | `…-game-setting-schema.md` |
| W7 | `architecture-structural-residuals` | 10 architecture 三条结构残留 | `…-architecture-structural-residuals.md` |
| W8 | `bundle-grant-ordinal-authority` | 11 `BundleGrantOrdinal` 由谁施加（**跨库**） | 两库各一份 `…-bundle-grant-ordinal-authority.md` |
| W9 | `pickmany-shortfall-handling` | 13 `PickMany` 抽不足两调用侧处置 | `…-pickmany-shortfall-handling.md` |
| W10 | `breakdown-granularity-and-signoff` | 15 `/breakdown-requirements` 两项形态确认 | `…-breakdown-granularity-and-signoff.md` |

**共享台账 `inbox/_index.md`（两库）由 orchestrator 收尾统一写**（铁律 ②）。worker 只交回台账行。

## 已知的跨分片交叉（orchestrator 收尾必查）

1. **W3 ↔ W4** —— 两者都在描述 `ProfileChangeSpec` 的列结构。若 W3 给 `ResourceElements` 的形状与 W4 给 `activeCombat`/RNG/`pastEvent` 的落列方案互相矛盾 → 新增 🔴 进 interview。
2. **W2 ↔ W6** —— `deviceId` 的持久化落点很可能就是「设备本地设置项」，而 W6 正在切分设备本地 vs 账号级。两份草稿对同一落点若给出不同归属 → 🔴。
3. **W5 ↔ W6** —— 两者同为 `player-profile/_index.md` 六处 `⟨待定⟩` 的来源，且都进 `sync-service` 的本地缓存序列化面。序列化形态若不一致 → 🔴。
4. **W4 ↔ W9** —— `PickMany` 抽不足的处置若涉及回滚，会牵动 W4 的事务/投影语义。
5. **W8 跨库对称** —— 两份草稿必须互相回链且不复述对方那一半。

## 波次

全部 10 个 worker 单波并行（写入面已两两不相交）。
`/provide-solution-draft` 本身无 interview 门 —— worker 一次写完草稿，取向项留在草稿的 `## 仍需用户决定`；
合并 interview 由 orchestrator 在第 4 步统一开。

# flags 单调闸补齐：应答体的 `flagsVersion` 也过同一道闸

- id: 2026-08-23-flags-version-client-gate
- date: 2026-08-23
- topic: systems/services/content-service（「flags：`ContentEnabled` 的第三层」新增应用闸一条）
- status: distilled
- distilled-to: `systems/services/content-service.md`、`open-questions/cross-boundary.md`、`open-questions/update-log.md`

## Intent（distilled）

**一句话：** 本库的 flags 单调闸此前只挂在**观测 `X-Flags-Version` 头**这一处；**拉回的那一批 body 里的 `flagsVersion` 是否也过闸**没写，而它不过闸就是「被秒关的内容当场复活」。

### 缺口

既有规则写的是「观测到头里的版本增大 → 拉一次全量；等值不拉；更小不拉 + 告警 + 上报」，以及「仅当本次拉回的版本 > 拉取前的内存值才允许尾随一次」。后者是**节流规则**（要不要再发一次请求），**不是应用与否的规则**。

头与应答体可能来自**不同来源**：多实例、多区域的传播窗口、中间层缓存了旧 body。于是存在「头说 42、体里是 41」这一情形；若把 41 那批应用上去，上一批已生效的秒关当场失效。后端侧对此只能缓解（传播窗口 SLO + 缓存键含版本），**堵住它的位置在客户端**。

### 定案

**拉回批次的 `flagsVersion` > 内存值 → 应用；否则整批丢弃 + `PushWarning`（带拉回值与内存值）+ 上报一次。** 通道与去重口径（上报侧本会话一次）与既有的「观测到更小版本」**完全相同，不新增第二套**。

**等值也丢弃，这不是保守。** 后端保证同一 `(flagsVersion, 账号)` 的解析结果恒定，故等值那一批与本地已生效的那一批逐字相同，应用它是纯粹的空操作。丢弃使「应用」这一步只有一条判据（严格增大），实现里不必区分「无害的等值」与「有害的更小」。

**零 API 改动、零新增上报通道、零新增阻塞点。**

## Clarifications（interview 产物）

**未触发 interview。** 该形态由既有设计逻辑必然推出：既有的「观测到更小 → 不拉 + 告警 + 上报」已经为同一失败模式定了处置与通道，本条只是把同一判据挪到应用这一步；而「应用一批更小的 flags」没有任何一侧的取向支持它——它正是整条单调纪律要防的事。

## Open questions

**无。**

## 对侧库对位

对侧同批落笔的 `flagsVersion` 三条服务端保证（单一全局单调序列 · 回滚即前滚 · 同版本结果恒定）见 `backend-design-documents/handoffs/2026-08-23b-flags-version-monotonic.md` → `contracts/content-manifest.md`「服务端保证」B 组。本条是该批的**越界发现**在本库的落笔，由本库自己裁决（对侧明写不代为改客户端规则）。**两侧无遗留欠账。**

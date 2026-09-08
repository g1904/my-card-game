# refresh 凭据失效的 `reasonKey` 消歧：`SessionExpired` 收编三种情形

- id: 2026-09-07-refresh-expiry-reasonkey
- date: 2026-09-07
- topic: contracts/auth（§4 求值顺序 · §8 refresh 错误段 · §10 取值表与说明段）· systems/account（refresh 校验流程伪码）
- status: distilled
- distilled-to: `contracts/auth.md`、`systems/account.md`

## Intent（distilled）

**一句话：`auth.session_revoked.detail.reasonKey` 的 `SessionExpired` 由「链达到绝对寿命上限」扩为「refresh 凭据不再有效，且不属于本表其余任一取值」，收编三种情形——滑动截止到期 · 绝对截止到期 · `tokenId` 无从识别。不新增取值、不新增 `code`、客户端零改动。**

### 缺口

`contracts/auth.md` §4 的 refresh 求值顺序第四分支（`now ≥ refreshExpiresAtUtc`，滑动截止到期）原写「`reasonKey` 沿用既有口径」，而 §10 的取值表里没有任何一值对应它：`SessionExpired` 明写触发是**绝对**寿命上限，其余各值各有确定且互斥的触发源。这条分支是可达的常态路径——闲置玩家回来时必然先撞一次 refresh 再落登录屏（客户端把静默续期落在启动链第二步）。

同一缺口的第二处实例在 `systems/account.md` 的 refresh 校验流程伪码：「按 `tokenId` 查 session 行（查不到 → `auth.session_revoked`）」这条叶子同样无取值。两处同属 §8 所列的第一类失败（refresh 凭据已失效），在契约面上整体没有取值。

### 三种情形共用一个取值

判据是 §10 自己的那一条：**`reasonKey` 分辨的是玩家措辞，不是机制的自述。** 三者对玩家是同一句话——完全正常的例行事件，玩家没做错任何事，也没有第二台设备在动他的账号；`SessionExpired` 已定的措辞「登录状态已过期，请重新登录」逐字适用于三者。

给它们各立一个取值的代价是一份**必然漂移的文案副本**：客户端 `errors.csv` 会多出逐字相同的二级行，而客户端不持有 `reasonKey` 清单、正向审计只查一级键，措辞调整时不同步是一次静默失准。要让它们真有分辨价值，二级文案就得说出「因为你太久没登录 / 因为这条链够老了」——那正是客户端侧已否决的写法（把后端可调旋钮写进翻译条目）。

服务端侧的分辨不依赖它：会话行同时持有 `refresh_expires_at_utc` 与 `absolute_expires_at_utc`，哪一个先到期在行内可判；且本库当前没有任何登记在 `operations/observability.md` 的指标以 `revokedReason` 为标签（已核对，`operations/` 全目录零命中）。日后确需在观测面分辨，加一个**不跨边界**的内部字段即可，与 `sid` / `channelUserId` / `idKind` 同一条纪律。

### 连带三项

- **`tokenId` 无从识别并入同一取值。** 通行做法是鉴权失败不向未知来源自述细节；而对正当玩家（会话记录已被清理、换机后残留的旧凭据）它与到期是同一件事。§10 已就 `SessionSuperseded` 否决过「让常态情形长期占用兜底路」，同一条适用于此。
- **`revokedAtUtc` 在无会话记录时取本次判定时刻**（服务端时钟，`operations/compliance-ops.md` 的可信时钟基准）。语义成立，且使 `detail` 形状恒定 ⇒ `envelope.md` §6 台账一字不动。
- **§8 的 refresh 错误段去计数化。** 原写「四者靠 `reasonKey` 分辨」，情形数因本次改写而变；照 §10「引用它的地方一律写指路、不写条数」的纪律改为指路。

### 边界（不牵动的东西）

不新增、不变更任何 `code`；`envelope.md` §6 台账连 `detail` 形状都不动；三条机检断言不受影响（断言②不下探到 `reasonKey`）；`systems/account.md` 的承重列与事务边界表不动（`revoked_reason` 列已存在，写入面与既有 `SessionExpired` 路径同形）；`operations/version-matrix.md` 取的是绝对寿命这个**时长**旋钮，与取值无关。

**客户端承接义务：零。** 无新键、无新文案、无代码改动、无发版顺序耦合。`SessionExpired` 的既定措辞与「不附原因句」纪律恰因本方案而继续成立。

**存档 / schema 影响：无。** `reasonKey` 是传输层字段，不进 profile、不进 `schemaVersion`。

## Clarifications（interview 产物）

- **滑动截止到期是共用 `SessionExpired` 还是新增第九个取值（`SessionIdleExpired`）？** → **共用 `SessionExpired`**（2026-09-07 批量评审裁决，选项 A）。连带：`tokenId` 无从识别随之并入同一取值，选项 B 附带的那个从属问题不再存在。
- 以下按标准默认直接落笔，用户未提异议：`revokedAtUtc` 在无会话行时取判定时刻（`envelope.md` §2「绝不下发 `null`」的直接推论）· §8 去计数化（§10 明文纪律）· 伪码「均不命中」那条叶子只补 `TokenReuseDetected` 标注（语义在紧随其后的正文里早已给出，不是新决定）。

## Notes / triage

- **`SessionExpired` 的既有定义被扩宽，这是本次唯一的张力。** §5b 与 §10 原写它是「链达到绝对寿命上限」。松动的必要性在于：不松动就必须新增取值，而新增取值的代价是一份逐字相同的文案副本。
- **§5b 的闸门收口论证不受影响。** 它只依赖「绝对截止存在、`signin` 时锚定、rotation 永不顺延」，与该取值是否独占无关；§5b 正文那句「超过 `absoluteExpiresAtUtc` 的 `refresh` → 回 `auth.session_revoked`（`reasonKey: "SessionExpired"`）」仍然成立，只是不再是该取值的唯一来源。
- 历史记录（`answer-logs/log-refresh-lifetime-cap.md`、`handoffs/2026-08-23-refresh-lifetime-cap.md`）**不随之改写**——它们记的是当时答了什么；权威以 `contracts/auth.md` §10 为准。
- 本次未移出任何 `open-questions/` 条目：该卡点记录在「derive 就绪度」小节（`/assess-derive-readiness` 独占写入），`01` 分片的待答清单本就为空。故**无 answer log**。
- 值得固化为 ADR 的一条：**`reasonKey` 的分辨判据是玩家措辞而非机制自述，故凡措辞相同的情形一律共用取值**。立档归 `/write-adr`，本 handoff 不建 ADR。

## 客户端侧影响

**无。** 本 handoff 不改动边界报文的任何字段、形状与取值集合的**外延**（`SessionExpired` 本就在表内、客户端本就有它的二级文案键）；改的只是该取值在契约侧的触发描述。`account-service` / `content-service` / `sync-service` 三个跨边界成分均无承接项，`game-design-documents/` 无需同步更新。

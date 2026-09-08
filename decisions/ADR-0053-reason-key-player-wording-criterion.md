# ADR-0053 — `reasonKey` 分辨的是玩家措辞而非机制自述，措辞相同即共用取值

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07-refresh-expiry-reasonkey.md

## 背景

`contracts/auth.md` §4 的 refresh 求值顺序里，「滑动截止 `refreshExpiresAtUtc` 到期」这一分支原写「`reasonKey` 沿用既有口径」，而 §10 取值表中没有任何一值对应它——`SessionExpired` 明写触发是**绝对**寿命上限。这条分支是可达的常态路径（闲置玩家回来时必然先撞一次 refresh）。同一缺口的第二处实例在 `systems/account.md` 的 refresh 校验伪码：「按 `tokenId` 查 session 行，查不到 → `auth.session_revoked`」同样无取值。

## 决策

`auth.session_revoked.detail.reasonKey` 的取值粒度**按玩家措辞划分，不按机制自述划分**：凡对玩家是同一句话的情形，一律共用同一个取值。

据此 `SessionExpired` 由「链达到绝对寿命上限」扩为「refresh 凭据不再有效，且不属于本表其余任一取值」，**收编三种情形**：① 滑动截止到期；② 绝对截止到期；③ `tokenId` 无从识别（伪造，或会话记录已被清理）。情形 ③ 无会话行可读时，`revokedAtUtc` 取**本次判定时刻**。

取值表与说明段见 `contracts/auth.md` §10，求值顺序见 §4，服务内部伪码见 `systems/account.md`。

## 理由

- 判据是 §10 自己那一条：`reasonKey` 面向的是**玩家措辞的分辨**。三种情形对玩家是一字不差的同一句话——完全正常的例行事件，玩家没做错任何事，也没有第二台设备在动他的账号；`SessionExpired` 已定的措辞逐字适用于三者。
- 各立一个取值的代价是**一份必然漂移的文案副本**：客户端 `errors.csv` 会多出逐字相同的二级行，而客户端不持有 `reasonKey` 清单、正向审计只查一级键，措辞调整时不同步是一次静默失准。要让它们真有分辨价值，二级文案就得说出「因为你太久没登录」——那正是客户端已否决的写法（把后端可调旋钮写进翻译条目）。
- 服务端侧的分辨不依赖它：会话行同时持有 `refresh_expires_at_utc` 与 `absolute_expires_at_utc`，哪一个先到期在行内可判；且当前无任何登记在 `operations/observability.md` 的指标以 `revokedReason` 为标签。日后确需在观测面分辨，加一个**不跨边界**的内部字段即可，与 `sid` / `channelUserId` / `idKind` 同一条纪律。
- 「`tokenId` 无从识别」并入同一取值另有一层：通行做法是鉴权失败不向未知来源自述细节，而对正当玩家（换机后残留的旧凭据）它与到期是同一件事。§10 已就 `SessionSuperseded` 否决过「让常态情形长期占用兜底路」。

## 备选方案

- **新增第九个取值 `SessionIdleExpired`** — 代价是一份逐字相同、且客户端审计发现不了的二级文案副本；分辨价值只对服务端成立，而服务端本就能在行内判。
- **让「`tokenId` 无从识别」走兜底路** — §10 已为 `SessionSuperseded` 否决过让常态情形长期占用兜底路。

## 后果

- **零新增 `code`、零新增取值**；`contracts/envelope.md` §6 台账连 `detail` 形状都不动（无会话行时 `revokedAtUtc` 取判定时刻，形状因此恒定）。
- `contracts/auth.md` §8 的 refresh 错误段**去计数化**（原写「四者靠 `reasonKey` 分辨」），照 §10「引用它的地方一律写指路、不写条数」的纪律改为指路。
- `SessionExpired` 的既有定义被扩宽，是本决策唯一的张力；§5b 的闸门收口论证不受影响——它只依赖「绝对截止存在、`signin` 时锚定、rotation 永不顺延」，与该取值是否独占无关。
- **客户端承接义务：零**（无新键、无新文案、无发版顺序耦合）。存档 / `schemaVersion` 无影响——`reasonKey` 是传输层字段。

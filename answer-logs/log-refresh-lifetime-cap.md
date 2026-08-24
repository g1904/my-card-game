# Answer log refresh-lifetime-cap

- 日期：2026-08-23
- 来源：`inbox/archive/solution-draft-refresh-lifetime-cap.md` → `handoffs/2026-08-23-refresh-lifetime-cap.md`
- 移出条数：1（另有一条计数副本纪律顺带收口，不单列为问题）

## 逐条

**静默续期使旧客户端可长期不经协议维度强更闸门，收口手段（滑动续期上限 / 强制 re-signin 周期 / 其他）未定** → **采纳 refresh token 链的绝对寿命上限**：`signin` 时锚定 `absoluteExpiresAtUtc`、rotation 永不顺延，有效性 = `now < min(滑动截止, 绝对截止)`；判定点只在 `refresh` 请求到达时，先判到期再判宽限回放；到期复用 `auth.session_revoked` + 新 `reasonKey` `SessionExpired`，**不新增错误码**；下行不新增时间字段，`refreshExpiresAtUtc` 收紧为 `min(...)`；旋钮初值 60 天（上限）与 3 天（软信号提前量），落后端配置。软着陆信号 `reauthRecommended` 引入，形态为**服务端算好的可选 body 布尔**，绝不是时间戳。连带：滑动续期承诺收窄为「不因**闲置**而被动重登」。（归档去向：`contracts/auth.md` §2 · §4 · §4a · **§5b（新增）** · §8 · §10 · 备选方案七条）

**顺带收口（不是一条待答问题，是一条落笔纪律）：** 契约正文里写死的封闭计数改为不带数目的回链——`envelope.md` §6 台账的 `reasonKey` 条数、`auth.md` §9 与 §8 的「三值见 §10」，以及客户端 `game-design-documents/ux/error-and-blocking-ux.md` 的同形写法。计数是会漂移的副本，与「回链而非复述」同向。

## 仍留在清单上的

- **`refresh` 的滥用面与限流形态**（`open-questions/01-contracts.md`，待 `06`）—— 与本条同在 refresh 面上，但互不阻塞、采纳顺序任意。本次刻意不新增错误码，**不消耗**那条纪律的额度。
- 绝对上限的**存储落点**随 `06-platform-stack.md` 落定，与 `auth.md` §4a 已移交实现层的三项同处。

## 跨边界

客户端侧的对应结论（二级文案键 `ERR_AUTH_SESSION_REVOKED_SESSION_EXPIRED` 的措辞基调 · 软信号的反应形态）记在 `game-design-documents/answer-logs/log-refresh-cap-and-flags-gate.md`，**本 log 不复述**。两侧成对采纳已完成。

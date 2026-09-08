# ADR-0037 — `signin` 四条合规拦截码的求值顺序写死

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-compliance-domain-storage.md · answer-logs/log-compliance-domain-storage.md

## 背景

四条 `compliance.*` 拦截码全部只在 `signin` 上生效，且可能同时成立。不定顺序，应答就不唯一；更糟的是其中两条撞在一起会形成死路：撤销注销所需的 ticket 只随 `account_deleting` 下发，而受限账号的会话已被吊销、调不动需鉴权的撤销端点。

## 决策

一次 `signin` 上多条拦截码同时成立时，求值顺序**写死并逐级短路**：

`compliance.account_deleting` → `compliance.account_restricted` → `compliance.realname_required` → `compliance.playtime_blocked`

该顺序落 `contracts/compliance.md` §5（唯一权威），运维与服务文档只回链、不复述。

## 理由

判据是：**不可逆且有时限的在前，可持续且可撤销的在后；每天都会重新成立的时段判定放最后。** 若先收到 `account_restricted` 就再也拿不到 ticket——那是一条会真实删掉玩家账号且无出路的死路。

顺序落契约侧是本库既有先例：决定应答唯一性的求值顺序一律写在契约侧（refresh 的五分支、同步侧的判定顺序）。

风控强度一秒都没有松动——先给出 `account_deleting` 只是让撤销通道保持可达，受限状态本身不变。

## 备选方案

- 不定顺序、由实现自行决定 — 会让「受限账号申请注销后无路可撤、15 天被不可逆删除」这条死路以随机概率发生且不可复现。

## 后果

- 它不是契约变更：不新增 / 不改动任何 `code`、`class`、字段或状态机取值，不 bump `openapi.yaml` 的 `info.version`。
- 客户端的落屏顺序因此可被写成确定的验收断言。
- 与 `ADR-0033`（撤销恢复到 `previous_status`）合起来，才使「受限账号误申请注销」这条路径完整可逆。

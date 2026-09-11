# ADR-0063 — 人类身份对业务表恒只有 `SELECT`，一切写入经服务端受控面

- **状态：** Accepted
- **日期：** 2026-09-09
- **来源：** `handoffs/2026-09-09-internal-ops-tools-and-operator-identity.md` · `answer-logs/log-internal-ops-tools.md`

## 背景

本库已把若干条写入纪律落在应用层：flags 规则集「不存在原地编辑路径」（`operations/content-delivery-ops.md` O1 / A3）、昵称复核队列「恰好被一人领到」「迟到提交被拒」两条保证靠条件 `UPDATE` 取租约兑现（`operations/moderation.md` M6 / M7）、账号处置靠 `baseAccountStatus` 乐观前置兑现（`operations/internal-tools.md`）。这些纪律有一个共同的、未被明说的前提：**没有人能绕过服务端直接改库**。

只要运维 / 维护者手上还有一份可写库凭据，上述每一条都停在评审级——纸面成立、线上不成立。此前该禁令只写在 flags 规则集表这一处（A3），而需要它最迫切的两处（昵称复核、风控处置）当时尚无文档承载，于是「它到底管几张表」成了一个必须显式回答的问题。

## 决策

**任何人类身份对任何业务表恒只有 `SELECT`；一切写入一律经服务端受控面**（应用层 API 或 `/internal/` 端点），不限于 flags 规则集表。

- 应用身份的权限按表另行收紧（规则集表为 `INSERT` + `SELECT`，无 `UPDATE` / `DELETE`）；**人类身份统一只有 `SELECT`，无例外表**。
- 该权限分层**落在建库脚本里**，不停在约定——它是存储选型判据的一条（`operations/content-delivery-ops.md`「存储选型判据」）。
- 推论：内部人工处置**不发放可写库凭据**，全部动作经 `/internal/` 六端点最小集完成。
- → 全文与逐表口径见 `operations/internal-tools.md`「界面档次」· `operations/content-delivery-ops.md` A3。

## 理由

- **限缩到单张表就等于承认其余表可以带外改。** 承重论证逐字见 `operations/content-delivery-ops.md` A3：而昵称复核与风控处置正是最需要它的两处。
- **它是既有保证的兑现条件，不是额外洁癖。** 人直接 `UPDATE nickname_review` 会绕过条件 `UPDATE` 取租约，`M6` / `M7` 当场失效，且 `claimed_by` 仍然没有来源（`operations/internal-tools.md`「界面档次」）。
- **成本为零、与既定取向同向。** 界面档次已定为 CLI + 服务端受控面（A3'），本决定不新增任何组件，只是把已有形态写成权限层的硬约束。
- 与 `vision/pillars.md` #4「一次误判 = 一次强制下线」同向：带外改库是唯一一条不留 `operator_audit` 痕迹的处置路径。

## 备选方案

- **限缩在 flags 规则集表一张表（原 A3 的范围）** — 否决：其余表默认可带外改，昵称复核与风控处置的服务端保证随之失效。
- **发放受限可写库凭据给维护者作应急通道** — 否决：应急通道即绕过条件 `UPDATE` 与 `baseAccountStatus` 前置的通道，本库已明写首版不给人可写库凭据去处置。

## 后果

- `operations/internal-tools.md` 的「不给人可写库凭据去处置」与六端点最小集**是本决定的直接后果**，不能单独被放宽。
- `operations/content-delivery-ops.md` 的存储选型判据必须保留「权限分层落在建库脚本里」这一条；`operations/environments.md` 的权限与凭据面按此配置。
- 为内部面 derive FR 时，本条写成否定断言（人类身份无 `INSERT` / `UPDATE` / `DELETE`），与 `operations/internal-tools.md` I1–I10 同体例。
- 放弃了「带外改库」这条应急路径：任何未被 `/internal/` 端点集覆盖的处置动作，必须先开端点，不能先改库。
- 对客户端零影响——不触及任何契约报文、不新增 `code`，`game-design-documents/` 侧无需同步。

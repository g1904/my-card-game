# ADR-0033 — 注销冷静期落独立表，`pendingDeletion` 由行派生，`previous_status` 是承重列

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-compliance-domain-storage.md · answer-logs/log-compliance-domain-storage.md

## 背景

注销是一个跨天的长时对象：有申请时刻、冷静期、执行时刻与多个终态，而且必须能被审计追问。`account.status` 则是「当前可玩性」的单点，契约已封定四值。把注销塞进 `account` 的列里，两件事会互相绑架。

## 决策

冷静期状态落**独立表 `account_deletion`**；`account.status = pendingDeletion` **由「存在处于冷静期的行」派生**，契约四值一字不改。状态取值收敛为三个（冷静期中 · 执行中 · 已执行），**撤销即删行**；申请 / 撤销的留痕交风控事件流（`DeletionRequested` / `DeletionCancelled`）。

**`account_deletion.previous_status` 是承重列**：撤销必须恢复到申请前的状态，而不是恢复到 `active`。

表定义见 `systems/account.md`；流程见 `operations/compliance-ops.md`；事件 `kind` 见 `operations/moderation.md`。

## 理由

`previous_status` 漏掉后就成了一条**用「申请注销 + 撤销」洗白风控处置**的路径，而且**线上不可发现**——表现只是「某些被封号的玩家又能进了」，无任何报错。

由行派生 `pendingDeletion` 与 `nicknameChangeRequired` 由云端状态算出是同一手法：契约面的取值不新增，服务端内部各自持有真实对象。

## 备选方案

- 在 `account` 上加两列（申请时刻 + 冷静期截止） — 注销有多个时刻与多个终态且要能被审计追问，`account.status` 是「当前可玩性」的单点，不该兼职。
- 由这张表兼任历史归档，保留「已撤销」取值与撤销时刻列 — 交风控事件流（只追加、有自己的保留期），避免多造一份需要自己定保留期的历史。

## 后果

- `contracts/compliance.md` 的四值状态机一字未改，本条纯属服务端内部形态。
- 风控事件流成为注销申请 / 撤销的唯一留痕处，其保留期即这段历史的保留期。
- 冷静期到期的执行由 `ADR-0034` 的周期扫描承接，删除深度由 `ADR-0035` 界定。

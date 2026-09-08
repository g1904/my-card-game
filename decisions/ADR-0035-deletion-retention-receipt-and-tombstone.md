# ADR-0035 — 注销执行保留 `receipt_idem` 全行与最小 `account` 墓碑，其余按数据类别硬删

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-compliance-domain-storage.md · answer-logs/log-compliance-domain-storage.md

## 背景

账号注销执行要真的删数据，但「全删」会与另一条承重保证撞车：`ADR-0013` 定死 `receiptId` 全局唯一、永久保留，而幂等查重正是靠这张表。删除权针对的是个人信息，需要一条判据把两者分开。

## 决策

注销执行在一次事务内按数据类别逐表硬删（identity · 实名材料 · profile · `signin_replay` · `compliance_ticket` · session · `export_task` 与其对象 · 风控事件 · `push_idem`），**全有或全无**。

两条保留：**`receipt_idem` 全行保留**；**最小 `account` 墓碑**（`account_id` + `created_at_utc` + `deleted_at_utc`，不含任何个人信息、不可关联到自然人，**且不进 `account.status` 枚举**）。

逐对象表与服务端保证见 `operations/compliance-ops.md` 与 `systems/account.md`（D 组保证）。

## 理由

删掉 `receipt_idem` 等于同一张收据可被新账号再核销一次，**且线上不可发现**；攻击形态明确：买一次 → 注销 → 重建号 → 再核销同一张票。保留一个不可关联到自然人的内部键，换来一条不可发现的重复发放漏洞被永久堵死。

`account` 墓碑必须留，否则 `receipt_idem.account_id` 悬空、退款对账通道断裂；它不进 `status` 枚举，因为它不表达任何可玩性。

## 备选方案

- 全量硬删（含 `receipt_idem`） — 打开一个线上不可发现的重复发放漏洞。
- 把 `receipt_idem` 的账号列匿名化 — 断掉退款对账，并需要新增一套 id 空间。

## 后果

- 它坐实了 `ADR-0045` 三层归档方案的承重前提「哨兵行永不删」——注销路径同样不删行。
- 它是 `ADR-0013`（`receiptId` 全局唯一 · 永久保留）在注销路径上的守护，二者互相回链、不复述。
- 墓碑行的存在使「`account_id` 存在」不再等价于「账号可用」，读路径须以 `deleted_at_utc` 判定。

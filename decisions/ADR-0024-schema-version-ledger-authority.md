# ADR-0024 — `schemaVersion` 兼容集合的登记权威落本库矩阵，顺序恒为「矩阵先加、客户端后发」

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** `handoffs/2026-09-03-schema-bump-ledger-authority.md` · `answer-logs/log-schema-bump-ledger-authority.md`

## 背景

`envelope.md` §7e 的版本兼容矩阵里，`schemaVersion` 那一格此前是空的、且指向一份不存在之物（「待客户端清单补齐」），而对侧那份清单本身也不完整 ⇒ **两侧都以为对方在记**。漏登的表现是一批玩家安静地上不去进度，而后端侧零信号。

## 决策

**`schemaVersion` 兼容集合的登记权威落 `operations/version-matrix.md`，形态为一版一行的四列子表；本库只登数字与运维事实，一个字段名都不写——第四列是回链，不是摘要。登记顺序恒为「矩阵先加、客户端后发」。**

- 四列：`schemaVersion` · 接受起始 · 下线计划 · **客户端登记回链**（指向 `game-design-documents/systems/services/profile-schema-versions.md`）。
- **本批即登 `schemaVersion = 1`**，不等首个客户端版本上线。
- 登记流程与错误码台账并列写进 `operations/_index.md`：触发点 = 对侧登记表新增一行 · 承载 = `open-questions/cross-boundary.md` 的标准四段式条目（**零新增机制**）· 责任人两段（开条目归发起方，恒为客户端；落笔矩阵归后端）· 顺序 = 矩阵先加、客户端后发。
- `schemaVersion` 集合由标量升为小表，但仍在旋钮表内——**改值不发版**。

## 理由

**`schemaVersion` 的结构权威在客户端，后端对它只做一件事——判定它在不在兼容集合内。** 因此本库该持有的是「哪些版本我接受、从什么时候起、什么时候下线」，而不是「第 N 版含什么字段」。第四列写成回链而非摘要，判据即 `envelope.md` §8「不把 Profile 的字段表抄进本库」——镜像一份摘要正是本问题要修的病（第二权威）。

**顺序唯一合理，因为成本极不对称**：后端补一版只需改一次旋钮值、不发版；客户端发出一个后端不认识的 `schemaVersion`，代价是那批玩家的进度暂时上不去。**反序的代价由玩家承担。** 这与下线纪律（先提下界、再删分支）方向一致——加与减都是先动矩阵。

本批即登 `1` 的理由同源：对侧 v1 已定案，按本库自己的顺序纪律，**等待就是无成本的反序**；且第四列回链若无行可挂，本次的核心交付物落笔当天即无处可指。

## 备选方案

- **把客户端 bump 清单的内容镜像进 `version-matrix.md`（每版含哪些字段）** — 直接违反 `envelope.md` §8，且这正是本问题要修的病。
- **靠周期性对账（每月比对两侧清单）发现漏登** — `contracts/_index.md` 已否决周期性对账：它允许漂移窗口存在，而那个窗口正是两侧按不同真值编码的时期。
- **本批不登 `1`，矩阵保持「待首个版本产生」** — 无成本的反序，且回链落笔当天即无处可指。
- **新立一套跨库登记机制承载** — `cross-boundary.md` 的四段式条目已够用；「每次 bump 须进兼容矩阵」本就是既有机械义务，本次是把它写成流程，不是新立机制。

## 后果

- **本库永不持有 Profile 的字段名**；想知道第 N 版改了什么就点回链过去。放弃后端自持一份可读的 schema 摘要——可读性换单一真值。
- 每次 bump 强制**先动矩阵**；客户端发版是第二步。这条顺序对客户端是一项常态义务，其登记表权威在 `game-design-documents/systems/services/profile-schema-versions.md`，两侧互相回链、互不复述。
- `contracts/envelope.md` §7e 只补一句指路，**语义未改**；`client.version_unsupported` 与 `sync.payload_schema_unsupported` 两码的判定输入自此有确定落点。
- 漏登的**机制发现面**是 `operations/observability.md` 的未知 `schemaVersion` 探针（阈值 0）；它属 `ADR-0025`，不由本条承载。
- **报文零改动**：不新增字段 / 端点 / 错误码 ⇒ 不 bump `openapi.yaml` 的 `info.version`。

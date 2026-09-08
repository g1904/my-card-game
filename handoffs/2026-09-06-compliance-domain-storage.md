# 合规域三类状态与产物的存储形态 + 三个旋钮的校准信号

- id: 2026-09-06-compliance-domain-storage
- date: 2026-09-06
- topic: operations/compliance-ops（新建 · 后四节）· systems/account · contracts/compliance · operations/environments · observability · deployment · moderation
- status: distilled
- distilled-to: `operations/compliance-ops.md`（ticket 存储与一次性消费 · 注销冷静期 · 数据导出 · 周期任务与旋钮校准信号 · 上线分级）、`contracts/compliance.md`（§5 四条拦截码求值顺序 · §8 §9 §10 指路与 `downloadUrl` / `downloadExpiresAtUtc` 读法澄清 · Open questions 收口）、`systems/account.md`（三张新表承重列 + `account.deleted_at_utc` + 四行事务边界 + 合规域服务端保证表）、`operations/environments.md`（旋钮清单 + 定时任务出口 + 区域与合规 + fail-closed 例外判据）、`operations/observability.md`（脱敏一条 + 探针三条）、`operations/deployment.md`（三张新表的迁移三步）、`operations/moderation.md`（风控事件 `kind` 增两值）、`answer-logs/log-compliance-domain-storage.md`
- counterpart: 无（客户端侧的合规流程编排已定：ticket 只在内存持有、不出任何 API 面、不落盘，`ticketExpiresAtUtc` 读取即丢弃——见 `game-design-documents/systems/services/account-service.md`。本 handoff 对客户端零义务、零发版）

## Intent（distilled）

契约把合规域的**语义**定完了（六端点 · ticket 的一次性与 60 秒回放 · 冷静期 15 天 · 导出四状态与 `taskId` 形态 · 保留期），但**怎么存、怎么调度、怎么签链接**全部空着。三项互相独立，缺的却是同一类东西：载体 · 键 · 生命周期 · 并发保证。本次一次补齐，并给三个旋钮补上校准信号。

**全部「到期 / 消费时刻 / 保留期」判定的时钟基准取自同批的 `2026-09-06-trusted-server-clock`**（该次事务的数据库时钟）。本 handoff 不复述那一半的论证——冷静期到期与未成年时段判定同吃一个时间源，口径必须只有一份。

### 一、`complianceTicket`：Postgres + 条件更新

载体是 Postgres 而非 Redis：ticket 的消费态是权威状态，且**消费标记必须与它守护的状态写入同事务**——这与 `signin_replay` 落关系库是同一条判据的第二个实例。存哈希不存明文；快照只装应答体，姓名 / 证件号不进任何一列。

一次性与 60 秒回放**不冲突**：一次性约束的是副作用，回放只是重发一份已产生的应答。落成一次条件更新 + 受影响行数分支，并把消费时刻的 `expires_at_utc` 拉到 `max(原值, 消费时刻 + 60 秒)`——**回放窗口做成寿命的延长而不是第二把尺**，「同时已过期且在窗口内」这个契约没定过口径的边角因此消失，求值顺序可以放心写死。

外部核验调用不放进持锁事务：取「占位消费 → 调核验 → 第二次事务写结果与快照」两段，中间态回 `server.unavailable`（契约已有的 `Retryable`），**终局出路是重走 `signin` 拿新 ticket**——实名状态仍未提交、拦截恒成立，故代价上界是一次重新登录，不需要补偿任务。

### 二、注销冷静期：独立表 + `SKIP LOCKED` 周期扫描

状态落独立表，`account.status = pendingDeletion` 由「存在处于冷静期的行」派生，契约四值一字不改。**`previous_status` 是承重列**：受限 / 封禁账号同样可以申请注销，撤销时若置回 `active` 就成了洗白风控处置的路径，而这一处漏掉后线上不可发现。

跨天长时状态机对可靠调度的追加要求由单库满足：周期扫描 + `FOR UPDATE SKIP LOCKED`，**零新增组件**——多副本安全靠 `SKIP LOCKED`、幂等重入靠条件转移 + 回滚重领、到期精度要求极低（15 天误差几分钟无语义影响，这正是不引入调度中间件的判据）、与撤销的竞态靠同一行的行锁。

执行按数据类别逐表硬删，一次事务全有或全无。**两条保留**：`receipt_idem` 全行（防重复发放的唯一防线，删了即「买 → 注销 → 重建号 → 再核销同一张票」且线上不可发现）与最小 `account` 墓碑（否则收据记录的账号列悬空、退款对账断链）。墓碑不含个人信息、不可关联到自然人、不进 status 枚举。

### 三、数据导出：私有桶 + 每次现签短寿命链接

任务表带一条部分唯一索引，把「同时至多一个在办任务」的幂等语义落成**数据库不变式**而非应用层先查再插。产物进私有 bucket，**绝不走 CDN**（含个人信息的对象会被复制到全部边缘、缓存寿命不受保留期控制）；对象键与 `taskId` 解耦，使「拿到 `taskId` 即能构造对象路径」不成立。

链接**每次查询现签一枚 15 分钟有效的预签名 URL**；`downloadExpiresAtUtc` 回答的是「产物还能取到多久」，不是链接寿命。照字面签 7 天等于签出一枚长期有效、无鉴权、可直下个人信息文件的凭据。保留期两道（应用层扫描为主 + 桶生命周期兜底留余量），缺任一道都出事：缺兜底是个人信息无限期留存，缺主路径是客户端拿到指向已删对象的链接。

### 四、三个旋钮：初值不动，补校准信号

实名提交上限 · 导出申请限流 · `pollAfterSeconds` 三个初值**确认沿用契约既有取值**，本次补的是「线上哪个指标动了就该改这个值」。另新增三个旋钮（导出链接单次有效期 · 导出生成重试上限 · 合规周期任务扫描间隔）。实名限流的计数落 Postgres 且 fail-closed——核验按次计费，命中「错误放行的代价不可回收」这条既有例外判据；导出限流零新增存储，任务表本身就是计数器。

## Clarifications

- **注销执行的删除深度** → 保留 `receipt_idem` 全行 + 最小 `account` 墓碑；identity / 存档 / 实名材料 / 风控事件照常硬删（2026-09-06 批量评审裁决）。全量硬删会打开一个线上不可发现的重复发放漏洞；把账号列匿名化则断掉退款对账并需新增一套 id 空间。
- **`signin` 四条合规拦截码的求值顺序** → `account_deleting` → `account_restricted` → `realname_required` → `playtime_blocked`（2026-09-06 批量评审裁决）。它消除了「受限账号申请注销后无路可撤、15 天被不可逆删除」这条死路，且风控不松动（撤销端点不签发会话）。「不定顺序、由实现自行决定」被否决——那会让该死路以随机概率发生且不可复现。
- **该求值顺序落在哪份文档** → 落 `contracts/compliance.md` §5，运维文档只回链不复述。依据是本库既有先例：决定应答唯一性的求值顺序一律写在契约侧（refresh 的五分支、同步侧的判定顺序皆是）。它不新增 / 不改动任何 `code` · `class` · 字段 · 状态机取值，**不是契约变更**（自行推演）。
- **ticket 消费与业务写入「同一事务」的准确形态** → 收窄为「消费标记与它守护的状态写入同事务，外部 HTTP 调用是唯一例外」，并补写两段事务之间崩溃的终局出路。原表述与后文的两段事务建议自相张力，按工程常识（外部调用不入持锁事务）收敛（自行推演）。
- **注销撤销后的行处置** → 撤销即删行，状态取值收敛为三个（冷静期中 · 执行中 · 已执行），不保留「已撤销」取值与撤销时刻列。草稿的备选方案已否决「由这张表承担历史归档」，申请 / 撤销留痕交风控事件流（自行推演，消除表定义与落地分支之间的残留不一致）。
- **新增旋钮个数** → 三个（导出链接有效期 · 导出重试上限 · 扫描间隔）。原文小标题写「两个」而其下列三行、后果段亦写「增三行」，取三个并去计数化（自行推演）。
- **风控事件 `kind` 增两值** → 增 `DeletionRequested` / `DeletionCancelled`，清单本就声明可增量、未知取值不驱动判定（自行推演）。

## Open questions

（无——本 handoff 范围内无用户当下答不出的远期未知。**实名核验服务商的选型与灾备**仍在 `open-questions/06-platform-stack.md`，它只影响外部核验调用的适配器细节与超时值，不改变本次任何形态；**合规能力的上线分级**仍在 `open-questions/02-account-compliance.md`，它决定的是落地时点而非形态。）

## Notes / triage

- 报文面零改动：不新增 / 删除 / 改动任何字段、端点、错误码、`class` ⇒ 不 bump `openapi.yaml` 的 `info.version`，不触发契约变更的三条机检断言。
- 存储 / 迁移影响：三张新表 + `account` 上一个已删除时刻列，走 expand → deploy → contract；线上尚无真实账号，**无既有数据迁移**。

## 客户端侧影响

无。ticket 的持有形态、`ticketExpiresAtUtc` 的读取即丢弃、导出链接「拿到即用系统浏览器打开」均为客户端既定行为，本次一条都不改；`downloadUrl` 每次查询各不相同这一点，客户端的既有用法天然兼容（它不缓存该值）。

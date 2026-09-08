# Answer log compliance-domain-storage

- 日期：2026-09-06
- 来源：`inbox/archive/solution-draft-compliance-domain-storage.md` → `handoffs/2026-09-06-compliance-domain-storage.md`
- 移出条数：1（`open-questions/06-platform-stack.md`「合规域的存储与产物」整条，含其从属项「合规域三个旋钮的初值待实测校准」）

## 移出的条目

**合规域的存储与产物** —— 三项：`complianceTicket` 的存储与一次性消费保证（含 60 秒兑付回放窗口）· 注销冷静期这条跨天长时状态机的调度形态（到期生效、撤销、幂等重入）· 数据导出产物的存储与下载链接签发（产物含个人信息、保留期 7 天、链接不得可枚举）
→ **三项均已落定，无新增存储组件、无新增契约面。**

- **ticket** 落主库一张表（消费态是权威状态，且消费标记须与它守护的状态写入同事务——`signin_replay` 那条判据的第二个实例）；存哈希不存明文；快照只装应答体。一次性与 60 秒回放靠一次条件更新 + 受影响行数分支兑现，**回放窗口做成寿命的延长而非第二把尺**，消除「同时已过期且在窗口内」这个契约未定口径的边角。外部核验调用取两段事务，中间态回既有的可重试码，终局出路是重走登录取新 ticket。
- **冷静期** 落独立表，`pendingDeletion` 由行派生（契约四值不动），`previous_status` 是承重列（防「申请注销 + 撤销」洗白风控处置，且漏掉后线上不可发现）；调度 = 周期扫描 + `FOR UPDATE SKIP LOCKED`，**零调度中间件、零消息队列、零分布式锁**；执行按数据类别逐表硬删、一次事务全有或全无。
- **导出** 任务表带部分唯一索引把幂等语义落成数据库不变式；产物进私有 bucket、**绝不走 CDN**；对象键与任务 id 解耦；链接每次查询现签、单次有效期 15 分钟；保留期两道（应用扫描为主 + 桶生命周期兜底留余量）；产物白名单加一条自动断言。
（归档去向：`operations/compliance-ops.md`、`systems/account.md`、`operations/environments.md`、`operations/observability.md`、`operations/deployment.md`、`operations/moderation.md`）

**从属项：合规域三个旋钮的初值待实测校准**（实名提交次数上限 · 导出申请限流 · `pollAfterSeconds`）
→ **三个初值确认沿用契约既有取值、一个都不改**；本次补的是各自的**校准信号**（线上哪个指标动了就该改这个值），并新增三个旋钮（导出链接单次有效期 · 导出生成重试上限 · 合规周期任务扫描间隔）。计数落点两条：实名限流落 Postgres 且 fail-closed（核验按次计费，命中「错误放行的代价不可回收」这条既有例外判据）· 导出限流零新增存储（任务表本身就是计数器）。
（归档去向：`operations/compliance-ops.md`「周期任务与旋钮的校准信号」；旋钮清单登记在 `operations/environments.md`，取值权威仍在 `contracts/compliance.md` §9）

## 同批裁决（随本次移出一并定案）

- **注销执行的删除深度** → 保留 `receipt_idem` 全行 + 最小 `account` 墓碑（墓碑不含任何个人信息、不可关联到自然人）；identity / 存档 / 实名材料 / 风控事件照常硬删。全量硬删会让「买 → 注销 → 重建号 → 再核销同一张收据」成为可反复白得商品且线上不可发现的路径；把账号列匿名化则断掉退款对账并需新增一套 id 空间。该裁决同时坐实了收据幂等记录冷存归档方案的承重前提「哨兵行永不删」。
- **`signin` 四条合规拦截码的求值顺序** → `account_deleting` → `account_restricted` → `realname_required` → `playtime_blocked`。它消除「受限账号申请注销后无路可撤、15 天被不可逆删除」这条死路；风控不松动（撤销端点不签发会话）。「不定顺序」被否决——那会让该死路以随机概率发生且不可复现。落 `contracts/compliance.md` §5（决定应答唯一性的求值顺序一律写在契约侧），不新增任何 `code` / `class` / 字段 ⇒ 非契约变更。

## 未答定 / 仍开放

- **实名核验服务商与灾备** —— 仍在 `open-questions/06-platform-stack.md`。它只影响外部核验调用的适配器细节与超时值，不改变本次任何形态。
- **合规能力的上线分级** —— 仍在 `open-questions/02-account-compliance.md`。它决定的是落地时点而非形态；`operations/compliance-ops.md` 已预留逐组标注档次的位置，本次不代为分级。

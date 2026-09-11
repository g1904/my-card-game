# Open questions — 后端待答清单（索引）

> 本文件是**后端**（云端服务）待答清单的**索引**；
> 问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 客户端侧的待答清单在 `game-design-documents/open-questions.md`（`game-design` 分支），
> 两份互不覆盖：**一个问题落在哪一侧，看它由谁实现**。
>
> 此清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；
> 一旦答定就从分片中移除、归档进对应主题文档，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> **最近更新：2026-09-11** —— 清单重整：零移出，补登跨边界承接 1 条（客户端 `ADR-0255`）（详见 `open-questions/update-log.md`）。
> （逐次更新摘要见 `open-questions/update-log.md`；答结归档见 `answer-logs/`。）

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身。 |
| `open-questions/01-contracts.md` | **① 协议契约**（六份已成文，待答已清零）：展开见表下 |
| `open-questions/02-account-compliance.md` | **② 账号与合规**（待答已清零，余一条外部事实挂账项）：展开见表下 |
| `open-questions/04-content-delivery.md` | **④ 内容分发（CDN）**（待答已清零，余条件化核对项与指路）：展开见表下 |
| `open-questions/06-platform-stack.md` | **⑥ 技术栈 · 托管 · 运维**（栈与运维形态已落定）：余**两条待实测取值**——成本模型 · `riskEventBufferRows`；另有一节条件化核对项（昵称审核阈值，首版不启用故不定值）。 |
| `open-questions/07-internal-tools.md` | **⑦ 内部运营工具**（人工处置面，权威落点 `operations/internal-tools.md` 已建立）：开片两条已答结，余两条相邻真空——告警接收人 / 值班形态 · 客服侧的账号查询入口。 |
| `open-questions/cross-boundary.md` | **跨边界承接**：客户端已定案、本库尚未落笔的条目。常态下**不是待答问题**——答案已有，等的只是落笔；形态与关闭条件见分片抬头，机制设计见客户端库同名分片。**现有 1 条**（客户端 `ADR-0255` 付费解锁角色系列，2026-09-11），且该条对侧亦明写载体形态未定 ⇒ **例外地是待答 / 提案形态**，本库不预设形态、不代为裁决。 |

分片展开（承接上表）：

- **`01`** —— 六份契约**全部完全成文**（→ `contracts/envelope.md`、`content-manifest.md`、`auth.md`、`profile-sync.md`、`purchase.md`、`compliance.md`）；
  三条机检断言的工程承载亦已答结（设计库分支上的独立 workflow）。**待答已清零**：flags 端点零装载的错误应答裁定为**不新增专属码、维持 `server.unavailable`**（判据落 `envelope.md` §6 承重项，台账表零增减）。
  契约面只余 `openapi.yaml` 与 `schemas/*.json` 尚未落笔——属**待落笔项而非设计未决**。
- **`02`** —— **待答已清零。** 身份模型、合规落地与多设备裁决、昵称审核口径、存量扫描、风控落地形态、**合规能力的上线分级（四项全部首版必备 · 昵称审核留位不启用）**均已答结
  （→ `contracts/auth.md`、`contracts/compliance.md`、`operations/moderation.md`、`systems/account.md`、`operations/deployment.md`、`operations/compliance-ops.md`、`vision/scope.md`）。
  余一条**挂账项**（须以真实过审要求核实，不是设计待答）：实名核验是否另需对接主管部门的实名认证系统。
- **`04`** —— 协议四条与运维三条均已答结（→ `contracts/content-manifest.md`、`operations/content-delivery-ops.md`），
  **剧本分包边界已由对侧答结**（不分包 → 客户端 `ADR-0029`，本库零机制增量）；
  **待答清单已清零**：多区域一致性以否定结论答结、传播窗口 T 重定义为跨实例窗口并取定初值。余一节条件化核对项（不是待办）与一张「已推给别处的」映射表。
- **`06`** —— 技术栈、托管形态与运维形态**均已落定**（C# / 腾讯云托管容器 / PostgreSQL 单主 / Redis / KMS / CDN，→ `systems/`、`operations/` 九份文档）；
  余下**两条**只差实测数据：成本模型（含收据归档与对账阈值的定值、剧本下载量上界）· `riskEventBufferRows`（风控事件旁路缓冲上界）。昵称审核两阈值已随 `02` 答结转为条件化核对项（首版不启用 ⇒ 不定值）。
- **`07`** —— **开片两条已答结**：内部人员身份定为本库自己的 `operator_id`（与 `account` 完全分离），复核台与风控工单共用同一套身份、同一个 `/internal/` 面与 CLI 调用方；权威落点 `operations/internal-tools.md` 已建立，`claimed_by` 的取值域与外键落定，「自动化止于工单」的工单落点自此有归属系统可指。
  **余两条**（本次落笔中显式化的相邻真空，均不阻断已落笔形态）：告警接收人 / 值班形态（全库告警共用的真空）· 客服侧的账号查询入口（可见字段范围须单独裁决）。

> **编号 `05` 已空缺**：原「⑤ 剧本下发」分片于 2026-08-11 随云端剧本服务撤销而**整片删除**
> （剧本内容本地化为客户端内容层，见 `handoffs/2026-08-11-plot-service-retired.md`）。
> 编号不回填、不重排——`06` 的编号在别处已被引用，重排的代价高于留一个空位。
>
> **编号 `03` 已空缺**：原「③ 存档同步 / 冲突」分片于 2026-08-14 随 `contracts/profile-sync.md` 成文而**整片删除**
> （五条全部答结或被契约覆盖，实现层面的部分并入 `06`，见 `handoffs/2026-08-14-profile-sync-contract.md`）。
> 同样不回填、不重排。

## 当前焦点：待实测取值与外部事实为主，设计取向面已基本清空

**六份契约全部完全成文**——

- `envelope.md`（边界层，08-11）
- `content-manifest.md`（内容分发，08-11）
- `auth.md`（登录与会话，08-13）
- `profile-sync.md`（存档同步，08-14）
- `purchase.md`（付费验票与后端权威写入，08-16 · 三渠道接入面 09-03）
- `compliance.md`（实名 / 防沉迷 / 注销 / 导出，08-16 · 六端点报文字段表与端点自身错误码 09-03）。

**技术栈、托管形态与运维形态均已落定**（C# / ASP.NET Core · 腾讯云托管容器 · PostgreSQL 单主 · Redis · KMS · CDN），
`systems/` 三份服务文档与 `operations/` 九份文档全部建立——全库再无结构性前置。**合规能力的上线分级亦已答结**（四项全部首版必备 · 昵称审核留位不启用 · 两份发布前置清单），**内部运营工具面亦已落定**（`operations/internal-tools.md`：`operator_id` 内部身份 · `/internal/` 不属于契约面 · CLI 调用方 · 复核台与 `ops_ticket` 工单台），`01` 分片待答清零。焦点因此落在三类：

1. **`06` 两条待实测取值** —— 成本模型（实例规格 · 灾备副本数 · CDN 成本 · 收据归档与对账阈值的定值 · 剧本下载量上界，共同前置是 DAU 预期）· `riskEventBufferRows`。两条都不取决于任何形态决定。
2. **`07` 两条相邻真空** —— 告警接收人 / 值班形态（全库工程级告警共用同一个真空：有口径、无接收方）· 客服侧的账号查询入口（可见字段范围须单独裁决）。两条均不阻断已落笔的任何形态。
3. **两条须以外部事实核实的项，不是设计待答** —— `02` 的挂账项（实名核验是否另需对接主管部门的实名认证系统，须以真实过审要求核实）·
   微信开放平台资质的审批到位时刻（`operations/external-providers.md` · `operations/deployment.md` 第一份前置清单第 4 项）。两者的共同处置都是：未到位则**推迟上线**，不降级放行。

## 判据：一个问题落在哪一侧

| 判据 | 归属 |
|------|------|
| 由客户端代码实现、后端不感知 | `game-design-documents/` |
| 由后端实现，或需要两侧约定报文 | 本库 |
| 客户端语义已定、只剩服务端如何兑现 | 本库（在条目中注明「客户端侧已定」+ 日期 + 回链） |

## derive 就绪度

> 本小节由 `/assess-derive-readiness` **独占写入**（`/analyze-new-ideas` 与 `/summarize-open-questions` 均不得改动）。就绪度需基于全库一次性全量扫描才有意义，顺带评估会迅速过时且互相矛盾。

**最近全量评估：2026-09-11（由 `/assess-derive-readiness` 产出）。** 扫描范围：`vision/`（2）· `contracts/`（7 份 `.md` + `vectors/splitmix64.json`）· `systems/`（`_index.md` + `account.md` + `profile-store.md` + `content-delivery.md`）· `operations/`（`_index.md` + **10 份正文**）· `decisions/`（**63 份 ADR，全部 Accepted** + `_index.md`），共 **89 份**（09-09 为 88，增量 = `ADR-0063`）。旁证：`requirements/` **零 FR**（无「已覆盖」项）· `handoffs/` **42 份全为 `distilled`** 且 42 行台账逐条对齐 · `inbox/` 顶层为空（`archive/` **38 ↔ 38**，直读订正——09-09 记的「39 ↔ 39」把 `_index.md` 自身算进了文件数）· `answer-logs/` 35 ↔ 35 · `operations/_index.md` **10 ↔ 10** · `systems/_index.md` 3 ↔ 3 · `decisions/_index.md` **63 ↔ 63**。

**全局结论：ready 14 份 · partial 4 份 · blocked 其余（全部为非 derive 对象或结构性 blocked）—— 三档较 09-09 零变动，全库仍无 🔴 就绪度卡点，可以开始 derive。** 本次评估与 09-09 之间，**全库主题文档零编辑**：唯一增量是 `decisions/ADR-0063`（人类身份对业务表恒只有 `SELECT`，一切写入经服务端受控面，2026-09-09 定案 · Accepted · 由 `/write-adr backend` 于 09-11 立档）。它把一条此前只散落在 `operations/internal-tools.md`「界面档次」与 `operations/content-delivery-ops.md` A3 的**全库通则**固化为决策记录，因此：① 不改变任何一份文档的档位——它固化的是既有正文，不是新机制；② 使 `operations/environments.md` 的「权限与凭据面」多出一条**可直接转验收的否定断言**（人类身份对任何业务表无 `INSERT` / `UPDATE` / `DELETE`），该文件的就绪切片**略扩**、判定仍为 partial（其卡点始终是非 FR 面的成本模型取值）；③ 使 `internal-tools.md` / `moderation.md` / `content-delivery-ops.md` 的判据 3（约束它的 ADR 均为 Accepted）多一条明确前置，三份维持 ready。

**09-09 那份评估的以下条目本次订正：** ①「62 份 ADR」「台账 62 ↔ 62」「`ADR-0001` ~ `ADR-0062`」→ 全部为 **63**、`ADR-0001` ~ `ADR-0063`（逐份核对，非 Accepted 者 **0** 份，连号无缺）；②「共 88 份」→ **89 份**；③「`archive/` 39 ↔ 39」→ **38 ↔ 38**（口径订正，非漂移）；④ 漂移清单第 11 条（`internal-tools.md:83` 的「人类身份恒只有 `SELECT`」具备独立 ADR 全部特征却未固化，是否提升属用户裁决）→ **已由 `ADR-0063` 兑现，销号**，清单其余条目顺次重编号。

**三条贯穿全库的判据说明（先读，避免误判）：**

- **判据 1 的形式说明（沿旧）。** 六份契约中只有 `content-manifest.md` 带正式 `## 意图` 标题；其余五份把同等分量的范围陈述放在标题下的 `>` 前言里。**全库无一处模板占位符 `> _..._`。** 判据 1 按「有真实内容」判定，**不按标题字面判定**。
- **库级 derive 限定语（沿旧，仍成立）。** `contracts/envelope.md` §1 自陈「在某端点的 spec 落笔前，其 markdown 字段表视为草案」。**处置不变：以 markdown 为源 derive，待 `openapi.yaml` 落笔时做一次纯形态对账——不作为闸门。** `openapi.yaml` 与 `schemas/` 至今不存在，符合「不预先建空壳」，触发点是任一侧首个端点进入实现。
- **「非 FR 面」不是欠账。** `vision/` 两份（北极星与五条裁决原则）、各 `_index.md` 台账、`vectors/splitmix64.json`、63 份 ADR 按定义就不是 derive 对象，**永远判 blocked 不代表缺内容**。给它们补验收标准会把北极星文档变成第二份契约。
- **内部面（`/internal/`）的 derive 归属（沿 09-09，仍成立）。** 内部端点**不进 `openapi.yaml`、不进 `envelope.md` §3 端点全集表、不进 §6 错误码台账**（`ADR-0062`）⇒ 为它写 FR 时，**「契约变更的完成判据」六条与三条机检断言一律不适用**，正确性由 `internal-tools.md` 的 I1–I10 承担。用契约面的核对清单去卡内部面的 FR，会得出一个永远过不了的闸。**`ADR-0063` 同批适用**：它在内部面 FR 中写成否定断言，与 I1–I10 同体例。

**卡点结构：纯参数化（沿 09-09，本次零新增卡点）：**

- **🟠 `06` 两条待实测取值** —— 成本模型（共同前置 = DAU 预期）· `riskEventBufferRows`。两条**均不取决于任何形态决定**：能力要求、旋钮位置与校准公式已全部落笔 ⇒ derive 时一律写成「存在该旋钮 + 落 `config_knob` + 改值不发版」的形态断言，不取数字。同款纪律见 `profile-sync.md` §10 / §12。同类四项（`internal-tools.md` 数值初值表）：工单租约超时 60 分钟 · 工单终态保留 180 天 · 内部动作审计保留 1095 天 · 内部凭据校验失败告警阈值（不定值）——前三项有初值可直接写断言，第四项同款参数化。
- **🟠 `02` 一条外部事实挂账项** —— 实名核验是否另需对接主管部门的实名认证系统。它**不阻塞任何已落笔的形态**，按 `04` 分片先例写进 FR 的 Scope 段作条件化核对项，不作验收断言。
- **🟠 `07` 两条相邻真空（均不阻断 derive）** —— ① **告警接收人 / 值班形态**：全库工程级告警共用同一个真空（有口径、无接收方）。它是**运维配置面**，不产验收断言 ⇒ 不构成任何一份的就绪度卡点；② **客服侧的账号查询入口**：`internal-tools.md` 已明写它**不在本面内**，六端点最小集是封闭的 ⇒ 它决定的是「要不要在既有端点集之外再开一组」，属未来范围，不是当前文档的缺口。

**跨边界闭合（强制检查项）—— 本库欠对侧 0 条（台账口径）· 对侧欠本库 0 条。本次无新增跨边界条目。**

- **`ADR-0063` 对客户端零影响**：其「后果」段末行逐字自陈「不触及任何契约报文、不新增 `code`，`game-design-documents/` 侧无需同步」。人类身份的库权限分层完全落在后端建库脚本内，结构性地不跨边界。与 `ADR-0061` / `ADR-0062` 同理。
- **本库欠对侧：0（09-08 的 2 条已于 09-09 登记进对侧台账）。** 对侧 `game-design-documents/open-questions/cross-boundary.md`「待承接」两条（`ADR-0051` manifest 路径分支拼法 · `ADR-0052` CDN 域 4xx 两分处置，均标 2026-09-07）**仍待对侧落笔**——那是对侧的待落笔项，**不是本库的台账欠账**。
- **两条常驻机械义务的本次核查结果**：① `profile-schema-versions.md` 新增行 ⇒ 登进 `version-matrix.md`——**未触发**；② `auth.md` §4 任一条被改写 ⇒ 触发对侧重评 refresh token 本地存放取向——**未触发**（`auth.md` 09-08 之后零编辑，本次增量只在 `decisions/`）。
- **预警仍未触发**（两侧均已登记）：`characterProfile` 的资源字段一旦提进透明档，必须同批把钳制语义与 `AppliedChange` 累加语义写进 `profile-sync.md`。`profile-sync.md` 本批零编辑，相关字段仍落不透明段。

| 文档 | 判定 | 卡点 / 就绪切片 |
|---|---|---|
| `contracts/profile-sync.md` | **ready，无排除面** | 维持 ready（08-28 之后零编辑）。**就绪切片 = 全文**：§1 两端点封定 · §2 pull 三字段与建号骨架 · §3 六字段负载信封 + 空 diff 照常 `+1` + 未知 `reason` 宽容 · §3a 顶层键浅合并 · §4 三分支 + 幂等命中五行表 + 判定顺序 + 四类拒绝均不消耗 `revision` · §5 十三行白名单 + 后端写入封闭四行表 · §5a / §5b / §5c · §6 / §6a SplitMix64 + 8 组已填向量（外部权威 `vectors/splitmix64.json`，可逐位断言）· §7 复算三检查 · §7a 仅记账不拒绝 · §8 账号级线性化 + 读己所写 · §9–§12。`## Open questions` 明写无待答项。**三条参数化纪律（不是排除面）**：风控事件写成「记一条结构化事件」· §10 的 60 次 / 分钟与 §12 四个初值写成配置阈值 · §4 的「`schemaVersion` 越出兼容集合」分支只断言形态、不断言边界 |
| `systems/profile-store.md` | **ready，无排除面** | 维持 ready（09-06 之后零编辑）。**就绪切片 = 全文**：承重列四表 · 事务边界四行 · 四条实现纪律（CAS 用受影响行数分支 · 判定顺序照契约写死 · 类型感知语义相等 · 零判定权字段关闭 enum 严校验而驱动判定的枚举仍封闭）· 两类幂等记录的分轴对照 · `push_idem` 月分区 · `receipt_idem` 全局唯一键与同事务序号推进 · 读己所写 · 512 KB 体积软告警。依赖全闭合；`ADR-0008` · `0013` · `0017` · `0021` · `0045` 全 Accepted |
| `contracts/purchase.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片 = 全文**：§1 三端点 + 全部需鉴权 · §2 写入只由 verify 承担、回调降为对账 · §3 请求根判别式（`ADR-0018`）+ 六行失败面表 · §3a 三张渠道 `receipt` 字段表 + 三张渠道状态映射表 + `receiptId` 三渠道前缀 / 字符集 / 上界 1024 · §3b 下单端点与 `Unknown` 预落记录（`ADR-0019`）· §4 `status` 三值 + `Rejected` 复用 verify 终态 `code`（`ADR-0046`）· §5 复算沿用 §7a · §6 七条栈中立服务端保证 · §7 `receiptId` 全局唯一键 + 永久保留。`## Open questions` 自陈无待答项。**参数化项**：归档触发三阈值与对账信号 N 待实测，形态、旋钮 key 与校准公式已由 `purchase-ops.md` §3d / §4 与 `ADR-0045` 定死 |
| `operations/purchase-ops.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片 = 全文**：§1 三渠道凭据与轮换 · 托管形态 · 收据环境校验以部署环境配置为准 · §2 三条对账通道 + 对账不驱动任何自动写入 · §3a S1–S3 选型判据 · §3b 哈希分区与部分索引 · §3c TTL 禁用断言 · §3d 三层分工 / 哨兵行五列 / 读路径五分支 / 归档任务三步顺序不可颠倒 · §4 两条对账信号与 N 的校准公式 · §5 风控高优四项。**三块排除面**：§3a 退化形态 · §3d 归档任务（`receiptArchiveEnabled` 初值 `false`）· 下单端点的滥用阈值（无初值、无旋钮 key ⇒ 只能写形态断言；该处另有一条遗留旧就绪度断言，见漂移清单第 2 条） |
| `contracts/compliance.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片 = 全文**：§2 六端点集与鉴权形态 · §3 ticket 机制（一次性 · 10 分钟 · 单端点 · 60 秒兑付回放窗口 · 兑付不签发 token）· §4 拦截只在 `signin` · §5 四条 `compliance.*` 拦截码 + 七值 `reasonKey` 表 + 求值顺序写死（`ADR-0037`）· §6 时段口径落配置 + 可信服务端时钟 · §7 防沉迷复用 `auth.session_revoked` 五步映射 · §8 导出正列白名单 · §9 九行旋钮初值 · §10 六端点报文字段表 · §11 三条端点自身错误码。`## Open questions` 章节整体不存在 ⇒ 判据 2 直接成立 |
| `operations/compliance-ops.md` | **ready** | 维持 ready（本批零编辑；09-09 的增量为注销删除清单新增 `operator_audit` **保留全行**，判据与 `deletion_audit` 逐字相同）。**就绪切片 = 全文**：可信时钟基准与两处例外 · 同步纪律 · 时段规则集承重列与「判定时读当前最高版本、不做预约生效」· 法定节假日日历四步判定顺序 · F1 / F2 / F3 三个失败面的降级语义 · ticket 条件更新 + 五级短路求值顺序 · 外部核验两段事务 · 注销冷静期状态三值与三端点分支 · **执行时删什么已扩至含 `operator_audit` 保留行的完整表** · 导出任务三条断言与两道保留期 · 周期任务四条与八个旋钮 · 上线分级四行表。ADR 前置齐备（`0028`~`0037` 全 Accepted）。**条件化核对项（不作验收断言）**：`02` 的主管部门实名认证接入义务 |
| `operations/external-providers.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片 = 全文**：A1–A6 共有形状 · 四个接口签名 · 三张归一映射表 · 逐能力供应商数与灾备判据表 · 短信切换触发判据与回切滞后 · 禁并发双发 / 同码转备用至多一次 / 禁双验 · 「一次 `challenge` 至多两次外部调用」· 选型判据 H1–H4 / S1–S4 · 凭据托管（能力 × 供应商 × 环境）· 可观测性五行增量与余额低水位两档 · 微信资质过闸断言 · 数值初值六行。`ADR-0038`~`0042` 全 Accepted。**排除面两块**：不点名具体服务商（A6 把归一点放在调用方，FR 因此与服务商无关，这正是该抽象的目的）· 微信资质前置链（外部审批日程，非 FR）。第三方昵称审核能力面写否定断言（供应商数 0，`ADR-0055`） |
| `contracts/auth.md` | **ready** | 维持 ready（09-08 之后零编辑——`ADR-0061` 明写内部人员不挂进 `account`、不污染 §3a 渠道语义，`ADR-0063` 只约束库权限层 ⇒ 本文件结构性地不受三份新 ADR 影响）。**就绪切片 = 全文**：§1 / §1a 七端点 + 身份模型 · §2 双 token 与 TTL 表 · §3 / §3a 渠道分形与换 openid 三条义务 · §4 rotation + 60 秒宽限 + 四分支求值顺序（三种情形共用 `SessionExpired`，`ADR-0053`）· §4a 会话裁决 · §5 / §5a / §5b · §6 头矩阵 · §7 七端点重放表 · §8 报文 + 四级短路判定链 + 13 行旋钮初值表 · §9 五个错误码 · §10 两张取值表 · §11。`## Open questions` 自陈「无待答项」。**排除面（已裁决的否定断言）**：判定链第④级第三方审核适配器写成「恒返回 Pass、不产生任何外部调用」 |
| `systems/account.md` | **ready**（排除面一块） | 维持 ready（本批零编辑）。**就绪切片 = 全文**：存储形态承重列**十五表**（含 `operator` · `operator_identity`（留位）· `ops_ticket` · `operator_audit`）· 事务边界**十行**（含复核领取 / 复核判定 / 工单处置三行，工单处置行含 `SELECT … FOR UPDATE on account` + `baseAccountStatus` 不等即拒）· 注销执行行的删除清单含 `ops_ticket` 硬删、`deletion_audit` 与 `operator_audit` 双保留 · `tokenId` 与 `sid` 的分工 · refresh token 五分支校验 · access token 签发四条 · 渠道能力适配层两条纪律 · 昵称判定链 N1–N10 · 存量扫描 S1–S5 · 合规域 C1–C6 / D1–D7 / E1–E6 / P1–P5。`claimed_by` 取值域已由 `ADR-0061` 定死（`text` + 外键 `REFERENCES operator(operator_id)` + 来源恒取自已认证凭据）。无 `## Open questions`。**余下唯一排除面**：判定链第④级 + N9 → 写「恒返回 Pass、不产生任何外部调用」。**参数化纪律**：改名频次上限 · ticket 寿命 / 60 秒回放 · 冷静期 15 天 · 导出保留期一律写「配置阈值」 |
| `operations/internal-tools.md` | **ready**（判据 3 前置本次再加固） | 维持 ready（本批零编辑）。`ADR-0063` 本次立档，把本文件「界面档次」段的「人类身份对业务表恒只有 `SELECT`」由**正文自陈的全库通则**升为**已采纳的决策记录**——三条 ADR 前置（`0061` 身份分离 · `0062` 内部面不属契约面 · `0063` 人类身份只读）自此齐备。**就绪切片 = 全文**：内部身份 `operator_id`（`op_` 前缀 · `credential_hash` 存 SHA-256 · 只停用不删行 · 与 `accountId` 两个永不相交的命名空间）+ **全库四处「操作者」空洞的唯一取值域**（`publishedBy` ×2 · `published_by` ×2 · `config_knob` 更新者 · KMS 解包审计「谁」）· 认证（`Authorization: Bearer <operator_id>.<secret>` · 不签发会话不做 rotation · 轮换 = 新行 + 停用旧行 · 企业 IdP 留位不启用且写死启用触发条件 · 第五类托管条目 operator × 环境）· **`/internal/` 不属于契约面的三条判据 + 六端点最小集 + 「明确不提供任意查询面」**· 界面档次 CLI + 「人类身份对业务表恒只有 `SELECT`」（`ADR-0063` ⇒ 可写成否定断言：人类身份无 `INSERT` / `UPDATE` / `DELETE`，且权限分层落在建库脚本里）· 复核台 `claimed_by` 四行机械形态 + `decision` / `enqueue_reason` 取值域 + 判 `Violation` / `Clean` 各自的一次事务清单 + 「云端昵称一字不变」· `ops_ticket`（软引用两列不建外键 · `UNIQUE (account_id) WHERE state IN ('Open','Claimed')` · 租约 60 分钟 · `decision` 三值 · `note` 不记个人信息不作举证）· 处置事务边界五步伪码 + `baseAccountStatus` 乐观前置 · `operator_audit`（`context` 只装内部键与结果 ⇒ 保留 3 年、注销不删）· **可见字段范围三行表**· 上线时点（不进第一份清单、进第二份）· **服务端保证 I1–I10**（与 N / S / C / M / F 同体例，逐行可直接转验收）· 数值初值四行。**两块排除面（均为文档自陈的范围外项，不是卡点）**：① 告警接收人 / 值班形态（运维配置面，全库共用的真空，不产验收断言）；② 客服侧的账号查询入口（明写不在本面内，六端点最小集是封闭的 ⇒ 属未来范围）。**derive 时注意**：`ADR-0062` ⇒ 本份 FR **不适用**「契约变更的完成判据」六条与三条机检断言 |
| `operations/moderation.md` | **ready** | 维持 ready（本批零编辑）。09-09 消解的唯一卡点（🔴 `07` · 判据 5 孤儿路径）未反弹：`:reviewer` 恒为 `operator_id`、由服务端从已认证凭据解析、绝不接受请求体传入；「自动化止于工单」的工单落点为本库 `ops_ticket` + 内部端点。`ADR-0063` 本次为 M6 / M7（「恰好被一人领到」「迟到提交被拒」）补上它们一直缺的显式前置——**没有人能绕过服务端直接改库**，两条保证自此不再停在评审级。**就绪切片 = 全文**：词表两档分级与不可变版本化发布（三条来源通道收敛到同一次发布动作）· 存量扫描 T1 / T2 / T3 与台账六字段 · 处置阶梯三档 · `nicknameChangeRequired` 由云端状态算出 · 风控事件字段表与 `kind` 十值 · 累计阈值分档与全局熔断（1% / 0.5%）· 四张台账的存储形态整节（`risk_event` 月 RANGE 分区与整分区 `DROP` · 主键 `(occurred_at_utc, event_id)` · 不建 rollup · 旁路有界缓冲与三类同事务例外 · `deletion_audit` 3 年不删 · `nickname_review` 条件 `UPDATE` 取租约含 SQL 骨架 · 过期方向判据表）· **服务端保证 M1–M11** · 数值初值表 16 行。无 `## Open questions`。**排除面一块**：第三方昵称审核适配器首版不启用（`ADR-0055`）⇒ 写否定断言。**建议与 `internal-tools.md` 同一波 derive**——两者是同一条人工处置纵向切片的两端 |
| `contracts/content-manifest.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片 = 全文**：端点四行表（含字面量 `public, max-age=31536000, immutable`）· `manifestSchema: 1` 八行字段表 + 全量清单 / 路径穿越 / semver 三段比较 · ES256 detached（P1363 `r‖s` 非 DER · `keyId` 轮换 · 拒绝 `contentVersion` 回退）· 三版本号分工 · A 组四条 + B 组三条与三个失效来源 + `X-Flags-Version` 取 `min(高水位, 本实例可兑现)`（`ADR-0047`）· 路径分支 `<contentRoot>/s<manifestSchema>/manifest`（`ADR-0051`，blob 不分支）· CDN 三端点失败状态码 11 行表与 4xx 两分判据（`ADR-0052`）· flags 报文五字段（`enabledIds` 恒空是硬契约）· 对客户端缓存的四行零义务否定表 · `## blob 通道不承载二进制资产`。全文无 `## Open questions` |
| `systems/content-delivery.md` | **ready**（排除面一块） | 维持 ready（本批零编辑）。**就绪切片 = 全文**：三份缓存的分工表（键 · 值 · 位置 · 生命周期，并写明混用任意两份各破坏哪条纪律）· 规则集缓存必须进程内不得落 Redis 的承重理由 · single-flight 回源 · 版本预热的请求无关触发（`ADR-0060`）· 「一次快照引用」的应答构造手法 · `X-Flags-Version = min(高水位, 本实例可兑现)` 与偏斜不对称性 · 取数面 = 已装载的最大键 · 回源失败三分支降级（F7 取兜底码 `server.unavailable`，09-09 已答结为否定结论）· LRU 上限 8 · 四条实现纪律 · **服务端保证 F1–F8**。**余下唯一排除面**：「存储形态：承重列」与「唯一写入面与事务边界」两节仍是回链占位（实体在 ops 的 A1–A3 / A5）⇒ FR 的 `Data & state touchpoints` 需跨文档取；方向反转已被 handoff 明写接受 |
| `operations/content-delivery-ops.md` | **ready**（判据 3 前置本次加固） | 维持 ready（本批零编辑）。`ADR-0063` 把 A3 的「人类身份对业务表恒只有 `SELECT`」正式固化为决策，并明写**权限分层落在建库脚本里**是存储选型判据的一条 ⇒ 该条自此可写成建库层的否定断言，而非仅正文约定。**就绪切片**：CDN 两类对象两种 TTL · 内容发布流水线 ⓪–⑦ 全序 + 双发期读法五条 · 发布侧校验闸 C1–C6（`ADR-0050`）· 留痕八字段（`publishedBy` 取值域 = `operator_id`）· A1–A5 规则集存储形态与变更通道（`publish` 为唯一写入面且 `rollback` ≡ `publish` · 直连写入权限禁止，`ADR-0063`）· flags 发布 / 回滚 O1–O7 与留痕四项 · B1–B5 私钥保管与 standby（`ADR-0049`）· `keyId` 轮换三类触发 / 四阶段 / 覆盖率 95% / T2 后 48 小时观察窗 · 传播窗口 T 的口径与三项预算 · 数值初值一览 10 行全部有初值。**排除面（文档自陈）**：A4' 池规模缩放（未采纳）· 对 CDN 的能力要求与三路径负缓存（基础设施配置）· 内容校验规则本体（权威在客户端库，`ADR-0048`） |
| `operations/deployment.md` | **partial**（小切片，主体属非 FR 面；可产出 FR 的面 4 处） | 维持 partial（本批零编辑）。**可产出 FR 的**：① 启动自检解析时区名失败即拒绝启动（`ADR-0029`）；② G-1「`/v1/auth/refresh` 上不存在任何返回限流码的限流」与 G-2「push 走应用层账号维度」两条否定断言；③ 第一份清单第 4 / 5 / 6 项的机检形态过闸断言；④ 第二份清单第 4 项「内部处置台可用」——本库少见的完整端到端断言（一次昵称复核领取 → 判 `Violation` → `nickname_scan.review_state` 落「须改名」档 → 云端昵称一字未变；一次工单领取 → `Ban` → 全部会话吊销 → 一条 `operator_audit` 已落；两条链路的应答与日志中 `realName` / `idNumber` 零出现），可**逐字**转成验收标准。**非 FR 面**：构建与制品 · expand→deploy→contract · 两份清单的人工过闸流程 · 周期性运维日程 · 共享 DTO 护栏 · 入站运维通道（堡垒机 / VPN）就位属基础设施配置。**未闭合项（自陈，非漂移）**：`contract-spec-check` workflow 与校验脚本**尚未落地**（本次复测：仓库仍无 `.github/`、无 `scripts/`）——注意它**不覆盖内部面**（`ADR-0062`） |
| `operations/environments.md` | **partial**（窄切片，宜随服务 FR 兑现；**切片本次再扩一条**） | 维持 partial（本批零编辑；切片因 `ADR-0063` 立档而扩）。**就绪切片**：「限流的实现分层」整节（fail-open 默认 · 三条 fail-closed 例外，`ADR-0031` · Redis 不可用放行并告警 · `refresh` 零限流的否定断言 · `Retry-After` 与 `detail.retryAfterSeconds` 同时给）· 密钥轮换「旧 `kid` 保留 ≥ access token TTL + 时钟偏移余量」· 定时任务出口的 `SELECT … FOR UPDATE SKIP LOCKED` 条件转移 · `identifier_mac = HMAC(...)` 明文不落库不落日志 · 本地开发 `kid` 空间与线上永不共用 · `config_knob` 的更新者与 KMS 解包事件审计的「谁」取值域为 `operator_id` · 本地 feature 环境用开发专用 operator、与线上 `operator_id` 空间隔离永不共用。**本次新增可断言项**：**权限与凭据面的否定断言**——任何人类身份对任何业务表**无 `INSERT` / `UPDATE` / `DELETE`**、无例外表，应用身份按表收紧（规则集表仅 `INSERT` + `SELECT`），且该分层**落在建库脚本里**（`ADR-0063`）；同源推论「内部人工处置不发放可写库凭据」亦可直接转否定断言。**其余属非 FR 面**：环境实体 · 配置三层与旋钮清单（数据登记）· 区域与合规 · 拓扑与副本 · 容量形状 · 密钥保管。**已声明的排除（非卡点）**：实例规格 / 副本数 / 备份保留期待成本模型（`06`） |
| `operations/observability.md` | **partial**（窄切片，宜随服务 FR 兑现） | 维持 partial（本批零编辑）。**就绪切片 = 探针发射面**：五条契约语义探针（「透明路径缺失」的带前提判定 · 「未知 `schemaVersion`」的按大小关系二分 · CAS 冲突率与回声拒绝率分开计数）· **日志脱敏中间件**（纯否定断言，且该断言的「应答」按 `internal-tools.md` 明写**已覆盖内部端点**，无需新造）· 合规域三条探针与时钟两条探针 · 日历到期告警 · flags 版本预热落后量 gauge（`ADR-0060`）· 风控台账四条探针（`risk_event` 分区裁剪滞后量是「个人信息超期留存」唯一的机制发现面；`nickname_review` 待办积压量与 `claim_attempts` 高位条目数正是内部复核台的容量信号）· flags 零装载失败计数器。**非 FR 面 / 参数化**：告警阈值与 P1 分级属运维配置 · RED / 连接池 / 复制延迟属基座通用监控 · 时钟两条探针阈值待实测校准。**注意**：`07` 的「告警接收人 / 值班形态」真空落在本文件的**下游**（接收方），不影响探针发射面的任何断言 |
| `operations/version-matrix.md` | **partial**（窄，宜随 auth / content FR 兑现；卡点不变） | 维持 partial（本批零编辑）。**就绪切片**：四项形态表 +「当前矩阵」四行 + `schemaVersion` 一版一行的四列子表并登入 `1`（第四列为客户端登记回链，本库一个字段名都不写——可作否定断言）· 「闸门在签发 token 时判定一次、会话期内不中途变严」· 「提升 `appVersion` 下界的覆盖上限 = refresh 绝对寿命」· `schemaVersion` 登记流程「矩阵先加、客户端后发」的顺序断言 · `manifestSchema` 双发下线序列 T0 / T1 / T2 三时点完整落表并回链 ops 的覆盖率口径（`ADR-0051`）。**卡点仍为两个取值**：`appVersion` 下界「待定」· `schemaVersion` 行的「接受起始」为「首个版本上线时（待落）」⇒ `client.version_unsupported` 与 `sync.payload_schema_unsupported` 两码的**形态可断言、边界不可断言**，并向下传导进 `profile-sync.md` §4。矩阵数据本身是旋钮登记，属非 FR 面。**另有一处标签滞后**（`manifestSchema` 集合行值列仍写「待定」而括号内已给出 `{1}`），见漂移清单第 6 条 |
| `contracts/envelope.md` | blocked（**结构性，非欠账**） | 共有层，**不存在独立可构建的增量**（无自身端点即无「请求 → 应答」验收断言），故即便内容极完备也判 blocked——FR 只能挂在其他契约的端点上兑现。**内容上已完备、随首个 FR 即可兑现**：§1 表达形式与 spec 落笔规则 · §2 序列化八条 · §3 **端点全集表 + P-3 机器读取面护栏**（表下非规范性说明：`/internal/` 前缀被保留、永不出现在 `/v1/` 下、永不进本表，`ADR-0062`；**表本身零加行**，提取脚本无须同改）· §4a 无鉴权例外判据（`ADR-0016`）· §4b 应答头五项 · §5 错误体五字段 + §5a 脱敏 + §5b 三条降级 · §6 **30 行错误码台账 + P-1 护栏**，含承重项「flags 零装载刻意不给专属码」（台账**零增减**、`code` 全量枚举不变）· §7a–§7d · §8 三段可见性。`ADR-0003` Accepted。`## Open questions` 唯一条目是 `openapi.yaml` 落笔，**自陈属待落笔项而非设计未决**，不是就绪度卡点 |
| `systems/_index.md` | blocked（**非 FR 面**） | 索引 + 三份服务文档的公共前提。「共用的存储与并发形态」六条与「契约条款 → 数据库不变式」五行表是实质内容、可直接转为断言，但**无独立可观测的应答 / 存储结果**（触发拆解下界 L1 / L2）⇒ 落点应在 `account` / `profile-store` / `content-delivery` 的 FR 内。「明确不引入」四条是否定性架构结论，同理。**台账：服务表 3 行 ↔ 3 份实际文件**，零悬空行、零孤儿文件（内部工具面的四张表随 `account` 域登记，**不新开第四份服务文档**——它不是一个服务，是一个工具面） |
| `operations/_index.md` | blocked（**非 FR 面**） | 台账 **10 行 ↔ 10 份正文**，逐条对上、全标「已建立」，零悬空行、零孤儿文件。**残留半句待收**：收据 TTL 行仍在正文断言「它与 O6『历史规则集永久保留』是同形取舍」（见漂移清单第 7 条） |
| `contracts/_index.md` · `contracts/vectors/splitmix64.json` | blocked（**非 derive 对象**） | 索引 / 台账与机器可读的对表产物。`_index.md` 承载契约面清单、分域判据、「契约变更的完成判据」六条 + 三条机检断言 + 人工清单四项 + 两条提取护栏 + `schemas/` 拆分判据——全部是**流程约束与元规则**，无端点无报文，写不出「请求 → 应答」断言；六份契约状态列均为「已成文」。**适用面边界**：这套完成判据与机检断言**对 `/internal/` 面不适用**（`ADR-0062`），内部端点的正确性由 `internal-tools.md` I1–I10 承担。`splitmix64.json` 是 `profile-sync.md` §6a **唯一可执行的验收检查点**（8 组已填，两侧实现后逐位对表，不得单方面改表迁就实现） |
| `vision/scope.md` · `vision/pillars.md` | blocked（**非 FR 面**） | 北极星与五条裁决原则，只陈述边界与硬约束，**零可验证行为断言**——`scope.md` 最接近断言的「硬约束」三条都是对协议的**元要求**，写不成「给定请求 / 状态 → 期望应答 / 存储结果」。作为其余文档的挂靠前置成立（`pillars.md` #4「一次误判 = 一次强制下线」正是 `moderation.md`「自动化止于工单」、`internal-tools.md` `baseAccountStatus` 前置条件与 `ADR-0063`「带外改库是唯一一条不留 `operator_audit` 痕迹的处置路径」的承重论证），自身不产需求。**建议不进入 derive 候选池。** 本批零编辑 |
| `decisions/ADR-0001` ~ `ADR-0063`（**63 份全部 Accepted**）· `decisions/_index.md` | blocked（**非 derive 对象**） | 已采纳的决策记录与台账，作为其余文档的就绪前置，本身不产 FR。**就绪判据第 3 条对六份契约与全部 `systems/` `operations/` 文档全部成立**——**无一份文档受任何 `Proposed` / 未采纳 ADR 约束**（63 份逐份核对，非 Accepted 者 **0** 份；`_index.md` 中出现的 `Proposed` / `Superseded` 字样仅在状态词汇图例中）。**台账 63 行 ↔ 63 份实际 ADR 逐条一致**（`ADR-0001`~`0063` 连号无缺），无孤儿文件、无悬空行。本批新增 `ADR-0063`（人类身份对业务表恒只有 `SELECT`），其「后果」段逐字自陈**客户端零影响** |

### 建议的 derive 顺序（被依赖的契约先于依赖它的系统）

**第一波 —— 两条完全无排除面的纵向切片：**

1. **`/derive-requirements backend contracts/profile-sync.md`** —— 全库最成熟的一份。协议面完整、ADR 前置齐备、跨边界两向对它零欠账，且有 `vectors/splitmix64.json` 这个全库唯一可执行的验收检查点。**无排除面**，遵守三条参数化纪律即可。
2. **`/derive-requirements backend systems/profile-store.md`** —— 同一条纵向切片的服务内部面。**无排除面。**

**第二波 —— 购买纵向切片：**

3. **`/derive-requirements backend contracts/purchase.md`** + **`operations/purchase-ops.md`** —— `## Failure & retry semantics` 可写全。三块排除面标清。

**第三波 —— 合规纵向切片（三份全 ready，只带一个外部事实挂账项）：**

4. **`/derive-requirements backend contracts/compliance.md`** + **`operations/compliance-ops.md`** —— 六端点逐端点断言可写全。`02` 的主管部门实名认证接入义务写进 Scope 段作条件化核对项。
5. **`/derive-requirements backend operations/external-providers.md`** —— 它是 4 与 6 的共同下游依赖（三张归一映射表）。

**第四波 —— 账号与会话纵向切片：**

6. **`/derive-requirements backend contracts/auth.md`** + **`systems/account.md`** —— 排除面只剩一块（第④级恒 Pass）。`version-matrix.md` 与 `deployment.md` G-1 / G-2 的窄切片随本波兑现。**注意**：`account.md` 的十五表与十行事务边界中，末四张表 / 末三行属内部工具面 —— 可随本波一并 derive（它们是同一域的存储形态），也可留给第七波与 `internal-tools.md` 合并；**二选一，不要两波都写**，否则同一批断言会被切进两个 FR。

**第五波 —— 内容分发纵向切片（三份全 ready，零机制卡点）：**

7. **`/derive-requirements backend contracts/content-manifest.md`** + **`systems/content-delivery.md`** + **`operations/content-delivery-ops.md`** —— F1–F8 与 ops 的 C1–C6 / O1–O7 / A1–A5 可直接落成验收标准。**排除**：A4' 池规模缩放 · 客户端侧义务 · 承重列两节需跨文档取。**落笔前建议先催对侧落笔那 2 条已登记的承接义务**——它们正是这一波的客户端对位面。

**第六波 —— 人工处置纵向切片（整波 ready，可提前）：**

8. **`/derive-requirements backend operations/moderation.md`** + **`operations/internal-tools.md`** —— 两者是同一条切片的两端（自动检出侧 / 人工处置侧），**宜合并成一波**：`moderation.md` 的四张台账存储形态 + M1–M11 + 词表发布 + 扫描 T1–T3 + 阈值与熔断，`internal-tools.md` 的六端点 + I1–I10 + 可见字段范围。**derive 时的三条特别纪律**：① `ADR-0062` ⇒ 内部端点的 FR **不适用**契约面的六条完成判据与三条机检断言；② 内部面的 `Contract touchpoints` 段应写「不触及任何契约面（`ADR-0062`）」，而不是留空 —— 留空读起来像漏写；③ **`ADR-0063` 写成否定断言**（人类身份对任何业务表无 `INSERT` / `UPDATE` / `DELETE`，且权限分层落在建库脚本里），与 I1–I10 同体例；其在 `environments.md` 的权限与凭据面有同源对位断言，**两波不要重复切**。

`envelope.md` **不单独 derive**（共有层，随上述任一份的**首个** FR 一并兑现信封、错误体与相关错误码）。`operations/environments.md` · `observability.md` · `deployment.md` · `version-matrix.md` 的窄切片**均不单独 derive**，随对应服务的 FR 一并兑现。

> **注意：首批 FR 会同时触发 `openapi.yaml` 的首落**（`contracts/_index.md` 定：触发点 = 任一侧首个端点进入实现，首落范围 = **全部共有层 + 该一个端点**，且 spec 始终落本库）。同批须过「契约变更的完成判据」六条 + 三条机检断言 + 人工清单四项——注意 `contract-spec-check` workflow **尚未落地**（本次复测确认仓库仍无 `.github/`、无 `scripts/`），当前以人工清单前三项执行。**若第六波先行，则不触发这一条**（内部端点不入 spec）。

### 最短解锁路径

1. **全库已无 🔴 就绪度卡点，且本次评估未新增任何卡点。** **可以开始 derive 了**——按上方顺序从第一波起。
2. **对侧待落笔的 2 条（🟠，不阻塞本库任何一份）** —— 客户端库 `open-questions/cross-boundary.md`「待承接」两条已登记但未落笔。它不阻塞本库 derive，但第五波落笔前催一次为宜。→ 对侧 `/analyze-new-ideas game`。**本技能只报告、不写对侧。**
3. **`operations/version-matrix.md` 的两个取值** —— `appVersion` 下界 · `schemaVersion` 的「接受起始」。**不阻断 derive**（形态可断言、边界不可断言，参数化即可），首个在架版本产生时即可填。
4. **🟠 `06` 两条待实测取值** —— 成本模型（前置 = DAU 预期）· `riskEventBufferRows`。**均不阻断 derive**：形态、旋钮 key 与校准公式已全部落笔。
5. **🟠 `07` 两条相邻真空** —— 告警接收人 / 值班形态（全库工程级告警共用，属运维配置面，不产验收断言）· 客服侧账号查询入口（明写不在已落笔的六端点最小集内，属未来范围）。**均不阻断 derive。**
6. **🟠 `02` 一条外部事实挂账项** —— 实名核验是否另需对接主管部门的实名认证系统。须以真实过审要求核实，**不是设计待答**。同类的还有微信开放平台资质的审批到位时刻。
7. **`contracts/envelope.md` · `contracts/_index.md` · `vectors/splitmix64.json` · `vision/` 两份 · 63 份 ADR · 各 `_index.md`** —— **无解锁路径，也不需要**：共有层的 blocked 是结构性的（随首个 FR 自动兑现）；台账 / 对表产物 / 裁决原则 / 决策记录按定义就不是 derive 对象，**永远判 blocked 不代表有欠账**。

### 本次核实到的台账漂移（非就绪度断言，不阻塞 derive，建议同批处理）

全库主题文档与 `handoffs/` 中的**遗留旧就绪度断言：1 条**（第 2 条；「可 derive / 暂缓 derive / 解锁 derive」在主题文档与 `handoffs/` 零命中——`inbox/archive/` 的 38 份 solution-draft 中普遍出现的 `## 具体形态（可 derive 的落地面）` 是草稿模板的固定小节标题，不是对某份主题文档的就绪度断言，**不计入**）。

**本次销号的旧漂移条：** 09-09 清单第 11 条（`operations/internal-tools.md:83` 的「人类身份对业务表恒只有 `SELECT`」具备独立 ADR 的全部特征却未固化，是否提升属用户裁决）→ **已兑现**：`decisions/ADR-0063` 于本批立档（Accepted · 日期取用户裁决日 2026-09-09），`decisions/_index.md` 同步 63 行。该条销号，清单其余条目顺次重编号。

**仍在 / 新增的漂移（逐条）：**

1. **仍在（第五次记录）** —— **`ADR-0017` 与 `ADR-0025` 的回链是单向的**：`grep -rn "ADR-0017\|ADR-0025" contracts/` **零命中**，而 `decisions/_index.md` 已把两者记为 Accepted 且影响文档指向 `profile-sync.md`。决策本体已完整落进正文，`profile-sync.md` 的 `## 决策(-> ADR)` 段只列 `ADR-0006` / `0008` / `0005`。**不是 derive 卡点**，是簿记漂移。连记五次未动，建议本批一并补两行。
2. **仍在（唯一一条遗留旧就绪度断言）** —— `operations/purchase-ops.md:241` 写下单端点滥用阈值「具体数值与实现**随栈落定**」。栈已于 09-03 落定（`ADR-0021`），该句未跟改；且该阈值**无初值、无旋钮 key、不在任何旋钮表**。建议改写为「形态同构 push 滥用阈值，取值待实测」并补进旋钮清单。
3. **仍在（同一文件内新旧两说并存）** —— `operations/compliance-ops.md:189` 仍在写撤销留痕「交给**风控事件流**（只追加、有自己的保留期）」，而同文件另两处已按 09-08 裁决写为 `deletion_audit`（单独成表 · 保留 3 年 · 注销执行不删，`ADR-0057`）。09-08 / 09-09 / 09-11 三批均未回改这一处。
4. **仍在（三处，同源）** —— **三份契约仍以「技术栈未定」作为「停在语义层」的理由**：`purchase.md:5` · `profile-sync.md:366` · `envelope.md:260`「落点 `operations/`（栈落定后）」（而下一句自己已回链已存在的 `version-matrix.md`）。三处的**结论仍成立且是本库纪律**，但**理由句已过期**。建议改写为「本库纪律：契约层只声明语义，实现形态归 `systems/` / `operations/`」。
5. **仍在（标签滞后，两处同源）** —— `operations/content-delivery-ops.md:4` 的 Source 行仍写「…（**A7–A9** · 传播窗口 T 的口径与预算 · CDN 负缓存两条）」，而本文件内已无 A6–A9 任何编号（已迁 `systems/content-delivery.md`）；`open-questions/04-content-delivery.md:10` 同样残留「配 **A7–A9** 三条服务端纪律」。按该标签检索会零命中。
6. **仍在（标签滞后）** —— `operations/version-matrix.md:26` 的 `manifestSchema` 集合行值列仍写「待定」，而同格括号内实际已给出 `{1}`（首发，路径分支 `s1`）且下方 T0/T1/T2 序列已完整。读者会误判此项未决。
7. **仍在（部分收敛未尽）** —— `operations/_index.md:32` 的收据 TTL 行已压回回链形态并明写「本索引不复述其形态与理由」，但同行仍在正文断言「它与 O6『历史规则集永久保留』是**同形取舍**」这半句结论。彻底做法是连这半句一并移进 `purchase-ops.md` §3c 或 `moderation.md` 的过期方向判据表。
8. **仍在（软指路，四处）** —— 已有实际落点却仍指向分片编号：`contracts/profile-sync.md:198` / `:358` 两处写风控事件「落地形态…归 `02` / `06`」（实际已在 `operations/moderation.md`）· `contracts/auth.md:55` 写「`02` 的三条待答项」与 `:492`「词表与审核口径归 `02`」（`02` 待答已清零）。
9. **仍在（「技术栈未定」的第二组，两处）** —— `requirements/_index.md:10` 与 `:54`（U2 依据栏）仍以「后端技术栈未定，无从设计实现形态 / 文件边界不存在」为由把 `/blueprint` 与 `/implement` 排除在后端之外。该理由已于 09-03 失效——**结论可能仍成立**（后端代码尚未开工），但**措辞须改**为「后端尚未开工」。`README.md:37` 这一半已修。同一句在 `.claude/rules/design-library-routing.md` 另有一份同源副本，属 `.claude` 工程层，不在本技能写入面。
10. **仍在（🟠 README 台账失真）** —— `README.md:34` 仍写「`systems/` 三份服务文档与 `operations/` **九份文档**因此已全部展开」。实为 **10 份**（`operations/_index.md` 台账已正确写成 10 行 ↔ 10 份）⇒ **失真只在 README 一侧**。同段的焦点陈述本身已正确（含 `07`）。
11. **新增（🟠 三份新 ADR 的回链是单向的，与第 1 条同类）** —— `grep -rn "ADR-0061\|ADR-0062\|ADR-0063"` 在 `contracts/` `systems/` `operations/` **全部零命中**：三份 ADR 的「影响文档」列共点名 7 份主题文档（`internal-tools.md` · `account.md` · `moderation.md` · `environments.md` · `content-delivery-ops.md` · `envelope.md` · `deployment.md`），但没有一份在正文里回引这三个编号。**决策本体已完整落进各正文**（本次逐处直读核实：`internal-tools.md` 的 `operator_id` 与「界面档次」段 · `content-delivery-ops.md` A3 · `envelope.md` §3 表下说明 · `account.md` 的 `claimed_by` 外键），故**不是漏落笔、不是 derive 卡点**，是与第 1 条同源的簿记漂移：从正文读不出「这条已固化为决策」。建议与第 1 条一并补回链（各文档的 `## 决策(-> ADR)` 或就近括注）。
12. **仍在（两处轻微不齐，不影响任何判定）** —— ① `decisions/_index.md` 对 `ADR-0016` 的标题措辞与该文件 H1 不一致（台账写「免鉴权是一条判据，不是一份名单：调用者此刻不可能持有 access token」，H1 写「…：『调用它的玩家此刻不可能持有 access token』」，语义同向）；② `handoffs/2026-09-08-risk-ledger-storage-shapes.md` 的 frontmatter `distilled-to` 只列 4 份，比 `handoffs/_index.md` 同行少列 `operations/observability.md` ⇒ 属 frontmatter 漏列，**非漏落笔**。
13. **工程欠账（非漂移，两处陈述一致）** —— `operations/deployment.md` 与 `operations/_index.md` 均写 `contract-spec-check` workflow 与校验脚本**尚未落地**（本次复测确认仓库仍无 `.github/`、无 `scripts/`）。首批**契约面** FR 落笔时会撞上它；**内部面 FR 不受影响**（`ADR-0062`）。
14. **无失真** —— `decisions/_index.md` **63 行 ⇔ 63 份 ADR** 逐条一致且**全 Accepted（非 Accepted 者 0 份）**，编号连号无缺；`handoffs/_index.md` **42 行 ⇔ 42 份 handoff**、全部 `distilled`（`raw` / `triaged` 仅存在于 `_TEMPLATE.md`）；`inbox/` 顶层为空（只有 `_TEMPLATE.md` / `_index.md` / `archive/`，`archive/` **38 ⇔ 38**）；`answer-logs/` **35 ⇔ 35**；`operations/_index.md` **10 ⇔ 10**；`systems/_index.md` 3 ⇔ 3；`requirements/_index.md` 如实写「当前尚无 FR」并把就绪度权威指回本小节。

## 下一阶段

**契约骨架完整（六份）、再无取值留白，且技术栈与托管形态已落定**——本库的结构性前置就此清空。
客户端侧已定的四组语义（`revision` CAS · `pushId` 幂等 · `AccountSeed` 与掷骰复算 · 购买段验票与权威写入）全部有处可依；
三处 `reasonKey`、`compliance.*` 码清单与五条 `purchase.*` 码也已填表——客户端的 `ErrorText` 自此可以机械落地。

下一步落在三处，彼此可并行：

- **成本模型** —— 唯一仍待答的设计输入，是一批数值的共同前置（实例规格、灾备副本数、备份保留期、CDN 成本），本库已把这些一律写成能力要求而非具体数字。
- **两份发布前置清单的实际过闸** —— 「首个真实账号建号之前」六项与「首次面向公众发行之前」三项（`operations/deployment.md`）；**微信开放平台资质必须在首个玩家建号之前完成**，未到位则推迟上线。
- **两条外部事实的核实** —— 实名核验是否另需对接主管部门的实名认证系统（`02` 挂账项）· 服务商的具体选型（商业决定，形态已由 `operations/external-providers.md` 定死，不改任何验收断言）。

**唯一仍未落笔的契约面欠账**（属待落笔，不是设计未决）：`openapi.yaml` 与 `schemas/*.json`——触发点是任一侧首个端点进入实现。

**跨库未闭合项**见 `open-questions/cross-boundary.md` 与客户端库同名分片：本批带出的客户端承接义务（内容签名 standby 公钥内置 · `OpError.Purchase` 成员 · 合规域三条新 `code` 的 `ERR_*` 与相关落屏）已在客户端库登记为承接项，**本库不代为裁决**。

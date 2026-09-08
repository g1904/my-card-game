# Open questions — 后端待答清单（索引）

> 本文件是**后端**（云端服务）待答清单的**索引**；
> 问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 客户端侧的待答清单在 `game-design-documents/open-questions.md`（`game-design` 分支），
> 两份互不覆盖：**一个问题落在哪一侧，看它由谁实现**。
>
> 此清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；
> 一旦答定就从分片中移除、归档进对应主题文档，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> **最近更新：2026-09-07** —— 合规上线分级答结，待答收为一条（详见 `open-questions/update-log.md` · `answer-logs/log-compliance-launch-tiering.md`）。
> （逐次更新摘要见 `open-questions/update-log.md`；答结归档见 `answer-logs/`。）

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身。 |
| `open-questions/01-contracts.md` | **① 协议契约**（待答已清零）：展开见表下 |
| `open-questions/02-account-compliance.md` | **② 账号与合规**（待答已清零，余一条外部事实挂账项）：展开见表下 |
| `open-questions/04-content-delivery.md` | **④ 内容分发（CDN）**（待答已清零，余条件化核对项与指路）：展开见表下 |
| `open-questions/06-platform-stack.md` | **⑥ 技术栈 · 托管 · 运维**（栈与运维形态已落定）：余一条成本模型，另有一节条件化核对项（昵称审核阈值，首版不启用故不定值）。 |
| `open-questions/cross-boundary.md` | **跨边界承接**：客户端已定案、本库尚未落笔的条目。**不是待答问题**——答案已有，等的只是落笔；形态与关闭条件见分片抬头，机制设计见客户端库同名分片。 |

分片展开（承接上表）：

- **`01`** —— 六份契约**全部完全成文**（→ `contracts/envelope.md`、`content-manifest.md`、`auth.md`、`profile-sync.md`、`purchase.md`、`compliance.md`）；
  三条机检断言的工程承载亦已答结（设计库分支上的独立 workflow）。**待答清单已清零。**
- **`02`** —— **待答已清零。** 身份模型、合规落地与多设备裁决、昵称审核口径、存量扫描、风控落地形态、**合规能力的上线分级（四项全部首版必备 · 昵称审核留位不启用）**均已答结
  （→ `contracts/auth.md`、`contracts/compliance.md`、`operations/moderation.md`、`systems/account.md`、`operations/deployment.md`、`operations/compliance-ops.md`、`vision/scope.md`）。
  余一条**挂账项**（须以真实过审要求核实，不是设计待答）：实名核验是否另需对接主管部门的实名认证系统。
- **`04`** —— 协议四条与运维三条均已答结（→ `contracts/content-manifest.md`、`operations/content-delivery-ops.md`），
  **剧本分包边界已由对侧答结**（不分包 → 客户端 `ADR-0029`，本库零机制增量）；
  **待答清单已清零**：多区域一致性以否定结论答结、传播窗口 T 重定义为跨实例窗口并取定初值。余一节条件化核对项（不是待办）与一张「已推给别处的」映射表。
- **`06`** —— 技术栈、托管形态与运维形态**均已落定**（C# / 腾讯云托管容器 / PostgreSQL 单主 / Redis / KMS / CDN，→ `systems/`、`operations/` 九份文档）；
  余下**一条**只差实测数据：成本模型（含收据归档与对账阈值的定值、剧本下载量上界）。昵称审核两阈值已随 `02` 答结转为条件化核对项（首版不启用 ⇒ 不定值）。

> **编号 `05` 已空缺**：原「⑤ 剧本下发」分片于 2026-08-11 随云端剧本服务撤销而**整片删除**
> （剧本内容本地化为客户端内容层，见 `handoffs/2026-08-11-plot-service-retired.md`）。
> 编号不回填、不重排——`06` 的编号在别处已被引用，重排的代价高于留一个空位。
>
> **编号 `03` 已空缺**：原「③ 存档同步 / 冲突」分片于 2026-08-14 随 `contracts/profile-sync.md` 成文而**整片删除**
> （五条全部答结或被契约覆盖，实现层面的部分并入 `06`，见 `handoffs/2026-08-14-profile-sync-contract.md`）。
> 同样不回填、不重排。

## 当前焦点：`06` 的成本模型（唯一待答），其次两条外部事实

**六份契约全部完全成文**——

- `envelope.md`（边界层，08-11）
- `content-manifest.md`（内容分发，08-11）
- `auth.md`（登录与会话，08-13）
- `profile-sync.md`（存档同步，08-14）
- `purchase.md`（付费验票与后端权威写入，08-16 · 三渠道接入面 09-03）
- `compliance.md`（实名 / 防沉迷 / 注销 / 导出，08-16 · 六端点报文字段表与端点自身错误码 09-03）。

**技术栈、托管形态与运维形态均已落定**（C# / ASP.NET Core · 腾讯云托管容器 · PostgreSQL 单主 · Redis · KMS · CDN），
`systems/` 三份服务文档去其二、`operations/` 九份文档全部建立——全库再无结构性前置。**合规能力的上线分级亦已答结**（四项全部首版必备 · 昵称审核留位不启用 · 两份发布前置清单），焦点因此只剩外部输入：

1. **`06` 成本模型**（唯一待答）—— 只差实测数据，不取决于任何形态决定：实例规格 · 灾备副本数 · CDN 成本 · 收据归档与对账阈值的定值 · 剧本下载量上界，其共同前置是 DAU 预期。
2. **两条须以外部事实核实的项，不是设计待答** —— `02` 的挂账项（实名核验是否另需对接主管部门的实名认证系统，须以真实过审要求核实）·
   微信开放平台资质的审批到位时刻（`operations/external-providers.md` · `operations/deployment.md` 第一份前置清单第 4 项）。两者的共同处置都是：未到位则**推迟上线**，不降级放行。

## 判据：一个问题落在哪一侧

| 判据 | 归属 |
|------|------|
| 由客户端代码实现、后端不感知 | `game-design-documents/` |
| 由后端实现，或需要两侧约定报文 | 本库 |
| 客户端语义已定、只剩服务端如何兑现 | 本库（在条目中注明「客户端侧已定」+ 日期 + 回链） |

## derive 就绪度

> 本小节由 `/assess-derive-readiness` **独占写入**（`/analyze-new-ideas` 与 `/summarize-open-questions` 均不得改动）。就绪度需基于全库一次性全量扫描才有意义，顺带评估会迅速过时且互相矛盾。

**最近全量评估：2026-09-07（由 `/assess-derive-readiness` 产出）。** 扫描范围：`vision/`（2）· `contracts/`（7 份 `.md` + `vectors/splitmix64.json`）· `systems/`（`_index.md` + `account.md` + `profile-store.md`）· `operations/`（`_index.md` + 9 份正文）· `decisions/`（**50 份 ADR，全部 Accepted** + `_index.md`），共 **74 份**。旁证：`requirements/` **零 FR**（无「已覆盖」项）· `handoffs/` **35 份全为 `distilled`** 且 35 行台账逐条对齐 · `inbox/` 顶层为空（`archive/` 31 ↔ 31）· `answer-logs/` 30 ↔ 30 · **两库 `cross-boundary.md` 的「待承接」区双双为空**。

**全局结论：ready 7 份 · partial 9 份 · blocked 其余（全部为非 derive 对象或结构性 blocked）—— 本库首次进入可 derive 阶段，且不是小幅升级，是结构性跃迁。** 08-30 记录的 🔴「`06` 技术栈 · 托管」这一**唯一结构性前置已于 09-03 整体倒下**（C# / ASP.NET Core · 腾讯云托管容器 · PostgreSQL 单主 · Redis · KMS · CDN），随之解锁的 `systems/` 2 份服务文档与 `operations/` 9 份正文**全部一次成文到可 derive 的密度**。同期六份契约中最后两处欠账（`compliance.md` 六端点报文字段表与端点错误码 09-03 · `purchase.md` 逐渠道 `receipt` 形态与 verify 失败面五条 `code` 09-03/09-06）双双落笔，ADR 由 17 份扩至 **50 份**。

**08-30 那份评估的以下判定已全部作废，本次逐条订正：** ①「`purchase.md` 连续第四次未兑现转 partial 的预告」→ 现为 **ready**（越过 partial 直接升两级）；②「`compliance.md` 两处未落笔」→ 两处均已落笔，现为 **ready**；③「`systems/` 与 `operations/` 目录下仍只有 `_index.md`」→ 现有 2 + 9 份正文；④「本库欠对侧一条」→ **零欠账**，且该条的因果判断本身有误（见下方跨边界一节）；⑤「17 份 ADR」→ 50 份；⑥「`envelope.md` §7e 兼容矩阵内容全空」→ 已建 `operations/version-matrix.md`，`schemaVersion` 子表已登入 `1`，余 `appVersion` 下界与 `manifestSchema` 集合两项待定。

**三条贯穿全库的判据说明（先读，避免误判）：**

- **判据 1 的形式说明（沿旧）。** 六份契约中只有 `content-manifest.md` 带正式 `## 意图` 标题；其余五份把同等分量的范围陈述放在标题下的 `>` 前言里。**全库无一处模板占位符 `> _..._`。** 判据 1 按「有真实内容」判定，**不按标题字面判定**。
- **库级 derive 限定语（沿旧，仍成立）。** `contracts/envelope.md` §1 自陈「在某端点的 spec 落笔前，其 markdown 字段表视为草案」。**处置不变：以 markdown 为源 derive，待 `openapi.yaml` 落笔时做一次纯形态对账——不作为闸门。** `openapi.yaml` 与 `schemas/` 至今不存在，符合「不预先建空壳」，触发点是任一侧首个端点进入实现。
- **「非 FR 面」不是欠账。** `vision/` 两份（北极星与五条裁决原则）、各 `_index.md` 台账、`vectors/splitmix64.json`、50 份 ADR 按定义就不是 derive 对象，**永远判 blocked 不代表缺内容**。给它们补验收标准会把北极星文档变成第二份契约。

**卡点结构已由「三类」缩为「两类，且均不阻断主干」：**

- **🟠 `02` 合规能力的上线分级**（唯一仍会改变首版验收面宽窄的问题）—— 它**不动契约面**（`compliance.md` 六端点逐端点断言已可写全），只决定「首版必须具备哪几项合规能力」这类范围断言，卡 `operations/deployment.md` 的上线前置清单与 `vision/scope.md` 的 In scope。**从属项「第三方昵称审核首版是否启用」构成本次唯一的横切排除面**：`operations/moderation.md` 已给出默认形态（首版不启用 · 透传恒放行），但同句自陈「是否启用取决于本条分级」⇒ 按「占位机制不构成 ready」的纪律，**判定链第④级的验收面在 `auth.md` / `systems/account.md` / `operations/moderation.md` 三处一律整体排除**。
- **🟠 `06` 两条待实测取值** —— 昵称审核两阈值（从属于上一条的启用与否）· 成本模型（共同前置 = DAU 预期）。两条**均不取决于任何形态决定**：能力要求、旋钮位置与校准公式已全部落笔 ⇒ derive 时一律写成「存在该旋钮 + 落 `config_knob` + 改值不发版」的形态断言，不取数字。这与 `profile-sync.md` §10 / §12 的既定参数化纪律同款。

**跨边界闭合（强制检查项）—— 两向零欠账，本库历史首次。**

- **本库欠对侧：零。** 08-30 记录的唯一欠账（`compliance.md` 六端点报文字段表 + 合规域端点错误码）已于 09-03 落笔（§10 六端点字段表 · §11 三条新 `code` `ticket_invalid` / `verification_failed` / `deletion_irrevocable` 及各自 `reasonKey`，三条已进 `envelope.md` §6 台账）；`contracts/_index.md` 状态列已由「已成文（报文字段表待落笔）」改为「已成文」。
- **⚠ 订正 08-30 的一处因果误判。** 旧评估写「对侧 `cross-boundary.md` 的唯一条目（`ComplianceManager` 覆盖面切分）**因本库欠账**写不出验收标准」——**这个因果不成立**。`handoffs/2026-09-03-compliance-endpoint-payloads.md` 自陈「它**不关闭**对侧那条待承接项——对侧原文明写切分是客户端自己的取向，不等本库任何输入」，`contracts/compliance.md` 亦写「本库只定边界另一侧的报文」。对侧已自行以客户端 `ADR-0155` 落笔该切分并于 09-07 移出。**后端报文是对侧写「合规端点对位」断言的输入，但覆盖面切分本身从不等后端。**
- **对侧欠本库：零。** 本库 `cross-boundary.md`「待承接」为空，其下 12 条对账基线全为已闭合留痕。常规触发源（对侧 `profile-schema-versions.md` 每新增一行 = 一次 bump）**未触发**——直读对侧登记表：`schemaVersion` 表仍只有 `1`（首发）一行，v1 首发形状清单虽已扩至 #34，但全部在 v1 行内；本库 `operations/version-matrix.md` 的 `schemaVersion` 子表已登入 `1`。
- **08-30 记录的「barter schema bump 在本库零留痕」已闭合且判断有误**：Exchange 物化字段与 `Source.ExchangeBarter = 10` 折入对侧 v1 首发形状清单 #25，**根本不是一次 bump**，触发源条件未成立。09-05 已在 `cross-boundary.md`「对账基线」补留痕。**该漂移条就此销号，不再记录。**
- **两条常驻机械义务（非欠账，derive 时须写进 FR 前置）**：① 对侧 `profile-schema-versions.md` 每新增一行 ⇒ 本库须登进 `version-matrix.md` 的 `schemaVersion` 子表，且顺序恒为「矩阵先加、客户端后发」；② `auth.md` §4 末「下游依赖登记」——客户端 refresh token 的本地存放取向挂在 rotation / 吊销语义上，§4 任一条被改写须同批触发对侧重评。
- **预警仍未触发**（两侧均已登记）：`characterProfile` 的资源字段一旦提进透明档，必须同批把钳制语义与 `AppliedChange` 累加语义写进 `profile-sync.md`，否则后端复算会在正常账号上误报。相关字段仍落不透明段。

| 文档 | 判定 | 卡点 / 就绪切片 |
|---|---|---|
| `contracts/profile-sync.md` | **ready** | 维持 ready（08-28 之后本文件零编辑）。**就绪切片 = 全文**：§1 两端点封定（含「`accountId` 绝不进 query/body」否定断言）· §2 pull 三字段与建号骨架（`accountSeed` 16 位小写 hex · `revision=1`）· §3 六字段负载信封 + 空 diff 照常 `+1` + 未知 `reason` 宽容 · §3a 顶层键浅合并 · §4 三分支 + 幂等命中五行表 + **判定顺序**（`schemaVersion` → 形状 → CAS → 回声 → 写入）+ 四类拒绝均不消耗 `revision` + 「宽容不适用于 `schemaVersion`」的不对称声明 · §5 十三行白名单 + 后端写入封闭四行表 + 「够格进表」两条判据与三条反例 · §5a / §5b · **§5c 完整四段** · §6 / §6a SplitMix64 + 8 组已填向量（外部权威 `vectors/splitmix64.json`，可逐位断言）· §7 复算三检查 · §7a 仅记账不拒绝 · §8 账号级线性化 + 读己所写 · §9 · §10 · §11 · §12。`## Open questions` 明写无待答项，四条原实现侧问题各有落点（`operations/moderation.md` · `systems/profile-store.md` · `operations/environments.md`）。ADR 前置齐备。**三条参数化纪律（不是排除面）**：① 风控事件写成「记一条结构化事件」；② §10 的 60 次 / 分钟与 §12 四个初值写成配置阈值；③ §4 的「`schemaVersion` 越出兼容集合」分支只断言形态、不断言边界（`version-matrix.md` 的 `appVersion` / `manifestSchema` 两项仍待定）。**08-30 记的「唯一不可断言项：512 KB 软告警无线上可观测面」已消失**——`operations/observability.md`「数据面」已给出体积分布指标与超阈值账号数 gauge |
| `contracts/purchase.md` | **ready**（08-30 为 blocked，**越过 partial 升两级**） | **旧评估的两条卡点均已消除**：① 逐渠道 `receipt` 形态已落笔（§3a 三张字段表 + 三张渠道状态映射表 + `receiptId` 三渠道前缀 / 字符集 `[A-Za-z0-9._~-]` / 上界 1024 / 不截断不哈希）；② verify 失败面五条 `code` 已进 `envelope.md` §6 台账（`receipt_invalid` · `receipt_claimed` · `receipt_pending` · `channel_disabled` · `payload_invalid`）⇒ 模板强制且不可切的 `## Failure & retry semantics` 现可写全。**就绪切片 = 全文**：§1 三端点 + 全部需鉴权 · §2 写入只由 verify 承担 · §3 请求根判别式（`oneOf` + `discriminator`，`ADR-0018`）· §3b 下单端点与 `Unknown` 预落记录（`ADR-0019`）· §4 `status` 三值 + `Rejected` 复用 verify 终态 `code`（`ADR-0046`）· §5 复算沿用 §7a · §6 七条栈中立服务端保证（含读己所写覆盖 `order` 预落记录）· §7 `receiptId` 全局唯一键 + 永久保留不设 TTL。ADR 前置齐备（`0007` · `0013` · `0018` · `0019` · `0041` · `0045` · `0046` 全 Accepted）。**参数化项**：归档触发三阈值与对账信号 N 待实测，但形态、旋钮 key 与校准公式已由 `operations/purchase-ops.md` §3d / §4 与 `ADR-0045` 定死 |
| `contracts/compliance.md` | **ready**（08-30 为 blocked，两处欠账均已落笔） | **§10 六端点报文字段表全部落笔**（`ComplianceRealnameStatus` 四值 · `isMinor` · `playtimeRemainingSeconds` 为相对量 · `deletionEffectiveAtUtc` 是 `pendingDeletion` 的唯一跨边界形态 · `nicknameChangeRequired` · `downloadUrl` 每次现签且 `downloadExpiresAtUtc` 为产物保留期终点 · `taskId` 形态 `^[0-9a-f]{32}$` · 导出四状态机）；**§11 三条端点自身错误码**及各自 `reasonKey` 取值表，三条已在 `envelope.md` §6 台账。其余就绪切片：§2 六端点集与鉴权形态 · §3 ticket 机制（一次性 · 10 分钟 · 单端点 · 不进 `Authorization` 头 · 60 秒兑付回放窗口）· §4 拦截只在 `signin` · §5 四条 `compliance.*` 拦截码 + **求值顺序写死**（`ADR-0037`）· §6 时段口径落配置 · §7 防沉迷复用 `auth.session_revoked` 五步映射 · §8 导出形态 · §9 四个旋钮初值。依赖闭合：`operations/compliance-ops.md` 成文，`ADR-0011` · `0015` · `0016` · `0028`~`0037` 全 Accepted。**唯一须作为外部排期参数写进 Scope 段、不作验收断言的**：「首版实现哪几项合规能力」仍在 `02` 未分级（导出已定首版必做） |
| `systems/profile-store.md` | **ready** | **就绪切片 = 全文**：承重列四表 · 事务边界四行 · 四条实现纪律（CAS 用受影响行数分支 · 判定顺序照契约写死 · 类型感知语义相等 · 零判定权字段关闭 enum 严校验而驱动判定的枚举仍封闭）· 两类幂等记录的分轴对照 · `push_idem` 月分区与「条数降级为观测阈值」· `receipt_idem` 全局唯一键与同事务序号推进 · 读己所写「玩家读路径全走写入区」· 体积软告警。依赖全闭合（`contracts/profile-sync.md` ready · `contracts/purchase.md` ready · `operations/purchase-ops.md` §3d · `operations/environments.md`）；`ADR-0008` · `0013` · `0017` · `0021` · `0045` 全 Accepted。**本库第二份无排除面的 ready，且它的契约面本身也是 ready** |
| `operations/purchase-ops.md` | **ready** | **就绪切片 = 全文**：§1 三渠道凭据与轮换 · 托管形态（云 Secrets · 渠道 × 环境 · `credentials[]` 新旧并存 · 5 分钟周期刷新）· **收据环境校验以部署环境配置为准、不以收据自述为准** · §2 三条对账通道 +「推送只作更快知道、周期拉取才是正确性来源」+ 对账不驱动任何自动写入 · §3a S1–S3 选型判据 · §3b 哈希分区与部分索引 · §3c **TTL 禁用断言**（部署时读取过期策略，非「永不过期」即拒绝启动）· §3d 三层分工 / 哨兵行五列 / 读路径五分支 / 归档任务三步顺序不可颠倒 / 断言逐表逐分区覆盖 / 同一 PITR 一致点 · §4 两条对账信号与 N 的校准公式 · §5 风控高优四项。**两块「已定但不启用」须标为排除面**：§3a 退化形态（S1 已由单库 PostgreSQL 满足）· §3d 归档任务（`receiptArchiveEnabled` 初值 `false`） |
| `operations/compliance-ops.md` | **ready** | **就绪切片 = 全文**：可信时钟基准与两处例外 · 同步纪律（只 slew 不后跳 · 不可逆动作在时钟异常期间暂停一轮）· 时段规则集承重列与「判定时读当前最高版本、不做预约生效」· 法定节假日日历两类条目与**四步判定顺序**（`WorkingWeekend` 排最前）· F1 / F2 / F3 三个失败面的降级语义与降级路径下 `resumeAtUtc` 取兜底周规则 · ticket 条件更新 + 受影响行数分支 + **五级短路求值顺序** + 「消费时把 `expires_at_utc` 拉到 `max(原值, +60 秒)`」· 外部核验两段事务与终局出路 · 注销冷静期状态三值与三端点分支 · **执行时删什么九行表**与两条保留的硬理由 · 导出任务部分唯一索引 / 私有桶 / 每次现签 15 分钟链接 / 白名单序列化器三条断言 / 两道保留期 · 周期任务四条与八个旋钮的校准信号。ADR 前置齐备（`0028`~`0036` 全 Accepted）。**判据 2 按「已有决策覆盖」成立**：文末 `## Open questions` 唯一条目「实名核验服务商选型与灾备」的**形态面已于 09-06 由 `operations/external-providers.md` + `ADR-0038`~`0040` 答结**（单供 · 禁双验 · 硬超时 5 秒 · 归一映射），余下只是「具体哪一家」这个商业事实，不改任何验收断言——**但该条目文字本身已陈旧，应清理**（见漂移清单）。**`02` 上线分级不构成卡点**：文档自陈「形态与上线时点是两件事，形态在此定死」 |
| `operations/external-providers.md` | **ready** | **就绪切片**：A1–A6 共有形状 · 四个接口签名 · **三张归一映射表**（按调用点所在域取 · `auth.challenge_expired` 永不来自服务商 · 不可达归 `code` 的判据是有无 `retryAfter`、不得靠 `providerCode` 分支）· 逐能力供应商数与灾备判据 · 短信切换触发判据与回切滞后（可写成定量断言）· 禁并发双发 / 同码转备用至多一次且只在首家未返回受理 id / 禁双验 · 「一次 `challenge` 至多两次外部调用」· 选型判据 H1–H4 / S1–S4 · 凭据托管（能力 × 供应商 × 环境，独立审计线）· 可观测性五行增量与余额低水位两档 · 微信资质过闸断言。`ADR-0038`~`0041` · `0042` 全 Accepted。**「不点名任何服务商」不构成卡点**——A6 把归一点放在调用方、适配层只产 `Outcome` 三档，FR 因此写成「给定适配层产出 `Outcome = 明确拒绝` → 端点归一为 `auth.credential_invalid` / `Fatal`」，与服务商无关，这正是该抽象的设计目的。**排除面**：第三方昵称审核的阈值面（能力首版不启用）· 微信资质前置链（外部审批日程，非 FR） |
| `contracts/auth.md` | **partial**（**距 ready 只差一行消歧**） | 08-30 的四条卡点**已全部解除**：`SensitiveWord` 判定输入（§8 四级短路 + `operations/moderation.md` 词表两档分级与不可变发布）· `TooFrequent` 阈值（§8 已定值 **3 次 / 30 天滚动**，`ADR-0043`）· `refresh` 限流形态（`operations/deployment.md` G-1：网关不得静默加限流）· token 签名密钥与会话存储（`systems/account.md` + `ADR-0022` / `0023`）。**就绪切片 = §1~§11 几乎全部**：七端点 · §1a 身份模型（`accountId` 自建 · 一对多 · 绝不隐式合并 · `channelUserId` / `idKind` / `sid` / `status` 不进任何报文，可写成否定断言）· §2 双 token 与 TTL 表 · §3 / §3a 渠道分形与换 openid 三条义务 · §4 rotation + 60 秒宽限 + 五分支求值顺序 · §4a 会话裁决 · §5 / §5a 闸门只在 `signin` · §5b 绝对寿命上限 60 天 + `reauthRecommended` · §6 头矩阵 · §7 六条重放场景 · §8 报文 + 十二个旋钮初值 · §9 五个错误码 · §10 两张取值表。**卡点一（窄，须先消歧）**：§4 求值顺序第四分支「`now ≥ refreshExpiresAtUtc`（滑动截止）→ `auth.session_revoked`（`reasonKey` 沿用既有口径）」，而 §10 八值中无对应项——`SessionExpired` 明写是「链达到**绝对**寿命上限」（§5b）⇒「闲置超 30 天后 refresh 返回哪个 `reasonKey`」**无契约答案**，只能靠推断。补一个取值、或把 `SessionExpired` 的触发列改为「滑动或绝对截止任一到期」即可转 ready。**卡点二（横切排除面）**：判定链第④级第三方审核适配器的启用与否仍挂 `02` ⇒ derive 时整体排除该级验收面 |
| `systems/account.md` | **partial**（08-30 时该文件尚不存在） | **就绪切片近乎全文**：「存储形态：承重列」全表 · 「事务边界」七行表（含 `signin` 两步反序的实现纪律）· `tokenId` 与 `sid` 的分工 · refresh token 形态的五分支校验流程 · access token 签发四条 · 渠道能力适配层两条纪律 · 昵称判定链 **N1–N10（除 N9）** · 存量扫描 **S1–S5 全表** · 合规域 **C1–C6 / D1–D7 / E1–E6 全表**。这三组表本身即模板要求的「给定请求 / 状态 → 期望应答 / 存储结果」形态，逐行可直接落成验收标准。**唯一卡点（须整体排除的切片）**：判定链第④级第三方审核适配器 + N9 行——`operations/moderation.md` 给的是默认形态（首版不启用 · 透传恒放行）而非裁决，同句自陈「是否启用取决于 `02` 的上线分级」⇒ 按「占位机制不构成 ready」判，排除该级。**参数化纪律**：改名频次上限 · ticket 寿命 / 60 秒回放 · 冷静期 15 天 · 导出保留期一律写「配置阈值」 |
| `contracts/content-manifest.md` | **partial**（**卡点由七条缩为两条**） | 08-30 的七条卡点**已解除五条**：传播窗口 **T = 60 秒**且主体重定义为「全部对外服务的实例」（`ADR-0047`）· 缓存层已裁决**不引入**（`content-delivery-ops.md` A6，并给出引入触发判据 p99 > 50ms 或 CPU > 5%）· ES256 私钥保管与 `keyId` 轮换（B1–B5 + standby，`ADR-0049`）· 发布侧校验闸 C1–C6（`ADR-0048` · `ADR-0050`）· 多区域 `contentVersion` 以**否定结论**收口（单区域部署，`ADR-0021`）+ 剧本分包由对侧 `ADR-0029` 裁定。**就绪切片 = CDN 域三端点 + `/v1/content/flags` 完整协议面**：端点四行表（含字面量 `public, max-age=31536000, immutable`）· `manifestSchema: 1` 八行字段表 + 示例 · ES256 detached（覆盖**原始字节** · P1363 `r‖s` 非 DER · `keyId` 轮换）· 三版本号分工 · **A 组四条** · **B 组三条 + 三个失效来源的堵法 + `X-Flags-Version` 取 `min(高水位, 本实例可兑现)`（`ADR-0047`）** · flags 报文五字段（`enabledIds` 恒空是硬契约）· 失败面五行处置表 · 剧本 arc / node 分野 · 对客户端缓存的四行零义务否定表 · `## blob 通道不承载二进制资产`。**余下卡于两条**：① **`manifestSchema` 破坏性变更时 N-1 / N 双发的分流机制仍是二选一**（正文原文「按 `appVersion` 或显式 `?manifestSchema=` 分流」）且保留时长未定；若走 query 变体，它还会成为 `envelope.md` §3 端点全集之外的一个未登记形态；② **CDN 三端点的失败状态码未在契约层钉死**（只有「不返回契约错误体、按 HTTP 状态码判定」这条纪律 + `operations/` 的负缓存要求隐含 404） |
| `operations/moderation.md` | **partial** | **就绪切片**：词表两档分级与不可变版本化发布（复用 O1–O7 + 留痕四项）· 存量扫描 **T1 / T2 / T3** 与扫描台账六字段 · **处置阶梯三档**（「须改名」豁免拦截不豁免计数）· `nicknameChangeRequired` 由云端状态算出、改名 push 后由 T1 比对自动清零、**不在端点判定通过那一刻清零** · 风控事件字段表与 `kind` 十值（含 `DeletionRequested` / `DeletionCancelled` 的同事务写入断言）· 阈值分档与全局熔断（1% / 0.5%）· 自动化止于工单。**卡于两条**：① 第三方审核适配器的启用与否 + 两阈值取值 ⇒ 该级验收面整体排除（同 `auth.md` / `account.md`）；② 文档自陈「风控事件流 / 复核队列 / 扫描台账**自身的存储形态**」（分区 · 索引 · 到期整体过期的执行方式）仍待 `06` ⇒ 字段与语义已全，可参数化，但模板的 `Data & state touchpoints` 若要写到表级则写不实 |
| `operations/content-delivery-ops.md` | **partial**（运维面本体已到 ready 密度，卡在 FR 归属） | **就绪切片**：CDN 两类对象两种 TTL · **内容发布流水线 ⓪–⑦ 全序**（含 ③b DER→P1363 编码归一 · ④ 必须用客户端内置公钥自验 · ⑤ 探针走 CDN 域）· **发布侧校验闸 C1–C6**（尤其 C6 逐基线各跑一遍，`ADR-0050`）· 留痕八字段（含 `gateAttestation`）· flags 发布 / 回滚 **O1–O7 与留痕四项** · B1–B5 私钥保管判据与 standby（`ADR-0049`）· `keyId` 轮换三类触发 / 四阶段 / 覆盖率 95% 口径 / T2 后 48 小时观察窗与回切 · 版本传播窗口 T 的口径、三项预算与 gauge 极差探针。**卡点（判据 5 · 孤儿路径）**：A6–A9 描述的是 **`GET /v1/content/flags` 的请求处理路径**（规则集缓存与 single-flight · 应答体 `flagsVersion` 取自实际使用的记录而非高水位 · `X-Flags-Version` = `min(高水位, 本实例最大版本)` · 签名结果按 `(flagsVersion, accountId)` 缓存），这是**服务内部行为**，而 `systems/_index.md` 已把该职责登记给 `systems/content-delivery.md`——**该文件不存在** ⇒ 这些切片的 FR 写出来 `service:` 无处可指。须先建该文档，或明确裁决「flags 服务内部形态就落在运维文档」。**明确排除面（文档自陈）**：A4' 池规模缩放（已定形态 · 未采纳，触发前一字不动）· 对 CDN 的能力要求与负缓存（基础设施配置）· 内容校验规则本体（权威在客户端库，本库只验背书，`ADR-0048`） |
| `operations/environments.md` | **partial**（窄切片，宜随服务 FR 兑现） | **就绪切片**：**「限流的实现分层」整节**（fail-open 默认 · 三条 fail-closed 例外：验证码短信计数 / 实名提交 / 未成年时段判定，`ADR-0031` · Redis 不可用放行并告警 · `refresh` 零限流的否定断言 · `Retry-After` 与 `detail.retryAfterSeconds` 同时给）· 密钥轮换「旧 `kid` 保留 ≥ access token TTL + 时钟偏移余量」。**其余属非 FR 面**：环境实体 · 配置三层与旋钮清单（数据登记）· 区域与合规 · 拓扑与副本 · 容量形状 · 密钥保管 · 定时任务出口。**已声明的排除（非卡点）**：实例规格 / 副本数 / 备份保留期待成本模型（`06`），文档已明写「不在此定稿」、只写能力要求 |
| `operations/observability.md` | **partial**（窄切片，宜随服务 FR 兑现） | **就绪切片 = 探针发射面**：五条契约语义探针——尤其「透明路径缺失」的**带前提判定**（只有该顶层键出现在本次 diff 中时才检查其下白名单路径）与「未知 `schemaVersion`」的**按大小关系二分**，两条都是「给定某类上行 → 指标计数 + 标签」的可断言形态 · CAS 冲突率与回声拒绝率分开计数 · **日志脱敏中间件**（给定含 token / `downloadUrl` / 手机号的事件 → 输出中不出现明文，纯否定断言）· 合规域三条探针与时钟两条探针的发射面。**非 FR 面 / 卡点**：告警阈值与 P1 分级属运维配置 · RED / 连接池 / 复制延迟属基座通用监控，无契约语义可断言 · 时钟两条探针阈值「待实测校准」（参数化处理） |
| `operations/deployment.md` | **partial**（**小**切片，主体属非 FR 面） | **可产出 FR 的两处**：① **启动自检解析时区名失败即拒绝启动**（给定规则集含不可解析 IANA 名 → 进程拒绝启动，`ADR-0029`）；② G-1「`/v1/auth/refresh` 上不存在任何返回限流码的限流」——可作为 auth FR 的一条否定断言。**非 FR 面**：构建与制品 · expand→deploy→contract · 发布前置清单四项（人工过闸）· 周期性运维日程 · 共享 DTO 护栏。**未闭合项（自陈，非漂移）**：`contract-spec-check` workflow 与校验脚本**尚未落地**，三条机检断言当前以人工清单前三项执行 |
| `operations/version-matrix.md` | **partial**（窄，宜随 auth FR 兑现） | **已填，非空置**（订正 08-30 的「§7e 全空」）：四项形态表 + 「当前矩阵」四行 + `schemaVersion` 集合已展开为**一版一行的四列子表并登入 `1`**（第四列为客户端登记回链，本库不写字段名）。**就绪切片**：「闸门在签发 token 时判定一次、会话期内不变严」· 「提升 `appVersion` 下界的覆盖上限 = refresh 绝对寿命」· `schemaVersion` 登记流程「矩阵先加、客户端后发」的顺序断言。**卡于**：`appVersion` 下界与 `manifestSchema` 集合仍为**待定**，`schemaVersion` 行的「接受起始」为「首个版本上线时（待落）」⇒ `client.version_unsupported` 与 `sync.payload_schema_unsupported` 两码的**形态可断言、边界不可断言**，并向下传导进 `profile-sync.md` §4。矩阵数据本身是旋钮登记，属非 FR 面 |
| `contracts/envelope.md` | blocked（**结构性，非欠账**） | 共有层，**不存在独立可构建的增量**（无自身端点即无「请求 → 应答」验收断言），故即便内容极完备也判 blocked——FR 只能挂在其他契约的端点上兑现。**内容上已完备、随首个 FR 即可兑现**：§1 表达形式与 spec 落笔规则 + 降级形态 · §2 序列化八条（含 > 2⁵³ 走字符串 · 绝不下发 `null`）· §3 **端点全集 22 行 + P-3 机器读取面护栏** · §4a 无鉴权例外**判据**（含 `GET /v1/compliance/status` 这个负例，`ADR-0016`）· §4b 应答头五项 · §5 错误体五字段 + §5a 脱敏 + §5b 三条降级 · §6 **29 行错误码台账 + P-1 护栏**（`class` 随 `code` 恒定是可断言不变式）· §7a–§7d · §8 三段可见性。`ADR-0003` Accepted。**两处待落笔（非设计未决）**：`openapi.yaml` / `schemas/*.json` 的实际落笔（规则与工程承载已定，见 `operations/deployment.md` 的 `contract-spec-check`）· §7e 兼容矩阵的两项待定（见 `version-matrix.md` 行） |
| `systems/_index.md` | blocked（**非 FR 面**） | 索引 + 三份服务文档的公共前提。「共用的存储与并发形态」五条与「契约条款 → 数据库不变式」五行表是实质内容、可直接转为断言，但**无独立可观测的应答 / 存储结果**（触发拆解下界 L1 / L2）⇒ 落点应在 `account` / `profile-store` 的 FR 内。「明确不引入」四条是否定性架构结论，同理。**台账：服务表 3 行 ↔ 实际 2 份文件**——第 3 行 `content-delivery.md` 指向不存在的文件，但「现状」已显式声明「尚未建立…按『先有设计再建文件』不预先占位」⇒ 属**声明式计划行，非悬空行**；无孤儿文件 |
| `operations/_index.md` | blocked（**非 FR 面**） | 台账 **9 行 ↔ 9 份正文，逐条对上、全标「已建立」，零悬空行、零孤儿文件**。但**自陈与自身内容相抵**：写「本索引不再承载运维面的正文」，其下「购买与验票」3 条与「版本兼容矩阵与错误码台账」6 条（含 `schemaVersion` 登记流程完整四段）仍是实质正文；其中「收据幂等表须显式关闭 TTL 并在配置层留断言」与 `purchase-ops.md` §3c **各写一遍** ⇒ 一处第二权威（见漂移清单） |
| `contracts/_index.md` · `contracts/vectors/splitmix64.json` | blocked（**非 derive 对象**） | 索引 / 台账与机器可读的对表产物。`_index.md` 的「六份 + 分域判据 + 完成判据六条 + 三条机检断言与降级形态 + 两条提取护栏 + 人工清单四项 + `schemas/` 拆分判据 + `profile-visible-subset.json` 三条纪律」与实际一致；六份契约状态列均已为「已成文」。`splitmix64.json` 是 `profile-sync.md` §6a **唯一可执行的验收检查点**（8 组已填，两侧实现后逐位对表，不得单方面改表迁就实现）。**08-30 记的「`session_revoked` 七值 vs 实际八值」已修**（现写八值），但**写法本身仍违反 `auth.md` §10 的明文纪律**（见漂移清单） |
| `vision/scope.md` · `vision/pillars.md` | blocked（**非 FR 面**） | 北极星与五条裁决原则，只陈述边界与硬约束，**零可验证行为断言**——`scope.md` 最接近断言的「硬约束」三条都是对协议的**元要求**（协议必须对重试与幂等成立 · 后端只能约束不能改变写入语义 · 不承诺跨内容版本可复现），写不成「给定请求 / 状态 → 期望应答 / 存储结果」。作为其余文档的挂靠前置成立（`pillars.md` 为 `profile-sync` 的「幂等与 CAS 是承重」、`purchase` 的「读己所写」、`content-manifest` 的「热更优先于跨版本可复现」提供承重论证），自身不产需求。**建议不进入 derive 候选池**，而非列为「待补断言」。**但 `scope.md` 已明显落后于本库落笔进度，三处失真同源，宜一次订正**（见漂移清单 D-1~D-3） |
| `decisions/ADR-0001` ~ `ADR-0050`（**50 份全部 Accepted**）· `decisions/_index.md` | blocked（**非 derive 对象**） | 已采纳的决策记录与台账，作为其余文档的就绪前置，本身不产 FR。**就绪判据第 3 条对六份契约与全部 `systems/` `operations/` 文档全部成立**——**无一份文档受任何 `Proposed` / 未采纳 ADR 约束**（50 份逐份核对 `状态：Accepted`，零 Proposed / Superseded / Rejected）。**台账 50 行 ↔ 50 份实际 ADR 逐条一致**（`ADR-0001`~`0050` 连号无缺），「影响文档」列引用的 20 个路径**全部实际存在**，无孤儿文件、无悬空行、无悬空指针 |

### 建议的 derive 顺序（被依赖的契约先于依赖它的系统）

**第一波 —— 三条无排除面的纵向切片（契约 + 服务内部 + 运维面配套齐备）：**

1. **`/derive-requirements backend contracts/profile-sync.md`** —— 全库最成熟的一份。协议面完整、ADR 前置齐备、跨边界两向闭合，且有 `vectors/splitmix64.json` 这个全库唯一可执行的验收检查点。**无排除面**，遵守三条参数化纪律即可。
2. **`/derive-requirements backend systems/profile-store.md`** —— 紧接上一份，它是同一条纵向切片的服务内部面（承重列 · 事务边界 · 两类幂等记录 · 读己所写）。**无排除面。** 与 1 合并成一次 derive 亦可，但分开更贴「一个 FR = 一个可构建增量」。
3. **`/derive-requirements backend contracts/purchase.md`** —— 本次升两级的一份，`## Failure & retry semantics` 现可写全。配套的 `operations/purchase-ops.md` 同批取（两块「已定但不启用」标为排除面）。

**第二波 —— 合规纵向切片（契约已 ready，运维面已 ready，只带一个外部排期参数）：**

4. **`/derive-requirements backend contracts/compliance.md`** + **`operations/compliance-ops.md`** —— 六端点逐端点断言可写全。**「首版实现哪几项合规能力」写进 Scope 段作为外部排期参数，不作验收断言**；落笔前顺手清理 `compliance-ops.md` 那条陈旧的 `## Open questions`。
5. **`/derive-requirements backend operations/external-providers.md`** —— ready，且它是 4 与 6 的共同下游依赖（归一映射表）。排除第三方昵称审核阈值面与微信资质前置链。

**第三波 —— 带排除面的 partial：**

6. **`/derive-requirements backend contracts/auth.md`** + **`systems/account.md`** —— **落笔前先给 §4 滑动截止分支的 `reasonKey` 做一句消歧**（补取值或改 `SessionExpired` 触发列），否则该分支断言写不实。**整体排除判定链第④级（第三方审核适配器 + N9 行）**；`operations/moderation.md` 的对应面同批排除。`version-matrix.md` 与 `deployment.md` G-1 的窄切片随本波兑现。
7. **`/derive-requirements backend contracts/content-manifest.md`** + **`operations/content-delivery-ops.md`** —— 排除面较 08-30 大幅缩小。**排除**：`manifestSchema` N-1 / N 双发的分流机制与保留时长 · CDN 三端点具体失败状态码 · A4' 池规模缩放 · 客户端侧义务。**前置动作**：先裁决 A6–A9（flags 请求处理路径）的 FR 归属——建 `systems/content-delivery.md`，或明确落在运维文档。

`envelope.md` **不单独 derive**（共有层，随上述任一份的**首个** FR 一并兑现信封、错误体与相关错误码）。`operations/environments.md` · `observability.md` · `deployment.md` · `version-matrix.md` 的窄切片**均不单独 derive**，随对应服务的 FR 一并兑现。

> **注意：首批 FR 会同时触发 `openapi.yaml` 的首落**（`contracts/_index.md` 定：触发点 = 任一侧首个端点进入实现，首落范围 = **全部共有层 + 该一个端点**，且 spec 始终落本库）。同批须过「契约变更的完成判据」六条 + 三条机检断言 + 人工清单四项——注意 `contract-spec-check` workflow **尚未落地**，当前以人工清单前三项执行。

### 最短解锁路径

1. **`contracts/auth.md` §4 滑动截止分支的 `reasonKey`** —— **一行消歧即可让 `auth.md` 转 ready**，是全库投入产出比最高的一处。补一个 §10 取值，或把 `SessionExpired` 的触发列改为「滑动或绝对截止任一到期」。→ `/analyze-new-ideas backend`
2. **🟠 `open-questions/02` 合规能力的上线分级（含从属项：第三方昵称审核首版是否启用）** —— 它是本次**唯一的横切排除面**，一条答案同时解锁 `auth.md` / `systems/account.md` / `operations/moderation.md` 三处判定链第④级的验收面，并让 `deployment.md` 的上线前置清单与 `vision/scope.md` 的 In scope 可写实。**不影响任何契约报文面。** → `/analyze-new-ideas backend`
3. **`systems/content-delivery.md` 尚未建立** —— 它是**可写而未写**（`systems/_index.md` 自陈「服务内部形态具备开写条件」），不是被阻塞。不建它，`content-delivery-ops.md` A6–A9 的 FR 无归属服务可指。→ `/analyze-new-ideas backend` 或直接补写该服务文档
4. **`contracts/content-manifest.md` 的两条** —— `manifestSchema` N-1 / N 双发的分流机制二选一 + 保留时长（若走 `?manifestSchema=` query 变体，须同批登进 `envelope.md` §3 端点全集）· CDN 三端点失败状态码钉死。→ `/analyze-new-ideas backend`
5. **🟠 `open-questions/06` 两条待实测取值** —— 昵称审核两阈值（从属于路径 2）· 成本模型（前置 = DAU 预期）。**均不阻断 derive**：形态、旋钮 key 与校准公式已全部落笔，参数化即可。等实测数据，不必急于关闭。
6. **`vision/scope.md` 的三处失真** —— 不解锁任何 derive，但它是六份契约的共同挂靠面，三处同源、宜一次订正（见漂移清单 D-1~D-3）。**第五次记录。**
7. **`contracts/envelope.md` · `contracts/_index.md` · `vectors/splitmix64.json` · `vision/` 两份 · 50 份 ADR · 各 `_index.md`** —— **无解锁路径，也不需要**：共有层的 blocked 是结构性的（随首个 FR 自动兑现）；台账 / 对表产物 / 裁决原则 / 决策记录按定义就不是 derive 对象，**永远判 blocked 不代表有欠账**。

### 本次核实到的台账漂移（非就绪度断言，不阻塞 derive，建议同批处理）

全库主题文档与 `handoffs/` 中的**遗留旧就绪度断言：零条**（`systems/` 与 `operations/` 对「可 derive / 暂缓 derive / 解锁 derive / 栈未定 / 栈落定后展开」全部零命中——08-30 记的那批「以栈落定后展开为条件」的措辞已随文档重写清干净；`inbox/archive/` 的历史断言属溯源留存，且其中三处自觉写明「就绪度判定归 `/assess-derive-readiness` 独占」，形态正确，不处理）。

**已闭合、本次销号的旧漂移条：** ① `contracts/_index.md` 的 `session_revoked` 七值 → 已改八值；② blob 通道的孤儿指路 → 09-05 已在 `04` 新增「条件化核对项」承接；③ barter schema bump 零留痕 → 该「bump」根本不成立（折入对侧 v1 首发形状清单 #25），09-05 已补对账基线留痕；④ 本库欠对侧的 `compliance.md` 两处 → 09-03 已落笔。

**仍在的漂移（逐条）：**

1. **仍在（第二次记录）** —— `contracts/envelope.md` 抬头仍写「瘦身…不一次性做完**四份**」，契约面现为**六份**。**同处另有一处新失真**：前言只枚举三份（「各端点的报文本体在 `auth.md` / `profile-sync.md` / `content-manifest.md`」），漏 `purchase.md` 与 `compliance.md`。
2. **仍在（第五次记录 · 互撞未消）** —— **五份契约的 `## 决策(-> ADR)` 段仍写「→ ADR 候选①/②/③/④，登记于 `decisions/_index.md`」**，而「ADR 候选」整节已于 08-19 删除 ⇒ 指向一个不存在的登记处；且 `auth.md` 与 `content-manifest.md` **本地编号互撞**（都称候选④）。共 **13 处**（`envelope.md` ×2 · `auth.md` ×1 · `content-manifest.md` ×5 · `profile-sync.md` ×3 · `purchase.md` ×3）。对照写法：`compliance.md` 已改用现代写法（直接引 `ADR-0015` / `ADR-0016`），是六份中唯一无该段的一份——**它就是该批修订的目标形态**。映射：候选①→`ADR-0001` · ②→`ADR-0002` · ③→`ADR-0003` · ④(auth)→`ADR-0004` · ④(flags)→`ADR-0009` · profile-sync 三条→`ADR-0006` / `0008` / `0005` · purchase 三条→`ADR-0007` / `0018` / `0019`。
3. **仍在（第二次记录）** —— **`ADR-0017` 与 `ADR-0025` 的回链是单向的**：`grep -rn "ADR-0017\|ADR-0025" contracts/` **零命中**，而 `decisions/_index.md` 已把两者记为 Accepted 且影响文档指向 `profile-sync.md`。决策本体已完整落进 §3 / §5a / §5c，**不是 derive 卡点**，是簿记漂移。
4. **新增** —— **`contracts/_index.md` 写死取值条数，违反 `auth.md` §10 的明文纪律。** `_index.md` 原句「…`session_revoked` **八值** · `nickname_rejected` **三值**」；`auth.md` §10 原句「**本表是该字段取值的唯一权威，且它按设计会持续扩张——引用它的地方一律写指路、不写条数。**」当前数值恰好正确，但**写法本身是被禁止的形态**——08-30 那处「七值 vs 八值」的漂移正是这么来的。改成指路即可根治。
5. **D-1 · 仍在（第五次记录）** —— `vision/scope.md` 的 In scope 四条**仍未列付费验票域**，而本库已为该域落下 `contracts/purchase.md` · `operations/purchase-ops.md` 与 7 份 ADR。**同理合规域**在 In scope 里只被压缩成半句「合规所需的账号能力（注销、数据导出等）」，与 `operations/compliance-ops.md` + `moderation.md` + `ADR-0026`~`0037` 的体量严重不匹配。**⚠ 订正 08-30 的一处误判**：旧评估称此处是「`purchase.md` §3 指回本文件取范围权威而本文件没写 ⇒ 真空指」——**这个指控不成立**。直读 `purchase.md:29` 原句是「范围权威在 `game-design-documents/vision/scope.md`」，指的是**客户端库**，而对侧 `scope.md` 明列三渠道，**该指针解析成功**。真正的缺口是本库 `scope.md` 的 In scope 未覆盖它自己已经承载的域——这是失真，但不是真空指。
6. **D-2 · 新增（🔴 与已落定事实直接冲突）** —— `vision/scope.md` **两处仍断言技术栈未定**：抬头「技术栈、托管与协议形态**均未定**（见 `open-questions.md`）」· 文末「…`01-contracts.md`（边界层已成文，**余下各端点报文本体**）与 `06-platform-stack.md`（**技术栈 / 托管全未定**）」。两句均已被 09-03 的 `handoffs/2026-09-03-backend-stack-and-hosting.md` + `ADR-0021` 推翻，且 `01` 分片自陈「六份契约全部完全成文…待答清单已清零」。**`scope.md` 是本库唯一仍在断言「全未定」的文档。**
7. **D-3 · 新增** —— `vision/scope.md` 的边界表断言「跨越这条边界的客户端成分有**三个**」（account / sync / content-service），付费验票三端点与合规六端点在该表中无落位。与 D-1 同源，可一并订正。
8. **新增** —— **`operations/_index.md` 自陈与自身内容相抵**：写「本索引不再承载运维面的正文——各面展开在下表的对应文档里」，而其下两节共 9 条实质纪律仍在正文里。其中「收据幂等表须显式关闭任何 TTL / 过期清理，并在配置层留一条断言」与 `purchase-ops.md` §3c 的同一条**并存** ⇒ 一处第二权威，两份会各自漂移而无机制发现。
9. **新增** —— **三处已答结但正文仍写「归 `06`」的悬空指路**：① `contracts/auth.md` 称「改名频次阈值…归 `06`」，而该阈值已在**同文件 §8 旋钮表**定值 3 次 / 30 天（`ADR-0043`），同段还自称「取值表已封定」⇒ 自相矛盾；② `contracts/compliance.md` 与 `operations/compliance-ops.md` 两处「实名核验服务商与灾备归 `06`」——灾备形态 09-06 已答结（`external-providers.md` + `ADR-0038`~`0040`），`06` 分片已无此条；③ `contracts/purchase.md` 称冷存归档「形态需真实体量才能定」，而三层形态与对账阈值 N 的初值 / 校准公式 09-06 已定（`purchase-ops.md` §3d / §4 + `ADR-0045`），待定的只是三条触发阈值的**取值**，不是形态。
10. **新增** —— `contracts/content-manifest.md` 一处**悬空指路**：「是否引入缓存层本身不在此裁决（`open-questions/04-content-delivery.md`）」，而 `04` 抬头已是「待答清单已清零」、其中没有此条；答案实际在 `operations/content-delivery-ops.md` A6（不引入 + 触发判据 + 键必含 `flagsVersion`）。
11. **新增（分类口径不一致）** —— `06` 的「昵称审核阈值取值」与 `02` 的从属项「第三方昵称审核首版是否启用」，在主题文档侧已被写成首版结论（不启用 · 不定值 · 透传恒放行，`moderation.md` · `external-providers.md`），却仍以「待答」形态留在分片里；而同类的 `04` 三点已被显式改造为「条件化核对项（不是待办）」⇒ **两处处置不一致**。建议同款处理（转条件化项，或在条目里就地注明「首版已定不启用，取值仅在启用假设下待定」）。**注意这不改本次判定**——因为默认形态不等于裁决，第④级仍作排除面。
12. **仍在（文字滞后，非欠账）** —— `contracts/envelope.md` 文末「跨库待办（客户端侧）」五项对侧已于 08-11b 落笔，该段文字未清理，**会被读成本库仍在等对侧**。
13. **工程欠账（非漂移，两处陈述一致）** —— `operations/deployment.md` 与 `operations/_index.md` 均写 `contract-spec-check` workflow 与校验脚本**尚未落地**，三条机检断言当前以人工清单前三项执行。首批 FR 落笔时会撞上它。
14. **无失真** —— `decisions/_index.md` 50 行 ⇔ 50 份 ADR 逐条一致且全 Accepted，20 个影响文档路径全部存在；`handoffs/_index.md` 35 行 ⇔ 35 份 handoff、全部 `distilled` 且均填 `distilled-to`；`inbox/` 顶层为空（`archive/` 31 ⇔ 31）；`answer-logs/` 30 ⇔ 30（与 archive 差 1 属同批合成 slug 的正常形态）；`operations/_index.md` 9 行 ⇔ 9 份正文；`requirements/_index.md` 如实写「当前尚无 FR」并把就绪度权威指回本小节。

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

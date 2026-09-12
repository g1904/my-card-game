# Open questions — 后端待答清单（索引）

> 本文件是**后端**（云端服务）待答清单的**索引**；
> 问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 客户端侧的待答清单在 `game-design-documents/open-questions.md`（`game-design` 分支），
> 两份互不覆盖：**一个问题落在哪一侧，看它由谁实现**。
>
> 此清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；
> 一旦答定就从分片中移除、归档进对应主题文档，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> **最近更新：2026-09-12** —— 清单专职重整：零移出，修 15 处失效回链与三处失真（详见 `open-questions/update-log.md`）。
> （逐次更新摘要见 `open-questions/update-log.md`；答结归档见 `answer-logs/`。）

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身。 |
| `open-questions/01-contracts.md` | **① 协议契约**（六份已成文）：**1 条待答**——微信下单端点在付费系列上架窗口外的应答码。展开见表下 |
| `open-questions/02-account-compliance.md` | **② 账号与合规**（待答已清零，余一条外部事实挂账项）：展开见表下 |
| `open-questions/04-content-delivery.md` | **④ 内容分发（CDN）**（待答已清零，余条件化核对项与指路）：展开见表下 |
| `open-questions/06-platform-stack.md` | **⑥ 技术栈 · 托管 · 运维**（栈与运维形态已落定）：余**两条待实测取值**——成本模型 · `riskEventBufferRows`；另有一节条件化核对项（昵称审核阈值，首版不启用故不定值）。 |
| `open-questions/07-internal-tools.md` | **⑦ 内部运营工具**（人工处置面，权威落点 `operations/internal-tools.md` 已建立）：开片两条已答结，余两条相邻真空——告警接收人 / 值班形态 · 客服侧的账号查询入口。 |
| `open-questions/cross-boundary.md` | **跨边界承接**：客户端已定案、本库尚未落笔的条目。常态下**不是待答问题**——答案已有，等的只是落笔；形态与关闭条件见分片抬头，机制设计见客户端库同名分片。**「待承接」现为空**（付费角色系列的三项义务已于 2026-09-12 两侧同批落笔）。 |

分片展开（承接上表）：

- **`01`** —— 六份契约**全部完全成文**（→ `contracts/envelope.md`、`content-manifest.md`、`auth.md`、`profile-sync.md`、`purchase.md`、`compliance.md`）；
  三条机检断言的工程承载亦已答结（设计库分支上的独立 workflow）。flags 端点零装载的错误应答裁定为**不新增专属码、维持 `server.unavailable`**（判据落 `envelope.md` §6 承重项，台账表零增减）。
  **余 1 条待答**：商户侧下单渠道（微信）在付费系列**上架窗口外**的下单请求如何应答——窗口校验现只落在 verify（付款之后），前移到 `order` 没有语义合身的既有 `code`。不阻塞首版（微信渠道首版不开通），但它是付费系列那次变更中唯一可能破坏「失败 `code` 零新增」的一处。
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
`systems/` 三份服务文档与 `operations/` **十份**文档全部建立——全库再无结构性前置。**合规能力的上线分级亦已答结**（四项全部首版必备 · 昵称审核留位不启用 · 两份发布前置清单），**内部运营工具面亦已落定**（`operations/internal-tools.md`：`operator_id` 内部身份 · `/internal/` 不属于契约面 · CLI 调用方 · 复核台与 `ops_ticket` 工单台）。焦点因此落在四类：

1. **`01` 一条真实待答（唯一一条设计取向面的待答）** —— 微信商户侧下单端点在付费系列**上架窗口外**如何应答（2026-09-12 新增）。窗口校验现只落在 verify（付款之后），前移到 `POST /v1/purchase/order` 没有语义合身的既有 `code`。**不阻塞首版**（微信渠道首版不开通），但它是付费系列那次变更中唯一一处可能破坏「失败 `code` 零新增」的地方，须在微信渠道开通前答定。`ADR-0068` 明写不预判本项。
2. **`06` 两条待实测取值** —— 成本模型（实例规格 · 灾备副本数 · CDN 成本 · 收据归档与对账阈值的定值 · 剧本下载量上界，共同前置是 DAU 预期）· `riskEventBufferRows`。两条都不取决于任何形态决定。
3. **`07` 两条相邻真空** —— 告警接收人 / 值班形态（全库工程级告警共用同一个真空：有口径、无接收方）· 客服侧的账号查询入口（可见字段范围须单独裁决）。两条均不阻断已落笔的任何形态。
4. **两条须以外部事实核实的项，不是设计待答** —— `02` 的挂账项（实名核验是否另需对接主管部门的实名认证系统，须以真实过审要求核实）·
   微信开放平台资质的审批到位时刻（`operations/external-providers.md` · `operations/deployment.md` 第一份前置清单第 4 项）。两者的共同处置都是：未到位则**推迟上线**，不降级放行。

## 判据：一个问题落在哪一侧

| 判据 | 归属 |
|------|------|
| 由客户端代码实现、后端不感知 | `game-design-documents/` |
| 由后端实现，或需要两侧约定报文 | 本库 |
| 客户端语义已定、只剩服务端如何兑现 | 本库（在条目中注明「客户端侧已定」+ 日期 + 回链） |

## derive 就绪度

> 本小节由 `/assess-derive-readiness` **独占写入**（`/analyze-new-ideas` 与 `/summarize-open-questions` 均不得改动）。就绪度需基于全库一次性全量扫描才有意义，顺带评估会迅速过时且互相矛盾。

**最近全量评估：2026-09-12（由 `/assess-derive-readiness` 产出）。** 扫描范围：`vision/`（2）· `contracts/`（7 份 `.md` + `vectors/splitmix64.json`）· `systems/`（`_index.md` + `account.md` + `profile-store.md` + `content-delivery.md`）· `operations/`（`_index.md` + **10 份正文**）· `decisions/`（**68 份 ADR，全部 Accepted** + `_index.md`），共 **94 份**（09-11 为 89，增量 = `ADR-0064` ~ `ADR-0068` 五份）。旁证：`requirements/` **零 FR**（无「已覆盖」项）· `handoffs/` **43 份全为 `distilled`** 且 43 行台账逐条对齐 · `inbox/` 顶层为空（`archive/` **39 ↔ 39**）· `answer-logs/` **36 ↔ 36** · `operations/_index.md` **10 ↔ 10** · `systems/_index.md` 3 ↔ 3 · `decisions/_index.md` **68 ↔ 68**（`ADR-0001` ~ `ADR-0068` 连号无缺，非 Accepted 者 **0** 份）。

**全局结论：ready 13 份 · partial 5 份 · blocked 其余（全部为非 derive 对象或结构性 blocked）—— 全库仍无 🔴 就绪度卡点，仍可以开始 derive。** 较 09-11 的**唯一档位变动**：`contracts/purchase.md` **ready → partial**。原因是判据 2 而非内容退步——该文件的 `## Open questions` 自 09-11 的「**无待答项**」变为**一条真实待答**（微信商户侧下单端点在上架窗口外如何应答，无 ADR 覆盖，同题已登进 `01-contracts.md`）。它**不阻塞第二波 derive**：微信渠道首版不开通，窗口外的下单在首版恒回 `purchase.channel_disabled`，该分支可直接写成否定断言，待答的那一格作排除面标清即可。

**本次评估与 09-11 之间的增量（全部来自 `handoffs/2026-09-12-premium-character-series-unlock.md` 一次跨库落笔）：**

- **五份新 ADR，全部 Accepted、日期 2026-09-11**：`ADR-0064`（付费角色系列取**系列级 SKU**，`productId = "series_" + <slug>` 机械变换，后端零内容知识、零新增下发面与端点）· `ADR-0065`（**验票应答按 `kind` 分形**，`oneOf` + `discriminator`，请求侧一格不加）· `ADR-0066`（`/entitlement/characterSeries` 进**后端写入字段封闭表**——该表成文以来的**第一次扩表**，4 行 → 5 行，透明白名单同加一行）· `ADR-0067`（**重复购买已拥有系列：接受写入 + 风控事件，绝不拒绝、不自动退款**）· `ADR-0068`（**上架窗口只约束「能不能买」**，不进 profile、不进任何封闭表、不下发客户端）。
- **五份主题文档被编辑**（09-11 那次评估「全库主题文档零编辑」的状态就此结束）：`contracts/purchase.md`（§2 写入按 `kind` 分流 · §3 / §4 应答分形 · §3a SKU 类别与机械变换与上架窗口 · §3c 重复购买处置 · §6 新增保证 8 · §7 幂等记录三格 · **新增一条待答**）· `contracts/profile-sync.md`（§5 封闭表与透明白名单各加一行、护栏措辞由「四项」改「五项」并逐条论证 · §5c 具体面表与比较口径表各加一行）· `systems/profile-store.md`（`receipt_idem` 加 `product_id` / `kind` / `granted_series_id` · verify 事务行改写 · 实现纪律 4 条 → **5 条**）· `operations/purchase-ops.md`（**新增 §1a** SKU 表 / 渠道商品类型 / 上架窗口 + 发版前核对清单五项 · §5 新增重复购买的工单处置）· `operations/version-matrix.md`（`schemaVersion` 子表新增 **`2`** 行 + 三条附注）。另 `contracts/_index.md` 一处计数订正（封闭表「四项」→「五项」）。
- **`envelope.md` 零改动、`code` 与端点零新增**（`ADR-0067` / `ADR-0068` 均逐条论证「玩家面为空 / 处置逐字相同 ⇒ 不独立成码」）⇒ §6 的 30 行错误码台账与 §3 端点全集表**一字不动**，两条提取护栏与三条机检断言的基准不变。

**三条贯穿全库的判据说明（先读，避免误判）：**

- **判据 1 的形式说明（沿旧）。** 六份契约中只有 `content-manifest.md` 带正式 `## 意图` 标题；其余五份把同等分量的范围陈述放在标题下的 `>` 前言里。**全库无一处模板占位符 `> _..._`**（本次复扫零命中）。判据 1 按「有真实内容」判定，**不按标题字面判定**。
- **库级 derive 限定语（沿旧，仍成立）。** `contracts/envelope.md` §1 自陈「在某端点的 spec 落笔前，其 markdown 字段表视为草案」。**处置不变：以 markdown 为源 derive，待 `openapi.yaml` 落笔时做一次纯形态对账——不作为闸门。** `openapi.yaml` 与 `schemas/` 至今不存在（本次复测确认），符合「不预先建空壳」，触发点是任一侧首个端点进入实现。
- **「非 FR 面」不是欠账。** `vision/` 两份（北极星与五条裁决原则）、各 `_index.md` 台账、`vectors/splitmix64.json`、68 份 ADR 按定义就不是 derive 对象，**永远判 blocked 不代表缺内容**。
- **内部面（`/internal/`）的 derive 归属（沿旧，仍成立）。** 内部端点**不进 `openapi.yaml`、不进 `envelope.md` §3 端点全集表、不进 §6 错误码台账**（`ADR-0062`）⇒ 为它写 FR 时，**「契约变更的完成判据」六条与三条机检断言一律不适用**，正确性由 `internal-tools.md` 的 I1–I10 承担。`ADR-0063` 同批适用。

**卡点结构：一条新的真实待答（不阻塞首版）+ 纯参数化：**

- **🟠 新增 · `01` 一条真实待答** —— **微信商户侧下单端点在上架窗口外的应答**。窗口校验现只落在 verify（付款之后），前移到 `POST /v1/purchase/order` 更合「把失败点挪到掏钱之前」，但下单端点没有语义合身的既有 `code`（`channel_disabled` 讲渠道未开通、`receipt_invalid` 的客户端处置针对已付款玩家）。**它是付费系列这次变更中唯一一处可能破坏「失败 `code` 零新增」的地方**，须在微信渠道开通前答定。**首版不受影响**（微信渠道不开通）⇒ 只把 `purchase.md` 判为 partial，不阻塞任何一波 derive。
- **🟠 `06` 两条待实测取值** —— 成本模型（共同前置 = DAU 预期）· `riskEventBufferRows`。两条**均不取决于任何形态决定** ⇒ derive 时一律写成「存在该旋钮 + 落 `config_knob` + 改值不发版」的形态断言，不取数字。同类四项（`internal-tools.md` 数值初值表）：工单租约超时 60 分钟 · 工单终态保留 180 天 · 内部动作审计保留 1095 天 · 内部凭据校验失败告警阈值（不定值）。**本次新增同款参数化项**：`purchase-ops.md` §1a 的**上架窗口取值**（逐 SKU 的运营配置，形态已定死 `[startAtUtc, endAtUtc)` + 空 = 常驻）⇒ 写形态断言，不取具体时刻。
- **🟠 `02` 一条外部事实挂账项** —— 实名核验是否另需对接主管部门的实名认证系统。**不阻塞任何已落笔的形态**，按 `04` 分片先例写进 FR 的 Scope 段作条件化核对项。
- **🟠 `07` 两条相邻真空（均不阻断 derive）** —— ① 告警接收人 / 值班形态（运维配置面，不产验收断言）；② 客服侧的账号查询入口（`internal-tools.md` 明写不在本面内，六端点最小集封闭 ⇒ 属未来范围）。

**跨边界闭合（强制检查项）—— 本库欠对侧 0 条 · 对侧欠本库 0 条。**

- **付费角色系列的跨边界承接本批两侧同批落笔、当场关闭**：本库 `open-questions/cross-boundary.md`「待承接」**现为空**（09-11 登记的那一条已答结并转入对账基线）；登记时留的两问均已答结——SKU 粒度 = **系列级且只有这一种** · 封闭表**两张都加**（正交、非二选一）。这是本库首次在**同一批内**完成「登记 → 落笔 → 关闭」，不再有第二半不会发生的风险。
- **两条常驻机械义务的本次核查结果**：① `profile-schema-versions.md` 新增行 ⇒ 登进 `version-matrix.md`——**本次触发且已兑现**（客户端 `schemaVersion = 2` ⇒ 矩阵子表已加 `2` 行，并写下「矩阵先加、客户端后发」的顺序纪律与「若付费系列改在首发之前落地则本行整行不成立」的条件分支）；② `auth.md` §4 任一条被改写 ⇒ 触发对侧重评 refresh token 本地存放取向——**未触发**（`auth.md` 09-08 之后零编辑）。
- **对侧待落笔 2 条仍未动**（不是本库欠账）：客户端 `open-questions/cross-boundary.md`「待承接」的 `ADR-0051`（manifest 路径分支拼法）· `ADR-0052`（CDN 域 4xx 两分处置），均标 2026-09-07。它们是第五波（内容分发）的客户端对位面。
- **预警仍未触发**：`characterProfile` 的资源字段一旦提进透明档，必须同批把钳制语义与 `AppliedChange` 累加语义写进 `profile-sync.md`。本批 `profile-sync.md` 虽被编辑，改的是 `entitlement` 键，`characterDiffs` 仍整体落不透明段。
- **五份新 ADR 对客户端的跨边界影响已由对侧同批承接**（客户端半见 `game-design-documents/handoffs/2026-09-12-premium-character-series-unlock.md`），**本库不复述其形态**；两条相互依赖（有序逐元素回声的前提 = 客户端原样回声不重排 · 矩阵先加客户端后发）两侧均已留痕。

| 文档 | 判定 | 卡点 / 就绪切片 |
|---|---|---|
| `contracts/profile-sync.md` | **ready，无排除面**（本批被编辑，档位不变） | **就绪切片 = 全文**：§1 两端点封定 · §2 pull 三字段与建号骨架（**「后端还能写入的时机」改述为按 SKU 类别分流，时机集合一字未增**）· §3 六字段负载信封 + 空 diff 照常 `+1` + 未知 `reason` 宽容 · §3a 顶层键浅合并 · §4 三分支 + 幂等命中五行表 + 判定顺序 + 四类拒绝均不消耗 `revision` · §5 **十四行白名单 + 后端写入封闭五行表**（新增 `/entitlement/characterSeries`，护栏措辞同改为「除表内五项外」并附逐条论证）· §5a / §5b / **§5c**（具体面表 + 比较口径表各加一行，`characterSeries` 取**有序逐元素**）· §6 / §6a SplitMix64 + 8 组已填向量 · §7 复算三检查 · §7a 仅记账不拒绝 · §8 账号级线性化 + 读己所写 · §9–§12。`## Open questions` 仍明写无待答项。**三条参数化纪律不变**。新增可直接转验收的否定断言：受约束顶层键**恰有两个**一字不改（`entitlement` 本就在内） |
| `systems/profile-store.md` | **ready，无排除面**（本批被编辑，档位不变） | **就绪切片 = 全文**：承重列四表（`receipt_idem` 记录体新增 `product_id` / `kind` / `granted_series_id`，后两者按 `kind` 二选一）· 事务边界四行（verify 行改述为「`doc` 的一处写入，按 SKU 类别落 `bundleGrantOrdinal += 1` 或 `characterSeries` 尾部追加」）· **五条实现纪律**（新增第 5 条：集合追加必须在同一次已加锁的 verify 事务内「读—判重—追加」· 恒在尾部不排序不去重 · 元素字段形状由客户端定义原样写入 · 判重读本事务内已加锁的当前值；纪律 4 的封闭校验面加入 `kind`）· 两类幂等记录的分轴对照 · `push_idem` 月分区 · `receipt_idem` 全局唯一键与同事务序号推进 · 读己所写 · 512 KB 体积软告警。依赖全闭合；`ADR-0008` · `0013` · `0017` · `0021` · `0045` · **`0066`** 全 Accepted |
| `contracts/purchase.md` | **partial**（**本次由 ready 降档**，判据 2；排除面一块，切片仍近全文） | **降档原因**：`## Open questions` 由「无待答项」变为**一条真实待答**——**微信商户侧下单端点在上架窗口外如何应答**（无 ADR 覆盖，同题登在 `01-contracts.md`）。**就绪切片 = 除该点外的全文**：§1 三端点 + 全部需鉴权 · §2 写入只由 verify 承担 + **写入动作按 `kind` 两行分流表** · §3 请求根判别式（`ADR-0018`）+ **应答按 `kind` 分形**（`oneOf` + `discriminator`，`bundleGrantOrdinal` 降为仅 `PremiumBundle` 存在，`revision` / `deduplicated` 两类同有）+ 六行失败面表 · §3a 三张渠道 `receipt` 字段表 + **SKU 类别两行表 + `productId = "series_" + <slug>` 机械变换 + 形态校验而非存在性 + 上架窗口在 verify 侧回 `receipt_invalid` 零新增码**（`ADR-0064` · `0068`）· §3b 下单端点与 `Unknown` 预落记录 · **§3c 重复购买已拥有系列：接受写入 + `revision += 1` + `deduplicated = false` + 风控事件、绝不拒绝、不自动退款**（`ADR-0067`，与 `profile-sync.md` §7a 逐字同构）· §4 `status` 三值 + `Verified` 同款分形 + 老客户端前提写明 · §5 **整节只对 `PremiumBundle` 适用** · §6 **八条保证**（新增保证 8「只增不删、元素唯一」；保证 4 / 7 对 `CharacterSeries` 不适用、保证 5 由 §5c 恒等式自动覆盖）· §7 幂等记录存储形态三格 + `receiptId` 全局唯一键 + 永久保留 · **十四条「已否决的替代」**（本批新增 8 条，条条可转否定断言）。**排除面（唯一）**：`POST /v1/purchase/order` 在上架窗口外的应答——**首版可写成否定断言**（微信渠道未开通 ⇒ 恒回 `purchase.channel_disabled`），微信开通前须答定，答案可能触及 `envelope.md` §6 台账 |
| `operations/purchase-ops.md` | **ready**（本批被编辑，档位不变；排除面由三块增至四块） | **就绪切片 = 全文**：§1 三渠道凭据与轮换 · 托管形态 · 收据环境校验以部署环境配置为准 · **§1a SKU 表四列**（`productId` · `kind` · 渠道商品类型 consumable / non-consumable · 可空上架窗口 `[startAtUtc, endAtUtc)`，空 = 常驻）+ 「限时销售不是绝版」三条 + **发版前核对清单五项**（逐项带「漏掉的后果」，可直接转人工过闸清单）· §2 三条对账通道 + 对账不驱动任何自动写入 · §3a S1–S3 选型判据 · §3b 哈希分区与部分索引 · §3c TTL 禁用断言 · §3d 三层分工 / 哨兵行五列 / 读路径五分支 / 归档任务三步顺序不可颠倒（记录体列新增 `product_id` / `kind` / `granted_series_id`）· §4 两条对账信号与 N 的校准公式 · §5 风控高优四项 + **重复购买的工单处置**（事件四字段 · 不自动退款的三条理由 · 人工工单通道 · 按周计数 gauge 不做逐账号告警）。**四块排除面**：§3a 退化形态 · §3d 归档任务（`receiptArchiveEnabled` 初值 `false`）· 下单端点的滥用阈值（无初值、无旋钮 key ⇒ 只能写形态断言；另有一条遗留旧就绪度断言，见漂移清单第 2 条）· **§1a 的逐 SKU 上架窗口取值**（运营配置数据登记，非 FR 面；发版前核对清单是人工过闸流程，同属非 FR 面） |
| `contracts/compliance.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片 = 全文**：§2 六端点集与鉴权形态 · §3 ticket 机制（一次性 · 10 分钟 · 单端点 · 60 秒兑付回放窗口 · 兑付不签发 token）· §4 拦截只在 `signin` · §5 四条 `compliance.*` 拦截码 + 七值 `reasonKey` 表 + 求值顺序写死（`ADR-0037`）· §6 时段口径落配置 + 可信服务端时钟 · §7 防沉迷复用 `auth.session_revoked` 五步映射 · §8 导出正列白名单 · §9 九行旋钮初值 · §10 六端点报文字段表 · §11 三条端点自身错误码。`## Open questions` 章节整体不存在 ⇒ 判据 2 直接成立 |
| `operations/compliance-ops.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片 = 全文**：可信时钟基准与两处例外 · 同步纪律 · 时段规则集承重列与「判定时读当前最高版本、不做预约生效」· 法定节假日日历四步判定顺序 · F1 / F2 / F3 三个失败面的降级语义 · ticket 条件更新 + 五级短路求值顺序 · 外部核验两段事务 · 注销冷静期状态三值与三端点分支 · 执行时删什么的完整表（含 `operator_audit` 保留行）· 导出任务三条断言与两道保留期 · 周期任务四条与八个旋钮 · 上线分级四行表。ADR 前置齐备（`0028`~`0037` 全 Accepted）。**条件化核对项（不作验收断言）**：`02` 的主管部门实名认证接入义务 |
| `operations/external-providers.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片 = 全文**：A1–A6 共有形状 · 四个接口签名 · 三张归一映射表 · 逐能力供应商数与灾备判据表 · 短信切换触发判据与回切滞后 · 禁并发双发 / 同码转备用至多一次 / 禁双验 · 「一次 `challenge` 至多两次外部调用」· 选型判据 H1–H4 / S1–S4 · 凭据托管（能力 × 供应商 × 环境）· 可观测性五行增量与余额低水位两档 · 微信资质过闸断言 · 数值初值六行。`ADR-0038`~`0042` 全 Accepted。**排除面两块**：不点名具体服务商 · 微信资质前置链（外部审批日程，非 FR）。第三方昵称审核能力面写否定断言（供应商数 0，`ADR-0055`） |
| `contracts/auth.md` | **ready** | 维持 ready（09-08 之后零编辑；本批五份新 ADR 均不触及登录域——`ADR-0064`~`0068` 全部落在购买 / 存档 / 运维配置面）。**就绪切片 = 全文**：§1 / §1a 七端点 + 身份模型 · §2 双 token 与 TTL 表 · §3 / §3a 渠道分形与换 openid 三条义务 · §4 rotation + 60 秒宽限 + 四分支求值顺序（`ADR-0053`）· §4a 会话裁决 · §5 / §5a / §5b · §6 头矩阵 · §7 七端点重放表 · §8 报文 + 四级短路判定链 + 13 行旋钮初值表 · §9 五个错误码 · §10 两张取值表 · §11。`## Open questions` 自陈「无待答项」。**排除面**：判定链第④级第三方审核适配器写成「恒返回 Pass、不产生任何外部调用」 |
| `systems/account.md` | **ready**（排除面一块） | 维持 ready（本批零编辑）。**就绪切片 = 全文**：存储形态承重列**十五表** · 事务边界**十行** · 注销执行行的删除清单 · `tokenId` 与 `sid` 的分工 · refresh token 五分支校验 · access token 签发四条 · 渠道能力适配层两条纪律 · 昵称判定链 N1–N10 · 存量扫描 S1–S5 · 合规域 C1–C6 / D1–D7 / E1–E6 / P1–P5。`claimed_by` 取值域已由 `ADR-0061` 定死。无 `## Open questions`。**余下唯一排除面**：判定链第④级 + N9 → 写「恒返回 Pass、不产生任何外部调用」。**参数化纪律**：改名频次上限 · ticket 寿命 / 60 秒回放 · 冷静期 15 天 · 导出保留期一律写「配置阈值」 |
| `operations/internal-tools.md` | **ready** | 维持 ready（本批零编辑）。三条 ADR 前置齐备（`0061` 身份分离 · `0062` 内部面不属契约面 · `0063` 人类身份只读）。**就绪切片 = 全文**：内部身份 `operator_id` + 全库四处「操作者」空洞的唯一取值域 · 认证（`Authorization: Bearer <operator_id>.<secret>` · 不签发会话不做 rotation · 轮换 = 新行 + 停用旧行 · 企业 IdP 留位不启用）· `/internal/` 不属于契约面的三条判据 + 六端点最小集 + 「明确不提供任意查询面」· 界面档次 CLI + 人类身份对业务表恒只有 `SELECT`（`ADR-0063` ⇒ 可写否定断言，权限分层落建库脚本）· 复核台 `claimed_by` 四行机械形态 + 两类判定各自的一次事务清单 + 「云端昵称一字不变」· `ops_ticket`（软引用两列不建外键 · 部分唯一索引 · 租约 60 分钟 · `decision` 三值）· 处置事务边界五步伪码 + `baseAccountStatus` 乐观前置 · `operator_audit` · 可见字段范围三行表 · 上线时点 · **服务端保证 I1–I10** · 数值初值四行。**两块排除面**：告警接收人 / 值班形态 · 客服侧账号查询入口（均为文档自陈的范围外项）。**derive 时注意**：`ADR-0062` ⇒ 本份 FR **不适用**「契约变更的完成判据」六条与三条机检断言 |
| `operations/moderation.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片 = 全文**：词表两档分级与不可变版本化发布 · 存量扫描 T1 / T2 / T3 与台账六字段 · 处置阶梯三档 · `nicknameChangeRequired` 由云端状态算出 · 风控事件字段表与 `kind` 十值 · 累计阈值分档与全局熔断（1% / 0.5%）· 四张台账的存储形态整节 · **服务端保证 M1–M11** · 数值初值表 16 行。无 `## Open questions`。**排除面一块**：第三方昵称审核适配器首版不启用（`ADR-0055`）⇒ 写否定断言。**注意（本批新增的相邻事实，不改判定）**：`purchase-ops.md` §5 新增的「重复购买已拥有系列」风控事件走**同一条风控通道**，其 `kind` 是否需要进本文件的十值枚举，属 derive 时的一次机械核对，不是设计未决——契约与运维两侧都已把处置写死。**建议与 `internal-tools.md` 同一波 derive** |
| `contracts/content-manifest.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片 = 全文**：端点四行表 · `manifestSchema: 1` 八行字段表 + 全量清单 / 路径穿越 / semver 三段比较 · ES256 detached · 三版本号分工 · A 组四条 + B 组三条与三个失效来源 + `X-Flags-Version` 取 `min(高水位, 本实例可兑现)`（`ADR-0047`）· 路径分支（`ADR-0051`）· CDN 三端点失败状态码 11 行表与 4xx 两分判据（`ADR-0052`）· flags 报文五字段（`enabledIds` 恒空是硬契约）· 对客户端缓存的四行零义务否定表 · `## blob 通道不承载二进制资产`。全文无 `## Open questions`。**本批复核**：`ADR-0064` 明写角色系列**零新增下发面**——不经 manifest / flags 通道，本文件因此零增量 |
| `systems/content-delivery.md` | **ready**（排除面一块） | 维持 ready（本批零编辑）。**就绪切片 = 全文**：三份缓存的分工表 · 规则集缓存必须进程内不得落 Redis 的承重理由 · single-flight 回源 · 版本预热的请求无关触发（`ADR-0060`）· 「一次快照引用」的应答构造手法 · `X-Flags-Version = min(高水位, 本实例可兑现)` 与偏斜不对称性 · 取数面 = 已装载的最大键 · 回源失败三分支降级（F7 取兜底码 `server.unavailable`）· LRU 上限 8 · 四条实现纪律 · **服务端保证 F1–F8**。**余下唯一排除面**：「存储形态：承重列」与「唯一写入面与事务边界」两节仍是回链占位（实体在 ops 的 A1–A3 / A5）⇒ FR 的 `Data & state touchpoints` 需跨文档取 |
| `operations/content-delivery-ops.md` | **ready** | 维持 ready（本批零编辑）。**就绪切片**：CDN 两类对象两种 TTL · 内容发布流水线 ⓪–⑦ 全序 + 双发期读法五条 · 发布侧校验闸 C1–C6（`ADR-0050`）· 留痕八字段 · A1–A5 规则集存储形态与变更通道（`publish` 为唯一写入面且 `rollback` ≡ `publish` · 直连写入权限禁止，`ADR-0063`）· flags 发布 / 回滚 O1–O7 与留痕四项 · B1–B5 私钥保管与 standby（`ADR-0049`）· `keyId` 轮换三类触发 / 四阶段 / 覆盖率 95% / T2 后 48 小时观察窗 · 传播窗口 T 的口径与三项预算 · 数值初值一览 10 行全部有初值。**排除面（文档自陈）**：A4' 池规模缩放（未采纳）· 对 CDN 的能力要求与三路径负缓存 · 内容校验规则本体（权威在客户端库，`ADR-0048`） |
| `operations/deployment.md` | **partial**（小切片，主体属非 FR 面；可产出 FR 的面 4 处） | 维持 partial（本批零编辑）。**可产出 FR 的**：① 启动自检解析时区名失败即拒绝启动（`ADR-0029`）；② G-1 / G-2 两条否定断言；③ 第一份清单第 4 / 5 / 6 项的机检形态过闸断言；④ 第二份清单第 4 项「内部处置台可用」的完整端到端断言，可**逐字**转成验收标准。**非 FR 面**：构建与制品 · expand→deploy→contract · 两份清单的人工过闸流程 · 周期性运维日程 · 共享 DTO 护栏 · 入站运维通道。**未闭合项（自陈，非漂移）**：`contract-spec-check` workflow 与校验脚本**尚未落地**（本次复测：仓库仍无 `.github/`、无 `scripts/`）——它**不覆盖内部面**（`ADR-0062`）。**本批新增的相邻项**：`purchase-ops.md` §1a 的「发版前核对清单五项」是本库第三份人工过闸清单，形态与本文件两份同构，derive 时归同一类非 FR 面 |
| `operations/environments.md` | **partial**（窄切片，宜随服务 FR 兑现） | 维持 partial（本批零编辑）。**就绪切片**：「限流的实现分层」整节（fail-open 默认 · 三条 fail-closed 例外，`ADR-0031` · Redis 不可用放行并告警 · `refresh` 零限流的否定断言 · `Retry-After` 与 `detail.retryAfterSeconds` 同时给）· 密钥轮换「旧 `kid` 保留 ≥ access token TTL + 时钟偏移余量」· 定时任务出口的 `SELECT … FOR UPDATE SKIP LOCKED` 条件转移 · `identifier_mac = HMAC(...)` 明文不落库不落日志 · 本地开发 `kid` 空间与线上永不共用 · `config_knob` 的更新者与 KMS 解包事件审计的「谁」取值域为 `operator_id` · **权限与凭据面的否定断言**（任何人类身份对任何业务表无 `INSERT` / `UPDATE` / `DELETE`，分层落建库脚本，`ADR-0063`）。**其余属非 FR 面**：环境实体 · 配置三层与旋钮清单（数据登记，**本批新增的 SKU 表与上架窗口同属这一类**）· 区域与合规 · 拓扑与副本 · 容量形状 · 密钥保管。**已声明的排除（非卡点）**：实例规格 / 副本数 / 备份保留期待成本模型（`06`） |
| `operations/observability.md` | **partial**（窄切片，宜随服务 FR 兑现） | 维持 partial（本批零编辑）。**就绪切片 = 探针发射面**：五条契约语义探针 · **日志脱敏中间件**（纯否定断言，已覆盖内部端点）· 合规域三条探针与时钟两条探针 · 日历到期告警 · flags 版本预热落后量 gauge（`ADR-0060`）· 风控台账四条探针 · flags 零装载失败计数器。**非 FR 面 / 参数化**：告警阈值与 P1 分级属运维配置 · RED / 连接池 / 复制延迟属基座通用监控 · 时钟两条探针阈值待实测校准。**本批新增的相邻项（不改判定）**：`purchase-ops.md` §5 的「重复购买按周计数 gauge、不做逐账号告警」是一条新的探针发射面断言，**权威落在购买域运维文档**，本文件未同步登记——属簿记相邻项，见漂移清单第 15 条 |
| `operations/version-matrix.md` | **partial**（窄，宜随 auth / content FR 兑现；**切片本批扩张，卡点性质不变**） | 本批被编辑：`schemaVersion` 子表新增 **`2`** 行。**就绪切片（扩）**：四项形态表 +「当前矩阵」四行 + `schemaVersion` 一版一行的四列子表并登入 `1` 与 **`2`**（第四列恒为客户端登记回链，本库一个字段名都不写——可作否定断言）· **新增三条可直接转断言的附注**：`sync.payload_schema_unsupported` 的 `detail.supportedSchemaVersions` 随本子表走（两版并存期为 `[1, 2]`）· **顺序纪律「矩阵先加、客户端后发」**（违反的症状写死：新版客户端首次 push 即被拒，`Upgrade` 档不硬阻塞但进度上不去云端）· `2` 行的**成立条件**（付费系列若改在客户端首发之前落地则本行整行不成立、矩阵零改动）· 「闸门在签发 token 时判定一次、会话期内不中途变严」· 「提升 `appVersion` 下界的覆盖上限 = refresh 绝对寿命」· `manifestSchema` 双发下线序列 T0 / T1 / T2（`ADR-0051`）。**卡点仍为同两类取值**：`appVersion` 下界「待定」· `schemaVersion` 两行的「接受起始」均为「（待落）」、`2` 行的下线计划「待定」⇒ `client.version_unsupported` 与 `sync.payload_schema_unsupported` 两码的**形态可断言、边界不可断言**，并向下传导进 `profile-sync.md` §4。**另有一处标签滞后**（`manifestSchema` 集合行值列仍写「待定」而括号内已给出 `{1}`），见漂移清单第 6 条 |
| `contracts/envelope.md` | blocked（**结构性，非欠账**） | 共有层，**不存在独立可构建的增量**（无自身端点即无「请求 → 应答」验收断言），故即便内容极完备也判 blocked——FR 只能挂在其他契约的端点上兑现。**内容上已完备**：§1 表达形式与 spec 落笔规则 · §2 序列化八条 · §3 端点全集表 + P-3 机器读取面护栏 · §4a 无鉴权例外判据（`ADR-0016`）· §4b 应答头五项 · §5 错误体五字段 + §5a 脱敏 + §5b 三条降级 · §6 **30 行错误码台账 + P-1 护栏**· §7a–§7d · §8 三段可见性。**本批复核：台账与端点全集表零增减**（`ADR-0067` / `ADR-0068` 各自逐条论证不新增 `code`；`ADR-0065` 的应答分形只 bump `info.version` minor）。`## Open questions` 唯一条目是 `openapi.yaml` 落笔，**自陈属待落笔项而非设计未决**。**须留意**：`01` 那条新待答（下单端点窗口外应答）若答成「新增一个 `code`」，会是本台账首次加行——届时 P-1 护栏与两条提取护栏同批适用 |
| `systems/_index.md` | blocked（**非 FR 面**） | 索引 + 三份服务文档的公共前提。「共用的存储与并发形态」六条与「契约条款 → 数据库不变式」五行表是实质内容、可直接转为断言，但**无独立可观测的应答 / 存储结果**（触发拆解下界 L1 / L2）⇒ 落点应在 `account` / `profile-store` / `content-delivery` 的 FR 内。**台账：服务表 3 行 ↔ 3 份实际文件**，零悬空行、零孤儿文件 |
| `operations/_index.md` | blocked（**非 FR 面**） | 台账 **10 行 ↔ 10 份正文**，逐条对上、全标「已建立」，零悬空行、零孤儿文件。**残留半句待收**：收据 TTL 行仍在正文断言「它与 O6『历史规则集永久保留』是同形取舍」（见漂移清单第 7 条） |
| `contracts/_index.md` · `contracts/vectors/splitmix64.json` | blocked（**非 derive 对象**） | 索引 / 台账与机器可读的对表产物。`_index.md` 承载契约面清单、分域判据、「契约变更的完成判据」六条 + 三条机检断言 + 人工清单四项 + 两条提取护栏 + `schemas/` 拆分判据——全部是**流程约束与元规则**，无端点无报文；六份契约状态列均为「已成文」（本批仅一处计数订正：封闭表「四项」→「五项」）。**适用面边界**：这套完成判据与机检断言**对 `/internal/` 面不适用**（`ADR-0062`）。`splitmix64.json` 是 `profile-sync.md` §6a **唯一可执行的验收检查点**（8 组已填，不得单方面改表迁就实现） |
| `vision/scope.md` · `vision/pillars.md` | blocked（**非 FR 面**） | 北极星与五条裁决原则，只陈述边界与硬约束，**零可验证行为断言**。作为其余文档的挂靠前置成立（`pillars.md` #1「后端不懂 Profile 结构」正是 `ADR-0064`「后端零内容知识」与 `ADR-0066` 两表正交论证的承重前提），自身不产需求。**建议不进入 derive 候选池。** 本批零编辑 |
| `decisions/ADR-0001` ~ `ADR-0068`（**68 份全部 Accepted**）· `decisions/_index.md` | blocked（**非 derive 对象**） | 已采纳的决策记录与台账，作为其余文档的就绪前置，本身不产 FR。**就绪判据第 3 条对六份契约与全部 `systems/` `operations/` 文档全部成立**——**无一份文档受任何 `Proposed` / 未采纳 ADR 约束**（68 份逐份核对，非 Accepted 者 **0** 份；`_index.md` 中的 `Proposed` / `Superseded` 字样仅在状态词汇图例中）。**台账 68 行 ↔ 68 份实际 ADR 逐条一致**（`ADR-0001`~`0068` 连号无缺）。本批新增 `ADR-0064` ~ `ADR-0068` 五份，全部日期 2026-09-11、来源同一份 handoff |

### 建议的 derive 顺序（被依赖的契约先于依赖它的系统）

**第一波 —— 两条完全无排除面的纵向切片：**

1. **`/derive-requirements backend contracts/profile-sync.md`** —— 全库最成熟的一份。协议面完整、ADR 前置齐备（本批 `ADR-0066` 再加一条）、跨边界两向对它零欠账，且有 `vectors/splitmix64.json` 这个全库唯一可执行的验收检查点。**无排除面**，遵守三条参数化纪律即可。**本批新增的封闭表第五行与 §5c 两行须一并切进**——它们与既有行同形，不单独成 FR。
2. **`/derive-requirements backend systems/profile-store.md`** —— 同一条纵向切片的服务内部面。**无排除面**；实现纪律现为五条，第 5 条（同事务读—判重—追加）是本批新增的可直接转验收项。

**第二波 —— 购买纵向切片（本波带一块排除面，非阻塞）：**

3. **`/derive-requirements backend contracts/purchase.md`** + **`operations/purchase-ops.md`** —— `## Failure & retry semantics` 可写全。**本波须显式标出的排除面**：`POST /v1/purchase/order` 在上架窗口外的应答（`01` 待答）——首版写成否定断言「微信渠道未开通 ⇒ 恒回 `purchase.channel_disabled`」，并在 FR 的 Scope 段注明该点待答、答案可能触及 `envelope.md` §6 台账。其余三块排除面（§3a 退化形态 · §3d 归档任务 · 下单端点滥用阈值）与逐 SKU 上架窗口取值照旧参数化。**两类 SKU 的断言须成对写**：`ADR-0065` 的应答分形、`ADR-0066` 的封闭表行、`ADR-0067` 的重复购买处置、`ADR-0068` 的窗口语义，四者是同一条切片的四个面。

**第三波 —— 合规纵向切片（三份全 ready，只带一个外部事实挂账项）：**

4. **`/derive-requirements backend contracts/compliance.md`** + **`operations/compliance-ops.md`** —— 六端点逐端点断言可写全。`02` 的主管部门实名认证接入义务写进 Scope 段作条件化核对项。
5. **`/derive-requirements backend operations/external-providers.md`** —— 它是 4 与 6 的共同下游依赖（三张归一映射表）。

**第四波 —— 账号与会话纵向切片：**

6. **`/derive-requirements backend contracts/auth.md`** + **`systems/account.md`** —— 排除面只剩一块（第④级恒 Pass）。`version-matrix.md` 与 `deployment.md` G-1 / G-2 的窄切片随本波兑现；**`version-matrix.md` 的 `schemaVersion` 子表现为两行，「矩阵先加、客户端后发」的顺序纪律可直接转断言**。**注意**：`account.md` 的十五表与十行事务边界中，末四张表 / 末三行属内部工具面 —— 可随本波一并 derive，也可留给第六波与 `internal-tools.md` 合并；**二选一，不要两波都写**。

**第五波 —— 内容分发纵向切片（三份全 ready，零机制卡点）：**

7. **`/derive-requirements backend contracts/content-manifest.md`** + **`systems/content-delivery.md`** + **`operations/content-delivery-ops.md`** —— F1–F8 与 ops 的 C1–C6 / O1–O7 / A1–A5 可直接落成验收标准。**排除**：A4' 池规模缩放 · 客户端侧义务 · 承重列两节需跨文档取。**落笔前建议先催对侧落笔那 2 条已登记的承接义务**——它们正是这一波的客户端对位面。

**第六波 —— 人工处置纵向切片（整波 ready，可提前）：**

8. **`/derive-requirements backend operations/moderation.md`** + **`operations/internal-tools.md`** —— 两者是同一条切片的两端，**宜合并成一波**。**derive 时的三条特别纪律**：① `ADR-0062` ⇒ 内部端点的 FR **不适用**契约面的六条完成判据与三条机检断言；② 内部面的 `Contract touchpoints` 段应写「不触及任何契约面（`ADR-0062`）」，而不是留空；③ **`ADR-0063` 写成否定断言**，与 I1–I10 同体例，其在 `environments.md` 的同源对位断言**两波不要重复切**。**本批新增的一处机械核对**：`purchase-ops.md` §5 的重复购买风控事件走同一条风控通道，其 `kind` 是否入 `moderation.md` 的十值枚举，在本波或第二波择一处交代清楚，不要两波各写一遍。

`envelope.md` **不单独 derive**（共有层，随上述任一份的**首个** FR 一并兑现信封、错误体与相关错误码）。`operations/environments.md` · `observability.md` · `deployment.md` · `version-matrix.md` 的窄切片**均不单独 derive**，随对应服务的 FR 一并兑现。

> **注意：首批 FR 会同时触发 `openapi.yaml` 的首落**（`contracts/_index.md` 定：触发点 = 任一侧首个端点进入实现，首落范围 = **全部共有层 + 该一个端点**，且 spec 始终落本库）。同批须过「契约变更的完成判据」六条 + 三条机检断言 + 人工清单四项——注意 `contract-spec-check` workflow **尚未落地**（本次复测确认仓库仍无 `.github/`、无 `scripts/`），当前以人工清单前三项执行。**若第六波先行，则不触发这一条**（内部端点不入 spec）。**若第二波先行**，`ADR-0065` 的 `oneOf` + `discriminator` 应答分形是 spec 首落里第一处需要 `schemas/` 拆分判据的地方。

### 最短解锁路径

1. **全库仍无 🔴 就绪度卡点。** **可以开始 derive**——按上方顺序从第一波起。本次唯一的档位变动（`purchase.md` ready → partial）**不改变任何一波的可行性**，只要求第二波把那一格标成排除面。
2. **🟠 新增 · `01` 一条真实待答（不阻塞首版，须在微信渠道开通前答定）** —— 微信商户侧下单端点在上架窗口外的应答。**最短路径**：一次 `/provide-solution-draft backend`，推演三个选项（复用 `purchase.channel_disabled` 改述其语义 · 新增一个 `purchase.*` 码 · 下单端点不校验窗口维持现状），并逐条对照 `envelope.md` §6 台账下方的三条「够格成码」判据。它是付费系列这次变更中**唯一**可能破坏「失败 `code` 零新增」的地方。
3. **对侧待落笔的 2 条（🟠，不阻塞本库任何一份）** —— 客户端库 `open-questions/cross-boundary.md`「待承接」两条（`ADR-0051` · `ADR-0052`）已登记但未落笔。第五波落笔前催一次为宜。→ 对侧 `/analyze-new-ideas game`。**本技能只报告、不写对侧。**
4. **`operations/version-matrix.md` 的取值** —— `appVersion` 下界 · `schemaVersion` **两行**的「接受起始」· `2` 行的下线计划。**不阻断 derive**（形态可断言、边界不可断言），首个在架版本产生时即可填。
5. **🟠 `06` 两条待实测取值** —— 成本模型（前置 = DAU 预期）· `riskEventBufferRows`。**均不阻断 derive**：形态、旋钮 key 与校准公式已全部落笔。
6. **🟠 `07` 两条相邻真空** —— 告警接收人 / 值班形态 · 客服侧账号查询入口。**均不阻断 derive。**
7. **🟠 `02` 一条外部事实挂账项** —— 实名核验是否另需对接主管部门的实名认证系统。须以真实过审要求核实，**不是设计待答**。同类的还有微信开放平台资质的审批到位时刻——**它现在多了一条下游**：微信渠道开通同时也是第 2 条那个待答的答定期限。
8. **`contracts/envelope.md` · `contracts/_index.md` · `vectors/splitmix64.json` · `vision/` 两份 · 68 份 ADR · 各 `_index.md`** —— **无解锁路径，也不需要**：共有层的 blocked 是结构性的；台账 / 对表产物 / 裁决原则 / 决策记录按定义就不是 derive 对象，**永远判 blocked 不代表有欠账**。

### 本次核实到的台账漂移（非就绪度断言，不阻塞 derive，建议同批处理）

全库主题文档与 `handoffs/` 中的**遗留旧就绪度断言：1 条**（第 2 条；「可 derive / 暂缓 derive / 解锁 derive」在主题文档与 `handoffs/` 零命中——`inbox/archive/` 的 39 份 solution-draft 中普遍出现的 `## 具体形态（可 derive 的落地面）` 是草稿模板的固定小节标题，**不计入**）。

**本次销号：0 条。** 09-11 清单的 1–13 条**逐条复测全部仍在**（第 11 条的适用面本批扩大，见下）；第 14 条（台账无失真）本批复核结论不变，数字全部改写为新值。

**仍在 / 新增的漂移（逐条）：**

1. **仍在（第六次记录）** —— **`ADR-0017` 与 `ADR-0025` 的回链是单向的**：`grep -rn "ADR-0017\|ADR-0025" contracts/` **零命中**，而 `decisions/_index.md` 已把两者记为 Accepted 且影响文档指向 `profile-sync.md`。决策本体已完整落进正文。**不是 derive 卡点**，是簿记漂移。连记六次未动，建议与第 11 条一并处理。
2. **仍在（唯一一条遗留旧就绪度断言）** —— `operations/purchase-ops.md:274` 写下单端点滥用阈值「具体数值与实现**随栈落定**」。栈已于 09-03 落定（`ADR-0021`），该句未跟改；且该阈值**无初值、无旋钮 key、不在任何旋钮表**。**本批相关性上升**：同一个下单端点现在还挂着第 2 条最短解锁路径里的那个待答，两处宜同批收拾。建议改写为「形态同构 push 滥用阈值，取值待实测」并补进旋钮清单。
3. **仍在（同一文件内新旧两说并存）** —— `operations/compliance-ops.md:189` 仍在写撤销留痕「交给**风控事件流**（只追加、有自己的保留期）」，而同文件另两处已按 09-08 裁决写为 `deletion_audit`（`ADR-0057`）。09-08 / 09-09 / 09-11 / 09-12 四批均未回改这一处。
4. **仍在（三处，同源）** —— **三份契约仍以「技术栈未定」作为「停在语义层」的理由**：`purchase.md:5`（**本批被编辑却未顺手改这一句**）· `profile-sync.md:376` · `envelope.md:260`「落点 `operations/`（栈落定后）」。三处的**结论仍成立且是本库纪律**，但**理由句已过期**。建议改写为「本库纪律：契约层只声明语义，实现形态归 `systems/` / `operations/`」。
5. **仍在（标签滞后，两处同源）** —— `operations/content-delivery-ops.md:4` 的 Source 行仍写「…（**A7–A9** · 传播窗口 T 的口径与预算 · CDN 负缓存两条）」，而本文件内已无 A6–A9 任何编号（已迁 `systems/content-delivery.md`）；`open-questions/04-content-delivery.md:10` 同样残留「配 **A7–A9** 三条服务端纪律」。按该标签检索会零命中。
6. **仍在（标签滞后）** —— `operations/version-matrix.md:26` 的 `manifestSchema` 集合行值列仍写「待定」，而同格括号内实际已给出 `{1}`（首发，路径分支 `s1`）且下方 T0/T1/T2 序列已完整。**本批该文件被编辑（加了 `schemaVersion = 2` 行）却未顺手修这一格**，两个子表现在一严一松，读者会误判 `manifestSchema` 未决。
7. **仍在（部分收敛未尽）** —— `operations/_index.md:32` 的收据 TTL 行已压回回链形态并明写「本索引不复述其形态与理由」，但同行仍在正文断言「它与 O6『历史规则集永久保留』是**同形取舍**」这半句结论。彻底做法是连这半句一并移进 `purchase-ops.md` §3c 或 `moderation.md` 的过期方向判据表。
8. **仍在（软指路，四处）** —— 已有实际落点却仍指向分片编号：`contracts/profile-sync.md:206` / `:368` 两处写风控事件「落地形态…归 `02` / `06`」（实际已在 `operations/moderation.md`）· `contracts/auth.md:55` 写「`02` 的三条待答项」与 `:492`「词表与审核口径归 `02`」（`02` 待答已清零）。
9. **仍在（两处）** —— `requirements/_index.md:10` 与 `:54`（U2 依据栏）仍以「后端技术栈未定，无从设计实现形态 / 文件边界不存在」为由把 `/blueprint` 与 `/implement` 排除在后端之外。该理由已于 09-03 失效——**结论可能仍成立**（后端代码尚未开工），但**措辞须改**为「后端尚未开工」。`README.md:37` 这一半已修。
10. **仍在（🟠 README 台账失真）** —— `README.md:34` 仍写「`systems/` 三份服务文档与 `operations/` **九份文档**因此已全部展开」。实为 **10 份**（`operations/_index.md` 台账已正确写成 10 行 ↔ 10 份）⇒ **失真只在 README 一侧**。同段的焦点陈述本身仍正确。
11. **仍在且适用面扩大（🟠 新 ADR 的回链全部是单向的，与第 1 条同源）** —— `grep -rn "ADR-006[1-8]"` 在 `contracts/` `systems/` `operations/` `vision/` **全部零命中**：**八份 ADR（`ADR-0061` ~ `ADR-0068`）没有任何一份在主题文档正文里被回引编号**。本批新增的五份尤其显眼——它们的「影响文档」列共点名 5 份主题文档（`purchase.md` · `profile-sync.md` · `profile-store.md` · `purchase-ops.md` · `version-matrix.md`），而这 5 份本批全部被编辑过，却没有一处写下编号。**决策本体已完整落进各正文**（本次逐处直读核实：`purchase.md` §2 / §3 / §3a / §3c / §6 · `profile-sync.md` §5 的逐条护栏论证 · `profile-store.md` 纪律 5 · `purchase-ops.md` §1a / §5 · `version-matrix.md` 子表），故**不是漏落笔、不是 derive 卡点**，是簿记漂移：从正文读不出「这条已固化为决策」。建议与第 1 条一并补回链（各文档的 `## 决策(-> ADR)` 或就近括注）。
12. **仍在（两处轻微不齐，不影响任何判定）** —— ① `decisions/_index.md` 对 `ADR-0016` 的标题措辞与该文件 H1 不一致（语义同向）；② `handoffs/2026-09-08-risk-ledger-storage-shapes.md` 的 frontmatter `distilled-to` 只列 4 份，比 `handoffs/_index.md` 同行少列 `operations/observability.md` ⇒ 属 frontmatter 漏列，**非漏落笔**。
13. **工程欠账（非漂移，两处陈述一致）** —— `operations/deployment.md` 与 `operations/_index.md` 均写 `contract-spec-check` workflow 与校验脚本**尚未落地**（本次复测确认仓库仍无 `.github/`、无 `scripts/`）。首批**契约面** FR 落笔时会撞上它；**内部面 FR 不受影响**（`ADR-0062`）。
14. **无失真（数字全部改写为新值）** —— `decisions/_index.md` **68 行 ⇔ 68 份 ADR** 逐条一致且**全 Accepted（非 Accepted 者 0 份）**，编号连号无缺；`handoffs/_index.md` **43 行 ⇔ 43 份 handoff**、全部 `distilled`；`inbox/` 顶层为空（只有 `_TEMPLATE.md` / `_index.md` / `archive/`，`archive/` **39 ⇔ 39**）；`answer-logs/` **36 ⇔ 36**；`operations/_index.md` **10 ⇔ 10**；`systems/_index.md` 3 ⇔ 3；`requirements/_index.md` 如实写「当前尚无 FR」并把就绪度权威指回本小节。
15. **新增（🔵 相邻登记缺口，最轻）** —— `operations/purchase-ops.md` §5 新增的两项可观测面（重复购买风控事件的四字段 · 按周计数 gauge、不做逐账号告警）**未在 `operations/observability.md` 留下对位登记**，而该文件本是全库探针发射面的集中处。同理，该风控事件的 `kind` 是否入 `moderation.md` 的十值枚举也未交代。两者**都不是设计未决**（处置已被契约与运维双侧写死），只是登记面未同步；derive 第二波或第六波择一处交代即可。

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

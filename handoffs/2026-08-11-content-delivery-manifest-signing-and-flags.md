# 内容分发：manifest 契约、ES256 签名与 flags 开关通道

- id: 2026-08-11-content-delivery-manifest-signing-and-flags
- date: 2026-08-11
- topic: contracts/content-manifest · operations（CDN 缓存 / 发布回滚 / 密钥）· decisions（两条 ADR 候选）
- status: distilled
- distilled-to: contracts/content-manifest.md, contracts/_index.md, operations/_index.md, decisions/_index.md, open-questions/04-content-delivery.md, answer-logs/log-content-delivery-manifest-and-flags.md

## Intent（distilled）

**一句话：** 内容分发的服务端侧一次答齐——**服务端无状态、内容寻址、发布顺序即提交点**；**ES256 detached 签名 + `keyId` 轮换**；**manifest 全量清单 + 三版本号分工**；`ContentEnabled` 从 overlay 通道**独立出来**，成为只覆盖一个布尔的 **flags 第三层**。

`open-questions/04-content-delivery.md` 的四条待答项是同一份契约的四个切面，全部落在 `contracts/content-manifest.md` 上，因此一并答结。前两条**客户端侧已定案**（2026-07-27，见 `game-design-documents/systems/services/content-service.md`），本库答的是「服务端如何兑现」；后两条两侧此前均未定。

### 1. 增量粒度与失败恢复：服务端无状态，只保证三件事

客户端已把事务模型全部揽在自己一侧（`overlay.staging/` → 全集齐备且逐文件 hash 通过 → 搬入 `overlay/` → 原子 rename `overlay.manifest.json` = 提交点）。因此后端**不设任何有状态的下载会话**——无断点协商、无下载令牌、不记录客户端进度。后端只保证：

1. 每个 overlay 文件有**独立、可单独 GET 的稳定 URL**；
2. **URL 的字节内容不可变**（immutable）；
3. **manifest 与它列出的全部文件在发布上是原子的**——manifest 可被读到时，其列出的文件必须已可下载。发布顺序因此固定为**先推全部 blob、后推 manifest**（manifest 是服务端侧的提交点，与客户端侧的 rename 对称）。

**URL 形态 = 内容寻址：** `/<contentRoot>/blobs/<sha256>`，文件的逻辑路径只出现在 manifest 条目里，不出现在 URL 上。若 URL 用逻辑路径，同一 URL 的字节会随版本变化，CDN 边缘节点在 TTL 内可能返回旧字节 → hash 校验失败 → 3 次退避重传**全部命中同一个陈旧边缘节点** → 整次更新永久失败且无自愈路径。内容寻址让「URL ↔ 字节」成为不变量，边缘可永久缓存，且回滚 / 多版本并存天然免费。

**回滚 = 前滚（roll forward），`contentVersion` 严格单调递增。** 撤回一个坏 overlay 的做法是**发布一个更大的 `contentVersion`，其内容指回旧 blob**（blob 都还在，只需新写一份 manifest）。允许版本号回退会给客户端引入「降级」分支，并破坏 `StartContentVersion` / `LastContentVersion` 的单调判据。

**字节级断点续传：不做，但不禁止。** CDN 通常默认支持 HTTP Range，属免费能力——**不写进契约、客户端也不依赖**；契约只要求整文件 GET 成立。

### 2. 防篡改：ES256 detached 签名 + `keyId`，签原始字节不签 JSON 语义

**签名对 manifest 的原始字节做，不对「解析后再规范化的 JSON」做。** 若签名字段内嵌在被签的 JSON 里，验签方必须剔除该字段再规范化重序列化（键序、空白、数字格式、Unicode 转义），任何一处两侧不一致就是**发生在玩家设备上、无法复现的随机验签失败**。故采用 **detached 签名**：manifest 原始字节与签名信封 `{alg, keyId, sig}` 分开取；客户端**先按字节验签，通过后才解析 JSON**。

- **算法：ECDSA P-256 + SHA-256（`ES256`）。** 决定性理由是客户端侧可用性——`System.Security.Cryptography.ECDsa` 在 .NET 内置，Godot / C# 侧**零第三方依赖、零额外包体**。
- **文件 hash：SHA-256**，manifest 内以小写 hex 记录。
- **密钥轮换：`keyId` 从第一天就在信封里。** 客户端内置**一组** `keyId → publicKey` 映射而非一把；轮换时先发内置新旧两把的客户端版本，覆盖率足够后服务端再切私钥。没有 `keyId`，轮换只能靠强更——这是签名方案里最常见、且事后无法补救的遗漏。
- **不引入证书链 / PKI。** 威胁模型只到「防误 / 防随手改」（客户端侧已明确不承诺防作弊），固定公钥即足够，CA 链是纯负债。
- **防回放旧 manifest：** 客户端**拒绝 `contentVersion` 小于本地已生效版本的 manifest**（与单调递增一致）。**不做基于绝对时间的 TTL**——设备时钟不可信，会误伤离线玩家。
- **flags 走同一密钥体系**（同 `keyId` 空间、同 detached 形态），不另立一套。

### 3. `manifest.json` schema 与版本化

字段语义见 `contracts/content-manifest.md`。承重的几条：

- **`files` 是全量清单，不是增量清单。** 客户端通过「本地 manifest 与云端 manifest 逐文件 hash 比对」自行推出待下集；服务端下发差量会把「差量基线是哪一版」变成有状态协商，与客户端事务模型冲突，且无法表达「文件被移除」。全量清单下，**不在清单里 = 应从 `overlay/` 删除**（回退到 `res://` 基线值）。
- **blob URL 不写进 manifest 条目**，由 `<contentRoot>/blobs/<hash>` 拼出；`contentRoot` 随信封 / 配置下发，使 CDN 域名可切换而不需重签历史 manifest（也为多区域托管留出自由度）。
- **`ContentEnabled` 不在 manifest 里**——它是 `.tres` 条目内的字段（随文件走），线上覆盖走 flags 通道。
- **`manifestSchema` 只在破坏性变更时 +1**；向后兼容的加字段不提升版本，契约明写「**客户端必须忽略未知字段**」。破坏性变更时服务端同时保留 N-1 与 N 两版端点一段时间。
- **三版本号分工**（同时答结 `content-service.md` 中的同名待决问题）：`appVersion` 承载客户端二进制、`manifestSchema` 承载 manifest 结构、`contentVersion` 承载 overlay 内容。**`manifestSchema` 不支持时降级到基线，而非强更**——客户端已定「断网降级：跳过更新，直接使用基线」，既然网络完全不可用都能开局，「manifest 读不懂」不该比断网更严厉。强更是 `appVersion` 维度的决定，走 `envelope`，不由内容分发通道兼职。

### 4. `ContentEnabled` 下发通道：独立 flags 通道，作为合并的第三层

客户端的 overlay 合并与 `LoadAll()` 校验发生在**启动链第一步**。沿用 overlay 通道时，关掉一个条目的实际生效点是玩家的**下一次冷启动**——满足 pillar #5 的「不需要发版」，但不满足其字面上的「秒关」，且 `.tres` 里的布尔对全体玩家同值，灰度 / 分批放量无处安放。**故采用独立通道。**

新增一个轻量端点，下发**已按当前账号解析完毕**的开关覆盖集，客户端把它作为**合并的第三层，只影响抽取池**：

```
res://基线  <  user://overlay/  <  flags（仅覆盖 ContentEnabled，不改任何数值）
```

**它与客户端已定的那条不对称设计严丝合缝**：`ContentEnabled` 唯一作用点是产出侧 `AllEnabled()` 取池，读取侧 `Get(id)` 本就不过滤。因此这一层不改任何数值 → 不触碰「合并后强校验」的任何输入；不新增 / 不删除 `Id` → 落在「热更只改不增」纪律内；存档解析不受影响 → 「存档引用未知内容」风险依然为零。**它之所以能秒，恰恰因为它被限制得足够窄。**

**硬边界（不可放宽）：flags 只能覆盖 `ContentEnabled` 这一个布尔，不得携带任何数值 / 文案 / 新 `Id`。** 一旦放宽，上述三条纪律立即失效。

顺带定下两件事：

1. **灰度 / 分批放量的落点 = 服务端。** 分桶规则（百分比 / 白名单 / 篇章档位）**留在服务端**，端点按账号计算后下发**结果**——客户端始终只看到「这些 `Id` 现在不进抽取池」，永远不知道分桶规则存在。这使 `content-service.md` 的「分桶信息放哪」有了答案：**哪也不放在客户端**；`DrawPool<T>` 的构造签名因此**不必**变成 `AllEnabled(bucketContext)`。
2. **刷新时机 = 搭车信封，零轮询。** flags 随**任意应答的信封**搭载一个 `flagsVersion`，客户端发现版本变化时才去拉全量 flags。秒关的实际延迟 = 该玩家的下一次事件推进上行（客户端已定「每个 AdventureEvent 后一次上行」），**分钟级以内**。

**`enabledIds`：保留字段，初期恒空。** 反向打开一个被基线关掉的条目，要求它的数值已随包发布且正确，风险与「关」不对称，不宜走同一条快通道。字段先立在 schema 里，避免日后启用时提升 `flagsSchema`。

## Clarifications（interview 产物）

| 问题 | 用户裁决 | 相对原始输入的改动 |
|---|---|---|
| flags 报文里的 `contentVersion` 语义（草稿列出了字段但未写作用） | **仅信息性，客户端不据此判断**——与 manifest 的 `generatedAt` 同性质，只用于运维排查与日志关联 | 补齐草稿缺失的字段语义。**并明确排除**「客户端须校验 flags 与本地 overlay 版本一致」这一解读：那会让秒关对尚未更新 overlay 的玩家失效，与 pillar #5 相抵；且 flags 只携带 `Id`、不依赖 overlay 内容 |
| `minAppVersion`（string）与 `appVersion` 的比较规则要不要本次定死 | **定为 semver 三段数值比较**（`MAJOR.MINOR.PATCH`，逐段按整数比较，不做字典序，不含预发布后缀） | 草稿只给了类型未给比较规则。字典序会判 `1.10.0 < 1.9.0`，且这类 bug 发版后才显形、无法在设备上复现。比较规则属**语义**，不必等 `01`；`01` 定稿只可能改字段名 |

**先于本次的用户裁决（记录在草稿中，2026-08-11）：** `ContentEnabled` 下发通道 = 独立 flags 第三层 · 签名算法 = ES256 · `enabledIds` 保留恒空。

## 自行推演（未询问，附依据）

- **`manifestSchema` 不受支持时「跳过更新用基线」是对客户端既有表述的必要细化。** `content-service.md` 写「`manifestSchema` 不匹配 → 整包全量重下」，未区分「客户端读得懂但版本不同」与「客户端根本不支持」。后者做全量重下没有意义（下回来也解析不了）。因此拆为两支：**支持但不同 → 全量重下**（保留客户端原意）、**不支持 → 跳过更新用基线**。这属客户端侧的措辞细化，列入跨库待办。
- **发布流程中 `.sig` 先于 manifest 可见**（或两者同一次原子切换），避免读到无签名的 manifest。由「manifest 是提交点」直接推出。

## 后果

- **新建 `contracts/content-manifest.md`**，覆盖范围为「manifest + blob + flags」三者。其中错误码映射与版本协商需与 `contracts/envelope.md` 同批定稿，不在该文件里另立一套错误码。
- **`envelope.md` 新增一项**：信封须携带 `flagsVersion`（与 `contentVersion` / `appVersion` / `revision` 并列）——这是 flags 零轮询刷新的承重字段。
- **`operations/` 的第一批内容有了具体对象**：两类对象两种缓存 TTL、内容发布与回滚流程、flags 数据源与灰度分桶的运营面、签名私钥的保管与轮换。
- **签名密钥管理进入运维范围**，反向约束 `06-platform-stack.md` 的托管选型（需 KMS / 密钥托管 + CI 内的签名步骤）。
- **ADR 候选两条**（登记在 `decisions/_index.md`，未写正文）：①「内容寻址 + `contentVersion` 严格单调递增（回滚即前滚）」；②「flags 第三层只覆盖 `ContentEnabled`」。
- **不影响存档 schema**：flags 是运行时态，不入存档；`StartContentVersion` / `LastContentVersion` 语义不变。

## 客户端侧影响

**是。** 定案 1/2/3 落在客户端已定案的形态内（`files[].size` 是新信息，但它服务的磁盘预检本就是客户端已定的三类失败之一）；**定案 4 需要客户端改动**。`game-design-documents/` 需另写一份 handoff，至少定案四点：

1. **改写 `systems/services/content-service.md` 的「存储形态：三层（已定案）」小节** —— 原模型是「`res://` 基线 + `user://overlay/` 两层数据 + 内存合并」，flags 引入第三个覆盖来源，「overlay 是唯一热更层」不再成立。须改写为三层覆盖来源，并写明 flags 只覆盖 `ContentEnabled`。
2. 第三层如何参与 `AllEnabled()` 取池（合并时机：启动时 + 收到新 `flagsVersion` 时热应用）。
3. `flagsVersion` 在信封 / 同步应答中的读取点与触发拉取的时机。
4. **flags 是否落地本地缓存以支撑离线开局** —— 若不缓存，断网启动时抽取池会回到 overlay 的 `ContentEnabled` 值（即「被秒关的条目在离线时复活」）。**这是本定案唯一未闭合的语义缺口，归客户端侧裁决。**
5. `manifestSchema` **不受支持**时跳过更新用基线（见「自行推演」）——客户端现有表述只写了「不匹配 → 全量重下」。

同时，客户端侧两条待决问题可随该 handoff 一并答结：「`ContentEnabled` 粒度是否够用」（答：分桶留服务端，客户端仍只见布尔）与「`manifestSchema` 的版本化」（答：见三版本号分工表）。

## 与既有决策的张力

**一处，已由用户裁决接受松动（2026-08-11）：** flags 第三层使客户端 `content-service.md` 的「overlay 是唯一热更层」不再成立。

- **接受理由：** overlay 通道下「秒关」的真实延迟是玩家下次冷启动；`vision/pillars.md` #5 明确把线上可干预排在可复现性之上。
- **代价：** 客户端多一个覆盖层与一条刷新路径；契约多一个端点；心智模型从「热更全部经由 overlay」拆成「数值走 overlay / 开关走 flags」两条。
- **限定条款（使代价可控）：** flags **只能覆盖 `ContentEnabled` 这一个布尔**。有此限制，「合并后强校验」「只改不增」「存档必可解析」三条纪律全部原样成立——flags 层根本不参与校验的输入。

其余三条定案与既有决策**无冲突**：都是在客户端已定案的形态内补齐服务端侧的兑现方式。

## Open questions

- ~~字段名与序列化形态未定稿~~ —— **已答结**（2026-08-11，`handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md` → `contracts/envelope.md`）：表达形式 = OpenAPI 3.1 单点，字段名就地转正；`/content/flags` 随之回改为 `/v1/content/flags`。
- **`minAppVersion` 与强更闸门的分工**（`01-contracts.md`）。本定案把强更推给 `envelope`，两者边界需与 `01` 一并确认；`flagsVersion` 进信封亦需在 `01` 落笔。
- **CDN / 托管选型**（`06-platform-stack.md`）。内容寻址 + 两类缓存策略是对 CDN 的能力要求（主流 CDN 均满足），但选型未定前无法写 `operations/`；ES256 私钥的保管方式同样取决于托管形态。
- **多区域一致性**（`02-account-compliance.md`）。若国内渠道要求内容分发也在境内，`contentRoot` 需按区域下发（已把 `contentRoot` 排除在被签名的 manifest 之外正是为留出这个自由度），但多区域间 `contentVersion` 是否必须同步推进，未定。
- **flags 数据源与分桶规则的运营形态**（新增，落 `operations/`）：分桶规则存在哪、由谁改、改动是否需要审计留痕、`GET /v1/content/flags` 的按账号计算是否需要缓存层。
- **flags 是否落地本地缓存以支撑离线开局** —— 归客户端侧裁决（见「客户端侧影响」），本库不代为决定。

## Notes / triage

- 来源：`inbox/archive/solution-draft-content-delivery-manifest-and-flags.md`（`/provide-solution-draft` 产出，用户已评审并裁决三处取向）。
- 答结 `open-questions/04-content-delivery.md` 的全部四条 → `answer-logs/log-content-delivery-manifest-and-flags.md`。
- 已考虑并否决的备选（整包版本粒度、服务端下发差量清单、字节级断点续传 / 下载会话令牌、签名内嵌 JSON 需规范化、RSA-2048、Ed25519、证书链 / PKI、允许 `contentVersion` 回退、绝对时间 TTL 防回放、`ContentEnabled` 沿用 overlay 通道、flags 长连接推送）逐条理由见归档草稿。

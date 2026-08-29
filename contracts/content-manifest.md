# content-manifest —— 内容分发契约（manifest · blob · flags）

> 覆盖 `content-service` 边界的全部报文：overlay 的 **manifest**、内容文件 **blob**、以及 `ContentEnabled` 的 **flags** 通道。**剧本文本亦走本通道**（见下方「剧本文本」一节）。
> 客户端侧门面见 `game-design-documents/systems/services/content-service.md`（那里描述**客户端怎么用**；此处描述**报文长什么样**）。
> Source: `handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md` · `handoffs/2026-08-23b-flags-version-monotonic.md`（服务端保证重构为两组 + flags 三条单调条款）。

> 序列化与命名约定（lowerCamelCase · RFC 3339 UTC · 忽略未知字段）、端点风格与错误码分层归 `envelope.md`，本文件不另立一套、也不复述。

## 意图

服务端**无状态**地兑现客户端已定的文件级事务模型：客户端自行比对推出待下集、逐文件校验、原子提交；服务端只保证 URL 稳定、字节不可变、发布原子。在此之上叠一条**只覆盖 `ContentEnabled` 的 flags 通道**，把线上秒关与灰度从 overlay 的冷启动延迟中解放出来。

## 端点

| 端点 | 域 | 方法 | 应答 | 缓存 | 签名 |
|---|---|---|---|---|---|
| `<contentRoot>/manifest` | CDN · 无鉴权 | GET | manifest.json **原始字节** | `no-cache` 或极短 TTL（秒级） | ES256 detached，见 `.sig` |
| `<contentRoot>/manifest.sig` | CDN · 无鉴权 | GET | `{alg, keyId, sig}` | 同 manifest | — |
| `<contentRoot>/blobs/<sha256>` | CDN · 无鉴权 | GET | 文件字节 | `public, max-age=31536000, immutable` | 由 manifest 内的 hash 覆盖 |
| `/v1/content/flags` | **API · 需鉴权** | GET | flags JSON + detached 签名 | `no-cache` | 同一密钥体系 |

- **manifest 端点的 TTL 决定秒关 / 回滚的实际生效速度**，故只能 no-cache 或秒级。
- **flags 归 API 域，不在 `contentRoot` 下**（见 `envelope.md` §3）：它需鉴权、按账号计算、`no-cache`——本质是 API 而非静态对象。放在 CDN 域会诱导中间层按静态对象缓存，导致**灰度分桶串号**，这类事故只在放量时显形且极难定位。
- **blob URL 是内容寻址**：`<contentRoot>/blobs/<hash>`，逻辑路径只出现在 manifest 条目里。`contentRoot` **随信封 / 配置下发，不写进被签名的 manifest**——使 CDN 域名可切换而无需重签历史 manifest，并为多区域托管留出自由度。

## 服务端保证

**本节是服务端义务的完整清单**，分两组——两组各自封闭，不互相溢出。

### A 组 · overlay 分发（CDN 域静态对象 · 四条，仅此四条）

1. **每个 overlay 文件有独立、可单独 GET 的稳定 URL。**
2. **URL 的字节内容不可变**（内容寻址的直接推论）。
3. **manifest 与它列出的全部文件在发布上是原子的**——manifest 可被读到时，其列出的文件必须已可下载。发布顺序因此固定为**先推全部 blob、后推 manifest**；manifest 是服务端侧的提交点，与客户端侧 `overlay.manifest.json` 的 rename 对称。
4. **`contentVersion` 严格单调递增，不允许回退。回滚 = 前滚**：发布一个更大的 `contentVersion`，其内容指回旧 blob——**内容寻址让这一步零成本**。允许回退会给客户端引入「降级」分支，并破坏 `StartContentVersion` / `LastContentVersion` 的单调判据。→ ADR 候选①。

**A 组不提供的**：断点协商、下载令牌、客户端进度记录、差量清单——任何一项都会把无状态拉取变成有状态协商，与客户端的事务模型冲突。**字节级 Range 不写进契约、客户端也不依赖**（CDN 若默认支持属免费能力）。**这句否定的边界只覆盖 A 组**，与 B 组的 API 域无关。

### B 组 · flags 通道（API 域，按账号计算）

flags 不是内容寻址的静态对象，故 A 组的保证对它不成立，须单列。三条：

5. **`flagsVersion` 取自单一全局单调序列。** 任意应答携带的 `X-Flags-Version`、以及 `GET /v1/content/flags` 应答体内的 `flagsVersion`，取自同一个序列——**它不按区域、不按实例、不按账号分别计数**。这不是修辞：`X-Flags-Version` 搭任意应答的车，设备在一次会话内会从多个实例（可能是多个区域）读到它，按区域 / 按实例计数当场违反本条。号**只由发布动作分配**，草稿态编辑不占号（否则版本号被未发布的编辑抖动推高，审计读起来全是空洞）。
6. **严格单调递增，不允许回退。回滚 = 前滚**：撤销一批误关没有「把版本号退回上一批」这个动作，而是以被回指批次的规则内容为源，发布一个**更大**的 `flagsVersion`。flags 是**全量快照**（`disabledIds` 是结果的全集，不是增量），故前滚与首次发布走完全相同的一条路径，成本为零。**这条的零成本理由与 A 组第 4 条不同源**（那条靠内容寻址，本条靠全量快照）。
7. **同一 `(flagsVersion, 账号)` 的解析结果恒定。** 对固定的账号，同一 `flagsVersion` 必须始终解析出相同的 `disabledIds`；**任何会改变解析结果的改动（规则增删、分桶比例调整、白名单增删、分桶盐值变更）都必须提升 `flagsVersion`**。分桶函数须是 `(accountId, 规则集版本)` 的**纯函数**，不得依赖实例本地随机、当前时间或请求属性。

**第 7 条不可省，它不是第 6 条的重复。** 客户端「等值不拉」——这条纪律使**内容变了而版本没变**成为一个静默失效模式，其危害不亚于版本回退，且更难定位。A 组第 4 条不需要这半句，因为 manifest 是静态对象、内容寻址天然保证同版本同字节；flags 是**按账号计算的结果**，没有这层保护。

**两种破坏方式的线上症状相同：** 允许版本回退，会让已观测到更高版本的设备**在当前会话内此后不再拉取 flags**；允许同版本内容漂移，会让改动对已在线设备**永不生效**、只对新会话生效。两者都表现为「秒关不生效 / 误关的内容不恢复」，且只有客户端一条本地告警 + 一次上报作为线索。客户端侧的观测规则、降级与爆炸半径闸见 `game-design-documents/systems/services/content-service.md`「flags：`ContentEnabled` 的第三层」。

**三个现实的失效来源，逐个堵：**

| 来源 | 破坏形态 | 本节如何堵 |
|---|---|---|
| **数据库回滚 / 备份恢复** | 版本计数器倒退，已用过的号被重新分配（更糟：同号承载不同规则） | 分配点持久化一条**单调高水位**，且高水位与规则集存储在**同一事务边界**内（避免只恢复其一）。恢复后取 `max(恢复值, 高水位)` 并**强制跳号**；「版本号未倒退」列为恢复演练的必检项（`operations/`） |
| **多区域发布传播时延** | 区域 A 已到 42，区域 B 仍在 41；设备跨区路由即观测到更小值 | 保证 5 钉死单一全局序列，区域差异降格为**传播时延**而非独立计数。再加一条运维 SLO：**新批次须在窗口 T 内在全部区域可见**。窗口内客户端观测到更小版本是**已知良性态**（它不拉、告警、按会话去重上报一次，保留当前那批 flags）。**T 的数值待「多区域内容分发的一致性」答定**（`open-questions/04-content-delivery.md`） |
| **手工改规则**（直接改存储 / 控制台绕过发布动作） | 内容变了、版本号没变 ⇒ 已在线设备「等值不拉」改动永不生效，新会话设备拿到新结果 ⇒ **两批设备行为分裂，且没有任何一侧报错** | **规则集不可变**：没有原地编辑路径，任何改动只能产出一个新版本（形态见 `operations/_index.md`）。可选加固：把规则集内容指纹与版本号绑定，服务端自检到「同版本不同指纹」即告警——**指纹不下发给客户端**（ADR-0002 的载荷边界） |

**单调递增只堵住回退，堵不住原地改**，而按账号计算的 flags 恰恰给了原地改一条极自然的路径——这是第 7 条与「规则集不可变」必须成对存在的理由。

**若引入按账号的解析结果缓存层，缓存键必须包含 `flagsVersion`**，且缓存条目**不得跨版本复用**、不得在版本提升后继续被读到。缓存键只按 `accountId` 时，版本提升后设备拉到的仍是旧结果——但版本号已经增大 ⇒ 客户端认为「已同步到最新」⇒ 此后「等值不拉」⇒ **这一批秒关对该账号永不生效**。这与「手工改规则」同一病理，只是发生在缓存层。**是否引入缓存层本身不在此裁决**（`open-questions/04-content-delivery.md`）。

**B 组零报文成本**：不新增任何字段、`flagsSchema` 不提升、客户端无需任何改动。→ ADR 候选④。

## manifest schema（`manifestSchema: 1`）

| 字段 | 类型 | 语义 | 客户端对位 |
|---|---|---|---|
| `manifestSchema` | `int` | manifest 结构自身的版本 | `manifestSchema` |
| `contentVersion` | `int` | 内容版本，**严格单调递增**；存档与 push 信封均携带 | `ContentVersion` / `StartContentVersion` / `LastContentVersion` |
| `generatedAt` | `string`（RFC 3339, UTC） | 发布时间，用于运维排查与日志关联；**不参与客户端逻辑判断** | — |
| `minAppVersion` | `string`（`MAJOR.MINOR.PATCH`） | 应用此 overlay 所需的最低客户端版本；低于它的客户端**跳过更新、照常用基线**（不是强更闸门） | 与 `appVersion` 比对 |
| `files` | `array` | 文件条目**全量清单** | 逐文件下载集 |
| `files[].path` | `string` | 相对 `user://overlay/` 的逻辑路径，如 `content/cards/card_x.tres`。**禁止 `..` 与绝对路径** | staging → overlay 的落地路径 |
| `files[].hash` | `string` | SHA-256 小写 hex | 逐文件校验 + 比对待下集 |
| `files[].size` | `int`（bytes） | **下载前的磁盘空间预检**——使「磁盘空间」这类失败能提前判定，而非写到一半才失败 | `OpError` 磁盘分支 |

```json
{
  "manifestSchema": 1,
  "contentVersion": 137,
  "generatedAt": "2026-08-11T04:12:00Z",
  "minAppVersion": "1.2.0",
  "files": [
    { "path": "content/cards/card_x.tres", "hash": "9f2b…", "size": 2048 }
  ]
}
```

**承重语义：**

- **`files` 是全量清单，不是增量清单。** 客户端通过「本地 manifest 与云端 manifest 逐文件 hash 比对」自行推出待下集。**不在清单里 = 应从 `overlay/` 删除**（回退到 `res://` 基线值）——差量清单无法表达这件事。
- **`files[].path` 的路径穿越是唯一有实质危害的注入面**，客户端落盘前须校验。
- **`ContentEnabled` 不在 manifest 里**——它是 `.tres` 条目内的字段（随文件走），其线上覆盖走 flags 通道。
- **`minAppVersion` 比较规则 = semver 三段数值比较**：`MAJOR.MINOR.PATCH` 逐段按**整数**比较，不做字典序，不含预发布后缀。（字典序会判 `1.10.0 < 1.9.0`，且这类 bug 发版后才显形、无法在设备上复现。）

## 版本化：三个版本号的分工

| | 承载 | 谁提升 | 不匹配时 |
|---|---|---|---|
| `appVersion` | 客户端二进制（含基线内容、内置公钥、支持的 `manifestSchema` 集合） | 发版 | 过旧 → 由 `envelope.md` 的版本协商裁决（软提示 / 硬闸门） |
| `manifestSchema` | manifest 的**结构** | 后端契约演进 | 客户端**不支持** → 跳过更新、用基线（**不阻塞开局、不强更**）；客户端**支持但与本地不同** → 整包全量重下 |
| `contentVersion` | overlay 的**内容** | 每次内容发布 | 与本地不同（且更大）→ 增量更新 |

- **`manifestSchema` 只在破坏性变更时 +1。** 向后兼容的加字段（新增可选字段）**不**提升版本；**客户端必须忽略未知字段**（契约条款）。
- 破坏性变更时，服务端**同时保留 N-1 与 N 两版 manifest 端点**一段时间（按 `appVersion` 或显式 `?manifestSchema=` 分流），使老客户端不被立即打断。
- **`manifestSchema` 不支持时降级到基线，而非强更。** 客户端已定「断网降级：跳过更新，直接使用基线」；网络完全不可用都能开局，「manifest 读不懂」不该比断网更严厉。强更是 `appVersion` 维度的决定，走 `envelope.md`，不由内容分发通道兼职。
- **`contentVersion` 严格单调递增、回滚即前滚**——条款本体见「服务端保证」A 组第 4 条（两条单调纪律并列在那一节，那是后端实现者唯一会当成义务清单读的地方）。

## 防篡改：ES256 detached 签名

**签名对 manifest 的原始字节做，不对「解析后再规范化的 JSON」做。** 内嵌签名要求验签方剔除签名字段后**规范化重序列化**（键序、空白、数字格式、Unicode 转义），任何一处两侧不一致就是发生在玩家设备上、**无法复现**的随机验签失败。故用 detached：

```json
{ "alg": "ES256", "keyId": "content-2026a", "sig": "<base64>" }
```

客户端流程：取 manifest **原始字节** → 按 `keyId` 选内置公钥 → 验签 → **通过后才解析 JSON**。

| 项 | 定案 |
|---|---|
| 签名算法 | **ES256**（ECDSA P-256 + SHA-256）。理由是客户端可用性：`System.Security.Cryptography.ECDsa` 在 .NET 内置，Godot / C# 侧零第三方依赖、零额外包体 |
| 文件 hash | **SHA-256**，小写 hex |
| 密钥轮换 | **`keyId` 从第一天就在信封里。** 客户端内置**一组** `keyId → publicKey` 映射；轮换时先发内置新旧两把的客户端版本，覆盖率足够后服务端再切私钥。无 `keyId` 则轮换只能靠强更，且事后无法补救 |
| 信任根 | **固定公钥（pinned），不引入证书链 / PKI。** 威胁模型只到「防误 / 防随手改」——客户端侧已明确不承诺防作弊 |
| 防回放 | 客户端**拒绝 `contentVersion` 小于本地已生效版本的 manifest**。**不做绝对时间 TTL**——设备时钟不可信，会误伤离线玩家 |
| flags | **走同一密钥体系**（同 `keyId` 空间、同 detached 形态），不另立一套 |

验签失败 / `keyId` 未知 → 客户端 `PushError` + 拒绝该 overlay + 回退 `res://` 基线 + 上报一次事件（客户端侧已定）。

## flags 通道：`ContentEnabled` 的第三层

```
res://基线  <  user://overlay/  <  flags（仅覆盖 ContentEnabled，不改任何数值）
```

```json
{
  "flagsSchema": 1,
  "flagsVersion": 41,
  "contentVersion": 137,
  "disabledIds": ["card_x"],
  "enabledIds": []
}
```

| 字段 | 语义 |
|---|---|
| `flagsSchema` | flags 结构自身的版本，演进规则同 `manifestSchema` |
| `flagsVersion` | 本批开关的版本，**严格单调递增且同版本结果恒定**（条款见「服务端保证」B 组）；由信封搭载给客户端做变更检测 |
| `contentVersion` | **仅信息性**：标注这批 flags 是针对哪个内容版本生成的，用于运维排查与日志关联。**客户端不据此判断**——不校验它与本地 overlay 版本是否一致 |
| `disabledIds` | 应从抽取池中移除的内容 `Id` 集合（**已按当前账号解析完毕的结果**） |
| `enabledIds` | **保留字段，初期恒空**（见下） |

**为什么独立于 overlay：** 客户端的 overlay 合并与 `LoadAll()` 校验在**启动链第一步**，沿用 overlay 通道时「秒关」的真实生效点是玩家**下一次冷启动**；且 `.tres` 里的布尔对全体玩家同值，灰度 / 分批放量无处安放。

**为什么这一层安全：** `ContentEnabled` 唯一的作用点是**产出侧 `AllEnabled()` 取池**，读取侧 `Get(id)` 本就不过滤。因此 flags 层：

- **不改任何数值** → 不触碰「合并后强校验」（`Id` 唯一性、交叉引用）的任何输入，校验模型原样成立；
- **不新增 / 不删除 `Id`** → 完全落在「热更只改不增」纪律内；
- **存档解析不受影响** → 「存档引用未知内容」的风险依然为零。

故它**可在轮回进行中安全热应用**（下一次抽取即生效），而数值型 overlay 无此性质。**它之所以能秒，恰恰因为它被限制得足够窄。**

> **硬边界（不可放宽）：flags 只能覆盖 `ContentEnabled` 这一个布尔，不得携带任何数值 / 文案 / 新 `Id`。** 一旦放宽，上述三条纪律立即失效。→ ADR 候选②。

**灰度分桶留在服务端。** 分桶规则（百分比 / 白名单 / 篇章档位）**不下发**；端点按账号计算后只给**结果**。客户端始终只看到「这些 `Id` 现在不进抽取池」，永远不知道分桶规则存在——因此 `game-design-documents/systems/services/content-service.md` 的「分桶信息放哪」的答案是**哪也不放在客户端**，`DrawPool<T>` 的构造签名不必变成 `AllEnabled(bucketContext)` 一类。

**刷新时机 = 搭车信封，零轮询。** `flagsVersion` 随**任意应答的 `X-Flags-Version` 头**下发（`envelope.md` §4b——放在头上而非 body，才能覆盖 `204`、错误应答与非 JSON 应答），客户端发现版本变化时才拉全量 flags。秒关的实际延迟 = 该玩家的下一次事件推进上行，**分钟级以内**。不引入长连接 / 第三方推送。

**`enabledIds` 初期恒空。** 反向打开一个被基线关掉的条目，要求它的数值已随包发布且正确，风险与「关」不对称，不宜走同一条快通道。字段先立在 schema 里，避免日后启用时提升 `flagsSchema`。

## 剧本文本：一类普通内容文件

> Source: `handoffs/2026-08-11-plot-service-retired.md` · `handoffs/2026-08-16d-plot-content-shape-adoption.md`（客户端侧决策见 `game-design-documents/handoffs/2026-08-11-plot-content-localization.md` 与 `.../2026-08-16i-plot-data-encoding.md`）。

剧本内容自 2026-08-11 起是**客户端本地内容层的一员**，不再有云端剧本服务、不再有剧本端点。它以 `.tres` 内容文件的形态出现在 `files[]` 中，与卡牌 / 事件 / 敌人条目**在报文层完全同形**——服务端不区分内容类别，上述三条服务端保证原样覆盖它。**契约层为此无需任何新增字段。**

两条承重的推论：

- **「overlay 可对剧本新增 `Id`」是客户端侧的合并纪律，不是契约条款。** manifest 本就是全量文件清单，新增文件是它天然支持的形态；「哪类内容允许新增 `Id`」由客户端合并后的强校验裁决，**服务端不感知、不校验、不需要标注文件的内容类别**。
- **flags 通道对剧本条目的作用面按 arc / node 分野，报文层无差别。** 客户端把剧本内容分成**剧本线的头**（`PlotArcData`，被激活抽取 ⇒ 产出侧）与**树上的节点**（`PlotNodeData`，由 key point 查表定位 ⇒ 结构性读取）：
  - **arc 的 `Id` 放进 `disabledIds` 生效**——它使该 arc **不再被新激活**；已在 `CharacterProfile` key point 里的 arc 照常解析（客户端读取侧不过滤），**不会因此悬空**。这使一条 overlay 热更推上去的问题剧本线有**分钟级**的止血手段。
  - **node 的 `Id` 放进 `disabledIds` 无效且危险**——客户端对被关闭的节点直接 `PushError`（关掉一个中间节点会在剧本树上造出空洞、让正在进行的 arc 卡死）。
  - **服务端不感知这一分野**：`disabledIds` 只是一串 `Id`，语义与准入由客户端裁决。归属与校验形态见 `game-design-documents/systems/services/plot-manager.md` 与 `.../content-service.md`。

**运营后果需明写：** **撤回一整段已发布剧情**（让它连同文件一起消失）仍只能靠发布更大的 `contentVersion`，速度是 **overlay 的冷启动级**；flags 能做的是**停止新激活**，不是撤回。玩家若已在被撤回的剧本 arc 下存过 key point，客户端侧已定的降级规则（悬空 key point → `PushWarning` + 跳过该段叙事 + 轮回照常继续）承接这一情形，**后端无需为此提供任何补偿报文**。

## 与客户端 `OpError` 的映射

> 权威错误码分层与台账归 `envelope.md` §5–6；本表只给内容分发侧的情形 → 客户端处置的对应关系。CDN 侧的三个静态对象**不返回契约错误体**（它们无鉴权、由 CDN 直接服务），客户端按 HTTP 状态码与本地校验结果判定。

| 情形 | 应答 | 客户端 `OpError` | 客户端处置 |
|---|---|---|---|
| 网络不可达 / 超时 / 5xx | — | `Network` | 跳过更新，用现有层开局（已定的断网降级） |
| 验签失败 / hash 不符 / `keyId` 未知 | — | `Validation` | `PushError` + 拒绝 overlay + 回退基线 + 上报一次事件 |
| `manifestSchema` 不受支持 | 200（客户端自行判定） | `Validation`（细分一个**不上报**的子因） | 跳过更新，用基线（**不强更**） |
| `minAppVersion` 高于当前 `appVersion` | 200（客户端自行判定） | — | 跳过更新，用基线；强更与否归 `envelope.md` 的版本协商 |
| 预估落盘空间不足（`files[].size` 求和） | — | 磁盘空间 | 下载前即失败，不产生半套 staging |

## 客户端侧的既定前提（回链，不复述）

本契约建立在 `game-design-documents/systems/services/content-service.md` 已定案的形态上：三层合并（overlay 优先、`res://` 兜底）· 热更只改不增 · 文件级事务（staging → 校验 → 搬入 → 原子 rename 提交）· manifest 验签后拒绝并回退基线 · `ContentEnabled` 的产出侧 / 读取侧不对称 · 不冻结轮回的 `contentVersion`。

## 决策(-> ADR)

- **内容寻址 + `contentVersion` 严格单调递增（回滚即前滚）** → ADR 候选①，登记于 `decisions/_index.md`。
- **flags 第三层只覆盖 `ContentEnabled`** → ADR 候选②（含限定条款，需固化其边界）。
- **flags 规则集不可变版本化 · `flagsVersion` 严格单调 · 同版本结果恒定 · 回滚即前滚** → ADR 候选④，登记于 `decisions/_index.md`。**不并进 ADR 候选①**：那一条的核心论证是「内容寻址让前滚零成本」，对 flags 不成立（flags 不是内容寻址的静态对象），其零成本另有理由（全量快照）；并进去会让一条 ADR 的理由段承载两条不同论证。真正值得固化的是「不可变版本化 + 同版本结果恒定」——ADR 候选②的载荷边界也覆盖不到它，而「临时改个比例」这类运营需求会反复来撬它。

## Open questions

- **多区域一致性**：若内容分发需按区域托管，`contentRoot` 按区域下发已留出自由度，但多区域间 `contentVersion` 是否必须同步推进未定（`02-account-compliance.md`）。
- **flags 数据源与分桶规则的运营形态**（落 `operations/`）：规则存在哪（配置表 / 数据库 / 控制台）、由谁改、按账号计算是否需要缓存层。**审计留痕不在此列**——它的四项最低要求见 `operations/_index.md`；**缓存层若引入，缓存键必须含 `flagsVersion`**（「服务端保证」B 组）。
- **blob 通道是否向二进制资产开放（承接项）：** A 组的内容寻址与 `files[]` 全量清单在报文层对文件类别无任何区分，但**当前实际被消费的只有 `.tres` 内容文件**——贴图 / 音频等二进制资产是否也经本通道下发（进而决定它们能否不发版更新），两库均未表述过，**本契约不代为裁决**。客户端侧的待答项（连同其字段侧的最小口径）见 `game-design-documents/open-questions/deferred-content.md` 与 `game-design-documents/art/visuals/_index.md`。若答为「开放」，须核对的是本文件的 `files[].path` 校验面与「manifest 与其列出文件发布原子」两条对非 `.tres` 文件是否仍逐字成立；若答为「不开放」，则是一条客户端侧的合并纪律，服务端义务清单不变。
- **flags 是否落地客户端本地缓存以支撑离线开局** —— **归客户端侧裁决**，本库不代为决定。若不缓存，断网启动时抽取池会回到 overlay 的 `ContentEnabled` 值（被秒关的条目在离线时复活）。

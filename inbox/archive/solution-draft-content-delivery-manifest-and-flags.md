---
type: solution-draft
date: 2026-08-11
question: 内容分发（CDN）四问：增量粒度与失败恢复的服务端形态、overlay 防篡改的签名方案、`manifest.json` 的 schema 与版本化、`ContentEnabled` 放量 / 秒关开关的下发通道。
source: open-questions/04-content-delivery.md → ④ 内容分发（CDN）
targets:
  - backend-design-documents/contracts/content-manifest.md（新建，`contracts/_index.md` 已登记为计划文档）
  - backend-design-documents/contracts/envelope.md（错误码 / 版本协商的交叉部分，与 01 同批）
  - backend-design-documents/operations/（CDN 缓存策略、内容发布与回滚流程、签名密钥保管与轮换；栈落定后）
  - backend-design-documents/decisions/（「内容寻址 + contentVersion 单调递增」与「flags 第三层只覆盖 ContentEnabled」两条值得各记一条 ADR）
  - 跨库：game-design-documents/systems/services/content-service.md（flags 第三层需客户端侧另写一份 handoff）
status: distilled
decided-on: 2026-08-11
reviewed: 2026-08-11 —— 用户裁决三处取向：下发通道 = flags 第三层 · 签名 = ES256 · `enabledIds` 保留恒空；其余按推荐采纳。提炼时另澄清两项：flags 报文的 `contentVersion` 仅信息性（客户端不据此判断）、`minAppVersion` 比较规则定为 semver 三段数值比较。
distilled-to: backend-design-documents/handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md
---

# 方案定案 — 内容分发：manifest 契约、ES256 签名与 flags 开关通道

> **状态：已由用户裁决定案（2026-08-11）。** 三处取向选择均已选定（下发通道 = flags 第三层 · 签名 = ES256 · `enabledIds` 保留恒空），其余按推荐采纳。本文件已从提案改写为定案陈述，是 `/analyze-new-ideas` 的输入。
>
> **仍非最终契约：** 字段**语义**已定案；**字段名与序列化形态**待 `01-contracts.md` 的契约表达形式定稿后才成为正式契约（见「前置依赖」）。

## 问题

`open-questions/04-content-delivery.md` 的四条待答项，实际是**同一份契约的四个切面**——它们全部落在 `contracts/content-manifest.md` 这一份尚未成文的文档上，因此一并答结：

1. **增量下载的粒度与失败恢复**——逐文件 hash vs 整包版本、断点续传 / 回滚。
2. **overlay 防篡改**——是否需服务端签名及签名方案。
3. **`manifest.json` 的 schema 与版本化**——字段形态、`manifestSchema` 自身的演进路径。
4. **放量与秒关开关的下发通道**——`ContentEnabled` 随 overlay 走全量分发，还是需要独立的、生效更快的配置通道。

前两条**客户端侧已定案**（2026-07-27，见下方约束），本库答的是「服务端如何兑现」；后两条两侧此前均未定，其中第 4 条反向改动客户端机制，已由用户裁决接受。

## 约束（来自既有设计）

**客户端侧已定案（硬前提，本定案不推翻）** — `game-design-documents/systems/services/content-service.md`：

- **三层存储**：`res://content/**.tres`（随包基线，只读）+ `user://overlay/**.tres`（热更层）→ ContentRegistry 内存合并（overlay 优先，`res://` 兜底）。
- **热更只改不增**：overlay **不得新增 `Id`**，只能改既有条目的数值 / 文案 / `ContentEnabled`。新内容只能随版本发布。
- **增量粒度 = 文件级，不做字节级断点续传**；改做**文件级事务**：`overlay.staging/`（可脏）→ 全集齐备且逐文件 hash 校验通过 → 搬入 `overlay/` → **原子写 `overlay.manifest.json`（临时文件 → rename）= 提交点**。失败即清空 staging，上一个完整版本原样保留，本次更新视为未发生。
- **整包全量重下仅两种情形**：首次安装 overlay、`manifestSchema` 不匹配。
- **防篡改路线已定**：后端**私钥签 manifest**，客户端**内置公钥验签**；逐文件完整性由已签名 manifest 内的 hash 承担。校验不过 → `PushError` + 拒绝该 overlay + 回退 `res://` 基线 + 上报一次事件。
- **明确边界**：客户端完整性做到「防误 / 防随手改」为止，**不承诺防作弊**。
- **合并 + 强校验发生在启动链第一步**（`LoadAll()`），`CheckAndUpdateAsync` 的失败分三类：`Network` / `Validation`（hash 或签名不符）/ 磁盘空间。
- **`ContentEnabled` 的不对称**：**产出侧**（抽取池 `AllEnabled()`）过滤，**读取侧**（`Get(id)`）不过滤——因此关闭一个条目只让它不再被新抽到，存档引用它仍能正确解析。
- **不冻结轮回的 `contentVersion`**：overlay 更新在轮回进行中即生效，不承诺跨内容版本可复现。
- `ContentVersion` 在客户端 API 面上的类型是 **`int`**。

**本库约束**：

- `vision/pillars.md` #5「线上可干预」：**改数值 / 关条目不需要发版**，优先于跨版本可复现。
- `vision/pillars.md` #3「契约单点定义」：报文只在 `contracts/` 定义，两侧派生；字段名可与客户端字段名不同，但须显式给出映射。
- `vision/scope.md` 硬约束：移动网络是常态（弱网、响应丢失、后台挂起）。
- `open-questions/06-platform-stack.md`：**技术栈 / 托管 / CDN 选型全未定**——因此本定案停在协议与语义层，不指定语言 / 框架 / CDN 厂商。

## 定案

### 1. 增量粒度与失败恢复：服务端无状态，只保证三件事

`[既有推演]`

客户端已把事务模型全部揽在自己一侧（staging + rename 提交点），后端**不设任何有状态的下载会话**——无断点协商、无下载令牌、不记录客户端进度。后端保证三件事：

1. **每个 overlay 文件有独立、可单独 GET 的稳定 URL**（客户端逐文件下载并逐文件校验 hash 的前提）。
2. **URL 的字节内容不可变**（immutable）——见下一条的内容寻址。
3. **manifest 与它列出的全部文件，在发布上是原子的**：manifest 可被读到时，其列出的所有文件必须已可下载。发布顺序因此固定为**先推全部文件、后推 manifest**（manifest 是服务端侧的提交点，与客户端侧的 `overlay.manifest.json` rename 对称）。

**URL 形态 = 内容寻址：** `/<contentRoot>/blobs/<hash>`（文件的逻辑路径只出现在 manifest 的条目里，不出现在 URL 上）。

`[通行做法]` 理由是**这条直接决定「永不半套 overlay」在有 CDN 的情况下是否还成立**：若 URL 是逻辑路径（`/overlay/cards/card_x.tres`），同一 URL 的字节会随版本变化，CDN 边缘节点在 TTL 内可能返回旧字节，客户端 hash 校验失败 → 3 次退避重传**全部命中同一个陈旧边缘节点** → 整次更新永久失败，玩家卡在旧内容且无自愈路径。内容寻址让「URL ↔ 字节」成为不变量，边缘缓存可设为永久，且**回滚 / 多版本并存天然免费**（旧版本的 blob 从未被覆盖）。

**缓存策略（→ `operations/`）：**

| 对象 | 缓存 |
|---|---|
| `/blobs/<hash>` | `Cache-Control: public, max-age=31536000, immutable`（可永久缓存） |
| manifest 端点 | `no-cache` 或极短 TTL（秒级）；秒关 / 回滚的实际生效速度由它决定 |

**字节级断点续传：不做，但不禁止。** `[既有推演]` 客户端已定「`.tres` 是 KB 级，续传复杂度换不回收益」。CDN 通常默认支持 HTTP Range，**这属于免费能力，不写进契约、客户端也不依赖它**——契约只要求整文件 GET 成立。

**回滚 = 前滚（roll forward），`contentVersion` 严格单调递增。** `[通行做法]` 客户端只比对「云端 `contentVersion` 与本地是否不同」，若允许版本号回退，客户端要处理「降级」这一额外分支（且 `CharacterProfile.StartContentVersion` / `LastContentVersion` 的「跨过更新」判据会失去单调性）。因此**撤回一个坏 overlay 的做法是发布一个更大的 `contentVersion`，其内容指回旧 blob**——内容寻址让这一步零成本（blob 都还在，只是新写一份 manifest）。

### 2. 防篡改：ES256 detached 签名 + `keyId`，签原始字节不签 JSON 语义

`[既有推演]` + `[通行做法]`

**签名对 manifest 的原始字节做，不对「解析后再规范化的 JSON」做。**

`[通行做法]` 这是签名实现里最经典的坑：若签名字段内嵌在被签的 JSON 里，验签方必须先剔除该字段再**规范化重序列化**（键序、空白、数字格式、Unicode 转义），任何一处两侧不一致就是随机失败——而这类失败发生在玩家设备上，无法复现。因此采用 **detached 签名**：

```
GET /content/manifest        → manifest.json 的原始字节（客户端按字节验签，再解析）
GET /content/manifest.sig    → 签名信封（或作为响应头随 manifest 一并返回）
```

签名信封（小 JSON，本身不参与签名）：

```json
{ "alg": "ES256", "keyId": "content-2026a", "sig": "<base64>" }
```

客户端流程：取 `manifest` 原始字节 → 按 `keyId` 选内置公钥 → 验签 → **验签通过后才解析 JSON**。验签失败 / `keyId` 未知 → `PushError` + 拒绝该 overlay + 回退基线（客户端侧已定）。

**算法定案：ECDSA P-256 + SHA-256（`ES256`）。** `[既有推演]` 决定性理由是客户端侧的可用性——它在 .NET 内置（`System.Security.Cryptography.ECDsa`），**Godot / C# 侧零第三方依赖、零额外包体**。（备选 RSA-2048 走 Godot 内置 `Crypto`，与 Ed25519 一并见「备选方案」。）

- **文件 hash：SHA-256**，manifest 内以小写 hex 记录。`[通行做法]`
- **密钥轮换：`keyId` 从第一天就在信封里。** `[通行做法]` 客户端内置**一组**公钥（`keyId → publicKey` 映射）而非一把；轮换时先发一个内置了新旧两把的客户端版本，待其覆盖率足够后服务端再切签名密钥。没有 `keyId` 的话，轮换必须靠强更——这是签名方案里最常见的、且事后无法补救的设计遗漏。
- **不引入证书链 / PKI。** `[既有推演]` 客户端侧已明确「不承诺防作弊」，威胁模型是「防误 / 防随手改」；固定公钥（pinned key）就够，CA 链是纯负债。
- **新鲜度（防回放旧 manifest）：** manifest 携带 `generatedAt` 与 `contentVersion`，客户端**拒绝 `contentVersion` 小于本地已生效版本的 manifest**（与上文单调递增一致）。这能挡住「重放一份旧的合法签名 manifest 把玩家按回旧内容」，且不需要时间同步。**不做基于绝对时间的 TTL**——玩家设备时钟不可信，会误伤离线玩家。
- **flags 走同一密钥体系**（同 `keyId` 空间、同 detached 形态），不另立一套。

### 3. `manifest.json` schema 与版本化

`[既有推演]` + `[通行做法]`

**字段形态**（字段名为契约名，待 `01` 定稿；与客户端字段的映射列在右侧）：

| 字段 | 类型 | 语义 | 客户端对位 |
|---|---|---|---|
| `manifestSchema` | `int` | manifest 结构自身的版本。**不匹配 → 整包全量重下**（客户端侧已定） | `manifestSchema` |
| `contentVersion` | `int` | 内容版本，**严格单调递增**；存档与 push 信封均携带 | `ContentVersion` / `StartContentVersion` / `LastContentVersion` |
| `generatedAt` | `string` (RFC 3339, UTC) | 发布时间，用于运维排查与日志关联；**不参与客户端逻辑判断** | — |
| `minAppVersion` | `string` | 应用此 overlay 所需的最低客户端版本；低于它的客户端**跳过更新、照常用基线**（不是强更闸门，见下） | 与 `appVersion` 比对 |
| `files` | `array` | 文件条目表 | 逐文件下载集 |
| `files[].path` | `string` | 相对 `user://overlay/` 的逻辑路径，如 `content/cards/card_x.tres`。**禁止 `..` 与绝对路径**（客户端落盘前须校验，路径穿越是唯一有实质危害的注入面） | staging → overlay 的落地路径 |
| `files[].hash` | `string` | SHA-256 小写 hex | 逐文件校验 + 比对待下集 |
| `files[].size` | `int` (bytes) | 用于**下载前的磁盘空间预检**——`CheckAndUpdateAsync` 的第三类失败（磁盘空间）需要它才能提前判定，而不是写到一半才失败 | `OpError` 磁盘分支 |

- **`files` 是全量清单，不是增量清单。** `[既有推演]` 客户端通过「本地 `overlay.manifest.json` 与云端 manifest 逐文件 hash 比对」自行推出待下集；服务端下发差量会把「差量基线是哪一版」变成有状态协商，而客户端的事务模型明确不要状态。全量清单也让「文件从 overlay 中移除」（回退到 `res://` 基线值）自然可表达：**不在清单里 = 应从 `overlay/` 删除**。
- **blob URL 不写进 manifest 条目**，由 `<contentRoot>/blobs/<hash>` 拼出；`contentRoot` 随信封 / 配置下发，使 CDN 域名可切换而不需重签历史 manifest。
- **`ContentEnabled` 不在 manifest 里**——它是 `.tres` 条目内的字段（随文件走），其线上覆盖走下一节的 flags 通道。

**版本化路径：**

- **`manifestSchema` 只在破坏性变更时 +1。** 向后兼容的加字段（新增可选字段）**不**提升版本；契约明写「**客户端必须忽略未知字段**」。`[通行做法]`
- 破坏性变更时，服务端**同时保留 N-1 与 N 两版 manifest 端点**一段时间（按客户端上报的 `appVersion` 或显式 `?manifestSchema=` 参数分流），使老客户端不被立即打断。`[通行做法]`
- **`manifestSchema` / `contentVersion` / `appVersion` 三者的关系（同时答结 `content-service.md` 中的同名待决问题）：**

  | | 承载 | 谁提升 | 不匹配时 |
  |---|---|---|---|
  | `appVersion` | 客户端二进制（含基线内容、含内置公钥、含支持的 `manifestSchema` 集合） | 发版 | 过旧 → 由 `envelope` 的版本协商裁决（软提示 / 硬闸门，属 `01-contracts.md`） |
  | `manifestSchema` | manifest 的**结构** | 后端契约演进 | 客户端不支持 → 跳过更新、用基线（**不阻塞开局**）；客户端支持但与本地不同 → 整包全量重下 |
  | `contentVersion` | overlay 的**内容** | 每次内容发布 | 与本地不同（且更大）→ 增量更新 |

  **`manifestSchema` 不支持时降级到基线，而非强更。** `[既有推演]` 客户端已定「断网降级：跳过更新，直接使用基线——首启不依赖网络下载内容」。既然网络完全不可用都能开局，「manifest 读不懂」显然也不该比断网更严厉。强更是 `appVersion` 维度的决定（走 `envelope`），不由内容分发通道兼职。

### 4. `ContentEnabled` 下发通道：独立 flags 通道，作为合并的第三层

`[用户裁决 2026-08-11]` + `[既有推演]`

**先把事实摆清楚** `[既有推演]`：客户端的 overlay 合并与 `LoadAll()` 校验发生在**启动链第一步**。因此沿用 overlay 通道时，关掉一个条目的实际生效点是玩家的**下一次冷启动**——一次已在进行的会话不受影响。这满足 pillar #5 的「不需要发版」，但不满足其字面上的「秒关」。**故采用独立通道。**

新增一个轻量端点，下发**已按当前账号解析完毕**的开关覆盖集：

```
GET /content/flags  →  { "flagsSchema": 1, "flagsVersion": 41, "contentVersion": 137,
                         "disabledIds": ["card_x", "event_y"], "enabledIds": [] }
                       + 同一密钥体系（ES256 detached）的签名
```

客户端把它作为**合并的第三层，只影响抽取池**：

```
res://基线  <  user://overlay/  <  flags（仅覆盖 ContentEnabled，不改任何数值）
```

**它与客户端已定的那条不对称设计严丝合缝** `[既有推演]`：`ContentEnabled` 唯一的作用点是**产出侧的 `AllEnabled()` 取池**，读取侧 `Get(id)` 本就不过滤。因此这一层：

- **不改任何数值** → 不触碰「合并后强校验」（`Id` 唯一性、交叉引用）的任何输入，校验模型原样成立；
- **不新增 / 不删除 `Id`** → 完全落在「热更只改不增」纪律内；
- **存档解析不受影响** → 「存档引用未知内容」的风险依然为零；
- 因此它**可以在轮回进行中安全热应用**（下一次抽取即生效），而数值型 overlay 无此性质。**它之所以能秒，恰恰因为它被限制得足够窄。**

**硬边界（使代价可控，不可放宽）：flags 只能覆盖 `ContentEnabled` 这一个布尔，不得携带任何数值 / 文案 / 新 `Id`。** 一旦放宽，上述三条纪律立即失效。

顺带定下两件事 `[既有推演]`：

1. **灰度 / 分批放量的落点 = 服务端。** 分桶规则（百分比 / 白名单 / 篇章档位）**留在服务端**，`GET /content/flags` 按账号计算后下发**结果**——客户端始终只看到「这些 `Id` 现在不进抽取池」，永远不知道分桶规则存在。这使 `content-service.md` 的「分桶信息放哪」有了答案：**哪也不放在客户端**；也使 `DrawPool<T>` 的构造签名**不必**变成 `AllEnabled(bucketContext)`（该待决问题点名这是它的唯一依赖）。
2. **刷新时机 = 搭车信封，零轮询。** flags 随**任意应答的信封**搭载一个 `flagsVersion`（后端每次同步都要回信封），客户端发现版本变化时才去拉 flags 全量。秒关的实际延迟 = 该玩家的下一次事件推进上行（客户端已定「每个 AdventureEvent 后一次上行」），**分钟级以内**。

**`enabledIds`：保留字段，初期恒空。** `[用户裁决]` 反向打开一个被基线关掉的条目，要求它的数值已随包发布且正确，风险与「关」不对称，不宜走同一条快通道。字段先立在 schema 里，避免日后启用时提升 `flagsSchema`。

**已承担的代价（如实记录）：**

- 新增一个契约面 + 一个客户端合并层，**需要客户端侧另写一份 handoff**（跨库事件，见「跨库待办」）。
- flags 是**运行时可变状态**，同一个轮回内抽取池可能中途变化——但这与既有的「不冻结 `contentVersion`、overlay 进行中即生效」是**同一性质**的让步，未新增语义债。

## 具体形态（可 derive 的落地面）

### 端点（路径为示意，最终形态随 `01` 的契约表达形式定稿）

| 端点 | 方法 | 应答 | 缓存 | 签名 |
|---|---|---|---|---|
| `/content/manifest` | GET | manifest.json 原始字节 | no-cache / 秒级 | ES256 detached，见 `.sig` 或响应头 |
| `/content/manifest.sig` | GET | `{alg, keyId, sig}` | 同 manifest | — |
| `/content/blobs/<sha256>` | GET | 文件字节 | `immutable, max-age=31536000` | 由 manifest 内 hash 覆盖 |
| `/content/flags` | GET | flags JSON + detached 签名 | no-cache | 同一密钥体系 |

### manifest schema（`manifestSchema: 1`）

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

### flags schema（`flagsSchema: 1`）

```json
{
  "flagsSchema": 1,
  "flagsVersion": 41,
  "contentVersion": 137,
  "disabledIds": ["card_x"],
  "enabledIds": []
}
```

### 与客户端 `OpError` 的映射（`CheckAndUpdateAsync` 的三分支）

| 情形 | 应答 | 客户端 `OpError` | 客户端处置 |
|---|---|---|---|
| 网络不可达 / 超时 / 5xx | — | `Network` | 跳过更新，用现有层开局（已定的断网降级） |
| 验签失败 / hash 不符 / `keyId` 未知 | — | `Validation` | `PushError` + 拒绝 overlay + 回退基线 + 上报一次事件 |
| `manifestSchema` 不受支持 | 200（客户端自行判定） | `Validation`（细分一个不上报的子因） | 跳过更新，用基线（**不强更**） |
| `minAppVersion` 高于当前 | 200（客户端自行判定） | — | 跳过更新，用基线；强更与否归 `envelope` 的版本协商 |
| 预估落盘空间不足（由 `files[].size` 求和） | — | 磁盘空间 | 下载前即失败，不产生半套 staging |

### 服务端发布流程（→ `operations/`，栈落定后细化）

1. 计算全部 overlay 文件的 SHA-256，推送缺失的 blob（幂等：已存在的 hash 跳过）。
2. 生成 manifest（`contentVersion` = 上一版 +1），用当前 `keyId` 的私钥对其原始字节做 ES256 签名。
3. **确认全部 blob 可读后**，再发布 manifest + `.sig`（两者需一起可见——同一次原子切换，或先 `.sig` 后 manifest 以避免读到无签名的 manifest）。
4. 回滚 = 重跑 1–3，manifest 内容指回旧 blob，`contentVersion` 继续 +1。
5. 秒关 / 灰度不走本流程——改 flags 数据源即可，不触碰 blob 与 manifest。

## 后果

- **新建 `contracts/content-manifest.md`**（`contracts/_index.md` 已登记它为计划文档，本定案是它的第一版内容），覆盖范围需扩写为「manifest + blob + flags」三者。其中「错误码映射」与「版本协商」两段需与 `contracts/envelope.md` 同批定稿，不在本文件里另立一套错误码。
- **`envelope.md` 新增一项**：信封须携带 `flagsVersion`（与 `contentVersion` / `appVersion` / `revision` 并列），这是 flags 零轮询刷新的承重字段。
- **`operations/` 的第一批内容有了具体对象**：CDN 缓存策略（两类对象两种 TTL）、内容发布与回滚流程、flags 数据源与灰度分桶的运营面、签名密钥的保管与轮换。
- **签名密钥管理进入运维范围**：私钥的存放（KMS / 密钥托管）与 CI 中的签名步骤，会反向约束 `06-platform-stack.md` 的托管选型。
- **ADR 候选两条**：①「内容寻址 + `contentVersion` 严格单调递增（回滚即前滚）」；②「flags 第三层只覆盖 `ContentEnabled`」——后者带有对客户端存储模型的松动，值得固化其边界条款。
- **对客户端的影响**：定案 1/2/3 全部落在客户端已定案的形态内，**不需要客户端改动**（`files[].size` 是新信息，但它服务的磁盘预检本就是客户端已定的三类失败之一）。**定案 4 需要客户端改动**——见下。
- **不影响存档 schema**：flags 是运行时态，不入存档；`StartContentVersion` / `LastContentVersion` 语义不变。

### 跨库待办（客户端侧，本库不代为决定）

flags 第三层需 `game-design-documents/` 另写一份 handoff，至少定案三点：

1. 第三层如何参与 `AllEnabled()` 取池（合并时机：启动时 + 收到新 `flagsVersion` 时热应用）。
2. `flagsVersion` 在客户端信封 / 同步应答中的读取点与触发拉取的时机。
3. **flags 是否落地本地缓存以支撑离线开局**——若不缓存，断网启动时抽取池会回到 overlay 的 `ContentEnabled` 值（即「被秒关的条目在离线时复活」）。这是本定案唯一未闭合的语义缺口，归客户端侧裁决。

同时，客户端侧的两条待决问题可随该 handoff 一并答结：`content-service.md` 的「`ContentEnabled` 粒度是否够用」（答：分桶留服务端，客户端仍只见布尔）与「`manifestSchema` 的版本化」（答：见本定案第 3 节的三版本关系表）。

## 备选方案（已考虑并否决）

- **整包版本粒度（每次全量重下 overlay）** — 否决：客户端已定文件级 + 逐条目 hash；且移动网络下全量重下的失败率远高于逐文件重试。
- **服务端下发差量清单（只列变化文件）** — 否决：需服务端知道「客户端的基线是哪一版」，把无状态拉取变成有状态协商，与客户端的事务模型（自行比对推出待下集）冲突，且无法表达「文件被移除」。
- **字节级断点续传 / 下载会话令牌** — 否决：`.tres` 是 KB 级，客户端侧已明确复杂度换不回收益。
- **签名内嵌进 manifest JSON（需规范化重序列化）** — 否决：canonical JSON 的两侧实现差异会造成无法在设备上复现的随机验签失败。
- **RSA-2048 + SHA-256（走 Godot 内置 `Crypto`）** — 未采纳。它同样可行（客户端连 .NET 加密 API 都不必碰），但 ES256 签名更小、验签更快，且 `ECDsa` 已在 .NET 内置，无额外收益差。
- **Ed25519** — 未采纳：.NET / Godot 侧需第三方原生依赖并跨四端导出，收益（更小的签名、更简的实现）对本场景不重要。
- **证书链 / PKI 验证 overlay** — 否决：威胁模型只到「防误 / 防随手改」，固定公钥 + `keyId` 轮换已足够。
- **允许 `contentVersion` 回退以实现回滚** — 否决：给客户端引入「降级」分支，并破坏 `StartContentVersion` / `LastContentVersion` 的单调判据；内容寻址让「前滚回旧内容」零成本。
- **基于绝对时间的 manifest TTL 防回放** — 否决：设备时钟不可信，会误伤离线 / 时区异常玩家；用 `contentVersion` 单调性即可。
- **`ContentEnabled` 沿用 overlay 通道** — 否决（用户裁决）：合并在启动链第一步，秒关实为「下次冷启动关」，延迟以小时计；且 `.tres` 里的布尔对全体玩家同值，灰度 / 分批放量无处安放。
- **独立的 flags 长连接 / 推送通道（WebSocket / 第三方推送）** — 否决：为一个低频运营动作引入长连接基础设施；搭车信封的 `flagsVersion` 已把延迟压到分钟级，成本几乎为零。

## 与既有决策的张力

**一处，已由用户裁决接受松动（2026-08-11）：**

- **张力对象**：`game-design-documents/systems/services/content-service.md` 的**「存储形态：三层（已定案）」**——原模型是 `res://` 基线 + `user://overlay/` 两层数据 + 内存合并，`ContentEnabled` 被定位为「overlay 只改这个既有布尔字段」。flags 第三层引入了第三个覆盖来源，使「overlay 是唯一热更层」不再成立。
- **接受松动的理由**：合并发生在启动链第一步，overlay 通道下「秒关」的真实延迟是玩家下次冷启动；`vision/pillars.md` #5 明确把线上可干预排在可复现性之上。
- **松动的代价**：客户端多一个覆盖层与一条刷新路径；契约多一个端点；「热更全部经由 overlay」的心智模型拆成「数值走 overlay / 开关走 flags」两条。
- **限定条款（使代价可控）**：flags **只能覆盖 `ContentEnabled` 这一个布尔**，不得携带任何数值 / 文案 / 新 `Id`。有此限制，「合并后强校验」「只改不增」「存档必可解析」三条纪律**全部原样成立**——flags 层根本不参与校验的输入。
- **落笔要求**：该松动须在客户端侧的 handoff 中同步改写 `content-service.md` 的「三层存储」小节（改为三层覆盖来源），并在本库记一条 ADR 固化限定条款。

其余三条定案与既有决策**无冲突**：它们都是在客户端已定案的形态内补齐服务端侧的兑现方式。

## 前置依赖

- **`01-contracts.md`（契约表达形式）** — 本定案的 schema 以 JSON 形态给出，但**端点风格、字段命名规范、序列化约定、错误码分层**要等 `01` 定稿（OpenAPI + JSON Schema vs 共享 DTO 代码）才能落成正式契约。**字段语义已定案；字段名与序列化形态不视为定稿。**
- **`01-contracts.md`（版本协商与强制更新）** — 本定案明确把强更**推给** `envelope`，因此 `minAppVersion` 与强更闸门如何分工，需与 `01` 一并确认；`flagsVersion` 进信封亦需在 `01` 落笔。
- **`06-platform-stack.md`（技术栈 / 托管 / CDN 选型）** — 内容寻址 + 两类缓存策略是对 CDN 的能力要求（不算苛刻，主流 CDN 均满足），但**具体选型未定前无法写 `operations/`**；ES256 私钥的保管方式同样取决于托管形态。
- **`02-account-compliance.md`（区域与合规托管）** — 若国内渠道要求内容分发也在境内，`contentRoot` 需按区域下发（本定案已把 `contentRoot` 排除在被签名的 manifest 之外，正是为了留出这个自由度，但多区域一致性策略未展开）。
- **客户端侧 handoff（flags 第三层）** — 见「跨库待办」；其中**「flags 是否落地本地缓存以支撑离线开局」是本定案唯一未闭合的语义缺口**。

## 仍需用户决定

无——三处取向选择均已于 2026-08-11 裁决：

| 项 | 裁决 |
|---|---|
| `ContentEnabled` 下发通道 | **独立 flags 通道，作为只覆盖 `ContentEnabled` 的第三层** |
| 签名算法 | **ES256（ECDSA P-256 + SHA-256）** |
| `enabledIds` 反向打开 | **保留字段，初期恒空** |

余下的开放项均为**前置依赖**（等 `01` / `06` / `02` 与客户端 handoff），不是取向选择。

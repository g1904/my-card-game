# `manifestSchema` 双发走路径分支 + CDN 三端点失败状态码钉死

- id: 2026-09-07-manifest-schema-path-branch-and-cdn-failure-codes
- date: 2026-09-07
- topic: contracts/content-manifest（端点表 · 版本化分工 · 失败面表）· contracts/envelope（§3 端点全集三行）· operations/version-matrix · operations/content-delivery-ops
- status: distilled
- distilled-to: `contracts/content-manifest.md`、`contracts/envelope.md`、`operations/version-matrix.md`、`operations/content-delivery-ops.md`

## Intent（distilled）

**一句话：`manifestSchema` 的 N-1 / N 双发靠客户端按内置支持集合选择路径分支 `<contentRoot>/s<manifestSchema>/manifest` 完成，`s1` 从第一天就在；`/blobs/<sha256>` 不分支。CDN 三端点的失败状态码在契约层钉死，4xx 按「manifest 是否已可读」两分。**

### 一、分流的判定方只能是客户端

正文原写的两个候选中，「按 `appVersion` 服务端分流」经直读**结构上不成立**，两条独立的硬事实各自否掉它：

- CDN 域三端点无鉴权、不是 API 请求，服务端在这条请求上既没有 token 也没有 `X-App-Version`（`envelope.md` §4a 只要求 API 请求带该头）。要让它拿到，只能让 CDN 对该头 `Vary`——那要求客户端在静态对象上带一个从未要求的头，并把缓存键按版本串碎；这条形态一旦立下就会被套到 `/blobs/*` 上，而那里的 `immutable` 长缓存是整条链的成本基石。
- manifest 拉取排在**登录之前**（客户端 `ContentService.InitializeAsync` 是启动链第一步）。哪怕日后给 CDN 加了鉴权，那一刻也不存在可供服务端判定的会话身份。

**推论（承重）：分流不可能是「服务端按谁来了给不同的东西」，只能是「客户端按自己支持什么去请求不同的 URL」。** 客户端是唯一同时知道「我支持哪个 `manifestSchema` 集合」（内置于二进制）与「我正在发这个请求」的一方。这条推论必须写进契约正文，否则日后必然有人重新提出按版本分流。

### 二、编码位取路径，不取 query

| 端点 | |
|---|---|
| `GET <contentRoot>/s<manifestSchema>/manifest` | 该结构版本的 manifest 原始字节 |
| `GET <contentRoot>/s<manifestSchema>/manifest.sig` | 对应的 detached 签名 |
| `GET <contentRoot>/blobs/<sha256>` | **不变**，与 `manifestSchema` 无关 |

- **blob 不分支是关键收益。** blob 是内容寻址的字节，与 manifest 的**结构**无关。双发的真实成本 = **两个小 manifest 对象 + 两次签名**，blob 一个字节都不重复推、不重复存、不重复回源。双发因此从「要限期止损的负担」降为一条可从容执行的常规发布动作。
- **未知 schema 天然是 404**，不需要 `400`——而 400 在一个不返回契约错误体的域里，客户端只能拿到一个裸状态码、读不到理由。路径分支把「你要的那一版结构不存在」与「对象不存在」合并为同一格，失败面表因此少一行、客户端少一条分支。
- **`s1` 从第一天就在。** 当下零在架客户端、`manifestSchema` 集合待定 ⇒ 迁移成本为零；此形态若不在首发前定，`1` 就会成为一个永久特例，此后每个读者与每次 spec 落笔都要先学这个例外。

否决 query 变体 `?manifestSchema=N` 的三条：① 它污染 `envelope.md` §3 的机器读取面——首列要么写裸路径（则变体形态在契约里无处登记），要么写成带 query 的串（则 P-3 的形态定义要重写且须同批改提取脚本）；② CDN 缓存键默认不含 query 是常见配置，两个变体会互相污染，症状是「一部分玩家拿到另一版结构的 manifest → 验签通过、解析失败」，只在破坏性变更当天、只在部分边缘上出现；③ 形态天然不对称且不可修复——老客户端不带 query，故裸路径必须永远是 N-1 的语义。

### 三、保留时长 = 覆盖率条件 ∧ 时间下界

```
T0  发布 manifestSchema N        两个路径分支并存；矩阵的 manifestSchema 集合 = {N-1, N}
T1  覆盖率 ≥ 95%（过去 7 天有请求的账号中 appVersion ≥ 首个支持 N 的版本）
    → 把 appVersion 下界提到该版本，并在矩阵里给 N-1 填下线计划
T2  = T1 + 60 天                 提下界只在下一次登录生效；覆盖存量会话所需时间的
                                 上限 = refresh 链的绝对寿命上限
    → 停发 N-1 分支、删实现分支
```

**保留时长 = (T1 − T0) + 60 天，绝对下界 60 天。** 60 天不是本方案新起的旋钮——它是 `contracts/auth.md` §8 的 refresh 绝对寿命上限，随那个旋钮走。本库对「旧客户端最长能活多久」只应有一份答案。

- **必须等到 T2 而非 T1**：T1 之后仍有存量会话只走 `refresh`、从不 `signin`，它们不经过闸门，仍会去请求 N-1 分支。绝对寿命上限是让这批会话必然翻转的唯一机制。
- **判据刻意偏向「宁可多留」**：超期未下线的代价近乎为零（两个小对象）；要防的是**过早**下线——它让一批还能正常游玩的客户端从此收不到任何内容热更，而客户端对此不报错、不阻塞，症状与「最近没发内容」不可区分。
- 覆盖率阈值 95% / 窗口 7 天在 `content-delivery-ops.md` 已有条目，**不复制第二份**。

### 四、CDN 三端点失败状态码：4xx 两分

判据一句话：

> **入口对象（manifest）的 4xx = 环境 / 配置面** —— 跳过更新用基线 + 本地告警，**不上报**；
> **入口之后的对象（`.sig` / blob）的 4xx = 发布原子性被违反** —— `Validation` + 上报一次，且**不进退避重试**；
> **408 / 429 / 5xx / 连接失败 / 超时 = 传输面** —— `Network`，照既有降级与既有重试。

理由：manifest 404 的最可能成因是 `contentRoot` 配置错、环境尚未首发内容——客户端无从区分，且它不代表已发布的内容被动过，映成 `Validation` 会在开发 / 测试环境刷出持续告警。而 `.sig` 或 blob 的 404 只可能发生在 manifest **已经被读到之后**，那一刻服务端保证 A 组第 3 条已承诺「它列出的文件必须已可下载」——收到 404 即证明发布纪律被破坏（或负缓存命中）。同理，对一个明确的 404 跑三次退避重传是纯浪费，重试语义是为传输抖动准备的。

**「版本已被回滚 / 撤下」这一失败面结构性不存在**：回滚 = 前滚，manifest 被更大的 `contentVersion` 覆盖而非删除，历史 blob 永不删除。逐字写下这一格，是为了让「回滚了要不要给客户端一个信号」此后不再被问。

### 五、运维面的连带

- **负缓存要求逐字扩到三端点**（现只覆盖 `/blobs/*`）：同一病理——某边缘在首发或双发新分支上线**之前**被探测器 / 人工排查请求过一次并缓存了 404，则在 TTL 内命中该边缘的客户端稳定拿不到一个已经发布的 manifest。`no-cache` 约束的是成功应答的复用，不自动约束错误应答的负缓存。
- **发布流水线顺序纪律一字不改**，双发期按下列方式读：步②③④对两个 schema 分支各生成、各签名、各自验一次（自验仍用客户端内置的公钥）；步⑥两个分支各自满足「`.sig` 先于或与 manifest 同一次切换」，**两分支之间不要求原子**——它们服务不相交的客户端集合，blob 集合共享且早已推完；步⑦留痕八字段中的 `manifestSha256` 承载**每个分支各一个摘要**。
- **`contentVersion` 仍是单一序列、单一分配点**：两个分支描述的是同一个内容版本，不各自计数，否则客户端「更大即增量更新」的判据在跨分支升级时当场失效。

### 边界

- **报文零改动**：`manifestSchema` 不因本方案提升、manifest 字段表一字不改、flags 通道零影响。改的只有 URL 形态与失败面语义。
- **`envelope.md` §6 错误码台账零改动**：台账每条都要给出 `code` · `class` · `detail` 形状 · `message` 必含值，而 CDN 域结构上产不出这四样；客户端在这条通道上映射的是 `OpError` 三档，不经 `code` 表。新增条目会造出一批永远不会被下发的 `code`，并让 P-1 的双向机检断言在「台账有、正文无」这一侧永久失衡。
- **`envelope.md` §3 端点全集改三行**（K5：新增 / 改名端点须同批改本表）。首列仍是反引号包裹的裸 `METHOD 路径`，`<contentRoot>/s<manifestSchema>/manifest` 与既有的 `<contentRoot>/blobs/<sha256>`、`GET /v1/compliance/export/{taskId}` 同构 ⇒ **不改变本表结构、不需要改提取脚本**。这是路径分支相对 query 变体的第二个结构性优势。
- 无存档 schema 影响、无迁移。

## Clarifications（interview 产物）

- **分流机制的最终形态，以及 `manifestSchema = 1` 是否也进路径分支？** → **选项 A：路径分支 · 现在就统一**（2026-09-07 批量评审裁决）。`s1` 从第一天就在；`envelope.md` §3 现在就改三行。选项 C（query 变体）与选项 D（按 `appVersion` 服务端分流）双双否决。
- 草稿列为「按推荐直接落笔」的一组用户未提异议，一并视同裁决：保留时长判据（95% / 7 天 ∧ 提下界后再等 60 天）· 状态码表全部行 · 4xx 两分判据 · 负缓存扩到三端点 · 留痕 `manifestSha256` 双发期承载两值 · 不新增 `envelope.md` §6 台账条目。

## Notes / triage

- **§3 是 P-3 机器读取面**，本次只改行内容、不改表结构，故提取脚本无须同批修改；`contract-spec-check` workflow 与校验脚本本身尚未落地（`operations/deployment.md` 自陈），当前三条机检断言以人工清单前三项执行——本次改动已按断言③′ 的口径人工核对：`envelope.md` §3 的三行 ⇔ `content-manifest.md` 正文中出现的三个 CDN 端点，双向一致。
- 与同批的 `handoffs/2026-09-07-refresh-expiry-reasonkey.md` 有一处交汇：那一份明确不动 §3。两处不冲突。
- **`auth.md` §8 的 refresh 绝对寿命上限（60 天）若被改动，本方案的保留时长下界随之改变。这是刻意的挂钩，不是遗漏。**
- 值得固化为 ADR 的两条：**① `manifestSchema` 的分流判定方只能是客户端，编码位取路径分支**；**② CDN 域失败面按「入口对象 / 入口之后的对象」两分。** 立档归 `/write-adr`，本 handoff 不建 ADR。
- 本次未移出任何 `open-questions/` 条目：这两条卡点记录在「derive 就绪度」小节（`/assess-derive-readiness` 独占写入），`04` 分片的待答清单本就为空。故**无 answer log**。
- **不依赖**：`operations/content-delivery-ops.md` A6–A9（flags 请求处理路径）的 FR 归属仍未裁决（`systems/content-delivery.md` 尚未建立）——A6–A9 全在 flags 通道，本方案只动 CDN 域三端点与 manifest 结构版本，二者不互相阻塞。

## 客户端侧影响

**两项承接义务，归对侧裁决，本库不代为决定：**

1. **按内置的 `manifestSchema` 支持集合拼出请求路径**（而非固定 `/manifest`）——`content-service` 的启动链第一步。
2. **对 CDN 域的 4xx 按上述两分处置**，其中「不对 4xx 走 3 次退避重传」是对既有下载重试语义的一次收窄。

两项均落 `game-design-documents/systems/services/content-service.md`。契约面已可先行落笔——路径形态与状态码是后端侧的权威，客户端半可任意延后（当下零在架客户端，无兼容负担）。

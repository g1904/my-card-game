# ADR-0051 — `manifestSchema` 双发走客户端选路的路径分支，blob 不分支

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07-manifest-schema-path-branch-and-cdn-failure-codes.md

## 背景

`manifestSchema` 发生破坏性变更时，服务端要同时向老客户端供 N-1、向新客户端供 N。正文此前把分流机制写成二选一（「按 `appVersion` 服务端分流」或「显式 `?manifestSchema=` query 变体」）且保留时长未定，这两处留白同时卡住契约面与端点全集的落笔。

约束来自两条硬事实：CDN 域三端点无鉴权、不是 API 请求，服务端在这条请求上既无 token 也无 `X-App-Version`；且 manifest 拉取排在**登录之前**（客户端启动链第一步），那一刻不存在可供服务端判定的会话身份。

## 决策

`manifestSchema` 的分流**由客户端按自己内置的支持集合选择路径分支**完成，服务端不做任何判定：

- `GET <contentRoot>/s<manifestSchema>/manifest` 与 `…/manifest.sig` 的路径段承载结构版本，**`s1` 从第一天就在**；
- `GET <contentRoot>/blobs/<sha256>` **不带该段**，与 `manifestSchema` 无关；
- 未知 schema 天然是 **404**，不为它另立 `400`；
- **保留时长 = 覆盖率条件 ∧ 时间下界**：T1（过去 7 天有请求的账号中 `appVersion` ≥ 首个支持 N 的版本，覆盖率 ≥ 95%）提 `appVersion` 下界并给 N-1 填下线计划，**再等 60 天**（T2）才停发 N-1 分支。60 天不是新旋钮——它是 `contracts/auth.md` §8 的 refresh 绝对寿命上限，随那个旋钮走；
- `contentVersion` 仍是单一序列、单一分配点，两个分支描述同一个内容版本，不各自计数。

端点形态见 `contracts/content-manifest.md`「端点」与「版本化」，端点全集登记见 `contracts/envelope.md` §3，下线计划与覆盖率口径见 `operations/version-matrix.md` 与 `operations/content-delivery-ops.md`。

## 理由

- **分流方只能是客户端。** 客户端是唯一同时知道「我支持哪个 `manifestSchema` 集合」（内置于二进制）与「我正在发这个请求」的一方。要让服务端拿到判定输入，只能让 CDN 对某个头 `Vary`，那要在静态对象上引入一个从未要求的头并把缓存键按版本串碎——而 `/blobs/*` 的 `immutable` 长缓存是整条链的成本基石。
- **blob 不分支是关键收益。** 双发的真实成本收敛为两个小 manifest 对象 + 两次签名，blob 一个字节都不重复推、不重复存、不重复回源。双发因此从「要限期止损的负担」降为常规发布动作。
- **路径优于 query。** query 变体污染 `envelope.md` §3 的机器读取面（P-3 的形态定义要重写并同改提取脚本）；CDN 缓存键默认不含 query，两个变体互相污染的症状是「验签通过、解析失败」，只在破坏性变更当天、只在部分边缘上出现；且老客户端不带 query ⇒ 裸路径必须永远是 N-1 语义，形态天然不对称且不可修复。
- **必须等到 T2 而非 T1。** T1 之后仍有存量会话只走 `refresh`、从不 `signin`，不经过强更闸门，仍会请求 N-1 分支；绝对寿命上限是让这批会话必然翻转的唯一机制。判据刻意偏向宁可多留：超期未下线的代价近乎为零，而过早下线让一批还能正常游玩的客户端从此收不到内容热更，且客户端不报错、不阻塞，症状与「最近没发内容」不可区分。

## 备选方案

- **按 `appVersion` 服务端分流** — 结构上不成立：CDN 域拿不到该头，且 manifest 拉取在登录之前。
- **`?manifestSchema=N` query 变体** — 污染机器读取面、CDN 缓存键默认不含 query、裸路径语义不对称且不可修复。
- **`s1` 不进分支、只从 `s2` 起用路径段** — `1` 会成为永久特例，此后每个读者与每次 spec 落笔都要先学这个例外；当下零在架客户端，迁移成本为零。

## 后果

- `contracts/envelope.md` §3 端点全集三行改为路径分支形态；**只改行内容、不改表结构**，提取脚本无须同改（这是路径分支相对 query 变体的第二个结构性优势）。
- `operations/content-delivery-ops.md` 的发布流水线顺序纪律一字不改，双发期按「两个分支各生成 / 各签名 / 各自验一次」读；步⑥ 两分支之间**不要求原子**；留痕的 `manifestSha256` 在双发期承载每个分支各一个摘要。
- **报文零改动**：`manifestSchema` 不因本决策提升，manifest 字段表与 flags 通道不受影响；改的只有 URL 形态。
- `contracts/auth.md` §8 的 refresh 绝对寿命上限被改动时，本决策的保留时长下界随之改变——这是刻意的挂钩，本库对「旧客户端最长能活多久」只应有一份答案。
- 客户端承接义务一项（按内置支持集合拼请求路径），落 `game-design-documents/systems/services/content-service.md`，由对侧裁决。

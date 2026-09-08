# Answer log cdn-multi-region-propagation-window

- 日期：2026-09-06
- 来源：`inbox/archive/solution-draft-cdn-multi-region-propagation-window.md` → `handoffs/2026-09-06-flags-propagation-window-and-instance-skew.md`
- 移出条数：**1**（`open-questions/04-content-delivery.md` 的唯一待答条目；该分片待答清单随之清零）

---

**多区域内容分发的一致性与传播窗口 T** → **两半分别答结。**

**第一半 · CDN 侧三问 —— 否定结论（问题被上游决策消解）。** 服务侧是单区域部署、不做跨区域多活，故「多区域」在内容分发面不存在对象：① `contentRoot` 按区域下发**不启用**（自由度保留、不撤销，其现役用途改述为域名 / 厂商切换与日后独立部署——CDN 边缘节点不是「区域」，它们回源同一源站、由同一份 manifest 定义内容）；② 多区域间 `contentVersion` 同步推进的问题**消解**（单一发布动作、单一序列、单一分配点，「同步推进」没有对象）；③ 区域间发布时序差**降格为边缘缓存传播**，已被「先推 blob 后推 manifest + 内容寻址 + 两类 TTL」覆盖，另补两条 CDN 能力要求（`/blobs/*` 关闭负缓存或 TTL ≤ 数秒 · 步⑤ 探针走 CDN 域而非直连源站）。日后走独立部署时是**两套独立部署**、各自独立的 `contentVersion` / `flagsVersion` 序列且不要求同步推进，作为新输入重新提起。

**第二半 · 传播窗口 T —— 先重定义、再取值。** 条款主体由「全部区域」改为「**全部对外服务的实例**」：单区域下仍有多个应用实例，`X-Flags-Version` 搭车下发而各实例的当前版本不在同一瞬间更新，这才是 T 的真实失效主体（单一全局序列与良性态口径原样成立）。**T 取初值 60 秒**（上侧受「秒关端到端分钟级」承诺约束，下侧因误报已被结构性消除而不必更小），预算分解为版本读取缓存 TTL **5 秒** + 副本滞后预算 **10 秒**（当前实际 0）+ 余量；**T 本身是 SLO 判定阈值、不进 `config_knob`**，两个分项进旋钮表。配三条服务端纪律（A7 应答体版本取自实际使用的规则集 · A8 头取 `min(高水位, 本实例可兑现最大版本)` 即**头永不领先** · A9 该数由既有规则集缓存自然给出），使唯一会产生误报的偏斜方向结构性不可能，T 由此降级为**纯延迟 SLO**。另配一条零契约面探针：实例 gauge 极差 ≠ 0 且持续超过 T 即告警。

**归档去向：** `contracts/content-manifest.md`「服务端保证」B 组失效来源表第二行（主体改多实例 + 头永不领先一句 + T 回链；`## Open questions` 唯一条目答结后整节删除）· `operations/content-delivery-ops.md`（新增 A7–A9 · 新增「版本传播窗口 T：口径、预算与探针」一节 · 数值初值一览 +3 行 · 对 CDN 的能力要求 +2 条 · 步⑤ 注记）· `operations/environments.md`（旋钮清单 +2 行）· `operations/observability.md`（数据面新增 gauge 极差告警）· `decisions/ADR-0009-immutable-versioned-flag-rulesets.md`（配套段与后果段两句悬空引用对齐，**决策本体不动**）· `decisions/ADR-0001-content-addressed-monotonic-versioning.md`（备选方案栏措辞对齐，**决策与否决理由本体不动**）· `systems/_index.md`（`content-delivery.md` 两项欠账全部闭合）。

**报文与客户端：** 契约层零报文改动、零 schema 提升，客户端零义务、零改动；两道单调闸原样保留，副作用只是误报率降到接近零。

**仍开放（不构成待答项）：** 三个数值全部待实测校准，须在 testing 环境跑过一次多实例发布后回填——运营期常规校准，初值与旋钮位置已给全。

# Answer log client-flag-cache-and-binary-overlay

- 日期：2026-08-30
- 来源：`inbox/archive/solution-draft-client-flag-cache-and-binary-overlay.md` → `handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md`
- 移出条数：2（`contracts/content-manifest.md`「Open questions」由四条降为两条）

## 逐条

**blob 通道是否向二进制资产开放（承接项）** → **答：不开放。** `files[]` 继续只承载 `.tres` 内容文件；贴图 / 音频等二进制资产不经本通道下发，换图 / 加图随客户端版本发布（裁决与判据在对侧，回链 `game-design-documents/systems/common-properties.md`）。**契约零改动**：A 组四条、manifest schema 字段表、签名形态、`manifestSchema` 一字不改。关闭时同批写下**「这不是契约能力不足」**——报文层对文件类别中立，内容寻址 · 稳定 URL 与字节不可变 · 发布原子性 · 完整性覆盖面 · `files[].path` 校验面五项对非 `.tres` 逐字成立，限制来自对侧的字段形态与资源引用模型。**否决**把它写成 A 组第 5 条服务端保证（它不是服务端义务，写进 A 组等于声称后端会拒绝二进制文件，既非事实也无人执行）。若日后开放须核对三点（`files[].size` 口径与磁盘预检 · 「字节级 Range 不写进契约」这条否定须两侧同批重估 · CDN 缓存与成本模型），以**条件化记录**形态登记、不列为待办。（归档去向：`contracts/content-manifest.md`「blob 通道不承载二进制资产」）

**flags 是否落地客户端本地缓存以支撑离线开局** → **答：落（对侧裁决），且问句的前提须一并纠正。** 「以支撑离线开局」这个用途在对侧不成立——客户端启动 pull 是硬阻塞，强制在线下不存在「断网启动并进入轮回」这条路径；真实收益只有「登录成功但 flags 拉取失败」时的降级值。客户端的持久化形态、失效语义与降级口径权威在 `game-design-documents/systems/services/content-service.md`，**本契约不复述、不代为约束**。本库侧新增三样只有本库有权威的内容：① **`no-cache` 的适用面是 HTTP 缓存层**（防中间层复用按账号计算的应答 = 防灰度分桶串号），**不约束客户端的应用层持久化**，回链 `envelope.md` §3 而不在 §3 侧复制；② **后端义务 = 零**（不下发 TTL / `max-age` 字段 · 不回显 `accountId` · 不提升 `flagsSchema` · 不新增服务端保证）；③ **B 组第 7 条的依赖方登记为两项**（等值不拉 · 客户端降级缓存的可复用性），条款本体一字不改。（归档去向：`contracts/content-manifest.md`「flags 通道：`ContentEnabled` 的第三层」与「服务端保证」B 组）

## 仍留在清单上的

- `contracts/content-manifest.md`「Open questions」余下两条：**多区域一致性** · **flags 数据源与分桶规则的运营形态**（共同前置仍是 `06-platform-stack.md`）。
- `open-questions/04-content-delivery.md` 余下条目全部是运维形态与选型，本次不受影响。

## 连带

- **`decisions/ADR-0002` 后果段末行同批改写**：「是否本地缓存 flags 以支撑离线开局」→「flags 的客户端持久化形态」+ 已由对侧裁决 + 回链。草稿的落点清单漏了这一处，照原样落笔会留下第三处错误前提副本。**`ADR-0002` 的决策本体（flags 只覆盖 `ContentEnabled`）一字未动**，`decisions/_index.md` 未改动。
- **「剧本文本」一节的「上述三条服务端保证」去计数化**为「A 组的服务端保证」（服务端保证现为 A 组四条）——否则与紧接其后新写的五项能力表在同一屏内自相矛盾。同款治法的先例是 Codex 顶层键去计数化。
- **报文形态零改动**：`flagsSchema` / `manifestSchema` 均不提升，无新增 / 删除 / 改名字段，端点 / 域划分 / 缓存指令 / 签名形态无变化。

## 跨边界

本条**成对落笔**，客户端半见 `game-design-documents/handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md` 与 `game-design-documents/answer-logs/log-client-flag-cache-and-binary-overlay.md`。对侧同批写下 `flags.json` 的落盘纪律（`schemaVersion` · 写入时点绑定「应用」· 失效三条 · 无 TTL · 丢弃 ≠ 删文件）、`Artwork` 的 overlay 收口与非 `.tres` 文件的两道处置。**本库本次无欠账**，`open-questions/cross-boundary.md` 的「待承接」不新增条目。

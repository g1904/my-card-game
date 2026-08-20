# report — architecture-structural-residuals

> worker 自身写入本文件被 harness 拦截，报告由 orchestrator 代为落盘。

- library: `game-design-documents`
- file: `game-design-documents/inbox/solution-draft-architecture-structural-residuals.md`
- 依据构成：**既有推演 12 · 通行做法 2 · 取向选择 5**

## 建议要点

- **最重要的发现：三条里有两条是过期的待决登记，不是设计空白。** ② 的两个子问在 `services/content-service.md` 里**已各有定案**（预埋占位 `Id` = 已否决，两条理由；存档记 `contentVersion` = 已采纳「记两个」`StartContentVersion` / `LastContentVersion`）；① 的主体在 `sync-service.md` + `account-service.md` + `content-service.md` 已写死。`architecture.md` 那三行是「答案写在下游、上游从没划掉」的**台账漂移**。
- **①**：草稿给出 **25 行逐场景降级全景表**（每行注明既有权威出处），提炼三条不变式：**阻塞点穷举 = 4 处**（登录 / 启动 pull 含迁移两变体 / 被挤下线 / 购后 pull 在主菜单内）· **「回退存档点」全表零次出现** · **降级只有三种形状**（进队列 + 退避 / 用上一个已知好值 / 硬阻塞给唯一动作），新失败态必须归入其一。
- **① 的唯一真实空白 = push 侧指数退避的参数形态。** 全库 5 处提「指数退避」，只有 overlay 下载给了参数（`3 次 / 1s·2s·4s`）。建议 `2 s · ×2 · cap 60 s · jitter ±20%`，落 `balance.md` 既有「同步 / 内容管线旋钮」表。**cap < 滞留闸门 180 s 是硬约束** —— 否则「已断线 180 s」的判定可能在一次退避睡眠中途才被发现。
- **①：push 退避没有放弃阈值**，是「绝不回退存档点」+「软阻塞闸门已承担告知与拦人，其触发是次数/时长而非重试耗尽」+「`Upgrade` / `session_revoked` 两态已定为**暂停**而非放弃」三条的合取，**不是取向**。队列淘汰路径仍只有既定三条。
- **①：挂起恢复后不补偿、不追赶、不重置阶梯层级**（滞留计时器已如实记录离线时长，补发只会打出一串同时失败的请求）。
- **②：两问皆已答定，建议该待决条目整条删除。** 新增一条否决记录防日后重提：**不在 `PastEventEntry` 逐事件记 `contentVersion`**（撞「重算得出来的不存」的快照判据；770 B 预算换不回信息）。
- **③：建议单列 `systems/viewmodel.md`（不归 `ux/`）。** 四路同向：**(a)** ViewModel 横切纪律现有 **9 条、散在 7 份文档**，其中第 7 条（`LocalizedText` 不经 `TranslationServer` ⇒ 订阅翻译变更即重组装）**已掉出主题文档层、只存在于 `handoffs/2026-08-13-*`** ⇒ 按「定义在最小公共祖先」判据，最小公共祖先就是 ViewModel 层本身而该落点不存在；**(b)** 服务于全部屏 × 全部服务、不属任何单屏；**(c)** 9 条无一在回答「怎么说」，而 `ux/` 已自我限定为「怎么说、说在哪、说几次」⇒ 归 `systems/`；**(d) 先例**：`system-overview.md`「非服务的横切件」三件套中 game-progression 单列顶层文件、EventBus 归 `architecture.md` 总则 5，判据 = 「内容是不是一条 API 契约总则」，ViewModel 9 条里只有 2 条像总则 ⇒ 落在 game-progression 那一侧。
- **③：建议现在建、不等第一份 UI FR**（纪律 7 已掉出主题文档层，症状「切语言后卡面不变」属**能上线且线上不可见**那一档；`FR-ux-translation-foundation` 已被定为一切含 UI 文案 FR 的 `depends-on`）。
- **零协议影响、零 schema 影响、无对侧库承接项** ⇒ 不写后端库配套草稿。

### 可 derive 的落地面（草稿 A–E 节）
A. `balance.md` 旋钮表 +4 行 · B. `sync-service.md` 断线降级节 3 处增补 · C. `architecture.md` 待决问题三条编辑（回链 / 删除 / 删除）· D. 新建 `systems/viewmodel.md` + `systems/_index.md` 一行 + 三处投影回链 · E. 待答清单侧动作留给 `/analyze-new-ideas`。

## 台账行

> `inbox/_index.md` 实际表头三列 `文件 | status | 说明`，非技能第 6b 步的五列。替换掉 `| *（空）* | — | — |` 占位行：

```
| `solution-draft-architecture-structural-residuals.md` | awaiting-review | `architecture.md` 三条结构残留：断线降级逐场景表 + 退避形态 · 热更「只改不增」两连带项（均已答定，建议收口） · ViewModel 层单列 `systems/viewmodel.md`。评审 5 项取向后 `/analyze-new-ideas` |
```

`open-questions/05-service-contracts.md` 与 `open-questions.md` 本次不动（移出归 `/analyze-new-ideas`；且 ② 若不采纳整条删除，该条不得整条移出）。

## 仍需用户决定（结构化）

**D1 · push 退避的三个初值与「无放弃阈值」形态**
- 问题：push 侧退避从未给过底数 / cap / jitter / 放弃条件，而它是唯一跨启动持续存在的重试通道。
- **A（推荐）** `2 s · ×2 · cap 60 s · jitter ±20% · 无放弃阈值` → 闸门 180 s 内至少两次重试窗口，队列条目永不因次数丢弃
- **B** cap 30 s → 更密、耗电耗流量，收益仅在 30–60 s 恢复的窄区间
- **C** 设放弃阈值（如 24 h 丢队列）→ **违反「绝不回退存档点」**，且需新定义丢弃时如何告知玩家
- 理由：cap < 闸门是硬约束；「无放弃阈值」是三条既有定案的合取；数值本身属「初值待实测」。

**D2 · ViewModel 是否现在单列 `systems/viewmodel.md`**
- **A（推荐）** 现在单列 + 三处回链 → 新增一份顶层文档，纪律 7 归位
- **B** 归 `ux/` → 与 `ux/` 自我限定的职责冲突，日后结构问题会在 `ux/` 里被回答
- **C** 维持现状 → 纪律 7 继续只在 handoff 里，第一次写屏大概率漏掉且线上不可见
- 理由：三条判据 + 一条先例四路同向，无一支持 B/C。

**D3 · 「展示层三层切分」ADR 固化时的主落点**
- **A（推荐）** 主落点 `systems/viewmodel.md`，`architecture.md` 保留三层定义段；**B** 主落点仍 `architecture.md`，新文件只做投影。
- **与 D2 绑定** —— D2 取 C 则本项自动取 B。

**D4 · 25 行全景降级表的去向**
- 问题：评审期是「① 已无空白」的证据，但 14 行的权威在别的文档，落库即第二权威。
- **A（推荐）** 只落三条不变式 + 一行索引，全景表随草稿归档；**B** 另写一份 handoff（无害但无用）；**C** 落进 `sync-service.md` → 明确违反「回链而非复述」，本库已踩过这个坑。

**D5 · ② 的收口力度**
- **A（推荐）** 待决条目整条删除；**B** 改写为一行回链（多一行噪音）。
- 理由：① 取回链是因为答案散在四份文档需要索引导航，② 不需要。

## 前置依赖
- **无硬性前置**，①②③ 可分别采纳、分别落笔。
- 软依赖 1：`systems/viewmodel.md` 的「重组装触发面」与 `auto_translate_mode` 待答项相邻，但该项已写明「两种情况下形态完全相同」⇒ 只影响写法示例，不阻塞。
- 软依赖 2：退避**数值**待实测；**形态**（无放弃阈值 / cap < 闸门 / jitter 叠加 / 挂起不补偿）是推演结论，不待实测。
- derive 就绪度：全采纳后 `systems/architecture.md` 的 partial 卡点由 4 项减至 1 项（只剩 `CostKey` 资源族 element 清单）。**重估归 `/assess-derive-readiness`，本 worker 不判。**

## 与既有决策的张力
1. 「回链而非复述」vs 全景表落库 —— 真实张力，转为 D4。
2. `architecture.md` 的结构权威身份 vs 第三层迁出 —— 迁出后仍持有三层定义与分层理由，符合「定义在最小公共祖先、投影在各落点」；代价是 ADR 候选跨两文档 ⇒ D3。
3. 新增顶层文档 vs「层数不是成熟度指标 / 不封底 / 不为完整性而拆」—— 抗辩：拆的是文档落点非代码层级，触发条件是可数事实（9/7/1）。
4. 无张力项：② 的结论与 `content-service.md` 逐字一致，只收口上游过期登记。

## 越界发现（均未处理）
1. **`inbox/_index.md` 表头与技能第 6b 步描述不一致**（实际三列，技能写五列）。
2. **`systems/architecture.md` 待决问题小节存在模式性过期登记**：本次三条里两条已在下游答定；同小节第一条「cost element 清单」与 `05-service-contracts.md` 多条 08-17 新增项相邻，**未核对**是否同样漂移。建议做一次 `architecture.md ↔ services/*` 待决问题对账。
3. `content-service.md` 三条待决问题一字未动。「flags 频次护栏」与本方案的退避形态主题相邻但机制无关（flags 拉取由搭车信封触发、失败不进队列、不参与退避通道），不会因本方案改变。
4. `ux/error-and-blocking-ux.md` 的常驻同步指示（`UpgradeRequired == true` → `需更新 · 待同步 N`）的**组装归属**是新文件天然要收的**第 10 条**纪律；未纳入 9 条清单（它当前有落点、不属「散落」），仅登记供落笔时留意。

# Answer log error-copy-and-update-prompts

- 日期：2026-08-12
- 来源：`inbox/solution-draft-error-copy-and-update-prompts.md`（`status: decided`，四项取向已裁决）+ `inbox/draft-0812a.md` 末尾的追加裁决两行 → `handoffs/2026-08-12-error-copy-and-update-prompts.md`
- 移出条数：**3**（另新定 1 条边界、新增待答 2 条、新挂后端欠账 1 条）

---

**玩家文案的映射归属（`open-questions/05-service-contracts.md`）** → **UI 层持有，键 = 后端 `code`，载体 = Godot 翻译键。** 否决「服务返回已本地化串」（推翻 08-11b 刚定的「`message` 是英文调试串、永不展示」；后端不掌握界面上下文；改文案要发后端版），判据是「**谁掌握上下文，谁产出**」。**处置表与文案表是两张表、共用同一个键**——`src/Core/` 的 `code → (OpError, 处置)` 表跑在后端适配层，无界面上下文。**`code` → 翻译键是机械变换**（`ERR_` + 全大写 + `.` 换 `_`），**不新建第二张手写对照表**（那会引入「处置表加了行、文案表忘了加」的新失效面）；缺翻译条目 → `PushWarning` + 按 `OpError` 回落四条通用文案（= `class` 默认路径表在文案侧的镜像），并由**启动期审计**一次性扫出。翻译资源 `res://text/errors.csv` **随包分发，不走 overlay / flags**。（归档去向：`ux/error-and-blocking-ux.md`、`systems/architecture.md` 总则 7）

**两条「去更新」提示的呈现形态与去重，含强更硬阻塞屏形态（`open-questions/05-service-contracts.md`）** → **三条提示是同一根严重度轴上的三档，同一时刻只呈现最高一档**（③ 强更全屏阻塞 / ② `UpgradeRequired` 常驻指示改写 + 既定软阻塞模态第二变体 / ① 主菜单可关闭横幅）。承重依据 = `combat-ux.md`「不在最高频操作上加提示，告知由别处的常驻呈现承担」的**第三个实例**。② 复用既有常驻同步指示（**必须换掉「离线」二字**——`Upgrade` 态本会话内永不恢复），① 加**每个 `recommendedVersion` 只提示一次**的频次护栏（落 `user://cache/dismissed-recommended-version.json`）。硬阻塞屏形态 = **一个 `BlockingNoticeScreen` + 三变体表**（不是三个屏）；**「去更新」地址 = 后端下发 `detail.updateUrl` 为主 + 随包 `ChannelConfig` 兜底 + 两者皆无则按钮置灰**，落地前校验 scheme。（归档去向：`ux/error-and-blocking-ux.md`、`ux/screen-flow.md`）

**迁移失败的玩家侧表现（`systems/services/sync-service.md` 待决问题）** → **先分两种情形**：云端 `schemaVersion` 高于客户端支持上界（迁移前即可判定）→ 走**「需更新」变体**，与 `client.version_unsupported` 同因不同径；`schemaVersion` 在范围内但迁移逻辑抛错 → 走**「存档读取失败」变体** + **必上报一次**（真正的程序缺陷态）。**否决「提示重装」**（存档权威在云端，重装不改变任何东西）与**「回退到云端上一个可用版本」**（`revision` 严格单调递增，回退即主动丢进度）。**绝不静默降级放行**——半迁移的 Profile 下一次 push 会把损坏的档写回云端。**不新增硬阻塞点**（两种变体都在「启动 pull」之内）。（归档去向：`systems/services/sync-service.md`、`ux/error-and-blocking-ux.md`）

---

## 同批新定（非清单移出项）

- **`OpResult.Detail` 正式收口为诊断串**，07-27b 的「携带面向玩家的原因串」**作废**，以 08-11b 为准。理由是可机械检查性：`Detail` 兼两个身份则总则 7 那三条承重纪律一条也无法机械检查。连带改写 `account-service.md` 的 `OpError.Compliance` 那一行——合规文案此后同样按 `code` 走 `ErrorText`。（`systems/architecture.md`、`systems/services/account-service.md`）
- **全库 UI 文案统一走 `TranslationServer` 翻译键**（追加裁决，来自 `inbox/draft-0812a.md` 末尾两行，经 interview 确认属本主题）：中文为默认与优先制作列，**英文列全部预设占位符**。这**推翻了原草稿裁决 ② 明写的「本次不裁决、应作为新待答项落位」**——该边界不再是待答项。（`ux/error-and-blocking-ux.md`、`ux/_index.md`、`system-overview.md`）

## 新增待答（2 条）

- **翻译键的铺开节奏**（逐屏改造排期 + 是否需要集中的键命名规范）→ `open-questions/05-service-contracts.md`。
- **英文占位符的具体形态与各 `ERR_*` 的实际措辞** → `open-questions/deferred-content.md`（属文案定稿，随内容搁置）。

## ⚠ 后端欠账（1 条）

- 错误体 `detail` 需新增一个**更新地址字段**（暂记 `detail.updateUrl`；字段名与是否按渠道解析由后端定）。跨库纪律下本次不写后端库，**可与 08-11b 已挂的那笔（`contracts/envelope.md` 删 `/v1/plot/…` 与 `plot.unavailable`）合并成一份后端 handoff**。客户端不因该字段未就绪而阻塞——兜底路径独立成立。

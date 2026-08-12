---
type: solution-draft
date: 2026-08-12
question: 玩家可见错误文案由谁持有（键 = 后端 `code`），以及三条「去更新」提示（软提示 / `Upgrade` 非模态 / 强更硬阻塞）如何呈现与去重
source: open-questions/05-service-contracts.md → 「玩家文案的映射归属」+「两条『去更新』提示的呈现形态与去重」
targets: ux/error-and-blocking-ux.md（建议新建）, ux/screen-flow.md, systems/architecture.md（总则 7 下映射小节）, systems/services/sync-service.md, systems/services/account-service.md
status: distilled
decided: 2026-08-12
reviewed: 2026-08-12 —— 用户裁决四项取向**全部按推荐方案**（去更新地址 = 后端下发为主 + 渠道配置兜底 · 错误文案即刻走翻译键 · 软提示 = 主菜单可关闭横幅 + 每版本一次 · `OpResult.Detail` 收口为诊断串）；提炼时另经 interview 追加裁决**全库 UI 文案统一走翻译键**（中文默认、英文全占位符），该项**推翻**本草稿裁决 ② 留下的「本次不裁决、作为新待答项」边界。
distilled-to: ../handoffs/2026-08-12-error-copy-and-update-prompts.md
---

> **已定案（2026-08-12）。** 用户裁决：三项取向**全部按推荐方案**，`OpResult.Detail` **按推荐收口为诊断串**。本文件的全部提案自此为**已裁决内容**，可直接喂给 `/analyze-new-ideas` 提炼。裁决明细见文末「已裁决」小节；`## 与既有决策的张力` 中那一处已随之闭合。
>
> **连带欠账：** 采纳「去更新地址由后端下发」⇒ **后端侧需要一份对应 handoff**（错误体 `detail` 增更新地址字段）。见「前置依赖」。

# 方案草稿 — 玩家可见错误文案的归属 · 三条版本提示的呈现与去重

## 问题

两条待答项，指向同一条链路的两端，分开答会互相悬空：

1. **玩家文案的映射归属（07-27b 提出 · 08-11b 收窄）。** 08-11b 已定「玩家文案按后端 `code` 分辨，`OpError` 只决定处置路径」「后端 `message` 是英文调试串，永不直接展示」。**剩下的是这份 `code → 玩家文案` 映射由谁持有**：UI 层常量表？本地化表？还是服务返回已本地化串？

2. **三条「去更新」提示的呈现形态与去重（08-11b 新增）。** `X-Recommended-App-Version` 的软提示、`Upgrade` 态的「需更新版本才能同步」非模态提示、`client.version_unsupported` 的强更硬阻塞屏——**三者指向同一个动作**（去更新），不该在屏上叠成两个甚至三个。硬阻塞屏本身的形态（是否跳应用商店、各渠道差异如何吸收）也未定。

**耦合点：** ② 的每一档都要落一句玩家可见文案，而 ① 正是决定这句文案从哪来。② 的三档同时也是 ① 的兜底路径必须覆盖的取值域。

**顺带覆盖：** `sync-service.md` 的待答项「**迁移失败的玩家侧表现**」——08-11b 已判定它与强更硬阻塞屏「同属一类，宜一并定」，本草稿的第 3 节给出它的形态。若本草稿被采纳，该条可一并移出。

## 约束（来自既有设计）

**硬约束（不得松动）：**

- **玩家文案按 `code` 分辨，`OpError` 只决定处置路径。** `client.version_unsupported` 与 `auth.channel_rejected` 同为 `OpError.Auth`，文案完全不同。来源：`open-questions/05-service-contracts.md` + `systems/architecture.md` 总则 7 下「后端错误码 → `OpError`」。
- **`message` 不进玩家可见弹窗**，它与 `requestId` 一起拼进 `OpResult.Detail`，随 `GD.PushError` / `GD.PushWarning` 输出。来源：同上，承重纪律 3。
- **不得解析 `message` 做任何分支**；需要被代码消费的值一律取 `detail`。来源：同上，承重纪律 2。
- **硬阻塞只有两处，且只由已知 `code` 触发**——`auth.session_revoked` 与登录 / 启动 pull 点的 `client.version_unsupported`。**未知 `code` 永远不得新增第三处硬阻塞。** 来源：同上。
- **`Upgrade` 类错误只在登录 / 启动 pull 构成硬阻塞**，其余时机一律降级为非阻塞（非模态提示 + 暂停退避 + 缓冲保留）。来源：`systems/services/sync-service.md`「`Upgrade` 类错误在非闸门点」。
- **软阻塞模态的口径完全不变**，`Upgrade` 只换文案与选项（「去更新 / 退出到主界面」，无「重试」）。来源：同上。
- **`X-Min-App-Version` 仅诊断，客户端不比较、不据此阻塞**；硬闸门判定权在服务端。**客户端不持有兼容矩阵的任何副本。** 来源：`handoffs/2026-08-11b-...` 第 6 节。
- **`X-Recommended-App-Version` 永不阻塞。** 来源：同上。
- **不在最高频操作上加提示，告知由别处的常驻呈现承担。** 来源：`ux/combat-ux.md`「进入战斗前的同步失败不产生任何额外提示」——这条纪律已有两个实例（静默退出的告知责任、进战斗前 flush 失败），本方案是第三个。
- **显示字符串与 `Id` 分离，可改动或本地化而不破坏引用。** 来源：`.claude/rules/data-resource-rules.md` + `handoffs/2026-07-25b-...` 第 1 条。
- **新增内容 = 新增数据，不编辑 switch。** 来源：`.claude/rules/data-resource-rules.md`；08-11b 已把它应用到错误码映射表（「形态是数据表，不是 switch」）。
- **可选缺失 → `PushWarning` + 安全默认值，绝不静默通过。** 来源：`.claude/rules/null-check-rules.md`。
- **云端权威，`revision` 单调递增。** 来源：`decisions/ADR-0003` + `systems/services/sync-service.md`。

**软约束（本方案在其框内取值）：**

- `vision/scope.md` 把「本地化打磨」列在 MVP 范围之外，但同时要求「让展示字符串与 id 分离，以免日后受阻」——**即：现在不做多语言，但现在就不能挡住多语言。**
- 登录渠道优先级为移动端手机 / 邮箱 → 微信 / QQ → 海外，暗示 **Android 多渠道分发**是既定现实（渠道包差异必须有吸收位）。

## 建议方案

### 1. 文案归属：UI 层持有，键 = `code`，载体 = Godot 翻译键

#### 1a. 三选项中先排除一个

`[既有推演]` **否决「服务返回已本地化串」。** 三条独立理由各自充分：

- 08-11b 已定后端 `message` 是**英文调试串**且**永不直接展示**——让服务返回可展示串等于推翻这条刚定案的纪律。
- 后端不知道客户端的语言 / 渠道 / 当前所处界面，同一个 `code` 在登录屏与轮回中途的措辞本就该不同。
- 文案会成为契约的一部分：改一个错别字要发后端版，且新旧客户端拿到同一句话。这与「客户端不持有兼容矩阵、判定权与其输出同处」是**方向相反但同源**的判据——**谁掌握上下文，谁产出**：兼容性判定的上下文在服务端，故服务端判；措辞的上下文在客户端界面，故客户端产。

#### 1b. 处置表与文案表是两张表，不是一张

`[既有推演]` **`src/Core/` 的 `code → (OpError, 处置)` 表不含任何玩家文案。**

它由三个 `HttpXxxBackend` 共用，跑在后端适配层——那里**没有界面上下文**，也不该有。往里塞文案会让一个网络适配器依赖 UI 层。

**但两张表共用同一个键（`code`）**，因此不构成「两份需要同步的真值」：处置表回答「怎么办」，文案表回答「怎么说」，一个 `code` 缺哪一张都各自有兜底路径（见 1d）。

#### 1c. 从 `code` 到文案键是机械规则，不是第二张手写表

`[既有推演]` 这是本方案最要紧的一条。**不新建一张手写的 `code → 翻译键` 对照表**，而是用一条纯机械的变换：

```
code                        →  翻译键
auth.session_revoked        →  ERR_AUTH_SESSION_REVOKED
client.version_unsupported  →  ERR_CLIENT_VERSION_UNSUPPORTED
sync.payload_schema_unsupported → ERR_SYNC_PAYLOAD_SCHEMA_UNSUPPORTED
rate.limited                →  ERR_RATE_LIMITED
```
规则：`ERR_` 前缀 + `code` 全大写 + `.` 替换为 `_`。

**理由：** 手写对照表引入一个新的失效面——「后端加了个 `code`，处置表加了一行、文案表忘了加」。机械规则下这个失效面**不存在**：键必然存在，只可能是**翻译条目缺失**，而那是一个可在启动期一次性扫出的问题（见 1d 的可执行化）。这与 08-11b「新增一个后端 `code` = 表里加一行」的可加性纪律一致，且更进一步——文案侧连那一行都不用加，只用加一条翻译。

#### 1d. 查不到翻译时的兜底 = 四条 `class` 默认路径在文案侧的镜像

`[既有推演]` Godot 的 `tr()` 在缺键时**原样返回键本身**——直接用就会把 `ERR_AUTH_SESSION_REVOKED` 显示给玩家。因此必须包一层：

```csharp
// UI 层（不在 src/Core/）
public static class ErrorText
{
    /// code 优先；缺翻译条目 → PushWarning + 按 OpError 回落到四条通用文案之一。
    public static string For(string code, OpError error);
}
```

- 命中 → 返回该 `code` 的专属文案。
- 缺失 → `GD.PushWarning($"[ErrorText-For] missing translation, code={code}, key={key}")` + 回落。**对上 null-check 规则的「可选缺失 → 警告 + 安全默认值」**，定位标识符是 `code`。
- 回落文案按 `OpError` 给（**不是按 `code`**，因为此时正是不认识这个 `code`）：

  | `OpError` | 兜底文案（示意，实际措辞由文案定稿） |
  |---|---|
  | `Network` | 网络不太顺畅，稍后会自动重试。 |
  | `Auth` | 登录状态需要刷新，请重新登录。 |
  | `Compliance` | 账号当前无法进行此操作。 |
  | `Validation` / 其余 | 操作未能完成，请稍后再试。 |

  这四条**正是 08-11b 那张 `class` 默认路径表在文案侧的镜像**（`Retryable`→`Network`、`Reauth`→`Auth`、`Fatal`/`Upgrade`→`Validation`），无需另立一套判据。

`[既有推演]` **可执行化（阶梯第 2 级：启动期审计）。** 启动期遍历处置表的全部已知 `code`，逐个查翻译条目，缺失者一次性 `GD.PushWarning` 列出。成本一个 `foreach`，把「上线后某个错误弹出一串大写英文键」这类事故挡在开发期。这与 `system-overview.md` 第四节的 BootstrapScreen 断言、`content-service` 的启动期校验同构，属「纪律的可执行化」阶梯上便宜的一级。

#### 1e. 翻译资源随包，不走 overlay 热更

`[既有推演]` 文案落 `res://text/errors.csv`（Godot CSV → `.translation`），**随包分发**：

- overlay 的既定纪律是「**只改不增**」，且只覆盖**内容条目**（`XxxData` 的 `.tres`）。错误文案不是内容条目——不进抽取池、不被存档引用、无 `Id`、不参与 `AllEnabled()`。硬塞进 overlay 会把一条窄而安全的热更通道撑宽。
- flags 层只覆盖 `ContentEnabled`，更无关。
- 代价：改一句错误文案要发版。可接受——**错误文案是本作变动频率最低的一类文本**，且真正需要事后补救的那一项（更新地址）由第 3 节的方案单独解决。

#### 1f. `OpResult.Detail` 正式收口为诊断串（推翻一处旧表述 · **已裁决 08-12**）

`[既有推演]` 07-27b 定的「`OpResult.Detail` 携带**面向玩家的原因串**」与 08-11b 定的「`message` + `requestId` 拼进 `Detail`，随 `GD.PushError` 输出」**已经互相矛盾**——后者事实上把 `Detail` 变成了诊断串，但前一句仍原样留在 `systems/services/account-service.md`「失败映射」段（`OpError.Compliance`（`Detail` 携带面向玩家的原因串，文案由 UI 层决定））。

建议**正式收口为诊断串**，并改掉残留表述：

- `Detail` 的构成 = `code` + `requestId` + 后端 `message`（本地失败则为定位上下文）。
- **UI 永不直接渲染 `Detail`。** 玩家可见文案一律经 `ErrorText.For(code, error)`。
- **`Detail` 是可机械检查的**（阶梯第 2 级）：UI 层不出现「把 `OpResult.Detail` 赋给任何 `Label.Text`」的写法。

**理由：** 若 `Detail` 同时兼两个身份，那三条已定案的承重纪律（`message` 不进弹窗 / 不解析 `message` / 文案按 `code`）就没有任何一处能被机械检查——只要 `Detail` 可能被渲染，英文调试串就随时可能漏到屏上。

#### 1g. `requestId` 需要一个玩家可达的出口

`[通行做法]` 强制在线 + 云端权威下，客服工单的第一件事是定位「这一次请求」。`requestId` 是唯一能做到的标识符，但它现在只进日志——而移动端**导出日志基本不可行**（这正是「设置屏显示同步版本 #1337」那条已定案背后的同一判据）。

建议：**在阻塞屏与错误模态的底部放一行极小字** `#<requestId>`，**可长按复制**（禁 hover-only 可供性，长按是触控等价物）。

- 非模态提示与 toast 级提示**不放**——那是高频呈现，加编号是噪音。
- 与「设置屏的同步版本 #N」同一条纪律：**它是诊断展示，不是玩法数据**，ViewModel 只读一次，不进任何玩法路径。

### 2. 三条版本提示：同一根轴上的三档，同一时刻只呈现最高一档

#### 2a. 去重规则

`[既有推演]` 三条提示不是三件事，是**同一根严重度轴上的三档**：

| 档 | 触发 | 含义 | 呈现 | 阻塞 |
|---|---|---|---|---|
| **③ 强更** | `client.version_unsupported`（登录 / 启动 pull） | 完全不能玩 | **全屏阻塞屏**（第 3 节） | 硬阻塞 |
| **② 需更新** | `UpgradeRequired == true` | 还能玩，但进度上不去 | **常驻状态指示改写** + 软阻塞模态第二变体（口径不变，已定案） | 非模态 / 既定软阻塞 |
| **① 建议更新** | `X-Recommended-App-Version` > 本机版本 | 无实际影响 | **主菜单一条可关闭横幅** | 永不 |

**去重规则一句话：同一时刻只呈现最高一档，低档被高档吸收。**

- `UpgradeRequired == true` ⇒ **不渲染 ① 的横幅**。二者指向同一个动作，而 ② 已经在常驻位置说了同一句话——叠加只是把一条信息说两遍。
- 硬阻塞屏出现时，① 与 ② 的载体都已不在屏上（阻塞屏独占）。
- **承重依据：** `combat-ux.md` 的既定纪律「不在最高频操作上加提示，告知由别处的常驻呈现承担」。本条是它的第三个实例——**当已有常驻呈现在承担告知时，不再另加一条**。

#### 2b. ② 的载体 = 既有的常驻同步指示，不新增第二处常驻 UI

`[既有推演]` 「离线 · 待同步 N」指示已是既定的常驻同步状态呈现，且**在战斗屏内也必须可见**。`UpgradeRequired` 是同一条链路（同步）的另一种失败态，理应同处呈现：

| `UpgradeRequired` | `PendingCount` | 常驻指示 |
|---|---|---|
| `false` | `0` | （不显示） |
| `false` | `N > 0` | `离线 · 待同步 N` |
| `true` | `N ≥ 0` | **`需更新 · 待同步 N`** |

`[既有推演]` **`UpgradeRequired == true` 时必须换掉「离线」二字。** 既定的「离线」措辞隐含「正在重连、会自己好」，但 `Upgrade` 态已定案为**本会话内永不恢复**（退避已暂停，唯一解除条件是重新登录）。继续显示「离线」是在给出一个已知为假的承诺。

- **点按该指示** → 打开更新引导（第 3 节的同一半屏面板）。这给了 `UpgradeRequired` 一个玩家主动了解的入口，而不必再弹任何东西。
- **不在轮回内新增任何模态。** 需要打断玩家的那一次由既定的软阻塞模态第二变体承担（口径不变、只换文案与选项——已定案，本方案不触碰）。

#### 2c. ① 的形态与频次护栏

`[通行做法]` `X-Recommended-App-Version` 每次应答都可能带，没有护栏就会变成「每次同步弹一次」。三条：

- **位置：主菜单一条可关闭横幅**（`MarginContainer` 顶部，安全区内）。**绝不在轮回内 / 战斗内呈现**——对上「不打断进行中的事件」与竖屏触控的最小干扰原则。
- **频次：每个 `recommendedVersion` 取值只提示一次。** 玩家关闭后把该版本号写入 `user://cache/`（与 `flags.json` / `sync-envelope.json` 同处同纪律：原子写、跨启动保留、**不进存档、不进 Profile、不上云**）。服务端推荐版本变了 → 再提示一次。
- **仍需比较 semver。** 注意这与「`X-Min-App-Version` 客户端不比较」**不冲突**：不比较的是**硬闸门**（判定权在服务端），软提示不阻塞任何东西，客户端自己比较是安全的。**复用 `minAppVersion` 已定的规则：semver 三段逐段整数比较，不做字典序**（字典序会判 `1.10.0 < 1.9.0`，且这类 bug 发版后才显形）。

`[既有推演]` **推论（值得单独记一笔）：客户端总共只在两处做 semver 比较**——manifest 的 `minAppVersion`（内容维度）与 `X-Recommended-App-Version`（软提示）。**两处都只导致「不做某事」或「说一句话」，都不阻塞**。协议维度的比较一处也没有。这条可机械检查（全库 semver 比较调用点计数 = 2），是「纪律的可执行化」阶梯上又一级便宜的。

### 3. 阻塞屏：一个屏三个变体，不是三个屏

`[既有推演]` 现存三种「玩家在此走不下去」的终局态，形态上完全同构（全屏 · 不可返回 · 一句原因 · 一个主动作 · 一个退出），应收敛为**一个 `BlockingNoticeScreen` + 一份数据驱动的变体表**，而不是三个各写一遍的场景。理由与「错误码映射是数据表不是 switch」「三个 `HttpXxxBackend` 共用一处头处理点」同源：**多于一处就会出现「一个改了另一个没改」的半配置态。**

| 变体 | 触发 | 文案键 | 主按钮 | 次按钮 | 底部编号 |
|---|---|---|---|---|---|
| **需更新** | `client.version_unsupported`（登录 / 启动 pull） | `ERR_CLIENT_VERSION_UNSUPPORTED` | 去更新 | 退出游戏 | `#requestId` |
| **被挤下线** | `auth.session_revoked` | `ERR_AUTH_SESSION_REVOKED` | 重新登录 | 退出游戏 | `#requestId` |
| **存档读取失败** | `OpError.Migration`（启动 pull） | `ERR_LOCAL_MIGRATION_FAILED` | 重试 | 退出游戏 | `fromVersion→toVersion` |

共同纪律：**全屏、无返回**（系统返回键 = 退出游戏，不是绕过）、**主按钮永不是「继续游玩」**、底部编号可长按复制。

#### 3a. 「去更新」按钮的落点与渠道差异吸收（**已裁决 08-12**）

移动端多渠道分发下，同一个二进制的更新地址随渠道而异（应用商店 deep link / 渠道自有更新 / TestFlight / 网页下载页）。**定案：后端下发为主 + 客户端渠道配置兜底。**

```
优先 detail.updateUrl（后端错误体下发）
  → 缺失 / 断网 / 字段不存在 → 回落随包 ChannelConfig 的渠道地址（PushWarning + 定位上下文）
  → 两者皆无 → 主按钮置灰，仅保留「退出游戏」（绝不给一个跳空的按钮）
```

- **回落路径的形状 = 「可选缺失 → 警告 + 安全默认值」**（`null-check-rules.md`），警告消息带 `code` 与所用地址来源。
- **`ChannelConfig` 是随包数据，不是硬编码**——按导出预设不同（与「平衡数值属数据资源」同构）。
- **`detail.updateUrl` 落地前必须校验 scheme**：只接受 `https://` 与已登记的应用商店 scheme（如 `market://`）。这是内容分发之外的第二个注入面，与 manifest 的「`files[].path` 校验路径穿越」同一条纪律。
- **⚠ 这需要后端错误体新增一个字段** ⇒ 后端侧一份对应 handoff，见「前置依赖」。

#### 3b. 迁移失败的玩家侧表现（顺带答结 `sync-service.md` 的待答项）

`[既有推演]` `sync-service.md` 的原问是「『清晰拒绝』在 UX 上是什么（提示重装？联系客服？回退到云端上一个可用版本？）」。三个候选里**两个应当直接否决**，剩下的形态由既有决策唯一确定：

- **否决「提示重装」。** 存档权威在云端（ADR-0003），重装**不会改变任何东西**——只会让玩家误以为本地有东西可丢，并平白冒一次重下客户端的风险。
- **否决「回退到云端上一个可用版本」。** `revision` 是**严格单调递增**的，回退等于主动丢弃已确认的进度，直接违反云端权威。云端根本不必保留旧版本快照来支持这条路径。
- **`OpError.Migration` 应先分两种情形**，因为绝大多数情况根本不是「存档坏了」：

  | 情形 | 判据 | 表现 |
  |---|---|---|
  | **云端 `schemaVersion` 高于客户端支持上界** | 迁移前即可判定 | **走「需更新」变体**，主按钮「去更新」。这与 `client.version_unsupported` **同因不同径**——客户端太旧，只是这次由本地迁移器先发现 |
  | **`schemaVersion` 在支持范围内但迁移逻辑抛错** | 迁移过程失败 | **走「存档读取失败」变体**，主按钮「重试」；**必上报一次**（`GD.PushError` + `fromVersion→toVersion` + `accountId`） |

  `[既有推演]` 第二种是**真正的程序缺陷态**，处置直接对上 `sync-service.md` 那条已定纪律：「处置相同但它是应当被观测到的异常——静默处理会让它永远看不见」。这也解释了为什么它不能只 `PushWarning` 后放行。

- **绝不静默降级放行。** 迁移失败后带着半迁移的 Profile 进入主菜单，下一次 push 会把一份已损坏的档写回云端——那才是不可逆的。**这是「必需缺失 → 报错退出」而非「可选缺失 → 降级」**（`null-check-rules.md` 的两种失败语义中的前者）。

## 具体形态（可 derive 的落地面）

### 类型与签名

```csharp
// ── UI 层（不在 src/Core/：src/Core/ 无界面上下文） ──────────────────

public static class ErrorText
{
    /// 玩家可见文案。命中 code 的翻译条目则用之；缺失 → PushWarning + 按 error 回落四条通用文案之一。
    public static string For(string code, OpError error);

    /// "auth.session_revoked" → "ERR_AUTH_SESSION_REVOKED"。纯机械变换，无手写对照表。
    internal static string ToTranslationKey(string code);

    /// 启动期审计：遍历处置表全部已知 code，缺翻译条目者一次性 PushWarning 列出。
    public static void AuditTranslations();
}

public enum BlockingNoticeKind { VersionUnsupported, SessionRevoked, MigrationFailed }

public readonly record struct BlockingNoticeSpec(
    BlockingNoticeKind Kind,
    string             BodyTextKey,      // ERR_* 翻译键
    string             PrimaryActionKey, // 去更新 / 重新登录 / 重试
    string             Diagnostic);      // requestId 或 fromVersion→toVersion，长按可复制

// ── sync-service（既有，无新增） ─────────────────────────────────────
// bool UpgradeRequired { get; }   —— 已定案 08-11b，本方案只定义它的呈现
// int  PendingCount    { get; }   —— 已定案
```

### 常驻同步指示的取值表

| `UpgradeRequired` | `PendingCount` | 文本 | 点按 |
|---|---|---|---|
| `false` | `0` | （隐藏） | — |
| `false` | `> 0` | `离线 · 待同步 N` | 无 |
| `true` | 任意 | `需更新 · 待同步 N` | 打开更新引导半屏 |

### 翻译资源

- `res://text/errors.csv` → Godot `.translation`，**随包**，不走 overlay / flags。
- 每行一个 `ERR_*` 键，列 = 语言。MVP 只有一列（中文），**但结构上多语言零成本接入**——这正是 `scope.md`「本地化打磨在范围外，但不能挡住多语言」要的东西。

### 本地缓存

- `user://cache/dismissed-recommended-version.json`（单字段 `dismissedVersion`）。原子写、跨启动保留、**不上云、不进存档 schema**。与 `flags.json` / `sync-envelope.json` 同处同纪律。**不需要按 `accountId` 分区**——它是设备维度的呈现状态，不是账号数据。

### 可机械检查的三条（「纪律的可执行化」阶梯第 2 级）

1. 启动期 `ErrorText.AuditTranslations()` —— 已知 `code` 的翻译条目无缺失。
2. UI 层不出现 `OpResult.Detail` → `Label.Text` 的赋值。
3. 全库 semver 比较调用点恰为 2 处（`minAppVersion`、`X-Recommended-App-Version`）。

## 后果

- **建议在 `ux/` 下新建 `error-and-blocking-ux.md`**，承载本方案全部呈现侧内容，并在 `ux/_index.md` 登记。理由：`screen-flow.md` 已相当长且主线是导航流程；错误 / 阻塞 / 版本提示是一条横切所有屏的独立关注点，塞进导航文档会稀释两边。`screen-flow.md` 只需在「同步状态的两处呈现」处补一句常驻指示的第三种取值并回链。
- `systems/architecture.md` 总则 7 下的映射小节需补一句：**处置表不含玩家文案，文案归 UI 层且键同为 `code`**（把「玩家可见文案由 UI 层决定」这句已有表述落到具体形态）。
- `systems/services/account-service.md`「失败映射」段的「`Detail` 携带面向玩家的原因串」**需改写**（见 1f 的张力）。
- `systems/services/sync-service.md`：「迁移失败的玩家侧表现」待答项可移出；`UpgradeRequired` 补一句呈现落点回链。
- **不改任何存档 schema、不改任何 record、不需要迁移。** 新增的只有一份随包翻译资源与一个设备维度的本地缓存文件。
- **新增一处随包资源类型（`.translation`）**，是本库第一处翻译键落地，会形成先例——**全库 UI 文案是否都走翻译键仍未定**，见「已裁决」②。
- **新增一处随包配置（`ChannelConfig`）** 作为更新地址的兜底来源，按导出预设不同——见 3a。

## 备选方案（已考虑并否决）

- **服务返回已本地化串** —— 推翻 08-11b 刚定的「`message` 是英文调试串、永不展示」；后端不掌握界面上下文；改文案要发后端版。见 1a。
- **手写一张 `code → 翻译键` 对照表** —— 引入「处置表加了行、文案表忘了加」的新失效面。机械变换规则下该失效面不存在。见 1c。
- **文案随 overlay 热更** —— overlay 的安全性建立在「只覆盖内容条目、只改不增、不进校验输入」之上；把非内容文本塞进去会撑宽一条被刻意限窄的通道。见 1e。
- **`UpgradeRequired` 另开一处常驻提示条** —— 与既有「离线 · 待同步 N」并列会出现两条同轴指示；且违反「已有常驻呈现在承担告知时不再另加一条」。见 2b。
- **`X-Recommended-App-Version` 每次拉到就提示** —— 每次同步弹一次，是典型的高频打扰。见 2c。
- **迁移失败 → 回退到云端上一个可用版本** —— `revision` 严格单调递增，回退即主动丢进度，违反云端权威。见 3b。
- **迁移失败 → 提示重装** —— 存档权威在云端，重装不改变任何东西，只制造「我的进度没了」的误解。见 3b。
- **三个阻塞屏各写一个场景** —— 形态完全同构，多于一处必出半配置态。见第 3 节。

## 与既有决策的张力（**已闭合 · 08-12**）

**一处，且是文档内部已存在的矛盾，不是本方案引入的：**

- **`OpResult.Detail` 的身份。** 07-27b 定「携带**面向玩家的原因串**，由 UI 层决定文案」；08-11b 定「后端 `message` + `requestId` 拼进 `Detail`，随 `GD.PushError` 输出」且「`message` 不进玩家可见弹窗」。**两句话不能同时为真**——`Detail` 里既然装着英文调试串，它就不能是面向玩家的串。
- **裁决（用户 · 08-12）：以 08-11b 为准，`Detail` 正式收口为诊断串。** 依据：08-11b 更晚、更具体，且它那三条承重纪律都建立在这个前提上。**07-27b 的「面向玩家的原因串」这一表述作废。**
  - **连带改写：** `systems/services/account-service.md`「失败映射」段的 `OpError.Compliance`（`Detail` 携带面向玩家的原因串，文案由 UI 层决定）。合规拦截的具体原因（实名未完成 / 时长受限 / 账号受限）此后按 `code` 走 `ErrorText`，与其他错误一致——**这实际上更好**：合规文案是最需要精确措辞、也最需要按渠道调整的一类，正是「按 `code` 分辨」的典型受益者。
  - **被否决的替代：** 保留 `Detail` 双身份——那样上述三条承重纪律一条也无法机械检查（只要 `Detail` 可能被渲染，英文串就随时可能漏到屏上）。

## 前置依赖

- **无阻塞性前置依赖。** 本方案不依赖任何仍待答的问题。
- **相邻但不耦合：**
  - `content-service.md` 的「flags 拉取的频次护栏」与本方案 2c 的「软提示频次护栏」**形态同构**（都是「应答头每次都带，需要一个不重复响应的护栏」），若两处一起定可共用一条判据；但各自独立成立，**不必等对方**。
  - `ux/screen-flow.md` 的「元婴界面具体形态」「跨档叙事的呈现位置」等 UX 待答项与本方案无交集。
- **⚠ 需另一侧一份 handoff（已确定 · 08-12 裁决 ① 采纳 B + A 兜底）：** 后端错误体 `detail` 需增一个**更新地址字段**（暂记 `detail.updateUrl`，字段名与是否按渠道解析由后端定）。**本次不写后端库**（跨库纪律：一次运行只作用于一个库）。注意 08-11b 已挂着一笔后端欠账（`contracts/envelope.md` 删 `/v1/plot/…` 与 `plot.unavailable`），**两条可合并为一次后端 handoff**。
  - **本方案不因该字段未就绪而阻塞**：兜底路径（`ChannelConfig`）独立成立，后端字段到位前客户端一律走兜底，行为完全定义。

## 已裁决（2026-08-12 · 用户定案）

**四项全部按推荐方案定案。本小节此后不再是待答项。**

### ① 「去更新」按钮的地址来源 → **后端下发为主 + 客户端渠道配置兜底**

被否决的两个：**纯客户端渠道配置**（客户端太旧时地址也可能已过时，且改地址要发版——而这恰恰是「客户端太旧」的场景）· **纯后端下发**（断网 / 字段缺失时无路可走）。

**采纳理由**与已定案的「客户端不持有兼容矩阵的任何副本」**同源**——判定权在服务端，那么判定的**产物**（「去哪更新」）也应与判定同处；客户端那份只是断网 / 字段缺失时的安全默认值，正好落在「可选缺失 → 警告 + 安全默认值」的形状里。落地形态见 3a。

**连带欠账：后端侧需一份对应 handoff**（错误体 `detail` 增更新地址字段），可与 08-11b 已挂的删 `/v1/plot/…` 合并。

### ② 错误文案的载体 → **即刻走 `TranslationServer` 翻译键**

被否决：**先用 C# 常量表、待全局 i18n 决策时再迁**——键的形态两者一样，**晚迁没有任何收益**，只多出一次改所有调用点的迁移。

采纳后，键与结构现在就位，将来接多语言零改动，直接兑现 `scope.md`「本地化打磨在范围外，但不能挡住多语言」。代价是引入一份 `res://text/errors.csv` + 一次导入配置，**这是本库第一处翻译键落地**。

**边界（本次不裁决）：** 全库 UI 文案（按钮、界面标签、叙事文本）是否都走翻译键，**仍未定**。本次只定错误文案走——因为它的键（`code`）本就由契约给定，是最不需要额外发明的一处。**这条边界应作为一个新的待答项进入 `open-questions/`**（由 `/analyze-new-ideas` 落位，落点建议 `ux/`）。

### ③ 软提示横幅的呈现位置 → **主菜单顶部可关闭横幅 + 每个版本号只提示一次**

被否决：**仅设置屏一行小字**——几乎没有玩家会看到，等于事实上不提示（那不如索性砍掉这一档）。

「建议更新」这一档**予以保留**，去重规则仍是完整三档（见 2a）。频次护栏与缓存形态见 2c 与「具体形态」。

### ④ `OpResult.Detail` 的身份 → **正式收口为诊断串**

07-27b 的「携带面向玩家的原因串」**作废**，以 08-11b 为准。明细与连带改写见「与既有决策的张力」小节（该处张力随此裁决闭合）。

---

## 提炼时的落点提示（给 `/analyze-new-ideas`）

- **新建 `ux/error-and-blocking-ux.md`** 承载全部呈现侧内容（1g · 第 2 节 · 第 3 节），并在 `ux/_index.md` 登记。
- `ux/screen-flow.md`「同步状态的两处呈现」补常驻指示的第三种取值 + 回链。
- `systems/architecture.md` 总则 7 下映射小节：处置表不含玩家文案 + `Detail` 收口为诊断串。
- `systems/services/account-service.md`「失败映射」段：改写 `OpError.Compliance` 那一行。
- `systems/services/sync-service.md`：移出「迁移失败的玩家侧表现」待答项 + `UpgradeRequired` 呈现落点回链。
- **可移出的待答项 3 条：** `open-questions/05-service-contracts.md` 的「玩家文案的映射归属」与「两条『去更新』提示的呈现形态与去重」（含强更硬阻塞屏形态）· `systems/services/sync-service.md` 的「迁移失败的玩家侧表现」。
- **新增待答项 1 条：** 全库 UI 文案是否统一走翻译键（见裁决 ②）。
- **新增后端欠账 1 条：** 错误体 `detail` 增更新地址字段（见裁决 ①）。

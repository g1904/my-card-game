# error-and-blocking-ux

> 错误呈现、版本提示与阻塞屏——一条**横切所有屏**的关注点：玩家可见错误文案的来源、三条「去更新」提示的去重、三种终局态的统一呈现。
>
> 规则侧（错误码 → `OpError` 的处置表、`UpgradeRequired` 的置位 / 清零、迁移失败的错误语义）在 `systems/architecture.md` 总则 7 与 `systems/services/sync-service.md`；本文只管**怎么说、说在哪、说几次**。

## 意图

### 玩家可见文案：UI 层持有，键 = 后端 `code`，载体 = 翻译键（已定案 · 08-12）

- **文案归属在客户端 UI 层。** 判据是「**谁掌握上下文，谁产出**」：兼容性判定的上下文在服务端，故服务端判（客户端不持有兼容矩阵副本）；措辞的上下文在客户端界面，故客户端产。**否决「服务返回已本地化串」**——后端 `message` 已定为英文调试串且永不展示（总则 7 承重纪律 3）；后端不知道客户端的语言 / 渠道 / 当前界面，同一个 `code` 在登录屏与轮回中途本就该有不同措辞；且文案一旦跨边界就成为契约的一部分，改一个错别字要发后端版。
- **处置表与文案表是两张表，共用同一个键 `code`。** `src/Core/` 的 `code → (OpError, 处置)` 表**不含任何玩家文案**——它由三个 `HttpXxxBackend` 共用、跑在后端适配层，那里没有界面上下文，塞文案会让一个网络适配器依赖 UI 层。处置表回答「怎么办」，文案表回答「怎么说」；一个 `code` 缺哪一张都各自有兜底路径。
- **`code` → 翻译键是机械规则，不是第二张手写表：`ERR_` 前缀 + `code` 全大写 + `.` 换 `_`。**

  | `code` | 翻译键 |
  |---|---|
  | `auth.session_revoked` | `ERR_AUTH_SESSION_REVOKED` |
  | `client.version_unsupported` | `ERR_CLIENT_VERSION_UNSUPPORTED` |
  | `sync.payload_schema_unsupported` | `ERR_SYNC_PAYLOAD_SCHEMA_UNSUPPORTED` |
  | `rate.limited` | `ERR_RATE_LIMITED` |

  **理由：** 手写对照表引入一个新的失效面——「后端加了个 `code`，处置表加了一行、文案表忘了加」。机械规则下该失效面**不存在**：键必然存在，只可能是**翻译条目缺失**，而那可在启动期一次性扫出。这比 08-11b 的可加性纪律更进一步——文案侧连那一行都不用加，只用加一条翻译。
- **兜底 = 四条 `class` 默认路径在文案侧的镜像。** Godot 的 `tr()` 缺键时**原样返回键本身**，直接用就会把 `ERR_AUTH_SESSION_REVOKED` 显示给玩家，故必须包一层：

  ```csharp
  // UI 层（不在 src/Core/：那里无界面上下文）
  public static class ErrorText
  {
      /// code 优先；缺翻译条目 → PushWarning + 按 OpError 回落到四条通用文案之一。
      public static string For(string code, OpError error);

      /// "auth.session_revoked" → "ERR_AUTH_SESSION_REVOKED"。纯机械变换，无手写对照表。
      internal static string ToTranslationKey(string code);

      /// 启动期审计：遍历处置表全部已知 code，缺翻译条目者一次性 PushWarning 列出。
      public static void AuditTranslations();
  }
  ```

  缺失时 `GD.PushWarning($"[ErrorText-For] missing translation, code={code}, key={key}")`，**定位标识符是 `code`**（对上 `null-check-rules.md` 的「可选缺失 → 警告 + 安全默认值」）。**回落按 `OpError` 给，不按 `code`**——此时正是不认识这个 `code`：

  | `OpError` | 兜底文案（示意，实际措辞由文案定稿） |
  |---|---|
  | `Network` | 网络不太顺畅，稍后会自动重试。 |
  | `Auth` | 登录状态需要刷新，请重新登录。 |
  | `Compliance` | 账号当前无法进行此操作。 |
  | `Validation` / 其余 | 操作未能完成，请稍后再试。 |

  这四条正是总则 7 那张 `class` 默认路径表在文案侧的镜像（`Retryable`→`Network`、`Reauth`→`Auth`、`Fatal` / `Upgrade`→`Validation`），**无需另立一套判据**。
- **启动期审计（「纪律的可执行化」阶梯第 2 级）。** `ErrorText.AuditTranslations()` 遍历处置表的全部已知 `code` 逐个查翻译条目，缺失者一次性 `PushWarning` 列出。成本一个 `foreach`，把「上线后某个错误弹出一串大写英文键」挡在开发期。与 `system-overview.md` 第四节的 BootstrapScreen 断言、`content-service` 的启动期校验同构。
- **`OpResult.Detail` 是诊断串，UI 永不直接渲染它。** `Detail` = `code` + `requestId` + 后端 `message`（本地失败则为定位上下文）。玩家可见文案一律经 `ErrorText.For(code, error)`。**可机械检查**：UI 层不出现「把 `OpResult.Detail` 赋给任何 `Label.Text`」的写法。若 `Detail` 兼两个身份，总则 7 那三条承重纪律**一条也无法机械检查**——只要它可能被渲染，英文调试串就随时可能漏到屏上。
- Source: `handoffs/2026-08-12-error-copy-and-update-prompts.md`。

### 翻译资源：全库统一走翻译键，随包分发（已定案 · 08-12）

- **全库 UI 文案（按钮、界面标签、叙事文本）统一走 `TranslationServer` 翻译键**，错误文案的 `res://text/errors.csv` 只是第一批。**中文是默认语言与优先制作的一列；英文列全部预设占位符。**
  - 与 `vision/scope.md`「本地化打磨在 MVP 范围外」**不冲突**：现在做的是**键与结构**，不是实际的英文文案——这正是那条软约束要的「现在不做多语言，但现在就不能挡住多语言」。
  - **否决「先用 C# 常量表、待全局 i18n 决策时再迁」**：键的形态两者一样，**晚迁没有任何收益**，只多出一次改所有调用点的迁移。
- **`res://text/errors.csv`**（Godot CSV → `.translation`），每行一个 `ERR_*` 键、列 = 语言。
- **随包分发，不走 overlay / flags 热更。** overlay 的既定纪律是「只改不增」且只覆盖**内容条目**（`XxxData` 的 `.tres`）；错误文案不进抽取池、不被存档引用、无 `Id`、不参与 `AllEnabled()`。硬塞进 overlay 会把一条**被刻意限窄**的热更通道撑宽；flags 层只覆盖 `ContentEnabled`，更无关。
  - **代价：改一句错误文案要发版。可接受**——错误文案是本作变动频率最低的一类文本，而真正需要事后补救的那一项（更新地址）由后端下发单独解决（见下）。
- Source: 同上。

### 三条版本提示：同一根轴上的三档，同一时刻只呈现最高一档（已定案 · 08-12）

三条提示不是三件事，是**同一根严重度轴上的三档**：

| 档 | 触发 | 含义 | 呈现 | 阻塞 |
|---|---|---|---|---|
| **③ 强更** | `client.version_unsupported`（登录 / 启动 pull） | 完全不能玩 | **全屏阻塞屏**（见下） | 硬阻塞 |
| **② 需更新** | `UpgradeRequired == true` | 还能玩，但进度上不去 | **常驻状态指示改写** + 既定软阻塞模态第二变体 | 非模态 / 既定软阻塞 |
| **① 建议更新** | `X-Recommended-App-Version` > 本机版本 | 无实际影响 | **主菜单一条可关闭横幅** | 永不 |

**去重规则一句话：同一时刻只呈现最高一档，低档被高档吸收。**

- `UpgradeRequired == true` ⇒ **不渲染 ① 的横幅**。二者指向同一个动作，而 ② 已在常驻位置说了同一句话——叠加只是把一条信息说两遍。
- 硬阻塞屏出现时，① 与 ② 的载体都已不在屏上（阻塞屏独占）。
- **承重依据：** `ux/combat-ux.md` 的既定纪律「**不在最高频操作上加提示，告知由别处的常驻呈现承担**」。本条是它的第三个实例（前两个：静默退出的告知责任、进战斗前 flush 失败）——**当已有常驻呈现在承担告知时，不再另加一条**。

#### ② 的载体 = 既有的常驻同步指示，不新增第二处常驻 UI

「离线 · 待同步 N」已是既定的常驻同步状态呈现，且**在战斗屏内也必须可见**。`UpgradeRequired` 是同一条链路（同步）的另一种失败态，理应同处呈现：

| `UpgradeRequired` | `PendingCount` | 常驻指示 | 点按 |
|---|---|---|---|
| `false` | `0` | （隐藏） | — |
| `false` | `> 0` | `离线 · 待同步 N` | 无 |
| `true` | 任意 | **`需更新 · 待同步 N`** | 打开更新引导半屏 |

- **`UpgradeRequired == true` 时必须换掉「离线」二字。** 「离线」隐含「正在重连、会自己好」，但 `Upgrade` 态已定案为**本会话内永不恢复**（退避已暂停，唯一解除条件是重新登录成功）。继续显示「离线」是在给出一个**已知为假**的承诺。
- **点按该指示 → 打开更新引导半屏**（与阻塞屏「去更新」同一入口）。这给了 `UpgradeRequired` 一个玩家主动了解的入口，而不必再弹任何东西。
- **不在轮回内新增任何模态。** 需要打断玩家的那一次由既定的软阻塞模态第二变体承担（闸门口径完全不变、只换文案与选项，见 `systems/services/sync-service.md`「`Upgrade` 类错误在非闸门点」）。

#### ① 的形态与频次护栏

`X-Recommended-App-Version` 每次应答都可能带，没有护栏就会变成「每次同步弹一次」：

- **位置：主菜单一条可关闭横幅**（顶部，安全区内）。**绝不在轮回内 / 战斗内呈现**——对上「不打断进行中的事件」与竖屏触控的最小干扰原则。
- **频次：每个 `recommendedVersion` 取值只提示一次。** 玩家关闭后把该版本号写入 **`user://cache/dismissed-recommended-version.json`**（单字段 `dismissedVersion`；与 `flags.json` / `sync-envelope.json` 同处同纪律：原子写、跨启动保留、**不进存档、不进 Profile、不上云**）。服务端推荐版本变了 → 再提示一次。**不按 `accountId` 分区**——它是设备维度的呈现状态，不是账号数据。
- **仍需比较 semver，且与「`X-Min-App-Version` 客户端不比较」不冲突**：不比较的是**硬闸门**（判定权在服务端），软提示不阻塞任何东西，客户端自己比较是安全的。复用 `minAppVersion` 已定规则：**semver 三段逐段整数比较，不做字典序**（字典序会判 `1.10.0 < 1.9.0`，且这类 bug 发版后才显形）。
- **推论（值得单独记一笔）：客户端总共只在两处做 semver 比较**——manifest 的 `minAppVersion`（内容维度）与 `X-Recommended-App-Version`（软提示），**两处都只导致「不做某事」或「说一句话」，都不阻塞**；协议维度的比较一处也没有。**可机械检查**（全库 semver 比较调用点计数 = 2）。

### 阻塞屏：一个屏三个变体，不是三个屏（已定案 · 08-12）

三种「玩家在此走不下去」的终局态形态上完全同构（全屏 · 不可返回 · 一句原因 · 一个主动作 · 一个退出），收敛为**一个 `BlockingNoticeScreen` + 一份数据驱动的变体表**。理由与「错误码映射是数据表不是 switch」「三个 `HttpXxxBackend` 共用一处头处理点」同源：**多于一处就会出现「一个改了另一个没改」的半配置态。**

| 变体 | 触发 | 文案键 | 主按钮 | 次按钮 | 底部编号 |
|---|---|---|---|---|---|
| **需更新** | `client.version_unsupported`（登录 / 启动 pull） | `ERR_CLIENT_VERSION_UNSUPPORTED` | 去更新 | 退出游戏 | `#requestId` |
| **被挤下线** | `auth.session_revoked` | `ERR_AUTH_SESSION_REVOKED` | 重新登录 | 退出游戏 | `#requestId` |
| **存档读取失败** | `OpError.Migration`（启动 pull） | `ERR_LOCAL_MIGRATION_FAILED` | 重试 | 退出游戏 | `fromVersion→toVersion` |

```csharp
public enum BlockingNoticeKind { VersionUnsupported, SessionRevoked, MigrationFailed }

public readonly record struct BlockingNoticeSpec(
    BlockingNoticeKind Kind,
    string             BodyTextKey,      // ERR_* 翻译键
    string             PrimaryActionKey, // 去更新 / 重新登录 / 重试
    string             Diagnostic);      // requestId 或 fromVersion→toVersion，长按可复制
```

**共同纪律：全屏、无返回**（系统返回键 = 退出游戏，**不是绕过**）· **主按钮永不是「继续游玩」** · **底部编号可长按复制**（禁 hover-only 可供性，长按是触控等价物）。

> **⚠ 三个变体 ≠ 三处硬阻塞。** 硬阻塞点仍是既定的**两处**——登录 / 启动 pull 闸门与被后端明确挤下线；迁移失败落在「启动 pull」那一处**之内**。`systems/architecture.md` 总则 7 的「硬阻塞只有两处，且只由已知 `code` 触发；未知 `code` 永不新增第三处」原样成立。

#### 「去更新」按钮的落点与渠道差异吸收

移动端多渠道分发下，同一个二进制的更新地址随渠道而异（应用商店 deep link / 渠道自有更新 / TestFlight / 网页下载页）。**定案：后端下发为主 + 客户端渠道配置兜底。**

```
优先 detail.updateUrl（后端错误体下发）
  → 缺失 / 断网 / 字段不存在 → 回落随包 ChannelConfig 的渠道地址（PushWarning + 定位上下文）
  → 两者皆无 → 主按钮置灰，仅保留「退出游戏」（绝不给一个跳空的按钮）
```

- **采纳理由与「客户端不持有兼容矩阵的任何副本」同源**：判定权在服务端，那么判定的**产物**（「去哪更新」）也应与判定同处；客户端那份只是断网 / 字段缺失时的安全默认值，正好落在「可选缺失 → 警告 + 安全默认值」的形状里（`null-check-rules.md`），警告消息带 `code` 与所用地址来源。
  - **被否决的两个：纯客户端渠道配置**（客户端太旧时地址也可能已过时，且改地址要发版——而这恰是「客户端太旧」的场景）· **纯后端下发**（断网 / 字段缺失时无路可走）。
- **`ChannelConfig` 是随包数据，不是硬编码**——按导出预设不同（与「平衡数值属数据资源」同构）。
- **`detail.updateUrl` 落地前必须校验 scheme**：只接受 `https://` 与已登记的应用商店 scheme（如 `market://`）。这是内容分发之外的**第二个注入面**，与 manifest 的「`files[].path` 校验路径穿越」同一条纪律。
- **⚠ 需后端错误体新增一个更新地址字段**（暂记 `detail.updateUrl`）——见 `backend-design-documents/`。**本方案不因该字段未就绪而阻塞**：兜底路径独立成立，字段到位前一律走兜底，行为完全定义。

#### 迁移失败的玩家侧表现

- **否决「提示重装」。** 存档权威在云端（ADR-0003），重装**不会改变任何东西**——只会让玩家误以为本地有东西可丢，并平白冒一次重下客户端的风险。
- **否决「回退到云端上一个可用版本」。** `revision` 严格单调递增，回退等于主动丢弃已确认的进度，直接违反云端权威；云端也不必为此保留旧版本快照。
- **`OpError.Migration` 先分两种情形**，因为绝大多数情况根本不是「存档坏了」：

  | 情形 | 判据 | 表现 |
  |---|---|---|
  | **云端 `schemaVersion` 高于客户端支持上界** | 迁移前即可判定 | **走「需更新」变体**，主按钮「去更新」。与 `client.version_unsupported` **同因不同径**——客户端太旧，只是这次由本地迁移器先发现 |
  | **`schemaVersion` 在支持范围内但迁移逻辑抛错** | 迁移过程失败 | **走「存档读取失败」变体**，主按钮「重试」；**必上报一次**（`GD.PushError` + `fromVersion→toVersion` + `accountId`） |

  第二种是**真正的程序缺陷态**，处置对上 `sync-service.md` 的既定纪律「处置相同但它是应当被观测到的异常——静默处理会让它永远看不见」。这也解释了它为什么不能只 `PushWarning` 后放行。
- **绝不静默降级放行。** 迁移失败后带着半迁移的 Profile 进入主菜单，下一次 push 会把一份**已损坏的档写回云端**——那才是不可逆的。**这是「必需缺失 → 报错退出」而非「可选缺失 → 降级」**（`null-check-rules.md` 两种失败语义中的前者）。

### 诊断编号的玩家出口（已定案 · 08-12）

强制在线 + 云端权威下，客服工单的第一件事是定位「这一次请求」；`requestId` 是唯一能做到的标识符，但它只进日志，而移动端**导出日志基本不可行**——这正是「设置屏显示同步版本 #1337」那条已定案背后的同一判据。

- **在阻塞屏与错误模态的底部放一行极小字 `#<requestId>`，可长按复制。**
- **非模态提示与 toast 级提示不放**——那是高频呈现，加编号是噪音。
- **纪律：它是诊断展示，不是玩法数据。** ViewModel 只读一次，不进任何玩法路径、不参与判断（与「同步版本 #N」同条纪律）。

## 决策(-> ADR)
> _已敲定的决定链接到 decisions/ADR-####。_

## 待解问题

- **`errors.csv` 之外的翻译键铺开节奏。** 全库统一走翻译键已定；**逐屏改造的排期**（是否随各屏 FR 一并落地、是否需要一次集中的键命名规范）未陈述。Source: `handoffs/2026-08-12-error-copy-and-update-prompts.md`。
- **英文占位符的具体形态。** 「英文文案全部预设占位符」已定；占位符取键名本身、`TODO`、还是机翻初稿，未陈述。Source: 同上。
- **四条兜底文案与各 `ERR_*` 的实际措辞。** 结构与键已定，**逐条中文措辞待文案定稿**（属内容充实，不阻塞结构落地）。

## 提供给
提炼进:`.claude/knowledge/scenes/_index.md`

# error-and-blocking-ux

> 错误呈现、版本提示与阻塞屏——一条**横切所有屏**的关注点：玩家可见错误文案的来源、三条「去更新」提示的去重、三种终局态的统一呈现。
>
> 规则侧（错误码 → `OpError` 的处置表、`UpgradeRequired` 的置位 / 清零、迁移失败的错误语义）在 `systems/architecture.md` 总则 7 与 `systems/services/sync-service.md`；本文只管**怎么说、说在哪、说几次**。

## 意图

### 玩家可见文案：UI 层持有，键 = 后端 `code`，载体 = 翻译键

- **文案归属在客户端 UI 层。** 判据是「**谁掌握上下文，谁产出**」：兼容性判定的上下文在服务端，故服务端判（客户端不持有兼容矩阵副本）；措辞的上下文在客户端界面，故客户端产。**否决「服务返回已本地化串」**——后端 `message` 已定为英文调试串且永不展示（总则 7 承重纪律 3）；后端不知道客户端的语言 / 渠道 / 当前界面，同一个 `code` 在登录屏与轮回中途本就该有不同措辞；且文案一旦跨边界就成为契约的一部分，改一个错别字要发后端版。
- **处置表与文案表是两张表，共用同一个键 `code`。** `src/Core/` 的 `code → (OpError, 处置)` 表**不含任何玩家文案**——它由三个 `HttpXxxBackend` 共用、跑在后端适配层，那里没有界面上下文，塞文案会让一个网络适配器依赖 UI 层。处置表回答「怎么办」，文案表回答「怎么说」；一个 `code` 缺哪一张都各自有兜底路径。
- **`code` → 翻译键是机械规则，不是第二张手写表：`ERR_` 前缀 + `code` 全大写 + `.` 换 `_`。**

  | `code` | 翻译键 |
  |---|---|
  | `auth.session_revoked` | `ERR_AUTH_SESSION_REVOKED` |
  | `client.version_unsupported` | `ERR_CLIENT_VERSION_UNSUPPORTED` |
  | `sync.payload_schema_unsupported` | `ERR_SYNC_PAYLOAD_SCHEMA_UNSUPPORTED` |
  | `rate.limited` | `ERR_RATE_LIMITED` |

  **理由：** 手写对照表引入一个新的失效面——「后端加了个 `code`，处置表加了一行、文案表忘了加」。机械规则下该失效面**不存在**：键必然存在，只可能是**翻译条目缺失**，而那可在启动期一次性扫出。它比「新增一个 `code` = 表里加一行」的可加性纪律更进一步——文案侧连那一行都不用加，只用加一条翻译。
- **兜底 = 四条 `class` 默认路径在文案侧的镜像。** Godot 的 `tr()` 缺键时**原样返回键本身**，直接用就会把 `ERR_AUTH_SESSION_REVOKED` 显示给玩家，故必须包一层：

  ```csharp
  // UI 层（不在 src/Core/：那里无界面上下文）
  public static class ErrorText
  {
      /// 二级键优先（reasonKey 非空且有翻译条目）→ 一级键（code）→ 按 OpError 回落到四条通用文案之一。
      /// 二级键缺条目时静默走一级键（后端可随时新增 reasonKey，那不是缺陷）；
      /// 一级键【在默认语言 zh 下】无条目才 PushWarning
      /// ——不是「当前 locale 解析不出值」：en 未翻译期每个 code 都会命中，那是噪音不是缺陷。
      public static string For(string code, string reasonKey, OpError error);

      /// "auth.session_revoked" → "ERR_AUTH_SESSION_REVOKED"。纯机械变换，无手写对照表。
      internal static string ToTranslationKey(string code);

      /// 一级键 + reasonKey 按大写字母切分转 UPPER_SNAKE。
      /// ("auth.session_revoked", "SignedInElsewhere") → "ERR_AUTH_SESSION_REVOKED_SIGNED_IN_ELSEWHERE"。
      internal static string ToTranslationKey(string code, string reasonKey);

      /// 启动期审计（双向，见下方「键命名规范」）：
      ///   正向 —— 遍历处置表全部已知 code，缺翻译条目者一次性 PushWarning 列出；
      ///   反向 —— 扫 ERR_ 分区的消息表，凡不以任何已知 code 的像为前缀的 ERR_* 键，一次性 PushWarning 列出。
      public static void AuditTranslations();
  }

  // 全分区的英文覆盖率审计不在 ErrorText 内——它扫全库分区、与错误码处置表零耦合。
  public static class TranslationAudit
  {
      /// 全 res://text/ 分区的 en 覆盖率审计。
      /// 数据源 = TranslationServer.GetTranslationObject(locale) 的消息表（非 .csv 源文件）。
      /// 未翻译 := 键不在 en 消息表中，或其值为空 / 全空白。
      /// 伪翻译 := en 值含 CJK 字符 → 不计入分子，单列一条 PushWarning。
      /// zh 值缺失 / 空 → PushError（键 + 所属分区文件）。
      /// 输出：按分区一行 + 合计一行，单条 GD.PushWarning。
      public static void AuditCoverage();
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
- **启动期审计（「纪律的可执行化」阶梯第 2 级）。** `ErrorText.AuditTranslations()` 遍历处置表的全部已知 `code` 逐个查翻译条目，缺失者一次性 `PushWarning` 列出。成本一个 `foreach`，把「上线后某个错误弹出一串大写英文键」挡在开发期。与 `system-overview.md` 第四节的 BootstrapScreen 断言、`content-service` 的启动期校验同构。**它是双向的**——反向那一半的理由见下方「键命名规范」的 `ERR_` 禁令。
- **三条审计的数据源统一为 `TranslationServer.GetTranslationObject(locale)` 的消息表，不读 `res://text/*.csv` 源文件。** `.csv` 是 Godot 的导入源文件、**不随导出包分发**（包内只有 `.translation`）；读源文件的审计在发布版中无从执行，而它失效时**没有任何症状**。换用消息表后判据一字不改（反向仍是前缀匹配），且省掉一个 CSV 解析器。
- **`TranslationAudit.AuditCoverage()` 的三条判定：**

  | 判据 | 条件 | 处置 |
  |---|---|---|
  | **未翻译** | 键不在 `en` 的消息表中 **或** 其值为空 / 全空白 | 计入分母，**不逐条告警** |
  | **伪翻译** | `en` 的值**含 CJK 字符** | **不计入已翻译分子** + 单列一条 `PushWarning` 列出前 N 个键 |
  | **已翻译** | 其余（非空、无 CJK） | 计入分子 |

  - **「缺键 **或** 空值」是刻意的双判据，不是冗余。** CSV 导入器对空单元格是「跳过该键」还是「写入空串」属落地细节；两种行为下本判据结论完全相同，故本形态**不依赖那次实测**、也不被它阻塞。
  - **伪翻译判据复用 CJK 检测**，是「UI 文案字面量审计」那条判据的第二次使用。它挡住的是覆盖率虚高的最后一条路径（`en` 列复制了 `zh` 原文），而那条路径**同样零症状**。
  - **输出与内容层的覆盖率审计同形**（`en: 12 / 840 条目已翻译`）：按分区一行 + 合计一行，让「英文版做到哪一步了」成为一个能一眼读到的数。
  - **覆盖率审计覆盖全部 `res://text/*.csv` 分区**；正向 / 反向两条仍只针对 `ERR_` 分区（它们的判据本就依赖处置表的 `code` 全集）。
  - **`zh` 列为空 → `PushError`（键名 + 所属分区文件），但不 `throw`。** 与内容层的「`PushError` + `throw`」**刻意不对称**：内容层 `throw` 是因为坏内容会进抽取池、被存档引用，把错误扩散到不可逆处；缺一条 UI 文案只影响**一屏的一处显示**，回落后仍是一个可操作的界面。这正是 `null-check-rules.md` 两种失败语义的分界（内容层一侧的判据见 `systems/services/content-service.md`，不受本条影响）。
  - **`en` 缺失一律不阻塞、不加编译期或构建期闸门。** 它是可选缺失、回落完全可用，且当前每一条都缺 `en`——任何硬闸门会让游戏直接起不来。本机验证走 Godot 编辑器运行、不假定额外工具在 PATH 上（`.claude/rules/environment-rules.md`），故不另开构建期工具链；**否决「做成 EditorScript 手动跑」——脱离启动链就没人会记得跑。**
- **`OpResult.Detail` 是诊断串，UI 永不直接渲染它。** `Detail` = `code` + `requestId` + 后端 `message`（本地失败则为定位上下文）。玩家可见文案一律经 `ErrorText.For(code, reasonKey, error)`。**可机械检查**：UI 层不出现「把 `OpResult.Detail` 赋给任何 `Label.Text`」的写法。若 `Detail` 兼两个身份，总则 7 那三条承重纪律**一条也无法机械检查**——只要它可能被渲染，英文调试串就随时可能漏到屏上。

### `detail.reasonKey`：二级措辞的键，且必须有兜底

有几个 `code` 的玩家侧含义**不由 `code` 单独决定**——后端在 `detail` 里给一个 `reasonKey` 区分同一个 `code` 下的不同情形（会话吊销的触发源、合规拦截的规则、昵称被拒的理由）。三条纪律：

- **一级文案仍按 `code` 取**，`reasonKey` 只驱动二级措辞。这保证任何一个 `code` 在 `reasonKey` 缺失或不认识时仍有话可说。
- **未知 `reasonKey` 必须回落到该 `code` 的一级文案**，不得留空、不得把键本身显示出来。这与「未知 `code` → 按 `class` 降级」同构，理由也同源：后端新增一个 `reasonKey` **不应要求客户端同批发版**。
- **`reasonKey` 的取值集合由后端契约给出，客户端不维护第二份清单。** 客户端只维护「已知取值 → 二级措辞」的翻译条目，未列出的一律走上一条。
  取值表与形态的权威在 `backend-design-documents/contracts/auth.md` §10（`auth.session_revoked` 与 `auth.nickname_rejected` 各一张取值表 · 形态 PascalCase 锁死）**——连条数也不在本库记**，写死一个数目就是又一份会漂移的副本与 `backend-design-documents/contracts/compliance.md` §5（`compliance.*` 四条码各自的取值）。**本库不复述取值**——复述即制造第二权威，而这份表按契约设计**会持续扩张**。

**二级文案键同样是机械变换，不是第二张手写表。** 一级键（`code` 的像）+ `_` + `reasonKey` 按大写字母切分转 UPPER_SNAKE：

| `code` + `reasonKey` | 二级翻译键 |
|---|---|
| `auth.session_revoked` + `SignedInElsewhere` | `ERR_AUTH_SESSION_REVOKED_SIGNED_IN_ELSEWHERE` |
| `compliance.playtime_blocked` + `MinorDailyLimit` | `ERR_COMPLIANCE_PLAYTIME_BLOCKED_MINOR_DAILY_LIMIT` |
| `auth.session_revoked` + `SessionExpired` | `ERR_AUTH_SESSION_REVOKED_SESSION_EXPIRED` |

**`SessionExpired` 的措辞取最平淡的例行口吻，且不附原因句。** 它与同一个 `code` 下的其余取值（被挤下线、被运营吊销）在情绪上必须明确区分：登录链到期是一次**完全正常的例行事件**——玩家没有做错任何事，也没有第二台设备在动他的账号。故只说要做什么（「登录状态已过期，请重新登录」），**不解释为什么**：一句「为保障账号安全，登录状态会定期过期」读起来更安抚，却把一个后端可调旋钮（链的寿命上限）写进了翻译条目，改值时两处不同步即**静默失准**，而没有任何机制会报错。触发条件与旋钮见 `backend-design-documents/contracts/auth.md` §5b，**本库不复述**。

与上方 `code → ERR_*` 是同一条纪律的第二次兑现，理由也同源：手写对照表引入「后端加了个 `reasonKey`、文案表忘了加」这一失效面，机械规则下它不存在——只可能是翻译条目缺失，而那走未知回落。**`ErrorText.For` 因此吃三个参数**（见下方代码块）。

**连带：反向审计的判据必须放宽为「前缀匹配」，否则每个二级键都会被误报。** `ERR_` 分区的一个键合法当且仅当它**等于**某个已知 `code` 的像，**或**以某个已知 `code` 的像为前缀、其后为 `_` + 一段 UPPER_SNAKE 后缀。

- **这仍然挡住了禁令要防的那件事**：手写 `ERR_LOGIN_FAILED` 在没有 `code = "login.failed"` 时不匹配任何已知 `code` 的像，照样被报出。
- **且它不要求客户端持有 `reasonKey` 清单**——放宽到「前缀 + 任意 UPPER_SNAKE 后缀」正是为了让上一条（不维护第二份清单）成立。二者若都要，反向审计就只能校验到一级键这一层，这是**刻意接受的精度损失**：二级键写错一个后缀的后果是该条文案走未知回落，属可降级失败；而撞键是静默显示错文案，属不可见失败。**挡住不可见的那个，放过可降级的那个。**

**另一类不参与文案的 `detail` 字段：渠道原始错误码。** 它随渠道版本漂移，**客户端不解析、只随日志上报**——文案按 `code` 取，不因它分叉。这与「客户端不解析 `message`」是同一条。

### 翻译资源：全库统一走翻译键，随包分发

- **全库 UI 文案（按钮、界面标签、叙事文本）统一走 `TranslationServer` 翻译键**，错误文案的 `res://text/errors.csv` 只是第一批。**中文是默认语言与优先制作的一列；英文列未翻译时留空。**
  - 与 `vision/scope.md`「本地化打磨在 MVP 范围外」**不冲突**：现在做的是**键与结构**，不是实际的英文文案——这正是那条软约束要的「现在不做多语言，但现在就不能挡住多语言」。
  - **否决「先用 C# 常量表、待全局 i18n 决策时再迁」**：键的形态两者一样，**晚迁没有任何收益**，只多出一次改所有调用点的迁移。
- **`res://text/errors.csv`**（Godot CSV → `.translation`），每行一个 `ERR_*` 键、列 = 语言。
- **随包分发，不走 overlay / flags 热更。** overlay 的既定纪律是「只改不增」且只覆盖**内容条目**（`XxxData` 的 `.tres`）；错误文案不进抽取池、不被存档引用、无 `Id`、不参与 `AllEnabled()`。硬塞进 overlay 会把一条**被刻意限窄**的热更通道撑宽；flags 层只覆盖 `ContentEnabled`，更无关。
  - **代价：改一句错误文案要发版。可接受**——错误文案是本作变动频率最低的一类文本，而真正需要事后补救的那一项（更新地址）由后端下发单独解决（见下）。

#### 未翻译的形态 = `en` 单元格留空，不写任何哨兵值

**一行未翻译时写成 `KEY,"中文文案",`。** 「未翻译」的判据是**该 locale 下没有可用值**，而不是「该 locale 下有一个约定好的特殊值」——这与内容层「`Entries` 只有 `zh` 键」在语义上逐字同构，两层载体不同（CSV 行 vs 字典键）但判据同一条。**覆盖率审计因此不需要第二套「什么算占位符」的识别规则。**

| 状态 | 行 | 审计判定 |
|---|---|---|
| 未翻译（当前的默认状态） | `COMMON_CONFIRM,"确定",` | 未翻译，计入分母 |
| 已翻译 | `COMMON_CONFIRM,"确定","Confirm"` | 已翻译，计入分子 |
| **伪翻译（禁止）** | `COMMON_CONFIRM,"确定","确定"` | CJK 命中 → `PushWarning`，**不计入分子** |
| **默认语言缺失（坏数据）** | `COMMON_CONFIRM,,"Confirm"` | `PushError` + 键名 + 分区文件 |

**两条连带禁令（不写下来本形态会被绕过）：**

- **`en` 列绝不复制 `zh` 原文。** 这是覆盖率恒读 100% 最容易发生的路径（复制粘贴整列），且英文玩家看到中文、**零症状**。由伪翻译告警挡住。
- **`en` 列绝不写键名本身。** 它是第 1 列的机械像，手写一份即「能机械变换的绝不建第二张手写表」的正面违反；引擎缺值时本就返回键名，显式写一遍是纯冗余；且覆盖率审计会被迫加一条「值 == 键」的识别规则，漏判时玩家直接看到 `ERR_AUTH_SESSION_REVOKED`。

**同样被排除的三种非空占位形态，理由各自独立且都仍然承重：**

- **`TODO` 一类哨兵**：形态一定会漂移（`TODO` / `TODO:` / `todo` / 带原文），审计要为它维护一套识别规则，漏判时玩家看到 `TODO`；而它相对空单元格**没有任何信息增量**——「哪些没翻」由覆盖率审计报，不需要写在每一行里。
- **机翻初稿**：覆盖率恒读 100%，正是本形态要防的那件事；且机翻与人工翻译**在值的形态上不可机械区分**，要区分就得再加一列状态，打破「两列封顶」。产出英文文案属本地化打磨，在 MVP 范围外（`vision/scope.md`）。若日后确要机翻打底，它的正确形态是一次**批量填值 + 单独的质量状态跟踪**，而不是让占位符字段兼两个身份。
- **在 `tr()` 外自包一层 `UiText.Get(key)` 自己回落**：引擎已提供回落能力，包一层等于把一条零成本的引擎配置换成一个全库必须遵守的调用纪律，且它挡不住 `.tscn` 里直接写 `text = "KEY"` 的自动翻译路径。

**回落靠引擎配置，不在调用点写分支。** `project.godot` 设 `internationalization/locale/fallback = "zh"`：`en` 下缺值 → 引擎自动回落 `zh` 串，**调用点零分支**，与内容层 `LocalizedText.Get()` 缺 `en` 静默回落 `zh` 完全一致。**不逐次警告**——未翻译期每一条 UI 文案在 `en` 下都会命中回落，逐次 `PushWarning` 会刷屏并淹掉真告警；留痕责任全部交给一次性的覆盖率审计。**不设回落则英文 locale 下每一条文案都会显示成大写英文键，比显示中文更糟。**

### 翻译键的铺开：没有改造期，只有一条起手纪律

- **「逐屏改造如何排期」这个提法被否掉——它默认了一个不存在的存量迁移场景。** `game-feature-branch/` 当前没有任何 `.tscn` / `.cs` / `.tres`，**UI 文案的存量是零**。定案改为一条纪律：**每个屏从写下第一行起就用翻译键，全库不新增任何 UI 文案字面量。**
  - 「先用 C# 常量表、待全局 i18n 决策时再迁」同样否决：晚迁没有任何收益，只多出一次改所有调用点的迁移——连「先写字面量」这一步都不该发生。
  - **推论：「随各屏 FR 一并落地」与「集中做一次」不是二选一。** 前者描述的是纪律的作用方式（每份含 UI 文案的 FR 天然带着它），后者要处理的批量迁移根本不会产生。
- **唯一需要集中做的是一次性基建 `FR-ux-translation-foundation`**，五件事，此后再不集中：建 `res://text/` 与首批分区 CSV（至少 `errors.csv` + `common.csv`）· 在 `project.godot` 注册翻译资源并设**默认 locale `zh`** 与 **`internationalization/locale/fallback = "zh"`** · 落 `ErrorText`（`For` / `ToTranslationKey` / `AuditTranslations`）与 `TranslationAudit`（`AuditCoverage`）· 落下方的键命名规范与分区表 · 落下方三条审计。
  - **三条启动期审计的调用顺序：`ErrorText.AuditTranslations()` → `TranslationAudit.AuditCoverage()` → CJK 字面量审计。** 前两条按「先查键在不在、再查值翻没翻」的因果链排；**带编辑器守卫的 CJK 那条排最后**，这样编辑器与发布版的日志前缀完全一致，排障时不必先分辨自己在哪个环境。
  - **它横切所有屏，不挂在任何一个屏下**——挂在某个屏下会让第二个屏的 FR 依赖第一个屏的 FR，凭空造出一条与设计无关的构建顺序。与「`ErrorText` 不放 `src/Core/`、放 UI 层」同一种归位思路：**按「它服务于谁」定位，而不是按「谁先用到它」。**
  - 它是**一切含 UI 文案的 FR 的 `depends-on`**。

### 键命名规范：三条 + 一条禁令

规范越长越没人遵守。三条足以覆盖已知的全部情形：

1. **`SCREAMING_SNAKE_CASE`**（全大写 + 下划线分词），**恒 ASCII**。既有 `ERR_*` 已是此形态，不另立第二套。
2. **`<PARTITION>_<CONTEXT>_<NAME>`**，首段是分区前缀。例：`COMBAT_BUTTON_END_TURN`、`LOGIN_TITLE`、`SYNC_STATUS_OFFLINE_PENDING`。
3. **一个分区 = 一个 CSV 文件**（`res://text/<partition>.csv`，文件名小写）。收益是分工与 diff：改战斗屏文案只动 `combat.csv`，不与别人在同一个巨型 CSV 上打架。

**分区表（开放表，随屏幕落地增补，不是封闭枚举）：**

| 分区前缀 | 文件 | 覆盖 |
|---|---|---|
| `ERR_` | `errors.csv` | **机械生成，见下方禁令** |
| `COMMON_` | `common.csv` | 通用按钮 / 确认 / 取消 / 返回 / 数量单位 |
| `BOOT_` | `boot.csv` | BootstrapScreen、阻塞屏的非 `ERR_` 部分（按钮、诊断行标签） |
| `LOGIN_` | `login.csv` | LoginScreen、T&S、渠道登录 |
| `MENU_` | `menu.csv` | 主菜单、篇章切换、更新横幅 |
| `SYNC_` | `sync.csv` | 常驻同步指示、软阻塞模态、更新引导半屏 |
| `EVENT_` | `event.csv` | EventMenu、事件选项框架文案（**不含事件正文——那是内容层**） |
| `COMBAT_` | `combat.csv` | CombatScreen、出牌 / intent / 结算面板的框架文案 |
| `PROFILE_` | `profile.csv` | PlayerProfile / CharacterProfile 面板、图鉴族、成就 |
| `SETTINGS_` | `settings.csv` | 设置屏（含同步版本 `#N` 的标签）。首批十个键：`SETTINGS_TITLE` · `SETTINGS_SECTION_AUDIO` · `SETTINGS_VOLUME_MASTER` / `_MUSIC` / `_SFX` · `SETTINGS_SECTION_COMBAT` · `SETTINGS_FAST_ANIMATION` · `SETTINGS_SECTION_LANGUAGE` · `SETTINGS_SYNC_REVISION` / `_NONE` |
| `STORE_` | `store.csv` | 礼包屏：标题、权益条目、再次购买说明、入口不可用说明、购买按钮、**购买处理态与兑现结果态的全部文案** |

> **边界必须写在规范里，否则分区表会被误用：分区划的是「界面」，不是「内容域」。** `EVENT_` 装的是选项框的按钮与标题，**事件正文一个字也不进**——正文归内容层（`ux/_index.md` 的四问判据）。这条不写清楚，第一个写事件屏的人就会把正文塞进 `event.csv`。

#### 禁令：`ERR_` 分区保留给机械变换，人不得手写 `ERR_` 开头的键

`ERR_*` 与其余分区有一条**本质差别**：它的键不是人取的，是 `code → ERR_ + 全大写 + `.`→`_`` 的**像**。若允许有人手写一个 `ERR_LOGIN_FAILED`，而后端某天新增 `code = "login.failed"`，两者会**撞进同一个键**——一条后端错误会静默显示成一句为别处写的文案。这类 bug 发版后才显形，且现场看不出异常。

- **`ERR_` 分区的每一个键都必须是某个已知 `code` 的像，或该像加一段 `reasonKey` 后缀**（二级键，见上方「`detail.reasonKey`」）。故 `ErrorText.AuditTranslations()` **是双向的**：正向查「已知 `code` 缺不缺条目」（**只查一级键**——客户端不持有 `reasonKey` 清单，二级键无从正向枚举），**反向扫 `ERR_` 分区的消息表，凡不以任何已知 `code` 的像为前缀的 `ERR_*` 键 → `PushWarning` 列出**。成本同样是一个 `foreach`，把撞键挡在开发期。
- **非错误场景要表达失败**（如「储物袋已满」这类**本地业务拒绝**，它没有后端 `code`）→ 走所属分区的普通键（`PROFILE_MAGICPACK_FULL`），**不占 `ERR_` 前缀**。

### 灰态判据：区分「玩家可能有意选择的失败」与「必然无结果的操作」

> 库内此前有两条看似相反的规则，本条给出它们的分界，否则后来者会读成矛盾。

| 情形 | 呈现 | 判据 |
|---|---|---|
| **事件选项付不起 `selectCost`** | **不设灰态**；`selectCost` **只在寿元 Band 2（< 10%）如实展示**，常态档不显示 | 「明知是死路仍然走」是**有意义的玩法决策**，与「打不过也得打」同构——灰掉它等于替玩家做决定。而「明知」所需的信息只在寿元濒尽时才真正起作用，故精确值随红字倒数同时开启（权威见 `systems/adventure-event/common-properties.md`） |
| **礼包购买入口的四条前置不满足** | **置灰 + 一行说明，不隐藏** | 玩家点下去只会撞上一个**必然失败的流程**，没有任何决策价值 |
| **有一笔购买待兑现时的「开始新轮回」** | **置灰 + 一行说明，不隐藏** | 同上；且此刻的等待是有终点的（一直重试直到发放成功），说明文案须让玩家看见它在推进 |
| **Exchange 刷新按钮的池前置不满足**（可产出 offer 数 < 1） | **置灰 + 一行说明，不隐藏** | 刷了也必然是空店，没有任何决策价值；且刷新要花 jade ⇒ 不拦就把失败点留在付费之后。**只拦「必然空店」这一种**——刷出一个商品更少的店是正常方差，不提示、不置灰（判据见 `systems/adventure-event/exchange/_index.md`） |

- **判据一句话：灰态禁令适用于「玩家可能有意选择的失败」，不适用于「必然无结果的操作」。**
- **不隐藏而是置灰**：隐藏会让玩家以为功能消失且无处解释，而闸 ② 触发时后端已收到 `PushError` 上报——**正在被修的运营事故不该表现为「功能不见了」**。
- 说明文案走**所属分区**的普通键（礼包入口 → `STORE_UNAVAILABLE_POOL` / `STORE_UNAVAILABLE_SYNC` / `STORE_UNAVAILABLE_PENDING`；主菜单「开始新轮回」→ `MENU_` 分区；Exchange 刷新 → `EVENT_REROLL_UNAVAILABLE_POOL`），**不占 `ERR_` 前缀**——它们是本地业务拒绝，没有后端 `code`。

### 语言开关只有一个：启动期把 locale 归一到封闭二值

**语言范围封顶为中英双语 `zh` / `en`，不带地区码；`en` 列当前整体未翻译（一律留空，见上方「未翻译的形态」）。**

- **`res://text/` 的 CSV 列名、内容层 `LocalizedText.Entries` 的键、`TranslationServer.GetLocale()` 的返回值必须是同一套 locale 标识符。** 两层不同载体、不同热更权限，但**共用同一个语言开关**——内容层不另设一个语言设置，否则设置屏会长出两个开关，玩家能把界面切成英文而卡面留在中文。内容层一侧见 `systems/common-properties.md`「内容文本的多语言形态」。
- **归一发生在启动期、登录之前，且只发生一次（单点）：**

  ```
  1. 读 user://cache/device-settings.json 的 locale（设备本地覆盖值）
       └ 缺失 / 解析失败 / 值不在 {zh, en} → PushWarning + 跳到 2
  2. 无覆盖值 → 读系统 locale
  3. 取主语言子标签（zh_CN / zh_TW → zh，en_US → en）
  4. 非 zh / en 一律置 zh
  5. TranslationServer.SetLocale(该二值)
  ```

  此后 CSV 与 `LocalizedText` 两层直接吃已归一的 `GetLocale()`，**各自零分支**。**第 1 步是唯一的可选覆盖来源，单点不变**——它必须在登录之前可读，故设备本地那份文件不得依赖任何服务（时序约束与文件形态见 `systems/player-profile/game-setting.md`）。
- **游戏内的语言设置项写入的也是同一个单点。** 设置屏改语言 = 写 `device-settings.json` + **调用同一个归一入口重跑一次**；**设置屏不得自己调 `TranslationServer.SetLocale`**，否则第 4 步那条兜底会在设置路径上被绕过。切换不需要重启应用。设置屏的语言行首批隐藏，理由与解除条件见 `systems/player-profile/game-setting.md`。
  - **为什么必须写下这条：** Godot 默认把 locale 设为系统 locale，真机上 `GetLocale()` 很可能返回 `zh_CN` / `en_US`，与封闭二值的键域对不上 ⇒ **每一条内容文案在所有真机上都命中「缺键 → 回落 `zh`」**；而回落已定为**静默**（见 `content-service.md`），这条失败因此没有任何症状。
- **归一与回落是两件事，各管一半，互不替代。** 归一决定 `GetLocale()` 落在封闭二值的哪一个上（上面五步）；**fallback locale 决定该 locale 下缺值时取哪一列**（`en` 缺值 → `zh`）。少了归一，真机会拿着 `zh_CN` 去查一个不存在的列；少了回落，`en` 下会满屏显示大写英文键。
- **CSV 列 = `key, zh, en`，两列封顶。** `zh` 为默认与优先制作列。**不设繁体分列**：简繁差异是机械的，日后确需繁体走**简繁转换**（同一套 `zh` 文本经转换呈现），而非再开一列——同一条「能机械变换的绝不建第二张手写表」（`code → ERR_*` 是它的第一例）。

### UI 文案字面量审计：阶梯第 2 级，编辑器内运行

按「纪律的可执行化」的选级判据，「UI 层写了中文字面量」属**能上线且线上不可见**——中文玩家完全看不出差别，只有做英文版时才整片暴露。该档必须做到第 1 / 2 级。

- **第 1 级（最短路径即正确）在这里代价过高，否决。** 要让「写字面量」在语言层不可能，得禁止 UI 代码直接触碰 `Label.Text` / `Button.Text`、包一层只吃键的 setter。这与 Godot 的**编辑器内直接编辑 `text` 属性**这一最自然的工作方式对着干，且 `.tscn` 里的字面量它一条也挡不住。
- **取第 2 级：一次审计。** 扫 `res://scenes/**.tscn` 与 `res://src/UI/**.cs`，命中「文本属性 / 赋给 `.Text` 的字符串字面量**含 CJK 字符**」即一次性 `PushWarning` 列出。
  - **CJK 判据在本作特别可靠**：键恒为 ASCII 大写；内容文案不经 UI 代码传递（UI 拿到的是 `Id`，正文由 ViewModel 向 ContentRegistry 取）。
- **落点 = 启动期，但以 `OS.HasFeature("editor")` 守卫，只在编辑器内运行。** 与 `AuditTranslations()`、`TranslationAudit.AuditCoverage()`、`ContentRegistry` 的负向条目清单告警**同处、同形、同为 `PushWarning`**——告警要落在能被看见的地方。**它在三条启动期审计里排最后**（顺序与理由见上方「翻译键的铺开」）。
  - **守卫是必需的**：导出包里 `.tscn` 已编译为 `.scn`、`.cs` 不随包分发（编进程序集），源文件扫描在发布版中无从执行。
  - **只有这一条需要守卫，另两条不需要——这是数据源差异，不是两套纪律。** 判据一句话：**扫源文件的必须守卫，扫消息表的不必**。翻译消息表随包分发，故 `AuditTranslations()` 与 `AuditCoverage()` 在发布版内同样成立；`.tscn` / `.cs` 不随包分发，故本条只能在编辑器内跑。
  - **用 `OS.HasFeature("editor")` 而非 `#if DEBUG`**：后者的成立性本身仍是 `open-questions/05-service-contracts.md` 的一条待实测项，不该让一条新纪律压在它上面。
  - **否决「移出运行时、做成 EditorScript 手动跑」**：脱离启动链就没人会记得跑。
  - 本机验证走 Godot 编辑器运行、不假定额外工具在 PATH 上，故**不另开构建期工具链**（`.claude/rules/environment-rules.md`）。

### 三条版本提示：同一根轴上的三档，同一时刻只呈现最高一档

三条提示不是三件事，是**同一根严重度轴上的三档**：

| 档 | 触发 | 含义 | 呈现 | 阻塞 |
|---|---|---|---|---|
| **③ 强更** | `client.version_unsupported`（**仅登录点**） | 完全不能玩 | **全屏阻塞屏**（见下） | 硬阻塞 |
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

- **`UpgradeRequired == true` 时必须换掉「离线」二字。** 「离线」隐含「正在重连、会自己好」，但 `Upgrade` 态为**本会话内永不恢复**（退避已暂停，唯一解除条件是重新登录成功）。继续显示「离线」是在给出一个**已知为假**的承诺。
- **点按该指示 → 打开更新引导半屏**（与阻塞屏「去更新」同一入口）。这给了 `UpgradeRequired` 一个玩家主动了解的入口，而不必再弹任何东西。
- **不在轮回内新增任何模态。** 需要打断玩家的那一次由既定的软阻塞模态第二变体承担（闸门口径完全不变、只换文案与选项，见 `systems/services/sync-service.md`「`Upgrade` 类错误在非闸门点」）。

#### ① 的形态与频次护栏

`X-Recommended-App-Version` 每次应答都可能带，没有护栏就会变成「每次同步弹一次」：

- **位置：主菜单一条可关闭横幅**（顶部，安全区内）。**绝不在轮回内 / 战斗内呈现**——对上「不打断进行中的事件」与竖屏触控的最小干扰原则。
- **频次：每个 `recommendedVersion` 取值只提示一次。** 玩家关闭后把该版本号写入 **`user://cache/dismissed-recommended-version.json`**（单字段 `dismissedVersion`；与 `flags.json` / `sync-envelope.json` 同处同纪律：原子写、跨启动保留、**不进存档、不进 Profile、不上云**。原子写走共享静态工具 `AtomicJsonFile`，见 `systems/architecture.md`；单字段文件不带版本）。服务端推荐版本变了 → 再提示一次。**不按 `accountId` 分区**——它是设备维度的呈现状态，不是账号数据。
- **仍需比较 semver，且与「`X-Min-App-Version` 客户端不比较」不冲突**：不比较的是**硬闸门**（判定权在服务端），软提示不阻塞任何东西，客户端自己比较是安全的。复用 `minAppVersion` 已定规则：**semver 三段逐段整数比较，不做字典序**（字典序会判 `1.10.0 < 1.9.0`，且这类 bug 发版后才显形）。
- **推论（值得单独记一笔）：客户端总共只在两处做 semver 比较**——manifest 的 `minAppVersion`（内容维度）与 `X-Recommended-App-Version`（软提示），**两处都只导致「不做某事」或「说一句话」，都不阻塞**；协议维度的比较一处也没有。**可机械检查**（全库 semver 比较调用点计数 = 2）。

### 阻塞屏：一个屏三个变体，不是三个屏

三种「玩家在此走不下去」的终局态形态上完全同构（全屏 · 不可返回 · 一句原因 · 一个主动作 · 一个退出），收敛为**一个 `BlockingNoticeScreen` + 一份数据驱动的变体表**。理由与「错误码映射是数据表不是 switch」「三个 `HttpXxxBackend` 共用一处头处理点」同源：**多于一处就会出现「一个改了另一个没改」的半配置态。**

| 变体 | 触发 | 文案键 | 主按钮 | 次按钮 | 底部编号 |
|---|---|---|---|---|---|
| **需更新** | `client.version_unsupported`（**仅登录点**） | `ERR_CLIENT_VERSION_UNSUPPORTED` | 去更新 | 退出游戏 | `#requestId` |
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

> **⚠ 三个变体 ≠ 三处硬阻塞。** 由后端 `code` 触发的硬阻塞点仍是既定的**两处**——**登录点**的版本闸门与被后端明确挤下线。「存档读取失败」变体**不由任何 `code` 触发**：它是本地迁移器在启动 pull 路径上做的**存档 schema 维度**判定（云端 `schemaVersion` 高于客户端支持上界），与协议维度的 `minAppVersion` 提升无关——**两者同因不同径，改一侧不牵动另一侧**。阻塞点的穷举清单见 `systems/services/sync-service.md`「三条不变式」①。`systems/architecture.md` 总则 7 的「硬阻塞只有两处，且只由已知 `code` 触发；未知 `code` 永不新增第三处」原样成立。

#### 判据：什么不进这张变体表

**只由已知后端 `code` 触发、且玩家没有任何自愈路径的终局态，才进这张表。** 二者缺一即不进——否则每一个「转圈等一等」的等待态都能援引本表长成第四、第五个变体，而那张表正是靠「三行且只由 `code` 触发」才可机械检查。

- **首个实例：premium bundle 的购买处理态不进本表。** 玩家已付款、验票 / 购后 pull 未回期间，行为上确实走不下去（不允许开始新轮回），但它**不由任何 `code` 触发**（是客户端自己的等待态）且**有自愈路径**（重试直到成功）。它落成 **Store 流程内的全屏模态进度态**——自带进度指示、「重试」与「退出应用」，文案走 `STORE_` 分区，≥ 15 秒追加一句「网络较慢，可稍后回来，购买不会丢失」；兑现完成后同屏切到兑现结果态。`BlockingNoticeKind` 与上表**一格不动**。流程与失败语义见 `systems/services/sync-service.md` 与 `systems/monetization.md`。

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

### 诊断编号的玩家出口

强制在线 + 云端权威下，客服工单的第一件事是定位「这一次请求」；`requestId` 是唯一能做到的标识符，但它只进日志，而移动端**导出日志基本不可行**——这正是「设置屏显示同步版本 #1337」那条已定案背后的同一判据。

- **在阻塞屏与错误模态的底部放一行极小字 `#<requestId>`，可长按复制。**
- **非模态提示与 toast 级提示不放**——那是高频呈现，加编号是噪音。
- **纪律：它是诊断展示，不是玩法数据。** ViewModel 只读一次，不进任何玩法路径、不参与判断（与「同步版本 #N」同条纪律）。

Source: `handoffs/2026-08-12-error-copy-and-update-prompts.md` · `handoffs/2026-08-13-translation-key-rollout-and-content-localization.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-16e-account-identity-client-adoption.md` · `handoffs/2026-08-19-bundle-grant-ordinal-authority.md` · `handoffs/2026-08-19-game-setting-schema.md` · `handoffs/2026-08-19-pickmany-shortfall-handling.md` · `handoffs/2026-08-19-translation-english-placeholder.md` · `handoffs/2026-08-23-refresh-lifetime-cap-client-half.md`

## 决策(-> ADR)
> _已敲定的决定链接到 decisions/ADR-####。_

## 待决问题

- **Godot 4.7 上 `Control` 自动翻译（`auto_translate_mode`）的默认行为。** 若默认即生效，`.tscn` 里把 `text` 直接写成键就够了、UI 代码里连 `tr()` 都不必出现；否则显式 `tr()`。**两种情况下键的形态、分区表、三条审计完全相同**，故它不阻塞本节以外的任何内容；宜与 `#if DEBUG` 判据的实测合并到同一次 `.csproj` 生成后的实测。
- **四条兜底文案与各 `ERR_*` 的实际措辞。** 结构与键已定，**逐条中文措辞待文案定稿**（属内容充实，不阻塞结构落地）。
- **`reasonKey` 二级措辞的逐条文案。** 结构、形态、机械变换与兜底规则均已定，三处的取值集合也已由后端契约填表（见「意图」的回链）——**仅剩逐条中文措辞待文案定稿**，与「四条兜底文案与各 `ERR_*` 的实际措辞」同属内容充实，不阻塞结构落地。

## 提供给
提炼进:`.claude/knowledge/scenes/_index.md`

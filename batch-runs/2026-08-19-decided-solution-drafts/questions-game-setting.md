# Phase A — game-setting

- 输入草稿：`game-design-documents/inbox/solution-draft-game-setting-schema.md`（`status: decided`）
- 目标库：`game-design-documents/`（用户显式给定 `game`）
- 本文件为只读校验产物；worker 未写入任何设计库文件。

## 一句话摘要

把 `PlayerProfile.gameSetting` 从「只有一句语义、类内零字段」补成完整形态：**账号级四项**（三条音量轨 `int 0–100` + `FastCombatAnimation`）落 `GameSetting`、**设备本地一项** `locale` 落 `user://cache/device-settings.json`，切分判据为「取值是否取决于这台机器」；写入通道为 `ProfileChangeSpec` 新增一列 `SettingChanges` + `SettingFields` 配表，`PushPolicy.Debounced` / `SavePointReason.MetaChanged`、**不计软阻塞闸门**；locale 归一链条链首加一个可选覆盖来源、**单点不变**；schema 追加进既有那一次 bump。

## 已定案项（用户已裁决，不进 interview）

草稿「用户裁决（2026-08-19 · 全部定案）」六项 + 三条跨草稿裁决，**一律按定案落笔，不再提问**：

| # | 定案 |
|---|---|
| ① | `locale` **归设备本地**（`user://cache/device-settings.json`）；连带**已获批**：`game-setting.md` 改写为两侧对照表，「GameSetting = 账号级常规系统设置」改为「设置 ⊃ `GameSetting`」口径 |
| ② | 写入通道 = `ProfileChangeSpec` 增列 `SettingChanges` + `SettingFields` 配表（否决塞进 `StatusChanges`、否决第二写入面 / setter） |
| ③ | 首批清单 = 四项账号级 + 一项设备本地；震动 / 画质 / 帧率 / 辅助功能 / 内容语言 / 二次确认开关**首批不收**，各带解除条件 |
| ④ | 字段与归一覆盖口先落，**设置屏语言行首批隐藏** |
| ⑤ | 音量默认 Master 100 / Music 80 / Sfx 100，**明确标注为待实测初值** |
| ⑥ | 三条音量轨**归账号级**（不降设备本地）；`GameSetting` 保留四个字段 |
| 跨 A | `deviceId` 与 `locale` **各自一份 `user://cache/` 文件，不合并**（失效口径不同） |
| 跨 B | 本批四份草稿把 `ProfileChangeSpec` 由 7 推到 **11 列，已裁决接受**；硬要求**单批收口、共用同一次 `schemaVersion` bump** |
| 跨 C | `user://` 原子写**抽成不属任何服务的共享静态工具**（如 `AtomicJsonFile.TryRead<T>/TryWrite<T>`），五处同用一份 |

## 🔴 冲突

### 🔴-1 `SettingAssignment` 的「另一格填缺省」使一条失败语义**不可机械检查**（想法自身的逻辑缺口）

- 草稿 §4.1 定义 `public readonly record struct SettingAssignment(SettingKey Key, int IntValue, bool BoolValue)`，并沿用 `StatusAssignment`「由配表 `Kind` 决定哪一格有效，另一格填缺省」。
- 但草稿同时把「`Kind` 与非缺省格不匹配（`Bool` 型却填了 `IntValue`）」列为**必需缺失 → `PushError` + 整批拒绝**。
- ✗ **该行在此形状下不可判**：`bool` 的缺省 `false` 与合法值 `false` 同形，`int` 的缺省 `0` 与合法值 `0`（音量 0 = 静音，草稿自己承认是合法且承重的取值）同形。**「另一格是否填了」在运行时无法与「填了一个恰好等于缺省的合法值」区分**。
- ✗ 既有权威给过正解：`systems/architecture.md`「共享核心类型」的 `EventStateAssignment(EventStateKey Key, ActiveEventState? ActiveEvent, EventOptionSave? EventOption)` **两格皆为可空**，注释明写「两格恒为 null = 置空」——可空正是为了让「哪一格有效」成为可机械校验的一列；`profile-service.md` §`EventStateChanges` 亦逐字写「**『哪一格该有效』因此是可机械校验的一列**」。`StatusAssignment` 之所以能用非可空，是因为它的另一格是 `string`（`null` 即缺省，可判）。
- 选项：
  - **(a) 改为 `int? IntValue, bool? BoolValue`**，失败语义行原样成立（非本 `Kind` 的格非 `null` ⇒ `PushError`）。后果：`architecture.md` / `profile-service.md` 的类型定义写可空；与 `EventStateAssignment` 同形，零新纪律。
  - (b) 保留非可空，**删掉那一行失败语义**并明写「该不匹配不可检测、依赖组装方自律」。后果：把一条本库一贯要求「可机械检查」的纪律降级为口头约定，且草稿正是以「可机械检查」为由否决了备选 B（塞进 `StatusChanges`）——自相矛盾。
  - (c) 拆成 `SettingInts` / `SettingBools` 两个列表。后果：与 `StatusFields` / `ResourceElements` 拒绝分表的既定判据（「分表必然出现『加了这张忘了那张』」）直接相抵，草稿自己也已否决。
- **推荐：(a)** —— 唯一同时保住「双字段单列表」与「可机械检查」两条既定判据的形态，且有 `EventStateAssignment` 的同库先例，不引入任何新纪律。

### 🔴-2 `device-settings.json` 的写入方：草稿内部自相矛盾，且与本批跨草稿裁决 C 相抵

- 草稿 §3.2 同时写下两句：
  1. 「经 `LocalCacheManager` 写（它已是 `user://` 原子写的既定归口）」；
  2. 「**它不得依赖 `account-service` / `sync-service` / `ContentRegistry` 的任何东西**」（承重时序约束：归一发生在登录之前）。
- ✗ `LocalCacheManager` 是 **sync-service 的 manager**（`systems/services/sync-service.md`「管理器」表：`LocalCacheManager | user:// 原子写（临时文件 → rename）、缓存读取与失效、待发队列的持久化`）。两句直接互斥。
- ✗ 且与本草稿末尾已记录的**跨草稿裁决 C**（原子写抽成**不属任何服务**的共享静态工具，本方案「照此落地、不自带实现」）相抵——§3.2 的正文未同步。
- 选项：
  - **(a) 删除「经 `LocalCacheManager` 写」一句，改写为经共享静态工具 `AtomicJsonFile`**，并保留「不依赖三个服务」的时序约束。后果：与跨草稿裁决 C 一致；`sync-service.md` 的 `LocalCacheManager` 职责行需同批调整（属跨草稿共同改动面，见「越界发现」）。
  - (b) 保留 `LocalCacheManager`，放弃「登录前无依赖」的时序约束。后果：locale 归一不再能在登录之前完成 ⇒ 直接打破 C6「归一是单点、只发生一次」，而那正是裁决 ① 选设备本地的**唯一**理由——等于推翻 ①。
- **推荐：(a)**。（若 orchestrator 认为跨草稿裁决 C 已足以覆盖，可不进 interview、直接按 (a) 落笔；此处按「拿不准往高判」列出。）

### 🔴-3 跨分片矛盾：C7 的「`en` 列全部预设占位符」与同批 `translation-english-placeholder` 的定案相抵

- 本草稿 C7 与 §5.3 以「**`en` 列全部预设占位符**」为据论证「首批隐藏语言行」。
- ✗ 同批 `inbox/solution-draft-translation-english-placeholder.md`（`status: decided`）已定案：「`en` 单元格**留空**，**不写任何哨兵值**」，并明写「`en` 列绝不写键名本身 / 绝不复制 `zh` 原文」，同时要把 `ux/error-and-blocking-ux.md` 现有措辞「短期 `en` 全占位符」一并订正。两份草稿都要写 `ux/error-and-blocking-ux.md`。
- 结论方向不受影响（`en` 无实际文案 ⇒ 隐藏语言行的理由更强），但**落笔措辞必须统一**，否则同一份文档里会同时出现「预设占位符」与「留空、无哨兵值」两种说法。
- 选项：
  - **(a) 本分片落笔时把理由句改写为「`en` 尚无实际文案（留空 + 回落 `zh`）」**，占位符形态一律以 translation 分片为准、不复述。
  - (b) 保留原措辞。后果：`ux/error-and-blocking-ux.md` 出现两处互相打架的陈述，且 `game-setting.md` 会成为一个过时口径的第二权威。
- **推荐：(a)**。

## 🟠 含糊

### 🟠-1 15 字段表第 15 行「层」格：填 `—` 还是引入第三个层名「偏好层」

- 草稿 §3.1 / 具体形态 A 写「层 = **`—`（偏好层：既不参与规则判定，也不是统计计数）**」，`GameSetting` 代码注释亦写「既非规则字段层、也非统计计数层」。
- 既有权威：`systems/player-profile/_index.md` 第 9 行明写「**层** = 规则字段层 / 统计计数层（判据见下方分层通则）」，即**二值**（C14：判据 = 有没有被规则读）；第 15 行**当前已经是 `—`**（见下 🔵-事实订正）。
- 两种解读导出不同文档内容：
  - **(a) 只填 `—`**，在 `game-setting.md` 用一句话解释「不被规则读、也不是计数，故不属两层中的任何一层」，**不造新层名**。`_index.md` 的分层通则一个字不动。
  - (b) 正式把「偏好层」立为第三个层名。则 `_index.md` 第 9 行的层定义、下方分层通则、以及所有引用「两层」的表述都要同批改写。
- **推荐：(a)** —— C14 的分层通则是判据（被不被规则读），不是分类学；`accountInfo` 之外的 `—` 已有先例（第 2 行 `characterProfile` 层写「规则」但写入通道 `—`），本库尚无「第三层」的概念，为一个偏好字段造一个层名会让一条二值判据变三值。

### 🟠-2 跨库：是否需要在后端库留一句「`gameSetting` 段不透明」的承接

- 本草稿「张力 ④」把这一条留给 orchestrator 裁决，个人判断为**不需要**（后端透明路径白名单是**封闭表**，「不在表里」本身即完整语义）。
- 但 `.claude/rules/design-library-routing.md`「跨库纪律」的字面要求是「跨边界改动在两侧都要留下痕迹……不允许只改一侧就宣称收口」。
- 选项：
  - **(a) 不写对侧库**，只在 `game-setting.md` 写下否定结论（后端零配合），理由：白名单封闭 ⇒ 无跨边界改动发生。
  - (b) 在 `backend-design-documents/contracts/profile-sync.md` §5 一侧补一句「`/gameSetting/**` 不透明，后端不解析」，两侧互相回链。
- **推荐：(a)** —— 本次并未改动任何契约，「不进白名单」不构成对后端的新增义务；(b) 会为**每一个不在表里的字段**开一个先例，白名单会长出一份等长的反向清单。
- **注：本批 `codex` 分片可能有同形问题（六个 Codex 同样不进透明段），建议合并成一题裁决。**

### 🟠-3 `SettingFields` 配表的落点文档未指定

- 草稿把 `SettingFields`（Key / Kind / Min / Max / 默认）写进 `profile-service.md`，与 `StatusFields` / `ResourceElements` 同处——这一点无歧义。
- 含糊在**默认值列**：草稿 §4.1 明写「**默认值就住在这张表里，是唯一一处**」，同时 §3.1 读档校验、§6.2 老档补默认、UI 初值都读它。但 `.claude/rules/data-resource-rules.md` 要求「可调数值（花费、伤害、掉落权重、ante 缩放）存放在导出字段或专门的平衡资源中——**不硬编码在系统逻辑里**」。
- 选项：
  - **(a) 判为「不是平衡数值」，留在代码常量配表** —— 与 `ResourceElements` / `StatusFields`「代码常量静态查表」同款（`profile-service.md` 对合法子集表逐字用过这一措辞）。音量默认值不进抽取 / 结算，改它不影响任何玩法平衡。
  - (b) 落一个 `.tres` 平衡资源。后果：为四个默认值引入一次 `ContentRegistry` 依赖，而 §3.2 的时序约束明确要求设置读取链**不依赖 `ContentRegistry`**（虽然那条只约束设备本地那一侧）。
- **推荐：(a)**，并在落笔时明写「这些是 UI 初值 / 缺省，不是平衡数值」，使 `data-resource-rules.md` 的边界可判。

## 🔵 可推演（无需回答）

- **`SavePointReason.MetaChanged` 与 `PushPolicy.Debounced` 均已在枚举中**（`sync-service.md` API 面：`public enum SavePointReason { CycleStarted, EventResolved, ChapterBoundary, CycleEnded, MetaChanged }` / `public enum PushPolicy { Debounced, Immediate }`）⇒ §4.3「不新增 reason、不新增 flush 点」如实成立。
- **「设置变更不计软阻塞闸门」与既有口径零冲突**：`sync-service.md`「缓冲上限（两个闸门）」明写只计四类事件级存档点，并已有推论「闸门计的是 push 单位，不是本地写入单位」。草稿主张的是把该推论**显式补一句**，不是改口径。
- **`SETTINGS_` 分区已在既有分区表内**（`ux/error-and-blocking-ux.md`：`| SETTINGS_ | settings.csv | 设置屏（含同步版本 #N 的标签） |`）⇒ §E 的十个键是填充，不是新建分区；「不占 `ERR_` 前缀」与该文档「`ERR_*` 由 `code` 机械变换、不得手写」一致。
- **归一链条改写只加链首一个可选来源**，第 2–5 步与 `ux/error-and-blocking-ux.md` 现文逐字相同；「设置屏不得自己调 `TranslationServer.SetLocale`」是「单点」纪律的直接后果。
- **`SelectCost` 内 `SettingChanges` 恒为空**：与 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` 四条同款不变式，`profile-service.md` 失败语义表已有四行同形先例，第五行是机械追加。
- **`AppliedChange` 中实际永不出现 `SettingChanges`**：草稿已自查并给出理由（列的存在源于写入面唯一），逻辑自洽，无需提问。
- **不设 `IsMuted` / `AudioEnabled`**：`MasterVolume == 0 ⟺ 静音`，与 `HasPremiumBundle ⟺ BundleGrantOrdinal > 0` 的既定判据逐字同款。
- **音量存 `int` 而非 `float` / dB**：`PlayerPowerFragment.Accumulated` 取万分比整数的理由（存档 / 跨端一致性 + 可复算 + 避免浮点比较）在 `player-profile/_index.md` 已成文，直接适用。
- **设备本地文件不走 `MigrationManager`**：判据「存档不可无损重建、本文件可」成立；`sync-service.md` 的迁移纪律约束的是 Profile 存档，不覆盖 `user://cache/` 的设备维度小文件（`flags.json` / `dismissed-recommended-version.json` 两份先例同样不走迁移）。
- **schema 追加进既有那一次 bump 合法**：`sync-service.md`「两层 Profile 的字段面收口」明写「**后续同批新增的字段追加进本清单，不另起一次 bump**」。
- **UI 文案与触控纪律合规**：`.claude/rules/ui-input-rules.md`（翻译键、无 hover-only、触控目标尺寸、竖屏）在 §D 逐条被满足。
- **事实订正（草稿有一处小误）：** 草稿 §问题 与 §3.1 称 15 字段表第 15 行「**『层』与『写入通道』两格皆为 `⟨待定⟩`**」。**实际只有「写入通道」一格是 `⟨待定⟩`，「层」格已经是 `—`**（`systems/player-profile/_index.md` 第 27 行）。落笔时只填一格 + 视 🟠-1 的裁决决定是否给 `—` 补一句括注。
- **连带小改（草稿未点名）：** `ux/screen-flow.md` 第 18 行主菜单四入口表 `| Settings(设置) | 音量等常规系统设置;外加一行只读的「同步版本 #N」 | gameSetting |` —— 「数据来源」列在 `locale` 判给设备本地后不再只有 `gameSetting`。建议同批把该格改为 `gameSetting`（+ 设备本地 `device-settings.json`），否则该表会与 `game-setting.md` 的两侧对照表相抵。
- **`open-questions.md`「下一阶段」第 6 条**现写「仅排除 codex / gameSetting 两块的序列化」，本次落笔后该措辞过时（属共享台账，归 orchestrator；**不得触碰同文件的「derive 就绪度」小节**，其中 `sync-service.md` / `player-profile/_index.md` / `game-setting.md` 三行提到的 gameSetting 卡点一律留给 `/assess-derive-readiness`）。

## 拟改动文档清单与各自新增要点

| 文档 | 新增/修改要点（供跨草稿核对） |
|---|---|
| `systems/player-profile/game-setting.md` | **主落点，近乎重写**：① 切分判据（一句话判据 + 反问 + 拿不准归设备本地 + 一项只落一侧）；② **「设置 ⊃ `GameSetting`」的包含关系**，改写现有「GameSetting = 账号级常规系统设置」一句；③ 两侧对照表（账号级四项 + 设备本地 `locale`）；④ `GameSetting` 类定义（四字段）+ 四条连带纪律（不设 `IsMuted`、`int` 0–100 不用 float/dB、禁用 `Ordinal`/`Total`/`Count` 词缀、字段名单数）；⑤ 五条不收候选 + 解除条件；⑥ 「同步版本 #N 不是设置项」的排除；⑦ 读档校验三行；⑧ **不进透明段 / 后端零配合**的否定结论（区分「不需后端配合」与「仍受 camelCase 机械映射约束」）；⑨ **离线改设置可能被云端覆盖的代价**明写；⑩ `device-settings.json` 的形态、切账号**不**失效、启动最早期可读、整份可选缺失、不走迁移；⑪ **删除现有「待决问题」两条** |
| `systems/player-profile/_index.md` | 15 字段表第 15 行「写入通道」格由 `⟨待定⟩` 填为 `SettingChanges`（「层」格视 🟠-1 裁决）；第 169 行待决项中划掉「`GameSetting` 的设置项清单」一句 |
| `systems/services/profile-service.md` | `ProfileChangeSpec` 分列段增 `SettingChanges`（**不写序数**）；新增 `SettingFields` 配表（4 行）；施加失败语义表**追加 4–5 行**（无对应行 / `Kind` 不匹配【视 🔴-1】/ `Int` 越界钳制 / 同批同 `Key` / `SelectCost` 内恒空）；「恒不经 modifier pipeline」一句；第 249 行待决项划掉 `GameSetting` 一句 |
| `systems/services/sync-service.md` | 既有 bump 表 `ProfileChangeSpec` 行追加 `SettingChanges`、`PlayerProfile` 行追加 `gameSetting`（**与 codex / profile-change-spec-gaps 分片合并为同一张表、同一次 bump**）；设置变更 = `Debounced` + `MetaChanged` 一句；**设置变更不计闸门**一句（并列于「决策点存档不计入闸门」）；`user://cache/` 三份文件的**切账号语义差异**一句；`LocalCacheManager` 职责行视 🔴-2 / 跨草稿裁决 C 调整 |
| `ux/error-and-blocking-ux.md` | 「语言开关只有一个」归一链条**链首加第 1 步**（读 `device-settings.json` 的 `locale`，缺失 / 非法 → `PushWarning` + 跳过）；`settings.csv` 十个键清单；**「日后若加游戏内语言设置项」一句改为现在时**；（与 translation 分片同文件 —— 见 🔴-3 与「越界发现」） |
| `ux/screen-flow.md` | Settings 屏竖屏线框（音量三轨 / 快速演出 / 语言行首批隐藏 / 只读同步版本）；**滑条拖动=预览、释放才提交、离屏强制提交**一条 UI 纪律；第 18 行四入口表「数据来源」格补设备本地 |
| `systems/architecture.md` | 「共享核心类型」`ProfileChangeSpec` 增 `SettingChanges` 字段行 + `SettingKey` 枚举 + `SettingAssignment` record（**可空与否取决于 🔴-1**）（**与另两份分片同一代码块，须单写者**） |
| `handoffs/2026-08-19-<slug>.md`（新建，worker 独占） | 本次意图的整洁 handoff，`status: distilled` |

**共享台账（worker 不写，交回 orchestrator 代笔）：**

- `handoffs/_index.md`：新增一行 `2026-08-19-game-setting-schema | 2026-08-19 | systems/player-profile/game-setting · systems/services/profile-service · systems/services/sync-service · ux/error-and-blocking-ux · ux/screen-flow · systems/architecture | distilled | <上表七份文档>`
- `inbox/_index.md`：待处理表删 `solution-draft-game-setting-schema.md` 行；已归档表加 `solution-draft-game-setting-schema.md | solution-draft | 2026-08-19 | handoffs/2026-08-19-game-setting-schema.md | answer-logs/log-game-setting-schema.md`
- `open-questions/deferred-content.md`：**移出第 25 行**「**GameSetting 的设备本地项 vs 账号级项切分**」整条
- `answer-logs/log-game-setting-schema.md`（新建）+ `answer-logs/_index.md` 追加一行；移出条数 **2**（`game-setting.md` 的两条待决问题）+ 1（`deferred-content.md` 那条）= 实际答结 **3 条**（其中两条同源）
- `open-questions/update-log.md`：本次摘要置顶
- `open-questions.md`：顶部「最近更新」一行；「下一阶段」第 6 条措辞（见 🔵）。**「derive 就绪度」小节禁止触碰**
- 草稿 front matter：`status: distilled` + `reviewed:` + `distilled-to:`，随后 `git mv` 进 `inbox/archive/`

## 越界发现

1. **写入面撞车（最重要，orchestrator 必须分区或串行）。** 本分片与同批至少三份草稿写**同一批文件的同一小节**：
   - `systems/services/profile-service.md` § `ProfileChangeSpec` 分列 + 失败语义表 ← `game-setting`（`SettingChanges`）· `codex-entry-schema`（`CodexElements`）· `profile-change-spec-gaps`（`RngElements` + `TraceElements`）
   - `systems/architecture.md` §「共享核心类型」的同一个 `ProfileChangeSpec` 代码块 ← 同上三份
   - `systems/services/sync-service.md` § 存档 schema bump 表 ← 同上三份（草稿末尾「落笔提醒」已点名**不得写成两次 bump**）
   - `systems/player-profile/_index.md` 15 字段表 ← `game-setting`（第 15 行）· `codex-entry-schema`（第 6–11 行）
   - `ux/error-and-blocking-ux.md` ← `game-setting`（归一链条 + `settings.csv` 键）· `translation-english-placeholder`（占位形态 + 审计 + `ErrorText.For` 措辞订正）
   - `systems/services/account-service.md` / `user://cache/` 文件清单 ← `device-id-provisioning`
   建议：**这五份文件各指定单一 worker 串行落笔**，或由 orchestrator 在 Phase B 收尾统一合并。
2. **「第八列」序数撞名。** `game-setting` 与 `codex-entry-schema` 两份草稿**各自自称「第八列」**，`profile-change-spec-gaps` 再加两列。既有权威已给出解法：`profile-service.md` 明写「**列表数不进承重表述**——它随字段族增长，把数字写死等于每加一列就要改一次这条纪律」。⇒ **落笔时四份一律不写序数**，只写列名与施加语义。
3. **`AtomicJsonFile` 抽取牵动四份既有文档**（`sync-service.md` 的 `LocalCacheManager` 职责行 · `content-service.md` 的 `flags.json` · `ux/error-and-blocking-ux.md` 的 `dismissed-recommended-version.json` · `account-service.md` 的 `device-id.json`）。它是跨草稿裁决 C 的落地面，**不属本分片范围**，但本分片的 🔴-2 依赖它——建议 orchestrator 指定一个 worker 统一落这条工具层。
4. **`ux/screen-flow.md` 第 18 行的数据来源列**（见 🔵）是本分片顺手可修的相邻项，已列进拟改动清单；若 orchestrator 把 `screen-flow.md` 分给别的 worker，请把这一格转交。
5. **未答定、不在本分片范围的相邻待答项**（草稿「前置依赖」已列，均**不阻塞**本次落笔，但落笔时要保留其解除条件原文）：「寿元告警是否伴随音效 / 震动」（`open-questions/deferred-content.md`）· 战斗 UX 专场的动效强度旋钮 · `refresh token` 的客户端持有形态。

---

**回报口径：🔴 3 项 · 🟠 3 项 · 🔵 12 项（含 2 处事实订正 / 连带小改）。**

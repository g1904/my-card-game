# `GameSetting` 的设置项清单、本地 / 账号切分与写入通道

- id: 2026-08-19-game-setting-schema
- date: 2026-08-19
- topic: systems/player-profile/game-setting.md · systems/player-profile/_index.md · systems/services/profile-service.md · systems/services/sync-service.md · systems/architecture.md · ux/error-and-blocking-ux.md · ux/screen-flow.md
- status: distilled
- distilled-to: systems/player-profile/game-setting.md, systems/player-profile/_index.md, systems/services/profile-service.md, systems/services/sync-service.md, systems/architecture.md, ux/error-and-blocking-ux.md, ux/screen-flow.md, systems/services/content-service.md

## Intent（distilled）

`PlayerProfile.gameSetting` 此前只有一句语义（「账号级常规系统设置，音量等」）与一条形态纪律（**具名类，不是字典**），类内一个字段也没有；15 字段表的「写入通道」格空着，`GameSetting` 子对象的 schema 也因此写不出来。本次按既定的落笔顺序**先答切分、再一次性定清单**，并把写入通道、`PushPolicy`、locale 衔接、版本化策略一并收口。

### 一、切分判据（先答这一条）

**一句话判据：这一项的正确取值是否取决于「这台机器」——硬件能力、系统环境、或只在本机成立的呈现状态？** 取决于 → 设备本地；纯粹是玩家的偏好、换台手机也应当跟着走 → 账号级（`GameSetting`）。

- **自检反问**：「玩家换了一台新手机、登录同一个账号，他会不会觉得这一项理应已经是他上次调好的样子？」会 → 账号级。
- **拿不准归设备本地**：两侧成本不对称——账号级一项要进 Profile、进 diff、进存档 schema、进迁移路径、受 camelCase 机械映射约束；设备本地一项只是一个 JSON 字段，可由玩家重设一次无损重建。
- **一项设置只能落一侧**，绝不两侧各存一份——那正是「设置屏会长出两个开关」要防的形态。
- **连带：`GameSetting` 只承载账号级那一半。** 包含关系是**设置 ⊃ `GameSetting`**，故 `game-setting.md` 承担的是一张两侧对照表，不是一张账号级清单。

### 二、清单：账号级四项 + 设备本地一项

判据是**「游戏里已经存在这个东西可调吗」**，逐项给存在依据，不凭空堆砌。

- **账号级（`GameSetting`）**：`MasterVolume` / `MusicVolume` / `SfxVolume`（`int` `[0,100]`，默认 100 / 80 / 100，为待实测初值）· `FastCombatAnimation`（`bool`，默认 `false`，敌人回合基线节拍 0.2 s）。
- **设备本地（`user://cache/device-settings.json`）**：`locale`（`zh` / `en` / 缺省 = 跟随系统）。

**四条可机械检查的连带纪律**：不设 `IsMuted` / `AudioEnabled`（`MasterVolume == 0 ⟺ 静音`）· 音量存 `int` 线性档位而非 `float` / dB（dB 是呈现层换算，在音频层做一次、不进存档）· 类内禁用 `Ordinal` / `Total` / `Count` 三个词缀（它们各自绑定一层，出现即意味着有人把它当成了另一层的字段）· 字段名单数已合规。

**首批不收五项，各带解除条件**：震动 / 触觉（游戏里当前一处震动都没有，收它即交付一个不控制任何东西的空开关）· 画质档（2D 卡牌 + GL Compatibility，没有可供分档的渲染负载）· 帧率上限（无任何实测证据，但最有可能第一个被补上）· 二次确认开关（同时踩「不做二次确认」的手感取向与两处安全性必需的二次确认）· 辅助功能（字号 / 色盲无既有陈述可依；「减少动效」与 `FastCombatAnimation` 高度重叠）。**内容语言与界面语言分离明确否决。** **「同步版本 #N」不是设置项**——它是 `SyncService.BaseRevision` 这个只读属性在设置屏上的一次呈现。

### 三、写入通道：`ProfileChangeSpec` 新增一列 `SettingChanges`

`GameSetting` 字段不提供 setter，唯一写入路径经 `ProfileManager.TryApply`。设置的施加语义是**绝对置值 · 无量纲 · 按 key 配表钳制 · 绝不走 modifier pipeline**——与 `StatusChanges` 逐条相同但作用对象不同（后者明写绑定 `CharacterProfile.Status` 上的规则字段），故按「施加语义根本不同就分列」独立成列。

- **`SettingAssignment(SettingKey Key, int? IntValue, bool? BoolValue)` 两格皆可空**，由配表 `SettingFields` 的 `Kind` 决定哪一格有效，另一格为 `null`。可空是**「哪一格有效」可机械校验**的前提：`bool` 的缺省 `false` 与合法值 `false` 同形，`int` 的缺省 `0` 与合法值 `0`（音量 0 = 静音）同形，非可空下「另一格是否填了」在运行时无法与「填了一个恰好等于缺省的合法值」区分。同库先例是 `EventStateAssignment` 的两格可空。
- **配表 `SettingFields`（Key / Kind / Min / Max / 默认）与 `StatusFields` / `ResourceElements` 同款**，默认值就住在这张表里、是唯一一处；老档补默认与 UI 初值读同一行。它是**代码常量静态查表**，明写「这些是 UI 初值 / 缺省，不是平衡数值」。
- **施加失败语义五行**：无对应行 / `Kind` 与非 `null` 格不匹配 / 同批同 `Key` / 出现在 `SelectCost` 内 → `PushError` + 整批拒绝；`Int` 型置值越界 → `PushWarning` + 钳制（把一个滑条拖过头变成整批失败不成比例）。
- **提交时机**：拖动中只做实时预览（直接改 `AudioServer` bus 音量，不碰 profile），`drag_ended` / 开关切换那一刻提交一次；离屏时若有未提交的预览值强制提交一次。这是一条 UI 纪律，不新增任何机制——「一次 `TryApply` ⇒ 一次本地原子写」下，每帧提交就是每帧一次磁盘原子写。
- **`PushPolicy.Debounced` + `SavePointReason.MetaChanged`**（两者均已在枚举中），不新增 reason、不新增 flush 点：既有的「应用失焦 / 挂起」`Immediate` flush 已经覆盖唯一真正需要担心的时刻。
- **设置变更不计软阻塞闸门**——与「决策点存档不计入闸门」是同一条推论的第二个实例（闸门计的是 push 单位，不是本地写入单位）。否则在主菜单反复拖滑条的玩家会在离线时把闸门推满。

### 四、设备本地文件与 locale 归一

`user://cache/device-settings.json` = `{ "schemaVersion": 1, "locale": "zh" }`，与同处的其余小文件同纪律：原子写、跨启动保留、不进存档、不进 Profile、不上云、不进 diff、不按 `accountId` 分区。

- **切账号不失效**，与 `sync-envelope.json` / `flags.json` 相反——那两份内含账号绑定的数据，本文件一个账号字段也没有；「`user://cache/` 下的文件切账号即失效」不是通则，是那两份文件各自的性质。
- **整份可选缺失**：文件不存在 / 解析失败 / `schemaVersion` 不认识 / `locale` 不在 `{zh, en}` 内 → `PushWarning` + 整份丢弃 + 回落「跟随系统」，绝不阻塞启动。
- **不走 `MigrationManager`**：存档不可无损重建，本文件可。
- **它必须能在启动链最早期被读**（归一发生在登录之前）⇒ 不得依赖 `account-service` / `sync-service` / `ContentRegistry` 的任何东西。这是一条承重的时序约束。
- **原子读写走共享静态工具 `AtomicJsonFile`**，不经 `LocalCacheManager`——后者是 sync-service 的 manager，依赖它与上一条时序约束直接互斥。

**归一链条只在链首加一个可选覆盖来源，单点不变**：读 `device-settings.json` 的 `locale`（缺失 / 非法 → `PushWarning` + 跳过）→ 无覆盖值则读系统 locale → 取主语言子标签 → 非 `zh` / `en` 置 `zh` → `SetLocale`。设置屏改语言 = 写文件 + 调用**同一个归一入口**重跑一次，**不得自己调 `TranslationServer.SetLocale`**，否则「非 zh/en 置 zh」这条兜底会在设置路径上被绕过。切换不需要重启应用。

**语言判给设备本地的理由**：归一发生在登录之前（它影响登录屏的 T&S / 渠道按钮 / 错误文案）。若 `locale` 是账号级字段，登录屏只能用系统 locale、pull 成功后主菜单出现那一刻语言跳一次变，而「归一只发生一次」这条纪律要么被打破、要么就得接受登录屏永远无视玩家的语言选择。**代价照录：换设备后语言不跟随，新设备回落跟随系统。**

**设置屏的语言行首批隐藏**：英文列尚无实际文案，暴露开关等于给玩家一个通往空白的入口。字段、文件与归一覆盖口首批就落（结构先行）。

### 五、共享静态工具 `AtomicJsonFile`

`user://` 下的小 JSON 文件此前有五处各自的原子写：`LocalCacheManager` 的信封与待发队列 · `flags.json` · `dismissed-recommended-version.json` · `device-id.json` · `device-settings.json`。五份实现受同一条纪律却各写各的，必然漂移，且漂移的形态正是「某一处漏了 rename，崩溃时留下半个文件」——原子写这条纪律唯一要防的事。

故把原子读写提为**不属任何服务的共享静态工具**（`AtomicJsonFile.TryRead<T>` / `TryWrite<T>`），五处同用一份。它是无状态工具、不是跨服务调用，不违反「服务之间不伸手进对方 manager」；`LocalCacheManager` 的职责随之由「实现原子写」改为「调用该工具」。

### 六、版本化与可加性

`GameSetting` 与 `SettingChanges` 并入既有那一次 schema bump（既有纪律明写「后续同批新增的字段追加进本清单，不另起一次 bump」）。加一个设置项的成本可预期：账号级 = 加具名字段 + 加 `SettingKey` 成员 + 加 `SettingFields` 一行 + bump 一次 schema，老档缺字段取默认（无损）、后端零配合；设备本地 = 加一个 JSON 字段，缺字段取默认、不 bump 任何 schema。**不做「版本化的默认值」**——改默认值就是对所有未显式设置过的玩家一起改，明写接受。

**离线改设置可能被云端覆盖的代价明写**：离线改音量、另一台设备写入、恢复时 pull 发现云端 `revision` 领先 ⇒ 以云端为准丢弃本地缓冲，那次改动回滚。**不为设置做任何补偿**——字段级三路合并正是 `ADR-0003` 明确排除的东西，为一个滑条位置削弱云端权威不成比例。

**不进透明段、后端零配合**：后端不读、不复算、不据它发放任何东西，`/gameSetting/**` 不进透明路径白名单。**但它仍受 camelCase 机械映射约束**——字段名 = JSON path，改名仍要 bump `schemaVersion`；只是不需要后端配合。这两件事必须分开说。

## Clarifications

- **`SettingAssignment` 的两格是否可空** → **改为 `int? IntValue, bool? BoolValue`**。这**推翻了原始输入 §4.1** 的 `record struct SettingAssignment(SettingKey Key, int IntValue, bool BoolValue)` 与「沿用 `StatusAssignment`：另一格填缺省」的措辞。理由：原始输入同时把「`Kind` 与非缺省格不匹配」列为 `PushError` + 整批拒绝，而在非可空形态下该行**不可判**——`false` / `0` 既是缺省也是合法值。`StatusAssignment` 能用非可空是因为它的另一格是 `string`（`null` 即缺省）。可空是唯一同时保住「双字段单列表」与「可机械检查」的形态，且有 `EventStateAssignment` 先例。
- **`device-settings.json` 由谁写** → **走共享静态工具 `AtomicJsonFile`**，删除原始输入 §3.2 的「经 `LocalCacheManager` 写（它已是 `user://` 原子写的既定归口）」一句。该句与同段「不得依赖 `account-service` / `sync-service` / `ContentRegistry` 的任何东西」自相矛盾（`LocalCacheManager` 正是 sync-service 的 manager）。
- **`AtomicJsonFile` 本体写在哪份文档** → **`systems/architecture.md` 的共享构件条目**，并同批把 `sync-service.md` 的 `LocalCacheManager` 职责由「实现原子写」改为「调用工具」。其余触及该工具的文档只写回链、不重复定义形态。
- **英文占位形态** → 本文档**不复述占位形态**，只写「英文列尚无实际文案」。原始输入 C7 / §5.3 的「`en` 列全部预设占位符」作废——占位形态的口径是 `en` 单元格留空、不写任何哨兵值，权威在 `ux/error-and-blocking-ux.md`。隐藏语言行的结论不受影响（理由反而更强）。
- **15 字段表第 15 行的「层」格** → **填 `—`，不立第三个层名**。原始输入 §3.1 / 具体形态 A 写「`—`（偏好层）」，倾向造一个新层名。分层通则是**判据**（有没有被规则读）而非分类学，为一个偏好字段造一个层名会让一条二值判据变三值；`game-setting.md` 用一句话解释「不被规则读、也不是计数」即可。
- **是否在后端库留「`gameSetting` 段不透明」的承接** → **不留**。透明路径白名单是封闭表，「不在表里」本身即完整语义；本次未改动任何契约，不构成对后端的新增义务。反向为每个不在表里的字段各写一句，会让白名单长出一份等长的反向清单。
- **`SettingFields` 的默认值列是否要落 `.tres`** → **留代码常量配表**，并明写「这些是 UI 初值 / 缺省，不是平衡数值」，使 `data-resource-rules.md` 的边界可判。音量默认值不进抽取 / 结算，改它不影响任何玩法平衡；落 `.tres` 还会为四个默认值引入一次 `ContentRegistry` 依赖。
- **六项取向照原始输入定稿**：`locale` 归设备本地（连带 `game-setting.md` 改写为两侧对照表 + 「设置 ⊃ `GameSetting`」口径）· 写入通道取增列 + 配表 · 首批清单取窄 · 语言行首批隐藏 · 音量默认 100 / 80 / 100（标注待实测）· 三条音量轨归账号级。
- **原始输入两处事实订正**：① 称 15 字段表第 15 行「层」与「写入通道」两格皆为 `⟨待定⟩`，实际只有「写入通道」一格是 `⟨待定⟩`，「层」格已经是 `—`；② 未点名的连带改动——主菜单四入口表 Settings 行的「数据来源」列在 `locale` 判给设备本地后不再只有 `gameSetting`，须同批补上设备本地一侧，否则该表会与两侧对照表相抵。

## Open questions

- **音量三轨的默认值仍是待实测初值**（100 / 80 / 100）。正确的调校时机是真机 + 响度目标定稿之后。
- **震动 / 触觉开关的解除条件未触发**：「寿元告警是否伴随音效 / 震动」仍在待答清单；答定为「有震动」时须补一项设备本地 `haptics`。
- **辅助功能一行待战斗 UX 专场重估**：若专场引入独立于速度的动效强度旋钮，该行需重新判断。
- **`refresh token` 的客户端持有形态**未定，它同样落 `user://cache/`；`user://cache/` 下的文件划分宜在它落定时一并回看。

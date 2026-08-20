# report — game-setting-schema

> worker 自身写入本文件被 harness 拦截，报告由 orchestrator 代为落盘。

- library: `game-design-documents`
- file: `game-design-documents/inbox/solution-draft-game-setting-schema.md`
- 依据构成：**既有推演 11 · 通行做法 3 · 取向选择 6**

## 建议要点

- **切分判据**：取值是否取决于「这台机器」→ 设备本地；纯玩家偏好、换机应跟随 → 账号级。反问式自检：「换台新手机登同一账号，他会不会觉得这项理应已是上次调好的样子？」**拿不准归设备本地**（成本不对称）。第三条推论：一项设置**只能落一侧**，绝不两侧各存一份。
- **账号级四项**：`MasterVolume` / `MusicVolume` / `SfxVolume`（`int` 0–100，默认 100 / 80 / 100）+ `FastCombatAnimation`（`bool`，默认 `false`）。**后者不是新提案** —— `ux/combat-ux.md` 已定案「永久快速演出为设置项、默认关、基线节拍 0.2 s」，本草稿只是如实登记。
- **四条连带纪律（皆可机械检查）**：不设 `IsMuted`（`MasterVolume == 0 ⟺ 静音`）· 音量存 `int` 线性档位不存 `float`/dB · 类内禁用 `Ordinal`/`Total`/`Count` 三词缀（使 15 字段表「层 = `—`」可机械检查）· `gameSetting` 已合规单数。
- **设备本地一项**：`locale`，落 `user://cache/device-settings.json`，形态沿用 `dismissed-recommended-version.json`。
- **首批明确不收五类，逐条给解除条件**：震动（**游戏里当前一处震动都没有** ⇒ 空开关）· 画质（2D + GL Compatibility 无可分档对象）· 帧率上限 · **二次确认开关（建议明确否决**——同时踩「不做二次确认」的手感定案与「解绑 / 绑定冲突两处必须二次确认」的安全纪律）· 辅助功能。
- **「同步版本 #N」不是设置项**——它是 `SyncService.BaseRevision` 只读属性的一次呈现；写成字段 = 第二份真值 + 把传输层元数据卷进存档 schema。建议明写排除。
- **写入通道**：`ProfileChangeSpec` 增列 `SettingChanges`（`SettingAssignment(SettingKey, int, bool)` + `SettingFields` 配表），**恒不经 modifier pipeline**（否则一条法则能改写玩家音量与演出速度），**`SelectCost` 内恒为空**。**默认值只住在 `SettingFields` 一处**。
- **提交时机纪律**：滑条拖动只改 `AudioServer` 实时预览、**不碰 profile**；`drag_ended` 才提交一次 `TryApply`；离开设置屏强制提交。否则「一次 `TryApply` ⇒ 一次本地原子写」会变成每帧一次磁盘写。
- **`PushPolicy` = `Debounced` + `SavePointReason.MetaChanged`（均为既有成员），不进立即 flush 清单。** 理由不是「丢了无所谓」，而是既有的「应用失焦 / 挂起」`Immediate` flush 已覆盖。**须显式补一句：设置变更不计入软阻塞闸门** —— 否则在主菜单离线反复拖滑条会把闸门推满、弹出「网络异常」模态。
- **locale 衔接（本题最硬的已定案约束，方案与之零冲突）**：归一链条**只在链首加一个可选覆盖来源**，第 2–5 步逐字相同；单点不变、只发生一次不变。设置屏改语言 = 写文件 + 调**同一个归一入口**，不重启即生效。**设置屏不得自行调 `TranslationServer.SetLocale`**。
- **schema**：`PlayerProfile.gameSetting` **追加进 `sync-service.md` 既有那一次「两层 Profile 字段面收口」的 bump 清单，不另起一次**。空迁移。**不做「版本化的默认值」**。
- **设备本地文件的三条特有纪律**：① **切账号不失效**（与 `sync-envelope.json`/`flags.json` **相反**；「`user://cache/` 下切账号即失效」**不是通则**）；② **不得依赖 account / sync / ContentRegistry**（归一在登录之前）；③ **不走 `MigrationManager`**（不认识的 `schemaVersion` 整份丢弃回落默认）。

## 台账行

```
| `solution-draft-game-setting-schema.md` | awaiting-review | `GameSetting` 设置项清单 + 设备本地 vs 账号级切分 + 写入通道；评审 6 项取向后 /analyze-new-ideas |
```

## 仍需用户决定（6 项）

### ① `locale` 归设备本地还是账号级？（最承重）
- 语言若进 `GameSetting`，只有在**启动全量 pull 之后**才可得，而 locale 归一是**登录之前**的单点。
- **A. 设备本地（推荐）** — 登录屏即为玩家选定的语言；归一仍是单点、只发生一次；「语言开关只有一个」一字不松动。代价：换设备不跟随；`game-setting.md` 须改写为两侧对照表。
- **B. 账号级** — 换设备跟随。代价：登录屏必然用系统语言，pull 完成后**语言跳变一次**；否则须把归一改成两次 `SetLocale`，**直接打破「归一只发生一次（单点）」这条已定案**。
- **C. 两侧都存** — 两者兼得，代价是**两份真值 + 一条同步规则**。
- 理由：判据反问答案是「否」；A 是唯一不动「归一单点」一个字的选项；C 的两份真值在本库有两个明确反面先例。

### ② 写入通道：`SettingChanges` 独立成列？
- **A. 增列 + `SettingFields` 配表（推荐）** — 与既有列同构、施加语义自洽。代价：为 4 个偏好字段付一列 + 一张配表 + 五行失败语义。
- **B. 扩 `StatusChanges` 目标域到两层 profile** — 不增列，但 `StatusFields` 的 key 混住两个对象，「这个 key 写哪个对象」从此要读上下文。
- **C. 另开第二个写入面** — **违反「`ProfileManager` 是唯一写入面」承重纪律**，列出仅为完整性。
- 理由：既定判据明写「施加语义根本不同就分列」且「**列表数不进承重表述**」⇒ 新增一列本就是这套设计预期中的动作。

### ③ 首批清单收多宽？
- **A. 四项账号级 + 一项设备本地（推荐）**；**B. A + 震动**（当前一处震动都没有 ⇒ 交付一个关掉也无变化的开关）；**C. 再加画质 / 帧率 / 字号**（三项无实测依据）。
- 每条「不收」都写了**解除条件**，故不是把问题推走。

### ④ 首批是否在设置屏暴露语言开关？
- `en` 列已定案全部预设占位符，首批暴露 = 给玩家一个通往一片占位符的入口。
- **A. 结构就位、UI 行首批隐藏（推荐）**；**B. 首批暴露**（切到 `en` 看到一片占位符，观感是「游戏坏了」）；**C. 暴露 + 「英文尚在制作中」**（为短期状态新增文案，它自己也要翻译）。

### ⑤ 三条音量轨默认值（纯手感初值）
- **A. 100 / 80 / 100（推荐，标注待实测）** — BGM 略低于音效，避免盖住出牌与结算反馈音；**B. 全 100**（手机小喇叭上互相盖）。

### ⑥ 三条音量轨是否也降为设备本地？
- **A. 仍归账号级（推荐）**；**B. 降为设备本地** → **`GameSetting` 将只剩 `FastCombatAnimation` 一个字段**，须重新确认该类是否还值得存在。

## 前置依赖

| # | 依赖 | 卡住哪一部分 | 阻塞定稿？ |
|---|---|---|---|
| 1 | **`deviceId` 落点**（本批并行 worker） | `device-settings.json` 与 `deviceId` 是否合并；「切账号不失效」是否也适用 | 否，须交叉核对 |
| 2 | 「寿元告警是否伴随音效 / 震动」 | 震动开关的解除条件 | 否 |
| 3 | 英文占位符形态 | 待决 ④ 的前提 | 否 |
| 4 | refresh token 客户端持有形态 | `user://cache/` 文件划分宜一并规划 | 否 |
| 5 | 战斗 UX 专场 | 辅助功能一行需重估 | 否 |

**不受阻塞可独立定稿的四块**：切分判据 · 四项账号级清单 · 写入通道与 `PushPolicy` · 版本化与加项策略。

## 与既有决策的张力
1. **「GameSetting = 账号级常规系统设置」这句措辞** 读起来像「所有常规系统设置都是账号级」。需松动的理由是结构性的（归一在登录前、`GameSetting` 在 pull 后），非观感取舍。代价：`game-setting.md` 须承担**两侧对照表**。由用户裁决（= 待决 ①）。
2. **云端权威 vs 离线改设置**：离线改音量 → 另一设备写入 → 恢复时以云端为准 ⇒ **那次改动回滚**。**建议如实接受、不做补偿**（为设置做字段级合并正是 `ADR-0003` 明确排除的）。这条代价须落进 `game-setting.md`。
3. **软阻塞闸门口径需显式补一句**：既定文本没有点名设置，而「主菜单离线拖滑条拖出『网络异常』模态」是真实可达的坏路径。
4. **跨库：一条否定结论。** `/gameSetting/**` 不进透明路径白名单、后端零配合。理想形态是后端 §5 也留一句「gameSetting 段不透明」，但后端白名单是**封闭表**，「不在表里」本身即完整语义 ⇒ 判断不需要单独一份对侧草稿。**请 orchestrator 定夺。**
   > 须分开说清：**`gameSetting` 不进透明段 ≠ 字段名可随便改。** 它仍受 camelCase 单点策略机械映射约束 ⇒ 改名仍要 bump `schemaVersion`；区别只在**不需要后端同批改**。

## 越界发现

### ① 对 `deviceId` 落点的隐含主张（须与 W2 交叉核对）
本草稿新建了设备维度文件 `user://cache/device-settings.json`；`deviceId` 同样在找「跨启动稳定 · 设备维度 · 不进 Profile」的落点 —— **两者文件形态判据完全重合**。草稿正文只写「本文件**只装 `locale`**，对 `deviceId` 落点**不作任何主张**」。但三条纪律须核对：

| | 本草稿为该文件定的纪律 | 与 `deviceId` 的关系 |
|---|---|---|
| a | **切账号不失效** | 方向一致。**但若 `deviceId` 被放进 `sync-envelope.json`（切账号即失效）**，`deviceId` 会随切账号被清掉重生 ⇒ **后端会话表 `(accountId, deviceId)` 唯一约束的稳定性被破坏**。 |
| b | **不得依赖 account/sync/ContentRegistry** | 时序一致 ⇒ 合并进同一文件在时序上可行。 |
| c | **不走 `MigrationManager`，不认识的 `schemaVersion` 整份丢弃** | **直接冲突。** 丢弃对 `locale` 安全，但**会导致 `deviceId` 重新生成 = 一次假「换设备」，在后端触发假挤下线**。若合并进同一文件，这条口径必须为 `deviceId` 改写。 |

**建议把「`deviceId` 与 `locale` 是否共用一份 `user://cache/` 文件」作为一条跨分片一致性检查加进合并 interview —— 两份草稿的答案必须一致。本 worker 不裁决它。**

### ② 与 `CodexEntry` 草稿的接触面
字段面与写入通道均不相交。唯一接触点：**都建议追加进 `sync-service.md` 那同一次既有 bump 的清单**。orchestrator 代笔时须把两份追加行**合并写进同一张表，别写成两次 bump**。

### ③ 顺带发现
`provide-solution-draft` SKILL 第 6b 步的台账表头（5 列）与 `inbox/_index.md` 实际表头（3 列）不一致。按实际表头产出台账行，未修改技能文件。

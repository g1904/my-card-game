# Answer log codex-entry-schema

- 日期：2026-08-19
- 来源：`inbox/solution-draft-codex-entry-schema.md`（→ `handoffs/2026-08-19-codex-entry-schema.md`）
- 移出条数：3（其中 1 条为部分移出）

**其余四个图鉴的解锁触发与词条深度** → 四本能力 / 道具类取「进入持有列表即记」（含角色创建时的初始持有），商店里见到但没买的不记；词条 = 内容条目自身已有的字段 + 一段可选的 `CodexFlavor: LocalizedText`，**不套用敌人的五项写作规格**，「词条正文不含阿拉伯数字」的适用范围只及 EnemyCodex；六本一律不分档解锁。（归档去向：`systems/player-profile/codex/common-properties.md`、`systems/player-profile/codex/_index.md`）

**敌人图鉴的慷慨度是否该上调（承重）** → 维持 3 张关键卡 + 五项文案，不给样本卡组完整列表；慷慨度旋钮交给 ③「运作方式」/ ④「特点与弱点」的写作厚度。退让阶梯：写厚 ③④ → `KeyCardIds` 数量上界由 3 放宽到 5（下界 2 不动）→ 才考虑全表。已知代价（首遇的信息劣势维持现有水平、尚未经实测检验）照录。（归档去向：`systems/player-profile/codex/enemy-codex.md`）

**图鉴的入口与浏览形态**（部分移出）→ 其中「是否与成就 / 奖励挂钩」答定为**不挂钩**：收集完成度不发放 PlayerPower / PlayerItem，也不驱动后端的任何发放；连带六个 Codex 键不进透明路径白名单、后端零配合。**剩余部分仍留在待答清单**：六本图鉴在主菜单如何组织、战斗内能否查阅。（归档去向：`systems/player-profile/codex/_index.md`、`systems/services/sync-service.md`）

**连带答定（不占移出条数，原本不在分片中）：**

- **六个 Codex 的计数字段是否要**（`systems/player-profile/_index.md` 的待决问题）→ 首批一格都不加，`CodexEntry` 只有 `Id`；读数类需求的落点是 `PlayerStatistics` 的聚合项。逐条目计数因此不可得，代价照录。
- **`CodexEntry` 的写入通道** → `ProfileChangeSpec` 新增一列 `CodexElements`（元素 `CodexUnlock(CodexKind, string Id)`，零 `Op`、恒不经 modifier pipeline），`PlayerProfile` 15 字段表第 6–11 行六格由此填满。
- **可选 `LocalizedText` 字段的「缺失」定义** → 字段本身为 `null`；语言强校验只对非 `null` 的 `LocalizedText` 执行，不引入必填 / 可选分类清单。

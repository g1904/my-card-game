# ADR-0105 — 集合字段名与元素类型名一律单数，且这是一条跨边界通则

- **状态：** Accepted
- **日期：** 2026-08-12
- **来源：** handoffs/2026-08-12c-identifier-singular-collapse.md · handoffs/2026-08-17h-profile-field-schema.md

## 背景

「集合元素类型该用单数还是复数」在库内并存了两个月：四类持有条目里三个是单数、`CharacterItems` 是唯一离群项，而内容层 `ItemData` / `PowerData` / `EnemyData` 全部单数。根因是「`CharacterItem` 指的到底是哪一层」从未写清。同时，Profile 的存档字段名经 camelCase 单点策略机械映射为 JSON path，字段改名是破坏性契约变更——这个决定越晚做越贵。

## 决策

**集合字段名与元素类型名一律单数**——`pastEvent` / `disabledAbility` / `achievement` / `playerPower` / `characterProfile` 同形，**不开复数例外**。

**适用边界 = 两层 Profile 及其子对象的存档字段名。** 不受约束的两类：diff 报文的结构键、运行时与内容侧的集合属性（如 `EventOptionBatch.Options`）。

法宝的集合字段例外性地取 `magicPack` 而非 `characterItem`——它直接命名已定名的容器概念「储物袋」，单复数之争在该字段上因此不存在。

逐条落点、四层分工表与三条改名成立前提 → `systems/player-profile/_index.md`。

## 理由

**可机械检查是这条通则的全部价值**：一旦开一个复数例外，「这个字段该不该是单数」就要逐个读上下文，通则退化为习惯。持有一组 `CharacterProfile` 的字段名 `characterProfile` 与类型名仅首字母之差，这是被接受的代价。

三条独立成立的依据：对称性（拉回单数改一处，反向统一要改三处并推翻既有定名表）；命名族一致（内容层全部单数，复数在全库只剩泛型参数位这一个出现点）；`List<CharacterItems>` 读作「一个『多件法宝』的列表」，是两层复数的语义错误，而 C# 通行约定同向。

它是跨边界的：存档字段的 C# 名机械映射为 JSON path，故 Profile 透明段字段改名 = 破坏性契约变更，须 bump `schemaVersion` 并与后端同批改。改名的三条成立前提（线上无真实账号数据 · 两侧同批落笔 · 一次性不留双读期）此刻同时成立，这是把命名一次改到位最便宜的窗口。

## 备选方案

- **`characterItems` 复数、松动既有的单数字段风格** — 否决：需一并推翻既定的单数命名句，且与内容层命名族相悖。
- **`characterItem` 单数** — 未取：形式上正确，但 `magicPack` 让「储物袋」从只在 UX 文本里出现的词落成真实字段，少一次「概念 → 字段」的翻译。
- **保留复数、只做文档标注** — 否决：不可机械检查即等于没有通则。

## 后果

- `systems/player-profile/_index.md` 是通则的权威；`systems/character-profile/_index.md`、`terminology.md`、`program-overview.md`、`systems/architecture.md` 与各服务文档的字段清单与之对齐。
- 文件夹 `systems/player-profile/achievement/` 随通则取单数，与 `player-item/` / `player-power/` 一致。
- 透明路径白名单在 `backend-design-documents/contracts/profile-sync.md` §5，本库不复制。
- 本次为纯标识符收口，机制侧零改动、不 bump 存档 schema、无迁移。
- 储物袋字段名 `magicPack` 的定名理由后被改写为「它是视图的轮回级那一半」→ `ADR-0097`。

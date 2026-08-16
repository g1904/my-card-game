# <类型中文名>（`<TypeName>Data`）—— 类型档案

- type: <文件夹名，kebab-case>
- code-type: `<TypeName>Data`
- class-authority:                # 类定义的权威文档（「这类内容怎么运作」）
    - systems/<doc>.md
    - systems/common-properties.md   # （共有字段那一份，按实际填）
- opened: <YYYY-MM-DD>            # 由 /scaffold-content-type 开张的日期
- id-form: `<类型>.<snake_case_slug>`
- readiness: <🟢 可写实 | 🟠 部分阻塞 | 🔴 阻塞>

> **本档案不定义字段。** 下表只列**字段名 + 该条目需要作答什么 + 权威回链**；类型、取值域、枚举成员、校验语义一律在回链那侧，此处不复述（越界判据见 `../_index.md`「硬边界」）。

## 字段核对清单

> `/author-content` 逐行核对：条目文档里这一行有没有被作答。**缺一行即不能翻 `ready`。**

| 字段 | 必填 | 这个条目需要作答什么 | 权威回链 |
|---|:--:|---|---|
| `Id` | ✅ | 稳定唯一标识符，形态见上方 `id-form` | `systems/common-properties.md`「稳定 Id 键」 |
| `ContentEnabled` | ✅ | 是否随本次放量开启 | `systems/common-properties.md`「`ContentEnabled`」 |
| `<显示名 / 描述 / 风味>` | ✅ | 面向玩家的文案（`zh` 必填、`en` 可缺） | `systems/common-properties.md`「`LocalizedText`」 |
| `<Rarity>` | <✅/—> | 这条内容属哪一档稀有度 | `systems/common-properties.md`「`Rarity: RarityTier`」 |
| `<ExclusiveSource>` | <✅/—> | 是否限定某条渠道给出（默认通用） | `systems/common-properties.md`「`ExclusiveSource`」 |
| `<类型专属字段…>` | | | `systems/<doc>.md` |

## 条目形状与写作要点

> _这类内容的条目文档相对通用骨架**多出**什么、以及写作时最容易写空的地方。控制在几条，不展开机制说明（那是 `class-authority` 那侧的事）。_

- <例：敌人条目必须给出完整样本卡组，只写「攻击型卡组」等于没写>
- <例：地域条目必须给出它在 `locationMap` 上的连边，且连边是双向承诺，改边即清空玩家的账号级图鉴资产>

## 交叉引用

> _这类条目会引用哪些**别的类型**的 `Id`。`/audit-content` 据此检查悬空引用。_

| 本类型的字段 | 指向的类型 | 悬空的后果 |
|---|---|---|
| <字段> | `content/<类型>/` | <一句话> |

## 就绪度与阻塞

- **当前 readiness：** <🟢/🟠/🔴> —— <一句话理由>
- **阻塞项：** <指向 `systems/` 的待决问题或依赖的上游类型；无则写「无」>

## 条目台账

> 最新的置顶。每个条目一行。**内容不进 `requirements/_index.md`，完成度只在这里追踪。**

| id | 标题 | status | blueprint | 备注 |
|---|---|---|---|---|
| _(暂无)_ | | | | |

## Open questions

> _这个类型层面尚未拍板、且会影响条目怎么写的事项。逐条指向其权威归属文档。_

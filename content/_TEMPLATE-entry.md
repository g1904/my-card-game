# <条目显示名> —— `<id>`

- id: `<类型>.<snake_case_slug>`
- type: <类型文件夹名>
- date: <YYYY-MM-DD>
- status: draft                   # draft | ready | blueprinted | built
- source-draft:                   # 原始草稿路径（inbox/… 或「粘贴文本」）
- blueprint:                      # 链接到 .claude/blueprints/<slug>.md，由 /blueprint 回填
- references:                     # 本条目引用到的其他条目 Id（供 /audit-content 检查悬空）

## 定位

> _一两句话：这个条目在游戏里是什么、玩家遇到它时的体验是什么。不复述字段。_

## 字段填写

> 逐行对应类型档案 `_index.md` 的字段核对清单。**只写取值 + 依据，不写字段的类型定义 / 取值域**（那在权威回链那侧）。
> 取值未定的写 `⟨待定：链接到待决项⟩`——**不留空白，也不臆造**。

| 字段 | 取值 | 依据 / 说明 |
|---|---|---|
| `Id` | `<id>` | |
| `ContentEnabled` | `true` | |
| `<Rarity>` | `<TierN>` | <为什么是这一档> |
| `<类型专属字段…>` | | |

## 内容文案（`LocalizedText`）

> `zh` 必填；`en` 可缺（缺 `en` 键 = 未翻译，是合法且默认的状态）。文案与 `Id` 分离，可改动而不破坏引用。

| 字段 | zh | en |
|---|---|---|
| 显示名 | | |
| 描述 | | |
| 风味文案 | | |

## 机制细节

> _这个条目**具体做什么**，逐条写到实现侧能照着做的程度：触发时机、作用对象、数值、结算顺序、与既有机制的交互。_
> _涉及的规则语义（何为「一次结算」「一个回合」）回链 `systems/`，不在此重新定义。_

- <逐条>

## 平衡定位

> _它进哪些抽取池、权重与稀有度的依据、它相对同类条目的强度定位。数值的通则权威在 `systems/balance.md`。_

## 图鉴词条

> _仅当本类型是六本图鉴的宿主之一（敌人 / 神通 / 法则 / 法宝 / 古宝 / 地域）时填写；否则整节删除。_
> _图鉴给**静态知识**，不给动态情报（`systems/player-profile/codex/_index.md`）。_

## 美术 / 音频需求

> _需要什么视觉 / 音频资产，以及它该走哪份 guide。回链 `art/visuals/guides/`、`art/soundtracks/guides/`；不在此写 prompt。_

## 验收断言

> _可在 Godot 编辑器里运行游戏观察到的条件。**这是 `/blueprint` 直接消费的部分**——每条都要能被一个人照着核验。优先 Given/When/Then。_

- [ ] Given <状态>，when <动作>，then <可观察结果>。
- [ ] 加载期：`Id` 唯一、交叉引用不悬空、必填字段齐备，否则启动期 `GD.PushError`。

## Open questions

> _尚未拍板、且会影响这个条目怎么落地的事项。**非空则本条目不是 `ready`。** 绝不在此杜撰答案。_

## Traceability

- 由 `/author-content` 从 <source-draft> 写就
- 类型档案：`content/<类型>/_index.md`
- 类定义权威：`systems/<doc>.md`
- 去向：`/blueprint` → `/implement` → `.tres`

# Adventure Event 重命名 + 术语表 + 玩家/角色/事件数据模型

- id: 2026-07-15-adventure-event-profiles
- date: 2026-07-15
- topic: terminology（新建）、systems/adventure-event-combat（分类法）、systems/run-manager（PlayerProfile/CharacterProfile 生命周期）、systems/map-progression（AdventureEvent 图结构）
- status: distilled
- distilled-to: terminology.md, 20-systems/adventure-event-combat.md, 20-systems/run-manager.md, 20-systems/map-progression.md

## Intent（你的原话，已提炼）

一次性搭好三块**大局骨架**（架构细节尚未敲定；待系统愿景成型后再自顶向下做架构与 UX）。

### 1. 术语重构：encounter → 修行历程（Adventure Event）

- 把贯穿设计的 **encounter** 一词重命名为 **修行历程 / Adventure Event**。
- 新建一份**术语表**文档，集中追踪开发中要用到的专有术语（中文领域词 ↔ 英文/代码标识），例如 `修行历程 → Adventure Event`。它是术语的事实来源，随开发滚动更新。

### 2. 修行历程的分类法（六类，待定）

修行历程分为不同**类型**，目前拟定六类：

| 中文 | 英文 / 代码 | 直观含义 |
|------|------------|----------|
| 修炼 | Practice | 训练 / 精进，主动变强 |
| 战斗 | Combat | 回合制战斗遭遇 |
| 闭关 | Research | 闭关潜修（打磨 / 突破 / 钻研） |
| 交易 | Exchange | 交易 / 商店 |
| 社交 | Social | 与 NPC / 势力的社交互动 |
| 未知 | Mystery | 未知 / 随机事件 |

> 征求反馈：是否有更好的增补或调整？若无，则将此分类法定为一项决策（ADR 候选，见 Open questions 中的反馈后再确认）。

### 3. 数据模型骨架：PlayerProfile → CharacterProfile → AdventureEvent

一个三层的持有关系。**PlayerProfile** 是账号级主档，追踪该玩家的全部历史与数据；其下挂着一组 **CharacterProfile**，各自追踪一次可用或进行中的修行 run；每个 CharacterProfile 又持有一串 **AdventureEvent**。

- **PlayerProfile（账号级 · 跨 run 持久）**
  ```
  PlayerProfile {
    List<CharacterProfile>
    GameSetting
    List<PlayerPower>
    List<PlayerItem>
    List<Achievements>
    AccountInfo
    // etc.
  }
  ```
- **CharacterProfile（单次 run / 单个角色）**
  ```
  CharacterProfile {
    status            // defeated | ongoing | discarded | completed
    chapter           // 当前所处篇章
    Status {          // 角色即时状态
      currentHealth, healthLimit,
      currentMana, manaLimit,
      faith,
      // etc.
    }
    List<AdventureEvent>
    List<CharacterItems>
    // etc.
  }
  ```
- **AdventureEvent（修行历程节点）**
  ```
  AdventureEvent {
    List<possibleFutureEvent>   // 后续可走向的历程
    List<pastEvent>             // 已经历的历程
    // etc.
  }
  ```

**隐含结构（从上述推演，非新增机制）：**
- **PlayerProfile 是元进程（meta-progression）层**，跨 run 持久；`PlayerPower` / `PlayerItem` / `Achievements` 是账号级的解锁 / 成就，独立于任何单次 run。
- **CharacterProfile 对应一次 run 的 run 状态**（对齐既有的 RunState 概念）。一个 PlayerProfile 持有**多个** CharacterProfile，且状态含 `ongoing`——意味着可能存在**多个并存的角色存档 / 进行中的 run**（类多存档槽）。
- **AdventureEvent 的 `possibleFutureEvent` / `pastEvent` 即分支 map 的图编码**：向前是分叉的可选历程，向后是已走过的历史轨迹。这正是 `map-progression` 里「分支 map 形态待定」的一种数据表达。
- `faith`（信仰）是一个**新的角色属性**，落在既有「类 Reigns 属性平衡」的待决属性模型之内。

## Design pillars（承接）
- 呼应 vision：修行历程并非每个都是战斗——六分类法把这一支柱显性化（仅一类是 战斗/Combat）。
- 元进程脊梁：PlayerProfile 层为「跨篇章携带元进程」提供了持有结构。

## Open questions

- **「修行历程」的单复数语义。** `修行历程` 直译为「修行的历程 / 旅程」，读来偏**集合 / 全程**；而 `AdventureEvent` 是**单个节点**。单个节点是否应另用一个词（如 `修行事件` / `历程节点`），把 `修行历程` 留给整段旅程？需确认命名意图。
- **六分类法的反馈（决策前）：**
  - **缺少休整 / 恢复类？** `闭关/Research` 是否已涵盖休息、疗伤、境界突破？还是需要单列一类「休整」？
  - **篇章边界的高潮事件。** 篇章边界是记录点，通常意味着一个 boss / 精英 / **境界突破（如渡劫 / 天劫）**。它是 `战斗/Combat` 的子类，还是应独立成一类（如 突破/Breakthrough / Tribulation）？
  - **`未知/Mystery` 的层级。** 它是与其它并列的一类，还是一个**元类型**（进入后才揭示为其它某类）？语义需澄清。
  - **`修炼/Practice` 与 `闭关/Research` 的边界。** 二者都是自我精进，区分标准是什么（前者主动练功、后者闭关突破？），避免玩家认知重叠。
- **CharacterProfile 状态机。** `ongoing → defeated / completed / discarded` 的转移规则？`discarded`（主动弃置）与 `defeated`（战败）在元进程后果上有何不同？
- **多角色并存。** 是否真的支持多个 `ongoing` 的 CharacterProfile 同时存在（多存档槽），还是同一时刻至多一个 run？这影响存档架构与 run-manager 的清理边界。
- **属性模型。** `faith` 之外，`Status` 里还要平衡哪些属性，修行历程又如何推拉它们？（沿用 vision 中「类 Reigns 属性平衡」的待决项。）
- **元进程持久化范围。** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 各自的字段与解锁规则待定；账号级 meta 系统或许值得单独一份系统文档。

## Notes / triage
大局骨架 handoff。术语重构 → 新建 `terminology.md`。六分类法 → 折进 `20-systems/adventure-event-combat.md` 的意图并回答其「分类法」待决项（作为 ADR 候选，待反馈确认）。数据模型：PlayerProfile/CharacterProfile 生命周期 → `20-systems/run-manager.md`；AdventureEvent 的 possibleFutureEvent/pastEvent 图结构 → `20-systems/map-progression.md`。全篇「大局，细节未定」，故落地的多为**结构与开放问题**，而非机制断言。

# Practice / Standard 两档的失败后果：不另加规则层的额外后果

- id: 2026-08-22-combat-defeat-consequences
- date: 2026-08-22
- topic: systems/adventure-event/combat/_index.md · systems/character-profile/life-total.md · systems/balance.md · systems/services/plot-manager.md
- status: distilled
- distilled-to: systems/adventure-event/combat/_index.md, systems/character-profile/life-total.md, systems/balance.md, systems/services/plot-manager.md

## Intent（distilled）

**一句话：** `Practice` / `Standard` 两档战斗失败**不另加任何规则层的额外后果**——一次失败已经在六个方向上付出代价，只是它们此前分散在五份文档里、从未被并排列出；「看起来单薄」是**呈现问题**，不是机制问题。

### 一次失败已经付出的六条代价

| # | 代价 | 量级 / 形态 |
|---|---|---|
| ① | 扣 `lifeTotal` | `= 敌人道念 − 角色道念`，1:1 无截断；炼气基线仅 10，最坏开局落差 9 |
| ② | 已支付的 `lifeSpanCost` 打了水漂 | 无条件施加、支付先于结算、不因失败退还 |
| ③ | 占掉一个 `eventCountLimit` 名额 | 纯计数不分胜负，挤掉的是另一个本可选的事件 |
| ④ | 经验按 `FailureRatio` 折半 | 供需比仅 1.15–1.20 ⇒ 反复失败真实导致卡级，卡级的终点是寿元耗尽而等级未满 |
| ⑤ | 失去胜利侧的全部奖励厚度 | 线性加厚归零、`advantage` 三档不适用，失败只发 `baseReward` |
| ⑥ | 隐藏属性照推，且推的是同一份量 | 胜负同施一份 `HiddenStatGrade`、不套 `FailureRatio` |

### 不另加的四条依据

1. **`FailureRatio` 取 50% 的既有论证前提正是「失败已付了 `lifeTotal` 的硬代价」。** 再加一层后果等于推翻那次论证的前提——若代价不够重，该调的是 `FailureRatio`，不是在旁边并联一条新惩罚。
2. **代价 ② ③ ④ 是「隐形但真实」的三条**，它们不可见是因为结算面板不呈现，不是因为不存在。用加惩罚解决呈现不足，是给一个已被满足的需求造结构。
3. **失败已是一条通向死亡的连续曲线**：① 与 ④ 分别推向 `LifeTotalExhausted` 与寿元归 0 两条独立终结路径。再加第三条压力源改变的是**容错量**，而容错量的旋钮是 `baseMomentum` 表 / 赋级带 / `lifeSpanCost` 定价表。
4. **撞休闲定位与「炼气可无限重试」的手感。** `Practice` 被明确定位为低风险历练；`Standard` 单独加则两档失去共用同一套结算代码的前提之一。

### 两档的差异化已由三个既有旋钮自动兑现

`TurnLimit`（8 / 10）使失败时的道念差期望更小 · `WinMargin`（0 / 1）使判负门槛更靠后 · `ExperienceGrade` 档位偏置使折半后的产出已分层；外加定价表的 `combatTier` 分格。**`Practice` 的「低风险」四条全部由既有参数承担，一条新机制都不需要。**

### 结构面净改动 = 零

不新增字段、不新增枚举成员、不新增 `DefeatReason` 项、不 bump 存档 schema、不新增加载期校验。

## Clarifications（interview 产物）

- **`Practice` 能否挂负向 `OnFailureRules`？** → **软口径，不加校验**。只写内容编排口径「`Practice` 默认不挂负向 `OnFailureRules`」。裁决理由：本条整个论证是「不需要**规则层**通则」，而 `OnFailureRules` 本就是内容层的例外通道；为一个 tier 关死例外通道，是把内容编排偏好升格成结构约束，量级不匹配。（推翻了草稿中「若选硬校验则追加一行加载期校验」那一支——该校验不落地。）
- **`Practice` 失败的 `lifeTotal` 扣减是否加折扣？** → **不加，维持 1:1 三档统一**。「点到为止」与「输得够惨仍可能终结角色」的张力**交给叙事层**：`Practice` 失败的定性文案写「力竭负伤 / 自愧不如」一类，落 `plot-manager.md` 既有叙事层，零新增结构。（这把草稿里「张力交叙事层」从建议升为定案落笔。）
- **`Standard` 负向 `OnFailureRules` 的频次是否给编排口径初值？** → **给，占比 ≤ 10%，落 `balance.md`，标为待实测初值**。理由：与「内容侧走枚举档 + 平衡表映射、可对账」的既有范式一致，成本仅一行表；10% 是初值不是安全证明，校准依赖 ch1 数值标杆专场的三条前置。

## 同批承接的四项残留同步

本次一并收掉四处**别处已定、此处未同步**的残留（全部为回链式同步，不新增语义）：

1. `combat/_index.md` 的 `manaLimit` 成长口径与炼气基线写法，与 `character-profile/mana.md` · `character-profile/life-total.md` 的现行结论对齐。
2. `life-total.md` 的「与 mana 的非对称」表补「境界基线」一列——mana 是增量、`lifeTotal` 是置值，两者形态差异需在同一处可读出。
3. `combat/_index.md` 与 `balance.md` 三处「三档各推哪一档 `HiddenStatGrade`」的默认口径补上**方向**（类型权威在 `systems/architecture.md`）。
4. `balance.md` 的 `eventCountLimit` 条补一句：恒为定值 ⇒ 一章事件总数可枚举、时长反推是算术问题。

## Open questions

- 六条代价里 ② ③ ④ 的**可见性**归 `ux/combat-ux.md` 与 `ux/screen-flow.md` 的战后面板设计（寿元那一条另受 Band 门控，Band 0 / Band 1 本就不显示数字）——本次不动。
- `Standard` 负向条目占比 ≤ 10% 的实测校准，与三条前置依赖（卡牌产 / 削道念的量纲基准 · 三档 `BaseReward` / `RewardPoolId` · `lifeSpanCost` 定价表的 `combatTier` 各格）同归 ch1 数值标杆专场。

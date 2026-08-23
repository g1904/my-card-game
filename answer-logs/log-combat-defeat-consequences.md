# Answer log combat-defeat-consequences

- 日期：2026-08-22
- 来源：`inbox/solution-draft-combat-defeat-consequences.md` → `handoffs/2026-08-22-combat-defeat-consequences.md`
- 移出条数：1

---

**`Practice` / `Standard` 两档战斗失败，除按道念差扣 `lifeTotal` 外是否另有后果？（`01-combat.md` ·「内容与数值的残留」）**
→ **不另加任何规则层的额外后果。** 一次失败已有六条代价（扣 `lifeTotal` · 已付 `lifeSpanCost` 打水漂 · 占掉一个 `eventCountLimit` 名额 · 经验按 `FailureRatio` 折半 · 失去胜利侧全部奖励厚度 · 隐藏属性照推同一份量），四条依据支撑「不加」（`FailureRatio` 50% 的论证前提即「已付硬代价」· 隐形代价是呈现问题不是机制问题 · 失败已是通向死亡的连续曲线，容错量的旋钮在别处 · 撞休闲定位与「炼气可无限重试」）。两档的差异化由 `TurnLimit` / `WinMargin` / `ExperienceGrade` 偏置三个既有旋钮自动兑现。结构面净改动为零。
（归档去向：`systems/adventure-event/combat/_index.md`「结算产物」+「决策」）

同一条问题下的三项落地取向，用户逐条当面裁决：

- **`Practice` 能否挂负向 `OnFailureRules`** → **软口径，不加加载期校验**：只写内容编排口径「`Practice` 默认不挂负向 `OnFailureRules`」，保留剧情性特例的书写位。（`systems/adventure-event/combat/_index.md`）
- **`Practice` 失败的 `lifeTotal` 扣减是否加折扣系数** → **不加，维持 1:1 三档统一**；「点到为止」的张力交由叙事层承担，失败定性文案取「力竭负伤 / 自愧不如」一类。（`systems/adventure-event/combat/_index.md` · `systems/services/plot-manager.md`）
- **`Standard` 负向 `OnFailureRules` 的频次口径** → **给口径，占比 ≤ 10%**，标为待实测初值，落 `systems/balance.md`；校准依赖 ch1 数值标杆专场的三条前置依赖。

**剩余未答部分：** 六条代价中 ② ③ ④ 的**可见性**（战后面板呈现）仍归 `ux/combat-ux.md` / `ux/screen-flow.md`，本次不裁决；`≤ 10%` 的实测校准归 ch1 数值标杆专场。二者均不新增待答条目——前者属既有 UX 设计面，后者已并入既有专场登记。

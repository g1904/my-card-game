# ADR-0210 — `AbilityScope` 两级标识 = 形状化角标，不用文字不用边框色

- **状态：** Accepted
- **日期：** 2026-09-08
- **来源：** handoffs/2026-09-08-combat-ui-elements.md · answer-logs/log-combat-ui-elements.md

## 背景

随身抽屉内同时呈现轮回级与账号级两层持有物，必须有一种表达「这一条来自账号级」的方式。

## 决策

**`AbilityScope` 的两级标识 = 一枚形状化角标**，取值 `Character`（法宝 · 轮回级）/ `Player`（古宝 · 账号级）；**不用文字、不用边框色**，**与只读层共用同一套形状**。

抽屉内另**按 `AbilityScope` 分两段**（法宝段在前、古宝段在后），使角标成为确认信息而非唯一信息。

## 理由

`ux/combat-ux.md`：**不能用文字**——UI 不能靠中文名传达「这是账号级的」，且「法宝 / 古宝」共用「宝」字根；**不能用边框色**——卡框色已被卡牌类型占用，同一张小卡面上两套色系必然相撞。

共用形状的依据：同一个枚举在战斗屏只学一次。

## 备选方案

- **文字标签** — 否决：中文名不表达层级、共用字根。
- **边框色** — 否决：与卡框色两套色系相撞。

## 后果

- 约束形状角标必须与只读层（`decisions/ADR-0208-readonly-power-icon-strip-overflow.md`）共用同一套形状。
- 放弃了色彩维度作为层级编码。
- 是 `decisions/ADR-0099-combat-holdings-two-tiers.md` 中「抽屉内同时呈现两级并带 `AbilityScope` 标识」的形态补齐。

# Answer log character-technique-identity

- 日期：2026-09-10
- 来源：`inbox/archive/design-draft-character-technique-identity.md`（`/design-direction-interview` 09-10 专场）→ `handoffs/2026-09-10-character-series-identity-and-monetization.md`
- 移出条数：3 条部分答定（均收窄，未整条移出；另记方向裁决 10 项、推翻 2 项与标准默认 6 项）

## 逐条

- **全池指定下角色强度差是否仍塌缩为单一最优** → **部分答定**：「每个角色都能以合理体验通关」定为内容打磨的验收目标（含付费角色，验收口径不分轨道）；塌缩不是接受终点而是触发内容向修正的信号（调功法池、不加新机制）。（归 `systems/character-profile/_index.md`）**「是否真塌缩」仍留清单待实测。**
- **多灵根角色的强度对齐换算** → **部分答定**：区分模式定为**双机制组合**——`RequiredAffinities` 多元素 = 复合功法（宽池角色独占亮点）、`MaxCharacterAffinityCount` = 数量上限（单灵根专属补偿）；换算题自此收窄为「两类专属内容的对铺量」。多灵根角色同批确认为**确定项、后续版本、免费轨道**（双灵根批估十个）。（归 `systems/character-profile/deck/_index.md`、`_index.md`）**对铺量仍留清单。**
- **通用功法（无属性要求）的占比口径** → **部分答定**：口径定为**按稀有度分层的梯度、无硬限制**——低档通用比例高且每种灵根都有低稀有度功法、高档通用限无条件直给型、build-around 高稀有度一律带属性；`/audit-content` 按稀有度档统计作核对面（只报告不阻断）。（归 `systems/character-profile/deck/_index.md`）**逐档比例数值仍留清单（归内容阶段随 ch1 starter deck 打磨）。**

## 同批方向裁决（十轴，用户亲口拍板）

强度对齐 = 验收目标 · 通用 / 专属按稀有度分层梯度 · build-around 带属性 + 高档通用限无条件直给型 · 多灵根确定项走免费轨道 · 双机制组合区分卡池 · 首批五角压平同一复杂度档 · 绑定功法灵根构成逐角色自由定 · 具名人物 + 专属剧情钩子 · 角色商业化轨道（付费解锁系列 = 第三支、单向棘轮、整系列礼包定价、严格横向） · 神通与主动词关系逐角色自由定。

## 推翻 2 项（用户确认，权威已改写）

- **J1 · 「解锁绝不可做成付费点」等三处付费面边界** → 付费解锁角色系列成为商业化第三支。改写：`systems/character-profile/_index.md` · `systems/monetization.md` · `vision/scope.md`；ADR 侧 `ADR-0023`（决策 ⑤）、`ADR-0055`（后果段）、`ADR-0024`（「唯一付费点」收窄为 MVP 口径）就地改写；付费面五项排除与外观族 `ADR-0191`~`0195` 不受影响。
- **J2 · 「五个角色的复杂度差异本身是产品特色」** → 首批五角同档从简、复杂度谱系由后续系列展开。改写：`systems/character-profile/_index.md` · `deck/_index.md` · `ux/onboarding.md` · `ADR-0229` / `ADR-0234` 理由句；「不标推荐项」「不设统一底盘」结论保留。

## 标准默认（自动采纳）

首批五角即第一个免费系列 · 轨道字段与解锁校验形态归 `/provide-solution-draft` · 单向棘轮落为内容纪律 + `/audit-content` 核对项候选 · 占比核对面只报告不阻断 · 付费角色纳入「都可通关」验收 · 背景设定不加字段走描述文本与图鉴。

## 新增待答（同批并入 `06-meta-progression.md`）

付费角色系列的解锁载体与购买流程形态 · 双灵根批与付费系列的推出时点与主题包装 · 付费角色与专属剧情的关系。

# ADR-0255 — 付费解锁角色系列 = 商业化第三支：系列化推出 · 双向棘轮 · 整系列礼包 · 严格横向不卖强度

- **状态：** Accepted
- **日期：** 2026-09-10
- **来源：** handoffs/2026-09-10-character-series-identity-and-monetization.md · answer-logs/log-character-technique-identity.md

## 背景

角色层此前的负面边界写着「解锁绝不可做成付费点」，商业化侧写着「仅 premium bundle、唯一预留方向纯外观」。而角色是本作最自然的横向内容扩张面：五行对称、成批可铺、零规则新增。是否把它打开，是一条必须正面回答的取向题——它同时决定角色池的形态与商业化的支数。

## 决策

**开放付费解锁角色，使其成为商业化的第三支**（premium bundle · 纯外观预留之外）。

- **系列化推出**：角色按系列成批出，一个系列 5 个或 10 个、每批保持五行对称；**一个系列全免费或全付费，绝不单出一个角色**。
- **轨道属性 + 双向棘轮**：角色条目带「免费 / 付费」轨道属性，**`Track` 发布后完全不可变——`Free → Paid` 与 `Paid → Free` 都是违规**。两个方向都落为内容纪律 + `/audit-content` 核对项，不做运行时机制。首批五角永久免费恒可用（它就是第一个免费系列），双灵根首批十角走免费轨道。
  禁反方向（`Paid → Free`）的理由：老系列免费化会让已付费玩家撞上「我买的现在白送」，而本作**没有补偿通道**（补偿要求一条账号级可支配货币，已被明确关死）。代价如实写下：运营失去「把老系列免费化拉新」这一手。
- **整系列礼包定价**：5 个的系列付 4 个单解之价，10 个的系列付 8 个单解之价。
- **强度边界：严格横向、不更强。** 付费角色卖的是新玩法与复杂度，不卖强度；验收口径不分轨道。

解锁载体、字段形态、购买流程与呈现面已由后续一族 ADR 逐条落定：`decisions/ADR-0269-character-series-id-and-track-fields.md`（`SeriesId` + `Track` 两格与五条校验）· `decisions/ADR-0270-player-entitlement-character-series.md`（持有集合与 `schemaVersion` v2）· `decisions/ADR-0272-character-unlock-filter-in-life-cycle-service.md`（取池过滤）· `decisions/ADR-0273-paid-track-retirement-policy.md`（退役口径）· `decisions/ADR-0274-character-series-no-redemption-stage.md`（兑现段不存在）· `decisions/ADR-0275-store-listing-self-derived-and-gate-scoping.md`（在售清单与前置条件表）· `decisions/ADR-0276-paid-series-sale-window.md`（限时在售窗口）· `decisions/ADR-0277-paid-series-surface-enumeration.md`（推销面穷举）。
→ `systems/monetization.md`「付费解锁角色系列」· `systems/character-profile/_index.md`「角色模板池的形态」。

## 理由

`systems/monetization.md`：付费面的五项排除（付费续命 / 抽卡 / 消耗型货币 / 体力 / 广告）**逐条都不被它触碰**——它是买断式的横向内容扩张，不撤销失败、无随机付费、无消耗货币、无加速、无广告。与既有「付费的战斗价值主要由古宝承载」的分工自洽：角色轨道不为付费提供任何数值优势。

「整系列全免费或全付费」与「绝不单出一个角色」是同一条五行对称纪律的两面：单出一个角色必然破坏五行对称，而对称本身是辨识度体系的骨架。

## 备选方案

- **维持「解锁绝不可做成付费点」** — 否决：用户在知悉代价（解锁载体与付费轨道的存档 / 契约表达自此成为真实义务）后明确推翻该边界。
- **单个角色零售** — 否决：破坏五行对称，且会把「买哪个最强」变成事实上的强度选择。
- **付费角色更强** — 否决：与「免费档是可通关基准」正面冲突，且会把第三支变成 pay-to-win 通道。

## 后果

- 推翻三处既有定案：`systems/character-profile/_index.md` 的「解锁绝不可做成付费点」· `systems/monetization.md` 的「商业化仅 premium bundle、唯一预留方向纯外观」· `vision/scope.md` 以「元进程解锁在范围外」作依据的那半句。`decisions/ADR-0023-premium-entitlement-and-redemption.md`（决策 ⑤）与 `decisions/ADR-0055-character-as-content-template.md`（后果段）已就地改写，`decisions/ADR-0024-in-app-purchase-channels-in-mvp.md` 的「唯一付费点」收窄为「MVP 唯一的付费点」。
- 外观族 ADR（`ADR-0191` ~ `ADR-0195`）与付费面五项排除**原样成立、不受影响**。
- 新增真实义务：解锁载体、轨道校验与一次 `schemaVersion` bump（v2，本库第一次真实 bump）；后端承接见 `backend-design-documents/handoffs/2026-09-12-premium-character-series-unlock.md`。
- **双向棘轮的代价：** 运营既不能把免费系列改付费，也不能把老付费系列免费化拉新。与 `decisions/ADR-0273-paid-track-retirement-policy.md` 合起来，`Track == Paid` 的条目发布后既不能改轨道、也不能被永久退役。
- 系列**对成员角色零规则强制**、名与概述落 `CharacterSeriesData` → `decisions/ADR-0282-character-series-as-worldbuilding-slice.md`；付费面**不含剧情** → `decisions/ADR-0283-story-is-not-a-paywall.md`；推出次序 → `decisions/ADR-0284-series-release-order-paid-advanced-batch-first.md`。
- **玩法进度型解锁仍不做**：轨道判定的输入只有付费凭证，不引入「通关解锁下一个角色」。

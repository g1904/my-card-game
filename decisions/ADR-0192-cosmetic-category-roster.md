# ADR-0192 — 外观品类：角色皮肤为首个、卡背为第二、界面主题不做

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07b-cosmetic-monetization-shape.md · answer-logs/log-cosmetic-monetization-shape.md

## 背景

品类未定 ⇒ `art/visuals/_index.md` 的资产类目表没有任何一行对应外观付费资产，美术排期无从下手。

## 决策

**角色皮肤 = 首个品类；卡背 = 第二品类；界面主题明确不做。**

卡背的可见面 = 玩家侧抽牌堆顶 + 己方埋伏的背面，两处（`decisions/ADR-0207-card-pile-visible-faces.md`）⇒ **该品类不再被任何事实确认阻塞**。三品类的成本 / 承载对照表见 `systems/monetization.md`。

## 理由

`systems/monetization.md`：界面主题要做全套 UI 元件（九宫格、状态变体、图标），且**对未来每一个新屏永久征税**；UI 元件明写「与插画分开、不适合整图生成」，不走 AI 流水线。将来若要做，须先答「主题覆盖到哪一层」——**它不是一个可以事后收窄的承诺**。

角色皮肤反向成立：复用 `RealmArtworks` 的稀疏覆写，一套皮肤 = 1 张基础 + 至多 3 张境界覆写，零新机制、零新资产字段。

## 备选方案

- **三品类全做 / 界面主题纳入** — 否决：成本不封顶，与「外观 = 零玩法影响、可无限扩展、低风险」这条立项理由相悖。

## 后果

- 约束美术排期：皮肤走 `RealmArtworks` 稀疏覆写；`art/visuals/_index.md` 落地时补「卡背」一行。
- 放弃了界面主题这条付费面。
- 依赖 `decisions/ADR-0124-artwork-single-slot-realm-override.md` 的 `RealmArtworks` 形态成立。

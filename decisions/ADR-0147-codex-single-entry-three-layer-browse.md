# ADR-0147 — 图鉴收进主菜单单一入口，按三层结构浏览

- **状态：** Accepted
- **日期：** 2026-09-02
- **来源：** handoffs/2026-09-02-codex-entry-and-browse.md

## 背景

图鉴族共七本，存档面早已就绪，呈现面却整块空缺：主菜单入口表里没有图鉴，七本在游戏里没有任何可达路径。意图机制移除后，敌人图鉴是**事前敌人知识的唯一通道**（`decisions/ADR-0059-no-enemy-intent-telegraph.md`、`decisions/ADR-0093-information-through-encounter.md`），故浏览形态不是装饰面——读不到就等于那条通道不存在。

## 决策

**入口 = 主菜单一行 `Codex（图鉴）`**，位于 Achievement 之后、Settings 之前（Store 恒在末位）；**纯标签**——不带红点 / 角标 / 动效，无条件可见、无门禁，总完成度不上主菜单。

**浏览 = 三层结构：** `CodexIndexScreen`（七格索引）→ `CodexBookScreen`（单本，纵向滚动网格，按 `Id` 升序、不分页、首批无筛选与排序切换）→ 词条（敌人本全屏 `CodexEntryScreen`；其余五本半屏 bottom sheet）。

**未收录一律灰态占位格，只给通用锁形图标**——不给名、不给剪影，点按给一条「尚未收录」提示（触控等价，非 hover）。已收录格 = `Artwork` + 名称；只有功法本恒无视觉资产，用统一占位图。地域本在入口 / 索引格 / 完成度口径 / 文案分区 / 触控纪律五层套用统一形态，**只有单本页的内容区不套用**（它是一张逐步显影的图）。

逐屏列数、完成度分母与词条项目清单 → `ux/screen-flow.md`「图鉴族的三层浏览结构」、`systems/player-profile/codex/_index.md`。

## 理由

- **一族的立论就是「七本差别只在收录对象」**（`decisions/ADR-0037-codex-family-third-track.md`）；在最显眼的一层拆成七个平行入口等于在 UI 上否掉自己的抽象，且收益为零。
- 主菜单是账号级视图的落点，图鉴是账号级的；三条元进程积累线里另两条（PlayerPower / Achievement）都持一等入口。
- **竖屏容量**：六行按钮仍在单手可及区内；十二行会把 Store 推到需滚动才可见的位置。
- **不给未收录条目名 / 剪影**：首遇的信息差是首遇的风险定价（同上 `ADR-0093`）；剪影还要为每个条目另出一份美术资产。地域本边缘态显示真实地名是全族唯一例外（`decisions/ADR-0027-location-codex-vertex-unlock.md`），不推广到其余六本。
- 单本页逐字复用储物袋已定的网格语汇（`decisions/ADR-0097-storage-pack-two-layer-view.md`），bottom sheet 复用「随身」抽屉同款控件语言 ⇒ 净增 3 屏、零新控件类型。

## 备选方案

- **七个平行的主菜单入口** — 否决：在 UI 上否掉「七本只差收录对象」的抽象，且不比一个入口更快到达任何一本；同时挤压竖屏主菜单容量。
- **一屏七页签** — 否决：窄屏页签条溢出 + 标签截断，并占掉索引页最该放完成度的纵向空间。
- **主菜单入口显示总完成度** — 否决：把「看着它变厚」这条自持动机往外部激励挪一步；同屏 Store 已明令无角标。
- **轮回内（EventOption 选择界面）另设图鉴入口** — 否决：战斗前确认页已自动呈现已解锁敌人的词条（`decisions/ADR-0094-pre-combat-confirmation-page.md`），高频用途已被覆盖。
- **未收录格给名或剪影** — 否决：泄掉首遇风险定价，且需为每条目另出美术资产。

## 后果

- **零新增存档字段、零 `ProfileChangeSpec` 列、零提交点、零缓存文件**；Codex 不进透明路径白名单 ⇒ 后端零配合。两个 ViewModel 随屏出生 / 消亡，开屏组装一次并缓存至离屏、不进 `_Process`。条目解析不到 → `PushWarning` + 跳过该格、不阻断本屏。
- 完成度分母口径 = `AllIncludingDisabled()`；地域本只计已解锁顶点。
- 翻译键全落 `PROFILE_` 分区 / `profile.csv`，不新开 `CODEX_` 分区；词条正文 / 条目名 / 风味文案走内容层 `LocalizedText`，不进 `res://text/`。
- 相关文档因此这么写：`ux/screen-flow.md`（主菜单入口表 + 三层浏览结构三屏表）· `systems/player-profile/codex/_index.md`（族级呈现口径与完成度分母）。
- 待定项：`LocationCodex` 除连边外的词条深度未答 ⇒ 它的单本页内容区画法与词条载体随该项定。

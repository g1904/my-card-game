# 标准 —— 移动竖屏 UI（深入）

`.claude/rules/ui-input-rules.md` 的配套文档。

## 分辨率与拉伸
- 针对固定的竖屏基准分辨率进行创作（选定一个，例如 1080×1920，并记录在 `project.godot`/此处）。当前显示配置：`stretch/mode = canvas_items`，`stretch/aspect = expand`。
- `expand` 意味着在更高/更矮的设备上，长轴会出现额外空间——用**带锚点的容器**来设计，使内容重排，而非绝对定位。

## 容器优先于坐标
- 用 `MarginContainer` → `VBoxContainer`/`HBoxContainer`/`GridContainer` 构建。使用 `size_flags`、`custom_minimum_size` 与锚点。避免在其他宽高比下会失效的像素级精确摆放。
- 测试极端情况：高瘦手机（19.5:9+）、经典 16:9、平板（约 4:3）。手牌区与 HUD 在所有情况下都必须保持可用。

## 安全区
- 将可交互/关键 UI 保持在安全区内（刘海、圆角、home 指示条、摄像头挖孔）。查询 `DisplayServer.GetDisplaySafeArea()` 并据此内缩顶层边距。
- 不要把可点击项放在系统会拦截手势的极端角落/边缘。

## 触摸目标与交互
- 满足最小舒适点击尺寸（约等于 48dp）。卡牌与按钮应便于手指操作。
- 核心手势：**拖拽**卡牌以打出/指定目标，**点按**敌人/商店项，**横向滑动**在候选项间移焦；事件选项的进入是**焦点制两段点按**（点非焦点卡只移焦、点焦点卡才支付进入）——单击即进已被明确否决，误触不可逆。→ `decisions/ADR-0219-event-option-focus-tap-entry.md`
- **详情入口按「对象是否可拖拽」分化**：可拖拽的（手牌）用**点按**，不可拖拽的（`Power` 图标、关键字、灰显道具）用**长按**——长按与拖拽起手在同一根手指上争同一段时间窗，给可拖拽对象用长按会频繁误触发。触控无悬停，故长按是唯一的等价物。→ `decisions/ADR-0085-gesture-split-tap-versus-longpress.md`
- **轮回内主导航是 eventOptions 横滑等宽 carousel，不是地图屏**——它是要打磨到位的那一个手势面，卡宽跨批恒定、逐项吸附。呈现规则与手感参数的旋钮位置全部落权威，此处不复制。→ `ux/screen-flow.md`「EventOption 选择区」、`decisions/ADR-0220-event-option-carousel-n-adaptation.md`
- **候选项的排布轴由一条判据决定**：推进进程的择一走横滑，面板内的择一与列举走纵向。新增决策面按判据落位、不自选轴——复用横滑会让两个层级的操作读成同一件事。→ `decisions/ADR-0217-option-list-layout-axis-criterion.md`
- **「跳过」按作用域分档，别按全局理解**；写呈现代码前先查权威那张分档表，按全局理解会给本作不存在跳过通道的地方加一个跳过键。→ `decisions/ADR-0170-cutscene-skip-scope-split.md`
- 按下时给予视觉/触觉反馈；让拖拽的可供性明显（抬起/放大被拖拽的卡牌）。
- **寿元只落在 EventOption 选择界面的角色状态条上，形态是静态标注**（不做跳动 / 计时器动画），**不做全局 HUD、不进战斗内**。**该状态条的字段数、位宽与告警阈值全部有既定取值**，竖屏窄栏并排字宽须实测——按两位数留位会当场溢出。逐字段取值去权威查，此处不复制。→ `ux/screen-flow.md`、`systems/character-profile/life-span.md`

## 跨平台一致性
- 单一输入路径。Godot 会模拟鼠标↔触摸；仍需在真机上验证拖放。桌面键鼠与网页指针是叠加在同一套交互之上的增强，而非独立流程。
- 保持在 GL Compatibility 渲染器的限制内（也是网页导出目标）：更简单的着色器，留意低端移动设备上的填充率。

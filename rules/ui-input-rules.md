# UI 与输入规则（移动优先、竖屏）

深入配套文档：`.claude/knowledge/standards/mobile-portrait-ui.md`。

## 布局
- **竖屏是首要朝向。** 每个屏幕都以竖高为先来设计；横屏/桌面是次要的适配，而非基准。移动优先与平台约束的权威：`game-design-documents/vision/scope.md`。
- 项目显示为 `stretch/mode = canvas_items`、`stretch/aspect = expand`。用带**锚点**的 `Container` 节点（`VBox`/`HBox`/`Margin`/`GridContainer`）搭建屏幕，使布局在各种移动端宽高比（18:9、19.5:9、平板）上重新排布，而非逐像素定位。
- 尊重**安全区（safe area）**（刘海、圆角、Home 指示条）。让可交互元素远离系统保留的边缘；在需要处使用 `DisplayServer.GetDisplaySafeArea()`。
- 选定一个固定的基准分辨率/视口用于编写，其余交给 stretch 处理。

## 触控输入
- **触控优先。** 主要交互（打出一张卡、拖拽以选择目标、点按地图节点、在商店购买）必须支持触控：拖放、点按和滑动。
- 满足最小**触控目标尺寸** —— 按钮/卡牌必须在手机上能舒适地点按；不要依赖精确的光标落点。
- **没有仅悬停（hover-only）的可供性。** 桌面上通过鼠标悬停传达的任何信息都必须有触控等价物（长按、点按以查看、始终可见的标签）。
- 同时处理 `InputEventScreenTouch`/`InputEventScreenDrag` 与鼠标/指针，不用分开的代码路径 —— Godot 会模拟鼠标↔触控，但要在真实设备上验证拖放手感是否到位。

## 文案
- **UI 文案一律走 `res://text/` 翻译键，绝不写文案字面量**；`ERR_*` 键由 `code` 机械变换而来，不得手写。
  写下的每个字面量都绕过唯一的语言开关，切语言时静默留在中文；手写 `ERR_*` 会与日后新增的后端 `code` 撞键。
  键命名规范、分区表与两条审计见 `game-design-documents/ux/error-and-blocking-ux.md`；UI ↔ 内容的归属四问见 `game-design-documents/ux/_index.md`。

## 跨平台
- 一套代码库服务于移动、桌面和网页。不要按平台分叉输入逻辑；仅在某项能力确有本质差异处分支（例如把键盘快捷键作为可选的桌面增强）。
- 网页导出已使用 GL Compatibility；把着色器/特效控制在该渲染器的限制之内。

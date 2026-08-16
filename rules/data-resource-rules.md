# 数据资源规则

游戏内容（卡牌、relic/joker、敌人、遭遇战、事件、blind/ante、平衡表）是**数据**，以序列化为 `.tres` 的自定义 `Resource` 类来定义。深入配套文档：`.claude/knowledge/data/_index.md`。

## 定义
- 每种内容类型都是一个 `[GlobalClass] partial class XxxData : Resource`，带 `[Export]` 字段。实例以 `.tres` 文件的形式在项目的数据文件夹下编写。
- **每个条目都有一个稳定、唯一的字符串 `Id`。** id 是其他一切引用的键（存档文件、注册表查找、relic→卡牌交互）。绝不用场景路径、数组索引或显示名来作为内容的键。
- 显示字符串（名称、描述）是资源上的字段、与 `Id` 分离，且**类型写 `LocalizedText`，不写裸 `string`**；`Get()` 只读、绝不把解析结果写回条目。
  裸 `string` 把语言数焊进 C# 类、线上补一句文案就得发版；写回则污染 ContentRegistry 里的共享只读单例。
  形态与失败语义见 `game-design-documents/systems/common-properties.md`「内容文本的多语言形态」。

## 注册表 / 加载
- 单一的 **DataRegistry** 自动加载在启动时加载每种类型的全部 `.tres` 并按 `Id` 建立索引。玩法代码通过注册表查找内容，而非到处散落 `ResourceLoader.Load` 调用。
- **从内容集合抽取一律经仓储的 `AllEnabled()` 取池**——仓储上没有中性名 `All()`（全量口径叫 `AllIncludingDisabled()`）。
  漏写过滤 = 线上放量开关失效，且**能上线、线上不可见**。
  `ContentEnabled` 的语义、读取侧不过滤的理由、校验与编译闸形态见
  `game-design-documents/systems/services/content-service.md` 与 `game-design-documents/systems/common-properties.md`。
- **坏数据必须在启动期大声失败**：注册表加载时全量校验，违规项以 `GD.PushError` 报出其 id / 路径（参见 `null-check-rules.md`）。
  漏校验的数据会在轮回中途才崩，届时现场已丢、玩家进度已废。
  校验口径见 `game-design-documents/systems/services/content-service.md`。

## 平衡与配置
- 可调数值（花费、伤害、掉落权重、ante 缩放）存放在导出字段或专门的平衡资源中 —— **不**硬编码在系统逻辑里。系统从数据中读取数值。
- 让内容保持可加性：新增一张卡牌 = 新增一个 `.tres`，而不是编辑某个 switch 语句。在可行处，优先使用数据驱动的效果定义，而非逐卡编码。

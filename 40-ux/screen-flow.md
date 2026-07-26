# screen-flow

> 屏幕流程:菜单 -> run -> 地图 -> 战斗 -> shop -> 设置。

## 意图

完整前置流程:**登录屏 → 主菜单 → (切换篇章) → run**。

- **登录屏(应用首屏)。** 含**服务条款(T&S)**;背景是一段 **live2d 风格循环动画视频**(氛围演出,美术 TBA,先留空占位)。登录入口用于**在线存档**:**微信 / QQ / 邮箱 / 手机号**。**强制账号登录——已移除游客(Guest)入口**,不再支持不登录直接进入。Source: `10-handoffs/2026-07-16-ux-flow-login-and-dev-order.md`;去游客 `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **主菜单(登录后)。** 核心操作是**切换篇章以开始一次 run**——在**已解锁**篇章中择一作为该次 run 的起始篇章。首玩者**只能从炼气(第一篇章)开始**,其余篇章选项**隐藏**,后续解锁后才出现(门禁细节见 `onboarding.md`)。
- **主菜单入口按钮**(各自是 PlayerProfile 数据模型的视图层,对应 `20-systems/services/life-cycle-service.md` 的账号级字段):

  | 按钮 | 内容 | 对应 PlayerProfile 字段 |
  |------|------|------------------------|
  | PlayerProfile(玩家档案) | 状态与账号信息(`AccountInfo`) | `AccountInfo` |
  | PlayerPower(玩家能力) | always-available 能力,带**开关(默认开启)**;QoL 或影响公平性的全局加强,不与角色绑定 | `List<PlayerPower>` |
  | Achievements(成就) | 分组成就;玩家**只能查看进度 / 领取奖励**;奖励按**组内加权进度**发放,分 **60% / 90% 两档一次性奖励**(见下) | `List<Achievements>` |
  | Settings(设置) | 音量等常规系统设置 | `GameSetting` |

  Source(能力 / 成就语义、加权发放):`10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。

- **成就发放细化(已定案)。** 每个类别按**组内加权进度**分**两档一次性奖励**:加权进度达 **60%** 发一次、达 **90%** 再发一次;**两档奖励不同,且都为一次性**。**成就目录 80% 条目可见、20% 为隐藏成就**,达成后才显示。(发放**何种**奖励 —— PlayerPower / PlayerItem / 账号级 —— 仍待定。)Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **登录渠道优先级。** 移动端优先(手机 / 邮箱)→ 微信 / QQ 其次 → 海外 / 跨平台最后。**已移除游客**入口。Source: `10-handoffs/2026-07-22-...`;去游客 `10-handoffs/2026-07-23-...`。
- **登录屏循环视频 = `VideoStreamPlayer`(已定)。** 用 `VideoStreamPlayer` 实现循环视频背景。Source: 同上。
- **美术挂点占位。** 循环视频、图标、卡面等 TBA;组合场景时为其保留可轻松替换的挂点,先用占位 / 免费资源。Source: `10-handoffs/2026-07-16-ux-flow-login-and-dev-order.md`。

## 决策(-> ADR)
> _已敲定的决定链接到 50-decisions/ADR-####。_

## 待解问题

- ~~**游客 → 登录的账号迁移**~~ → **已解答(取消问题):** 游客态已**彻底移除**,强制账号登录,不存在游客→登录迁移。Source: `10-handoffs/2026-07-23-...`。
- **成就发放的奖励内容:** 阈值(60% / 90%)、一次性、80/20 可见比例**已定**(见「意图」);仅剩**两档各发放何种奖励**(PlayerPower / PlayerItem / 账号级)待定。
- **PlayerPower 细化:** 语义已定(全局、可开关、可获取 / 失去);但**获取 / 失去的具体触发**、是否影响 run seed / 计分公平性、平衡边界仍待定。→ `20-systems/player-profile/player-power/`。
- Source(未决项):`10-handoffs/2026-07-16-...`;语义裁定 `10-handoffs/2026-07-22-...`。

## 提供给
提炼进:`.claude/knowledge/scenes/_index.md`

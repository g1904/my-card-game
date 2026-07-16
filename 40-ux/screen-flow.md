# screen-flow

> 屏幕流程:菜单 -> run -> 地图 -> 战斗 -> shop -> 设置。

## 意图

完整前置流程:**登录屏 → 主菜单 → (切换篇章) → run**。

- **登录屏(应用首屏)。** 含**服务条款(T&S)**;背景是一段 **live2d 风格循环动画视频**(氛围演出,美术 TBA,先留空占位)。登录入口用于**在线存档**:**微信 / QQ / 邮箱 / 手机号**。也可 **游客账号(Guest)** 直接进入不登录。Source: `10-handoffs/2026-07-16-ux-flow-login-and-dev-order.md`。
- **主菜单(登录后)。** 核心操作是**切换篇章以开始一次 run**——在**已解锁**篇章中择一作为该次 run 的起始篇章。首玩者**只能从炼气(第一篇章)开始**,其余篇章选项**隐藏**,后续解锁后才出现(门禁细节见 `onboarding.md`)。
- **主菜单入口按钮**(各自是 PlayerProfile 数据模型的视图层,对应 `run-manager.md` 的账号级字段):

  | 按钮 | 内容 | 对应 PlayerProfile 字段 |
  |------|------|------------------------|
  | PlayerProfile(玩家档案) | 状态与账号信息 | `AccountInfo` |
  | PlayerPower(玩家能力) | 可开 / 关的特殊能力 | `List<PlayerPower>` |
  | Achievements(成就) | 分组成就;某组达成度到 **90%** 时自动发放该组奖励 | `List<Achievements>` |
  | Settings(设置) | 音频开 / 关等 | `GameSetting` |

- **美术挂点占位。** 循环视频、图标、卡面等 TBA;组合场景时为其保留可轻松替换的挂点,先用占位 / 免费资源。Source: 同上。

## 决策(-> ADR)
> _已敲定的决定链接到 50-decisions/ADR-####。_

## 待解问题

- **登录屏循环视频的技术实现:** `VideoStreamPlayer`(Theora/WebM) vs live2d 风格骨骼 / 序列帧?影响 GL Compatibility + 移动 / 网页导出下的资源管线与包体(架构待决)。
- **游客 → 登录的账号迁移:** 游客先玩、后登录时,本地进度如何并入云端账号(合并 / 覆盖 / 提示选择)?
- **登录方式的平台边界:** 微信 / QQ 主要面向国内移动端;桌面 / 网页 / 海外 iOS 的回退(邮箱 / 手机号 / 游客)是否为跨平台基线?
- **成就自动发放语义:** 90% 按组内数量还是加权进度?发放何种奖励(PlayerPower / PlayerItem / 账号级)?一次性还是可复触发?
- **PlayerPower「开 / 关」语义:** 玩家自选修改器(影响难度 / 计分)还是解锁后可装配的被动?是否影响 run 的 seed / 公平性?
- **篇章解锁条件:** 见 `onboarding.md`——解锁触发与「篇章存档角色是有限资源」模型如何衔接。
- Source: `10-handoffs/2026-07-16-ux-flow-login-and-dev-order.md`。

## 提供给
提炼进:`.claude/knowledge/scenes/_index.md`

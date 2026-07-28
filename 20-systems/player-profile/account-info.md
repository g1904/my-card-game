# account-info

> 账号信息 / **AccountInfo** —— PlayerProfile 上的账号身份与状态元数据。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **AccountInfo = 账号身份与状态元数据。** PlayerProfile 的一个账号级字段，承载登录身份与账号状态；是主菜单「PlayerProfile（玩家档案）」按钮的数据来源。Source: `40-ux/screen-flow.md`。
- **强制账号登录（无游客态）。** 登录渠道优先级：移动端手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台；**游客入口已彻底移除**，因此不存在游客→登录的账号迁移。Source: `50-decisions/ADR-0003-online-cloud-authority.md` + `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **服务归属：登录与身份归 `account-service`，持久化经 `profile-service.ProfileManager` 写入、`sync-service` 同步。** Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **本子系统为独立 markdown（已定案）。** 结构轻，不成文件夹——与 `player-item/` / `player-power/` / `achievements/` 三个文件夹子系统区分。Source: `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **强制在线 · 云端权威 · 重账号** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **字段 schema 未定：** 承载哪些字段（账号 id、绑定渠道、昵称 / 头像、注册时间、封禁 / 实名状态？）未设计。多渠道绑定到同一账号的模型亦未定。
- **合规字段的归属：** 实名 / 未成年人限制等合规要求落在客户端还是纯后端，权威在 `backend-design-documents/open-questions.md`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/account-info.md`（待建）。

# account-info

> 账号信息 / **AccountInfo** —— PlayerProfile 上的账号身份与状态元数据。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **AccountInfo = 账号身份与状态元数据。** PlayerProfile 的一个账号级字段，承载登录身份与账号状态；是主菜单「PlayerProfile（玩家档案）」按钮的数据来源。Source: `ux/screen-flow.md`。
- **强制账号登录（无游客态）。** 登录渠道优先级：移动端手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台；**游客入口已彻底移除**，因此不存在游客→登录的账号迁移。Source: `decisions/ADR-0003-online-cloud-authority.md` + `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **服务归属：登录与身份归 `account-service`，持久化经 `profile-service.ProfileManager` 写入、`sync-service` 同步。** Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **`AccountSeed`（`ulong`）= AccountInfo 上的账号级随机种子（已定案 · 08-09b）。** 账号创建时**由后端下发**，跨设备一致、终身不变。**唯一消费者是道统残卷的掷骰**——`roll = Hash64(AccountSeed, FinaleWinOrdinal) mod 10000`（见 `player-power/_index.md`）。
  - **它不进 `SeedManager`、不进四条子流清单**，因此不触及「增删子流不 bump schema 版本」那条纪律，也**不影响轮回的可复现性**（不派生自 `CycleSeed`、不消耗任何子流 `State`）。
  - **它同时是一条客户端 ↔ 后端契约**：种子在后端，客户端掷骰、后端可离线复算任一次掷骰结果，防篡改能力不因客户端执行而丢失。下发时机、复算不一致时的处置归后端库，见 `backend-design-documents/open-questions.md`。
  Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。
- **本子系统为独立 markdown（已定案）。** 结构轻，不成文件夹——与 `player-item/` / `player-power/` / `achievement/` 三个文件夹子系统区分。Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **强制在线 · 云端权威 · 重账号** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **字段 schema 未定：** 承载哪些字段（账号 id、绑定渠道、昵称 / 头像、注册时间、封禁 / 实名状态？）未设计。多渠道绑定到同一账号的模型亦未定。
- **合规字段的归属：** 实名 / 未成年人限制等合规要求落在客户端还是纯后端，权威在 `backend-design-documents/open-questions.md`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/account-info.md`（待建）。

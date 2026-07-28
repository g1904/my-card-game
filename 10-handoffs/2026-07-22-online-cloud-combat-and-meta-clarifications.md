# 强制在线云端 + 战斗模型(life+mana) + 一批元进程澄清

- id: 2026-07-22-online-cloud-combat-and-meta-clarifications
- date: 2026-07-22
- topic: 承接并裁定多份既有 Open questions；feeds scope、run-manager、map-progression、adventure-event-combat、energy-economy、references、screen-flow、onboarding、terminology
- status: distilled
- distilled-to: 00-vision/scope.md, 00-vision/references.md, 20-systems/run-manager.md, 20-systems/map-progression.md, 20-systems/adventure-event-combat.md, 20-systems/energy-economy.md, 40-ux/screen-flow.md, 40-ux/onboarding.md, terminology.md

## Intent（你的原话，已提炼）

一批集中裁定，回答了此前多份 handoff 遗留的 Open questions，并**推翻**了 `2026-07-16` 关于「离线可玩 + 云同步混合模型」的方向。

### 1. 存档模型（**推翻 07-16 的混合模型**）
- **去除离线游玩功能：必须在线，进度实时同步云端。**
- **一切以云端为准**——这同时裁定了此前的「同步冲突解决」Open question：**冲突时云端权威**。
- 影响：`00-vision/scope.md` 原「离线可玩 + 云同步混合模型（本地 `user://` 权威）」被取代；MVP 的「离线可玩」被取代。这也与项目根约定 `.claude/CLAUDE.md`「玩法完全离线」直接冲突（见 Open questions，需确认是否连同工具约定一并调整）。

### 2. 战斗模型（**回答既有 Open question**）
- **参考 Magic: the Gathering 与 Hearthstone 的 life + mana 系统。**
- 与既有 `CharacterProfile.Status` 的 `currentHealth/healthLimit`、`currentMana/manaLimit` 字段一致——生命 + 法力（mana）双资源模型，而非 StS 纯 HP 或 Balatro 的 chips×mult。

### 3. 节点形态（**回答既有 Open question**）
- 节点 / 修行事件的呈现形态**参考《月圆之夜》风格**（精心策划的事件菜单，而非 StS 式完全分支地图）。
- 重申重构：**把所有 `encounter` 重构为 `AdventureEvent`**——encounter 即 AdventureEvent（术语层已完成；此处将重构范围明确扩展到代码 / 知识笔记中残留的 `encounter` 命名）。

### 4. 篇章继承（**回答关键 Open question**）
- **篇章继承上一篇章的所有信息。** 读档续章时角色带入下一篇章的是**全部**内容（deck、法宝、属性、叙事标记等），无逐项筛选。

### 5. 角色状态分类法（**回答 discarded vs defeated**）
- `discarded` 与 `defeated` **都是终态**，其数据都会被清理。
- **合并为单一终态 `defeated`**；`discarded` 改为 `defeated` 的一个**类型 / 原因**（主动弃置是战败的一种）。
- 由此 `CharacterProfile.status` 收敛为 `ongoing | defeated | completed`（`defeated` 内含 discarded 等原因子类型）。

### 6. 「每篇章至多一个 ongoing」精确语义（**确认既有解读**）
- 每个篇章内，玩家可继续游玩的角色**只能有一个**：只要有一个角色在该篇章尚未结束进程（ongoing），就**不能在该篇章使用其他角色游玩**。
- （不同篇章之间可各自并行，与既有解读一致。）

### 7. 重试上限（数值）
| 阶段 | 起手 / 来源 | 重试上限 |
|------|------------|----------|
| 第一章（炼气→筑基） | 随机角色起手 | **10000**（近乎无限） |
| 第二章（筑基→金丹） | 每个第一章完结的角色 | **3** 次 |
| 第三章（金丹→元婴） | 每个第二章完结的角色 | **2** 次 |
| 「第四章」 | — | **1** 次 |
- 每个篇章挑战成功则该角色进入下一境界；**不能重试之前的篇章**。
- ⚠️ **矛盾**：术语与 map-progression 现定为**四境三篇章**（炼气/筑基/金丹/元婴 → 三段攀登）。本条却列出「第四章」。见 Open questions。

### 8. 篇章解锁触发条件（**回答既有 Open question**）
- **解锁触发 = 角色通关上一篇章**，随即成为下一篇章的**可挑战角色**。
- 若某篇章**没有可重试 / 可挑战的角色**，该篇章**重新进入锁定状态（隐藏）**。

### 9. PlayerProfile 账号级字段（澄清语义）
- **PlayerPower**：always-available 的能力，带一个**开关，默认开启**。可以是 **QoL**，也可以是**影响公平性的一定加强**（需衡量平衡性），**通常是全局性加强、不与角色绑定**。玩家获取更多 power 确实让后续游戏更容易；但 **AdventureEvent 过程中也可能失去**已获取的 PlayerPower。
- **PlayerItem**：有**使用次数限制**的道具。
- **Achievements**：成就系统，玩家**只能查看进度、领取奖励**；奖励发放**按照组内加权进度**（裁定此前「90% 按数量还是加权」的 Open question：**加权进度**）。
- **GameSetting**：音量大小等常规系统设置。
- **AccountInfo**：玩家账户信息。

### 10. 平台优先级（登录渠道 / 目标平台排序）
- **移动端优先**（手机 / 邮箱 / 游客登录）。
- **微信 / QQ 登录接入其次。**
- **海外与跨平台最后考虑。**

### 11. 登录屏循环视频技术实现（**回答架构 Open question**）
- 用 **`VideoStreamPlayer`** 实现登录屏循环视频背景。

## Open questions

- **强制在线是否连带推翻项目根约定？** 本次「去除离线、必须在线、云端为准」直接冲突于 `.claude/CLAUDE.md` / 规则里的「玩法完全离线、`user://` 持久化、无网络」这一根级约定，也推翻了 `2026-07-16` **刚由你确认**的混合模型。我已按新意图取代 `scope.md`；但工具约定（`.claude/rules/state-save-rules.md` 的「仅离线」等）尚未改动——**是否要连同这些工具规则一并调整为在线优先？** 这是对近期已确认决策的反转，请确认。
- **强制在线与「移动优先、可离线单手玩」支柱的张力。** 强制在线意味着无网时不可游玩——与「手机上随时可玩、玩法不依赖网络」的移动手感有冲突。是否接受（例如：允许短暂断线缓冲后再同步，仍以云端为最终权威）？还是「必须在线」是硬性？
- **「第四章」矛盾（需确认）。** 重试表列出第四章（1 次），但现定为**三篇章**（四境）。我的解读有二：(a) 实际是四篇章 / 五境（术语需扩展）；(b) 笔误，「第四章」应为第三章、或指元婴之上的隐藏 / 终局篇章。**倾向 (b)：三篇章，重试上限为 ch1=10000、ch2=3、ch3=2**；「第四章一次」可能是把终局突破另算。请拍板篇章总数。
- **重试上限是否为最终平衡值？** 10000/3/2/1 看起来是设定值而非占位；确认它们是正式数值（→ `30-content/balance.md`）还是仍可调。
- **PlayerPower 平衡边界。** 「可影响公平性的全局加强、越多越容易」需要防止 pay/grind-to-win 失衡；获取与失去 PlayerPower 的具体触发、以及是否影响 cycle seed / 计分公平性仍待定。
- **强制在线下的后端 / 账号系统选型、合规**（PIPL、渠道审核、账号注销 / 数据导出）仍未定——由「可选云同步」升级为「强依赖后端」，优先级与风险上升。
- **游客态在强制在线下的语义。** 平台优先级仍保留「游客」入口；但「必须在线同步云端」下，游客账号是**在线匿名账号**（服务端有记录、后续可绑定）还是仍有本地成分？游客→登录迁移随之改变。

## Notes / triage

承接式批量裁定。路由：
- 存档模型反转（在线 / 云端权威）→ `00-vision/scope.md`（取代混合模型段与 MVP 离线条）+ `20-systems/run-manager.md`（同步冲突 = 云端权威）。**ADR 候选**：以「强制在线 · 云端权威」取代先前「混合存档」ADR 候选。
- 战斗模型 = life + mana（MTG / Hearthstone）→ `20-systems/adventure-event-combat.md` + `20-systems/energy-economy.md`（mana 资源）+ `00-vision/references.md`（新增两条参照）。
- 节点形态 = 月圆之夜风格 → `20-systems/map-progression.md`（节点 map 形态）+ `references.md`（补「借鉴」）。
- 篇章继承（全部）、状态分类法（defeated 单终态）、ongoing 语义、重试上限、篇章解锁、PlayerPower/PlayerItem/Achievements 语义 → `20-systems/run-manager.md`、`20-systems/map-progression.md`、`40-ux/onboarding.md`、`40-ux/screen-flow.md`。
- 成就加权发放、视频 = VideoStreamPlayer、平台优先级 → `40-ux/screen-flow.md`、`00-vision/scope.md`。
- 新术语 PlayerPower / PlayerItem / life+mana → `terminology.md`。

## 更新（同 session 用户裁定，2026-07-22）

- **篇章总数 = 四境三篇章（确认）。** 草稿第 7 条的「第四章」为笔误。
- **重试上限（定案）：** 第一章（炼气→筑基）= **无限**；第二章（筑基→金丹）= **3**；第三章（金丹→元婴）= **1**。（取代草稿的 10000 / 3 / 2 / 1。）
- **强制在线为重大反转，已授权更改项目根约定。** 用户确认：更改 `.claude/CLAUDE.md`（Context.md）、`.claude/rules/state-save-rules.md` 及相关知识笔记为「强制在线 · 云端权威」，并**确立治理原则：任何决策（含根约定）都可被后续更权威的用户意图推翻重构**（已写入 `Context.md` 约定首条）。

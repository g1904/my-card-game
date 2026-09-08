# Answer log stale-wording-roundup

- 日期：2026-09-06
- 来源：`inbox/solution-draft-stale-wording-roundup.md` → `handoffs/2026-09-06-stale-wording-roundup.md`
- 移出条数：0（本次答定的六条失真项均登记在 `open-questions.md`「derive 就绪度」小节而非 `open-questions/` 分片，无分片条目可移；逐条裁定记录如下，供下次全量评估对账）

## 逐条裁定

- **`game-progression.md:195` 与 `:57` 自相矛盾（台账 :69）** → 不成立（已修）——主题文档侧已在 09-06 前批落笔中收口，只余台账更正（`open-questions.md`「derive 就绪度」小节删该条 + `:125` 行删失真尾注）。顺带：同文件 `## 待决问题` 面上以「已明确」开头的已定案条目（可用结束点 = 存档点 · 章首重试）整条删除，事实由正文与 `decisions/ADR-0004-realm-checkpoint-retry-model.md` 承载。（`systems/game-progression.md`）
- **`item/` 两份抬头「占位结构，细节待定」（台账 :70）** → 不成立（已修）——两抬头已是实质内容、全目录零命中，两份 item 文档零改动，只余台账更正。
- **`exchange/_index.md` 决策节的「ADR 候选，待 `/write-adr` 立档」（台账 :71）** → 成立——`ADR-0126` 已于 08-30 Accepted，候选标记替换为回链。（`systems/adventure-event/exchange/_index.md`）
- **`account-info.md` 唯一待决项「合规字段的归属」（台账 :72）** → 成立——已被对侧穷尽答死（`backend-design-documents/contracts/compliance.md`「不下发」+ 被否决项 · `contracts/auth.md` §1a；客户端承载在 `account-service.md` 的 `ComplianceManager`），待决项撤销、`## 意图` 补正面陈述「合规域一格也不落 `AccountInfo` ⇒ 字段表不因合规增行」。对侧库零改动。（`systems/player-profile/account-info.md`）
- **animations「须可跳过 / 可加速」 vs combat-ux「只能加速不能跳过」（台账 :73）** → 成立——按 `decisions/ADR-0086-lifo-resolution-and-combat-log.md`（Accepted，「无玩家侧的暂停 / 跳过控件」）裁给 combat-ux 侧；animations 按作用域分档改写，`ux/combat-ux.md` 一字不动。（`art/visuals/animations/_index.md`）
- **战斗外演出是否允许跳过（第 5 条的作用域边界，草稿唯一取向题）** → **用户裁决（2026-09-06 批量评审）：选项 A——战斗外的演出默认允许跳过 / 快进，只有战斗内的结算演出不可跳过。** 承接项（战斗外跳过控件的统一形态：触点、是否记忆偏好）并入 `animations/_index.md` 的 `## 结构` 文本，不提前新建 `animation-direction.md`。（`art/visuals/animations/_index.md`）
- **`profile-schema-versions.md` 结构与全库不同构（台账 :74）** → 成立——补齐 `## 意图` / `## 决策(-> ADR)`（`ADR-0158` · `ADR-0145` 两行回链）/ `## 待决问题`（achievement 承接项 + golden 快照排期项）三个标准小节，只写回链与承接、不复述字段规格；原文三处（`achievement` 段 · golden 快照格 · 落地时点）不动。（`systems/services/profile-schema-versions.md`）

# Answer log mechanism-contradiction-roundup

- 日期：2026-09-06
- 来源：`inbox/solution-draft-mechanism-contradiction-roundup.md` → `handoffs/2026-09-06-mechanism-contradiction-roundup.md`
- 移出条数：0（五条矛盾登记在 `open-questions.md`「derive 就绪度」小节，该小节归 `/assess-derive-readiness` 独占写入，不属分片条目；本 log 记录五条裁定供下次全量评估对账）

## 逐条裁定

- **① Exchange 待决措辞同批两份打架（四组全欠 vs 两组待定）** → 矛盾成立；`exchange/_index.md` + `balance.md` 待决区一侧为准，`exchange/common-properties.md` 是 09-05 落笔批的机械遗漏——待决条收窄为两组、补登 09-05 handoff 进 `Source:`；`balance.md` 自己的「三组待定」转发条同批对齐（orchestrator 授权的同型残留）。（归档去向：`systems/adventure-event/exchange/common-properties.md`、`systems/balance.md`）
- **② 战后奖励候选池三类混合 vs 神通 `CombatReward` 通道** → 矛盾成立；`power/_index.md` 内容编排口径（ADR-0152 / ADR-0153）为准——候选池改四类混合 + `Practice` 档整族排除 `PowerData`，新增「神通候选的两条口径」子条，`balance.md` 战后奖励池族维度同批改四类。五条中唯一有实质 derive 结构后果的一条（第 23 步候选生成器形态）。（归档去向：`systems/services/combat-service.md`、`systems/balance.md`）
- **③ `lossPerMomentum` ch2 / ch3「三种口径」** → **矛盾不成立**：三处实质结论逐格一致（ch1 = 10 锁定 · 候选值 5 / 10 · 均未定案 · 形状锚校验已过），就绪度小节所依前提「09-03 反推已做完」被该 handoff 自己的 Open questions 否定。仅做措辞对齐：「定案待反推」→「定案待『典型道念差的实际分布』实测」。取值仍待答，留在 `systems/balance.md` 待决区。（归档去向：`systems/character-profile/life-span.md`）
- **④ `life-cycle-service.md` 的 `experiencePoint` 待决条** → 矛盾成立；`balance.md` / `game-progression.md` 一侧为准（阈值曲线 · `ExperienceGrade` 给予量 · 池覆盖率 · 失败折算四项均已定值），待决条整条删除，风险提示由 `balance.md` 独占不留副本。（归档去向：`systems/services/life-cycle-service.md`）
- **⑤ `systems/_index.md` 残留「意图（三档揭示）」及三处论据 + references 借鉴项** → 矛盾成立；ADR-0059（Accepted）为准——索引行整格替换（并顺带修「抽/弃/洗」→「不重洗」、补两个漏登 manager），`deck/_index.md` 三处已伪论据修正，`vision/references.md` 借鉴项改「其意图预告一族本作不采用」（用户已确认）。（归档去向：`systems/_index.md`、`systems/character-profile/deck/_index.md`、`vision/references.md`）

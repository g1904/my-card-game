# Answer log grant-source-per-kind-scope

- 日期：2026-08-12
- 来源：`inbox/solution-draft-grant-source-per-kind-scope.md`（`status: decided`）→ `handoffs/2026-08-12b-grant-source-per-kind-scope.md`
- 移出条数：1（并连带在评审阶段答定 4 项取向）

## 逐条

**⚠ `Source` 三值封闭清单与轮回级两类的取值冲突（原在 `open-questions/06-meta-progression.md`；同条并列于 `systems/common-properties.md` 的 `## 待决问题`）** → **两个候选收口全部否决，改为扩清单**：`Source` 从封闭三值改为**按 `(Kind, Scope)` 分域的七值开放清单**（`Unknown=0` · `FinaleWin=1` · `PremiumBundle=2` · `AchievementReward=3` · `EventOutcome=4` · `CombatReward=5` · `ExchangePurchase=6` · `InitialGrant=7`），分域约束由**合法子集校验表**承载而非类型系统（保留单一枚举，不拆四个）。**推翻 08-10b 的「成员清单已穷举、只有三条途径」与「清单是封闭的」**；「**不为置换所得预留成员**」那半句**保留并强化为禁令**。校验取「**入口严、读档宽**」：`Op == Grant` 时非法组合或 `Unknown` → `PushError` + 整批拒绝；读档遇不合法的既有条目 → `PushWarning` + **保留原值**（回落 `Unknown` 会压低残卷的 `x` 并让档位回跳）。**残卷 `x` 的口径与「单调不减 ⇒ 档位只降不回跳」完全不变**；**不 bump 存档 schema**。（归档去向：`systems/common-properties.md`「授予来源共有字段」整节 · 四类各自的 `common-properties.md` · `systems/services/profile-service.md` · `systems/player-profile/player-power/_index.md` · `systems/player-profile/_index.md`）

### 评审阶段一并答定的四项取向

1. **法则 / 古宝是否接受 `EventOutcome` / `ExchangePurchase`** → **暂不开放**（校验表三格标 ❌ + ※ 注脚：是「暂不开放」而非「语义上不可能」，日后开放 = 翻一格，无结构改动）。（`systems/common-properties.md`）
2. **`EventOutcome` 与 `CombatReward` 是否合一** → **分成两个成员**。（同上）
3. **`InitialGrant`（开局初始持有）是否单列** → **单列成员**。（同上）
4. **轮回级两类的 `SourceCode` 是否单列同步口径** → **不单列**，升格为一条通则：「一个字段不为『部分落点无规则消费点』而拆出第二套同步口径」。（`systems/player-profile/_index.md` 的两层通则）

## 未完全答结、仍留在待答清单的部分

- **`Source` 在上行负载里的序列化形态**（整数 code vs `contracts/envelope.md` 的字符串枚举名）——**本次不裁决，收口归后端库**，新立于 `open-questions/05-service-contracts.md`。不阻塞扩清单落地。
- **`EventOutcome` 与 `CombatReward` 是否终将合并**——取决于 `Spoils` 与事件 outcome 是否确为两条组装路径，新立于 `open-questions/06-meta-progression.md`。
- **法则的第三条获取渠道**（决定校验表那三格 ※ 何时翻转）——仍挂在 `systems/player-profile/player-power/_index.md` 的既有待决项上，不阻塞。

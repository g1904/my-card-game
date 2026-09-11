# Answer log flags-zero-load-code

- 日期：2026-09-09
- 来源：`inbox/archive/solution-draft-flags-zero-load-code.md` → `handoffs/2026-09-09-flags-zero-load-no-dedicated-code.md`
- 移出条数：1（`open-questions/01-contracts.md` 的唯一待答项；该分片待答清单随之**清零**）

---

**flags 端点零装载时的错误应答是否值得一条专属 `code`** → **不值得，维持兜底的 `server.unavailable`（`class: Retryable`）。**

判据（自 `envelope.md` §6 台账既有条目的裁决理由归纳而来，逐条套用）：客户端处置与一般断线降级**逐字相同** · 玩家面为空（flags 拉取失败从不落屏，`ERR_*` 键永不被取用） · `class` 相同、无档位污染 · 客户端在这条路径上不消费任何 `detail` · 「两条曲线」的两个限定均不成立——区分所需的事实**就在服务端自己的进程内**（「本实例已装载的键集是否为空」已在供两条 gauge 用），且本库已有「同码 + 指标层分辨」的既定解法（`sync.conflict`）。端点错误清单的封闭性反向支持不新增。

**承重推论**：「绝不把空 `disabledIds` 持久化为降级值」这条纪律是**结构性成立**的（错误应答体不含 flags 报文任何字段，服务端保证 F7 已写成可验收断言；客户端缓存的写入时点唯一 = 一批 flags 通过单调闸并被应用之后），**与 `code` 取什么值完全无关** ⇒ 专属码解决不了它宣称要解决的问题。

归档去向：`contracts/envelope.md` §6「台账的承重项」（**表本身零增减**，守 P-1）· `contracts/content-manifest.md` B 组末段 · `systems/content-delivery.md`「回源失败的降级」· `operations/observability.md`（零装载失败计数器，把可见性从契约转移到指标后真的落下来）。

---

**同批的一处记述修改**：`open-questions.md` 原写「derive `/v1/content/flags` 时按兜底码落笔**并标注该条可能后续替换**」——后半句随本条销号删去。那句注记是**悬项状态**的产物、不是结论的一部分，留着会让 FR 的验收标准无法机械核对。

**本次无取向项待裁决**（草稿自陈 0 项，校验后确认七条判据无反例）。**未新增任何待答项。ADR 零新增**——本条是既有台账判据的一次应用，不产生新的横切决策。

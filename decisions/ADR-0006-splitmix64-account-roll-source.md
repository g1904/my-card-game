# ADR-0006 — 账号级掷骰的随机源 = 契约定义的纯函数 SplitMix64

- **状态：** Accepted
- **日期：** 2026-08-14
- **来源：** `handoffs/2026-08-14-profile-sync-contract.md` · `handoffs/2026-08-14-splitmix64-test-vectors.md` · `answer-logs/log-profile-sync-contract.md` · `answer-logs/log-splitmix64-test-vectors.md`

## 背景

后端复算 `roll`（ADR-0005）要成立，前提是两侧对同一三元组算出**逐位相同**的序列。客户端手边现成的是 Godot 的 `RandomNumberGenerator`——沿用它意味着跨语言一致性押在引擎实现细节上，而客户端自己已为 `RandomNumberGenerator.State` 写过同一条警告。

## 决策

**账号级掷骰不走 Godot `RandomNumberGenerator`，改用本契约定义的纯函数 SplitMix64。**

- 算法、两个常量、两次异或移位量、`GOLDEN`、**三参数逐级混入的顺序**、`+1` 全零防御、`mod 10000` 且**不做拒绝采样**——全部是契约的一部分，两侧逐位一致。
- `stream` 的整数取值随客户端 `AccountStream` 的成员序**冻结**（`PowerFragment = 0` · `PremiumBundle = 1`），新增域只能追加。
- **测试向量是本契约唯一可执行的检查点**，数值权威在 `contracts/vectors/splitmix64.json`（8 组），两侧测试直接读该文件；markdown 表格是人类可读对照。实现与表不符时先复核实现、再复核表，**不得单方面改表迁就实现**。
- **轮回级 RNG 完全不受影响**（不跨边界，继续用 Godot RNG）。
- 算法伪码、向量表与选组理由 → `contracts/profile-sync.md` §6 §6a。

## 理由

跨语言逐位一致是复算成立的**前提**。押在引擎实现细节上，等于让「Godot 升级」成为一次静默的作弊窗口——没有任何一侧会报错，只会算出不同的 `roll`，且缺陷可能只在部分账号上显形。→ `contracts/profile-sync.md` §6。

向量表先于实现填值：向量是已冻结算法的函数、不含设计自由度 ⇒ 等待换不来信息，而先有表意味着两侧是**对着验收物写实现**，失败形态从「两侧都写完才发现差一位、且不知谁错」变成「当场红灯，且表是基准」。

## 备选方案

- **账号级掷骰继续用 Godot `RandomNumberGenerator`** — 引擎升级可能改变其序列语义，而两侧逐位一致是复算成立的前提。
- **做拒绝采样以消除 `mod 10000` 的模偏差** — 偏差 < 2⁻⁵⁰ 不可观测，而抽取次数不定会让连续抽的序列在两侧更难对齐：用真实的对齐风险换一个不可观测的收益。
- **向量表只给 `roll`、不给三个 `Next()` 输出** — 把 64 位输出压成 4 位十进制，约 2⁵⁰ 分之一的错误实现会碰巧对上，且不覆盖流状态推进。
- **向量表只给边界的 1–2 组** — 顺序判别对与相邻 `ordinal` 对正是最易差一位的两处，都不是边界值能覆盖的。
- **向量数值写进两侧各自的测试代码，不建共享文件** — 抄错即静默失效，而失效形态就是作弊窗口。
- **向量随机生成、每次实现时各自重算** — 那不是验收物而是同义反复：两侧各自重算只会各自自洽。
- **另立一张 `Mix()` 单函数向量表** — `Next()` 的输出已完全暴露 `Mix` 的正确性，多一张表多一处需同步维护的真值。

## 后果

- 「客户端本来就有 RNG，为什么另写一个」不再是开放问题——它的答案是 ADR-0005 的前提，重新提出等于要求推翻复算本身。
- `accountSeed` 因此**以 16 位小写 hex 字符串下发**：它是 `ulong`、几乎必然超 2⁵³，JSON number 会静默丢低位而它是逐位复算的输入。`contracts/envelope.md` §2 为此补了一条判据（「可能超出 2⁵³ 的整数一律走字符串」）而非开例外。
- `contracts/vectors/splitmix64.json` 不属 OpenAPI spec（不是报文形态），故单开 `vectors/` 目录而非塞进 `schemas/`。
- 购买域兑现段以同一三元组（`stream = PremiumBundle`）复算，**不定义任何新的随机源** → `contracts/purchase.md` §5。
- 客户端侧对位（随机源换 SplitMix64、账号级掷骰通则）权威在 `game-design-documents/systems/common-properties.md`。

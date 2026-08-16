# SplitMix64 测试向量填值 —— 契约随机源的验收物落地

- id: 2026-08-14-splitmix64-test-vectors
- date: 2026-08-14
- topic: contracts/profile-sync（§6 向量表 + 填值时机措辞）· contracts/vectors（新建数值权威文件）· contracts/_index（现状段）
- status: distilled
- distilled-to: `contracts/vectors/splitmix64.json`、`contracts/profile-sync.md`、`contracts/_index.md`、`open-questions/01-contracts.md`、`open-questions.md`、`open-questions/update-log.md`、`answer-logs/log-splitmix64-test-vectors.md`

## Intent（distilled）

**一行摘要：把 `profile-sync.md` §6 那张"必须有、但一直空着"的 SplitMix64 测试向量表填满，并把填值时机从「等任一侧首次实现」提前到「现在」——让它从实现的副产物变成实现的验收前置。**

§6 已把账号级掷骰的随机源定为契约定义的纯函数 SplitMix64，算法、两个 finalizer 常量、`GOLDEN`、三参数逐级混入顺序、`+1` 全零防御、`stream` 取值冻结、`mod 10000` 不做拒绝采样——**全部封定**。§6 同时自陈：那张 8 组的测试向量表是「跨语言逐位一致」这条纪律**唯一可执行的检查点**，不填即等于没有这条纪律。而这条纪律失效的形态是**静默的**：两侧算出不同的 `roll`，复算校验 ① 要么在部分账号上稳定失败、要么稳定放行，两侧都不报错——也就是一个作弊窗口。

因此本次做三件事：

1. **算出并填入 8 组数值**，权威落 `contracts/vectors/splitmix64.json`，`profile-sync.md` §6 附人类可读的对照表。
2. **把填值时机的措辞改掉**：由「向量值在任一侧首次实现 SplitMix64 时填入并同批两侧逐位复核」改为「向量值由独立参考实现预先算出并落 `vectors/splitmix64.json`；两侧各自实现后**逐位对表**，对不上以本文件为准」。
3. **补一条配套纪律**（新引入，原契约没有）：两侧实现与表不符时，**先复核实现、再复核表**；两者都复核完仍不符，则重算并同批改 markdown + JSON，**不得单方面改表迁就实现**。

### 为什么提前填（这是本次唯一的取向裁决）

向量是**已冻结算法的函数**，不含任何设计自由度 ⇒ 等待换不来更多信息。而先有表意味着两侧是**对着验收物写实现**，失败形态从「两侧都写完了才发现差一位、且不知道谁错」变成「当场红灯，且表是基准」。

代价写明：本表由一份**第三方参考实现**算出，而非项目两侧中的任何一侧 ⇒ 若这份参考实现本身有误，两侧会被一起带偏。第 3 条配套纪律正是为这个代价配的护栏。

### 8 组用例的选取依据

这张表抓的不是"随机性好不好"（那是 SplitMix64 自身的既有结论），而是**两侧实现的对齐**。最容易差一位的地方恰好是 §6 已经点名的三处：`+1` 防御、`stream` 与 `ordinal` 的**混入顺序**、`uint64` 环上运算与逻辑右移。因此：

| 用途 | 组 |
|---|---|
| 全零边界（验 `+1` 防御：不塌缩为纯 `Mix(accountSeed)`） | `seed=0, stream=0, ordinal=0` |
| 全 `F` 边界（验环上运算与逻辑右移，抓有符号右移 / 溢出异常） | `seed=ffffffffffffffff, stream=0, ordinal=0` |
| **顺序判别对**（把两级混入写反即失败） | `seed=0, stream=0, ordinal=1` ↔ `seed=0, stream=1, ordinal=0` |
| **相邻 ordinal 对**（验 `finaleWinOrdinal` 逐次 `+1` 不产生相关序列，也抓"少混一级"） | `seed=9f2c…, ordinal=1` ↔ `ordinal=2` |
| 现实取值 + `stream = 1`（`PremiumBundle` 域也被覆盖一次） | `seed=0123456789abcdef, stream=1, ordinal=1000` |
| 大 `ordinal`（客户端 `finaleWinOrdinal` 是 `int`，取 `int.MaxValue`，抓 `(uint64)` 转换处的符号扩展） | `seed=ffffffffffffffff, stream=1, ordinal=2147483647` |

- 现实种子取 `9f2c1a77b30e45d1` 是刻意的：它就是 `profile-sync.md` §2 初始 profile 骨架示例里的那个 `accountSeed`，**同一个值在两处出现**，读者一眼能把向量表与报文示例接上。
- 组 3 的 `roll = 30` 顺带覆盖了一类单位错误：若某侧误用 `mod 100`，组 3 会**碰巧对上**（`30 < 100`）而组 1（`roll = 2433`）不会——两组同表，不可能同时通过。

### `vectors/splitmix64.json` 的形态依据

- 64 位值（`accountSeed` 与三个 `next`）一律 **16 位小写 hex 字符串**——`envelope.md` §2 的「取值域可能超出 2⁵³ 的整数一律走字符串」判据；`roll` / `stream` / `ordinal` 是小整数，走 JSON number。
- **算法常量与 `streams` 冻结映射写进同一个文件**：它们是向量的前提，同处放置使"照着 JSON 写实现、再拿 JSON 验实现"成为一次完整闭环；也让「`stream` 取值只能追加」这条冻结纪律在唯一被机器读取的地方有个落点。
- `vectors` 为**有序数组**、每项带 `name`：测试失败时报出的是名字而不是下标，定位快一级。
- **不为它建 JSON Schema 校验文件**：它不是报文形态，`_index.md` 的 `schemas/` 两条拆分判据都不满足；`vectors/` 单开目录这一点 §6 已定。

### 数值的产出与自检（供溯源，非契约内容）

数值由一份独立的 C# 参考实现按 §6 定义逐字实现后算出（`ulong` 环上运算、逻辑右移）。两道自检：

1. **`Mix` 与 `GOLDEN` 已用公开的标准 SplitMix64 向量钉住**：以 `state = 0` 起、`state += GOLDEN; Mix(state)` 的前三个输出为 `e220a8397b1dcdaf` / `6e789e6aa1b965f4` / `06c45d188009454f`，与公开值逐位一致 ⇒ 两个 finalizer 常量、两次异或移位量、末尾 `>> 31` 与 `GOLDEN` 均正确。
2. **落盘后二次复算比对**：重新解析 `vectors/splitmix64.json`（含 hex 字符串 → `ulong` 的解析路径，与首次产出路径不同），逐组重算并与文件中的 `next[0..2]` + `roll` 逐位比对，8 组全过。

**本表之上的部分（三参数逐级混入 + `+1` 防御）是 §6 独有的，无外部参照**，其正确性只靠"逐字实现 §6 的五行伪代码"——这是复核时最该盯的一处：请对着伪代码复核，而不是对着数值。

## Clarifications（interview 产物）

本次**未触发 interview**：输入草稿 `status: decided`，唯一取向项已由用户裁决，本库校验未发现新的 🔴 / 🟠。

- **用户裁决（2026-08-14）**：填值时机取 **A —— 现在填**；其余（8 组用例选取 · 8 组数值 · JSON 字段形态 · 「不新增错误码 / 不改报文形状 / 不 bump 任何版本号」的边界 · 全部备选否决理由）按草稿推荐定案。
- **第四条机检断言不立**（按草稿推荐，用户认可）：「markdown §6 表格 ⇔ `vectors/splitmix64.json` 逐值一致」与 `06` 的自动化承载耦合，在此之前只作 `_index.md` 人工清单第 2 项（承重纪律段落）下的一次具体检查。**不进本次的规范性内容**，作为 `06` 落定时的候选。

## Notes / triage

- 本次**不改动任何报文形状、不新增错误码、不 bump `schemaVersion` / `/v1/` / `info.version`**——向量不是报文形态，也不进 `openapi.yaml` 的 `paths`。
- **对三条机检断言无影响**：①（spec 自身合法）②（错误码台账 ⇔ spec 枚举）③（`METHOD 路径` ⇔ `paths`）三者都不沾向量文件。
- `contracts/vectors/` 目录本次首次实际创建（此前只在 `_index.md` 的目录形态图中作为计划存在）。`splitmix64.json` 因此是 `contracts/` 下**第一个已落笔的机器可读产物**——早于 `openapi.yaml`。
- 顺带发现（本次未改，归 `/update-readme`）：`README.md` 文件夹图例中 `contracts/` 那行仍写「当前有两份：`envelope.md` 与 `content-manifest.md`」，实际已四份。

## 客户端侧影响

**不改动客户端 ↔ 后端的任何报文语义 ⇒ 客户端侧不需要承接性 handoff。** 但有一条**操作性收益**需要客户端知晓：

- 受影响的客户端成分：`sync-service`（账号级掷骰的复算输入由它上行）。
- `handoffs/2026-08-14-profile-sync-contract.md`「客户端侧影响」段的**第 6 点**（`AccountRng` 换随机源 —— SplitMix64 实现 + 测试向量对表，含 `AccountRng.For` 返回类型 `RandomNumberGenerator` → `AccountRandom` 的改动）**自此有了可直接消费的验收物**：客户端实现 `AccountRandom` 后跑一遍这 8 组即可，**无须等后端动手**。
- 建议客户端侧那份 handoff（尚未写，属既有跨库欠账）在第 6 点回链 `backend-design-documents/contracts/vectors/splitmix64.json`，并写明「测试直接读该文件，不抄进代码」这条纪律。

## Open questions

**本 handoff 无遗留待答项。** §6 的向量条自此答结（→ `answer-logs/log-splitmix64-test-vectors.md`）。`01-contracts.md` 余下三条（`auth.md` 三处留白 · `compliance.*` 码清单 · `bundleGrantOrdinal` 透明路径 · 机检断言承载位置）与本次无关，原样保留在分片中。

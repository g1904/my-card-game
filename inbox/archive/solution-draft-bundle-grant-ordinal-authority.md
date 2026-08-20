---
type: solution-draft
date: 2026-08-18
question: monetization.md 内部相抵 —— `BundleGrantOrdinal` 究竟由谁施加？`ResourceElements` 里那一行的 `AllowedOps = Set` 是否存在客户端施加路径？
source: open-questions/05-service-contracts.md → 「`monetization.md` 内部相抵——`BundleGrantOrdinal` 究竟由谁施加（08-17 新增 · 承重）」
targets: systems/monetization.md · systems/services/profile-service.md（`ResourceElements` 表 `BundleGrantOrdinal` 行）· systems/player-profile/_index.md（字段表第 14 行 + `PlayerEntitlement` 类）· systems/services/sync-service.md（购后 pull 与待兑现态）· ux/error-and-blocking-ux.md（阻塞屏变体）
counterpart: backend-design-documents/inbox/solution-draft-bundle-grant-ordinal-authority.md
status: distilled
reviewed: 2026-08-19 — 用户逐条裁决完毕（取向零剩余）；批量提炼时的合并 interview 另有 48 项裁决，全部取推荐项
distilled-to: handoffs/2026-08-19-bundle-grant-ordinal-authority.md
---

# 方案 — `BundleGrantOrdinal` 的施加权归属（客户端侧）

> **本文件只写客户端这一半**：`AllowedOps` 的最终形态、兑现事务、派生与 `TryApply`、push / pull 时序中的**客户端动作**、UI 态。
> 验票、后端 `+1` 的写入权威与原子性、后端主动写入后的可读语义、收据幂等窗口 → 见 `counterpart`，**本文件不复述**。

## 问题

`systems/monetization.md` 同一份文档内部两处互相抵触：

| 处 | 表述 | 蕴含 |
|---|---|---|
| 「一次授予 = 一次 `TryApply`，序号先算后写」的伪码 | `ordinal = profile.Entitlement.BundleGrantOrdinal + 1` → `spec = { Elements: [ BundleGrantOrdinal := ordinal ], … }` | **客户端**自己算出下一个序号并把它写进 Profile |
| 同文档「购买段后端权威 · 兑现段客户端演算」 | 「谁有权把 `BundleGrantOrdinal` 从 n 推到 n+1**只能是后端**」「否决客户端自行置位 + 后端事后校验」 | **客户端无权**推进该序号 |

矛盾外溢到第三处：`systems/player-profile/_index.md` 字段表第 14 行把 `entitlement` 的写入通道写作「`Elements`（`BundleGrantOrdinal` 置值）」，**而同一文件里 `PlayerEntitlement` 的类注释写着「客户端永不自行置位」**。三处表述，两种事实。

它卡住的是一个可机械落地的点：`systems/services/profile-service.md` 的 `ResourceElements` 表里 `BundleGrantOrdinal` 一行现登记 `AllowedOps = Set`——**这一行存在，就等于代码层面开着一条客户端施加路径**。启动期断言只检查「`AllowedOps != 0`」与「含 `Set` 则两修正列为 `null`」，不会告诉任何人这条路径本不该被走。

## 约束（来自既有设计）

- **云端权威**（`ADR-0003`）+「付费凭证不能只信客户端」（`systems/monetization.md`）⇒ 序号推进权在后端。
- **后端写入字段表是封闭表**，`/entitlement/bundleGrantOrdinal` 已登记在内、写入时机为「每次验票通过时 `+1`」——权威在 `counterpart` 所在库的 `contracts/profile-sync.md` §5。
- **`AccountRng.For(PremiumBundle, ordinal)` 需要序号才能派生**（`systems/common-properties.md`）⇒ 时序上**序号必先于掷骰存在**，客户端在拿到序号之前无法开始兑现。
- **一次授予 = 一次 `TryApply`，全有或全无**（`systems/services/profile-service.md`）。
- **购后强制一次 pull、pull 失败即阻塞在主菜单重试直到成功**（`systems/services/sync-service.md`）；`receiptId` 随待兑现态持久化、跨启动可补查。
- **`Op == Set` 恒不经 modifier pipeline；含 `Set` 的行两个修正列恒为 `null`**（启动期断言）。
- **`Ordinal` 后缀 ⇒ 规则字段层**（位置 / 幂等键 / 严格同步），统计层禁用该后缀（`answer-logs/log-finale-win-ordinal-vs-statistics.md`）。
- **`PlayerEntitlement` 类内只有一个字段（承重）**，且明确「不设第二个字段」——判据是「同一个数的三份拷贝」（`systems/player-profile/_index.md`）。**本方案的子项 3 与这条有张力，见下。**

## 建议方案

### 1. 裁决：保留「后端唯一 `+1`」，删除客户端置位路径

`[既有推演]` 三条依据各自独立地指向同一侧，且**没有任何一条依据支持客户端置位**：

- **防篡改。** 客户端置位 = 客户端有权发货。既有否决语已写死：「事后发现不一致时玩家已拿到东西，回收比不发更糟」。
- **时序。** 后端在验票事务内 `bundleGrantOrdinal += 1` 与 `cloudRevision += 1`，客户端**强制 pull** 后拿到的 profile **已经带着新序号**。此刻客户端若再算一次 `+1` 并置值，得到的是 `n+2`——**这不是一处措辞冗余，是一个会跳号的实现缺陷**：跳号即掷骰序列错位，且下一次购买的后端 `+1` 会与本地值冲突，在 CAS 下表现为「云端落后于本地」的不可能态。
- **依赖方向。** `AccountRng` 的 `ordinal` 是**输入**不是输出；伪码里 `ordinal` 之所以看起来需要客户端算，只是因为那段伪码写在「后端主动写入」这一情形被识别之前。识别之后，序号的来源变成 pull 下行，`+1` 这一步在客户端侧**整个消失**。

**结论：伪码首行是残留，应改写；购买段定案是权威，保留。**

### 2. `ResourceElements` 里 `BundleGrantOrdinal` 那一行：整行撤下，不存在客户端施加路径

`[既有推演]` 该行的唯一用途是让 `ChangeElement` 能带 `Key == BundleGrantOrdinal`，而按子项 1 客户端永不组装这样的 element。

- **建议把该行从 `ResourceElements` 表整行删除**，并**不把 `BundleGrantOrdinal` 登记为 `CostKey` 成员**（该表的末三行本就注明「随各自的 `CostKey` 成员登记时同步生效」，本条即**不登记**）。
- 由此自动获得一条机械保证：`profile-service.md` 失败语义表已有「`ChangeElement.Key` 在 `ResourceElements` 中无对应行 → 必需缺失 → `PushError` + 整批拒绝」。**任何日后误写的客户端置位当场在启动 / 施加时大声失败**，不需要为此新增任何断言或注释。这比「保留该行 + 写一句『但客户端不要用』」强一个量级——后者是纪律，前者是编译期外的硬闸。
- **否决「保留该行但把 `AllowedOps` 置空」**：违反既有启动期断言「每一行的 `AllowedOps != 0`」。
- **否决「保留该行、标注 backend-only」**：`ResourceElements` 是**客户端施加语义**的表，表里不存在「后端写入」这一语义位；引入它等于在这张表上开第二种读法。后端写入的落点是 pull 下行的整份 profile，根本不经 `TryApply`。
- **连带：`entitlement` 的写入通道列改写。** `systems/player-profile/_index.md` 字段表第 14 行的「写入通道」由「`Elements`（`BundleGrantOrdinal` 置值）」改为「**后端写入 · 经 pull 下行进入内存态，无客户端写入通道**」，与同文件 `PlayerEntitlement` 的类注释一致。

### 3. 兑现幂等需要一个客户端写的水位字段 `BundleRedeemedOrdinal`（承重 · 与既有「类内只有一个字段」有张力）

`[既有推演]` 子项 1、2 关掉客户端写 `BundleGrantOrdinal` 之后，**「这个序号兑现过没有」在云端没有任何记录**——而这是整条链上唯一还没有被兜住的重复面：

| 重复面 | 谁兜住 | 结论 |
|---|---|---|
| 同一张票重复 verify | 后端收据幂等（`receiptId`） | 已闭合，见 `counterpart` |
| 同一批变更重复上行 | `pushId` | 已闭合 |
| 多设备并发写 | `revision` CAS | 已闭合 |
| **pull 到同一序号重复兑现** | **无** | ⚠ 缺口 |

**必须写清：`pushId` 与 `revision` CAS 都兜不住这一条。** `pushId` 只保证「同一批变更不被写两次」；第二次兑现是**另一批**变更（另一个 `pushId`、另一组条目），在 CAS 下是一次完全合法的推进，两侧都不会报错。玩家凭一次付款拿到 2 法则 4 古宝——**这是发放侧的漏洞，方向与「不收钱又不给货」相反但同样是事故**。

反过来，若把待兑现态**只**放在 `user://cache/`（当前 `sync-service.md` 的写法）：卸载重装 / 清缓存 / 换设备后该状态消失，而云端序号已 `+1`、客户端无从知道自己欠一次兑现 ⇒ **收了钱永不给货**，且线上无任何痕迹。**本地缓存不是权威**这条既定语义在这里正面生效。

**建议形态：**

```csharp
public sealed class PlayerEntitlement    // 规则字段层：严格同步 · 后端可复算
{
    public int BundleGrantOrdinal    { get; }   // 后端写：验票通过时 +1。客户端无写入通道
    public int BundleRedeemedOrdinal { get; }   // 客户端写：兑现事务内置为本次 ordinal。0 = 从未兑现
}
```

| 项 | 取值 |
|---|---|
| JSON path | `/entitlement/bundleRedeemedOrdinal`（camelCase，由既定序列化策略机械对应） |
| 层 | 规则字段层（`Ordinal` 后缀合规：它是位置 / 幂等键，不是数量） |
| 默认值 | `0`；老档缺字段 → `0`。**当前无线上存档 ⇒ 空迁移**，并入既有的同一次 bump |
| 写入方 | **客户端**，且**只在兑现事务内** |
| `ResourceElements` 行 | `Min 0` · `Max 无` · 归 Min 时无 · `CostModifier null` · `GainModifier null` · `AllowedOps Set` · 依据「兑现水位，被赋为 pull 下来的绝对序号，不是加法；经 pipeline = 一条法则能伪造兑现记录」 |
| 不变式 | `0 ≤ BundleRedeemedOrdinal ≤ BundleGrantOrdinal`；两者相等 ⟺ 无待兑现 |
| 后端 | **只读**（透明路径），可校验上述不变式 —— 归 `counterpart` |

- **它不是 `BundleGrantOrdinal` 的拷贝**（既有「不设第二个字段」判据针对的是同一个数的多份拷贝）：两者**恰在存在待兑现购买时不相等**，这个差值正是它承载的信息。`HasPremiumBundle` 仍读 `BundleGrantOrdinal > 0`，不变。
- **兑现判定收敛为一次纯比较**：`Grant > Redeemed` ⇒ 有一次待兑现；跨启动、跨设备、清缓存后都成立，不依赖任何本地状态。`receiptId` 的本地持久化**仍保留**，但降级为**加速补查的优化**（少一次 pull 的等待），不再是正确性的承载者。
- **不做「一次追多个序号」**：不变式下 `Grant - Redeemed` 恒 ≤ 1（购买入口前置条件禁止在待兑现状态下再次购买，见子项 5），若真读到 `> 1` 属异常 → `PushError` + 上报，逐一按序兑现（每个 ordinal 一次独立 `TryApply`），**不合并成一次事务**（合并会让 `AccountRng` 的 `(域, 序号)` 完全确定性失去逐次对位）。

### 4. 兑现事务的最终形态

`[既有推演]` 伪码改写为：

```
// 触发点：主菜单，pull 完成之后
if (profile.Entitlement.BundleGrantOrdinal <= profile.Entitlement.BundleRedeemedOrdinal) return;   // 无待兑现

ordinal = profile.Entitlement.BundleGrantOrdinal          ← 直接取 pull 下来的值，客户端不做 +1
rng     = AccountRng.For(AccountStream.PremiumBundle, ordinal)
picked  = TryPickGrantable(Power, Player, rng) + TryPickGrantableMany(Item, Player, rng, 2)
spec    = { Elements:        [ BundleRedeemedOrdinal := ordinal ],
            AbilityElements: [ Grant(picked…, Source.PremiumBundle) ] }
ProfileManager.TryApply(spec)                             ← 全有或全无，一次事务
→ Push(SavePointReason.MetaChanged, PushPolicy.Immediate)
```

- **「随机在 spec 组装之前掷完」原样成立**；`Source.PremiumBundle` 原样携带。
- **闸 ③（兑现结算时 `TryPickGrantable*` 失败，理论不可达）的处置随之变清晰**：该项计未兑现、不补发、`PushError` + 上报，但 **`BundleRedeemedOrdinal` 照常置为 `ordinal`**——否则客户端会永远认为自己欠一次兑现，每次启动重掷同一 `ordinal`、抽空池、反复报错。原文「`BundleGrantOrdinal` 照常 +1」那条纪律**整体迁移到水位字段上**，理由逐字相同（不迁移即幂等键当场失效）。
- **`SavePointReason = MetaChanged` · `PushPolicy = Immediate`** 不变。
- **兑现的 push 失败不阻塞**（既定：push 失败一律不阻塞玩家，`Immediate` 不改变这一条）。已提交的本地事务保证退出重进不回滚；水位已置，不会重兑。

### 5. 完整时序与逐步失败语义

| # | 步 | 谁 | 失败 | 处置 |
|---|---|---|---|---|
| 1 | 检查购买入口四条前置条件 | 客户端 | 任一不满足 | 不渲染（条件 1）/ 置灰 + 说明（条件 2/3/**4 新增**） |
| 2 | 唤起平台内购、拿到收据 | 平台 SDK | 用户取消 / SDK 失败 | 回主菜单，无任何 Profile 变更，无痕迹 |
| 3 | **持久化待兑现态**（`receiptId`，`user://cache/`）**在上行之前** | 客户端 | 本地写失败 | `PushError`；仍继续 verify（水位字段是正确性兜底，本地态只是加速） |
| 4 | 上行验票 | → 后端 | 网络失败 / 平台不可达（可重试类） | 退避重试，UI 停在阻塞屏「购买处理中」；**不放弃、无硬超时**（见子项 6） |
| 5 | 后端在同一事务内 `bundleGrantOrdinal += 1`、`cloudRevision += 1`，应答回新序号 + `revision` | 后端 | 收据无效 / 已被他账号核销（不可重试类） | 客户端清待兑现态、出错误文案（`code → ERR_*`）、回主菜单。**不写任何 Profile 字段** |
| 6 | **强制一次 pull** | 客户端 | pull 失败 | **阻塞在主菜单重试直到成功**（既定），不允许开始新轮回 |
| 7 | 比较 `Grant > Redeemed` | 客户端 | 相等（例：另一设备已兑现） | 正常路径，非失败：清待兑现态、静默结束 |
| 8 | 掷骰 → 一次 `TryApply` | 客户端 | 池空（闸 ③，理论不可达） | `PushError` + 上报 + 该项计未兑现、不补发；水位照常置（子项 4） |
| 9 | `Immediate` push | 客户端 | 网络失败 | 进待发队列、退避重试、**不阻塞**；本地已落盘，退出重进不回滚 |
| 10 | 后端复算校验 | 后端 | 不一致 | 接受写入 + 打风控事件（既定 §7a），不拒绝、不改写 —— 归 `counterpart` |
| 11 | 清待兑现态、呈现兑现结果 | 客户端 | — | — |

**跨启动补入口：** 每次启动 pull 之后、进入主菜单之前，比较一次 `Grant > Redeemed`；为真则直接进第 7 步。**不需要本地待兑现态存在**——这正是子项 3 换来的性质。本地态存在时可省掉「先 verify 再 pull」的一次往返（走收据幂等读，见 `counterpart`）。

### 6. pull 到新序号之前的 UI 态

`[通行做法]` + `[既有推演]`（复用既有阻塞屏变体表，不新增拦截点）：

| 阶段 | 形态 | 可退出 |
|---|---|---|
| 第 2 步（平台内购中） | 平台 SDK 自己的界面 | 由 SDK 决定 |
| 第 4–6 步（验票 / pull 未回） | **既有阻塞屏的一个变体**：「正在处理你的购买…」+ 进度指示；≥ 15 秒后追加副文案「网络较慢，可稍后回来，购买不会丢失」 + 显式「重试」 | **不可继续游玩**（既定：不允许在未兑现状态下开始新轮回）；允许「退出应用」 |
| 第 7–9 步（兑现中） | 同一屏，文案切「正在发放…」 | 否（毫秒级 + 本地事务） |
| 第 11 步 | **兑现结果一屏**：本次获得的 1 法则 + 2 古宝（条目名 + 图标） | 是 |
| 待兑现态存续期间（重启后仍未兑现） | 主菜单可进入，但**「开始新轮回」禁用 + 说明「有一笔购买待发放，正在重试」**；顶部常驻同步指示复用既有形态 | 是 |

- **无硬超时、永不放弃。** 「超时后放弃」= 收了钱不给货；本方案的终态是「一直重试直到成功」，代价被水位字段与收据幂等读兜住，玩家最坏体验是「稍后回来」而不是「钱没了」。
- **购买入口新增第 4 条前置条件：`BundleGrantOrdinal == BundleRedeemedOrdinal`（无待兑现）**，不满足 → 置灰 + 「上一笔购买正在发放」。理由：不变式 `Grant - Redeemed ≤ 1` 靠它维持；且在待兑现状态下允许再次付款，会把一个待发放问题叠成两个。**这是往既有三条前置条件表加一行，不新增拦截点**（表本身就是那个拦截点）。
- **不做「后台静默兑现 + 事后弹提示」**：玩家付了钱却看不到东西的窗口越短越好，且既定纪律本就把玩家钉在主菜单。

## 具体形态（可 derive 的落地面）

**A. `ResourceElements` 表的两处改动**（`systems/services/profile-service.md`）

| 行 | 动作 |
|---|---|
| `BundleGrantOrdinal` | **删除**；不登记为 `CostKey` 成员 |
| `BundleRedeemedOrdinal` | **新增**：`0` / 无 / 无 / `null` / `null` / `Set` / 「兑现水位，绝对置值；经 pipeline = 一条法则能伪造兑现记录」 |

两处均自动满足既有启动期断言（含 `Set` ⇒ 两修正列 `null`；`AllowedOps != 0`）。

**B. `PlayerEntitlement` 两字段**（`systems/player-profile/_index.md`）—— 见子项 3 的代码块与字段表；字段表第 14 行写入通道列同改。

**C. 存档 schema** —— 并入既有的同一次 bump，老档 `bundleRedeemedOrdinal → 0`，**空迁移**（当前无线上存档）。

**D. 透明路径新增一条** `/entitlement/bundleRedeemedOrdinal` —— 白名单登记与后端只读语义归 `counterpart`；客户端侧承接的是既有的**透明路径稳定性纪律**（移动 / 重命名 = 破坏性契约变更，须 bump `schemaVersion` 并与后端同批改）。

**E. `sync-service.md` 的购买段小节** —— 「`receiptId` 随待兑现态持久化」一句补上定位：它是**加速补查的优化**，正确性由 `/entitlement` 两字段之差承载。

## 后果

- 触及文档：`systems/monetization.md`（伪码 + 前置条件表）· `systems/services/profile-service.md`（`ResourceElements` 两行）· `systems/player-profile/_index.md`（字段表 + 类）· `systems/services/sync-service.md`（购后 pull 与待兑现态定位）· `ux/error-and-blocking-ux.md`（阻塞屏变体文案）。
- 存档 schema：**加一个 int，空迁移**，并入既有同批 bump。
- 契约：新增一条透明路径 ⇒ 须与后端同批落笔（见 `## 前置依赖`）。
- **`monetization.md` 的「允许的全部呈现穷举为两处」**（主菜单入口 + 礼包详情页）需要补一句：**兑现结果屏是第三处呈现**。它不是推销面（发生在付款之后、内容已定），但那句「穷举」是逐字的，不补即是新的内部相抵。

## 备选方案（已考虑并否决）

- **客户端 `+1` + 后端事后校验** —— 既有否决语原样成立（客户端有权发货；回收比不发更糟）。且在本时序下它还会**跳号**（子项 1）。
- **保留 `ResourceElements` 的 `BundleGrantOrdinal` 行、靠注释约束** —— 把一条能被机械闸住的纪律降级为人记；「缺行即 `PushError`」是免费的硬闸。
- **由 `Source.PremiumBundle` 的法则条目数反推已兑现次数**（不加字段） —— 三处失效：闸 ③ 下序号推进但无条目；**自愿置换会移除付费法则**（`monetization.md` 明写置换是唯一真正移除路径）；古宝可被消耗。派生量不可靠即不能当幂等键。
- **靠重掷同一 `(域, ordinal)` 得到相同结果来实现幂等**（不加字段） —— **不成立**：取池已排除已持有，第一次授予后池子变了，同一 rng 会抽到**不同**条目 ⇒ 重兑 = 多发，不是幂等。这是最诱人的错误答案，须明确写进否决记录。
- **待兑现态只放本地缓存** —— 清缓存 / 重装 / 换设备后「收了钱永不给货」，且线上无痕迹（子项 3）。
- **兑现也交给后端做** —— 既有否决语原样成立（`AccountRng` / `GrantPoolPicker` 要在两侧各实现一遍）。
- **verify 应答内联新序号即直接兑现、跳过 pull** —— 后端 verify 只回序号 + `revision`、不内联 profile（`counterpart`），而兑现需要**完整的当前 profile**（排重取池要读已持有条目）。跳过 pull 会让取池读到过期的持有状态。

## 与既有决策的张力

1. **本题本身就是一处内部相抵，且是三处而非两处。** `monetization.md` 的伪码 ↔ 同文档购买段定案 ↔ `player-profile/_index.md` 字段表第 14 行「写入通道 = `Elements`（`BundleGrantOrdinal` 置值）」。**采纳本方案须三处同改**，只改 `monetization.md` 会留下第三处继续与之相抵，而下一次读到它的人会照它写代码。
2. **⚠ 与「`PlayerEntitlement` 类内只有一个字段（承重）」直接张力。** 那条的判据是「三者是同一个数的三份拷贝」，本方案的 `BundleRedeemedOrdinal` **不是**拷贝（恰在待兑现时不相等），故形式上不违反判据；但它确实**松动了那条承重表述的字面**。松动的代价：`PlayerEntitlement` 从 1 字段变 2 字段，`schemaVersion` 并入既有 bump（≈ 零成本）。**不松动时的替代方案**：待兑现态只放本地缓存（后果见备选否决第 5 条：收了钱永不给货）。**建议松动，并把那条表述改写为「类内只放付费凭证本身与其兑现水位，不放任何派生量」**——保住它真正想拦的东西（`HasPremiumBundle` / `PremiumBundleCount` 这类拷贝），同时容纳一个语义独立的字段。**这一条必须由用户裁决。**
3. **与「允许的全部呈现穷举为两处」的字面张力** —— 见 `## 后果` 末条，属措辞补充，不改机制。
4. **与「不新增拦截点」的字面张力（轻）** —— 购买入口第 4 条前置条件是在**既有的那张表**里加一行，拦截点数量不变，符合该纪律的本意。

## 前置依赖

- **本方案的子项 3（`BundleRedeemedOrdinal` 字段）与子项 5 第 5 步（后端 `+1` 的原子性与应答形态）须与 `counterpart` 的 §「兑现水位路径的后端承接」与 §「验票写入权威」同时采纳。单侧采纳即两侧不一致**：只客户端加字段 ⇒ 该路径不在后端白名单内、后端无法校验不变式、且它对后端表现为不透明段的一次静默变更；只后端登记 ⇒ 客户端无写入方，字段恒为 0。
- **本方案的子项 5 第 4 步（重试路径）依赖 `counterpart` 的收据幂等读语义与幂等记录保留期**——若后端的幂等记录窗口短于客户端待兑现态的存活时间（可跨天），「跨启动补查」会查不到而退化为死等。该窗口的定值归对侧库。
- 不依赖任何仍待答的**客户端**问题。`K` 与 `GrantPoolMargin` 的数值（`systems/balance.md`）与本方案无关——本方案不改闸 ①/②/③ 的结构。

## 用户裁决（2026-08-19 · 全部定案）

**客户端侧三项取向全部按本方案的推荐定案（各取 A）**：Q1 沿用 2026-08-18 批量评审的裁决，兑现结果屏与阻塞形态于本次一并采纳。本方案自此为**定案方案**，`## 建议方案` 与 `## 具体形态` 各节即最终形态，可直接喂给 `/analyze-new-ideas` 提炼。

> **成对采纳（硬要求，不变）：** 本方案与 `backend-design-documents/inbox/solution-draft-bundle-grant-ordinal-authority.md` **必须成对采纳** —— 只客户端加字段则路径未登记且覆写窗口在无校验下常态化；只后端登记则字段无写入方、恒为 0。

| # | 取向 | 定案 | 承重理由（保留） |
|---|---|---|---|
| Q1 | `PlayerEntitlement` 是否加第二个字段 `BundleRedeemedOrdinal`（承重） | **取 A —— 加字段**，云端承载兑现水位<br>*（2026-08-18 已裁，照录）* | A 是唯一**同时闭合两个方向**（重复兑现 / 收钱不给货）的形态，成本是一个 int 与一句表述改写。B 的失败模式（清缓存 / 重装 / 换设备后玩家付了钱永不拿到货，且线上无痕迹）恰好是本系统投入最多笔墨去防的那一个；C 引入的新面比 A 多一个量级 |
| Q5 | 兑现结果屏是否设立 | **取 A —— 设立一屏**，列出本次获得的 1 法则 + 2 古宝；`monetization.md` 的呈现穷举随之补一条（两处 → 三处） | 那句「穷举」约束的是**推销面**，兑现结果不是推销；「付了钱看不到货」与本文件反复出现的诚实性纪律正面相悖，且是退款争议的常见诱因 |
| Q6 | 是否允许玩家在结果屏之前离开 | **取 A —— 不允许**，维持既定「阻塞在主菜单重试直到成功、不允许开始新轮回」 | 水位字段虽让 B 在技术上安全（重启后必定补上），但不改变 B 被否决的那条理由——**期间玩家看不到自己买的东西**；`sync-service.md` 已明确否决「兑现被推迟到不确定时刻」。**代价照录**：极端网络下玩家被钉在主菜单，只能退出应用 |

**Q1 的三处连带（照录，采纳须一并落笔）：**
- `ResourceElements` 里 `BundleGrantOrdinal` **整行撤下、不登记为 `CostKey` 成员**；`solution-draft-costkey-statkey-registry.md` 的账号层第 8 个成员换为 `BundleRedeemedOrdinal`（总数仍 15），其「决定 3」自动消解。
- **张力 2 的松动已获批**：`PlayerEntitlement` 由 1 字段变 2，承重表述改写为「类内只放付费凭证本身与其兑现水位，不放任何派生量」。
- **内部相抵是三处而非两处**：`systems/player-profile/_index.md` 字段表第 14 行是第三处，**采纳须三处同改**。

**Q2（后端 `/entitlement` 回声校验）→ 已裁决：取 A**（不等即整批拒绝 + 风控）。详见 `counterpart`。

## 已定案的相邻项（本方案不写其本体，只记录裁决与连带）

- **平台内购 SDK 的工程连带 → 已裁决：纳入 MVP。** 计划支持 **Google Play Billing · App Store（StoreKit）· 微信支付** 三条渠道，连同 Godot 导出配置与各平台构建。
  **这推翻了 `monetization.md` 原先「MVP 之外」的登记**，该句须改写；`vision/scope.md` 的范围表若有对应行须同改。本方案的**第 2 步（唤起平台内购、拿到收据）由此获得实现依托**，但**它的具体形态仍不由本方案定**——SDK 选型 / 封装层 / 三渠道的收据差异归后端库的支付渠道选型（`backend-design-documents/open-questions/06-platform-stack.md`）与一次专门的客户端工程蓝图。
  **对本方案的实质影响为零**：时序表第 2 步的失败语义（用户取消 / SDK 失败 → 回主菜单，无任何 Profile 变更，无痕迹）逐字不变。
- **纯外观付费点 → 已裁决：架构上必须支持，实现推后（未来会做）。** 与本题无耦合，但**「不排除」由此升格为「预留且必须留出扩展位」**：`PlayerEntitlement` 的字段扩展方式（**具名字段 + bump**，不开放式 map）已由既有决策给定，落地时沿用即可；`vision/scope.md` 中「外观装饰」那一行的措辞须从「范围之外」改写为「架构预留、首批不做」。**首批不新增任何字段、不新增任何屏。**
- **`K` 与 `GrantPoolMargin` 的数值** —— 待内容规模明朗，与本题无耦合，不阻塞。

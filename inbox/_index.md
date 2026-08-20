# 收件箱（inbox · 后端）

未整理的想法草稿的暂存区。**顶层只放在办的草稿；已被提炼进 `handoffs/` 与主题文档的一律移入 `archive/`。**

## 两层结构

| 位置 | 含义 | 谁写入 |
|------|------|--------|
| `inbox/*.md`（顶层） | **在办**：尚未提炼进 `handoffs/` 与主题文档的草稿。 | 用户手写；`/provide-solution-draft` |
| `inbox/archive/*.md` | **已提炼**：已产出对应 `handoffs/<date>-<slug>.md`（`status: distilled`）的草稿，只作溯源留存。 | 提炼完毕后移入 |
| `_TEMPLATE.md` | 新建草稿的空模板，不是在办条目。 | — |

判据只有一条：**这份草稿有没有对应的 distilled handoff**。有 → `archive/`；没有 → 留在顶层。

## 两类草稿

- `draft-<suffix>.md` —— 手写的零散想法。**`<suffix>` = `MMDD` + 序列字母，从 `a` 起，同日依次 `a` · `b` · `c` …**（例：`draft-0816a.md` · `draft-0816b.md`）。
  **当天第一份也带 `a`，不写裸 `draft-MMDD.md`。** 序列位恒定存在，`ls` 与 `log-*` 后缀才能整齐排序、一眼看出同日批次的先后；裸日期与带字母混排时，同日第一份会脱离它自己的序列。
- `solution-draft-<slug>.md` —— 针对某个待答问题产出的**提案式**方案草稿。front-matter `status` 生命周期：`awaiting-review` → `reviewed` / `decided` → `distilled`（移入 `archive/`）。

## 在办清单

| 文件 | status | 说明 |
|------|--------|------|
| `solution-draft-bundle-grant-ordinal-authority.md` | decided | `bundleGrantOrdinal` 施加权归属（后端半）：`/entitlement` 回声校验（**新发现的既有漏洞**：浅合并按顶层键 ⇒ 客户端整键替换可覆写后端唯一写入字段，封闭表此前无执行点）· 兑现水位路径登记 · 读己所写 · `receiptId` 幂等窗口。**全部定案（三项皆取 A）**：回声校验整批拒绝 + 风控 · 「读己所写」升格为服务端一致性要求 · `receiptId` 永久保留不设 TTL。**跨库**，与 `game-design-documents/inbox/` 同名草稿**成对采纳**。另记录一条相邻定案：**平台内购 SDK 与支付渠道选型纳入 MVP**（Google Play Billing / App Store / 微信支付）⇒ `06-platform-stack.md` 的渠道选型由「可推后」变为 MVP 内必答，`purchase.md` §3 的 `receipt.platform` 取值域收敛为三个具名渠道 |

清空即为「无在办草稿」。已提炼草稿 → handoff 的对应关系见 `archive/_index.md`。

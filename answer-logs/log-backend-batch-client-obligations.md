# Answer log backend-batch-client-obligations

- 日期：2026-09-05
- 来源：`inbox/solution-draft-backend-batch-client-obligations.md`（→ `handoffs/2026-09-05-backend-batch-client-obligations.md`）
- 移出条数：3

**内容分发的三项客户端承接（内置两把公钥 · 产包证明的字段形态 · 基线内容快照的归档形态；登记在 `open-questions/cross-boundary.md`「待承接」，三项须成对采纳）** → 已答定，整条移出。① `content-service.md` 明写**首个客户端版本即内置 active + standby 两把内容签名公钥**（报文零改动，价值全在「首版就做」）；② 产包证明字段集由本库自定，取四项下限（工具版本 · 基线 `appVersion` · 断言项计数 · 逐文件 `path` + `sha256`），须与产包**同批产出、同批上传、内嵌在产包唯一路径上**；③ 基线内容快照按在架版本归档，并补一条草稿漏写的硬约束——须**归档到发布侧可达处**，否则闸对老基线跑不了；同时明写**打包工具不自持在架版本清单**（跑哪几个基线由发布侧按其兼容矩阵决定），并就地澄清既有句「客户端不持有兼容矩阵的任何副本」中的「客户端」指**运行时客户端**，不含构建期打包工具。校验规则本身不变、不外移。（归档去向：`systems/services/content-service.md`）

**购买域新增错误码的承接：是否新增 `OpError` 成员、各条码的呈现与处置**（登记在 `open-questions/cross-boundary.md`「待承接」） → 已答定，整条移出。**新增 `OpError.Purchase`**，落 `systems/architecture.md` 的枚举**一行**，并补一句「`Purchase` 只由 `purchase.*` 映入」；**不建逐 `code` 表**——本库从来没有逐 `code` 表（只有按 `class` 的默认表），开半张表即制造与对侧台账重复的第二权威，逐 `code` 清单的权威仍在 `backend-design-documents/contracts/envelope.md`。呈现与处置四情形写进 `systems/monetization.md`：处理中（保持待兑现态、留在全屏模态进度态，15 秒软提示按「收据还在处理」与「平台不可达」分岔文案）· 收据无效终态失败（解除待兑现态 + 客服可达面）· 已在另一账号核销（解除 + 客服可达面）· 渠道未开通（不进待兑现态、不出客服可达面）；报文格式错误那一条仍映既有校验档、不进新档。**客服可达面复用既有 `#requestId`**（`STORE_` 文案 + 长按复制的编号 + 一行「请提供此编号联系客服」），不新增独立客服入口、不引入客服地址配置面。另补两个流程步骤：渠道要求商户侧下单时的下单端点前置步（**首版微信不开通、不阻塞上线**）与 Apple `finish()` 作为流程内显式步骤。**不新增变体、不设硬超时、`BlockingNoticeKind` 一格不动。**（归档去向：`systems/architecture.md`、`systems/monetization.md`、`ux/error-and-blocking-ux.md`）
> ⚠ 该条目登记时把 `OpError` 枚举的位置写成 `systems/services/sync-service.md`，实际在 `systems/architecture.md`。移出时一并订正。

**合规域仍欠的两项：剩余时长呈现 · 须改名的流程落屏**（登记在 `open-questions/cross-boundary.md`「待承接」） → 已答定，整条移出。**须改名**落成**启动链内、主菜单之前的一道全屏模态**（**不新增屏**——本库没有改名屏，昵称编辑是 PlayerProfile 屏内的一个区，模态复用其输入与提交路径），status 取不到即放行；**不进阻塞屏变体表**（准入两条判据都不成立），并**就地改写** `account-service.md` 的边界句为四处阻塞点的消歧——那四处是失败态阻塞、玩家无自愈路径，本处是一次性、可自愈、取不到即放行的流程门。提交失败沿用既有映射，标记本身不带二级原因键。**剩余时长**落成两级提醒 + 主菜单常驻指示（复用顶部同步指示同一条带形态），战斗内至多常驻指示、不弹窗；阈值落数据资源、按**秒**计，初值 **1800 / 600**；并就地澄清「呈现用的单调递减倒计时不属『判定』」——它永不决定能否继续游玩，到点仍由既有会话失效路径接住。（归档去向：`systems/services/account-service.md`、`ux/screen-flow.md`、`ux/error-and-blocking-ux.md`）

**本次新产生、仍未决的两项**（不属移出，须新登记）：更高版本客户端基线是否为更低版本基线的超集（成立则「每个在架基线各跑一遍」可简化为「只跑最新」，取决于「发版能否删除随包内容条目」这条未定的内容纪律；本次取安全默认，不依赖它）· 产包证明是否加「按类型的条目计数」一格（对侧的优化路径需要它、但对侧当前未采纳且自注须同批落地，本次不纳入字段集）。

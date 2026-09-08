# Answer log compliance-launch-tiering

- 日期：2026-09-07
- 来源：`inbox/archive/solution-draft-compliance-launch-tiering.md` → `handoffs/2026-09-07-compliance-launch-tiering.md`
- 移出条数：2（`02` 一条整条含从属项 · `06` 一条改造为条件化核对项）

**合规能力的上线分级（含从属项「第三方昵称审核首版是否启用」）**（原 `open-questions/02-account-compliance.md`）
→ **四项能力全部首版必备，不分档**：实名核验（T0，防沉迷的唯一数据源，后置会造成对全体存量账号的一次全量拦截潮而无灰度旋钮）· 防沉迷时段（T0，实名在线后服务端已知 `isMinor`，知情不限制的敞口更大）· 账号注销（T1，PIPL 删除权 + 商店审核查 App 内可注销，且墓碑行使读路径须以 `deleted_at_utc` 判定，越晚做改动面越大）· 数据导出（T0，此前已定）。可后置的是各项的**增强项**，不是能力本身。分档判据：「后置之后再补，是否需要对存量账号做一次追溯动作？需要 → 不得后置」——与发布前置清单既有判据同源。
**从属项**：第三方昵称审核适配器**首版不启用**，并补一条唯一的启用触发器——渠道过审点名要求接入第三方内容审核能力；触发时以真实人工判定样本标定两阈值。
**同批裁决的外部事实（用户批量评审）**：① **首版 = 中国大陆正式发行**（iOS / Android 国内渠道 + 微信）⇒ 分级原样成立，不触发内测形态下「注销可推迟 + 客户端隐藏入口」的跨库承接项，也不触发海外第二套部署；② **主管部门实名认证系统的接入义务暂不裁决**，按现状（只用商用持牌核验）落笔并保留为挂账项——**不写成「已确认无此义务」**。
（归档去向：`operations/deployment.md` 两份发布前置清单 · `vision/scope.md` In scope · `operations/compliance-ops.md`「上线分级」· `contracts/compliance.md` §1 · `operations/moderation.md` · `operations/external-providers.md` · `systems/account.md` 时段判定保证 P1–P5）

**第三方昵称审核的评分阈值取值**（原 `open-questions/06-platform-stack.md`）
→ **首版不启用故不定值**，该条随上一条答结而不再是待办：按 `04` 分片的先例改造为 `06` 的「条件化核对项（不是待办）」，条件是「该能力被触发启用」。形态（两阈值 · 服务商 × 环境维度 · 以真实人工判定样本标定）此前已定，不变。
（归档去向：`open-questions/06-platform-stack.md`「条件化核对项」· `operations/moderation.md` 数值初值表与适配器阈值一节）

**仍未答定、本次新登记的挂账项**：实名核验是否另需对接主管部门的实名认证系统（须以真实过审要求核实）——落 `open-questions/02-account-compliance.md` 的「挂账项」小节，不是设计待答，改动面已逐条写明。

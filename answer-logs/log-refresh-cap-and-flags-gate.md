# Answer log refresh-cap-and-flags-gate

- 日期：2026-08-23
- 来源：`inbox/archive/solution-draft-refresh-lifetime-cap.md` → `handoffs/2026-08-23-refresh-lifetime-cap-client-half.md`；以及 `handoffs/2026-08-23-flags-version-client-gate.md`（对侧 flags 条款落笔时的越界发现，本库自行裁决）
- 移出条数：1（另有两项本库自己的取向在本次定案，它们此前不在待答清单上）

## 逐条

**后端契约条款「flags 回滚须以更高 `flagsVersion` 发布」尚未成文（08-22 新增）** → **对侧已成文**：`flagsVersion` 取自单一全局单调序列 · 严格单调递增、回滚即以历史规则内容发布更大版本 · 同一 `(flagsVersion, 账号)` 解析结果恒定。本库「增大即拉」所依赖的那一半就此到位，**本库规则一字未改**。权威在 `backend-design-documents/contracts/content-manifest.md`「服务端保证」B 组，**本库不复述**。
（归档去向：无需改本库主题文档；条款依赖关系见 `systems/services/content-service.md` 的 flags 一节）

**同批补上本库自己的一处缺口（此前未登记，落笔时发现）：** 单调闸此前只挂在**观测 `X-Flags-Version` 头**这一处，**拉回批次 body 里的 `flagsVersion` 是否也过闸**没写。定案：**拉回版本 > 内存值才应用，否则整批丢弃 + `PushWarning` + 上报一次**（通道与去重口径与「观测到更小版本」相同）；**等值也丢弃**——后端保证同版本结果恒定，等值那批逐字相同，丢弃使「应用」只有一条判据。（归档去向：`systems/services/content-service.md`「flags：`ContentEnabled` 的第三层」）

## 本次定案的两项取向（此前不在待答清单，随对侧收口一并裁决）

- **到期重登的玩家措辞基调** → **最平淡的例行口吻，不附原因句**。附一句原因会把后端可调旋钮写进翻译条目，改值时两处不同步即静默失准。二级键 `ERR_AUTH_SESSION_REVOKED_SESSION_EXPIRED`。（归档去向：`ux/error-and-blocking-ux.md`）
- **软信号 `reauthRecommended` 的「自然时机」** → **启动期续期成功即呈现可跳过的登录屏**；失败即忽略，会话照常有效。启动期是唯一必然经过、必然空闲、且已有现成屏幕的时刻，零新增屏幕与接线。（归档去向：`systems/services/account-service.md`）

## 仍留在清单上的

- **平台密钥库的后置评估**（`open-questions/05-service-contracts.md`）不受本次影响。
- **location 无法被 flags 秒关时的运营替代通道**（同分片）不受本次影响。

## 跨边界

后端侧的机制本体与旋钮记在 `backend-design-documents/answer-logs/log-refresh-lifetime-cap.md` 与 `log-flags-version-monotonic.md`，**本 log 不复述**。两个主题的成对采纳均已完成。

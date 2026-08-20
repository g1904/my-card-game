# `deviceId` 的生成与持久化落点

- id: 2026-08-19-device-id-provisioning
- date: 2026-08-19
- topic: systems/services/account-service.md · systems/architecture.md · systems/common-properties.md
- status: distilled
- distilled-to: systems/services/account-service.md, systems/architecture.md, systems/common-properties.md, .claude/rules/state-save-rules.md, backend-design-documents/contracts/auth.md

## Intent（distilled）

`POST /v1/auth/signin` 把 `deviceId` 列为必填字段，它是后端多设备裁决（`(accountId, deviceId)` 唯一键 · 活跃会话上限 1）与幂等回放窗口的输入；后端契约已把生成与持久化落点明确移交客户端，而本库此前没有落点。本次给出完整形态。

### 一、由客户端生成，不由后端下发

契约已明写落点归客户端，但更强的理由是结构性的：`deviceId` 是 `signin` 请求本身的必填字段，而首次 `signin` 之前客户端与后端之间没有任何会话。要让后端下发，就得新开一个**无鉴权**的「领设备号」端点，它自身还得幂等、下发的值还得被客户端持久化——同一个持久化问题被原样推后一步，代价是多一条协议面与一次启动期网络往返。

### 二、取值 = `Guid.NewGuid().ToString("N")`

32 位小写十六进制、无连字符，客户端侧校验式 `^[0-9a-f]{32}$`。

- **满足两条硬要求**：跨启动稳定由落盘保证，不碰撞由 122 bit 随机性保证（无需任何注册中心或后端协调）。
- **排除全部平台硬件标识**（Android SSAID / OAID / IMEI / MAC，iOS `identifierForVendor` / IDFA）：采集设备硬件标识属个人信息，须单独告知、单独同意并进入隐私清单，而 PIPL 与渠道审核是本作必须正面处理的合规面；契约第三条「重装后变化可接受」已把这一整类方案的唯一卖点（卸载后仍存活）声明为不需要。收益为零、合规成本非零。附带一提：IDFV 在同厂商 App 全部卸载后即变、SSAID 在恢复出厂与部分 ROM 上不稳定，连那个卖点也兑现不满。
- **与库内两个先例同形**：`pushId` 取 GUID；`AccountSeed` 取定长小写 hex、无前缀、便于校验。取 `"N"` 而非带连字符的 `"D"` 免去两侧对大小写 / 分隔符的归一。**库内形态一致比与外部惯例一致更值钱。**

### 三、落点 = `user://cache/device-id.json`，单字段，刻意不带 `accountId`

`{ "deviceId": "..." }`，**仅此一字段**。与 `dismissed-recommended-version.json` 逐条同形：单字段 · 设备维度 · 原子写 · 跨启动保留 · 不进存档 / 不进 Profile / 不上云 · **不按 `accountId` 分区**。

- **「文件里没有 `accountId` 这一格」是承重设计，不是省略。** `sync-envelope.json` 与 `flags.json` 都带 `accountId`，其纪律是「`accountId` ≠ 当前登录账号 → 丢弃 / 重建」。若本文件也带上这一格，同设备切账号就会重新生成一个 `deviceId`，而后端唯一键是 `(accountId, deviceId)`，同设备切回原账号会被判成一台新设备、白挤掉一次会话。**这一格不存在，该错误在结构上不可能被写出来。**
- **不带 `schemaVersion`。** 单字段结构体没有迁移面，那一格纯属仪式；更重的是「不认识的版本即整份丢弃」这个口径对本文件有害——一次版本不认 = 重新生成 = 一次假换设备 = 后端一次假挤下线。
- **不进 `GameSetting`**：它不是玩家可见的设置项，且与设置文件的失效口径不同（设置文件可整份丢弃回落默认，本文件不可）。
- **不进 `PlayerProfile` / `AccountInfo`**：`PlayerProfile` 是账号级、云端权威、跨设备一致的主档，上云后 A 设备会读到 B 设备写的 `deviceId`，多设备裁决当场失效。
- **不与 `sync-envelope.json` 合并**：信封按 `accountId` 校验、切账号时整份丢弃，`deviceId` 会被连坐清掉。
- **不由 `accountId` / `AccountSeed` 派生**：二者是账号维度，同账号的两台设备会算出同一个值，后端唯一键退化为 `accountId` 唯一键。
- **不与 refresh token 同文件**：两者失效口径恰好相反（refresh token 必须按账号失效，`deviceId` 必须切账号不变），同处一份文件会逼出一条「清一半留一半」的写入路径。

### 四、归属 = `account-service.AuthManager` 私有，不进任何服务的公开 API 面

唯一消费点是 `signin` 上行，且既有纪律要求「客户端不得把任何本地判断挂在它上面」。**因此不提供 `TryGetDeviceId()` 这类公开取值方法**——一个公开取值口就把「挂个本地判断」变成一行代码的距离；私有化后这条纪律从纪律阶梯第 4 级（评审清单）抬到第 1 级（跨服务代码里根本写不出来），与 `internal sealed` manager 同款手法。**代价照录：客服排障时无法让玩家直接报设备号**（后端侧以 `(accountId, deviceId)` 为键的反查路径仍在）。

**不落 `sync-service.LocalCacheManager`**，两条独立理由：边界纪律禁止 account-service 伸手进 sync-service 的 manager，而 sync-service 的 API 面上也不该出现「替我原子写一个任意文件」这种方法；且启动顺序对不上——签名那一刻 sync-service 尚未初始化。原子读写走**共享静态工具 `AtomicJsonFile`**（形态见 `systems/architecture.md`）。

### 五、时机与失败语义

惰性：`AuthManager` 首次组装 `signin` 请求时才读文件。**先落盘成功、内存里才认**——若允许「先上行、后落盘」，一旦写盘失败就形成「本次上行用了 X，盘上没有 X」，下次启动生成 Y，玩家每次启动都自己把自己挤下线一次，且这个症状永不自愈。

- 文件不存在 → 生成 → 落盘 → 使用，并留一行 `GD.Print`（信息级，不是告警）：首次生成是一次不可回溯的一次性事件，静默发生则日后排查「玩家为什么被判成新设备」时无任何痕迹。
- 解析失败 / 字段缺失 / 不匹配校验式 → `PushWarning` + 重新生成 + 覆写。
- 落盘失败 → `PushWarning` + 本次进程使用内存态值，**不阻塞登录**；该次登录被后端记成一台新设备，可能挤掉本设备上一次的会话。这是被接受的代价——`user://` 写不了本身已是异常态。
- **三处失败一律 `PushWarning` 而非 `PushError` + 抛**：`deviceId` 永不参与鉴权，缺它不阻断任何流程；抛会把一次可降级的缓存问题升级成登不上游戏。

### 六、`SignInAsync` 签名逐字不变

`deviceId` 是传输层元数据，与 `X-App-Version` 请求头、`baseRevision`、`pushId` 同类——由服务自己填，调用方（登录屏）既无从提供也不该看见；加进签名等于把上一节刚关掉的那个取值口从另一侧重新开出来。填充点是 `AuthManager` 取到值后交给内部后端接口，而不是沉进 HTTP 实现层（离线实现也要能拿到它记日志，且文件 I/O 不该在传输层）。

### 七、五种情形的语义

清缓存 / 重装换机 → 重新生成，视作新设备（被吊销的是本机自己的旧会话，玩家无感）· 多设备同账号 → 各不相同，后登录挤掉先登录 · **同设备多账号 → 不变**，两条记录互不影响 · 同设备同账号重登 → 不变，原地替换。后两行正是「不按 `accountId` 分区」的兑现点：切账号与重登都不产生一次假的挤下线。

**存档 schema 零影响、零迁移；后端零改动、零新增义务。**

## Clarifications

- **`device-id.json` 是否带 `schemaVersion`** → **不带**，并**同批修订三处全称措辞**（`systems/architecture.md` 的 `user://cache/` 一句、`systems/common-properties.md` 的同源一句、`.claude/rules/state-save-rules.md` 的存档版本化一句）：把「一律带 schema 版本 + 迁移路径」改为带判据的措辞（多字段结构体才需版本，单字段文件不需要）。原始输入自身前后不一致——「具体形态」写明无 `schemaVersion`，「约束」一节却把 schema 版本列进 `user://cache/` 的既有纪律。库内已有先例 `dismissed-recommended-version.json`；不改措辞则留下第三处「文档写全称、实现各写各的」漂移。
- **`AtomicJsonFile` 本体的落笔面** → 本次**只写回链**，本体（`systems/architecture.md` 的共享构件条目 + `sync-service.md` 的 `LocalCacheManager` 职责改写）随 `GameSetting` 那一份意图一并落定。
- **「不进 `PlayerProfile` 的三样」是否补成四样** → **不补，改为把判据说清**。原始输入「后果」一节倾向补上。那张表的三样共有的排除判据是「进 Profile 会自指」，而 `deviceId` 不自指——它的排除理由是「账号级云端主档跨设备一致 ⇒ A 设备会读到 B 设备写的值」。把判据写清比条目多一条更有价值，也避免把一条精确判据放宽成「传输层 / 设备维度元数据一律不进」。
- **首次生成是否留日志** → **留一行 `GD.Print`**（信息级）。原始输入定为「首次运行的正常态，不告警」。信息级同时满足「正常态不该 warning」与「关键状态转换要留痕」，成本一行。
- **是否同批更新后端 `contracts/auth.md`** → **更新那一句**，改为一行回链、零规则复述。该句此前有两处失真：`deviceId` 那一半已落；且它称这两条登记在客户端的 `open-questions/cross-boundary.md`，而客户端库明写它们不是跨边界承接项、登记在 `account-service.md`。协议规则一字不改。
- **三项取向照原始输入定稿**：不提供只读 `deviceId` 展示口 · 取值取 32 位小写 hex（`Guid "N"`）· 原子写抽成共享静态工具。
- **原始输入一条理由已失效，落笔时换掉**：它以「设备本地项 vs 账号级项的切分本身未答定」作为「不进 `GameSetting`」的第一条理由，而该切分已在同批落定。结论不变，改写为两条仍成立的理由（它不是玩家可见的设置项 · 两者失效口径不同）。
- **启动链序号不写死**：既有 API 面小节按「只数服务」写作第二步，原始输入按「数上登录屏」写作第三步，两种数法都自洽；新写的段落一律写相对位置（在登录屏之后、flags 刷新之前），不引入第三种读法。

## Open questions

- **`refresh token` 的客户端持有形态**仍未落（同一条待答项的另一半）。本次向它交付一条硬约束（不得与 `device-id.json` 同文件）与一份可直接复用的落点形态；两者互不阻塞，可分别落笔。
- **`ComplianceManager` 的客户端侧覆盖面**与**多设备并发登录的云端裁决规则**不在本次范围内，原样留在待答清单。

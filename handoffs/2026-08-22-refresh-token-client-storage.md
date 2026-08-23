# refresh token 的客户端持有形态与启动期静默续期

- id: 2026-08-22-refresh-token-client-storage
- date: 2026-08-22
- topic: systems/services/account-service · systems/architecture · ux/screen-flow · ux/error-and-blocking-ux · systems/services/sync-service · vision/scope
- status: distilled
- distilled-to: `systems/services/account-service.md`、`systems/architecture.md`、`ux/screen-flow.md`、`ux/error-and-blocking-ux.md`、`systems/services/sync-service.md`、`vision/scope.md`、`backend-design-documents/contracts/auth.md`（对侧承接项）

## Intent（distilled）

后端契约已定「refresh token 不进 `Session`、由客户端落 `user://cache/`」。本次把它在客户端侧落到具体形态，并补上它唯一的消费者。

1. **落点与字段面。** `user://cache/refresh-token.json`，字段 `{ schemaVersion, accountId, refreshToken }`；原子写走 `AtomicJsonFile`、跨启动保留、不进存档 / Profile / 不上云。独立一份文件，四条不合并（`device-id.json` / `sync-envelope.json` / `flags.json` / `device-settings.json`）各有理由，其中「不与 `device-id.json` 合并」是既定硬约束（失效口径恰好相反）。
2. **带 `schemaVersion`，与 `device-id.json` 刻意不同。** 判据是「结构会不会增长到需要逐版迁移」，且「版本不认识就整份丢弃」在本文件上安全——丢弃 = 玩家多登一次，而丢弃设备标识 = 一次假换设备 + 一次假挤下线。这条对照必须与规则同处。
3. **不存过期时刻、不存 access token、不存渠道便利字段。** 设备时钟不可信 ⇒ 客户端无一处可合法据过期时刻分支；`signin` 应答里的 `refreshExpiresAtUtc` **读取即丢弃**。
4. **失效路径穷举六条**（登出 / `session_revoked` / 切账号 signin / 同账号重登 / 每次 rotation / 读取时无效），处置只有「删除 + 清内存」与「覆写」两种。
5. **读写失败一律 `PushWarning` 降级**，且**刻意不沿用 `deviceId` 的「先落盘成功、内存里才认」**——判据是**失败症状是否自愈**，不是「是不是凭据」。
6. **归属 `AuthManager` 私有，不出 API 面**；文件 I/O 不沉进 `HttpAccountBackend`（离线实现也要能走通静默续期）；日志绝不写凭据值（含截断形式）。
7. **消费点 = 启动期静默续期。** `AccountService.InitializeAsync` 上提到登录屏之前，内部「读凭据 → 尝试刷新」；登录屏降为**条件步**。三分支（成功 / `session_revoked` / 网络失败）在报文层面穷举，两种失败一律落回登录屏——登录屏不是阻塞屏，本次不新增阻塞点。
8. **强更闸门只在登录点。** 本库此前三处写作「登录 / 启动 pull」，与后端契约（pull 侧不做版本闸门，由 `signin` 独占）相抵；以契约为准改本库三处。启动 pull 上的「需更新」变体是**存档 schema 维度**的迁移路径，与协议维度的 `minAppVersion` 无关，保持不动。
9. **静默续期的连带缺口不在客户端收口。** 旧客户端可长期不经协议维度闸门；收口手段全在后端侧，本次在对侧库落一条承接项，两侧互相回链。

## Clarifications（interview 产物 · 2026-08-22）

- **静默续期与既定启动链相抵，改哪一处？** → **`AccountService.InitializeAsync` 上提到登录屏之前，登录屏降为条件步**。推翻草稿「启动链第二步（LoginScreen → SignInAsync）改为……」这句未指明改哪份文档的表述；同时补上草稿 `targets:` 漏列的 `systems/architecture.md` 总则 4 与 account-service 的 `IBootstrappable` 位置。依据：`IBootstrappable` 的既有语义就是「按固定顺序驱动各服务的 I/O」，静默续期正是 account-service 自己的 I/O。
- **强更闸门到底在哪触发？** → **只在登录点**，本库三处按后端契约改写。推翻草稿「闸门仍只在 `signin` 判定一次、缺口登记备查」的轻描述——实地核实是本库三处记载**本身就是错的**，那是先于本草稿存在的跨库漂移。改写时明确区分协议维度与存档 schema 维度。
- **客户端是否自己收口？** → **不自收口**。客户端自加「距上次 `signin` 超过 N 天强制回登录屏」会撞「设备时钟不可信」既定纪律（同一条理由已被用来否决存过期时刻），且客户端擅定 N 会与后端 TTL 策略漂移。收口归后端，对侧落承接项。
- **是否存 `refreshExpiresAtUtc`？** → **不存** `[采纳推荐 — 待复核]`。含糊点在于它对诊断有表面价值；取「不存」这一解读的依据是「让错误在结构上写不出来」，与「不存 access token」「`device-id.json` 刻意没有 `accountId` 这一格」同手法。连带明写「应答里该字段读取即丢弃」。
- **凭据落盘保护强度？** → **明文 `user://cache/`** `[采纳推荐 — 待复核]`，**但理由改写为「依托平台沙箱 + 后端 rotation / 窗口外重放即吊销全部会话兜底」**。推翻草稿以「本作不承诺防作弊」为背书这一句：那条边界的成立前提是「作弊者只损害自己」，而凭据泄漏的受害者是账号所有者，属**跨类别外推**，被引用的原文不支持它。同时显式登记已知残余风险（root / 越狱、备份提取、共享设备），并留一条「平台密钥库后置评估」待答项。
- **「硬阻塞只有两处」怎么写？** → **不复述枚举**，只写「本节不新增阻塞点」并回链 `sync-service.md` 不变式①。本库对这「两处」现有三种互不相同的枚举，复述会固化第四种读法。
- **UX 改动面有多大？** → `ux/screen-flow.md` **两句**（流程行 + 「登录屏（应用首屏）」），`vision/scope.md` 一句（同一事实的第三处复述）一并轻改；**`ux/onboarding.md` 不改**（已实地核实全篇无「登录屏 = 首屏」陈述，首玩者必然无凭据）。

## Open questions

- **`[采纳推荐 — 待复核]`：不存 `refreshExpiresAtUtc`**（含「应答里该字段读取即丢弃」这条连带）——按推荐落笔，未经用户当面拍板。
- **`[采纳推荐 — 待复核]`：明文 `user://cache/` 落盘**（含理由改写与残余风险登记）——同上。
- **平台密钥库（Android Keystore / iOS Keychain）的后置评估。** 触发条件与四端（含 Web）行为不一致的处置未定。
- **静默续期绕过协议维度强更闸门的收口手段。** 归后端库，承接项已落 `backend-design-documents/contracts/auth.md` §5。

## Notes / triage

- 越界发现（不在本次处理面内）：① 本库对「硬阻塞只有两处」有三种互不相同的枚举（`architecture.md` 总则 7 · `sync-service.md` 不变式① · 各草稿的口语化复述），全库收口是独立 session 的事；② `backend-design-documents/contracts/auth.md` 的「跨库待办」段仍写着「refresh token 的客户端持有形态尚未写死落点」，本次落笔后该句已过时，但按分派范围本次只加承接项、不动该文件其余内容。
- `.claude/knowledge/systems/account-service.md`（引用层，待建）日后建立时须覆盖本次新增节。

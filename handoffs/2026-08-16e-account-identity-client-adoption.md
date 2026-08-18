# 账号身份模型的客户端承接：AccountInfo 三字段 · account-service 四方法 · 绑定管理 UX

- id: 2026-08-16e-account-identity-client-adoption
- date: 2026-08-16
- topic: systems/player-profile/account-info · systems/services/account-service · ux/onboarding · ux/screen-flow · ux/error-and-blocking-ux
- status: distilled
- distilled-to: `systems/player-profile/account-info.md`、`systems/services/account-service.md`、`ux/onboarding.md`、`ux/screen-flow.md`、`ux/error-and-blocking-ux.md`、`open-questions/deferred-content.md`、`open-questions/cross-boundary.md`、`open-questions.md`、`open-questions/update-log.md`、`answer-logs/log-account-identity-model.md`
- counterpart: `backend-design-documents/handoffs/2026-08-16b-account-identity-model.md`

## Intent（distilled）

账号身份模型的**问题主体归后端库**（由后端实现）。本 handoff 只写客户端那一半——该模型落地后客户端必须同步存在的东西。**不复述后端的 identity 模型、端点报文与错误码定义**，需要时一律回链 counterpart。

它一次解开两处互相等待：`account-info.md` 的「字段 schema 未定 + 多渠道绑定模型未定」，与 `account-service.md` 的 API 面缺三个方法——而后端契约那侧又把绑定端点挂在「待客户端的绑定模型」上。

### 一、`AccountInfo` 的绑定列表是只读投影，不是客户端的真值

绑定关系的权威在后端。客户端持有的是一份随 `/v1/profile/pull` 下行的只读投影：

```csharp
public readonly record struct BoundIdentity(LoginChannel Channel, DateTime BoundAtUtc);
```

三条纪律：**客户端从不写它**（绑定成功后不本地追加，靠绑后一次 pull 取回——本地追加会在弱网下造出一份与云端不一致的展示，错误形态是玩家看到一个其实没绑上的渠道）· **渠道侧的用户标识不进客户端**（后端内部键）· **客户端不需要任何新的读取端点**（它就是 `AccountInfo` 上一个普通只读字段，走既有 pull 与存档路径）。

### 二、`AccountInfo` 的字段本次一并收口

| 字段 | 有无 | 说明 |
|---|---|---|
| `AccountId` | 有 | `Session.AccountId` 的持久化投影，展示用 |
| `AccountSeed` | 有 | 形态已定，见 `systems/common-properties.md` |
| `Identities` | 有 | 见「一」 |
| `CreatedAtUtc` | 有 | 注册时间，玩家档案屏展示；后端权威、随 pull 下行 |
| `Nickname` | 有 | `string`，**不是 `LocalizedText`**——它是用户数据不是 UI 文案 |
| 头像 | **无** | 首版不做 |
| `Status` | **无** | 见下 |
| 实名 / 防沉迷状态 | 不在本 handoff | 归后端库的合规分级 |

### 三、`account-service` 新增四个 B 形态方法，`SignInAsync` 扩一个参数

`RequestChallengeAsync` / `BindChannelAsync` / `UnbindChannelAsync` / `SetNicknameAsync`。

- **`RequestChallengeAsync` 是 `SignInAsync` 的前置一步，不是它的内部实现。** 藏进去则倒计时与重发按钮无从驱动。
- **`SignInAsync` 扩 `LoginCredential` 参数**：自建渠道要交 `identifier + code`，第三方渠道传 `LoginCredential.None` 由服务内部走 SDK 取 authCode。
- **昵称的合法性不由客户端判定**：客户端只做长度与空白这类无争议的输入约束；敏感词与改名频次由后端判定并下发 `code`。客户端自带一份词表 = 第二权威，且改词表要发版。
- **`rate.limited` 映射到 `OpError.Network`**：它与网络类失败共享同一条处置（可重试 + 退避），而 `Auth` 档的语义是「凭据失效」。文案不受影响——文案按 `code` 取。

### 四、渠道 SDK 边界：`bind` 与 `signin` 走同一条取 authCode 的路径

不为绑定另开一条，否则渠道 SDK 的初始化 / 授权 / 错误处理会有两份，而它们必然漂移。

### 五、绑定管理在「玩家档案」屏，不在登录屏

登录屏只做登录（渠道按钮 + 两步握手）。绑定是已登录态的低频操作，放登录屏会让最高频路径变重。**只列出本版本已实现的渠道**（首版两行）——展示一个点了没反应的入口比不展示更差，且依据是「本版本实现了哪些渠道」而非遍历枚举。

**两处必须的二次确认**：解绑，以及绑定失败为「渠道已被占用」时——后者要明确告诉玩家那个渠道下有另一份进度、绑定不会合并两份存档，否则玩家会以为是 bug。

## Clarifications（interview 产物）

三项，其中两项**推翻了草稿原文**：

- **`Nickname` 由谁写进 profile？** → **客户端写，后端只判定**。改名端点只回答「这次提交是否被接受」，接受后由客户端写进 profile 并走既有 push 通道。**因此「改昵称后强制一次 pull」这一条不成立并已删除**（客户端自己就是写入方）；绑定 / 解绑仍需绑后一次 pull。代价（改包可绕过敏感词判定）与它为何可接受，记在 counterpart 的契约里。
- **`Status` 是否进 `AccountInfo`？** → **不进**。这推翻了草稿「二」的字段表里那一行。`restricted` / `banned` 的客户端表现全部由登录应答分支与 `compliance.*` 错误码承载；本地副本没有消费点，且会在会话中途过期（封禁发生时本地那份仍写着 `active`）。**`CreatedAtUtc` 保留**——它有明确展示消费点，且后端在建号时与种子同一步写入。
- **改名端点本次是否落契约？** → **是**，与本 handoff 同批。否则客户端有 `SetNicknameAsync` 而后端无端点。

## Open questions

- **绑定 / 解绑后那一次 pull 失败怎么办？** 已按既有降级纪律推演为「不阻塞、列表暂不刷新、下次 pull 自然一致」（依据：绑定列表是只读投影，展示滞后无实际损失；与购买段「购后 pull 失败阻塞在主菜单重试」**刻意不同**——那里阻塞是因为付费权益必须落地）。若日后绑定与某项权益挂钩，这条要回头重议。
- **`ERR_AUTH_NICKNAME_REJECTED` 的二级文案**：`detail.reasonKey` 的取值集合待后端合规分级落定，客户端侧**兜底文案的结构已定**（未知 `reasonKey` 必须有兜底），只差逐条措辞。
- **`deviceId` 的生成与持久化落点**、**refresh token 的客户端持有形态**——两条早于本次的跨边界欠账，不在本 handoff 范围。

## Notes / triage

来源：`inbox/solution-draft-account-identity-model.md`（`status: decided`）。与后端库同批运行，counterpart 见文件头——**两侧同批采纳，单侧采纳即两侧不一致**。

`AccountInfo` 增字段 ⇒ 存档 schema 版本 bump 一次，迁移 = 老档缺字段以默认值补齐（空列表 / 默认时间 / 空昵称），无损。

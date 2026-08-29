# ADR-0107 — 账号身份的客户端承接：绑定列表是只读投影，昵称客户端写、后端只判定

- **状态：** Accepted
- **日期：** 2026-08-16
- **来源：** handoffs/2026-08-16e-account-identity-client-adoption.md

## 背景

账号身份模型的问题主体归后端库，但它落地后客户端必须同步存在一批东西。此前两处互相等待：`account-info.md` 的字段 schema 与多渠道绑定模型未定，`account-service.md` 的 API 面缺三个方法，而后端契约那侧又把绑定端点挂在「待客户端的绑定模型」上。

## 决策

**`AccountInfo.Identities` 是随 pull 下行的只读投影，客户端从不写它。** 绑定 / 解绑成功后靠一次 pull 取回，不本地追加；渠道侧的用户标识（openid 一类）是后端内部键，不进客户端、不进存档；不新增任何读取端点。

**`Nickname` 反向：客户端是写入方，后端只判定。** 提交经 `account-service` 走一次服务端判定（敏感词与改名频次），接受后由客户端写进本字段并随既有 push 上行——改昵称因此**不需要**绑后 pull 那一步。它是 `string` 而非 `LocalizedText`（用户数据，不是 UI 文案）。

**`Status` 不进 `AccountInfo`**；`CreatedAtUtc` 保留。

**绑定 / 解绑落「玩家档案」屏，不在登录屏**，且只列出本版本已实现的渠道；解绑与「渠道已被占用」两处强制二次确认。

`account-service` 新增四个方法、`SignInAsync` 扩 `LoginCredential` 参数，`rate.limited` 映射 `OpError.Network`。字段表与 API 面 → `systems/player-profile/account-info.md`、`systems/services/account-service.md`。

## 理由

绑定关系的权威在后端，本地追加会在弱网下造出一份与云端不一致的展示——错误形态是玩家看到一个其实没绑上的渠道。

`Status` 不进本地有两条各自成立的理由：它没有消费点（`restricted` / `banned` 的客户端表现全部由登录应答分支与 `compliance.*` 错误码承载），且它会在会话中途过期——封禁发生时本地那份仍写着 `active`。

昵称合法性不由客户端判定：客户端自带一份词表 = 第二权威，且改词表要发版。

`rate.limited` 归 `Network` 而非 `Auth`：它与网络类失败共享同一条处置（可重试 + 退避），而 `Auth` 档的语义是「凭据失效」。

绑定管理不落登录屏：登录是最高频路径，把低频操作放进去会让它变重。只列已实现渠道——展示一个点了没反应的入口比不展示更差。

## 备选方案

- **绑定成功后本地追加、不做绑后 pull** — 否决：弱网下造出与云端不一致的展示。
- **`Status` 进 `AccountInfo`** — 否决：无消费点且会中途过期。
- **改昵称后强制一次 pull** — 否决：客户端自己就是写入方，这一步不成立。
- **`RequestChallengeAsync` 藏进 `SignInAsync` 内部** — 否决：藏进去则倒计时与重发按钮无从驱动。
- **为绑定另开一条取 authCode 的路径** — 否决：渠道 SDK 的初始化 / 授权 / 错误处理会有两份，而它们必然漂移。

## 后果

- `systems/player-profile/account-info.md` 与 `systems/services/account-service.md` 是客户端侧权威；`ux/onboarding.md` 与 `ux/screen-flow.md` 承接两屏的分工与两处二次确认。
- 「渠道已被占用」的二次确认必须明确告诉玩家那个渠道下有另一份进度、绑定不会合并两份存档——否则玩家会以为是 bug。这与账号不做隐式合并同向 → `backend-design-documents/decisions/ADR-0010-account-identity-no-implicit-merge.md`。
- 绑定 / 解绑后那一次 pull 失败**不阻塞**（列表暂不刷新、下次 pull 自然一致），与购买段「购后 pull 失败阻塞在主菜单重试」刻意不同；若日后绑定与某项权益挂钩，这条要回头重议。
- 跨库对位：identity 模型、端点报文与错误码的权威在 `backend-design-documents/contracts/auth.md`，本库不复述。

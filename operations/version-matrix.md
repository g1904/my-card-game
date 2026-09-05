# version-matrix —— 版本兼容矩阵

强更闸门与版本协商的服务端判定输入。语义权威在 `contracts/envelope.md` §7e；此处是**矩阵本体与它的运维流程**。

## 形态

- **矩阵由后端单点维护，客户端不持有任何副本。** 它是闸门判定的输入，必须与判定逻辑同处。
- **它的数据形态即旋钮表的一员**：落 `config_knob`，改值不发版（`environments.md`）。
- 至少含四项：

  | 项 | 含义 |
  |---|---|
  | 支持的 `appVersion` 下界 | 低于它的客户端在签发 token 时被闸门拦下 |
  | 并存的 URL 主版本 | `/v1/` … |
  | 并存的 `manifestSchema` 集合 | 各自的下线计划 |
  | 并存的 `schemaVersion` 集合 | 各自的下线计划 |

## 当前矩阵

**多数项尚未填值**：后端未开工、无在架版本。`schemaVersion` 集合已展开为下方的子表。

| 项 | 值 |
|---|---|
| `appVersion` 下界 | 待定 |
| URL 主版本 | `v1` |
| `manifestSchema` 集合 | 待定 |
| `schemaVersion` 集合 | 见下方「`schemaVersion` 集合」子表 |

### `schemaVersion` 集合

**四列全部是本库自己持有真值的东西，一列都不描述该版本「含什么字段」。**

| `schemaVersion` | 接受起始 | 下线计划 | 客户端登记回链 |
|---|---|---|---|
| **1** | 首个版本上线时（待落） | — | `game-design-documents/systems/services/profile-schema-versions.md` |

- **第四列是回链，不是摘要。** 想知道第 N 版改了什么 → 点过去看客户端登记表；**本库一个字段名都不写**。判据即「契约不把 Profile 的字段表抄进本库」（`contracts/envelope.md` §8）。这与 §5 白名单的处理**刻意不同**：白名单里的 JSON path 是后端**自己要读**的复算输入，故它进本库；不透明段的字段名后端根本不读，抄进来只会多一份必然漂移的真值。
- **「接受起始」记的是本库开始接受该版本的时刻 / 配置版本**，不是客户端发版时刻——后者是对侧的事实。
- **下线计划照下方运维流程填**（先提下界、等存量会话自然翻转、再删实现分支），不新增语义。

## 运维流程

- **闸门在签发 token 时判定一次**，会话期内不因阈值提升而中途变严。
- **提升 `appVersion` 下界的生效点是玩家的下一次登录**，永远不会打断进行中的轮回。因此**不得假定它即时生效**：覆盖存量会话所需时间的上限 = refresh 链的绝对寿命上限（`contracts/auth.md` §5b）。运营在排期时按这个上限计算。
- **下线一个 `schemaVersion` 或 `manifestSchema` 是同一条纪律**：先把下界提上去，等存量会话自然翻转，再删实现分支。
- **在架版本集合同时是内容发布侧校验闸的输入**——「哪些基线要各跑一遍」由本矩阵给出，不另立一份清单（`deployment.md`）。

Source: `handoffs/2026-09-03-backend-stack-and-hosting.md` · `handoffs/2026-09-03-schema-bump-ledger-authority.md`。

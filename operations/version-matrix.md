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
| `manifestSchema` 集合 | 待定（首发即 `{1}`，路径分支 `s1`；下线计划照下方序列填） |
| `schemaVersion` 集合 | 见下方「`schemaVersion` 集合」子表 |

### `schemaVersion` 集合

**四列全部是本库自己持有真值的东西，一列都不描述该版本「含什么字段」。**

| `schemaVersion` | 接受起始 | 下线计划 | 客户端登记回链 |
|---|---|---|---|
| **1** | 首个版本上线时（待落） | — | `game-design-documents/systems/services/profile-schema-versions.md` |
| **2** | 付费角色系列的客户端版本发布**之前**（待落） | 待定——`1` 的下线按下方运维流程排期，先提 `appVersion` 下界、等存量会话自然翻转、再删实现分支 | 同上 |

- **`2` 的成立条件如实写下**：付费角色系列若改在客户端**首发之前**落地，客户端侧的一切结构改动仍归 `schemaVersion = 1`，本行随之整行不成立、矩阵零改动。当前预期是它在首发之后引入（`game-design-documents/decisions/ADR-0255-*`）。
- **`sync.payload_schema_unsupported` 的 `detail.supportedSchemaVersions` 随本子表走** ⇒ 两版并存期间为 `[1, 2]`。
- **顺序纪律是硬的：矩阵先加、客户端后发。** 矩阵未加就发客户端 ⇒ 每一个新版客户端的第一次 push 即被 `sync.payload_schema_unsupported` 拒。它是 `Upgrade` 档、不硬阻塞，但玩家进度上不去云端。
- **第四列是回链，不是摘要。** 想知道第 N 版改了什么 → 点过去看客户端登记表；**本库一个字段名都不写**。判据即「契约不把 Profile 的字段表抄进本库」（`contracts/envelope.md` §8）。这与 §5 白名单的处理**刻意不同**：白名单里的 JSON path 是后端**自己要读**的复算输入，故它进本库；不透明段的字段名后端根本不读，抄进来只会多一份必然漂移的真值。
- **「接受起始」记的是本库开始接受该版本的时刻 / 配置版本**，不是客户端发版时刻——后者是对侧的事实。
- **下线计划照下方运维流程填**（先提下界、等存量会话自然翻转、再删实现分支），不新增语义。

## 运维流程

- **闸门在签发 token 时判定一次**，会话期内不因阈值提升而中途变严。
- **提升 `appVersion` 下界的生效点是玩家的下一次登录**，永远不会打断进行中的轮回。因此**不得假定它即时生效**：覆盖存量会话所需时间的上限 = refresh 链的绝对寿命上限（`contracts/auth.md` §5b）。运营在排期时按这个上限计算。
- **下线一个 `schemaVersion` 或 `manifestSchema` 是同一条纪律**：先把下界提上去，等存量会话自然翻转，再删实现分支。

  `manifestSchema` 的双发下线序列由此展开为三点（**保留时长 = (T1 − T0) + 绝对寿命上限，绝对下界即该上限**）：

  | 时点 | 动作 | 判据 |
  |---|---|---|
  | T0 | 发布 `manifestSchema` N，两个路径分支并存，本集合 = `{N-1, N}` | — |
  | T1 | 提 `appVersion` 下界到「首个支持 N 的客户端版本」，给 N-1 填下线计划 | 覆盖率 ≥ 阈值（口径与阈值见 `content-delivery-ops.md`「覆盖率口径」「阈值推导」，**本表不复制第二份**） |
  | T2 = T1 + 绝对寿命上限 | 停发 N-1 分支、删实现分支 | 上一条运维流程：覆盖存量会话所需时间的上限 = refresh 链绝对寿命上限（`contracts/auth.md` §5b · §8） |

  T2 的等待期不可省：T1 之后仍有只走 `refresh`、从不 `signin` 的存量会话不经过闸门，仍会请求 N-1 分支。**该等待期不是本表自己的旋钮**，它随 `auth.md` §8 的绝对寿命上限走——本库对「旧客户端最长能活多久」只有一份答案。
- **在架版本集合同时是内容发布侧校验闸的输入**——「哪些基线要各跑一遍」由本矩阵给出，不另立一份清单（`deployment.md`）。

Source: `handoffs/2026-09-03-backend-stack-and-hosting.md` · `handoffs/2026-09-03-schema-bump-ledger-authority.md` · `handoffs/2026-09-07-manifest-schema-path-branch-and-cdn-failure-codes.md`（`manifestSchema` 双发的下线序列）· `handoffs/2026-09-12-premium-character-series-unlock.md`（`schemaVersion` 子表的 `2` 行与顺序纪律）。

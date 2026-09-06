# ADR-0023 — 签名密钥的保管边界：KMS 只保管被包裹私钥，不进签发热路径

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** `handoffs/2026-09-03-backend-stack-and-hosting.md` · `answer-logs/log-backend-stack-and-hosting.md`

## 背景

栈落定后要给「token 签名密钥保管」这一挂账项落形态。最合规姿态的做法是「私钥永不出 KMS、签发走 KMS Sign API」——但 access token 的签发在**每一次登录与每一次 refresh** 上，把它挂到一个外部托管服务上，等于把全站登录能力的可用性押给该服务。

## 决策

**access token 保持 EdDSA(Ed25519) 自包含 JWT；KMS 只保管被包裹的私钥，签名在进程内完成——KMS 不在签发热路径上。**

- 进程启动时向 KMS 解包一次，私钥只在内存：**不落盘、不进环境变量、不进镜像**。
- **代价如实记下**：失去逐次签名审计，降级为**解包事件审计**（谁、在哪个环境、什么时候解包过）。这是被接受的取舍。
- 轮换纯服务端、零客户端义务、不需要发版：JWT header 带 `kid`，旧 `kid` 保留 ≥ access token TTL + 时钟偏移余量；例行 90 天 + 疑似泄漏立即轮换。
- `refreshSecret` 同处 KMS、带自己的 `kid`（落会话行 `refresh_key_id`）。
- 形态、轮换窗口与对照表 → `operations/environments.md`；签发侧 → `systems/account.md`。

## 理由

**KMS 停机不影响登录**——把全站登录能力的可用性押给一个外部托管服务，是**用一次审计换一个单点**（`operations/environments.md`）。签发走 KMS Sign API 还额外依赖一项未核实的厂商能力。

算法保持 EdDSA 而非与内容签名共用 ES256：**ECDSA 签名含随机 `k`，无法满足 `ADR-0004` 要求的「回放完全相同的那一对 token」**。两把钥匙的档位、轮换窗口与爆炸半径都不同，共用算法是把一个不相干的相似性当成理由。

## 备选方案

- **签发走 KMS Sign API（私钥永不出 KMS）** — KMS 停机 = 全体无法登录；且依赖一项未核实的厂商能力。
- **access token 改用 ES256 以与内容签名共用工具链** — 省一套密钥心智，但 ECDSA 的随机 `k` 使确定性回放不成立；两把钥匙的约束本就不同。
- **私钥离线保管、发布时人工签名** — 引入「人可以直接签」的旁路（同 `operations/content-delivery-ops.md` B4 的判据），且与每次登录都要签名的热路径根本不相容。

## 后果

- **排除「私钥永不出 KMS」类合规姿态**：部署形态必须允许把私钥解包进进程内存。若日后合规要求变化，本 ADR 是要被重新审视的那一条。
- **审计能力降级已被明确接受**——重新提出「为什么不用 KMS Sign」等于要求推翻这次取舍，须连同登录可用性的单点一起论证。
- 内容 manifest 的签名私钥是**另一把钥匙、另一套判据**（`operations/content-delivery-ops.md` B 组），两者不共用保管流程；JWT 的 `kid` 与 manifest 的 `keyId` 是两套命名空间。
- 轮换零客户端义务 ⇒ 本决策不产生任何跨库承接项。

# 拆解粒度判据（后端侧）与子需求签核语义

- id: 2026-08-19-breakdown-granularity-and-signoff
- date: 2026-08-19
- topic: requirements/_index.md（后端侧粒度判据与签核语义的落点）
- status: distilled
- distilled-to: requirements/_index.md

## Intent（distilled）

> **一句话：** `derive → breakdown → blueprint` 这条链的**拆解工艺**在客户端侧已成文；本库落下**形态同构、指标不同**的后端那一半，两侧互相回链、互不复述。

### 为什么这一半必须落在本库

拆解粒度判据要两库通用，但后端库没有文件边界（技术栈未定）、没有 EventBus、没有 Godot 编辑器——客户端的那几个指标搬过来是空的。而把后端指标写进客户端的 `requirements/_index.md` 即是**两库台账合并**：两份表会各自漂移，且没有任何机制能发现它们不一致。故两侧各写各的指标，只在**形态**上同构。

同理，本库不复述客户端的指标表与签核规则的论证，需要时回链 `game-design-documents/requirements/_index.md`。

### 后端侧的等价指标

客户端量的是「一次 `/blueprint` 能一口吃下多少」，后端量的是同一件事在协议与存储上的对应面：

| 客户端量的东西 | 后端的等价面 |
|---|---|
| 新建 + 修改文件数 | 触及的端点 / 报文（新端点 ≤ 1，或既有端点上 ≤ 1 组字段） |
| 涉及的服务数 | 主写的持久化对象数（profile 记录 / `revision` 计数器 / `pushId` 窗口 / manifest，≤ 1 处） |
| 新引入 EventBus 信号数 | 新契约字段组 ≤ 1，且必须已在 `contracts/` 中定义 |
| 存档 schema 迁移点 | 存储 schema / 版本迁移 ≤ 1 |
| 「能在 Godot 编辑器里跑出来」 | 「能表述为**给定请求 / 状态 → 期望应答 / 存储结果**」 |

「新契约字段组必须已在 `contracts/` 中定义」不是新规则：本库已定「`client-facing` 的 FR 必须先有契约，FR 只引用不发明」，拆解同样不得自造报文。

### 一条后端专有的不可切约束

> 模板强制的 `## Failure & retry semantics` **必须在同一个子需求内完整**——不得把「正常路径」与「幂等 / 重试 / 冲突语义」切成两个子需求。

理由：半个失败语义不可验证，而弱网下的幂等与重试是后端 FR 的承重设计。先做正常路径、后补重试的切法，会产出一个**验收标准全通过但线上必炸**的中间状态。

### 机械处理与签核语义与客户端同形

软界不硬拒（超界须在拆解 `_index.md` 写一行理由）；签核取「继承父 FR 的签核状态 + `## Open questions` 非空 ⇒ `draft`」的例外闸，判定对象是签核状态而非 `status` 字面值。这两条的论证在客户端库，本库只落条文并回链。

## Open questions

_（无。）_

## 客户端侧影响

不改动客户端 ↔ 后端边界的任何语义，不触及任何契约报文。客户端侧的对称落笔见 `game-design-documents/handoffs/2026-08-19-breakdown-granularity-and-signoff.md` 与 `game-design-documents/requirements/_index.md`。

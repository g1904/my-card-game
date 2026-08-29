@.claude/rules/Context.md

# 子代理分发（skill 内已获授权，无需再问用户）

执行 `.claude/skills/` 下的任一 skill / 工作流时，**允许并鼓励主动派发子代理**（Agent 工具）承担扇出型工作，不必等用户开口要求。适用场景：

- 跨多个系统 / 多份设计文档的并行探查（blueprint / investigate / review-feature / batch-\* 的「探索」阶段）；
- 需要横扫大量文件才能得出一个结论、而正文只需要结论不需要文件内容的检索（用 `Explore`）；
- 彼此独立、可同时推进的子任务 —— 一条消息内发多个 Agent 调用使其并发执行。

派发规则：

- **模型与思考强度一律继承父会话**：调用 Agent 时**省略 `model` 参数**（也不要在 `.claude/agents/` 里给这些代理钉死 model），由其继承本会话的 `model` / `effortLevel`（见 `.claude/settings.json`）。仅当明确判断某个廉价机械子任务适合降级时才显式指定，且需在回答中说明。
- **只读优先**：探查/检索类子任务用 `Explore` 或 `general-purpose`；**写文件、编辑源码的动作留在主上下文执行**，不外包给子代理，以免绕过四个快照目录的只读纪律与本仓库的分支约定。
- **约束随任务下发**：子代理不继承本文件的完整规范，派发时必须在 prompt 里带上关键前提 —— 代码只写 `game-feature-branch/`（客户端）与 `backend-feature-branch/`（后端）；`game-testing-branch/`、`game-production-branch/`、`backend-testing-branch/`、`backend-production-branch/` 四个快照目录只读；两个设计库（`game-design-documents/`、`backend-design-documents/`）归用户所有，仅在明确要求时才编辑。
- 已委派的检索不要自己再跑一遍；子代理返回的结论需自行判断可信度，必要时抽查关键文件后再采信。
- 一次派发的子代理数量与任务规模匹配，默认不超过 5 个；`Workflow` / deep-research 仍需用户显式要求，不在本授权范围内。

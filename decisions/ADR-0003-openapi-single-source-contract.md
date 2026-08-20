# ADR-0003 — 契约表达形式 = OpenAPI 3.1 单点，不共享 DTO 代码

- **状态：** Accepted
- **日期：** 2026-08-11
- **来源：** `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md` · `answer-logs/log-contract-expression-envelope-and-error-codes.md`

## 背景

客户端与后端要就同一批报文达成一致，形态权威必须只有一处。Godot 客户端是 .NET/C#，后端技术栈未定且**可能也选 C#**——一旦如此，「不如两侧共享一个 DTO 程序集」会立刻成为看起来最省事的选项。这个选项与根约定的分支线独立性冲突，需要在它被反复提出之前把依据固化下来。

## 决策

- 契约以 **OpenAPI 3.1 + JSON Schema 2020-12** 单点定义，落点 `contracts/openapi.yaml` + 拆分的 `contracts/schemas/*.json`，`paths` 同时覆盖 API 域与 CDN 域。
- **明确否决共享 DTO 代码，即使后端最终也选 C#**：两侧各自持有自己的 DTO，可生成也可手写，契约不规定实现手段。
- **markdown ↔ spec 分工**：markdown 承载语义、理由与承重纪律；spec 单点承载字段名、类型、必填性、枚举值。冲突时**字段形态以 spec 为准，语义以 markdown 为准**。
- 落笔时机、形态迁移规则、`info.version` 与 `/v1/` / `schemaVersion` 三者不复用 → `contracts/envelope.md` §1；完成判据与三条机检断言 → `contracts/_index.md`。

## 理由

依据不在技术栈选型，而在根约定：客户端与后端是两条**从不互相合并**的分支线（理由是后端代码不得被编译进游戏程序集、不得被 Godot 导入器扫描并随客户端打包）。共享 DTO 要成立就需要一个被两条分支线同时引用的编译期依赖——它要么住在某一条分支里（当场违反那条理由），要么需要第三个发布物，而那个发布物的版本节奏要同时迁就 Godot 4.7 的 .NET 目标框架与后端运行时。→ `contracts/envelope.md` §1。

选 3.1 而非 3.0：3.0 的 schema 是 JSON Schema 的裁剪方言，`nullable` 一类差异会以「字段可空性对不上」的形式在实现期才暴露。

## 备选方案

- **共享 C# DTO 代码** — 需要跨两条独立分支线的共享编译期依赖，与根约定直接冲突；且把契约的版本节奏绑死在两个运行时的交集上。
- **OpenAPI 3.0** — schema 是裁剪方言，工具链差异在实现期才暴露。
- **gRPC / Protobuf** — CDN 侧的 manifest / blob 本就是裸 HTTP 静态对象（会造出两套栈），客户端跨四端导出（含 Web）；请求量级（每玩家每事件一次上行）远不到需要二进制协议的地步。
- **只用 markdown 描述报文、不落 spec** — 字段形态无机检基准，两侧各读各的理解。

## 后果

- 「后端也用 C# 了，不如共享 DTO」不再是一个开放问题——重新提出它等于要求推翻本 ADR 并重新论证分支线独立性。
- 两侧各自的 DTO 漂移只能靠 spec 对账发现，故 `contracts/_index.md` 立了三条机检断言 + 人工清单；断言的**承载位置**待 `06-platform-stack.md`。
- 各 markdown 契约的字段表在对应端点进入 spec 后**同批降级**为「字段名 + 语义」，形态列删除——任何时刻形态只有一处权威。
- `openapi.yaml` 不预先建空壳：触发点 = 任一侧首个端点进入实现，由动手的那一侧落笔（即使动手方是客户端，spec 仍落本库）。

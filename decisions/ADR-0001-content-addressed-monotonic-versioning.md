# ADR-0001 — 内容分发走内容寻址，`contentVersion` 严格单调递增

- **状态：** Accepted
- **日期：** 2026-08-11
- **来源：** `handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md` · `answer-logs/log-content-delivery-manifest-and-flags.md`

## 背景

overlay 内容需要一条能被边缘永久缓存、又能在事故时快速撤回的分发通道。两个要求彼此拉扯：永久缓存要求 URL 的字节永不改变；快速撤回的直觉做法是「把版本号退回上一版」。同时客户端已把 `StartContentVersion` / `LastContentVersion` 用作轮回期内的单调判据，版本号一旦可退，那两个判据当场失效。

## 决策

- **blob 以内容寻址下发**：URL 形如 `<contentRoot>/blobs/<sha256>`（SHA-256 小写 hex），字节不可变，缓存 `public, max-age=31536000, immutable`；逻辑路径只出现在 manifest 条目里，`contentRoot` 随信封 / 配置下发、**不写进被签名的 manifest**。
- **`contentVersion` 严格单调递增，不允许回退。** 撤回一个坏 overlay 的手段是**前滚**：发布一个更大的 `contentVersion`，其内容指回旧 blob。
- 报文形态、三条服务端保证（稳定 URL · 字节不可变 · 发布原子）、三个版本号（`appVersion` / `manifestSchema` / `contentVersion`）的分工 → `contracts/content-manifest.md`。

## 理由

内容寻址让「前滚指回旧 blob」成为**零成本**操作——旧字节本就还在，不需要重新上传、不需要重新签名，撤回与首次发布走完全相同的一条路径。因此「不允许版本回退」不是一条纯粹的限制，它有等价替代。

反过来允许回退要付两笔代价：客户端必须多一条「降级」分支（而分支只在事故时走，恰是最难验证的那类代码），且破坏 `StartContentVersion` / `LastContentVersion` 的单调判据。→ `contracts/content-manifest.md`「版本化：三个版本号的分工」。

## 备选方案

- **允许 `contentVersion` 回退以表达回滚** — 给客户端引入一条只在事故时执行的降级分支，并破坏两个已定的单调判据；而前滚已能等价达成撤回。
- **按逻辑路径寻址 blob（`<contentRoot>/content/cards/card_x.tres`）** — 同一 URL 的字节会随发布改变，`immutable` 缓存失效，边缘必须回源校验。
- **把 `contentRoot` 写进被签名的 manifest** — CDN 域名切换或多区域托管时须重签全部历史 manifest。

## 后果

- 运营侧**没有「回滚」这个动作，只有「再发一版」**：发布流水线与事故预案按前滚编写，落点 `operations/`（栈落定后）。
- 撤回一整段已发布内容的速度是 **overlay 的冷启动级**；秒级止血只能靠 flags 通道（ADR-0002），且它只能「停止新激活」，不能撤回。
- manifest 端点只能 `no-cache` 或秒级 TTL —— 它决定撤回的实际生效速度。
- 客户端侧对位：拒绝 `contentVersion` 小于本地已生效版本的 manifest（防回放），语义权威在 `game-design-documents/systems/services/content-service.md`。

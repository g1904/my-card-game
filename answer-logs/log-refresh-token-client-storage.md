# Answer log refresh-token-client-storage

- 日期：2026-08-22
- 来源：`inbox/solution-draft-refresh-token-client-storage.md` → `handoffs/2026-08-22-refresh-token-client-storage.md`
- 移出条数：1

---

- **refresh token 的客户端持有形态未落笔**（`open-questions/05-service-contracts.md`；同条登记在 `systems/services/account-service.md`「待决问题」第 2 条）
  → **答定。** 落点 `user://cache/refresh-token.json`，字段 `{ schemaVersion, accountId, refreshToken }`（带版本，与 `device-id.json` 刻意不同）；四条不合并各有理由；失效路径穷举六条；读写失败一律 `PushWarning` 降级且刻意不沿用 `deviceId` 的「先落盘成功、内存里才认」（判据 = 失败症状是否自愈）；归属 `AuthManager` 私有、不出 API 面；消费点 = 启动期静默续期，`AccountService.InitializeAsync` 上提到登录屏之前、登录屏降为条件步。
  （归档去向：`systems/services/account-service.md`「refresh token 的持有与失效」· `systems/architecture.md` 总则 4 · `ux/screen-flow.md` · `vision/scope.md`）

**部分未答定 / 本次新增，仍留在待答清单：**

- 两项 `[采纳推荐 — 待复核]`（不存 `refreshExpiresAtUtc` · 明文 `user://cache/` 落盘）——按推荐落笔，未经当面拍板。
- 平台密钥库的后置评估（新增）。
- 静默续期绕过协议维度强更闸门的收口手段（新增 · 跨边界，承接项已落 `backend-design-documents/contracts/auth.md` §5）。

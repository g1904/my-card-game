# Answer log device-id-provisioning

- 日期：2026-08-19
- 来源：`inbox/solution-draft-device-id-provisioning.md` → `handoffs/2026-08-19-device-id-provisioning.md`
- 移出条数：1

- **`deviceId` 的生成与持久化落点** → 客户端生成 `Guid.NewGuid().ToString("N")`（32 位小写 hex，校验式 `^[0-9a-f]{32}$`），落 `user://cache/device-id.json` 单字段、**刻意不带 `accountId`、不带 `schemaVersion`**；归 `account-service.AuthManager` 私有，不出任何 API 面、不进 `SignInAsync` 签名；惰性读取、**先落盘成功再上行**，三处失败一律 `PushWarning`（首次生成留一行 `GD.Print`）；五种情形（清缓存 / 重装换机 / 多设备同账号 / 同设备多账号 / 同设备重登）逐行与后端契约对位。存档 schema 零影响，后端零新增义务。（归档去向：`systems/services/account-service.md`）

**同一条待决项中 refresh token 的客户端持有形态仍留在待答清单**，并由本次新增一条硬约束：**不得与 `device-id.json` 合进同一文件**（两者失效口径恰好相反）。

**同批答定的相邻结论**（不单独占条目）：`deviceId` 与 `locale` 各自一份 `user://cache/` 文件、不合并；原子写走共享静态工具 `AtomicJsonFile`（本体登记在 `systems/architecture.md`）；`user://cache/` 的 schema 版本要求由全称改为按判据（三处同源措辞同批修订：`systems/architecture.md` · `systems/common-properties.md` · `.claude/rules/state-save-rules.md`）；后端 `contracts/auth.md` 的「余下两点仍在客户端侧待落」一句订正为一行回链。

> 本条从未作为条目进入任何 `open-questions/` 分片——它只登记在 `systems/services/account-service.md` 的「待决问题」，故分片无条目可删。

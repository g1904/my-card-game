# ADR-0071 — `deviceId` 由客户端生成并落 `user://cache/device-id.json`；文件内刻意不带 `accountId`

- **状态：** Accepted
- **日期：** 2026-08-19
- **来源：** handoffs/2026-08-19-device-id-provisioning.md

## 背景

后端以 `(accountId, deviceId)` 为唯一键做会话裁决（活跃会话上限 1）。`deviceId` 要么由后端下发，要么由客户端生成。而生成之后，它落盘的文件里还可以顺带存一个 `accountId` 作便利字段。

## 决策

`deviceId` 由**客户端生成**（`Guid.NewGuid().ToString("N")`），落 **`user://cache/device-id.json`**。

**「文件里没有 `accountId` 这一格」是承重设计，不是省略。**

归 **`AuthManager` 私有，不出任何服务的 API 面**。落盘语义是「**先落盘成功、内存里才认**」。

→ `systems/services/account-service.md`。

## 理由

若文件里带 `accountId`，就会出现「切换账号时是否要换 `deviceId`」这个问题，而任何一种错误答案都会让**同设备切回原账号被判成一台新设备、白挤掉一次会话**。**这一格不存在，该错误在结构上不可能被写出来。**

后端下发被否是因为它需要新开一个**无鉴权端点**（首次启动尚无账号），而同一个持久化问题被原样推后一步——下发回来的值仍要落盘。

## 备选方案

- **后端下发 `deviceId`** — 否决：需无鉴权端点，且持久化问题原样存在。
- **由 `accountId` / `AccountSeed` 派生** — 否决：后端 `(accountId, deviceId)` 唯一键退化为 `accountId` 单键，会话裁决失效。
- **文件内带 `accountId` 便利字段** — 否决：见理由。

## 后果

- 这份文件**不与 `refresh-token.json` 合并**——两者的失效口径恰好相反（→ `ADR-0080`）。
- `device-id.json` 是**单字段的设备维度小文件，不带版本**：无脑加版本会让「版本不认识就整份丢弃」误伤它。
- 落盘顺序（先盘后内存）与 refresh token 的相反，两处的不对称必须与规则同处陈述。

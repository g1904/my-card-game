# Answer log platform-keystore-upgrade

- 日期：2026-09-02
- 来源：`inbox/solution-draft-platform-keystore-upgrade.md`（→ `handoffs/2026-09-02-platform-keystore-upgrade-triggers.md`）
- 移出条数：1

---

**平台密钥库的后置评估（何时升级 + 四端差异是否导致平台分支）** → 「后置」落成可判定的兑现物三件：① **四端能力矩阵**（Android / iOS / 桌面 / Web × 有无 OS 级凭据机制 · Godot 有无内置绑定 · `user://` 实际落点 · 消掉哪几条已登记残余风险 · 升级后新增坏路径 · 边际成本），读出「收益集中在移动双端且只覆盖备份提取一条半，root / 越狱消不掉」与「桌面 / Web 收益为零而非小」两条结论；② **升级触发条件穷举五条 T1–T5**（后端 `auth.md` §4 rotation / 吊销语义被改写 · 出现第二份落盘鉴权材料 · 首次为移动端引入任何自有原生插件 · 出现一例经确认的凭据泄漏工单 >0 即触发 · 渠道 / 合规以条款形式要求），命中即从后置项转为**必须在当次同批裁决**的工作项（可裁决为「仍不升级」，但必须给出结论、不得再记为后置），配**四条明确非触发**（「有空了」· root 占比统计 · 竞品做了 · 「安全总是好的」）；③ **不引入平台分支**——判据是「这一端有没有可用的凭据存储实现」的运行期一次探测，不是「我在哪个平台」；明文实现是四端共同缺省、不被移除，移动双端在插件可用时替换；不碰条件编译清单。配套：现在不预留 `ICredentialStore` 抽象；升级真发生时的落地形态五条一并写下（含 iOS 必须显式选不随备份 / 不随 iCloud 同步的可访问性、必须明写 Keychain 条目卸载后存活）。（`systems/services/account-service.md`「refresh token 的持有与失效」；`decisions/ADR-0080-refresh-token-client-custody.md` 加一行回链；后端 `backend-design-documents/contracts/auth.md` §4 加一条只回链不复述的下游依赖登记）

> **未答定的部分：** 矩阵中三项平台能力**事实**（Godot 4.7 有无内置安全存储绑定 · Web 导出 `user://` 的持久化后端 · Android Keystore 密钥失效的具体异常与触发面）仍待实测，已并入 `open-questions/05-service-contracts.md` 既有的「`.csproj` 生成后实测」批次，未随本条移出。它们是事实待查，不影响上述三件交付物的机制形状。

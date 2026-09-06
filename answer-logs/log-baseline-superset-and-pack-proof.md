# Answer log baseline-superset-and-pack-proof

- 日期：2026-09-06
- 来源：`inbox/solution-draft-baseline-superset-and-pack-proof.md`（→ `handoffs/2026-09-06-baseline-superset-and-pack-proof.md`；跨库成对，后端半见 `backend-design-documents/handoffs/2026-09-06-baseline-superset-and-pack-proof.md`）
- 移出条数：2

**更高版本客户端的随包基线内容集，是否恒为更低版本基线的超集（= 客户端发版能否删除随包内容条目；登记在 `open-questions/cross-boundary.md`「待承接」）** → 已答定，整条移出。**纪律定为：客户端发版对随包基线只增不删——跨发版的基线 `Id` 集合单调不减**，故更高版本基线恒为更低版本基线的 **`Id` 层超集**（超集只在 `Id` 集合层成立，字段值与 `ContentEnabled` 不承诺跨版本不变）。改名 = 删 + 增同禁；剧本类型不开删除例外。退役按类型三分（抽取池成员永久禁用 / 结构类型只演进字段值 / 合规级掏空——`zh` 留中性句、`Artwork` 置空并同版删贴图资产；命中结构性恒启用类型不置 `ContentEnabled = false`）。机械闸 = 基线快照归档步比对上一版 `Id` 集（「上一版」按 semver 版本序），缺失即非零退出；「快照可枚举 `Id` 集」立为快照形态硬要求。**但超集成立不把打包闸简化为「只跑最新」**——存在性判据在最旧在架基线上最严 + 值敏感断言依赖各基线取值，逐基线各跑定为长期形态，`ADR-0141` 后果句与备选方案句随之订正；对侧 C6 前提句与 `backend-design-documents/handoffs/2026-09-03-content-delivery-ops.md` 同句成对订正。（归档去向：`systems/services/content-service.md`「内容发版纪律」节、`decisions/ADR-0141-overlay-packer-proof-and-baseline-snapshot.md`）

**产包证明是否增设「按类型的条目计数」一格（登记在 `open-questions/cross-boundary.md`「待承接」）** → 已答定，整条移出。**维持不增设（不 emit、不进字段集），但 dormant 形态现在预写进产包证明节**：字段名 `entryCountsByType` · 键 = `Id` 首段前缀 · 值 = 合并后 enabled 数（抽取池口径）· 仅 flags 适用类型 · 按被跑基线逐份；计数由既有逐基线 `LoadAll()` 顺手产出，零新增校验路径。**启用与对侧 A4' 池规模缩放同批**（任一侧未落另一侧不启用）；对侧同批定死读数面（矩阵内最小池 · 未知前缀兜底 20 · 阈值 max(20, 5%×池)· flags 发布不重取）与采纳触发（季度 ≥ 2 次合法摩擦 / 最小池 > 400，触发者 = 后端运维），登记于 `backend-design-documents/operations/content-delivery-ops.md`。（归档去向：`systems/services/content-service.md`「打包工具的两项产出」节 dormant 附注；对侧落点见上）

**方向性记录（不属移出，亦不新登记）**：「2.0 式内容集重启」若发生须连带存档迁移 / 清档的产品级裁决并重开本纪律——记录在本次 handoff 的 Notes，不进待答清单。

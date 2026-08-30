# Answer log client-flag-cache-and-binary-overlay

- 日期：2026-08-30
- 来源：`inbox/archive/solution-draft-client-flag-cache-and-binary-overlay.md` → `handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md`
- 移出条数：2

## 逐条

**二进制资产是否可经 overlay / blob 通道下发** → **答：不开放。** 二进制资产不经 overlay / blob 通道下发，换图 / 加图随版本发布；`Artwork`（以及同小节的全部资产引用格）的指向恒落在随包基线内已存在的资产，overlay 能做的只有改指到另一张已随包的资产或置空（置空 → ViewModel 占位回落）。四条理由：撞 `ADR-0120` 的直接资源引用形态（`user://` 的裸资产不是导入产物，要引用只能退回已否决的路径字符串 + 运行时加载）· overlay 的收益边界里没有它（改图不是止血手段，止血手段是 flags 秒关）· 连锁推翻「不做字节级断点续传」的 KB 级前提 · 美术是路线末段、资产替换与发版同节奏。配套两道处置：打包工具遇非 `.tres` 不产出包（运维形态归对侧）+ 客户端跳过并汇总一行 `PushWarning`。可撤销的代价清单落 `art/visuals/_index.md`。（归档去向：`systems/common-properties.md`「内容共有字段 `Artwork`」· `systems/services/content-service.md`「增量下载：文件级事务」· `art/visuals/_index.md` · `decisions/ADR-0120-content-artwork-and-enemy-lines.md` 后果第 4 条）

**flags 是否落客户端本地缓存（跨边界闭合的强制检查项）** → **答：落——本就已定案，本次是对账 + 补落盘细节。** `user://cache/flags.json` 的字段、原子写、跨启动保留、切账号即失效、冷启动内存版本归零早已成文；本次补的是两处真空缺与一处明写：① 加 `schemaVersion`（按 `systems/architecture.md` 的逐份判据，该判据本就点名 `content-service.md` 为落点；版本不认识即整份丢弃，丢弃就是迁移路径）；② **写入时点唯一 = 一批 flags 通过单调闸并被应用之后**，等值 / 更小丢弃、验签失败、拉取失败一律不写；③ 盘上 `flagsVersion` 只进日志与告警上下文、不参与判断、不回填内存版本。另封闭失效语义三条、明确**不设 TTL**、**丢弃 ≠ 删文件**、登出不主动删除。同批关闭对侧那条「归客户端侧裁决」的悬空指针，并纠正其问句里「以支撑离线开局」这一错误前提（客户端启动 pull 是硬阻塞，该路径不存在；真实收益只有「登录成功但 flags 拉取失败」时的降级值）。（归档去向：`systems/services/content-service.md`「flags：`ContentEnabled` 的第三层」）

## 仍留在清单上的

- `open-questions.md`「跨边界闭合（强制检查项）」余下一条（`ComplianceManager` 覆盖面切分）——它是本库自己的取向，不是跨边界缺口。
- `art/visuals/_index.md`「待决问题」余下四条（guide 粒度 · 资产目录划分与完备性校验 · UI 元件是否走 AI 生成 · 境界晋升是否改变外观）不受本次影响。

## 连带

- **ADR 候选一条：「二进制资产不经 overlay / blob 通道下发；`Artwork` 的指向恒落在随包基线内」**，立档归 `/write-adr`；`decisions/_index.md` 本次未改动。
- `ADR-0120` 后果第 4 条同批改写：删掉「已登记为待答项 / 后端库留对侧承接项」这一不准的尾句，改为结论 + 回链 `systems/common-properties.md`，**不指向任何 ADR 编号**。
- `content-service.md`「manifest 契约对位」首句由「服务端只保证三件事」改为回链对侧「服务端保证」小节（该计数是后端把保证重构为 A 组四条之前的残留）。

## 跨边界

本条**成对落笔**，后端半见 `backend-design-documents/handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md` 与 `backend-design-documents/answer-logs/log-client-flag-cache-and-binary-overlay.md`。对侧关闭的是 `contracts/content-manifest.md` Open questions 的两条（blob 是否向二进制开放 · flags 是否落客户端缓存），并新增 `no-cache` 的层次澄清、后端零义务声明、B 组第 7 条的依赖登记与 blob 通道的能力中立声明。**本库无欠账，`open-questions/cross-boundary.md` 的「待承接」不新增条目。**

# Answer log flags-fetch-throttle

- 日期：2026-08-22
- 来源：`inbox/solution-draft-flags-fetch-throttle.md`（`/batch-analyze-new-ideas` 合并 interview 裁决）
- 移出条数：1（部分移出 —— 见下方说明）

- **flags 拉取的频次护栏 —— 服务端版本短时间连续抖动时，客户端是否需要最小拉取间隔，或只在版本增大时拉** → **不设最小拉取间隔；改为「增大即拉」**（等值不拉、更小不拉 + `PushWarning` + 上报一次），配单飞 + 尾随一次（尾随以「本次拉回版本 > 拉取前内存值」显式封顶）、失败路径**闸门式**指数退避（1 s · ×2 · cap 60 s · 无放弃阈值 · 无定时器 · 无抖动 · 取服务端等待时间为下界）、验签失败按**单个**版本号记忆（更高版本照常重试）、内存 `FlagsVersion` 冷启动一律归零。客户端由此开始依赖契约条款「`flagsVersion` 单调递增」，失败症状已明写并回链后端契约。（归档去向：`systems/services/content-service.md`、`systems/balance.md`；后端承接项：`backend-design-documents/contracts/content-manifest.md`）

**部分移出说明：** 主体结论已答定并移出，但**两项以 `[采纳推荐 — 待复核]` 形态仍留在待答清单**（`open-questions/05-service-contracts.md`），未随本批移出：① 退避上限（cap）取值 = 60 s；② 观测到更小版本的告警去重口径 = 上报侧本会话一次。两项均已按推荐落笔于 `balance.md` / `content-service.md`，等待用户复核确认。

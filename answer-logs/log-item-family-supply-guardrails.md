# Answer log item-family-supply-guardrails

- 日期：2026-09-10
- 来源：`inbox/solution-draft-item-family-supply-guardrails.md`（经 `handoffs/2026-09-10-item-family-supply-guardrails.md` 提炼）
- 移出条数：**1**

**道具整体的获取频率、库存深度与置换对价** → 其余道具族的三格口径由两条判据塌缩成三件具体口径：① 战斗外可写 key 收窄为白名单 `{ LifeSpan }`（加载期校验 `I-13`，产货币 / `ManaLimit` 的法宝一律 `PushError`，方向可逆）；② 「一个族需要独立供给护栏，当且仅当其产出进入某条已被反推封账的预算线」——战斗内八原语的六族与战斗外 `CodexElements` / `Stats` 两族一条都不进账，故不需要第四套口径。据此落笔的三件口径是：**商店逐族库存深度 3 / 2 / 1 / 1 / 0（Σ 7）· 事件侧法宝产出 ≈ 1.5 件 / 完整轮回（每条 `Count == 1`，另加软校验 `X-1`）· 置换对价（法宝置换 ≈ 2 次 / 完整轮回并计入「失去能力」上层 ≈ 1.0 的分子 · 法宝逐档启用条目数 ≥ 2 · barter 对价按档差 `产出档 ≤ 支付档 + 1` 且 ≤ 1 条 / 店）**。`R_item,c` 的收口旋钮取「按实际可供给重填分账」（`R_item,c` = 34 / 39 / 53 · `R_event,c` = 66 / 77 / 264，Σ 恒等 ⇒ λ 与 21 格 `lifeSpanCost` 定价表零改动），回代式的 `P` 同批补一层 `RarityTier` 权重条件概率。（归档去向：`systems/character-profile/item/_index.md` · `systems/adventure-event/exchange/_index.md` · `systems/adventure-event/exchange/common-properties.md` · `systems/balance.md` · `systems/player-profile/player-power/_index.md` · `content/_index.md`）

**仍留在待答清单的部分：**

- 回寿三档的绝对点数（50 / 100 / 200）与三个 ⚠ 标定假设（败率 20% · `E[道念差]` · 购买转化率 0.7）仍待实测校准，第 6 节的全部回代数字随它们重算 —— 已在既有的延后内容分片与 λ 输入表登记，本次不重复立项。
- `ExchangePoolMargin` / `K` 取值后须复核逐族库存深度在闸 ① 上的余量；「一次轮回预期获得几条神通」答定后须复核 `CharacterPower` 族深度 ≤ 1（现按「池只有 4 条」反推的硬下限，不是按供给目标反推）。
- 法宝置换在上层 ≈ 1.0 合计中占多少**份额**未定（口径结构已定：计入上层分子、不自持分母），落 `systems/character-profile/item/_index.md` 的待决问题。
- `ItemData` 的种类目录本身仍未设计；本次给的是供给口径、不是目录。

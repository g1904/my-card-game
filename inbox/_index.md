# 收件箱（inbox）

未整理的想法草稿的暂存区。**顶层只放在办的草稿；已被 `/analyze-new-ideas` 提炼过的一律移入 `archive/`。**

## 两层结构

| 位置 | 含义 | 谁写入 |
|------|------|--------|
| `inbox/*.md`（顶层） | **在办**：尚未提炼进 `handoffs/` 与主题文档的草稿。 | 用户手写；`/provide-solution-draft` |
| `inbox/archive/*.md` | **已提炼**：已产出对应 `handoffs/<date>-<slug>.md`（`status: distilled`）的草稿，只作溯源留存。 | `/analyze-new-ideas` 处理完毕后移入 |
| `_TEMPLATE.md` | 新建草稿的空模板，不是在办条目。 | — |

判据只有一条：**这份草稿有没有对应的 distilled handoff**。有 → `archive/`；没有 → 留在顶层。

## 两类草稿

- `draft-<suffix>.md` —— 手写的零散想法。**`<suffix>` = `MMDD` + 序列字母，从 `a` 起，同日依次 `a` · `b` · `c` …**（例：`draft-0816a.md` · `draft-0816b.md`）。
  **当天第一份也带 `a`，不写裸 `draft-MMDD.md`。** 序列位恒定存在，`ls` 与 `log-*` 后缀才能整齐排序、一眼看出同日批次的先后；裸日期与带字母混排时，同日第一份会脱离它自己的序列。
  归档区 `archive/` 里 08-10 之前的裸日期命名是这条约定成文之前的历史，**不追溯重命名**。
- `solution-draft-<slug>.md` —— `/provide-solution-draft` 针对某个待答问题产出的**提案式**方案草稿。它有自己的 front-matter `status` 生命周期：`awaiting-review`（待人工评审）→ `reviewed` / `decided`（已裁决，可喂给 `/analyze-new-ideas`）→ `distilled`（已提炼，移入 `archive/`）。

## 在办清单

| 文件 | status | 说明 |
|------|--------|------|
| `solution-draft-future-event-generation-weighting.md` | awaiting-review | `future-event-service` 的生成 / 加权运算形态：类型修正 = **乘性系数**（Travel 外四类恒 `> 0`）· 十步管线 · 三层叠加顺序是伪问题（RNG 是消费者，location 与 arc 皆乘性可交换）· 多 arc **权重相乘 / 白名单非空者取并** · 批次规模 N 走**按篇章分格的权重表**且 `k` 是其副产品 · 新增 `SelectionWeightGrade` 三档补上「权重不存在于任何字段」这个空格。**4 项取向已于 08-22 批量评审全部裁决**。评审后 `/analyze-new-ideas` |
| `solution-draft-event-outcome-spec-fields.md` | awaiting-review | `EventOutcomeSpec` 的内部字段面：复用 `ProfileChangeSpec` 两侧 · **三列开放九列恒空** · 经验失败折算在物化组装时完成 · 模板侧五格 + `OutcomeRule` 三种。连带**核实并推翻「阻于效果关键字体系」这处误挂**（战斗效果原语与事件产出 element 作用面不相交）。**4 项取向已全部裁决**（含承重项「Explore 壳的 `OutcomeSpec` 取真身模板」）。评审后 `/analyze-new-ideas` |
| `solution-draft-priority-elevation-conditions.md` | awaiting-review | `Priority = 1` 的抬升判据（三条与门子判据取代清单）· 清单闭合为配额闸门 + 开局构筑（**收窄为新角色首批**）+ **Finale（已裁定抬升）** · 同批多 `1` 档在当前伪码下结构上不可达故不新增收窄规则。**3 项取向已全部裁决**。⚠ 连带：「满级后 Finale 恒进候选池、不参与类型加权」须带进生成 / 加权那份。评审后 `/analyze-new-ideas` |
| `solution-draft-remaining-event-decision-points.md` | awaiting-review | 非战斗四类的事件内决策点清单（`R1`/`R2`/`X1`/`X2`/`X3` + Explore、Travel 两条「无」）· 「非战斗类决策点不触发第二次写入」口径 · 零结构增量。揪出 **Research 槽「已选未提交」无承载格**（已裁定不落存档、不加格 ⇒ 置换 / 禁用候选另找落点）。**3 项取向已全部裁决**。评审后 `/analyze-new-ideas` |
| `solution-draft-combat-runtime-counter-persistence.md` | awaiting-review | 战斗内运行态计数器的 `ActiveCombat` 字段形态；**主体已在 `combat-service.md` 落定（已裁定视为定案）**，本稿补 `counters` 键约定（`<abilityId>[#<子名>]` + 悬空校验）、三条读档校验、法宝 `Charges` 即时写的对称性。**3 项取向已全部裁决**。⚠ 连带回填：`open-questions/01-combat.md` · `power/_index.md` · `player-item/_index.md` 三处登记落后于主题文档。评审后 `/analyze-new-ideas` |
| `solution-draft-enemy-pool-chapter-scoping.md` | awaiting-review | 敌人取池第三层「篇章框定」的承载字段：`EnemyData.ChapterScope : int[]`（照搬 `PlotArcData` 同名字段，空 = 不限），空池校验扩到 `(EventType × 篇章)` 九组合。**跨分片合并裁决：`AdventureEventData` 同样新增同名同形字段**（两处是同一个空格）。**3 项取向已全部裁决**。评审后 `/analyze-new-ideas` |
| `solution-draft-band-boundary-config-placement.md` | awaiting-review | `±2` 赋级带边界的配置落点：**平衡资源**（本库无「服务配置」这一层，7 处先例零反例），且须与带内分布权重表同住一份 `EnemyLevelingData`；附五条加载期校验与两条**显式否定**（作废 08-06b 那条随意图移除而失效的一致性检查）。**3 项轻级取向已按推荐裁定（待复核）**。评审后 `/analyze-new-ideas` |
| `solution-draft-echo-validation-scope.md` | awaiting-review | 上行整键回声校验的适用面（客户端半）：受约束顶层键分两层持有（path 权威留后端）· 回声值取自 pull 权威快照 · **回声路径不参与钳制 / 补默认 / 归一化** · push 前自检 = **强制回声改写 + `PushError`**。**跨库**，与 `backend-design-documents/inbox/` 同名草稿**成对采纳**。**3 项取向已全部裁决**（含批准松动 `account-info.md` 的「老档补默认值」）。⚠ 前置：后端 `solution-draft-bundle-grant-ordinal-authority.md` 须先提炼进契约——回声规则本体至今未落笔，本库正文的回链当前指向不存在的内容。评审后 `/analyze-new-ideas` |
| `solution-draft-refresh-token-client-storage.md` | awaiting-review | refresh token 的客户端持有形态：`user://cache/refresh-token.json` 独立一份、**带** `schemaVersion`（与 `device-id.json` 刻意不同）· 字段 `{schemaVersion, accountId, refreshToken}`、不存过期时刻 · 失效路径穷举六条 · 落盘失败处置与 `deviceId` 刻意不同（判据 = 症状是否自愈）· 归属 `AuthManager` 私有。**3 项取向已全部裁决**，其中**已裁定落地启动期静默续期** ⇒ 须同批改写 `ux/screen-flow.md`「登录屏 = 应用首屏」，并登记「静默续期绕过强更闸门」这条新暴露的口子。评审后 `/analyze-new-ideas` |
| `solution-draft-flags-fetch-throttle.md` | awaiting-review | flags 拉取的频次护栏：「不同即拉」→「**增大即拉**」· **明确不设最小拉取间隔**（节流会把秒关延迟抬到间隔级）· 单飞 + 尾随一次 · 护栏落在失败路径（退避 1s·×2 / cap 60s / 无放弃阈值）· 验签失败不走网络退避。API 零改动，张力：无。**2 项轻级取向已按推荐裁定（待复核）**。评审后 `/analyze-new-ideas` |

清空即为「无在办草稿」。已提炼草稿 → handoff 的对应关系见 `archive/_index.md`。

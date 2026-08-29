# ADR-0069 — 子需求的签核继承父 FR；唯一例外是 Open-questions 闸

- **状态：** Accepted
- **日期：** 2026-08-19
- **来源：** handoffs/2026-08-19-breakdown-granularity-and-signoff.md

## 背景

`/breakdown-requirements` 把一份父 FR 拆成一个文件夹的可执行子需求。子需求要不要各自签核？逐个签核意味着把同一批验收标准签第二遍；完全继承则会让「拆解时新发现的疑问」被父 FR 的签核状态掩盖。

## 决策

**签核语义：父 FR 签核即覆盖其子需求**——子需求继承父 FR 的**签核状态**，不再逐个签核。

**唯一例外 —— Open-questions 闸：`## Open questions` 非空的子需求一律产出为 `draft`。**

父 FR 用 **`signed-off-as` 一格**记住迁入 `broken-down` 前的签核状态。

状态词汇与覆盖核对 → `requirements/_index.md`。

## 理由

父 FR 的验收标准就是子需求验收标准的并集，签核父 FR 已经是对全部内容的确认。逐个签核不增加信息，只增加仪式。

而 Open-questions 闸是必需的，因为它捕捉的正是**签核时不存在的信息**：拆解过程中发现的、父 FR 没能回答的疑问。这些疑问不应被继承来的 `ready` 掩盖。

`signed-off-as` 的存在是因为父 FR 迁入 `broken-down` 后原状态被覆盖，而子需求需要知道它继承的是什么。

## 备选方案

- **逐个签核子需求** — 否决：等于把同一批验收标准签第二遍。
- **按 `status` 字面值判定继承** — 否决：增量拆解时（父 FR 已是 `broken-down`）三条规则一条都不匹配。

## 后果

- 本条的落点是 `requirements/_index.md`，不在 `vision/ systems/ art/ ux/` 四类主题文档内——它是流程决定而非设计决定。
- 增量拆解（给已 `broken-down` 的父 FR 补子需求）走同一套规则，读 `signed-off-as` 而非 `status`。
- 批量拆解时逐条覆盖核对仍由 orchestrator 承担，本条不放松那道检查。

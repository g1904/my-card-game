# Answer log breakdown-granularity-and-signoff

- 日期：2026-08-19
- 来源：`inbox/solution-draft-breakdown-granularity-and-signoff.md` → `handoffs/2026-08-19-breakdown-granularity-and-signoff.md`
- 移出条数：**1**

## 已答定（从 open-questions/05-service-contracts.md 移出）

**`/breakdown-requirements` 的两项形态确认（① 子需求是否需要用户逐个签核；② 拆解粒度判据的上下界，含是否允许纯数据资源型子需求）** → 两项均已定案，无残留：

- **① 签核语义** —— 取「**继承 + Open-questions 例外闸**」：子需求继承父 FR 的**签核状态**，唯一例外是 `## Open questions` 非空的子需求一律产出为 `draft`。理由：拆解不新增验收标准 + 覆盖核对强制 ⇒ 签核的实质对象（标准集合）在拆解前后同一，逐个签核等于签第二遍；例外闸是父 FR 模板同一条规则下沉一层，可机械判定，并消掉「台账 `ready`、进 `/blueprint` 被当未签核拦下」那处不一致。配套：规则的判定对象是**签核状态**而非 `status` 字面值（增量拆解时父 FR 恒为 `broken-down`），故 `broken-down` 只由 `ready` / `draft` 迁入，父 FR frontmatter 新增 `signed-off-as` 一格记住迁入前的签核状态。切分本身与 `depends-on` 依赖链**不新增状态词**，作为拆解结构的评审面由技能报告点名请用户过一眼（否决 `structure-approved`）。
- **② 拆解粒度** —— 落成一张**软上界（U1~U6）/ 软下界（L1~L4）判据卡**：超界或触发下界不硬拒，但须在拆解 `_index.md` 写一行理由。U3 口径定为「涉及的服务数 ≤ 1」；U6 起算点定为「该子需求所属系统的首个可交互屏」；软下界取 `L1 ∨ L2` 触发、`L3` / `L4` 降为辅助信号；U2 / U6 标注为待校准初值，前三次 `breakdown → blueprint → implement` 跑通后回看。**纯数据资源型子需求：允许独立成条**，须过三条闸（`XxxData : Resource` + ≥1 真实 `.tres` ∧ 经 DataRegistry 启动期加载并可按 `Id` 查到 ∧ ≥1 条负向验收标准报出坏 id 与路径），不过闸即并入消费方；它不违反「按可观察行为切」是因为**启动期校验报错本身就是可观察行为**。
- **判据的归属** —— 阈值与准入闸归设计库（`requirements/_index.md`），切法与顺序归技能；判据是「用户的评审面在哪一侧」，这句写进 `decisions/ADR-0005`。不为 `.claude` 开任何具名例外，阈值表不进技能文本。
- **两库对称** —— 后端库落一份同构判据（指标不同、互不复述、互相回链），见 `backend-design-documents/requirements/_index.md`。

（归档去向：`requirements/_index.md`「两层结构」与新增的「拆解粒度判据」为权威；`decisions/ADR-0005-knowledge-thin-reference-layer.md` 载归属判据；模板形态在 `requirements/_TEMPLATE.md` / `_TEMPLATE-sub.md`；后端半在 `backend-design-documents/requirements/_index.md`。）

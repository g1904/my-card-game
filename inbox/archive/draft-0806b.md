# 收件箱 — 草稿

- more on eventOptions this session.
- 图鉴族第六本已定案（「去过即记」） = LocationCodex 记「它通向哪些地域」，玩家可跨轮回重建整张 locationMap。这是设计意图。
- skipCost is too complex to be involved. Let's remove the conecpt of 'skipCost' all together.
- let's remove the option of skipping as well. After the removal, choosing another event option is basically skipping the other ones since the eventoptions will be refreshed after the selection anyway.
- 付不起必做项 selectCost 时的终态 = 支付 selectCost 是可推进行为，支付后判定状态，判负进入失败流程。
- eventPriority 与 ifMandatory 的叠加规则 = ifMandatory concept is removed along with skipping.
- eventPriority 的取值域与置位方 = 两档（0 / 1）由 future-event-service 赋值，PlotManager 不可改变。

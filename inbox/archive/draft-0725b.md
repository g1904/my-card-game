# 收件箱 — 草稿

- lifeSpan 到元婴阶段 +500，不过这时候游戏已经结束了，只是最后数值更新后存档。
- AdventureEvent common-properties:
  - element, selectCost 选择成本
  - element, eventType 类型（combat/explore/research, etc)
  - element, ifMandatory 是否强制（不可跳过）
  - element, skipCost 跳过成本
  - method, eventStart(...);
  - method, eventEnd(...);
- PlayerPower common-properties:
  - element, status: 状态，启用/禁用
- 这些类目前只携带了编码，前端要用的描述（充血模型）字段是否应该包括进去，还是应该为充血模型单独创建一个对应的类，供前端展示使用？
- PlayerPower 这种更改全局设定的效果，比如可以让玩家看见角色隐藏属性数值，如何系统性的定制？而不是在每个受影响的层去添加定制条件？感觉不够优雅，帮我想个优雅的解决方案，能够系统性地实现此类效果。
- adventure-plot-service 是隶属于 future-event-service 的，future-event-service 会调用 adventure-plot-service 的接口去计算 eventOptions 传给 characterProfile。
- 最后，帮我分析当前架构是否合理，有何缺失的逻辑尚未完成闭环？

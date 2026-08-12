# 收件箱 — 草稿

let's work on 「本轮回禁用」与置换型剥夺 this session.
- CharacterPower and PlayerPower are like static ability in mtg.
- CharacterItem and PlayerItem are like activated ability in mtg.
- New field in characterProfile = disabledAbility, tracking all disabled power and item, including their corresponding duration (event or chapter or cycle).
- 被禁用的在开局不如入场，战斗中立即生效，对玩家可见。
- 「本轮回禁用」与置换型剥夺 = 排除已有 and 同稀有度 and 可看到换来的是什么再决定 and 拒绝置换无代价 and 同样对'神通''法宝'‘古宝'有效 （但只会同类型置换）。
- ProfileChangeSpec 表达三类移除的 element 形态 = 置换是 transactional 的 （参考 provide-solution-draft skill 决定是一条 update 还是 delete + insert 两条）。置换和禁用都可以出现在 selectCost。
- PushWarning 逐条列举是否要在事件 outcome 侧补一处对称落点 = 参考 provide-solution-draft skill 决定如何实现。
- 账号级统计计数的容器形态 = 落成 PlayerStatistics 类
- 首批统计项清单 = [TotalCyclesCompleted, TotalCyclesDefeated]
- 宽松同步口径的具体形态是什么？参考 provide-solution-draft skill 决定.
- Dont change anything yet. Rewrite this draft first similar to provide-solution-draft skill output.

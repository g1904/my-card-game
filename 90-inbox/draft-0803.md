# 收件箱 — 草稿

- 手牌达到上限时如何处理 = 满手时抽牌是抽不进，「加入手牌」类效果同理。
- 重新定义字典：playerPower = 法则; playerItem = 古宝; characterPower = 神通; characterItem = 法宝;
- 触发式效果的载体形态 = 牌上的触发器 / 场上的持续状态 / CharacterPower / etc 都可能承载触发式效果。
- 引入 战场（battlefield）概念，battlefield 里会记录所有场上的准确数据，有哪些卡牌在生效等，同时引入 battlefieldManager 和 stackManager 类。
- 多个削减效果同时在栈上时「道念下限 0」 = 每次结算时截断。
- 敌人赋级的等级差上界 = 最多是高一个大境界的初期。比如 炼气期最高遇到筑基初期。
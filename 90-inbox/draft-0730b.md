# 收件箱 — 草稿

- let's discuss the combat mechanic this session.
- intent is only hidden when enemy level is much higher than the current character (Level: 1 to 13 in chapter 1; 1 to 4 in chapter 2; 1 to 4 in chapter 3).
- much higher in chapter 1 means enemy level - character level > 3. For chapter 2 and 3, it means one level higher.
- level system: 炼气期 1 层到 13 层；筑基 初期，中期，后期，巅峰；金丹 初期，中期，后期，巅峰。chapter 结束进阶后皆为初期，包括最后元婴也是初期。
- power 译为 能力。
- 某些能力或者道具可以授予窥视意图。
- combat-service 中与 enemyManager 平级的还需要有个 characterManager 来管理玩家对战信息。
- enemyManager 和 characterManager 有很多共用接口定义，但 enemyManager 有代理操作的部分，比如行为选择。而 characterManager 则监听玩家操作。
- enemyManager 中无需再细分职能。
- practice 和 finale 缺失会用到 enemyManager 和 characterManager，相当于 combat 的变体。
- 战斗过程中不落存档点，selectCost 不回滚。
- 同一事件重试上限10次 <10，篇章重试总数上限30次 <30。重试过多则强制进入 defeat。
- manaLimit 的成长 属于 事件 cost / reward 的范畴。
- 对战中每回合开始自动恢复到上限。
- for all enemies, I plan to have a collection like a Pokédex that tracks info on what player has encountered.
- further combat details will have another session.
- regarding 玩家凭什么做出牌决策？, this is a good question. I have stated what I had in mind so far. Since it's the core experience of the game (战斗手感的承重问题), it's important to address this question well and make the game unique.
- First, understand. Next, criticize. Then, propose (if there is a better idea or solution). Finally, after discussion and my approval, modify the design files.


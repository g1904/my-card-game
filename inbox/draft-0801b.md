# 收件箱 — 草稿

- DeckManager 降为参战方子组件与「不设第三级」的措辞冲突 -> New decision, there might be more levels of abstractions beyond service and manager. For now, let's define the first level to be service, the second level to be manager, and the third level to be module. Therefore, deckmanager is refactored into deckModule. And for other third level abstractions naming, use the term 'module'. For future forth level, use the term 'processor'; for future fifth level, use the term 'handler'.
- 「仅类别」与「完全无信息」的分界值。 -> ch1: 同阶 0<diff<3 仅类别, 同阶 diff>3 无信息。ch2: 同阶 diff=1 仅类别，同阶 diff=2 无信息。ch3: 同阶 diff=1 仅类别，同阶 diff=2 无信息。越阶等同无信息。
- 敌人等级的来源 -> there will be smth like an EnemyTemplate collection contains static data of enemies similar to the EnemyCodex, which contains a brief description of all encountered enemies. future-event-service will pull out a template then enrich/modify the template and assign one to the event.
- 全局等级序的具体基数。 = 「炼气 1–13 / 筑基 14–17 / 金丹 18–21 / 元婴 22」枚举值，例：level=1,desc=炼气一层;level=14,desc=筑基初期;etc. baseMomentum=「炼气 1–12,15 / 筑基 20,24,32 / 金丹 45,55,75 / 元婴 100」
- 敌人图鉴的记录深度与粒度 = 人物背景，功法简介，运作方式，特点与弱点，和 EnemyTemplate 中的样本卡组的关键卡牌。一次遭遇，全文案解锁。
- 战斗的终止条件 = ends after 10 turns (each side takes 5 turns for one combat) 
- Extends the gameplay length for each chapter: ch1=30-40mins; ch2=35-45mins; ch3=45-55mins; And those time are for experienced players knowing the strategies.
- other than enemyCodex, there will also be characterPowerCodex, playerPowerCodex, characterItemCodex, and playerItemCodex.
- Monetization: with premium bundle purchase, one random playerPower, two random playerItems, increase ch2 retry to 9 and ch3 retry to 3.
- 道念的产出途径: 卡牌。可以互相削减。道念不会小于0。起始道念参考 baseMomentum
- refactor life into lifeTotal. lifeTotal 归 0 的语义 = defeated (cycle level). lifeTotal 的意思是这个角色的生命值，通过 event 恢复。
- 胜利侧是否也读道念差，道念差影响奖励厚度。

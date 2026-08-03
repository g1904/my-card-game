# 收件箱 — 草稿

已分流至 `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。

- .claude should be all about config are engineering-related rules and reusable skills to push forward the project. all the design related knowledge and details should be in design branches and only be referenced and lightly described in .claude content. The goal of .claude is to help me implement my ideas while the core of my visions lives inside design. This should help draw the lines of 主从关系 in open qeustions.
- for combat-service, intentManager is only a part of the enemyManager, and intent is usually not revealed to the player. I will have a dedicated session for each type of adventureEvent in the future.
- 寿元红字倒数的呈现细节 = 静态标注于 EventOption 选择界面。
- create a new skill 'breakdown-requirements' that take one derive-requirements feature requirement draft output as input and breakdown the draft into a folder with smaller executable requirements that can be feed into 'blueprint' skill. This should close the loop of the design to code process. 
- after the above, reorganize the open-questions, the enrichment of game content should be sit aside and the next focus should be details of each system mechanics such as combat and eventOptions generation process, etc.

# 收件箱 — 草稿

- 寿元 lifespan is a count, the initial lifespan of 炼气 is 100, reaching 筑基 +100，reaching 金丹 +300.
- 寿元 is hidden initially, when below <10%, it's shown on screen, and when it reaches 0, the character is defeated.
- there is a service that produces event options based on the current characterProfile. Events are NOT linked to each other — the next step is computed at runtime, not authored as graph edges.
- to make service more clear, let's refactor adventurePlot into adventure-plot-service, introduce future-event-service, and refactor run-manager into life-cycle-service.
- eventOptions is a set of available AdventureEvent that player can select which one to progress the game.
- After each event done, a new set of eventOptions is calculated via future-event-service for the player to choose again.
- addressing character-profile 结构不一致: deck and item are folder to include content designs (starter decks, item designs) in addition to the rulings in the future. life, currency and mana are systematic resource so they are md files for now since I expect the rules are short enough.
- clean up legacy content in the files, only keep the latest design and decisions, etc.
- dont mention or keep outdated/replaced/legacy content and data, always rewrite and replace the data with the newest data.
- The project is version controlled via github, legacy files or content can be manually retrieved back if I want to. Keep them in files will only make documents bloated.

# 收件箱 — 草稿

- let's work on some reconstructions on the game-design-documents branch.
- create an 'adventure-event' folder to replace the current adventure-event-combat.md 
  - with 'combat', 'finale', 'mystery', 'practice', 'exchange', 'research', 'explore', 'social', 'travel' each with an individual folder with _index.md and 'common-properties.md', and a 'common-properties.md' inside systems folder as well.
  - mystery is fairly simple, it masks a fixed AdventureEvent rather than making up one on-click.
  - other types of adventure events are quite complex that requires a dedicated folder to hold each variation of the design detail in the future.
  - explore is a new type of adventure event, keyword as '探索秘境'.
  - travel(前往某处地点) is a new type of adventure event that function as a map routing choice (refresh the location of the character)
  - '地域' location is a new abstract concept that frames the eventOptions (which event pool is open at the current place)
- remove shop-rewards.md and relics-jokers.md, replace them with 'player-profile' folder (-> 'player-item', 'player-power', etc. each with dedicated folder with detail index structure. In the future, each player-power design will have an individual Markdown file to describe it.)
- replace map-progression.md with game-progression.md
- replace card-resolution.md and deck-hand.md into 'character-profile' folder with similar structure as 'player-profile', deck, item and etc each with a folder.
- replace energy-economy.md with files inside character-profile 'currency.md', 'life.md', 'mana.md'
- I think now 30-content basically merged into 20-systems, and systems is structured like class concept in java.
- We also need an archietecture.md file inside systems folder that provide a high-level guidance of the system structure (how would the codebase work).
- 'run-manager.md' and 'adventure-plot.md' should be microservices inside the system to provide an api that interacts with character-profile and player-profile.
- Reorganize the above tasks and distribute each group of tasks into agents.
- There should be lots of refactoring that cares about references and usages.
- the .claude content should be updated with this change and game-design-documents will hold the source of truth for both game content and tech structure, the claude knowledge base should reference the files there.

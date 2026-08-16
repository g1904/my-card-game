status: distilled
distilled-to: handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md

# let's address eventOption and AdventureEvent types
- eventOption will usually be 3, and the range is from 1 to 5 per batch.
- selectCost is only a wrapper for 寿元 扣减，I currently can't think of other cost should be included in selectCost. 
- Also dealing with 余额扣减与确保可选 is messy. However, 寿元是强制扣减，which is straightforward. Maybe there's a better way to handle 寿元 adjustment per event.
- After completing one event, a new batch of options is provided (not based on last batch, but based on overall character history, heavily based on pastEvent ofc).

for AdventureEvent types:
* major change to simplify things
* combat / practice / finale all merged into one type 'combat' since they share the same characteristics.
* practice no longer exists, and finale is a special designed type of combat with extra content.
* explore and mystery are merged into one type 'explore' since they share the same characteristics.
* Social and exchange are merged into one type 'exchange' since they share the same characteristics
- Combat should be the more frequent encountered ones, where player fight enemies and gain resources.
- exchange is where player exchange resources for item / cultivationTechnique / etc.
- research is where player adjust / level-up their deck.
- travel is where player choose to change location (is not an always-available option, and only show up for sure if the location is run out of events. And not all travel options are guaranteed to show up even if the location is connected to both in map, randomly choose one option.)
- explore is basically choosing a mystery event where it could be combat / travel / exchange (no research tho).

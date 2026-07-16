# 收件箱 — 草稿

- let's talk about some general ux designs today, and some light touch on development order.
- the first screen will be a login screen with terms and services (an animated loop video similar to live2d style scene)
- soundtrack assets, card art, animations, etc. Pretty much everything art related will be TBA after the design is 90% done.
- so leave those files blank for now, but keep them in a mind during architecture so in the future they can be easily customized.
- my plan of develop is design first top down, then engineering the system, have the system running first, finally come with testing, balancing and art making.
- criticize this plan, propose a better one if there's a big flaw. Since testing and balancing are labor-intensive and art making will cost a fortune, that's why they are in the end phase after a working demo first.
- although this is an offline game, it's preferred to log in via 微信/QQ/email/手机 to save the progress online. And yes, there will be a server to store those data.
- art assets are left blank for now, but as development cycle progress, it's a todo to use or find some generic or free assets just to use for default. Either use existing library/package or ask me to find some from online godot community resources.
- user either login or continue as a guest (游客账号)
- after login, there's the main screen where the first timers should only be able to start from chapter one (炼气), while other chapter options are hidden (to be unlocked later).
- In the main screen, other than being able to switch chapters to start a run, there're following buttons: one for PlayerProfile (status and account info), one for PlayerPower (special powers that be turned on or off), one for achievements (with groups that once a group of achievements reaches 90% auto awards the player), one for settings (audio on/off, etc). 
- I have left the open questions from last session in ./game-design-documents/open-questions.md, it's a new file that needs to be integrated.
- I want open questions that unanswered after each session to be saved in open-questions.md file so that I can pick-up in the next session. Therefore, update the ./.claude content to keep the file in the loop.
- also scan the project, refactor all 'scratch' into 'draft'.
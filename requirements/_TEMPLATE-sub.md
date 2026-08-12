# FR-\<parent\>-\<NN\>-\<subslug\> — \<short title\>

- id: FR-\<parent\>-\<NN\>-\<subslug\>   # e.g. FR-profile-store-revision-cas-01-counter-storage
- parent: FR-\<parent\>                  # 父 FR（本子需求由它拆出）
- date: \<YYYY-MM-DD\>
- service: \<与父 FR 相同\>
- source-docs:                           # 继承父 FR 的来源，不新增
    - systems/\<doc\>.md
- client-facing: \<yes | no\>
- status: ready                           # 继承父 FR 的签核状态：ready | draft → blueprinted | built
- blueprint:
- depends-on:                             # 同一拆解内的其他子需求 id（构建顺序）

## Intent
> _一句话：这一薄切片让系统能做到什么。追溯父 FR，不复述整份文档。_

## Scope
**In scope**
> _本子需求覆盖的具体、可构建行为。小到一次 blueprint 能一口吃下。_

**Out of scope**
> _明确交给兄弟子需求或后续处理的部分（点名是哪个子需求）。_

## Acceptance criteria
> _1 ~ 5 条。每条都必须可验证（请求 → 应答 / 存储状态）。Given/When/Then。_
- [ ] Given \<state\>, when \<request\>, then \<observable result\>.

## Covers (parent criteria)
> _本子需求承担父 FR 的哪几条验收标准（引用其原文或编号）。覆盖核对的依据。_

## Contract touchpoints
> _涉及的端点 / 字段 / 错误码。新字段必须已在 `contracts/` 中定义。_

## Failure & retry semantics
> _本切片在重复请求 / 部分失败 / 超时下的行为。强制。_

## Open questions
> _父 FR 下发的相关问题 + 拆解中新发现的问题。绝不在此杜撰答案。_

## Traceability
- Broken down from: FR-\<parent\>

<!-- 一个子需求 = 一次 blueprint 能一口吃下的薄纵切片，做完后服务仍可部署。 -->

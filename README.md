# backend-production —— 后端发布快照

从 `backend-testing` 提升而来的发布稳定快照。孤儿历史，与 `game-*` 分支线彼此独立。

**这是只读的参考快照** —— 不在此分支上开发；新工作一律在 `backend-feature` 进行，经 `backend-testing` 验证后提升到这里。

## 状态

尚未开工。见 `backend-feature-branch/`（`backend-feature` 分支）与 `backend-design-documents/`（`backend-design` 分支）。

## 流程

```
backend-feature  →  backend-testing  →  backend-production
   (develop)          (verify)             (release)
```

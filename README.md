# backend-feature —— 后端活跃开发

**MyCardGame** 后端的开发分支。孤儿历史，与 `game-*` 分支线彼此独立，从不互相合并。

后端为强制在线的客户端提供云端权威能力：账号鉴权、档案存储、剧本下发、内容分发（CDN）。

## 状态

尚未开工。技术栈与目录结构待定。设计意图见 `backend-design-documents/`（`backend-design` 分支）。

在后端就绪之前，客户端的边界服务（`account-service` / `content-service` / `sync-service`）以**离线 stub** 实现，使整个游戏可先端到端跑起来。

## 流程

```
backend-feature  →  backend-testing  →  backend-production
   (develop)          (verify)             (release)
```

与客户端的 `game-feature → game-testing → game-production` 是**两条独立的提升线**，各自部署、各自回滚。两侧的耦合点只有协议契约，其权威在 `backend-design-documents/`。

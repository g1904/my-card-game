# backend-feature —— 后端活跃开发

**MyCardGame** 后端的开发分支。孤儿历史，与 `game-*` 分支线彼此独立，从不互相合并。

后端为强制在线的客户端提供云端权威能力：账号鉴权、档案存储、内容分发（CDN）。

## 状态

代码尚未开工——本目录目前只有这份 README，工程目录结构待定。

**技术栈与托管形态已落定：** C# / ASP.NET Core · 腾讯云托管容器 · 云数据库 PostgreSQL（单主）· 云 Redis · 云 KMS · CDN。环境实体为两套云上（testing + production）+ 本地 docker-compose 承担 feature。权威在 `backend-design-documents/systems/_index.md` 与 `operations/environments.md`；协议契约六份已成文，见 `backend-design-documents/contracts/`。

在后端就绪之前，客户端的边界服务（`account-service` / `content-service` / `sync-service`）以**离线 stub** 实现，使整个游戏可先端到端跑起来。

## 流程

```
backend-feature  →  backend-testing  →  backend-production
   (develop)          (verify)             (release)
```

与客户端的 `game-feature → game-testing → game-production` 是**两条独立的提升线**，各自部署、各自回滚。两侧的耦合点只有协议契约，其权威在 `backend-design-documents/`。

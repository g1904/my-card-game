# backend-design —— 后端设计意图

**MyCardGame** 后端的设计意图事实来源。孤儿历史，与 `game-*` 分支线彼此独立，从不互相合并。

游戏客户端（Godot 4.7 / .NET）是**强制在线、云端权威**的：进度实时同步云端，本地 `user://` 仅作缓存。本分支承载云端那一侧的设计——账号鉴权、档案存储、剧本下发、内容分发（CDN）、协议契约。

## 为什么与 `game-design` 分开

`game-design` 是**客户端**的设计事实来源。客户端的七个「服务」全部是同一个 Godot 进程内的模块单例，彼此为直接 C# 方法调用；**唯一真实的进程边界是客户端 ↔ 后端**。这条边界两侧的部署节奏、技术栈与发布线都不同，因此文档也分线承载。

跨越这条边界的客户端服务有四个：`account-service`、`content-service`、`sync-service`，以及 `future-event-service` 内部的 `PlotManager`。它们在客户端侧的门面设计见 `game-design-documents/systems/services/`。

## 布局

| 文件 / 文件夹 | 内容 |
|---|---|
| `README.md` | 本文件：分线理由 + 布局导航 |
| `open-questions.md` | 后端侧的跨 session 待答清单 |

其余结构随后端设计展开逐步建立。

## 相关

| 分支 | 本地文件夹 | 内容 |
|------|-----------|------|
| `game-design` | `game-design-documents/` | 客户端设计意图（含客户端侧的边界服务门面） |
| `backend-feature` | `backend-feature-branch/` | 后端活跃开发 |

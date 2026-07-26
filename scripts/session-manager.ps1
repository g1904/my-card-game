# session-manager.ps1 — PowerShell 入口（供在 PowerShell 提示符下直接调用）
#
# 这是给 PowerShell 用户的封装：把全部参数原样转发给底层实现 session-manager-impl.ps1。
# 因此可直接用底层的命名参数（大小写不敏感）：
#   .\.claude\scripts\session-manager.ps1 -save d46cba96              # 收藏（-save 绑定到 -Save）
#   .\.claude\scripts\session-manager.ps1 -save . -Tags 库存审查,待跟进  # 收藏当前会话并打多个标签（逗号分隔）
#   .\.claude\scripts\session-manager.ps1 -saved                      # 列出已收藏
#   .\.claude\scripts\session-manager.ps1 -grep 库存                 # 按关键词搜索
#   .\.claude\scripts\session-manager.ps1                           # 列出全部
#
# 若执行策略拦截脚本运行，改用：
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\.claude\scripts\session-manager.ps1 -saved
#
# Git Bash / 我的 Bash 工具环境下请改用同目录的无扩展名脚本 session-manager（子命令语法）。

& "$PSScriptRoot\session-manager-impl.ps1" @args

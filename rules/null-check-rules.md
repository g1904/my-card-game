# 空值 / 结果校验规则（强制）

在每一次**节点查找**、**资源加载**、**注册表/字典查找**和**存档读取**之后，你都必须在使用结果之前对其进行显式校验。把未经检查的 null/空值向下游传递是难以追踪的崩溃的头号原因。这是把旧后端的“data-check”规则适配到 Godot/C#。

## 四个检查点

1. **节点查找**（`GetNodeOrNull`、`%Unique`、`GetNodesInGroup`）：在解引用之前检查是否为 null / 空。优先使用 `GetNodeOrNull<T>` 而非 `GetNode<T>`，这样缺失的节点是一种已处理的情况，而非引擎错误。
2. **资源加载**（`ResourceLoader.Load`、`GD.Load`、注册表按 id 获取）：在使用前检查加载出的资源非 null 且类型正确。
3. **集合 / 字典查找**（`TryGetValue`、`FirstOrDefault`、索引访问）：在解引用之前确认键/元素存在；对空列表加以防护。
4. **存档读取 / 反序列化**：校验解析出的对象、它的版本以及所引用的内容 id。

## 两种失败语义（择一 —— 绝不静默通过）

- **必需（没有它无法继续）→ 带定位上下文报错退出。**
  ```csharp
  var card = _registry.GetCardOrNull(cardId);
  if (card == null)
  {
      GD.PushError($"[ContentRegistry-GetCard] card not found, id={cardId}");
      throw new InvalidOperationException($"Card not found: {cardId}");
  }
  ```
- **可选（可优雅降级）→ 警告 + 安全默认值，并留下痕迹。**
  ```csharp
  var sfx = GetNodeOrNull<AudioStreamPlayer>("%Sfx");
  if (sfx == null)
  {
      GD.PushWarning("[Combat-PlaySfx] sfx player missing; skipping sound");
      return; // continue without audio
  }
  ```

对缺失情况既不报错也不警告的查找是一处缺陷。每条消息里都要包含一个定位标识符（节点路径、资源 id、存档键）。

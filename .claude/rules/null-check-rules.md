# Null / result-validation rules (mandatory)

After every **node lookup**, **resource load**, **registry/dictionary lookup**, and **save-file read**, you must explicitly validate the result before using it. Passing an unchecked null/empty downstream is the top cause of hard-to-trace crashes. This adapts the old backend "data-check" rule to Godot/C#.

## The four checkpoints

1. **Node lookup** (`GetNodeOrNull`, `%Unique`, `GetNodesInGroup`): check for null / empty before dereferencing. Prefer `GetNodeOrNull<T>` over `GetNode<T>` so a missing node is a handled case, not an engine error.
2. **Resource load** (`ResourceLoader.Load`, `GD.Load`, registry get-by-id): check the loaded resource is non-null and the right type before use.
3. **Collection / dictionary lookup** (`TryGetValue`, `FirstOrDefault`, index access): confirm the key/element exists before dereferencing; guard empty lists.
4. **Save-file read / deserialize**: validate the parsed object, its version, and referenced content ids.

## Two failure semantics (pick one — never silently pass)

- **Required (can't continue without it) → error out with locating context.**
  ```csharp
  var card = _registry.GetCardOrNull(cardId);
  if (card == null)
  {
      GD.PushError($"[DataRegistry-GetCard] card not found, id={cardId}");
      throw new InvalidOperationException($"Card not found: {cardId}");
  }
  ```
- **Optional (can degrade gracefully) → warn + safe default, and leave a trace.**
  ```csharp
  var sfx = GetNodeOrNull<AudioStreamPlayer>("%Sfx");
  if (sfx == null)
  {
      GD.PushWarning("[Combat-PlaySfx] sfx player missing; skipping sound");
      return; // continue without audio
  }
  ```

A lookup that neither errors nor warns on the missing case is a defect. Include a locating identifier (node path, resource id, save key) in every message.

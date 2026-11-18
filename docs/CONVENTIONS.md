# Conventions

- `--!strict` at the top of every `.luau` file; typed signatures on every public function.
- One responsibility per ModuleScript; keep files under ~200 lines (older big files like `SenService` and `Build` are known exceptions; don't add to them, split instead).
- **Pure logic goes in modules Lune can test; engine glue (Instances, Lighting, remotes) stays thin** and is checked by playtest.
- Server-authoritative: phase, clock, clues, items, who is taken, endings are server state. The server validates every remote (argument types, ranges, who is allowed, rate limits). The client does UI, camcorder view and effects only.
- Find world objects with CollectionService tags (constants in `src/shared/Tags.luau`), never `workspace.Foo.Bar` paths. Rojo mounts `src/server` as `ServerScriptService.Server`.
- Remotes are created only through `Shared.Remotes`.
- Services and controllers return a table with `Init()` then `Start()`; the boot scripts load every module in `Services/` / `Controllers/`.
- Naming: modules and types `PascalCase`, functions and variables `camelCase`, constants in `Config`. Prefab names match `^[A-Za-z][A-Za-z0-9_]*$` and are unique.
- No magic numbers (use `Config`); no hard-coded player text (use `Content/`). Keep Vietnamese diacritics.
- Base Lighting is owned only by `Scenes/<name>/mood.luau` via `SceneLoader`. Runtime effects may change it temporarily and must restore it.
- Scene `layout.luau` / `mood.luau` hold only numbers, strings, booleans and tables, so Lune can load them.
- Shared libraries (Signal, Janitor, data persistence) come from Wally, added only when a feature needs them; never hand-rolled. Never keep scripts that come inside free models.
- Disconnect or clean up every connection a module makes after Init.
- Format with StyLua, lint with selene; both run inside `tools/check.sh` and the post-edit hook.
- When you edit a file in `tools/type-baseline.txt`, fix its type errors if cheap and lower its count.

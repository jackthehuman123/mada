# Assets

Rules for bringing assets in, a search list for the Creator Store, and a log of every asset used.

## Rules

1. **Gameplay first.** Graybox with parts until M7, unless an asset is needed to test something (e.g. a readable silhouette for Bà Thu).
2. **Sanitize every inserted model** right after `insert_asset`:
   ```lua
   -- run with execute_luau (Edit context); `model` is the inserted instance
   for _, d in model:GetDescendants() do
       if d:IsA("LuaSourceContainer") then d:Destroy() end
   end
   ```
   Then check nothing suspicious is left (no scripts, no `require(<number>)`, no hidden parts far away). Our code lives only in `src/`.
3. **Anchor, scale, rename** (`Prop_PaperLantern`, `House_Teacher`), parent under `Workspace.World.<Area>`, and add the CollectionService tags the code expects.
4. **Keep it light:** prefer single meshes over 500-part models; under ~10k triangles per prop; reuse one asset many times rather than many similar assets.
5. **Fit the setting:** 1990s north-central Vietnamese village. Avoid modern items, Japanese/Chinese-specific architecture that reads wrong (pagoda towers, torii gates), fantasy styles.
6. **Never use:** characters, logos or props from other games or franchises; brands; gore or blood; copyrighted music. Audio: use Roblox-licensed or uploaded-by-Roblox sounds from the Creator Store.
7. **Log it** below. If it's not in the log, it shouldn't be in the place.

## Creator Store search list

| Need | Try these searches |
| --- | --- |
| Houses | vietnamese house, asian village house, thatched hut, tile roof house, rural house, wooden shack |
| Shrine | small shrine, asian shrine, altar, incense burner, offering table |
| Nature | bamboo, banana tree, reeds, cattail, lotus, lily pad, marsh grass, tropical tree, rocks |
| Water props | wooden dock, jetty, wooden boat, sampan, fishing net, stone steps |
| Village props | water jar, clay pot, well, wooden fence, bench, conical hat, bicycle (old), straw mat |
| Lanterns | paper lantern, floating lantern, candle lantern, lotus lantern |
| Interior | wooden bed, cupboard, table and stools, teacup, teapot, old radio, family altar, photo frame |
| Puppets | water puppet, wooden puppet, puppet stage |
| Fish | koi, carp, fish school |
| Sound | night crickets, frogs, water lapping, wind reeds, radio static, child humming, wooden drum, distant festival |

Not found or wrong style → `generate_mesh` with a specific prompt, e.g. *"small handmade paper lantern folded in the shape of a carp, lumpy, faded red and white paper, a candle inside"*.

## Asset log

| Asset ID | Name in place | Source (Creator Store / generated / imported) | Creator | Used where | Sanitized? | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |

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

## Audio used (M7, 2026-11-02)

All from Roblox's licensed sound library on the Creator Store, published by **ProSoundEffects** for use in any
experience. Chosen by name and checked to load in Studio; **not yet listened to**. Used through `src/shared/Content/Sounds.luau`.

| Sound id in the game | Asset | Name on the Creator Store | Length |
| --- | --- | --- | --- |
| amb_night | 9112764546 | Crickets Night 1 (SFX) | 36.0 s, looped |
| amb_water | 9116203162 | Lake Lap Water Movement 2 (SFX) | 45.7 s, looped |
| amb_underwater | 9112889917 | Underwater Ambience 1 (SFX) | 59.4 s, looped |
| child_crying_water | 9113996806 | Cries Whimpers 14 (SFX) | 3.6 s |
| child_inside | 9113784466 | Child Giggle 1 (SFX) | 5.6 s |
| lantern_on_water | 9119293555 | Small Splash Shallow Water Fountain Pool 1 (SFX) | 2.8 s |
| carp_splash | 9119481268 | Splashes Small Wet Sloshes Drips 13 (SFX) | 0.9 s |
| wet_footsteps | 9120589946 | Water Splash Wet Smacking Footsteps 1 (SFX) | 10.6 s (cut at 5 s) |
| taken | 9126147241 | Underwater Movement Gurgly Mysterious Cu Boa (SFX) | 43.2 s (cut at 6 s) |
| incense | 9120930385 | Wood Matches 4 (SFX) | 14.0 s (cut at 3 s) |
| tape_static, festival_static | 9118027586 | Radio Static 9 (SFX) | 0.7 s, looped |
| radio_off | 9117158538 | Old Radio Click On Off Tuning Buzz 1 (SFX) | 2.2 s |
| memento_minh | 9117233304 | Paper Tear Tear Heavy Paper Bag Rustle 2 (SFX) | 3.0 s |
| memento_hanh | 9120918417 | Wood Knock Knocking On Wooden Door Hits 3 (SFX) | 1.6 s |

Still silent (no fitting licensed sound found): camera_beep, memento_ti (clay whistle), memento_khoa (drum), finale_home (music).

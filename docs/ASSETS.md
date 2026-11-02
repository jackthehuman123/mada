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

## Shortlist (scouted 2026-11-02 with `tools/art/scout.luau`, nothing inserted yet)

Free Creator Store models, judged from thumbnails only. Look again in Studio before using any of them.

| Asset ID | Name | For | Verdict |
| --- | --- | --- | --- |
| 14769019514 | Oriental Bamboo Conical Hat (RZKU, 3.5k tris, 0 scripts) | nón lá on porches, Bà Thu's mat | Good |
| 137203388093234 | grandma (Bank_Biker, 18.7k tris) | Bà Thu base | Realistic Asian grandmother; remove the bag (looks branded), recolour to a worn áo bà ba. Check rig and scale |
| 124926625809038 | Fishing Village Kit / Stilt Houses, Pier & Boats | dock, boats | Toy-like and bright; props only, if at all |
| 103169988462307 | Fishing Village & Dock Kit (180k tris) | boat, dock planks | Heavy; take single props |
| 8518538975 | Vietnamese House (127k tris) | — | An overgrown shell, too heavy. No |
| 5141896074, 13593241424, 4151631784 | Thai / Chinese / Japanese houses | — | Wrong country (rule 5). No |
| 2100050345 | Ghost Girl | — | Reads as Sadako (The Ring) and is adult-sized. No |

Avatar catalog items (usable on NPC rigs through a HumanoidDescription, no ownership needed): Nón Lá conical hat
110467700930899, Headlamp 26733587 (Bin). Áo bà ba isn't in the catalog by that name; look for plain button
shirts with loose pants, or upload our own clothing texture (a human step).

Search words that worked better than "vietnamese house": `old lady`, `grandma npc`, `asian old woman`, `conical hat`,
`fishing village`, `abandoned house`. For houses, plan on `generate_mesh` (I-10).

### Music candidates (I-13, scouted 2026-11-02 with `scout.luau --audio`, none listened to)

In use (`Content/Sounds.luau`): 140021816582186 menu, 9043359699 bed, 1836290021 tension, 70615932668908 chase.
Alternatives, if those sound wrong:

| Use | Asset ID | Title (artist, uploader) | Seconds |
| --- | --- | --- | --- |
| menu | 133759804695426 | Creepy Music Box (Terra Fantasy, DistroKid) | 185 |
| menu | 99895453377463 | Existential Dread, deep dark ambient drone (Horrarchive, DistroKid) | 238 |
| bed | 1847595163 | Creepy B (Mac Prindy, APM "New Drones and Dark Moods") | 103 |
| bed | 9112775175 | Eerie Ambience 1 (Pro Sound Effects) | 56 |
| tension | 1836289781 | Unseen Danger (Steve Gray, APM Suspense/Tension) | 160 |
| tension | 1843585137 | Unarmed (Barry Devorzon, APM Suspense/Tension/Action) | 72 |
| chase | 84484303568744 | Don't Look Back (Horror Music Archives, DistroKid) | 95 |
| chase | 71374905925238 | The Chase Protocol (Horror Music Archives, DistroKid) | 147 |
| chase | 97460960711268 | Corrupted Lullaby (Horror Music Archives, DistroKid) | 155 |
| sting | 9042971851 | An Ending, A Beginning Sting (APM "Dark Piano Builds") | 11 |

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

| camera_beep | 9113936447 | Cordless Phone Sony Digital 900 3 (SFX) | 0.2 s |
| memento_ti | 9120675895 | Whistle Calling 4 (SFX), played at 1.25x toward a clay whistle | 0.9 s |
| memento_khoa | 9125514674 | Drum Tom Tom Single Hits Bent Drum Head (SFX) | 3.5 s |
| finale_home | 130372750623176 | Hours Before Dawn Underscore Ambient + Melody (APMOfficial, Roblox's licensed music) | 153 s, stops on reset |

Added 2026-11-03; all four checked to load, none listened to yet. No sound is left silent.

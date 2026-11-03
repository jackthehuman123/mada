# Generating models in Roblox Studio for Làng Vọng (guide for a helper's Claude)

**Who this is for:** a Claude Code session on a friend's computer that has Roblox Studio and the Studio MCP server.
The friend is helping Catlyn, who designs and owns *Làng Vọng*. Your job is to **generate 3D props with Roblox's
own generator (Cube, through the Studio Assistant or the MCP `generate_mesh` tool)** and hand them back as files.
You don't build the game, edit its code or open Catlyn's place.

Read this whole page before the first generation. Written 2026-11-02.

---

## 1. The game in one minute

*Làng Vọng* is a 1–4 player co-op story-horror game on Roblox, based on the Vietnamese *ma da* (drowning spirit)
folklore. It takes place in a small 1990s village in north-central Vietnam, on a lake in the forest, on the night of Rằm tháng bảy (the
15th of the 7th lunar month: ghost month, full moon). People float paper lotus lanterns for the dead. Thirty years ago a
lonely eight-year-old girl, Sen, drowned there; the neighbours turned their radios up so they wouldn't hear what went
on in her house. She is still in the lake. The old woman at the shrine, Bà Thu, is her mother.

The look: cold, foggy, blue-grey night; the only warm light comes from lanterns, oil lamps and incense. Everything is
**old, worn, handmade and poor**: faded paint, flaking lime plaster, dark wood, terracotta tiles, moss. Nothing new,
shiny, modern or branded.

## 2. Rules you must keep (non-negotiable)

1. **Content.** No gore, no blood, no wounds, no bodies, no skulls, nothing monstrous. Sen is a sad child, not a
   monster: **her face is always hidden by her hair.** Reject any preview that shows her face, or anything that looks
   scary, hurt or sexualised.
2. **Respect.** The altar, the incense, the ancestor photos and the shrine are sacred things in Vietnamese homes.
   Prompt and handle them plainly and respectfully; no skulls, demons, fire or "spooky altar" styling.
3. **No brands, logos or text** on anything (the camcorder and radio especially). Nothing copied from another game, film
   or franchise.
4. **Don't touch Catlyn's game.** Work in your own empty place (§4). Don't edit the repo's `src/`,
   `src/server/World/Build.luau` or any `.github/` file, and don't run `rojo serve` against this place.
5. **Nothing published, no Robux, no account settings.** Generating in Studio is free; if any step asks for Robux, a
   purchase, publishing a game or changing permissions, stop and ask your human.
6. **Your human picks.** Show them the screenshots (§5 step 5) and let them choose between previews. Catlyn approves in
   the end.

## 3. Setup (once)

1. Studio up to date. In Studio: **File → Beta Features → turn on "Assistant Mesh Generation"** (if it's listed; it
   may be out of beta by now). If Studio has an **"Allow Mesh / Image APIs"** setting (Game Settings → Security, or
   the Assistant's settings), turn it on.
2. Assistant panel → **… → Manage MCP Servers → Enable Studio as MCP server**, and connect your Claude Code to it
   (Roblox docs: <https://create.roblox.com/docs/studio/mcp>). Check with `list_roblox_studios`.
3. Clone the repo (`git clone` the URL Catlyn gave you) and check out the branch she names (today: `playtest-fixes`).
   Make your own branch for the results: `git switch -c art/studio-gen-<yourname>`.
4. Look at the reference pictures in `docs/refs/v2/` (especially `sen_house_interior.jpg`, `4_the_last_lane.jpg`,
   `5_the_bottom_step.jpg`) and `docs/refs/forest_village_edge.png`. That's the target look.

## 4. Your workspace: a lab place

- In Studio: **File → New → Baseplate**. Save it locally as `LangVong_AssetLab.rbxl` (File → Save to File). Never use
  Catlyn's game place for this.
- Run this once with `execute_luau` (Edit context) to set up night light like the game's, so you judge models the way
  players will see them:

```lua
local L = game:GetService("Lighting")
L.ClockTime = 20.5
L.Brightness = 1
L.Ambient = Color3.fromRGB(40, 48, 60)
L.OutdoorAmbient = Color3.fromRGB(70, 80, 95)
local cc = L:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", L)
cc.Saturation = -0.25
cc.TintColor = Color3.fromRGB(215, 225, 240)
local lab = workspace:FindFirstChild("Lab") or Instance.new("Folder", workspace)
lab.Name = "Lab"
```

- To see colour properly too, also take one screenshot in daylight (`ClockTime = 14`), then set it back.

**Scale:** a player is about 5 studs tall, so **1 stud ≈ 30 cm**. The sizes in §6 are already in studs. X is
width, Y is height, Z is depth (Z is the length for the camcorder; its lens points at −Z).

## 5. How to make one asset

**Step 1: bounding box.** For each asset, make a transparent box of the exact size in §6 so the generator fits the model inside it:

```lua
-- execute_luau, Edit context. name and size from §6; spread boxes 15 studs apart along X
local name, size, x = "lotus_lantern", Vector3.new(1.6, 1, 1.6), 0
local box = Instance.new("Part")
box.Name = name .. "_Box"
box.Size = size
box.Anchored = true
box.Transparency = 0.8
box.CanCollide = false
box.Position = Vector3.new(x, size.Y / 2 + 0.5, 0)
box.Parent = workspace.Lab
```

**Step 2: generate.** Two ways; use whichever works on your Studio:

- **Assistant (best quality control):** select the `_Box` part, open the Assistant, type
  `/generate <prompt>` (some versions call it `/generate_mesh`). Use the **prompt + style line** from §6 and set the
  **max triangles** from §6 if asked (default 10,000). Before it generates, the Assistant shows a **segmentation
  plan**: rename the parts to the **Parts** names in §6 (up to 8). Confirm; it makes **four previews**. Take
  screenshots, let your human pick one, then **Add to place**.
- **MCP `generate_mesh`:** read the tool's schema first (its parameters aren't fully documented). If it takes a
  size or bounding part, a triangle limit or part names, use the §6 values. If it doesn't, generate, then scale the
  result into the box (step 4).

Text **or** an image can be the prompt, not both. Use text by default. Use an image only when §6 says so, or when two text tries
miss: crop the reference to that one object (`store_image` turns a local file into a URI for the tools).

**Step 3: check it.** Reject and regenerate (at most 3 rounds per asset, then move on and note why) if:
- it breaks a rule in §2 (a face on Sen, a logo, anything gory or disrespectful);
- it looks modern, new, plastic-shiny, Japanese or Chinese (pagoda roofs, torii), fantasy or cartoonish;
- extra objects are stuck to it (a ground slab, a table under it, water, a second copy);
- it's over the triangle limit. Count with:

```lua
local AssetService = game:GetService("AssetService")
local function tris(model: Instance): number
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA("MeshPart") then
			local ok, em = pcall(function()
				return AssetService:CreateEditableMeshAsync(d.MeshContent)
			end)
			if ok and em then n += #em:GetFaces() end
		end
	end
	return n
end
print(tris(workspace.Lab.Prop_LotusLantern))
```

  If that errors on your Studio, trust the triangle limit you set at generation and note "count not checked".

**Step 4: tidy it.** For a kept model:
- name it `Prop_<PascalCaseName>` (e.g. `Prop_LotusLantern`); each part named as in §6;
- delete anything that isn't a MeshPart, Part, SurfaceAppearance, Attachment or WeldConstraint (generated models
  shouldn't contain scripts, but check: **no Script/LocalScript/ModuleScript may remain**);
- anchor every part; scale so it fits its `_Box`; set the model's **pivot to the bottom centre** (the point that sits on the
  floor or water), the front facing −Z;
- put these attributes on the model: `Source = "Roblox Cube (Studio Assistant)"`, `Prompt = <the prompt used>`,
  `MadeBy = <your human's name>`, `Date = "YYYY-MM-DD"`, `Triangles = <count or 0>`;
- delete the `_Box`.

**Step 5: screenshots.** `screen_capture` from the front at 3/4 angle and from eye height (a player's eyes are ~4.5 studs up),
at night light. For hand-held or table props, also close up. Show them to your human.

**Step 6: save the file.** Ask your human to right-click the model in the Explorer → **Save to File…** →
`art/generated/<name>.rbxm` (the `name` in §6, snake_case), in the repo. If Studio offers **Export Selection** (.obj),
also export to `art/generated/obj/<name>.obj` (with its .mtl and textures): it's the fallback if the mesh can't load in Catlyn's place (§7).

**Step 7: log it.** Add a row to `art/generated/LOG.md` (create it with this header if it's missing):

```
| name | date | made by | source | prompt (short) | triangles | parts | rounds | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
```

## 6. What to make, in order

Add this **style line** to the end of every prompt:

> *, old and worn, handmade, rural Vietnam 1990s, realistic proportions, muted colours, single object, no ground, no
> background, no text, no logo, game asset*

**Do the first four (the probe set) and hand them back before the rest** (§7): they show whether the pipeline works
end to end and how good Cube is at each kind of object.

### Probe set

| # | name | size (studs) X×Y×Z | max tris | Parts | prompt |
| --- | --- | --- | --- | --- | --- |
| 1 | `lotus_lantern` | 1.6 × 1.0 × 1.6 | 1500 | Petals, Base, Candle | small floating paper lotus lantern, layers of pointed pale pink and white paper petals, a short white candle in the middle, flat round base so it floats |
| 2 | `camcorder` | 0.45 × 0.55 × 1.1 (lens toward −Z) | 3000 | Body, Lens, Viewfinder, Strap | 1990s handheld home video camcorder, boxy dark grey plastic body, round black lens at the front, small fold-out viewfinder on the left side, fabric hand strap on the right side, scuffed |
| 3 | `old_radio` | 1.8 × 1.1 × 0.8 | 3000 | Case, Grille, Dial, Knobs | old wooden tabletop valve radio, rectangular case of dark varnished wood with rounded top corners, woven cloth speaker grille on the left of the front, a yellowed tuning dial window, two round knobs, worn edges |
| 4 | `sen_standing` | 1.6 × 3.8 × 1.2 | 8000 | Hair, Shirt, Trousers, Skin, Sandal | thin eight-year-old Vietnamese girl standing still, arms hanging at her sides, head slightly lowered, very long straight black hair hanging down in front of her face so the face is completely hidden, plain loose faded grey-blue áo bà ba shirt and trousers, wet, one bare foot and one small plastic sandal, quiet and sad, not scary, no blood, no wounds |

Notes:
- **camcorder:** the player holds it in first person all game, so it's seen up close. The game adds the red REC light
  itself, so leave it out. Should read as a generic 90s camcorder; any visible brand is a reject.
- **old_radio:** the radios that were turned up along the lane; one sits in Sen's house, hissing for thirty years.
  Every house will have one.
- **sen_standing:** check every preview: **the face must be fully covered by hair**. She'll be seen pale and
  half-transparent under the water, so the silhouette (hair, thin arms, one sandal) matters more than detail.

### The rest, in priority order

| # | name | size X×Y×Z | max tris | Parts | prompt |
| --- | --- | --- | --- | --- | --- |
| 5 | `carp_lantern` | 1.6 × 1.2 × 2.4 (head toward −Z) | 2000 | Body, Fins, Base | small handmade paper lantern folded in the shape of a carp fish, lumpy hand-folded red and white paper, a small flat base so it floats, a candle glow inside |
| 6 | `sandals_pair` | 0.8 × 0.2 × 0.7 | 800 | Soles, Straps | a pair of small child's plastic sandals side by side, cheap faded plastic, thin straps, worn |
| 7 | `incense_bowl` | 0.8 × 1.2 × 0.8 | 2000 | Bowl, Ash, Sticks | small bronze incense burner bowl on three short feet, filled with grey ash, three thin incense sticks standing in it, plain and respectful |
| 8 | `oil_lamp` | 0.4 × 0.9 × 0.4 | 1500 | Base, Glass, Wick | small old kerosene oil lamp, round glass base holding oil, tall clear glass chimney, metal collar with a little wheel, simple |
| 9 | `bowl_chopsticks` | 0.6 × 0.35 × 0.6 | 1000 | Bowl, Chopsticks | one small white ceramic rice bowl with a thin blue line pattern, a pair of wooden chopsticks laid across the top, clean |
| 10 | `tea_set` | 1.4 × 0.7 × 1.0 | 2500 | Tray, Teapot, Cups | small round clay teapot and three tiny tea cups on a round wooden tray, covered in grey dust |
| 11 | `altar_table` | 6 × 5 × 2.4 | 5000 | Table, Carving, Shelf | tall narrow Vietnamese family ancestor altar table of dark red-brown lacquered wood, simple carved apron under the top, a lower shelf, empty top, respectful |
| 12 | `wooden_chair` | 1.8 × 3.2 × 1.8 | 2500 | Seat, Back, Legs | old simple wooden chair with a straight slatted back, dark worn wood, dusty |
| 13 | `water_jar` | 2.4 × 3.0 × 2.4 | 2500 | Jar, Lid | large glazed brown clay water jar, round belly, wide mouth, a round wooden lid, moss near the bottom |
| 14 | `roadside_shrine` | 3 × 4.5 × 3 | 5000 | Base, Walls, Roof, Altar | small brick roadside shrine on a raised base, whitewashed walls stained with moss, a tiny curved terracotta tile roof, an open front with a small offering ledge inside, plain and respectful, no statues |
| 15 | `ox_cart_overturned` | 6 × 4 × 9 | 6000 | Bed, Wheels, Shafts | old wooden ox cart lying overturned on its side, two big spoked wooden wheels, long wooden shafts, weathered grey wood |

Notes:
- **carp_lantern** is Sen's alone (everyone else's lantern is a lotus). If a preview looks good, also make a
  `carp_lantern_unfinished` variant: *"…half-finished, one side still flat unfolded paper"*: Bà Thu left one on
  Sen's shelf.
- **altar_table:** the table only. The bowl, candles and photo frame are placed on it separately, so leave them off.
- **sandals_pair:** five pairs are lined up on the stone steps, one per lost child, so it gets reused.

### Don't generate these (they're done other ways)

Houses, walls, roofs, porches, fences, bamboo, reeds, hanging roots, rocks, trees, the lake, terrain, faces,
Bà Thu (she needs an animated rig; a separate plan), Bin. If your human wants to try something not on the list, ask
Catlyn first.

### Optional: materials (`generate_material`)

If you have time after the list, make these MaterialVariants (the tool returns a base material and a variant name).
Put each variant in a Folder `Materials` and save the folder as `art/generated/materials.rbxm`:

| name | base | prompt |
| --- | --- | --- |
| `TerracottaTiles` | Slate | rows of old curved terracotta roof tiles, faded orange-brown, dark moss in the gaps |
| `LimewashOld` | Plaster | old yellow-ochre lime-washed plaster, flaking, damp grey stains at the bottom |
| `MossyStoneSteps` | Cobblestone | wet dark grey stone, green moss in the cracks |
| `MudPath` | Mud | wet dark brown mud with leaf litter and small puddles |

## 7. Handing it back

1. **After the probe set (1–4):** commit `art/generated/` on your branch, push it, and tell Catlyn (a pull request
   to her branch is ideal; never push to `main`). If you can't push, zip `art/generated/` and send it to her.
2. **Catlyn checks that the meshes load in her own place.** The generated meshes are stored under *your*
   Roblox account. Roblox may not let another account's place load them. If they don't load, she'll re-import
   from the `.obj` files instead, which is why step 6 exports both. Wait for her answer before doing the rest, so you
   don't make 15 models in a format that doesn't work.
3. Then do 5–15 the same way, in batches of a few, pushing as you go.
4. In your final message to your human, list: what was made, what was rejected and why, the triangle counts, and
   anything you had to change from this guide.

## 8. What happens next (not your job; for context)

On Catlyn's side, a session with Studio inserts each `.rbxm` into the game under `Workspace.World.<Area>`,
keeps the names and tags the game code uses, logs it in `docs/ASSETS.md`, and runs the game's tests. The camcorder
replaces the block one the player holds (`src/server/Services/BodyService.luau`), the lotus lantern replaces the
glowing ball in `Build.luau`, and so on.

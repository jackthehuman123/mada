# Asset pipeline: Meshy + Roblox

How Làng Vọng gets 3D models it can't find in the Creator Store (I-10, I-11). The queue and log is
`art/meshy/manifest.json`; the tools are in `tools/meshy/`. Asset rules in `docs/ASSETS.md` still apply.

## Which source, in order (reviewed 2026-11-02: Meshy's free plan is the weakest generator, so it comes last)

| | Source | Cost | Textured? | Use it for |
| --- | --- | --- | --- | --- |
| 1 | **Hand-made CC BY models** on Sketchfab / Fab, by Vietnamese modellers (search: `api.sketchfab.com/v3/search?type=models&downloadable=true&q=...`) | free, credit the author | yes | anything specifically Vietnamese: altar, village gate, interiors. Few exist; check them first (shortlist in `ASSETS.md`) |
| 2 | Creator Store (`tools/art/scout.luau`, then `insert_asset`) | free | yes | small generic props: jars, baskets, bamboo, rocks, reeds, nón lá |
| 3 | **Roblox Cube** (`generate_mesh` in Studio MCP, or Assistant `/generate`) | free, no monthly cap we know of | yes | most generated props; no licence to track; made for Roblox's limits |
| 4 | Hunyuan3D web (Tencent, about 20 a day free, unverified) | free | yes | hero shapes Cube can't do. Licence: not valid in the EU/UK/South Korea, label as AI-generated, a licence from Tencent past 1M monthly users. Catlyn decides |
| 5 | Meshy free plan (this page) | 10 a month | **no** | plain shapes only (roof, walls, porch kit) when 3 and 4 fail |
| 6 | Meshy Pro ($20/month, textures + API), a paid pack, or a modeller | money | yes | if none of the above is good enough (Catlyn's call) |

Tripo's free plan is out: its models are licensed CC BY *non-commercial*. Everything below (the queue, the checker,
the uploader) works the same for any source that gives a `.glb`.

## What the free plan gives (checked 2026-11-02)

- **100 credits a month**, reset on the 1st at 00:00 UTC, no rollover. Use them before the month ends.
- **10 downloads a month, untextured Meshy 6 Lite models only.** Textured models, Meshy 6/7 models and retextures
  can be made but not downloaded. So on the free plan **Meshy gives us shape, Roblox gives the colour**: Roblox
  materials (Plaster, Slate, Wood, WoodPlanks), part colours, MaterialVariants, Studio's texture tools.
- A Meshy 6 Lite preview (text or image to 3D, mesh only) costs **5 credits**, so 100 credits make 20 previews:
  **two tries per download**. Don't press texture/refine (10 credits) on the free plan: it can't be downloaded.
- No API (web app only), one task at a time, slow queue, no remesh, no free retries.
- Licence **CC BY 4.0**: allowed in the game, with credit. Every Meshy model gets "Generated with Meshy
  (meshy.ai), CC BY 4.0" in its Roblox description and the game's credits, and a row in `ASSETS.md`.
- Pro ($20/month, 1,000 credits) adds the API, private licence, texture downloads and remesh. Then
  `tools/meshy/` could call the API directly instead of the web app; nothing else in this pipeline changes.

## Spending the 10 a month well

1. **Generate parts that repeat, not whole scenes.** One roof shape dresses all 10 houses; the lantern, ~40 times.
   Untextured meshes take one colour each, so split by material: roof, walls and porch as separate models makes
   each house three colours (tile, limewash, wood) without textures.
2. **Image beats text** when the look is specific: a reference photo (CC-licensed, e.g. Wikimedia Commons, saved
   in `art/meshy/refs/`) of a real rural central Vietnamese house gives a much closer shape than words. Same price.
3. **Two previews, one download.** Make two previews (10 credits), compare them, download the better one. Never
   download "to see": a download is the scarce part.
4. **One object per prompt**, ending with "single object, no ground, game asset"; say what to leave out ("no walls",
   "no people"). Prompts follow `characters.md` and `story.md` only, and the content rules (`AGENTS.md` §8): Sen's
   face hidden, nobody hurt, respectful altars.
5. **Check before using up a download slot on a heavy model:** Meshy shows the polycount; Roblox takes up to ~20k
   triangles per MeshPart, and a prop used 40 times should stay well under 5k.
6. **Keep a spare:** plan 8 assets a month and keep 2 downloads for a redo.

## The pipeline, step by step

| Step | Who | What | Where |
| --- | --- | --- | --- |
| 1. Queue | any Claude session | add an entry: name, what it dresses (graybox parts, names and tags to keep), size in studs, material/colour, mode (text/image), prompt | `art/meshy/manifest.json` |
| 2. Generate | Catlyn (Meshy web app, signed in) | Meshy 6 Lite, mesh only; two previews; paste the model's Meshy link into `meshyUrl`; status `generated` | meshy.ai |
| 3. Download | Catlyn | download the better one as **.glb**, save as `art/meshy/in/<name>.glb` (the manifest name) | `art/meshy/in/` |
| 4. Check | any session, no Studio | `lune run tools/meshy/check.luau art/meshy/in/<name>.glb`: triangles, size, textures vs Roblox limits; writes them to the manifest (`checked` / `too heavy`) | — |
| 5. Upload | Catlyn's account (AGENTS.md §9) | `lune run tools/meshy/upload.luau <name>` with her Open Cloud key in the environment, **or** Studio's 3D Importer; asset id into the manifest (`uploaded`) | Roblox |
| 6. Place | `world-builder` in Studio | `insert_asset` the id, scale to `studs`, set material/colour, rename, keep every graybox name, tag and position the code uses, parent under `Workspace.World.<Area>`; status `placed`; row in `ASSETS.md` | the place |
| 7. Test | Studio session | `python tools/factory/test.py --art` PASS, screenshot in `PROGRESS.md`, Catlyn approves | — |

Too heavy (step 4)? Do the next month's attempt with "low poly" in the prompt, or decimate it in Blender (free):
Modifier → Decimate → ratio until under the limit → export .glb with the same name.

The Meshy files themselves are committed under `art/meshy/in/` (a few MB each; nothing gets lost on a borrowed
laptop). The Roblox asset id is what the place uses.

## Setup

- A Meshy account (free) for whoever generates. Meshy's web app is the only way in on the free plan.
- Lune (already in `rokit.toml`) for `check.luau` and `upload.luau`.
- For `upload.luau` only: an Open Cloud API key (create.roblox.com → Open Cloud → API Keys, **Assets: read and
  write**), kept in the shell as `ROBLOX_API_KEY` with `ROBLOX_CREATOR_USER_ID`. Never commit it.

## This month (2026-11)

Ten queued in the manifest, in order: roof, walls, porch (the house kit for all 10 houses), shrine, carp lantern,
Bà Thu seated, Sen standing, family altar, lotus lantern (swapped in for the sampan after Catlyn's references), water puppet pavilion. Bà Thu's finale walk and Bin (who
follows players) need animated rigs, so they stay on the HumanoidDescription plan in I-11.

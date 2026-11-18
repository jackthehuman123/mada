# Tooling setup: Rojo, Roblox Studio MCP, free assets

This is how the human sets up the machine once, and how the agent uses the tools afterwards.

Three pieces work together:

| Piece | What it does | Required? |
| --- | --- | --- |
| **Rojo** | Syncs the Luau code in `src/` (git) into the open Studio place, live. | Yes |
| **Roblox Studio MCP server** (built into Studio) | Lets Claude Code drive Studio: build the world, run Luau, **search and insert free Creator Store assets**, generate meshes, playtest, read the console, take screenshots. | Yes |
| **Blender MCP** | Lets Claude pull free CC0 models from Poly Haven / Poly Pizza / Sketchfab into Blender, then you import them to Roblox. | Optional |
| **ElevenLabs MCP** | Lets Claude generate speech, sound effects and music. | Optional (§6) |

> Run Claude Code **on the same computer as Roblox Studio** (Windows or macOS), natively — not inside WSL or a cloud machine. The Studio MCP server is a local process that talks over stdio.

---

## 1. Install (once)

1. **Roblox Studio** — latest version, signed in.
2. **Git**.
3. **Claude Code** (needs a paid Claude plan).
4. **Rokit** (Roblox toolchain manager):
   - Windows (PowerShell): `irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex`
   - macOS: `curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash`
5. In the repo folder: `rokit install` (installs the Rojo and Lune versions pinned in `rokit.toml`; answer yes to trusting them), then `rojo plugin install` (installs the matching Rojo plugin into Studio).
6. Optional formatters/linters: `rokit add JohnnyMorganz/StyLua` and `rokit add Kampfkarren/selene`.

## 2. Create the place

1. Studio → **New** → **Baseplate** (delete the baseplate later; the agent builds the terrain).
2. **File → Publish to Roblox** as a new private experience called *Làng Vọng (prototype)*. Publishing gives you cloud saves and lets you add collaborators later (Game Settings → Permissions / Team Create).
3. Game Settings → Places → max players **4**.

## 3. Connect Rojo (every session)

1. In a terminal in the repo: `rojo serve`
2. In Studio: **Plugins → Rojo → Connect**.
3. You should see `ServerScriptService.Server`, `ReplicatedStorage.Shared` and `StarterPlayer.StarterPlayerScripts.Client` appear.

Rules:
- Rojo only manages the folders listed in `default.project.json`. It does **not** touch `Workspace`, so the world the agent builds in Studio is safe.
- Only **one** person should run `rojo serve` into a shared Team Create place at a time, or the two copies of `src/` will fight.
- Don't edit synced scripts inside Studio; edit the files.

## 4. Connect the Roblox Studio MCP server (once, then it stays on)

1. In Studio, open **Assistant** (top right).
2. Click **…** → **Manage MCP Servers**.
3. Turn on **Enable Studio as MCP server**.
4. Under **Quick connect**, turn on **Claude Code**. (If Claude Code isn't listed, install it, then restart Studio.)
5. Restart Claude Code. In Claude Code, run `/mcp` — you should see the Roblox Studio server connected.
6. Test: ask Claude "List the open Roblox Studio windows" (it calls `list_roblox_studios`).

**Manual setup** (only if Quick connect doesn't work):

- **Windows** (run from `cmd.exe`, not PowerShell, so `%LOCALAPPDATA%` expands):
  ```
  claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
  ```
- **macOS:**
  ```
  claude mcp add --transport stdio Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP
  ```
- Or as JSON (e.g. in a project `.mcp.json`, Windows shown):
  ```json
  {
    "mcpServers": {
      "Roblox_Studio": {
        "command": "cmd.exe",
        "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"]
      }
    }
  }
  ```

> Security: an MCP client connected this way can read and change everything in the open place. Only connect clients you trust, and keep only the Làng Vọng place open while the agent works.

**Troubleshooting:** restart both Studio and Claude Code; make sure Studio is open with the place loaded; check the binary path exists; if two Studio windows are open, the agent must pick the right `studio_id` from `list_roblox_studios`.

### What the Studio MCP server gives the agent

| Group | Tools |
| --- | --- |
| Scripts | `script_read`, `multi_edit`, `script_search`, `script_grep` (read-only use for Rojo-managed scripts) |
| **Free assets & generation** | `search_asset` (Creator Store + your inventory), `insert_asset` (by ID), `generate_mesh` (text → textured mesh), `generate_material`, `generate_procedural_model` + `wait_job_finished`, `upload_image`, `store_image` |
| World | `search_game_tree`, `inspect_instance`, `execute_luau` |
| Playtest | `get_studio_state`, `start_stop_play`, `get_console_output`, `screen_capture` |
| Input simulation | `character_navigation`, `user_keyboard_input`, `user_mouse_input` |
| Helpers | `subagent` (explore / playtest), `http_get` (Roblox docs), `skill`, `list_roblox_studios` |

## 5. Getting free assets and 3D models

### A. Creator Store, through the Studio MCP (main route)

The Creator Store holds hundreds of thousands of free models, meshes, decals and sounds that can be used in Roblox experiences. The agent:

1. `search_asset` with specific keywords (see `ASSETS.md` for the search list).
2. Picks results that look right, preferring simple meshes without scripts.
3. `insert_asset` with the ID, then **sanitizes** it (deletes every script inside), scales, anchors, renames, tags and parents it under `Workspace.World.<Area>`.
4. Logs the asset in `docs/ASSETS.md`.

Free models are a known source of malicious "backdoor" scripts. **Every** inserted model is stripped of Script, LocalScript and ModuleScript instances before it stays in the place.

### B. Generated meshes, through the Studio MCP

For props that are specific to this story and unlikely to exist in the store — the lumpy paper carp lantern, the clay whistle, the broken water puppet, a 1990s Vietnamese radio — the agent uses `generate_mesh` with a precise text prompt. Generated meshes are saved into the place. There may be usage limits; if a call fails, fall back to building the prop from parts.

### C. Built from parts / procedural (always available)

Graybox and simple props (walls, fences, steps, jars, tables) are built from parts in `tools/worldgen/` scripts, or with `generate_procedural_model`.

### D. Optional: CC0 libraries through Blender MCP

For better-looking models (rocks, plants, wooden props, HDRI-like textures), the Blender MCP server can search and download from **Poly Haven**, **Poly Pizza** (low-poly) and **Sketchfab** (check each model's license) into Blender. Setup:

1. Install Blender and `uv` (official installer).
2. `uvx mcp-for-blender setup` — or add it by hand: `claude mcp add blender uvx mcp-for-blender`, then `uvx blender-mcp install-addon` and enable the addon in Blender (Edit → Preferences → Add-ons).
3. In Blender's sidebar (`N`) → the MCP tab → enable Poly Haven / Sketchfab → **Connect**.

Getting a model from Blender into Roblox needs a human step: the agent exports an `.fbx`/`.obj` (keep it low-poly, under ~10k triangles per mesh) to `art/exports/`, then the human uses Studio's **File → Import 3D** to upload it. Log the result in `ASSETS.md` with its source and license.

Other free CC0 sources a human can download by hand: Kenney (kenney.nl), Quaternius, Poly Haven textures.

## 6. Optional: generated voice, sound effects and music (ElevenLabs MCP)

Free, Roblox-cleared audio from the Creator Store comes first, through the Studio MCP. That needs nothing extra.

To also **generate** voice-over, sound effects or music, connect ElevenLabs' official MCP server:

1. Make an ElevenLabs account and an API key. It has a free tier with limited monthly credits; **read their plan's terms on commercial use and attribution** before using generated audio in a published game.
2. Install `uv` (see §5D), then:
   ```
   claude mcp add elevenlabs -e ELEVENLABS_API_KEY=<your key> -- uvx elevenlabs-mcp
   ```
3. Restart Claude Code and check `/mcp`.

Generated files land in `audio/vo/`, `audio/sfx/` and `audio/music/`. **Uploading audio to Roblox is a human step:** Creator Hub → Creations → Development Items → Audio, or Studio's Asset Manager → Bulk Import. Uploads go through moderation and there are monthly upload limits. After uploading, put the asset IDs in `docs/ASSETS.md` / `docs/SOUND.md`.

Check that a voice supports the language and names you need (Vietnamese names like Bà Thu, Hạnh, Tí) before generating a whole script; make 2–3 samples first.

## 7. Using the subagents

The specialists in `.claude/agents/` load automatically when Claude Code starts in this folder. Check them with `/agents`. Claude delegates on its own based on each agent's description, or you can ask directly:

> Use the world-builder subagent to move the lanterns in the village layout.
> Use the studio-tester subagent to run the [playtest] checks in docs/specs/scene-village.md.

Only one agent should use Roblox Studio at a time (see `CLAUDE.md`).

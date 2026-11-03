"""A whole run of Làng Vọng played by a bot in Studio, filmed and checked against the timeline it should follow.

  python tools/factory/playthrough.py          # Studio window of its own, like test.py

The bot (playthrough_bot.luau) plays in the client like a player: it walks with pathfinding, holds the real prompts and
presses the dialogue's buttons. The few director shortcuts are marked [debug] in the timeline (game speed, keeping Sen
back outside her own beats so the run is repeatable, jumping the clock to midnight at the end).
Writes tools/factory/reports/playthrough-<stamp>/: timeline.md (expected beats, ticks, times, the event log), shots/,
frames/ (about one a second), playthrough.mp4 (the frames, 4x), sheets/ (contact sheets for the inspector).
"""
import base64
import datetime
import json
import pathlib
import subprocess
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test as T  # noqa: E402  (Studio handling, rojo build)

BOT = (T.TOOLS / "playthrough_bot.luau").read_text(encoding="utf-8")

# (id, what should happen, server setup run first or None, client body, timeout s)
STEPS = [
    ("intro", "The intro card (the rumour video) shows, then the Arrival phase", 'dbg("speed", 4) dbg("sen", "off")', """
tick("intro card shown", waitFor(function() return gui.Card.Visible and gui.Card.Text.Text:find("lanterns", 1, true) end, 20))
shot("intro-card")
tick("Arrival phase", waitFor(function() return phase() == "Arrival" end, 60))
""", 90),
    ("arrival", "Goal says walk with Bin to the shrine; Bin is there; walking into the shrine starts Night 1", None, """
task.wait(1.5)
tick("goal: walk with Bin to the shrine", goal():find("shrine", 1, true), goal())
tick("Bin is in the world", #CS:GetTagged("NpcBin") > 0)
shot("arrival-goal")
tick("walked to the shrine", walkTo(Vector3.new(-330, 2, -58), 6))
tick("Night 1 starts", waitFor(function() return phase() == "Night1" end, 15), phase())
shot("at-shrine")
""", 120),
    ("thu", "Bà Thu speaks (dialogue box, Skip button); Skip ends her scene; the lanterns go out", None, """
tick("dialogue box up", waitFor(function() return gui.Dialogue.Visible end, 20))
tick("goal: listen to Bà Thu", goal():find("Bà Thu", 1, true), goal())
shot("thu-dialogue")
tick("Skip button there", gui.Dialogue:FindFirstChild("Skip") and gui.Dialogue.Skip.Visible)
Remotes.DialogueSkip:FireServer() -- what the Skip button fires
tick("Skip closed the dialogue", waitFor(function() return not gui.Dialogue.Visible end, 8))
tick("beat 3: the lanterns", waitFor(function() return (RS:GetAttribute("Night1Beat") or 0) >= 3 end, 10))
task.wait(2)
shot("lanterns-drift")
""", 60),
    ("bin-gone", "The lanterns reach the four houses; Bin wanders off; the causeway floods; the camera beeps in the reeds", None, """
tick("Bin wanders off (beat 4)", waitFor(function() return (RS:GetAttribute("Night1Beat") or 0) >= 4 end, 40))
shot("bin-wanders")
tick("the causeway floods (beat 5)", waitFor(function() return (RS:GetAttribute("Night1Beat") or 0) >= 5 end, 40))
tick("Bin's camera is in the reeds (beat 6)", waitFor(function() return (RS:GetAttribute("Night1Beat") or 0) >= 6 end, 40))
tick("goal: something beeping in the reeds", waitFor(function() return goal():find("reeds", 1, true) end, 5), goal())
""", 120),
    ("camera", "Picking up Bin's camera starts the Open phase: goal 'Find Bin', the camera keys, the first rule", None, """
local p, pos = findPrompt("Pick up", Vector3.new(-286, 0, -55), 30)
tick("pickup prompt on Bin's camera", p ~= nil)
local held = p and hold(p, pos)
tick("held the prompt and it fired", held)
if not held then state:SetAttribute("NeedServer", "pickup") task.wait(2) end -- [debug fallback]
tick("Open phase", waitFor(function() return phase() == "Open" end, 10), phase())
shot("camera-picked")
tick("goal: find Bin, search the lit houses", waitFor(function() return goal():find("Search", 1, true) end, 5), goal())
task.wait(8)
shot("open-goal-rule")
""", 90),
    ("tape", "[debug key T] Bin's tape plays in the camcorder view", None, """
cam("tape", 1)
task.wait(3)
shot("tape-1")
cam("stopplay")
task.wait(1)
tick("tape played and closed", true)
""", 30),
    ("clues", "Searching the lit houses finds clues and mementos; the counter rises; after 4 clues the goal points at Sen's house", None, """
local Clues = require(RS.Shared.Content.Clues)
local got = 0
for _, house in { "TeacherHouse", "PuppetHouse", "FishHouse", "HeadHouse" } do
	local m = location(house)
	if m then
		walkTo(m:GetPivot().Position + Vector3.new(0, 0, 4), 6)
		for _, c in CS:GetTagged("Clue") do
			local id = c:GetAttribute("ClueId")
			local def = id and Clues[id]
			local pr = c:FindFirstChildWhichIsA("ProximityPrompt", true)
			if def and def.location == house and pr and pr.Enabled then
				if not hold(pr, posOf(c)) then
					state:SetAttribute("NeedServer", "clue:" .. id) -- [debug fallback]
					task.wait(2)
				end
				local panel = gui:FindFirstChild("CluePanel")
				if panel and panel.Visible then
					got += 1
					if got == 1 then shot("clue-panel") end
					panel.Visible = false -- (the panel's Close button)
				end
			end
		end
		for _, mm in CS:GetTagged("Memento") do
			local pr = mm:FindFirstChildWhichIsA("ProximityPrompt", true)
			local pos = posOf(mm)
			if pr and pr.Enabled and pos and (pos - m:GetPivot().Position).Magnitude < 30 then
				hold(pr, pos)
				task.wait(3)
				shot("memento-" .. house)
				task.wait(4)
			end
		end
	end
	if got >= 4 and goal():find("end of the lane", 1, true) then break end
end
tick("clue panels opened: " .. got, got >= 4, got)
tick("counter shows the clues", gui.Goal.Counts.Text:find(tostring(RS:GetAttribute("CluesFound")) .. "/14", 1, true), gui.Goal.Counts.Text)
tick("goal points at Sen's house", waitFor(function() return goal():find("end of the lane", 1, true) end, 5), goal())
shot("goal-sen-house")
""", 400),
    ("lane", "Walking the empty stretch of the lane: a child cries in the water and carp gather (once a run)", 'dbg("speed", 2) dbg("sen", "on")', """
tick("walked the empty stretch", walkTo(Vector3.new(140, 2, -20), 6))
task.wait(1.5)
shot("lane-scare")
tick("the lane scare played (a cry from the water)", waitFor(function() return since("child_crying_water") end, 6))
""", 120),
    ("sen", "Alone on the dock: Sen's warnings 1-5, she walks out of the water after you, and takes you to the drowned festival", None, """
walkTo(Vector3.new(-140, 3, -58), 4)
walkTo(Vector3.new(-140, 3, -70), 3)
tick("first warning (a child crying)", waitFor(function() return since("sen_warning_1") end, 90))
tick("footprints / warning 3", waitFor(function() return since("sen_warning_3") end, 20))
local seen = waitFor(function() return workspace:FindFirstChild("SenOnLand", true) end, 4)
shot("sen-on-land")
tick("Sen came out of the water", seen or since("sen_on_land"))
tick("taken", waitFor(function() return lp:GetAttribute("Taken") == true end, 25))
task.wait(6)
tick("in the drowned festival", root() and root().Position.Y < -300, root() and root().Position)
tick("goal: taken and alone, find the lantern", goal():find("lantern on the stage", 1, true), goal())
shot("drowned-festival")
""", 200),
    ("wayback", "Alone: following the festival lantern home wakes you on the shore; running to the shrine is safe", None, """
local p, pos = findPrompt("Follow the lantern home", Vector3.new(0, -397, -30), 80)
tick("the way-back prompt on the stage", p ~= nil)
local held = p and hold(p, pos)
tick("held it and it fired", held)
if not held then state:SetAttribute("NeedServer", "wayback") task.wait(2) end -- [debug fallback]
tick("back on the shore", waitFor(function() return lp:GetAttribute("Taken") ~= true and root() and root().Position.Y > -50 end, 8))
task.wait(1)
shot("woke-on-shore")
tick("reached the shrine", walkTo(Vector3.new(-330, 2, -58), 6))
tick("not taken again on the way", lp:GetAttribute("Taken") ~= true)
task.wait(1.5)
shot("safe-at-shrine")
""", 90),
    ("letter", "[debug: Sen kept back now] Sen's house: 'Look under the altar' gives the letter; goal says bring it to Bà Thu", 'dbg("sen", "off") dbg("speed", 4)', """
local sen = location("SenHouse")
tick("walked to Sen's house", walkTo(sen:GetPivot().Position + Vector3.new(0, 0, 4), 8))
local altar = CS:GetTagged("SenAltar")[1]
local p = altar and altar:FindFirstChildWhichIsA("ProximityPrompt", true)
tick("altar prompt", p ~= nil and p.Enabled)
local held = p and hold(p, posOf(altar))
tick("held it and it fired", held)
if not held then state:SetAttribute("NeedServer", "letter") task.wait(2) end -- [debug fallback]
tick("goal: bring the letter to Bà Thu", waitFor(function() return goal():find("letter", 1, true) end, 6), goal())
shot("letter-found")
""", 150),
    ("give", "Back at the shrine: Bà Thu takes the letter, 'Write: Sen' is pressed, she sets off for the stone steps", None, """
tick("walked back to the shrine", walkTo(Vector3.new(-330, 2, -58), 6))
local thu = CS:GetTagged("NpcBaThu")[1]
local p = thu and thu:FindFirstChildWhichIsA("ProximityPrompt", true)
tick("talk prompt on Bà Thu", p ~= nil)
local held = p and hold(p, posOf(thu))
tick("held it and it fired", held)
if not held then state:SetAttribute("NeedServer", "talk") task.wait(2) end -- [debug fallback]
local t0 = os.clock()
while os.clock() - t0 < 40 and not (gui.Dialogue.Visible and gui.Dialogue.Choice.Visible) do
	if gui.Dialogue.Visible then Remotes.DialogueAdvance:FireServer() end -- (a click on the box)
	task.wait(1)
end
tick("the 'Write: Sen' choice", gui.Dialogue.Choice.Visible)
shot("write-sen")
Remotes.DialogueChoice:FireServer() -- what the choice button fires
tick("goal: Bà Thu walks to the steps", waitFor(function() return goal():find("stone steps", 1, true) end, 20), goal())
task.wait(2)
shot("thu-walks")
""", 120),
    ("ending", "[debug clock -> 23:59] Midnight: Về nhà, the teller's card, then the recap", 'dbg("time", 23.99)', """
tick("finale", waitFor(function() return phase() == "Finale" or phase() == "Ending" end, 20), phase())
task.wait(3)
shot("finale")
tick("Ending phase", waitFor(function() return phase() == "Ending" end, 90), phase())
tick("Về nhà card", waitFor(function() return gui.Card.Visible and gui.Card.Text.Text:find("Về nhà", 1, true) end, 10), gui.Card.Text.Text)
shot("ending-card")
tick("recap panel", waitFor(function() return gui:FindFirstChild("Recap") and gui.Recap.Visible end, 20))
shot("recap")
tick("recap lists the letter", gui.Recap.Text.Text:find("reached", 1, true), gui.Recap.Text.Text)
""", 150),
    ("again", "After the recap the night starts again (Studio; a live run server sends the team to the menu)", None, """
tick("back to the intro", waitFor(function() return phase() == "Intro" end, 60), phase())
shot("again")
""", 90),
]


def wrap(step_id, body):
    return (BOT + f"""
state:SetAttribute("Step", "{step_id}")
state:SetAttribute("Done", false)
state:SetAttribute("Result", "")
state:SetAttribute("Ticks", "[]")
state:SetAttribute("EvFrom", #events.Value)
task.spawn(function()
	local ok, err = pcall(function()
{body}
	end)
	state:SetAttribute("Result", ok and "ok" or ("ERROR " .. tostring(err)))
	state:SetAttribute("Done", true)
end)
return "started"
""")


READ = """local s = game.Players.LocalPlayer.PlayerGui:FindFirstChild("LVBot")
if not s then return "{}" end
return game:GetService("HttpService"):JSONEncode({ done = s:GetAttribute("Done"), want = s:GetAttribute("Want"),
	got = s:GetAttribute("Got"), result = s:GetAttribute("Result"), ticks = s:GetAttribute("Ticks"), need = s:GetAttribute("NeedServer") })"""
EVENTS = 'local e = game.Players.LocalPlayer.PlayerGui:FindFirstChild("LVBotEvents") return e and e.Value or ""'
SERVER_LOG = """local out = {}
for _, m in ipairs(game:GetService("LogService"):GetLogHistory()) do
	if m.message:find("^%[") then table.insert(out, { m.timestamp, m.message }) end
end
return game:GetService("HttpService"):JSONEncode(out)"""
DBG = 'local D = game:GetService("ServerScriptService"):WaitForChild("Debug", 10) local function dbg(...) return D:Invoke(...) end\n'


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    import os
    os.environ["RBX_STUDIO"] = T.SLUG
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    out = T.TOOLS / "reports" / f"playthrough-{stamp}"
    for d in ("shots", "frames", "sheets"):
        (out / d).mkdir(parents=True)
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=T.ROOT, capture_output=True, text=True).stdout.strip()
    place = T.ROOT / "build" / f"{T.SLUG}.rbxl"
    place.parent.mkdir(exist_ok=True)
    r = subprocess.run([T.ROJO, "build", str(T.ROOT / "default.project.json"), "-o", str(place)], capture_output=True, text=True, cwd=T.ROOT)
    if r.returncode:
        raise SystemExit("rojo build failed:\n" + r.stderr)
    before = T.studio_pids()
    subprocess.Popen([T.STUDIO, str(place)])
    results, frames, server_log, events, fallbacks = [], [], [], "", []
    t_start = time.time()
    try:
        if not T.wait_for(T.studio_open, 180, 2):
            raise SystemExit("Studio never opened the place")
        time.sleep(5)
        subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(T.TOOLS / "mute_studio.ps1")], capture_output=True)
        st = T.Studio()
        st.call("start_stop_play", is_start=True)
        ready = T.wait_for(lambda: "ok" in st.luau(
            "local p = game.Players:GetPlayers()[1] local D = game.ServerScriptService:FindFirstChild('Debug') "
            "if D and p and not p:GetAttribute('InRun') then D:Invoke('begin') end return D and p and "
            "p.Character and p.Character:FindFirstChild('HumanoidRootPart') and 'ok' or 'no'", "Server")[0], 90)
        if not ready:
            raise SystemExit("the server never got ready")
        t_start = time.time()

        def frame():
            _, images, _ = st.call("screen_capture", capture_id=f"f{len(frames)}")
            if images:
                name = f"f{len(frames):04d}.png"
                (out / "frames" / name).write_bytes(base64.b64decode(images[0]))
                frames.append((round(time.time() - t_start, 1), name))

        for sid, expect, server, body, timeout in STEPS:
            print("▶", sid, "-", expect)
            t0 = time.time()
            if server:
                st.luau(DBG + server.replace(") dbg(", ")\ndbg("), "Server")
            text, err = st.luau(wrap(sid, body), "Client")
            shots, state = [], {}
            while time.time() - t0 < timeout:
                frame()
                text, err = st.luau(READ, "Client")
                try:
                    state = json.loads(text) if not err else {}
                except ValueError:
                    state = {}
                want = state.get("want")
                if want and want != state.get("got"):
                    _, images, _ = st.call("screen_capture", capture_id=f"shot-{want}")
                    if images:
                        name = f"{len(results) + 1:02d}-{want}.png"
                        (out / "shots" / name).write_bytes(base64.b64decode(images[0]))
                        shots.append(name)
                    st.luau(f'game.Players.LocalPlayer.PlayerGui.LVBot:SetAttribute("Got", "{want}") return "ok"', "Client")
                need = state.get("need")
                if need:  # the bot's [debug fallback]: one action it couldn't do as a player
                    cmd, _, arg = need.partition(":")
                    st.luau(DBG + (f'dbg("{cmd}", "{arg}")' if arg else f'dbg("{cmd}")') + ' return "ok"', "Server")
                    st.luau('game.Players.LocalPlayer.PlayerGui.LVBot:SetAttribute("NeedServer", nil) return "ok"', "Client")
                    fallbacks.append((sid, need))
                if state.get("done"):
                    break
            ticks = json.loads(state.get("ticks") or "[]")
            if not state.get("done"):
                ticks.append({"label": "step finished in time", "ok": False, "detail": f"timeout {timeout} s", "t": None})
            if (state.get("result") or "").startswith("ERROR"):
                ticks.append({"label": "bot error", "ok": False, "detail": state["result"], "t": None})
            results.append({"fallbacks": [n for i, n in fallbacks if i == sid], "id": sid, "expect": expect, "ticks": ticks, "shots": shots,
                            "start": round(t0 - t_start, 1), "seconds": round(time.time() - t0, 1)})
            bad = [t["label"] for t in ticks if not t["ok"]]
            print(f"   {len(ticks) - len(bad)}/{len(ticks)} ticks" + (f" — missing: {', '.join(bad)}" if bad else ""))
        events, _ = st.luau(EVENTS, "Client")
        log_text, err = st.luau(SERVER_LOG, "Server")
        try:
            server_log = json.loads(log_text) if not err else []
        except ValueError:
            server_log = []
        st.call("start_stop_play", is_start=False)
    finally:
        for pid in T.studio_pids() - before:
            subprocess.run(["taskkill", "/PID", str(pid), "/F"], capture_output=True)
    write_outputs(out, stamp, commit, results, frames, events, server_log)


def write_outputs(out, stamp, commit, results, frames, events, server_log):
    from PIL import Image, ImageDraw
    # the video: every frame, 4 frames a second (a 4x time-lapse)
    try:
        import imageio.v2 as imageio
        with imageio.get_writer(out / "playthrough.mp4", fps=4, macro_block_size=16) as w:
            for _, name in frames:
                im = Image.open(out / "frames" / name).convert("RGB")
                im = im.resize((im.width // 16 * 16, im.height // 16 * 16))
                w.append_data(__import__("numpy").asarray(im))
    except Exception as e:  # the timeline still stands without a video
        print("video failed:", e)
    # contact sheets: every 3rd frame, 4 x 4, time stamped
    pick = frames[::3]
    for k in range(0, len(pick), 16):
        sheet = Image.new("RGB", (4 * 400, 4 * 200), (0, 0, 0))
        for i, (t, name) in enumerate(pick[k:k + 16]):
            im = Image.open(out / "frames" / name).convert("RGB").resize((400, 196))
            sheet.paste(im, ((i % 4) * 400, (i // 4) * 200))
            ImageDraw.Draw(sheet).text(((i % 4) * 400 + 6, (i // 4) * 200 + 4), f"{t:.0f}s", fill=(255, 255, 0))
        sheet.save(out / "sheets" / f"sheet-{k // 16:02d}.jpg", quality=80)
    total = sum(len(r["ticks"]) for r in results)
    good = sum(t["ok"] for r in results for t in r["ticks"])
    md = [f"# Làng Vọng playthrough {stamp}", "", f"- Commit `{commit}`; {len(frames)} frames; video `playthrough.mp4` (4x)",
          f"- Bot ticks: **{good}/{total}**", "", "| # | Beat (expected) | Start | Ticks | Shots |", "|---|---|---|---|---|"]
    for i, r in enumerate(results, 1):
        t = "<br>".join(f"{'✅' if x['ok'] else '❌'} {x['label']}" + (f" ({x['detail'][:80]})" if not x["ok"] and x["detail"] else "")
                        for x in r["ticks"])
        fb = "".join(f"<br>⚙️ [debug fallback] {n}" for n in r.get("fallbacks", []))
        md.append(f"| {i} | {r['expect']} | {r['start']} s | {t}{fb} | {', '.join(r['shots'])} |")
    md += ["", "## What the player's client saw (t = seconds since the bot started)", "", "```"]
    for line in events.splitlines():
        try:
            e = json.loads(line)
            md.append(f"{e['t']:7.1f}  {e['kind']:<12} {e['text'][:110]}")
        except ValueError:
            pass
    md += ["```", "", "## Server log", "", "```"]
    t0 = server_log[0][0] if server_log else 0
    md += [f"{ts - t0:7.1f}  {msg[:120]}" for ts, msg in server_log]
    md += ["```"]
    (out / "timeline.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    (out / "results.json").write_text(json.dumps(results, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"\n{good}/{total} ticks — {out / 'timeline.md'}")


if __name__ == "__main__":
    main()

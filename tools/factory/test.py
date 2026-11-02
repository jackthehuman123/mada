"""Automated playtest for Làng Vọng through Roblox Studio's built-in MCP server (the Roblox factory's test runner).

  python tools/factory/test.py            # every test in tests/
  python tools/factory/test.py 02 04      # only tests whose file name starts with these prefixes
  python tools/factory/test.py --keep     # leave the Studio window open afterwards
  python tools/factory/test.py --art      # run on the art layer (art/*.rbxm, tools/art/export.luau), not the graybox

What it does, every run, from git alone:
  rojo build -> build/langvong.rbxl -> opens it in a NEW Studio window (muted) -> Play -> runs each test's sections
  -> Stop -> closes only the window it opened. The world is built by the server from src/server/World (no place file).
Writes tools/factory/reports/<timestamp>/report.md (+ screenshots, console) and exits 1 if anything failed.
Needs: Roblox Studio installed and logged in, Rojo (rokit install), Python 3.10+. Windows (Mac: see README).

Test files (tests/NN_name.luau) are split into sections by marker lines:
  --@ Server      Luau run in the play-mode server  (helpers: dbg(cmd, arg), check, eq, near, Config)
  --@ Client      Luau run in the play-mode client  (helpers: cam(cmd, arg), gui, check, eq, near, Config)
  --@ Shot name   screenshot saved as name.png (of the play window as it is)
  --@ Shot name x,y,z -> x,y,z   the same, from a camera at the first point looking at the second
A section passes unless it raises; whatever it returns is shown in the report. A failed section skips the rest of
its file (later sections depend on earlier ones).
"""
import base64
import datetime
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import time

from rbx import BIN, ROOT_DIR as ROOT, Client

TOOLS = pathlib.Path(__file__).resolve().parent
SLUG = "langvong"
ROJO = shutil.which("rojo") or os.path.expanduser(r"~\.rokit\bin\rojo.exe")
LUNE = shutil.which("lune") or os.path.expanduser(r"~\.rokit\bin\lune.exe")
STUDIO = os.path.join(os.path.dirname(BIN), "RobloxStudioBeta.exe")
NOISE = [r"rbxassetid://", r"DataModel Loading", r"Asset type does not match", r"TextChatService"]

PRELUDE = {
    "Server": """
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local D = game:GetService("ServerScriptService"):WaitForChild("Debug", 10)
local function dbg(...) return D:Invoke(...) end
""",
    "Client": """
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local lp = game:GetService("Players").LocalPlayer
local C = lp:WaitForChild("PlayerScripts"):WaitForChild("LVClientDebug", 10)
local function cam(...) return C:Invoke(...) end
local gui = lp:WaitForChild("PlayerGui"):WaitForChild("LangVongUI", 10)
""",
}
HELPERS = """
local function check(c, msg) if not c then error(msg or "check failed", 0) end end
local function eq(a, b, msg)
  if a ~= b then error((msg or "value") .. ": expected " .. tostring(b) .. ", got " .. tostring(a), 0) end
end
local function near(a, b, tol, msg)
  if math.abs(a - b) > tol then error((msg or "value") .. ": expected ~" .. tostring(b) .. ", got " .. tostring(a), 0) end
end
"""
LOG_CODE = """
local out = {}
for _, m in ipairs(game:GetService("LogService"):GetLogHistory()) do table.insert(out, { m.messageType.Name, m.message }) end
return game:GetService("HttpService"):JSONEncode(out)
"""


def studio_pids():
    out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq RobloxStudioBeta.exe", "/FO", "CSV", "/NH"],
                         capture_output=True, text=True).stdout
    return {int(line.split('","')[1]) for line in out.splitlines() if line.startswith('"RobloxStudioBeta')}


class Studio:
    def __init__(self):
        self.c = Client()
        self.sid = self.c.studio_id()

    def call(self, tool, **args):
        args["studio_id"] = self.sid
        res = self.c.req("tools/call", {"name": tool, "arguments": args})
        text = "\n".join(p["text"] for p in res.get("content", []) if p.get("type") == "text")
        images = [p["data"] for p in res.get("content", []) if p.get("type") == "image"]
        return text, images, res.get("isError", False)

    def luau(self, code, dm="Edit"):
        text, _, err = self.call("execute_luau", code=code, datamodel_type=dm)
        return text, err


def parse(path):
    sections, kind, arg, buf = [], None, "", []
    for line in path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^--@\s*(Server|Client|Shot)\s*(.*)$", line)
        if m:
            if kind:
                sections.append((kind, arg, "\n".join(buf)))
            kind, arg, buf = m.group(1), m.group(2).strip(), []
        else:
            buf.append(line)
    if kind:
        sections.append((kind, arg, "\n".join(buf)))
    return sections


def wrap(kind, body):
    return (PRELUDE[kind] + HELPERS + "local ok, res = pcall(function()\n" + body +
            "\nend)\nreturn (ok and 'OK ' or 'FAIL ') .. tostring(res == nil and '' or res)")


def wait_for(fn, timeout, step=1.0):
    end = time.time() + timeout
    while time.time() < end:
        if fn():
            return True
        time.sleep(step)
    return False


def studio_open():
    r = subprocess.run([sys.executable, str(TOOLS / "rbx.py"), "call", "list_roblox_studios", "{}"],
                       capture_output=True, text=True, encoding="utf-8")
    return f'"name": "{SLUG}.' in r.stdout or f'"name":"{SLUG}.' in r.stdout


def run_tests(st, files, out):
    results, shots = [], []
    for f in files:
        print("▶", f.name)
        for kind, arg, body in parse(f):
            if kind == "Shot":
                m = re.match(r"^(\S+)\s+([-\d.]+),([-\d.]+),([-\d.]+)\s*->\s*([-\d.]+),([-\d.]+),([-\d.]+)$", arg)
                label = m.group(1) if m else arg
                extra = {"camera_position": [float(v) for v in m.groups()[1:4]],
                         "look_at_position": [float(v) for v in m.groups()[4:7]]} if m else {}
                _, images, _ = st.call("screen_capture", capture_id=f"{f.stem}-{label}", **extra)
                if images:
                    name = f"{f.stem}-{label}.png"
                    (out / name).write_bytes(base64.b64decode(images[0]))
                    shots.append(name)
                continue
            text, err = st.luau(wrap(kind, body), kind)
            if err and "not reachable" in text:
                time.sleep(2)
                text, err = st.luau(wrap(kind, body), kind)
            text = text.strip()
            status = "OK" if (not err and text.startswith("OK")) else "FAIL"
            detail = re.sub(r"^(OK|FAIL)\s?", "", text) if not err else text
            results.append((f.stem, kind, status, detail))
            print(f"   {status} [{kind}] {detail[:140]}")
            if status == "FAIL":
                break
    return results, shots


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    os.environ["RBX_STUDIO"] = SLUG  # talk only to the window this run opens
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    files = sorted(p for p in (ROOT / "tests").glob("*.luau") if not args or any(p.name.startswith(a) for a in args))
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    out = TOOLS / "reports" / stamp
    out.mkdir(parents=True)
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    dirty = bool(subprocess.run(["git", "status", "--porcelain", "src", "tests", "art"], cwd=ROOT, capture_output=True,
                                text=True).stdout.strip())

    place = ROOT / "build" / f"{SLUG}.rbxl"
    place.parent.mkdir(exist_ok=True)
    r = subprocess.run([ROJO, "build", str(ROOT / "default.project.json"), "-o", str(place)], capture_output=True, text=True,
                       cwd=ROOT)  # (rokit picks the Rojo version pinned in rokit.toml here)
    if r.returncode:
        raise SystemExit("rojo build failed:\n" + r.stderr)
    art = "--art" in sys.argv
    if art:  # the dressed world from art/ instead of the graybox from Build.luau
        if not os.path.exists(LUNE):
            raise SystemExit("--art needs Lune: run `rokit add lune-org/lune` (or `rokit install`) in this folder")
        r = subprocess.run([LUNE, "run", str(ROOT / "tools" / "art" / "merge.luau"), str(place), str(place)],
                           capture_output=True, text=True, encoding="utf-8", cwd=ROOT)
        print(r.stdout.strip())
        if r.returncode:
            raise SystemExit("art merge failed (is Lune installed? rokit install):\n" + r.stderr + r.stdout)
    art_commit = subprocess.run(["git", "log", "-1", "--format=%h", "--", "art"], cwd=ROOT, capture_output=True,
                                text=True).stdout.strip()
    before = studio_pids()
    subprocess.Popen([STUDIO, str(place)])
    results, shots, logs = [], [], []
    try:
        if not wait_for(studio_open, 180, 2):
            raise SystemExit("Studio never opened the place")
        time.sleep(5)
        subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(TOOLS / "mute_studio.ps1")],
                       capture_output=True)
        st = Studio()
        print("Studio:", st.sid)
        st.call("start_stop_play", is_start=True)
        ready = wait_for(lambda: "ok" in st.luau(
            "local p = game.Players:GetPlayers()[1] return game.ServerScriptService:FindFirstChild('Debug') and p and "
            "p.Character and p.Character:FindFirstChild('HumanoidRootPart') and 'ok' or 'no'", "Server")[0], 90)
        time.sleep(3)
        if not ready:
            results.append(("startup", "", "FAIL", "server never got ready (no Debug hook or no character)"))
        else:
            results, shots = run_tests(st, files, out)
        for dm in ("Server", "Client"):
            text, err = st.luau(LOG_CODE, dm)
            try:
                logs += [(dm, k, m) for k, m in (json.loads(text) if not err else [])]
            except ValueError:
                pass
        st.call("start_stop_play", is_start=False)
    finally:
        if "--keep" not in sys.argv:
            for pid in studio_pids() - before:
                subprocess.run(["taskkill", "/PID", str(pid), "/F"], capture_output=True)

    errors = [f"[{dm}] {m}" for dm, k, m in logs if not any(re.search(n, m) for n in NOISE)
              and (k == "MessageError" or (k == "MessageWarning" and "[LangVong]" in m))]
    failed = [x for x in results if x[2] == "FAIL"]
    passed = sorted({x[0] for x in results} - {x[0] for x in failed})
    ok = not failed and not errors
    md = [f"# Làng Vọng test report {stamp}", "", f"- Commit: `{commit}`{' + uncommitted changes' if dirty else ''}",
          f"- World: {'art layer (`art/`, last changed in `' + (art_commit or 'uncommitted') + '`)' if art else 'graybox (Build.luau)'}",
          f"- Result: **{'PASS' if ok else 'FAIL'}** — {len(passed)} tests passed, {len({x[0] for x in failed})} failed, "
          f"{len(errors)} console errors", "", "| Test | Section | Status | Detail |", "|---|---|---|---|"]
    for t, k, s, d in results:
        md.append(f"| {t} | {k} | {'✅' if s == 'OK' else '❌'} | {d.replace('|', '/').replace(chr(10), ' ')[:300]} |")
    if errors:
        md += ["", "## Console errors", ""] + [f"```\n{e}\n```" for e in errors[:30]]
    if shots:
        md += ["", "## Screenshots", ""] + [f"![{s}]({s})" for s in shots]
    (out / "report.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    (out / "console.txt").write_text("\n".join(f"[{dm}] {k}: {m}" for dm, k, m in logs), encoding="utf-8")
    print(f"\n{'PASS' if ok else 'FAIL'} — {len(passed)} passed, {len({x[0] for x in failed})} failed, {len(errors)} errors"
          f" — report: {out / 'report.md'}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()

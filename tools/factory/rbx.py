"""Minimal stdio MCP client for Roblox Studio's built-in StudioMCP.

Usage:
  python3 rbx.py list                      # list tools
  python3 rbx.py call <tool> '<json args>' # call a tool
  python3 rbx.py call <tool> @file.json    # args from file
"""
import json
import os
import pathlib
import subprocess
import sys

TOOLS = pathlib.Path(__file__).resolve().parent
ROOT_DIR = TOOLS.parent.parent  # (tools/factory/ -> the repo)

def _bin():
    if sys.platform == "win32":  # Studio updates land in a new Versions\version-* folder; take the newest
        import glob
        found = glob.glob(os.path.expandvars(r"%LOCALAPPDATA%\Roblox\Versions\*\StudioMCP.exe"))
        if not found:
            raise SystemExit("StudioMCP.exe not found: is Roblox Studio installed?")
        return max(found, key=os.path.getmtime)
    return "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"


BIN = _bin()


class Client:
    def __init__(self):
        self.p = subprocess.Popen([BIN], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, text=True, encoding="utf-8", bufsize=1)
        self.i = 0
        self.req("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                "clientInfo": {"name": "rbx-cli", "version": "0.1"}})
        self.send({"jsonrpc": "2.0", "method": "notifications/initialized"})

    def send(self, msg):
        self.p.stdin.write(json.dumps(msg) + "\n")
        self.p.stdin.flush()

    def req(self, method, params):
        self.i += 1
        rid = self.i
        self.send({"jsonrpc": "2.0", "id": rid, "method": method, "params": params})
        while True:
            line = self.p.stdout.readline()
            if not line:
                raise SystemExit("StudioMCP exited: " + self.p.stderr.read()[-2000:])
            msg = json.loads(line)
            if msg.get("id") == rid:
                if "error" in msg:
                    raise SystemExit("ERROR: " + json.dumps(msg["error"]))
                return msg["result"]


def _studio_id(self, tries=15):
    import time
    for _ in range(tries):
        r = self.req("tools/call", {"name": "list_roblox_studios", "arguments": {}})
        studios = json.loads(r["content"][0]["text"])["studios"]
        want = os.environ.get("RBX_STUDIO")  # pick a Studio window by place name, e.g. RBX_STUDIO=test
        if want:
            studios = [s for s in studios if (s.get("name") or "").split(".")[0] == want]
        if studios:
            return studios[0]["id"]
        time.sleep(1)
    raise SystemExit("No Roblox Studio instance connected")


Client.studio_id = _studio_id


def main():
    sys.stdout.reconfigure(encoding="utf-8")  # Windows consoles default to cp1252; tool docs contain arrows etc.
    c = Client()
    if sys.argv[1] == "list":
        for t in c.req("tools/list", {})["tools"]:
            if len(sys.argv) > 2:
                if t["name"] == sys.argv[2]:
                    print(json.dumps(t, indent=1))
            else:
                print(t["name"], "-", t.get("description", "")[:150].replace("\n", " "))
        return
    if sys.argv[1] == "luau":  # luau <file.lua> [Edit|Server|Client]
        tool = "execute_luau"
        raw = json.dumps({"code": open(sys.argv[2], encoding="utf-8").read(),
                          "datamodel_type": sys.argv[3] if len(sys.argv) > 3 else "Edit"})
    else:
        tool = sys.argv[2]
        raw = sys.argv[3] if len(sys.argv) > 3 else "{}"
    if raw.startswith("@"):
        raw = open(raw[1:], encoding="utf-8").read()
    args = json.loads(raw)
    if "studio_id" not in args and tool != "list_roblox_studios":
        args["studio_id"] = c.studio_id()
    res = c.req("tools/call", {"name": tool, "arguments": args})
    for part in res.get("content", []):
        if part.get("type") == "text":
            print(part["text"])
        elif part.get("type") == "image":
            import base64, os, time
            os.makedirs("shots", exist_ok=True)
            path = f"shots/shot-{int(time.time()*1000)}.png"
            open(path, "wb").write(base64.b64decode(part["data"]))
            print("IMAGE:", os.path.abspath(path))
        else:
            print(f"[{part.get('type')} content]")
    if res.get("isError"):
        sys.exit(1)


if __name__ == "__main__":
    main()

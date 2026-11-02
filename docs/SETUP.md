# Local development setup

How to get from a fresh computer to Claude Code building the game in Roblox Studio. Covers **Windows** and **macOS**. The repo is `mada` on GitHub.

> Run everything **natively** on the computer that has Roblox Studio (PowerShell on Windows, Terminal on macOS). Not inside WSL, a VM or a cloud machine: Studio's MCP server is a local program that Claude Code has to launch.

---

## 0. Accounts and access

- A **Roblox** account (for Studio).
- A **Claude** plan that includes Claude Code.
- A **GitHub** account with access to the `mada` repo (Catlyn adds you as a collaborator: repo → Settings → Collaborators).
- Roblox Studio installed and **opened once and signed in** (some tools look for it on first launch).

## 1. Install the tools (once per computer)

### macOS (Terminal)

```bash
# Git (comes with the Xcode command-line tools)
xcode-select --install

# Claude Code, then sign in
curl -fsSL https://claude.ai/install.sh | bash
claude            # log in, then type /exit

# Rokit (Roblox toolchain manager) — open a NEW Terminal window afterwards
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
```

### Windows (PowerShell)

```powershell
# Git
winget install --id Git.Git -e

# Claude Code, then sign in
irm https://claude.ai/install.ps1 | iex
claude            # log in, then type /exit

# Rokit — open a NEW PowerShell window afterwards
irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex
```

**If `claude` (or `rokit`) is "not recognized" / "command not found"** after installing, its folder isn't on your PATH. The installer prints the folder (e.g. `C:\Users\<you>\.local\bin` or `~/.local/bin`).

- Windows (no admin needed), then open a new PowerShell window:
  ```powershell
  [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";$HOME\.local\bin", "User")
  ```
- macOS (zsh), then open a new Terminal window:
  ```bash
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
  ```

Check: `claude --version`, `rokit --version`, `git --version`.

## 2. SSH key for GitHub

### Your own computer (account key)

macOS:
```bash
ssh-keygen -t ed25519 -C "<your GitHub email>"     # Enter for default path, set a passphrase
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub                      # copies the public key
```
Windows:
```powershell
ssh-keygen -t ed25519 -C "<your GitHub email>"
Get-Content "$HOME\.ssh\id_ed25519.pub" | Set-Clipboard
```
Then GitHub → your profile → **Settings → SSH and GPG keys → New SSH key** → paste. Test: `ssh -T git@github.com`.

### A shared or loaner computer (repo-only deploy key)

Use a key that can only reach `mada`, and delete it when you're done with the machine:
```powershell
ssh-keygen -t ed25519 -f "$HOME\.ssh\mada" -C "mada on <computer name>"
Get-Content "$HOME\.ssh\mada.pub" | Set-Clipboard
```
GitHub → `mada` repo → **Settings → Deploy keys → Add deploy key** → paste → tick **Allow write access**. (A deploy key can only be added to one repo, and each computer needs its own.)

## 3. Clone and install the project tools

Pick a folder for code (examples: `~/dev` on macOS, `C:\dev` on Windows).

macOS:
```bash
mkdir -p ~/dev && cd ~/dev
git clone git@github.com:<owner>/mada.git
cd mada
```
Windows (account key):
```powershell
mkdir C:\dev -Force; cd C:\dev
git clone git@github.com:<owner>/mada.git
cd mada
```
Windows (deploy key; the `-c` makes pull/push use it automatically):
```powershell
git clone -c core.sshCommand="ssh -i C:/Users/<you>/.ssh/mada" git@github.com:<owner>/mada.git
cd mada
```

Set your name for commits in this repo:
```
git config user.name "<your name>"
git config user.email "<your GitHub email>"
```

Then, **inside `mada`**:
```
rokit install          # answer "yes" to trust rojo-rbx/rojo
rojo plugin install    # prints nothing when it succeeds
```

**If `rojo plugin install` errors** ("Couldn't find registry keys", or similar on macOS): open Roblox Studio once, sign in, close it, and try again. If it still fails, install the plugin by hand:
1. Download **`Rojo.rbxm`** from github.com/rojo-rbx/rojo/releases, version **v7.6.1** (must match `rokit.toml`).
2. Studio → **Plugins** tab → **Plugins Folder** → put `Rojo.rbxm` there.
3. Restart Studio. A **Rojo** button appears in the Plugins tab.

## 4. The Roblox place

The game world lives in **one published Roblox place**, not in git.

- **Catlyn** (owner): Studio → **New → Baseplate** → **File → Publish to Roblox** as a private experience, *Làng Vọng (prototype)*. Then **Home → Game Settings → Permissions** (or **Collaborate / Team Create**) and add the other builder as a collaborator with edit access.
- **Collaborator:** Studio → **My Games → Shared With Me** (or **Collaborations**) → open the place.

Rules for working in the same place:
- **Only one person runs `rojo serve` into the shared place at a time.** Two people syncing different copies of `src/` overwrite each other. Pull the latest code before you connect.
- Save/publish the place at the end of every session.

## 5. Connect Claude Code to Studio (once per computer)

In Studio: **Assistant** (top right) → **…** → **Manage MCP Servers** → turn on **Enable Studio as MCP server** → under **Quick connect**, turn on **Claude Code**. Restart Studio.

If Claude Code isn't listed or doesn't connect, add it by hand, then restart Claude Code:
- macOS:
  ```bash
  claude mcp add --transport stdio Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP
  ```
- Windows (run from `cmd.exe`, not PowerShell):
  ```
  claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
  ```

Optional extras (Blender for free CC0 models, ElevenLabs for voice/music): `docs/MCP_SETUP.md` §5D and §6.

## 6. Every session

1. `git pull` in `mada`.
2. Open the place in Studio.
3. Terminal/PowerShell window 1, inside `mada`: `rojo serve` (leave it running). In Studio: **Plugins → Rojo → Connect**. You should see `ServerScriptService.Server`, `ReplicatedStorage.Shared`, `StarterPlayer.StarterPlayerScripts.Client`.
4. Window 2, inside `mada`: `claude`. Type `/mcp` and check that Roblox Studio is connected. Check the specialist subagents with `/agents`.
5. Tell Claude what to do. First time:
   > Read CLAUDE.md and follow it. Do milestone M0 only, then stop and tell me what you verified.

   After that:
   > Continue with the next milestone in docs/PROGRESS.md. Use the qa-tester subagent before marking it done.
6. At the end: **save/publish the place** in Studio, then `git push`.

## 7. Troubleshooting

| Problem | Fix |
| --- | --- |
| `claude` / `rokit` not recognized | PATH — see §1. Open a new terminal after changing it. |
| `rojo plugin install` fails | Open Studio once, retry, or install `Rojo.rbxm` by hand (§3). |
| Rojo won't connect | `rojo serve` must be running in `mada`; the plugin's port must match the terminal (default 34872). |
| `/mcp` doesn't show Roblox Studio | Studio open with the place loaded; MCP server enabled; restart Studio and Claude Code; try the manual command (§5). |
| Claude can't find the right place | Close other Studio windows; it picks a target with `list_roblox_studios`. |
| Code changes don't appear in Studio | Rojo disconnected — reconnect. Don't edit synced scripts inside Studio; Rojo overwrites them. |
| Push rejected (permission) | Deploy key without write access, or not added as a collaborator. |

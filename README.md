# gamebox

**Try a Windows game on Linux for a day before you buy it, without letting its installer anywhere near your files.**

`gamebox` runs a game's installer and the game itself inside a locked-down [bubblewrap](https://github.com/containers/bubblewrap) sandbox with Wine. The program sees an empty fake home folder, has no internet, and can't touch anything else on your system. When you're done, one command deletes it all.

```bash
gamebox new mygame ~/Downloads/MyGame          # folder with setup.exe, or the installer .exe itself
gamebox install mygame                         # run the installer, jailed + offline
gamebox play mygame                            # play, jailed + offline
gamebox shortcut mygame "My Game"              # optional: app launcher entry with the game's real icon
gamebox remove mygame                          # liked it? go buy it. Didn't? Gone.
```

## Why this exists

Modern games often look great for the first hour or two. The problems show up later: the story drags, the loop gets repetitive, performance falls apart in the open world, or the game only becomes playable after a week of tweaking settings and drivers. On Linux you also have to find out whether it runs well under Wine/Proton at all.

Steam's refund window is **2 hours of playtime within 14 days**. That's often not enough to judge a 60-hour game, and definitely not enough when part of those 2 hours goes into troubleshooting.

`gamebox` is for people who want to **evaluate a game properly and then buy the ones they enjoy**. Installers and builds from unofficial sources can contain malware, so they're treated as hostile by default.

## Disclaimer

- **Buy the games you play.** This project exists so you can make an informed purchase decision. It does not endorse piracy, and you are responsible for complying with copyright law and the terms of service where you live. If a developer offers a demo, use it.
- **No sandbox is perfect.** gamebox greatly reduces what a malicious program can do, but it is not a guarantee. See [Limitations](#limitations). Don't run anything you'd be devastated to be wrong about, and keep your system updated.
- Provided as-is, without warranty (MIT license).

## What the sandbox blocks

Every game and installer runs with:

| Malware tries to... | What happens |
|---|---|
| Steal browser cookies, Discord tokens, SSH keys, crypto wallets | Your real home folder is replaced by an empty fake one. Nothing to steal. |
| Send stolen data home, download more malware | No network at all: no TCP, no DNS. |
| Mine crypto | No network means it can't reach a mining pool, so it earns nothing. It dies when you quit. Use `GAMEBOX_CPUS` to cap cores. |
| Persist (autostart, systemd units, `.bashrc`, cron) | Those writes land in the fake home. `/usr`, `/etc` are read-only. |
| Spy on or inject into your other apps | Separate PID namespace: it can't see your processes. |
| Ask the desktop to launch things (D-Bus, `systemd-run`) | No D-Bus socket. |
| Encrypt/ransom your files | It can only reach its own sandbox folder. The installer source is read-only. |
| Keep running in the background | When the game exits, everything inside the sandbox is killed. |

Network is only turned on once, during `gamebox new`, while the sandbox is still empty. That step only runs trusted Wine tools to set up the prefix and download DXVK/VKD3D from their official releases. The installer and the game always run offline.

### Don't trust me: test it

```bash
gamebox test            # quick test in a throwaway sandbox
gamebox test mygame     # full test against a real sandbox, including from the Windows side via Wine
```

The test is a harmless "fake malware". It plants a secret file in your **real** home, then from inside the sandbox it tries to read it (with Linux tools and with a Windows program via Wine's `Z:` drive), open internet connections, resolve DNS, write to system folders and the installer source, see your processes, reach D-Bus, plant an autostart entry, and leave a process running after exit. Every check should say `PASS`:

```
Escape test against sandbox 'mygame' (all attacks should be blocked):
  PASS  cannot read files in your real home
  PASS  cannot even see your real home's contents
  PASS  no ~/.ssh, no browser profiles
  PASS  system folders are read-only
  PASS  installer source is read-only
  PASS  no internet (raw TCP blocked)
  PASS  no DNS
  PASS  cannot see or touch your other processes
  PASS  no D-Bus (cannot ask the desktop to run things)
  PASS  autostart/persistence lands only in the fake home
  PASS  background processes die when the sandbox exits
  PASS  Windows programs cannot read your real home via Z:
Result: 12 passed, 0 failed
```

## Install (Linux only)

Tested on **Arch Linux** (Hyprland/Wayland, Intel Arc, Mesa). It should work on any distro with bubblewrap and Wine, but other distros are untested.

**Dependencies (Arch):**

```bash
sudo pacman -S bubblewrap wine winetricks
# 32-bit Vulkan drivers (enable [multilib] first). Pick your GPU:
sudo pacman -S lib32-vulkan-intel     # Intel
sudo pacman -S lib32-vulkan-radeon    # AMD
sudo pacman -S lib32-nvidia-utils     # NVIDIA
```

**Install gamebox:**

```bash
git clone https://github.com/niiithish/gamebox
cd gamebox
./install.sh            # copies gamebox to ~/.local/bin (make sure it's on your PATH)
```

Or on Arch, build the package: `makepkg -si` (uses the included `PKGBUILD`).

## Usage

```
gamebox new <name> <repack-folder | installer.exe>   create a sandbox + Wine prefix
gamebox install <name>                 run the installer   (offline, jailed)
gamebox play <name> [Game.exe]         play the game       (offline, jailed)
gamebox shortcut <name> ["Title"]      add it to your app launcher
gamebox shell <name>                   open a shell inside the sandbox
gamebox run [--net] <name> <cmd...>    run any command inside the sandbox
gamebox test [name]                    prove the sandbox holds (harmless escape test)
gamebox list                           list sandboxes and disk use
gamebox remove <name>                  delete a sandbox completely
```

**Tips**

- **During install, choose a path on `C:`** (for example `C:\Games\MyGame`). `C:` lives inside the sandbox folder on your real disk. `R:` is the read-only installer source, so installing there fails.
- **Which exe:** `play` picks the game's `.exe` automatically (the largest one that isn't an uninstaller/redistributable) and remembers it. If it picks wrong: `gamebox play mygame TheRealGame.exe`.
- **Repacks with an `MD5` folder** (for example FitGirl) are checksum-verified during `new` using `md5sum`. No Windows tool needed.
- **Vulkan games** (for example RDR2, Doom) can use their native Vulkan renderer. DirectX games go through DXVK/VKD3D.
- **Where things live:** `~/Games/gamebox/<name>/`. Change it with `GAMEBOX_ROOT`.
- **Shortcut icons** are extracted from the game's `.exe` inside the sandbox, using a stdlib-only Python PE parser, so the untrusted file is never parsed on the host.
- **Cap CPU usage:** `GAMEBOX_CPUS=8 gamebox play mygame`.

## Limitations

Be honest with yourself about what's left:

1. **X11 access.** Wine draws through XWayland, so the game gets the X11 socket. A malicious program could read keystrokes from, or send input to, **other XWayland windows**. Native Wayland apps (most browsers and terminals on modern Wayland desktops) aren't reachable this way. On a pure X11 session, this exposure covers your whole desktop.
2. **Kernel / GPU driver exploits.** A sandbox escape through a kernel or driver bug is possible in theory. It's rare and usually reserved for high-value targets, but keep your system updated.
3. **Audio.** The PulseAudio/PipeWire socket is shared so the game has sound. That socket can technically be used to record from your microphone.
4. **It still uses your hardware.** A miner can burn CPU/GPU while the game runs. It can't get paid, and it stops when you quit.
5. **Online games won't work.** There's no network by design.

## Roadmap

- Wine's native Wayland driver, to drop the X11 socket entirely
- Optional audio-output-only mode (no mic)

## License

MIT

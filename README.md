# Lost Track

![WoW 3.3.5a (WotLK)](https://img.shields.io/badge/WoW-3.3.5a%20WotLK-a335ee?style=flat-square)
![Version](https://img.shields.io/badge/version-1.1.0-6f42c1?style=flat-square)

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [How it works](#how-it-works) • [FAQ](#faq)

Tracking that follows your target, automatically.

**Lost Track** is a tiny World of Warcraft (WotLK 3.3.5) addon for hunters. While you are in combat it keeps your tracking on the target's creature type: target a beast and it switches to **Track Beasts**, target a humanoid and **Track Humanoids** takes over. Drop the target or leave combat and tracking is turned off entirely. Out of combat it never touches your tracking.

## Features

- 🎯 **Tracking that matches the target** — beasts, humanoids, undead, demons, elementals, giants and dragonkin, straight from the target's creature type
- ⚔️ **In combat only** — out of combat your tracking is yours; clicking NPCs, changing targets or picking a tracking yourself changes nothing
- 🚫 **No tracking when the fight is over** — leaving combat, or losing the target in combat, turns tracking off. Nothing is restored, nothing is left running
- 🐺 **Hunters only** — on any other class it loads, says so and sits idle
- 🪶 **Featherweight** — one Lua file, no dependencies, nothing to configure
- ⚙️ **Toggles from chat** — `/lt on`, `/lt off`, `/lt status`

## Installation

Lost Track targets the WoW 3.3.5a client (interface `30300`).

1. In your WoW installation, make sure the `Interface/AddOns` folder exists.
2. Put the addon files inside a `LostTrack` folder there, for example by cloning this repository directly:
   ```bash
   git clone <your-repo-url> LostTrack
   ```
3. Start the client and enable **Lost Track** in the AddOns list on the character selection screen (use `/reload` if you're already logged in).

The result should look like this:

```text
WoW/
└── Interface/
    └── AddOns/
        └── LostTrack/
            ├── LostTrack.toc
            └── LostTrack.lua
```

> [!TIP]
> The addon ships **enabled**. It only does anything on a hunter, so it is safe to leave on for every character.

## Usage

Everything is done from the chat console; there's no configuration screen.

| Command | Description |
| --- | --- |
| `/lt on` | Enable automatic tracking |
| `/lt off` | Disable it (leaves the current tracking alone) |
| `/lt toggle` | Flip it on or off |
| `/lt status` | Show whether it is on, and what tracking is active now |
| `/lt` | Same as `/lt status`, plus the command list |

`/losttrack` is the long-form alias of `/lt`.

## How it works

When you enter combat, and whenever your target changes while in combat, Lost Track:

1. Reads the target's creature type with `UnitCreatureType("target")`.
2. Scans the tracking types available to you for the one naming that type — "Track Beasts" contains "Beast", and so on for the rest.
3. Switches to it if it isn't already active.

With no target, or a target whose creature type has no tracking, it turns tracking off (`SetTracking(nil)`). When combat ends, it turns tracking off as well. It never restores a previous tracking, and it does nothing at all out of combat — your own tracking choices and target clicks outside combat are left alone.

> [!NOTE]
> Creature types with no hunter tracking — critters, totems, mechanicals — leave you with tracking off while they are your target in combat.

## FAQ

**Is it on by default?**
Yes. `/lt off` disables it for that character.

**Are settings shared between characters?**
No — settings are saved per character (in the `WTF` folder), in `LostTrackDB`.

**Will it turn off Find Herbs / Find Minerals?**
Only in combat. Enter combat and tracking follows your target; leave combat and tracking is turned off. It never restores whatever you had before, so re-enable Find Herbs / Find Minerals yourself after the fight. Out of combat it never touches tracking.

**Does it work on non-English clients?**
The match relies on the client's tracking name containing the creature type's name. That works on English clients; other locales may name the two differently, in which case Lost Track leaves tracking alone rather than guessing.

**I'm not a hunter — why is this addon loaded?**
It does nothing on other classes and says so on load. Disable it in the AddOns list if you prefer it out of the way.

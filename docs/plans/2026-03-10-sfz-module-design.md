# SFZ Module Design

## Overview

New `move-anything-sfz` module providing SFZ format sample playback using the [sfizz](https://github.com/sfztools/sfizz) library. Separate module from the existing SF2 player.

## Architecture

- **Engine**: sfizz (BSD-2-Clause, C API, proven on ARM64)
- **Plugin API**: V2 instance-based
- **Format**: SFZ files with associated sample directories

## Instrument Organization

- `instruments/` directory on device
- Each subfolder = one instrument (folder name = display name)
- Multiple `.sfz` files within a folder = presets
- Shift+L/R switches instruments, preset nav switches .sfz files within

## File Structure

```
move-anything-sfz/
├── src/
│   ├── dsp/
│   │   ├── sfz_plugin.c        # Plugin API V2 wrapper
│   │   └── third_party/
│   │       └── sfizz/           # Git submodule
│   ├── module.json
│   ├── ui.js
│   └── help.json
├── scripts/
│   ├── build.sh                 # Docker + CMake cross-compile
│   ├── install.sh
│   └── Dockerfile
├── release.json
└── CLAUDE.md
```

## Parameters

| Parameter | R/W | Description |
|---|---|---|
| instrument_index | RW | Current instrument folder index |
| instrument_count | R | Number of instrument folders |
| instrument_name | R | Current folder name |
| instrument_list | R | JSON array of folder names |
| preset | RW | Current .sfz index within instrument |
| preset_count | R | Number of .sfz files in instrument |
| preset_name | R | Current .sfz filename (sans ext) |
| gain | RW | Output level 0.0-2.0 |
| octave_transpose | RW | -4 to +4 |
| state | RW | Full JSON state for save/restore |

## Build

sfizz built from source via CMake in Docker, linked as static library into dsp.so.

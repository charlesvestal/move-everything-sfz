# CLAUDE.md

## Project Overview

SFZ sample player module for Move Anything. Uses sfizz library (BSD-2-Clause).

## Build Commands

```bash
./scripts/build.sh      # Build with Docker (cross-compiles sfizz + plugin)
./scripts/install.sh    # Deploy to Move
```

## Structure

```
src/
  module.json           # Module metadata
  ui.js                 # JavaScript UI
  help.json             # On-device help
  dsp/
    sfz_plugin.c        # Plugin wrapper around sfizz
    third_party/
      sfizz/            # Git submodule - sfizz library
```

## Instrument Organization

- `instruments/` directory contains instrument folders
- Each folder = one instrument (folder name = display name)
- Multiple .sfz files within a folder = presets
- Shift+L/R switches instruments, preset nav switches .sfz files

## DSP Plugin API

Standard Move Anything plugin_api_v2:
- `on_load()`: Initialize sfizz synth, scan instruments
- `on_midi()`: Process MIDI input via sfizz
- `set_param()`: Set instrument_index, preset, gain, octave_transpose
- `get_param()`: Get instrument/preset info, state
- `render_block()`: Render 128 frames stereo via sfizz

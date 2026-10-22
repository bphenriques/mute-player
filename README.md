# mute

A music and audiobook player for handhelds: offline, minimal, and quick to find your way in. It
plays music by artist, album, genre, year or folder, with lyrics, an equalizer and gapless
playback; and audiobooks with chapters, bookmarks, speed and a sleep timer.

mute is a set of crates a host builds into itself. [slot](https://github.com/bphenriques/slot),
a frontend for the Anbernic RG SP, is the first.

| Crate | What it is |
|---|---|
| `mute-audio` | Plays files: decoding, resampling, speed, gain, gapless, ALSA. |
| `mute` | The player's behaviour, and every screen as data, tested without a device. |
| `mute-ui` | The kit that draws a screen's parts, as a list of rectangles and pictures. |
| `mute-view` | A screen made into the kit's faces each frame, for any host to show. |

`AGENTS.md` holds the rules the code keeps; `music/README.md` what a listener's card holds.

## Build and test

With Nix, `nix-shell` has the tools: Rust, as `rust-toolchain.toml` pins it, and CMake, to build
libopus.

```sh
nix-shell --run "cargo test --workspace"
```

## The screens

Each screen, light and dark, drawn without a device into `target/shots/`, to look at a change:

```sh
nix-shell --run "cargo test -q -p mute-view --test shots -- --ignored"
```

## Licence

GPL-3.0-or-later (`LICENSE`). SoundTouch (`crates/mute-audio/soundtouch`) is LGPL-2.1; the fonts
in `crates/mute-ui/assets` are under the OFL and MIT, their licences beside them.

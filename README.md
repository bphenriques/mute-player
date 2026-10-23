# mute

> [!WARNING]
> **Experimental, and built with AI assistance.** I have experience in the field and did my best
> to follow the right patterns, but I am not an expert on this, and in the end I wanted a fast,
> clean music player running in [slot](https://github.com/bphenriques/slot). It may be unstable:
> expect rough edges, and things that break or change between versions.
>
> Don't expect much support. I'm happy to help where I can, and happier still if someone forks
> it and carries on the work (I'd gladly use the mature fork!) :)

What I focused on:

- **Pocket use.** With the screen off, the shoulders skip or seek and the triggers play, pause
  or mark a place in a book, all found by feel; holding two shoulders locks the keys, or the
  screen going off can lock them, so nothing changes in a pocket. I haven't seen this in a
  handheld player before.
- **Performance.** It's a battery device: nothing runs while idle, and the screen is drawn only
  when something on it changes.
- **A decoupled design.** The player is crates any host builds in; slot only hosts it, so it
  isn't tied to slot.
- **Minimal and modern.** Familiar keys, one kind of row, quiet animations, light and dark.

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

# Agents

mute is a music and audiobook player for handhelds, made of crates a host builds into itself:
slot (a handheld frontend) is the first. `README.md` says how to build, test and look at the
screens; these are the rules.

## Shape

Layers, each knowing only the one below it:

| Crate | Owns | Never |
|---|---|---|
| `mute-audio` | Playing files: decode, resample, speed, gain, gapless, ALSA. `Command` in; its `Status` (state, place, length, whether still heard) read each frame; `Event` out only for what happens (an end, going on into the next, a failure, the device lost, the player gone); behind `Handle`. | Albums, books, queues, screens. |
| `mute` | The player's behaviour: library, queue, books, lyrics, keys, settings, and every screen as data (`Screen`). Every word in `text.rs`; every file it keeps on the card in `store/`. | Drawing, textures, colours. |
| `mute-ui` | The kit that draws a `Screen`'s parts: faces, list, Now Playing, text view, `tween`, every colour in `theme.rs`; its own fonts and hints, and a draw list of its own for any host. | Behaviour, state, the frontend. |
| `mute-view` | The music screen as the kit draws it, for any host: each frame's `Screen` into the kit's faces, the textures kept, the motion (`motion.rs`); and the screenshot tour (`tests/shots.rs`). | Hosts: a device, a window, slot. |
| A host (slot's `music_faces` and `app::music`) | Its own: the view's faces into its textures and draws; its buttons into `mute`; the screen off, power and volume. | Decisions the layers above make. |

`Screen` is the only contract between behaviour and drawing. New behaviour goes in `mute` with
tests; new looks go in the kit.

## Rules

- Simple, idiomatic, succinct; YAGNI. Do what familiar players do (Apple Music, Spotify,
  Symfonium, Smart AudioBook Player, Rockbox).
- `Music` (`mute/src/music/`) is state and a shell around it. What happens comes in as
  messages (the player's events, the scan, the worker) or keys; the state acts and asks for
  what it needs outside as an `Effect` (tell the player, write a file, set a key, give the
  worker a job), which the shell carries out after. The state never touches the card or a
  thread, and never waits: a slow read (pictures, lyrics, chapters) is a worker job.
- State is plain values; only `mute/src/store/` reads and writes what is kept on the card,
  each file a `Kept` type (`encode`/`decode`, tested on text) written off the frame loop by the
  one `Store`. The library scan, its cache and the album pictures keep their own files.
- No literal words outside `mute/src/text.rs`, no literal colours outside
  `mute-ui/src/theme.rs`, no motion outside `mute-ui/src/tween.rs`'s curve and
  durations.
- Keys: a tap does one thing, a hold another, hinted "Tap (Held)"; a START menu holds only what
  no key does. Each screen's keys are one table, as niri declares its binds
  (`screens/binds.rs`): how each acts while down, and its hint, in `text.rs`'s `Word`s. The
  legend is chosen in one place (`screens::legend`), and both the hints shown and the keys'
  modes are read from its table, so they cannot disagree; tests hold the tables to one meaning
  a key, and to hints that say a hold only of a key that holds. What a key then does is the
  screen's `press` and `held`. A key the hints leave out goes in Settings › Help (`text.rs`'s
  `KEYS`); `music/README.md` says only what the screens cannot.
- Rust as the community writes it, not a house style: rustfmt and clippy as they are, `if` over
  a `match` on a bool, and a `// SAFETY:` comment on every `unsafe` saying why it holds. The
  lints keep it so (`[lints.clippy]` in every crate).
- Comments read as plain sentences saying what something is for, in the existing voice.
- Every behaviour change comes with a test (see Tests).
- A battery device: nothing polls while idle, nothing works harder than it must. The music
  screen is drawn only when a frame would show something new (`music/DRAWING.md`), so a
  `Screen` says only what is seen, never finer, and the `work_budget_…` tests hold it so.

## Tests

Behaviour is tested on the state and what it gives out, never on drawing: the kit only draws a
`Screen`, so a `Screen` is what a test reads. As niri tests its layout:

- **The music through its face** (`mute/src/music/tests.rs`, `Rig`): a card made for the
  test, keys and the player's answers in, the `Screen` and what the player was told out. The
  player is a fake that does as told; the time is the test's own, moved on, never slept on. The
  state is checked whole after every step, and a run of random keys must keep it so.
- **What the state asks for**: its `Effect`s are its output as much as the screen, so a test
  may read them before the shell carries them out (`Music::frame`, then `out`).
- **The parts on their own**: pure functions and plain types beside their code, or by area in
  `mute/src/tests/` (browsing, the queue, books, the library, settings), inside the
  crate, so the crate shows a host only its face (`lib.rs`, pinned by a rule).
- **The player** (`mute-audio/tests/player.rs`): WAVs made in the test, played into `Capture`,
  or into `Device`, which plays them out against a clock as a real one does.
- **The rules** (`mute/tests/rules.rs`): this file's rules, checked on the code.

Nothing is shared between tests: each makes its own card, clock and player. Code that reads the
world (a clock, a device, the card) is kept thin, the decisions it makes pulled out as pure
functions and tested there.

## Threads

State has one owner, and threads share no mutable state, only messages:

- **One owner.** Each piece of state belongs to one thread, which alone changes it. `Music` is
  the frame loop's; what plays is mute-audio's writer's; the store, the scan and the worker own
  theirs.
- **Messages down, facts up.** A thread is asked by message (`Command`, `Effect`, a job) and
  tells what happened by message (`Event`, `Found`, `Done`), on channels, in order. The UI is
  the same one way: the state builds a `Screen` value each frame and the kit only draws it; keys
  come back as messages, never by the view changing state.
- **What others read is a snapshot.** A value read across threads (the player's `Status`) is one
  `Copy` value the owner replaces whole, behind one lock: never several atomics or flags for one
  thing, which a reader can catch half old, half new.
- **Slow work goes to a thread of its own**, not the owner's: the engine opens files so the
  writer never waits on the card; the worker reads pictures and lyrics so the frame never does.
  What comes back carries what it was asked under (the library's generation), so a late answer
  is dropped, not raced.
- **Stopping is said**, when an inbox has other senders than the one letting go (`In::Quit`
  when a `Handle` is dropped); no thread is left running.
- **Timing is tested against a clock**: the player's status is held to what a device model has
  really played (`mute-audio/tests/player.rs`, `Device`), not to what was written.

## Check before you finish

```sh
nix-shell --run "cargo fmt --all"
nix-shell --run "cargo clippy --workspace --all-targets -- -D warnings"
nix-shell --run "cargo test --workspace"
```

Among the tests, `mute/tests/rules.rs` checks this file's rules on the code (words, colours,
motion, clocks, shared state, threads, layers); a line that must break one is named there, with
why, never quietly. A change that shows is looked at in the screenshots (`README.md`).

Never push, tag or commit without the owner's go; commits authored as
`4727729+bphenriques@users.noreply.github.com`, no other address.

## Editing

Back a file up before splicing it by line numbers or patterns; check the result is not empty
before copying it over. There is no Python on the host. With perl, use `~` as the delimiter, and
note that `\x27` comes out literally from shell heredocs.

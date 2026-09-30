# Design spike: "Merge 1 · Gather and fuse"

Flutter recreation of `docs/design/spike-artifact/Main.dc.html` (390x844,
scaled to fit). Delete this folder plus `assets/fonts` and the font entries in
`pubspec.yaml` to remove the spike.

Files: `spike_tokens.dart` (all literals), `merge_model.dart` (port of the
artifact script), `merge_scene_painter.dart` (all drawing), `merge_screen.dart`
(ticker, tap target), `nav_button.dart`.

## Motion inventory (artifact -> Flutter)

| Motion | Duration / rate | Delay | Curve |
|---|---|---|---|
| Cell slide idle<->run (`pos`) | exponential approach, 5/s (~0.6 s to settle) | none | `smooth()` (smoothstep) applied to `pos` |
| Wave tilt on slide | spring k=90, c=9, gain 3.4, clamp ±13 | none | spring |
| Fill wave | continuous, phase = 2.2 rad/s; flood wave 0.8 rad/s | none | sine |
| Cell -> unit slot flight | 0.8 s | none | smoothstep on progress; quadratic Bezier path; size shrink smoothstep over first 62.5% |
| Cell slides to idle while flying | first 0.4 of flight | none | smoothstep |
| Fuse (10 units -> ten, 6 tens -> hour) | 0.8 s | sources move 0-55%, merged piece fades in 40-55%, grows 40-100%, sources fade 50-80% | smoothstep per phase |
| Block re-layout slide | 450 ms | none | `Curves.ease` (CSS `ease`, cubic-bezier .25,.1,.25,1) |
| Cell press scale .97 | 180 ms | none | `Curves.ease` |
| Stream wiggle / bead dash travel | 3.2 rad/s; bead 150 px/s, period 62 px | none | linear |
| Ground splash sparks | life 0.78 s, gravity 430 | staggered n/N of life | ballistic |
| Catch sparks | life 0.55 s | staggered | ballistic |
| Stain / seep / ripple | 1.7 s / 1.3 s / 1/0.7 s cycles | staggered | linear |
| Splash <-> catch crossfade (`gs`) | exponential approach, 8/s | none | none |
| Undo (let go < 1 min) drain | exponential approach, 2.5/s | none | none |

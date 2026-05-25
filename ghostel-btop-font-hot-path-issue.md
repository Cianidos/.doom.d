# Ghostel: Unicode TUI redraw freezes Emacs due to font metric hot path and GC churn

## Summary

Running a Unicode-heavy TUI such as `btop` inside Ghostel can make Emacs freeze
or sit at 100% CPU. The freeze is reproducible when `btop` updates quickly
(`100ms` update interval was enough on the affected setup). Profiling shows the
hot path is Ghostel redraw, specifically native renderer callbacks into Emacs
font APIs for glyph adjustment, amplified by frequent automatic GC.

## Environment

- OS: Linux
- Emacs: 30.2, graphical frame
- Config: Doom Emacs
- Ghostel: 0.27.0, straight checkout at `~/.emacs.d/.local/straight/repos/ghostel`
- Font: Iosevka, reported frame font `-UKWN-Iosevka-light-normal-normal-*-32-*-*-*-d-0-iso10646-1`
- Example terminal size during repro: approximately `238` columns, `29-50` rows
- TUI: `btop`, update interval `100ms`
- GCMH active: `gcmh-low-cons-threshold = 800000`, `gcmh-high-cons-threshold = 67108864`

## Reproduction

1. Start Emacs with Ghostel available.
2. Open a Ghostel buffer.
3. Run `btop` inside Ghostel.
4. Set `btop` update interval to `100ms`.
5. Let the TUI redraw continuously.
6. Observe Emacs responsiveness and CPU usage.

## Expected Behavior

Ghostel should remain interactive while a TUI redraws at a moderate refresh rate.
CPU usage may rise, but Emacs should not freeze or spend most time in GC/font
metric callbacks.

## Actual Behavior

Emacs becomes sluggish or freezes, with the Emacs process consuming high CPU.
Interactive commands and redisplay can be delayed significantly.

## Profiled Hot Path

CPU profiler sample during the freeze:

```text
Automatic GC                                                72%
server-process-filter                                       27%
  server--process-filter-all-pending
    server--process-filter-1
      server-execute-continuation
        accept-process-output
          timer-event-handler
            ghostel--delayed-redraw
              ghostel--redraw
                my/ghostel-preserve-evil-point-a
                  native module renderer
                    query-font                              26%
                    font-get-glyphs
                    font-at
```

A counter sample over a 2s window, before mitigation, showed a single Ghostel
redraw causing approximately:

- `2564` calls to `font-at`
- `2564` calls to `query-font`
- `2564` calls to `font-get-glyphs`
- `16` automatic GCs taking `1.83s` total during the sample

This makes the renderer/font path and GC dominate wall time.

## Suspected Cause

In `src/Renderer.zig`, Ghostel marks cells for glyph adjustment when a grapheme
cluster is present or when the codepoint is greater than or equal to a default
font coverage threshold:

```zig
if (self.graphemes.items.len > 1 or self.graphemes.items[0] >= adjustment_threshold) {
    try self.adjust_cells.append(...);
}
```

For every adjusted cell, `adjustGlyph` calls back into Emacs:

```zig
const font = env.f("font-at", .{ start_val, window });
const font_info = env.f("query-font", .{font});
const glyphs = env.f("font-get-glyphs", .{ font, start_val, end_val });
```

This is expensive for Unicode-heavy terminal frames. `btop` uses many box,
block, and braille graph characters, so each frame can enqueue thousands of
adjustment cells. On the affected system, the default Iosevka font already
reports coverage for representative btop glyph ranges:

- Box drawing `U+2500`: covered
- Block element `U+2588`: covered
- Braille `U+2800..U+28FF`: covered

So many fallback/glyph-adjustment checks appear to be conservative false
positives rather than actual font fallback cases.

## Workaround Tested in User Config

A Doom config workaround made the repro responsive immediately:

- Cache `query-font` results dynamically for the duration of one
  `ghostel--redraw` call.
- Temporarily raise `gc-cons-threshold` during Ghostel redraw only.

After this, the same `btop` session remained responsive even at a `100ms`
update interval.

## Proposed Fix Direction

Potential upstream fixes:

- Add per-redraw font metric caching in Ghostel so repeated `query-font` calls
  for the same font are not repeated thousands of times per frame.
- Cache glyph adjustment decisions/metrics in the native renderer, keyed by
  font and character/grapheme where safe.
- Refine the adjustment predicate so default-font-covered Unicode characters
  do not go through fallback adjustment unnecessarily.
- Optionally add a user-facing switch to disable or reduce expensive glyph
  adjustment for users who prefer terminal redraw performance over perfect
  fallback glyph fitting.

## Follow-Up Finding

An attempted native fast path that skipped glyph adjustment for single-width
characters rendered with the default font made btop fast but reintroduced visual
artifacts: shifted borders and glitchy TUI lines. That suggests Ghostel's
current glyph adjustment is still needed even when Emacs chooses the default
font for Unicode box/block/braille characters.

The safe patch direction is therefore narrower:

- Keep the existing glyph adjustment behavior.
- Cache `query-font` results for the duration of one redraw.
- Raise GC thresholds dynamically only around native redraw.

A fresh Emacs session with that narrower patch loaded showed no visible btop
artifacts, while a 2s sample dropped `query-font` calls to single digits and
kept GC time low.

## Notes

The issue is not caused by Evil point preservation advice in the local config.
During btop's alt-screen mode, that advice falls through to the original
`ghostel--redraw`; the profiler showed the cost inside the native renderer's
font metric calls and automatic GC.

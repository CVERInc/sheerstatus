# Changelog

All notable changes to sheerstatus are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

Entries for 0.2.0 – 0.6.5 were reconstructed from the commit history on
2026-07-27; the file had been left at 0.1.0 while the script reached 0.6.5.

## [0.8.0]

### Added — `--json` carries the verdict

The tool exists to produce a verdict. `--json` shipped without one: eleven
readings and no answer. A consumer had to re-derive the thresholds — and
whichever way they rounded, the two would eventually disagree about the same
machine.

```json
"verdict": { "memory": "warn", "storage": "warn", "battery": "pass" }
```

The words are the family's closed badge set. The reason it was missing is the
reason it took a refactor rather than a `printf`: **which tier this machine is
in** and **how to say it** were the same code, so there was nothing for a second
renderer to ask. `verdict_memory` / `verdict_storage` / `verdict_battery` answer
the question now; the report lines and the JSON both ask them, and cannot drift.

A battery the machine can't read returns `unknown` — not a guess, and not a
missing key.

### Fixed — readings are numbers, or `null`

`"battery_health_pct": "89"` sat beside `"swap_used_mb": 2889`: the same kind of
fact, two types. And an unavailable reading was the **string** `"N/A"`, which
any consumer doing arithmetic turns into a silent zero — the same class of lie
as a size column holding a count.

Numbers are numbers now, and a reading this machine can't take is `null`.

### Fixed — `temp_max_c` was a number wearing a unit

`get_temp_max` returned `42 °C` while its two siblings returned bare numbers, so
the display special-cased it and `--json` emitted `"42 °C"` under a field named
`_c`. The getter returns a number; the unit is added where the other two add it.

### Changed — the JSON test asserts the product

It checked that `"version":` appeared, which proved only that the heredoc ran.
It now asserts the verdict is present and inside the closed set, and that no
reading is the string `"N/A"` — verified against a deliberately regressed tool.

## [0.7.0]

### Fixed — the 9-locale claim was true of the labels and false of the sentences

The README promised nine locales. The nouns delivered: `Storage`, `Batería`,
`メモリ`. The **sentences** were four — every verdict line and the entire
recommendation section fell through to English for `es-ES`, `de-DE`, `fr-FR` and
`pt-BR`, so a Spanish reader got `[ PASS ] Batería: Health good (89%)`.

It survived because of how it was built, not because someone skipped a string:
the recommendation was one *code block* per language, roughly eighteen lines
each, so adding a language meant copying branching logic rather than adding a
sentence. Those sentences now live in `t()` beside the other keys, and the
function that decides *which* sentence to say runs once for all languages.

Each variant is a whole sentence rather than a stem plus a suffix — gluing
fragments only works in languages that share English's word order.

### Fixed — Simplified Chinese was reading Traditional Chinese

`zh-Hans` shared a branch with `zh-TW`, so a Simplified reader met 硬體 / 記憶體
/ 硬碟 — Taiwan terms — throughout the report. The two are split wherever the
words actually differ (硬件 / 内存 / 硬盘) and left shared where they genuinely
coincide (已用, 容量).

Also: `pt-BR` was sharing Spanish's `Memoria`. Portuguese is `Memória`.

### Fixed — French colons, everywhere at once

French sets a space before a high punctuation mark; `Mémoire:` reads to a French
eye roughly the way `Memory ：` reads to an English one. The colon rule was
written out inline in `pad_row` **and** again inside every verdict line, which is
how it ended up right in one place and wrong in the other. It is one key now.

### Added — a gate that can actually see a missing translation

The obvious check — *does `t <key>` return something in every locale?* — cannot
see a partial translation at all: a missing branch falls through to `*)` and
returns English, which is very much something. That check would have passed on
every version above.

The new one reads the shape. A key whose body opens `case "$SS_LANG"` is
claiming per-language text, so every locale must appear as a branch label; a key
with no such case (a badge, a glyph) is deliberately universal and is skipped.
The distinction is structural, so there is no exception list to maintain. Hence
`en-US|*)` throughout `t()`: one label meaning both "English" and "any language
we haven't heard of" is precisely what made the gap invisible.

### Added — CI, on both platforms the README promises

ShellCheck, syntax, the CVER CLI signet lint, a CHANGELOG-version gate, and the
local suite on **ubuntu-latest and macos-latest**. The tool has real `/proc` and
`/sys` paths; a cross-platform claim that only ever runs on one platform is the
same kind of unbacked promise as a nine-locale claim with four locales in it.

### Changed — one language across the CVER command line

`▸` group headers, `·` as the only bullet, no horizontal rules, and badges
padded to eight columns and never translated — the CVER CLI signet
(`signet/packages/cli`), shared with sheersweep and clikae.

A row that opens with a badge drops its bullet: the badge is already the row's
mark, and it is fixed-width, so it gives the column its left edge without help.
`[ CRIT ]` joined the family's closed badge set **because of this tool** — the
set was derived from one that acts, and a tool that measures needs the rung.

The local suite speaks the same language, and counts its own checks: it used to
end with a hard-coded `(10/10)` while actually running thirteen.

## [0.6.5]

- Future-proofed the memory verdict with a dynamic ratio of total RAM instead of
  fixed thresholds.
- Fixed a JSON injection path, Linux CPU-name whitespace, and a green-verdict
  line that was factually wrong.
- Linux battery detection now keys on device *type* rather than a name prefix.
- Raw battery capacity is shown; rows with no reading are hidden rather than
  printed as `N/A`.

## [0.6.3] – [0.6.4]

- Complete UI overhaul, then a further pass toward extreme minimalism.
- Fixed a format glitch where an `N/A` live temperature still got a `°C`.

## [0.6.0] – [0.6.1]

- Battery sections hide themselves on battery-less devices.
- Hardened against NFS hangs (`df -hl`), smarter Linux target-mount selection,
  and multi-battery aggregation.
- Added the zero-dependency local self-test suite (`test.sh`).

## [0.5.0] – [0.5.2]

- Full macOS **and** Linux support, with the copy generalized to match.
- ARM64 Linux sysfs support, verified on PineNote hardware.

## [0.4.0]

- Three-pillar, status-first verdict and streamlined typography.

## [0.3.0]

- Zero emoji, CJK grid alignment, non-verbose verdicts.

## [0.2.0]

- Dynamic specs, battery health, de-duplicated output, sheersweep footer.

## [0.1.0] - 2026-07-26

### Added
- Initial public release of `sheerstatus`.
- Zero-dependency single-file Bash implementation.
- Multi-language i18n support (`zh-TW`, `en-US`, `ja-JP`, `zh-Hans`).
- Instantaneous Swap usage and compressed memory auditing (`sysctl vm.swapusage` & `vm_stat`).
- Battery and thermal sensor reader with lifetime temperature history (`ioreg`).
- Objective, neutral verdict classifier.
- Support for `--json`, `--version`, and `--help` CLI flags.

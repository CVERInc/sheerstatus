# Changelog

All notable changes to sheerstatus are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

Entries for 0.2.0 – 0.6.5 were reconstructed from the commit history on
2026-07-27; the file had been left at 0.1.0 while the script reached 0.6.5.

## [0.10.1]

### Fixed — one partition was reported as the whole machine

`System Specs: Pine64 PineNote v1.2 (RAM 3 GB · Storage 15 GB)` — on a device
with 115 GB. The storage figures follow the **tightest** local filesystem, which
is the right thing to verdict on (that PineNote's `/` has 7.8 GB left while its
`/home` has 73), but the specs line presents its number as a property of the
machine. Measurement of a partition, printed as a fact about hardware.

The mount is named when there is more than one local filesystem to confuse it
with: `Storage 15 GB (/)`. Nothing is added on a machine where `/` and `$HOME`
share a device — every Mac, and most Linux boxes — because a suffix that never
varies is noise, and a test holds that line.

`--json` is untouched: `ssd` stays a bare size, so it and `disk_used_pct` still
describe the same filesystem.

## [0.10.0]

### Fixed — on a machine that cannot swap, the RAM verdict could only ever say PASS

`verdict_memory` read exactly one number: swap in use. The PineNote's kernel is
built with `CONFIG_SWAP is not set` — no swap subsystem at all, which is why
`swapon` returns 255 there and a swapfile is as impossible as zram. `SwapTotal`
is 0 for a **structural** reason, so it can never move, and reading that 0 as
"ample" printed this on a 3.6 GB machine with no cushion whatsoever:

```
[ PASS ] RAM: Ample (Swap 0 B).
```

It would have printed the same line with 50 MB left and the OOM killer one
allocation away. A gauge whose needle is welded to green is not a gauge.

Linux now also reads **`MemAvailable`** — the kernel's own estimate of what it
can still hand out without swapping, which is the one figure that stays honest
whether or not swap exists. Both instruments are consulted and **the worse answer
wins**: a machine is in trouble by either road — already paying for swap, or
about to run out with none — and reporting the flattering one is how this bug
happened in the first place.

The sentence follows the instrument that saw the trouble, because the old words
are false on such a machine: "started using disk as virtual memory" is not
something a kernel without swap can do. And when there is no swap at all, the
verdict names the consequence, since it differs from every other machine this
tool runs on:

```
[ CRIT ] RAM: Almost no headroom (only 5% of RAM still allocatable). This kernel
         has no swap, so pressure ends in a killed process, not a slowdown.
```

macOS is untouched — there the compressor/swap pair is the right instrument, and
`mem_available_pct` is `null` rather than a number invented to fill the column.

### Added — `--json` carries `mem_available_pct`, and the script can be sourced

The new reading joins the payload, `null` where the platform has no such figure.
And `SHEERSTATUS_LIB=1` now loads the script as a library without running the
audit, which is what let the tiers be tested at all: a verdict you can only reach
by owning a machine that happens to be in the tier you want to check is a verdict
nobody tests. Ten cases now cover the tiers in both directions, including the
exact welded-gauge case — swap silent, headroom at 5%, answer `crit`.

*Found by running 0.9.0 on the PineNote itself — the machine whose `rk817-battery`
is the reason the Linux path exists.*

## [0.9.0]

### Added — `npx sheerstatus`, which is the original idea, not a departure from it

The concept was always "nothing to install." The README's Quick Start then asked
you to `git clone` a repository and `cd` into it — which is *more* installation
than the thing it was avoiding: a directory that stays, that you have to `git
pull`, sitting on your disk between the two times a year you audit a machine.

`npx sheerstatus` leaves nothing behind. It is the first channel that actually
keeps the promise, and the tool it hands you is byte-for-byte the same single
Bash file.

**npm is a delivery channel here, not a dependency.** `bin` points straight at
the script — never a JS launcher that spawns it, because "the auditor you can
read" must not quietly come to mean reading two languages across a process
boundary. No `dependencies`. No install-time script: `preinstall` / `install` /
`postinstall` are the one npm hook that runs on a stranger's machine, and this
tool's whole claim is that nothing runs until you run it. `test.sh` now fails
the build if one ever appears.

It also makes the trust story checkable by someone who has never seen the repo:
the published bytes are readable in a browser at
[unpkg.com/sheerstatus/sheerstatus](https://unpkg.com/sheerstatus/sheerstatus),
versioned and immutable, with an integrity hash. A tarball on a Homebrew tap
gives you no such thing.

The single file stays canonical, and `curl` stays a first-class way to get it —
`npx` needs Node, and the Linux servers this audits often have none.

### Added — the version is now checked in two places, so it can't drift in one

`package.json` and the script both carry the version. A "these must match" that
nothing verifies is a wish, and it fails quietly: npm serves 0.9.0 while
`sheerstatus --version` tells every user 0.8.0. `test.sh` compares them, and
also checks that what `files` promises to ship exists and is executable — an
unreadable bin bit is a broken `npx` for everyone, discovered by strangers.

### Fixed — the agent guide had rotted against the tool

`AGENTS.md` said **macOS only** while the script had grown a full Linux path
(`/proc`, `/sys`, and the `type=Battery` scan that reads a PineNote's
`rk817-battery` where a hardcoded `BAT*` prefix finds nothing), and described
the verdicts as `🟢/🟡/🔴` when the tool prints `[ PASS ]` / `[ WARN ]` /
`[ CRIT ]` and has for six versions. Both statements were true once. A stale
guide reads exactly like a current one — and this one was about to be handed a
`package.json` declaring `"os": ["darwin", "linux"]`, which would have made the
repo contradict itself in a file npm publishes.

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

# sheerstatus

**the zero-daemon hardware & pre-upgrade auditor you can read.**

`sheerstatus` is a single-file POSIX Bash executable that audits your Mac or Linux system metrics (RAM, Swap, Storage capacity, Battery health, BMS thermals) and outputs a zero-fluff, hard-data pre-upgrade verdict.

- **Zero Daemons**: No background services running 24/7. Run it on-demand when contemplating a hardware upgrade or debugging lag.
- **Zero Dependencies**: Pure POSIX Bash using native `sysctl`, `df`, `ioreg` (macOS), and `/proc`, `/sys` (Linux).
- **Cross-Platform**: Supports macOS & Linux natively out-of-the-box.
- **9 Locales Supported**: `en-US`, `ja-JP`, `zh-TW`, `zh-Hans`, `ko-KR`, `es-ES`, `de-DE`, `fr-FR`, `pt-BR`.
- **Zero Decorative Emojis**: Clean, professional ASCII status indicators (`[ PASS ]`, `[ WARN ]`, `[ CRIT ]`), padded to a fixed width and never translated.

---

## Output Demo

```text
sheerstatus Hardware Health Audit
   · System Specs: Apple M2 (RAM 16 GB · Storage 245 GB)

▸ Storage
   · Used: 205 GB

▸ Battery
   · Capacity: 5107 / 5760 mAh
   · Live Temp: 30.4 °C
   · Avg Temp: 24.2 °C
   · Max Temp: 42 °C
   · Cycle Count: 136

▸ Audit Verdict
   [ CRIT ] RAM: Heavy virtual memory thrashing will degrade disk lifespan (Swap 3.15 GB).
   [ CRIT ] Storage: Severe storage deficit (95% used).
   [ PASS ] Battery: Health good (88%).

▸ Recommendation
   · If lag persists, consider upgrading RAM and storage on your next machine.
   · Consider using sheersweep to free up disk space.
```

A machine with no battery — a Mac mini, a Linux server — prints no Battery section
and no battery verdict, rather than a row of `N/A`.

---

## Quick Start

```bash
# Run it without installing anything
npx sheerstatus

# The same audit as JSON, for automation
npx sheerstatus --json
```

On a Mac you'd rather keep it around on, there's a tap:

```bash
brew install CVERInc/sheerstatus/sheerstatus
```

Or take the file itself — no package manager involved, nothing left behind but
the one script you can read:

```bash
curl -fsSL https://raw.githubusercontent.com/CVERInc/sheerstatus/main/sheerstatus -o sheerstatus
chmod +x sheerstatus
./sheerstatus
```

**npm is a delivery channel here, not a dependency.** What it hands you is the
same single Bash file — no `node_modules`, no install-time script, nothing that
runs until you run it. You can read the exact published bytes in a browser at
[unpkg.com/sheerstatus/sheerstatus](https://unpkg.com/sheerstatus/sheerstatus)
before you ever execute them. `npx` itself needs Node; the script does not, so on
a Linux box without Node, take the `curl` line.

The JSON carries the **verdict**, not just the readings — the same three words
the report prints, so a monitor never has to re-derive the thresholds and drift
from the tool about the same machine:

```json
{
  "swap_used_mb": 2889,
  "mem_available_pct": null,
  "disk_used_pct": 93,
  "battery_health_pct": 89,
  "verdict": { "memory": "warn", "storage": "warn", "battery": "pass" }
}
```

A reading this machine can't take is `null`, never the string `"N/A"` — a
consumer doing arithmetic on `"N/A"` gets a silent zero. A battery with no
reading verdicts as `"unknown"` rather than being guessed at or omitted.
`mem_available_pct` is Linux-only for the same reason: it is `/proc/meminfo`'s
own figure, and macOS has no equivalent to borrow.

**Two instruments, worse answer wins.** Swap in use says you are already paying;
`MemAvailable` says how much is left to hand out. A kernel built without swap —
the PineNote's is — pins the first at zero forever, so a verdict that reads only
that can never leave `pass`. Both are consulted, and the memory verdict follows
whichever one saw the trouble.

---

## Command Options

| Option | Description |
| :--- | :--- |
| `sheerstatus` | Print human-readable 3-pillar hardware health & audit verdict |
| `sheerstatus --json` | The same audit as JSON — readings **and the verdict** |
| `sheerstatus --version` | Output version string |
| `sheerstatus --help` | Output usage instructions |

---

## Ecosystem

Looking to free up disk space after auditing? Check out [`sheersweep`](https://cver.net/oss/sheersweep), CVER's zero-daemon disk cleaner.

---

## License

MIT © 2026 CVER Inc.

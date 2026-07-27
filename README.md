# sheerstatus

**the zero-daemon hardware & pre-upgrade auditor you can read.**

`sheerstatus` is a single-file POSIX Bash executable that audits your Mac or Linux system metrics (RAM, Swap, Storage capacity, Battery health, BMS thermals) and outputs a zero-fluff, hard-data pre-upgrade verdict.

- **Zero Daemons**: No background services running 24/7. Run it on-demand when contemplating a hardware upgrade or debugging lag.
- **Zero Dependencies**: Pure POSIX Bash using native `sysctl`, `df`, `ioreg` (macOS), and `/proc`, `/sys` (Linux).
- **Cross-Platform**: Supports macOS & Linux natively out-of-the-box.
- **9 Locales Supported**: `en-US`, `ja-JP`, `zh-TW`, `zh-Hans`, `ko-KR`, `es-ES`, `de-DE`, `fr-FR`, `pt-BR`.
- **Zero Decorative Emojis**: Clean, professional ASCII status indicators (`[PASS]`, `[WARN]`, `[CRIT]`).

---

## Output Demo


```text
============================================================
sheerstatus v0.6.0 — Hardware & Pre-Upgrade Auditor
  • System Specs: Apple M2 (16 GB · 228 GB Disk)

Memory & Swap
  • Swap Used: 2.07 / 3.00 GB

Storage
  • Capacity Usage: 192 / 228 GB (95%)

Battery Status
  • Live Temp: 30.4 °C
  • Avg Temp: 24.2 °C
  • Max Temp: 42 °C
  • Health: 100%
  • Cycle Count: 136

------------------------------------------------------------
Audit Verdict
  • [WARN] Memory: Swap in use 2.07 / 3.00 GB (current: 16 GB).
  • [CRIT] Storage: Severe storage deficit (95% used).
  • [PASS] Battery: Health 100% (136), good condition.

Recommendation: If lag persists, consider opting for a higher RAM tier and larger storage on your next machine.
============================================================
```

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/CVERInc/sheerstatus.git
cd sheerstatus

# Run on-demand audit
./sheerstatus

# Run for automation (JSON output)
./sheerstatus --json
```

The JSON carries the **verdict**, not just the readings — the same three words
the report prints, so a monitor never has to re-derive the thresholds and drift
from the tool about the same machine:

```json
{
  "swap_used_mb": 2889,
  "disk_used_pct": 93,
  "battery_health_pct": 89,
  "verdict": { "memory": "warn", "storage": "warn", "battery": "pass" }
}
```

A reading this machine can't take is `null`, never the string `"N/A"` — a
consumer doing arithmetic on `"N/A"` gets a silent zero. A battery with no
reading verdicts as `"unknown"` rather than being guessed at or omitted.

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

Looking to free up disk space after auditing? Check out [`sheersweep`](https://oss.cver.net/sheersweep), CVER's zero-daemon disk cleaner.

---

## License

MIT © 2026 CVER Inc.

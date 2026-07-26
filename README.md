# sheerstatus

**The Mac hardware & pre-upgrade auditor you can read.**  
Open source · zero daemons · hard-data verdict · single-file Bash.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## What is sheerstatus?

`sheerstatus` is a single-file, zero-dependency CLI auditor for macOS that answers one core question: **"Does my Mac actually need an upgrade right now?"**

Unlike heavy menu bar utilities that run 24/7 background daemons (wasting RAM just to tell you your RAM is full), `sheerstatus` runs **on-demand**. Run it once before Apple sales / BTS season or whenever you're tempted to buy a new Mac. It queries macOS system controllers for lifetime hardware metrics and outputs an objective, hard-data **Verdict**.

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/cver-inc/sheerstatus.git
cd sheerstatus

# Make executable and run
chmod +x sheerstatus
./sheerstatus
```

---

## Features

- ⚡ **Zero Background Daemons**: Runs only when you invoke it. Uses 0 MB of RAM while idle.
- 🔒 **Zero Dependencies**: Pure POSIX/Bash script. Uses native macOS utilities (`sysctl`, `ioreg`, `vm_stat`, `df`).
- 🌐 **Multi-Language (i18n)**: Auto-detects system locale (`zh-TW`, `en-US`, `ja-JP`, `zh-Hans`). Override anytime with `SHEERSTATUS_LANG`.
- 📊 **Lifetime Hardware History**: Extracts lifetime battery/chassis average & maximum temperatures recorded by Apple's BMS IC.
- ⚖️ **Objective Verdict**: Neutral, hard-data classifier (`🟢 Healthy`, `🟡 Warning`, `🔴 Critical`) that never assumes purchase channels or promotion eligibility.

---

## Command Options

```bash
sheerstatus              # Run interactive hardware health audit
sheerstatus --json       # Output machine-readable JSON for automation
sheerstatus --version    # Print version
sheerstatus --help       # Print help
```

---

## License

MIT © [CVER Inc.](https://cver.net)

# AGENTS.md — driving sheerstatus as an agent

You are likely an AI coding agent (Claude Code, Codex, Antigravity, …) being asked to maintain or extend `sheerstatus`. This file is your guide to understanding the architecture and safety constraints.

## What sheerstatus is, in one breath

`sheerstatus` is **the Mac hardware & pre-upgrade auditor you can read** — a single Bash script with **no telemetry, no background daemon, no network calls, no dependencies**.

**macOS only.** On non-macOS hosts, hardware audit metrics will return `N/A` or fallback values gracefully.

## Headless Execution

```bash
sheerstatus              # Print instantaneous hardware health & audit verdict
sheerstatus --json       # Output JSON format for automated pipelines
sheerstatus --version    # Print version
SHEERSTATUS_LANG=zh-TW sheerstatus  # Force specific locale
```

Locale is auto-detected; force it with `SHEERSTATUS_LANG=en-US|ja-JP|zh-TW|zh-Hans`.

## Core Guidelines

1. **No background daemons or telemetry.** Never add background daemons, persistent polling workers, or network calls.
2. **Neutral verdicts.** Verdicts must remain strictly hard-data driven (`🟢 Healthy`, `🟡 Warning`, `🔴 Critical`). Never assume promotional eligibility, student discounts, or specific purchase channels in script output.
3. **Single-file Bash.** Maintain `sheerstatus` as a clean, single-file Bash script using native macOS utilities (`sysctl`, `ioreg`, `vm_stat`, `df`).

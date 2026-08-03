# AGENTS.md — driving sheerstatus as an agent

You are likely an AI coding agent (Claude Code, Codex, Antigravity, …) being asked to maintain or extend `sheerstatus`. This file is your guide to understanding the architecture and safety constraints.

## What sheerstatus is, in one breath

`sheerstatus` is **the hardware & pre-upgrade auditor you can read** — a single Bash script with **no telemetry, no background daemon, no network calls, no dependencies**.

**macOS and Linux.** Each reading is taken with that platform's own instruments (`sysctl`/`ioreg`/`vm_stat` on Darwin, `/proc` and `/sys` on Linux — including non-`BAT*` battery classes, which is how it reads a PineNote's `rk817-battery`). A reading this machine can't take is omitted from the report and is `null` in `--json`, never the string `"N/A"`.

## Headless Execution

```bash
npx sheerstatus          # no install: the same single file, fetched and run
sheerstatus              # Print instantaneous hardware health & audit verdict
sheerstatus --json       # Output JSON format for automated pipelines
sheerstatus --version    # Print version
SHEERSTATUS_LANG=zh-TW sheerstatus  # Force specific locale
```

Locale is auto-detected; force it with `SHEERSTATUS_LANG=en-US|ja-JP|zh-TW|zh-Hans|ko-KR|es-ES|de-DE|fr-FR|pt-BR`.

## Core Guidelines

1. **No background daemons or telemetry.** Never add background daemons, persistent polling workers, or network calls.
2. **Neutral verdicts.** Verdicts must remain strictly hard-data driven, and they print as the CLI signet's badges — `[ PASS ]`, `[ WARN ]`, `[ CRIT ]`, fixed width, never translated, never an emoji. Never assume promotional eligibility, student discounts, or specific purchase channels in script output.
3. **Single-file Bash.** Maintain `sheerstatus` as a clean, single-file Bash script using each platform's native utilities (`sysctl`, `ioreg`, `vm_stat`, `df`; `/proc`, `/sys`).
4. **The npm package ships that same file, and nothing else.** `bin` points straight at the script — never a JS launcher that spawns it, because "you can read it" must not come to mean reading two languages across a process boundary. No `dependencies`, and **no install-time script**: `preinstall`/`install`/`postinstall` are the one npm hook that runs on someone else's machine, and `test.sh` fails the build if one appears. Publishing is `npm publish` from a real terminal — the account uses passkey 2FA, so there is no OTP to pass and no way to automate it headlessly.

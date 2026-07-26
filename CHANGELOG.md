# CHANGELOG — sheerstatus

## [0.1.0] - 2026-07-26

### Added
- Initial public release of `sheerstatus`.
- Zero-dependency single-file Bash implementation.
- Multi-language i18n support (`zh-TW`, `en-US`, `ja-JP`, `zh-Hans`).
- Instantaneous Swap usage and compressed memory auditing (`sysctl vm.swapusage` & `vm_stat`).
- Battery and thermal sensor reader with lifetime temperature history (`ioreg`).
- Objective, neutral verdict classifier (`🟢 Healthy`, `🟡 Warning`, `🔴 Critical`).
- Support for `--json`, `--version`, and `--help` CLI flags.

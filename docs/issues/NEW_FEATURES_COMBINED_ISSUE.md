# Combined Tracking Issue — Upcoming Features (Single Thread)

This single issue tracks the next set of high-impact work. We’ve moved away from phased planning; this thread is the source of truth for upcoming features and their acceptance criteria.

Last updated: 2025-10-25

## Recommended Features

1) GPU Acceleration Auto-Detect and Smart Offload

- Goal: Detect available hardware encoders (NVENC, AMF, QSV; platform-appropriate) and automatically use them when compatible with the selected container/codec, with transparent fallback to software.
- Why: Dramatically faster encoding on supported hardware; reduces CPU load.

Scope
- Detect hardware capabilities at startup and on-demand (e.g., Settings → Refresh)
- Map detected capabilities to supported encoder options per codec/container
- Auto-select hardware encoder when:
  - The selected output codec has a hardware encoder available
  - The target container supports the resulting bitstream
  - The user has not explicitly disabled hardware acceleration
- Fallback to software encoder with clear log message when:
  - No compatible hardware encoder exists
  - Hardware initialization fails (driver/runtime issues)
  - User disables “Use GPU when available”
- UI: Add a Settings toggle: “Use hardware acceleration when available” (default: ON)
- Logging: Record detection results, selection decisions, and fallback reasons

Acceptance Criteria
- [ ] On a machine with a supported GPU encoder, exports use the hardware encoder by default when codec/container combinations are compatible
- [ ] On machines without supported hardware, exports succeed with software encoding; logs include fallback reason
- [ ] Users can disable the feature globally via Settings, forcing software encoding
- [ ] Logs clearly show detection results and which encoder was used for each job
- [ ] Unit tests cover decision logic for common scenarios (NVENC present/absent, QSV present/absent, incompatible containers)

Notes
- Windows priority: NVENC (NVIDIA), AMF (AMD), QSV (Intel)
- Cross-platform considerations can be added later; start with Windows where this app primarily runs

2) Disk Space Preflight and Temp Path Guard

- Goal: Prevent mid-export failures due to insufficient disk space by pre-checking the target output and temporary working directories.
- Why: Saves time and avoids partial exports and confusion.

Scope
- Estimate required disk space prior to export (heuristics: input size, codec/quality, remux vs re-encode)
- Check free space on both output directory volume and temp directory volume
- Provide a clear warning with required vs available space; allow override with a checkbox (optional)
- Log the preflight check results for each export session

Acceptance Criteria
- [ ] When free space is insufficient by heuristic estimate, user is warned before export starts
- [ ] Exports do not start unless user explicitly overrides (when allowed by settings)
- [ ] Logs include required/available estimates and decision (proceed/block/override)
- [ ] Unit tests cover estimation and threshold logic

Out of Scope (for this issue)
- Cross-platform GPU acceleration beyond Windows first pass
- Live playback preview or waveform analysis (explicitly removed)

## Implementation Notes
- Keep encoder selection logic centralized (service) with a pure function that can be unit-tested given environment capability inputs.
- Prefer small, well-logged steps. If detection fails, do not block exports—only fallback and log.
- UI changes minimal: one settings toggle and optional “Refresh hardware detection” button.

## Tracking Checklist
- [ ] Capability detection implemented and logged
- [ ] Encoder selection and fallback logic
- [ ] Settings toggle and wiring
- [ ] Disk space estimator and preflight check
- [ ] Unit tests for decision/estimation logic
- [ ] README/FEATURES docs updated accordingly

## Links
- Implementation overview: `../IMPLEMENTATION_OVERVIEW.md`
- Feature list (implemented): `../FEATURES.md`
- Roadmap and ideas: `../ENHANCEMENTS.md`

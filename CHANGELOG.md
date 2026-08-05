# Changelog

Entries are added only for genuinely user-visible or contract-relevant changes.

## Unreleased

## 0.2.0 — 2026-08-05

### Added

- Registers itself as a service with nxc_core, and exports `health`. A
  diagnostics resource missing from the diagnostics is a gap exactly where
  somebody is looking.


Initial implementation.

### Added

- **Demonstrations: the first thing in the project that uses the framework.**
  Three zones, four target options, and one workflow, registered through the same
  public exports a gameplay resource would use. Until this existed, nxc_zones,
  nxc_target and nxc_interact started correctly, passed every test, and had
  nothing to do.

  At Legion Square, which exists on every GTA V server. ADR-0018 forbids assuming
  content exists, and a coordinate on the base map is the one assumption that
  holds.

  The polygon is concave on purpose: walking into the notch and being outside it
  is the only way to see that the test is real rather than a bounding box with
  more vertices.

- **Two gates, both required.** `nxc_dev_mode` is about the environment; the
  command ace is about the person. If either refuses, this resource registers
  nothing at all — no commands, no demonstrations, no handlers. Refusing by not
  registering rather than by declining: a command that exists and says no is one
  somebody will find and probe.

- `nxc_devtools` and `nxc_devtools demos` on the console or in game, and
  `/nxc_devtools_here` to set a waypoint.

- 17 tests.

### Known limitations

- **Nothing here grants anything.** No demonstration consumes an item or pays
  anything, and a test asserts it. A demo that did would be a back door with a
  friendly label, in the one resource whose purpose is to be enabled on servers
  under development.

- One demonstration option is capability-gated **so that it is refused**, since
  nothing grants capabilities yet. That refusal is the behaviour an operator most
  needs to recognise, because it looks identical to a broken feature.

- The configuration editing interface is **not** built. `nxc_config` supports
  drafts, publication and rollback; there is still no screen for them.

- Event and RPC tracing (NXC-P1-047) is not built.

- Nothing here has run on a server.

Initial development. No release has been made.

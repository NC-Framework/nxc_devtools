# Platform — nxc_devtools

**Target:** FiveM for GTA V Enhanced, Enhanced Cfx Server runtime.

Required by Master Design Document v0.4 section 38.3 and
[`PLATFORM_STANDARDS.md`](https://github.com/NC-Framework/nxc-core-governance/blob/main/standards/PLATFORM_STANDARDS.md).
All eight items are answered. **`None` is written where it applies** — an empty section is a claim that
someone looked and found nothing, and an absent section is not.

`nxc_devtools` provides development diagnostics, gated by development mode and capability.

---

### 1. Enhanced natives and platform APIs used

**None — this resource has no code yet.**

That is a statement about the present, not a claim about the design. MDD v0.4 section 38.8 requires development tooling use the Enhanced developer-mode model, and section 38.9 requires launching additional local test clients through the supported Enhanced workflow. This resource integrates with or complements Enhanced tooling rather than reimplementing it.

### 2. Deprecated or compatibility-only natives used

**None.**

### 3. Game assets, archetypes, metadata, or data files required

**None currently.**

### 4. Voice, networking, state bag, entity, and routing bucket assumptions

**Diagnostics read everything and change nothing.** Resource timing, OneSync entities, sync trees, state bags, routing buckets, and NetIDs are all read surfaces. Production never exposes them globally.

Routing buckets, when needed, are **requested from `nxc_core`**, never chosen. Two resources picking the
same number is the accidental-instance failure the design names as an existing production problem.

### 5. Known Enhanced platform limitations

**None known, and none have been looked for.** Nothing has been tested on Enhanced, because the
development server runs Legacy artifacts (blocker B-10).

### 6. Minimum supported Cfx Server build

**Not pinned.** No build has been named — OD-020, blocker B-11. The manifest declares `UNPINNED`, which
fails `check-manifests.mjs` deliberately rather than passing with a plausible-looking number.

### 7. Asset conversion or validation requirements

**None.**

### 8. Optional Legacy compatibility layer

**None**, and none is planned. Legacy support is not a launch requirement (ADR-0016).

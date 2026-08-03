--- nxc_devtools — diagnostics, and the first thing that uses the framework.
---
--- Two jobs that belong together because both exist to make the rest visible:
---
---   **Viewers.** Health, sessions, buckets, services, configuration, zones,
---   targets, and workflows. What the framework thinks is true, shown to
---   somebody who can act on it.
---
---   **Demonstrations.** Real zones, target options, and workflows, registered
---   the way a gameplay resource would. Until this exists, nxc_zones,
---   nxc_target, and nxc_interact are three resources that start correctly and
---   have nothing to do.
---
--- **IT IS OFF UNLESS `nxc_dev_mode` IS ON.** Every command, every viewer, every
--- demonstration. MDD v0.4 section 38.8 forbids a diagnostics surface in
--- production, and nxc_core's bootstrap refuses to start a production
--- environment with dev mode enabled — so this inherits a gate enforced
--- somewhere else that cannot be quietly loosened here.
---
--- **AND EVERY COMMAND IS ACE-RESTRICTED ON TOP.** Dev mode is about the
--- environment; the ace is about the person. A development server with players
--- on it is an ordinary thing, and neither gate implies the other.
---
--- The demonstrations are the reason to be careful. A viewer leaks information;
--- a demonstration that registered a working, capability-free, server-side
--- action would be a back door with a friendly label.

NxcDevtools = NxcDevtools or {}

NxcDevtools.RESOURCE = 'nxc_devtools'

NxcDevtools.VERSION = (type(GetResourceMetadata) == 'function'
    and GetResourceMetadata(GetCurrentResourceName(), 'version', 0))
    or '0.0.0-test'

NxcDevtools.CONTRACT_VERSION = 1

local REQUIRED_LIB_CONTRACT = 3

if type(Nxc) ~= 'table' then
    error('nxc_devtools requires nxc_lib. Load its shared modules with @nxc_lib/... '
        .. 'entries in shared_scripts: a dependency orders startup and shares no '
        .. 'code, because every resource has its own Lua state.', 0)
end

if (Nxc.CONTRACT_VERSION or 0) < REQUIRED_LIB_CONTRACT then
    error(('nxc_devtools requires nxc_lib contract %d and found %d. Install a whole '
        .. 'compatibility set; mixing versions is unsupported.')
        :format(REQUIRED_LIB_CONTRACT, Nxc.CONTRACT_VERSION or 0), 0)
end

return NxcDevtools

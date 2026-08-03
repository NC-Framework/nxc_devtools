--- Whether this resource may do anything at all.
---
--- Pure, so the decision is testable rather than being scattered across every
--- command as an `if` somebody can forget.
---
--- **TWO GATES, AND BOTH MUST OPEN.** They are not redundant:
---
---   `nxc_dev_mode`  is about the ENVIRONMENT. Diagnostics on a production
---                   server are an information-disclosure vulnerability whoever
---                   is running it did not choose.
---
---   the ace         is about the PERSON. A development server with players on
---                   it is ordinary, and they should not be reading session
---                   internals.
---
--- A resource that checked only the first would expose everything to every
--- player on a dev server. One that checked only the second would expose it in
--- production to anyone who obtained the ace.

local Gating = {}

--- The environments where diagnostics are permitted at all.
---
--- An allowlist rather than a denylist. A new environment name added later
--- defaults to refusing, which is the direction that fails safe — a denylist
--- would silently admit `staging-2`.
Gating.PERMITTED_ENVIRONMENTS = {
    development = true,
    staging = true,
}

--- May this resource run?
---
---@param opts table  { devMode, environment }
---@return boolean, string|nil  allowed, and why not
function Gating.enabled(opts)
    opts = opts or {}

    if opts.devMode ~= true then
        return false, 'nxc_dev_mode is not enabled'
    end

    local environment = opts.environment
    if type(environment) ~= 'string' or environment == '' then
        -- An unknown environment is refused. Guessing would mean the one server
        -- with a misspelled environment name is the one running diagnostics in
        -- production.
        return false, 'the environment is not set'
    end

    if not Gating.PERMITTED_ENVIRONMENTS[environment] then
        return false, ('diagnostics are not permitted in %s'):format(environment)
    end

    return true, nil
end

--- May this person use it?
---
--- Separate from `enabled` because they answer different questions and are
--- checked at different times: the resource decides once at startup whether to
--- register anything, and each command decides per caller.
---
---@param opts table  { allowed, source }
---@return boolean, string|nil
function Gating.permitted(opts)
    opts = opts or {}

    -- The console is not a person and holds no ace. It already has complete
    -- control of the server, so gating it would protect nothing from anybody.
    if opts.source == 0 then return true, nil end

    if opts.allowed ~= true then
        return false, 'missing the command ace'
    end

    return true, nil
end

NxcDevtools.Gating = Gating
return Gating

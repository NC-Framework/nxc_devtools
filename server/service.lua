--- Registering the demonstrations, and answering the viewers.
---
--- **NOTHING IN THIS FILE RUNS UNLESS BOTH GATES OPEN.** The check happens once,
--- at startup, and if it refuses the resource registers no commands, no
--- demonstrations, and no event handlers at all.
---
--- Refusing by not registering — rather than by registering something that
--- checks a flag — is deliberate. A command that exists and declines is a
--- command somebody will find and probe; one that was never registered is not
--- there to find.

if not IsDuplicityVersion() then return end

local Service = {}

local enabled, reason = NxcDevtools.Gating.enabled({
    devMode = GetConvar('nxc_dev_mode', 'false') == 'true',
    environment = GetConvar('nxc_environment', ''),
})

if not enabled then
    -- Said once, plainly. An operator who expected diagnostics and has none
    -- should not have to guess which of the two gates closed.
    Nxc.Logger.info('devtools.disabled', {
        reason = reason,
        effect = 'no commands, demonstrations, or viewers are registered',
    })
    return
end

local registered = { zones = 0, options = 0, workflows = 0 }

--- Register everything, once the resources that receive it are up.
---
--- Waits rather than assumes: nxc_devtools starts last, but "last in the config"
--- and "finished starting" are different things, and a registration sent to a
--- resource that has not opened yet is silently lost.
local function registerDemos()
    for _, zone in ipairs(NxcDevtools.Demos.ZONES) do
        local ok, result = pcall(function() return exports.nxc_zones:register(zone) end)
        if ok and type(result) == 'table' and result.ok then
            registered.zones = registered.zones + 1
        else
            Nxc.Logger.warn('devtools.zone_rejected', {
                zone = zone.id,
                reason = ok and type(result) == 'table' and result.error
                    and result.error.code or tostring(result),
            })
        end
    end

    for _, option in ipairs(NxcDevtools.Demos.OPTIONS) do
        local ok, result = pcall(function() return exports.nxc_target:register(option) end)
        if ok and type(result) == 'table' and result.ok then
            registered.options = registered.options + 1
        else
            Nxc.Logger.warn('devtools.option_rejected', {
                option = option.id,
                reason = ok and type(result) == 'table' and result.error
                    and result.error.code or tostring(result),
            })
        end
    end

    for _, workflow in ipairs(NxcDevtools.Demos.WORKFLOWS) do
        local ok, result = pcall(function() return exports.nxc_interact:register(workflow) end)
        if ok and type(result) == 'table' and result.ok then
            registered.workflows = registered.workflows + 1
        else
            Nxc.Logger.warn('devtools.workflow_rejected', {
                workflow = workflow.id,
                reason = ok and type(result) == 'table' and result.error
                    and result.error.code or tostring(result),
            })
        end
    end

    Nxc.Logger.info('devtools.demos_registered', {
        zones = registered.zones,
        options = registered.options,
        workflows = registered.workflows,
        at = ('%.1f, %.1f, %.1f'):format(
            NxcDevtools.Demos.ORIGIN.x, NxcDevtools.Demos.ORIGIN.y, NxcDevtools.Demos.ORIGIN.z),
    })
end

CreateThread(function()
    local deadline = GetGameTimer() + 30000
    local needed = { 'nxc_zones', 'nxc_target', 'nxc_interact' }

    while GetGameTimer() < deadline do
        local ready = true
        for _, resource in ipairs(needed) do
            if GetResourceState(resource) ~= 'started' then ready = false break end
        end
        if ready then break end
        Wait(250)
    end

    for _, resource in ipairs(needed) do
        if GetResourceState(resource) ~= 'started' then
            -- Named individually. "Something was not ready" sends an operator
            -- looking at all three.
            Nxc.Logger.warn('devtools.dependency_not_started', {
                dependency = resource,
                effect = 'its demonstrations are not registered',
            })
        end
    end

    registerDemos()
end)

--- A demonstration option was chosen, and the gate permitted it.
---
--- Reaching here means nxc_target re-checked distance and capability against the
--- server's own state. The context is what it built, not what the client sent.
AddEventHandler('nxc_devtools:server:demoSelected', function(context)
    Nxc.Logger.info('devtools.demo_selected', {
        option = context.option,
        account = context.account,
        distance = ('%.2f'):format(context.distance or 0),
        correlationId = context.correlationId,
    })

    TriggerClientEvent('nxc_devtools:client:notify', context.source,
        ('Server accepted "%s" from %.1fm away.'):format(
            tostring(context.option), context.distance or 0))
end)

--- The option that starts a workflow.
---
--- **This is the link between the two resources**, and the reason
--- `nxc_interact:begin` exists: this handler runs on the server with a validated
--- context and no client to ask.
AddEventHandler('nxc_devtools:server:demoWorkflow', function(context)
    local started = exports.nxc_interact:begin(context.source, 'nxc_devtools:slow_thing')

    if type(started) ~= 'table' or not started.ok then
        local code = type(started) == 'table' and started.error and started.error.code or 'unknown'
        Nxc.Logger.info('devtools.workflow_refused', {
            account = context.account, reason = code,
        })
        TriggerClientEvent('nxc_devtools:client:notify', context.source,
            ('Workflow refused: %s'):format(code))
    end
end)

AddEventHandler('nxc_devtools:server:demoWorkflowDone', function(context)
    Nxc.Logger.info('devtools.workflow_completed', {
        workflow = context.workflow,
        account = context.account,
        elapsedMs = context.elapsedMs,
        success = context.success,
        outcomeDecidedBy = context.outcomeDecidedBy,
        correlationId = context.correlationId,
    })
    TriggerClientEvent('nxc_devtools:client:notify', context.source,
        ('Workflow completed in %dms. The server timed it, not your client.')
            :format(context.elapsedMs or 0))
end)

--- `nxc_devtools` — what the framework currently believes.
RegisterCommand('nxc_devtools', function(source, args)
    local allowed, why = NxcDevtools.Gating.permitted({
        source = source,
        allowed = source ~= 0 and IsPlayerAceAllowed(source, 'command.nxc_devtools') or false,
    })
    if not allowed then
        Nxc.Logger.debug('devtools.command_refused', { reason = why })
        return
    end

    local function line(text)
        if source == 0 then print(text)
        else TriggerClientEvent('chat:addMessage', source, { args = { text } }) end
    end

    local what = args[1] or 'overview'

    if what == 'demos' then
        line(('^5[nxc_devtools]^7 demonstrations at %.1f, %.1f, %.1f'):format(
            NxcDevtools.Demos.ORIGIN.x, NxcDevtools.Demos.ORIGIN.y, NxcDevtools.Demos.ORIGIN.z))
        for index, check in ipairs(NxcDevtools.Demos.CHECKS) do
            line(('  %d. %s'):format(index, check))
        end
        return
    end

    line(('^5[nxc_devtools]^7 v%s'):format(NxcDevtools.VERSION))
    line(('  environment           %s'):format(GetConvar('nxc_environment', '?')))
    line(('  demonstrations        %d zones, %d options, %d workflows')
        :format(registered.zones, registered.options, registered.workflows))
    line(('  framework ready       %s'):format(tostring(exports.nxc_core:isReady())))
    line('  run "nxc_devtools demos" for what to try')
end, true)

NxcDevtools.Service = Service
return Service

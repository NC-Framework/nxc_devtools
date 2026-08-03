--- The client half: a marker to walk to, and zone events made visible.
---
--- Zone transitions and workflow outcomes both happen without anything on
--- screen. That is correct for production and useless for testing, which is what
--- this file is for.

if IsDuplicityVersion() then return end

local function notify(text, severity)
    if GetResourceState('nxc_ui') == 'started' then
        pcall(function()
            exports.nxc_ui:show({
                type = 'notify', surface = 'nxc_devtools',
                text = text, severity = severity or 'info', durationMs = 4000,
            })
        end)
    end
    print(('[nxc_devtools] %s'):format(text))
end

RegisterNetEvent('nxc_devtools:client:notify', function(text)
    notify(text)
end)

--- Zone transitions, said out loud.
AddEventHandler('nxc_zones:client:entered', function(id, data)
    if id:sub(1, 12) ~= 'nxc_devtools' then return end
    notify(('Entered: %s'):format(data and data.label or id), 'success')
end)

AddEventHandler('nxc_zones:client:exited', function(id, data)
    if id:sub(1, 12) ~= 'nxc_devtools' then return end
    notify(('Left: %s'):format(data and data.label or id), 'info')
end)

--- A marker at the demonstration site.
---
--- Drawn only when nearby, and only when a marker is actually somewhere the
--- player can see. A marker drawn every frame from across the map is the same
--- waste this project spends effort avoiding everywhere else.
CreateThread(function()
    local origin = NxcDevtools.Demos.ORIGIN

    while true do
        local wait = 1000
        local position = GetEntityCoords(PlayerPedId())
        local distanceSquared = NxcZones and NxcZones.Geometry
            and NxcZones.Geometry.distanceSquared(
                position.x, position.y, position.z, origin.x, origin.y, origin.z)
            or ((position.x - origin.x) ^ 2 + (position.y - origin.y) ^ 2)

        if distanceSquared < 10000 then  -- 100m
            wait = 0
            DrawMarker(1, origin.x, origin.y, origin.z - 1.0, 0, 0, 0, 0, 0, 0,
                2.0, 2.0, 1.0, 0, 200, 255, 120, false, false, 2, false, nil, nil, false)
        end

        Wait(wait)
    end
end)

--- `/nxc_devtools_here` — a waypoint, because 195, -933 is not directions.
RegisterCommand('nxc_devtools_here', function()
    local origin = NxcDevtools.Demos.ORIGIN
    SetNewWaypoint(origin.x, origin.y)
    notify('Waypoint set to the demonstration site.')
end, false)

return true

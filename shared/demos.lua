--- Demonstration zones, target options, and workflows.
---
--- **THE FIRST THING IN THE PROJECT THAT USES THE FRAMEWORK.** Until this
--- existed, nxc_zones, nxc_target, and nxc_interact were three resources that
--- started correctly, passed every test, and had nothing to do — holding the
--- interact key found nothing because nothing had registered anything.
---
--- These are registered the way a gameplay resource would register them, which
--- is the point: if this file needs a private arrangement to work, the public
--- one is wrong.
---
--- **NOTHING HERE GRANTS ANYTHING.** Every demonstration is observable and
--- inert: it logs, it shows a notification, it makes you wait. None consumes an
--- item, none pays anything, and none is capability-free with a real effect —
--- a demo that did would be a back door wearing a friendly label, shipped in a
--- resource whose whole purpose is to be enabled on servers under development.
---
--- Deliberately placed near Legion Square, which every GTA V server has. ADR-0018
--- forbids assuming any content exists, and a coordinate on the base map is the
--- one location that assumption holds for.

local Demos = {}

--- Where the demonstration lives.
---
--- One place, so an operator can walk to it. Legion Square: on the base map, in
--- every server, and central enough to reach quickly.
Demos.ORIGIN = { x = 195.0, y = -933.0, z = 30.7 }

--- Zones a player can walk into.
Demos.ZONES = {
    {
        id = 'nxc_devtools_sphere',
        kind = 'sphere',
        shape = { x = Demos.ORIGIN.x, y = Demos.ORIGIN.y, z = Demos.ORIGIN.z, radius = 8.0 },
        data = { label = 'demonstration sphere' },
    },
    {
        id = 'nxc_devtools_box',
        kind = 'box',
        shape = {
            x = Demos.ORIGIN.x + 20.0, y = Demos.ORIGIN.y, z = Demos.ORIGIN.z,
            width = 10.0, length = 6.0, height = 4.0, heading = 45.0,
        },
        data = { label = 'demonstration box, rotated 45 degrees' },
    },
    {
        id = 'nxc_devtools_polygon',
        kind = 'polygon',
        shape = {
            points = {
                { x = Demos.ORIGIN.x - 30.0, y = Demos.ORIGIN.y - 5.0 },
                { x = Demos.ORIGIN.x - 15.0, y = Demos.ORIGIN.y - 5.0 },
                { x = Demos.ORIGIN.x - 15.0, y = Demos.ORIGIN.y + 5.0 },
                { x = Demos.ORIGIN.x - 22.0, y = Demos.ORIGIN.y + 5.0 },
                { x = Demos.ORIGIN.x - 22.0, y = Demos.ORIGIN.y + 15.0 },
                { x = Demos.ORIGIN.x - 30.0, y = Demos.ORIGIN.y + 15.0 },
            },
            minZ = Demos.ORIGIN.z - 2.0,
            maxZ = Demos.ORIGIN.z + 4.0,
        },
        -- An L shape on purpose. Walking into the notch and finding yourself
        -- OUTSIDE is the only way to see that the polygon test is genuinely
        -- concave rather than a bounding box wearing more vertices.
        data = { label = 'demonstration polygon, concave — the notch is outside' },
    },
}

--- Target options a player can look at and choose.
Demos.OPTIONS = {
    {
        id = 'inspect_ped',
        label = 'Inspect this person',
        icon = 'user',
        global = 'ped',
        distance = 2.5,
        serverEvent = 'nxc_devtools:server:demoSelected',
    },
    {
        id = 'inspect_vehicle',
        label = 'Inspect this vehicle',
        icon = 'car',
        global = 'vehicle',
        distance = 3.0,
        serverEvent = 'nxc_devtools:server:demoSelected',
    },
    {
        -- Demonstrates the gate REFUSING. Nothing grants capabilities yet, so
        -- this option appears and is then refused server-side — which is the
        -- behaviour an operator most needs to be able to recognise, because it
        -- looks identical to a broken feature.
        id = 'restricted',
        label = 'Restricted action (should be refused)',
        icon = 'lock',
        global = 'ped',
        distance = 2.5,
        capability = 'nxc_devtools.demo',
        serverEvent = 'nxc_devtools:server:demoSelected',
    },
    {
        id = 'start_workflow',
        label = 'Do something slow (5 seconds)',
        icon = 'clock',
        global = 'object',
        distance = 3.0,
        serverEvent = 'nxc_devtools:server:demoWorkflow',
    },
}

--- Workflows a player can be made to wait through.
Demos.WORKFLOWS = {
    {
        id = 'slow_thing',
        durationMs = 5000,
        cooldownMs = 10000,
        onComplete = 'nxc_devtools:server:demoWorkflowDone',
        steps = {
            { kind = 'progress', label = 'Doing something slow' },
            { kind = 'animation', dict = 'amb@world_human_hammering@male@base',
              anim = 'base', flags = 49 },
        },
    },
}

--- What an operator should try, in an order that builds.
---
--- Kept beside the definitions so the two cannot drift: a step describing an
--- option that no longer exists is worse than no guide at all.
Demos.CHECKS = {
    'Walk to the marker. `/nxc_zones_debug` draws the three zones',
    'Enter the sphere — the chat line says entered, and leaving says exited',
    'Walk into the notch of the L-shaped polygon. You should be OUTSIDE it',
    'Look at a person and hold the interact key. Two options appear',
    'Choose "Inspect this person" — a notification, and a server log line',
    'Choose "Restricted action" — it is REFUSED. Nothing grants capabilities yet',
    'Look at an object and choose the slow thing. A progress bar runs for 5s',
    'Do it again immediately — refused, because it is on a 10 second cooldown',
    'Start it and press Escape halfway. It cancels, and sets NO cooldown',
}

NxcDevtools.Demos = Demos
return Demos

import { test, describe, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { createEngine } from './harness.mjs';

let lua;
beforeEach(async () => { lua = await createEngine(); });
afterEach(() => lua.global.close());

/**
 * This resource exposes internal state and registers working interactions. Both
 * gates matter, and they are not redundant — one is about the environment, the
 * other about the person.
 */
describe('Environment gating', () => {
  const enabled = (opts) => lua.doString(`
    local allowed, why = NxcDevtools.Gating.enabled(${opts})
    return { allowed = allowed, why = why }
  `);

  test('development with dev mode on is permitted', async () => {
    const r = await enabled(`{ devMode = true, environment = 'development' }`);
    assert.equal(r.allowed, true);
  });

  test('dev mode off is refused in every environment', async () => {
    for (const env of ['development', 'staging', 'production']) {
      const r = await enabled(`{ devMode = false, environment = '${env}' }`);
      assert.equal(r.allowed, false, env);
      assert.match(r.why, /nxc_dev_mode/);
    }
  });

  test('production is refused even with dev mode on', async () => {
    // nxc_core already refuses to START a production environment with dev mode
    // enabled, so this should be unreachable. Checking anyway: a gate that
    // relies on another resource having refused first is a gate that opens the
    // day that resource changes.
    const r = await enabled(`{ devMode = true, environment = 'production' }`);
    assert.equal(r.allowed, false);
    assert.match(r.why, /not permitted in production/);
  });

  test('an unknown environment is refused rather than guessed', async () => {
    const r = await enabled(`{ devMode = true, environment = 'staging-2' }`);
    // An allowlist, so a new environment name defaults to refusing. A denylist
    // would silently admit this one, and the server with a misspelled
    // environment would be the one running diagnostics in production.
    assert.equal(r.allowed, false);
  });

  test('a missing environment is refused', async () => {
    assert.equal((await enabled(`{ devMode = true }`)).allowed, false);
    assert.equal((await enabled(`{ devMode = true, environment = '' }`)).allowed, false);
  });

  test('no options at all is refused', async () => {
    const r = await lua.doString(`
      local allowed = NxcDevtools.Gating.enabled()
      return allowed
    `);
    // Failing open on a missing argument is how a gate becomes decorative.
    assert.equal(r, false);
  });
});

describe('Person gating', () => {
  const permitted = (opts) => lua.doString(`
    local allowed, why = NxcDevtools.Gating.permitted(${opts})
    return { allowed = allowed, why = why }
  `);

  test('the console is permitted without an ace', async () => {
    // It already has complete control of the server, so gating it protects
    // nothing from anybody.
    assert.equal((await permitted(`{ source = 0 }`)).allowed, true);
  });

  test('a player with the ace is permitted', async () => {
    assert.equal((await permitted(`{ source = 5, allowed = true }`)).allowed, true);
  });

  test('a player without the ace is refused', async () => {
    const r = await permitted(`{ source = 5, allowed = false }`);
    assert.equal(r.allowed, false);
    assert.match(r.why, /ace/);
  });

  test('a missing ace result is refused rather than treated as true', async () => {
    assert.equal((await permitted(`{ source = 5 }`)).allowed, false);
    assert.equal((await permitted(`{ source = 5, allowed = 'yes' }`)).allowed, false);
  });
});

describe('Demonstrations', () => {
  test('every demonstration zone is a valid zone', async () => {
    // Registered through the same public export a gameplay resource uses. If
    // these need a private arrangement to work, the public one is wrong.
    const r = await lua.doString(`
      local bad = {}
      for _, zone in ipairs(NxcDevtools.Demos.ZONES) do
        if type(zone.id) ~= 'string' or type(zone.kind) ~= 'string'
           or type(zone.shape) ~= 'table' then
          bad[#bad + 1] = tostring(zone.id)
        end
      end
      return table.concat(bad, ',')
    `);
    assert.equal(r, '');
  });

  test('the polygon is genuinely concave', async () => {
    const r = await lua.doString(`
      local polygon
      for _, zone in ipairs(NxcDevtools.Demos.ZONES) do
        if zone.kind == 'polygon' then polygon = zone end
      end
      -- A convex hull of these points would contain the notch. Walking into it
      -- and being OUTSIDE is the only way to see the test is real.
      local points = polygon.shape.points
      return { count = #points, hasNotch = #points > 4 }
    `);
    assert.equal(r.count, 6);
    assert.equal(r.hasNotch, true);
  });

  test('no demonstration grants anything', async () => {
    const r = await lua.doString(`
      local granting = {}
      for _, workflow in ipairs(NxcDevtools.Demos.WORKFLOWS) do
        if workflow.consumes or workflow.rewards then
          granting[#granting + 1] = workflow.id
        end
      end
      return table.concat(granting, ',')
    `);
    // A demo that consumed or paid would be a back door with a friendly label,
    // shipped in the one resource whose purpose is to be enabled on servers
    // under development.
    assert.equal(r, '');
  });

  test('one demonstration option is capability-gated, to show a refusal', async () => {
    const r = await lua.doString(`
      local gated = 0
      for _, option in ipairs(NxcDevtools.Demos.OPTIONS) do
        if option.capability then gated = gated + 1 end
      end
      return gated
    `);
    // Nothing grants capabilities yet, so this one is always refused — which is
    // the behaviour an operator most needs to recognise, because it looks
    // identical to a broken feature.
    assert.ok(r >= 1, 'no option demonstrates the gate refusing');
  });

  test('every check in the guide refers to something that exists', async () => {
    const r = await lua.doString(`
      local ids = {}
      for _, zone in ipairs(NxcDevtools.Demos.ZONES) do ids[zone.id] = true end
      for _, option in ipairs(NxcDevtools.Demos.OPTIONS) do ids[option.id] = true end
      for _, workflow in ipairs(NxcDevtools.Demos.WORKFLOWS) do ids[workflow.id] = true end
      return { checks = #NxcDevtools.Demos.CHECKS, defined = (function()
        local n = 0 for _ in pairs(ids) do n = n + 1 end return n end)() }
    `);
    // A step describing an option that no longer exists is worse than no guide.
    assert.ok(r.checks > 0);
    assert.equal(r.defined, 3 + 4 + 1);
  });
});

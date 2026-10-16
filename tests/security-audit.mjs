// Run with explicitly supplied test credentials; never commit credentials or tokens.
// Uses synthetic records only and cleans up its own records in a finally block.
export async function runSecurityAudit({ api, key, accounts }) {
  const results = [], sessions = [], rows = [], photos = [];
  const check = (name, ok) => { results.push({ name, passed: !!ok }); if (!ok) throw new Error(name); };
  async function request(route, { token, method = 'GET', body, headers = {} } = {}) {
    const response = await fetch(api + route, {
      method, cache: 'no-store', headers: { apikey: key, ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(body && !(body instanceof Uint8Array) ? { 'Content-Type': 'application/json' } : {}), ...headers },
      body: body instanceof Uint8Array ? body : body === undefined ? undefined : JSON.stringify(body)
    });
    const raw = await response.text();
    let data; try { data = JSON.parse(raw); } catch { data = raw; }
    return { status: response.status, ok: response.ok, data };
  }
  const denied = result => !result.ok || (Array.isArray(result.data) && result.data.length === 0);
  async function login(account) {
    const r = await request('/auth/v1/token?grant_type=password', { method: 'POST', body: {
      email: account.username + '@storybook.sekkemache.info', password: account.password
    } });
    check('Login: ' + account.username, r.ok && r.data.user?.id && r.data.access_token);
    const s = { id: r.data.user.id, token: r.data.access_token };
    sessions.push(s); return s;
  }
  try {
    const a = await login(accounts[0]), b = await login(accounts[1]);
    for (const table of ['sb_members', 'sb_people', 'sb_entries', 'sb_connections']) {
      check('Anonymous denied: ' + table, denied(await request('/rest/v1/' + table + '?select=id')));
    }
    check('Member cannot grant membership', denied(await request('/rest/v1/sb_members', {
      token: a.token, method: 'PATCH', body: { enabled: false }, headers: { Prefer: 'return=representation' }
    })));
    const person = await request('/rest/v1/sb_people', { token: a.token, method: 'POST',
      body: { owner_id: a.id, name: 'Temporary security audit ' + crypto.randomUUID() }, headers: { Prefer: 'return=representation' } });
    check('Owner creates person', person.ok && person.data[0]?.id);
    const p = person.data[0]; rows.push({ id: p.id, token: a.token });
    check('Friend may read person', (await request('/rest/v1/sb_people?id=eq.' + p.id, { token: b.token })).data.length === 1);
    check('Friend cannot update person', denied(await request('/rest/v1/sb_people?id=eq.' + p.id, {
      token: b.token, method: 'PATCH', body: { name: 'Forbidden update' }, headers: { Prefer: 'return=representation' }
    })));
    check('Friend cannot delete person', denied(await request('/rest/v1/sb_people?id=eq.' + p.id, {
      token: b.token, method: 'DELETE', headers: { Prefer: 'return=representation' }
    })));
    check('Owner cannot transfer ownership', denied(await request('/rest/v1/sb_people?id=eq.' + p.id, {
      token: a.token, method: 'PATCH', body: { owner_id: b.id }, headers: { Prefer: 'return=representation' }
    })));
    check('Friend cannot write chapter for owner', denied(await request('/rest/v1/sb_entries', {
      token: b.token, method: 'POST', body: { owner_id: b.id, person_id: p.id, title: 'Forbidden chapter' }
    })));
    const pixel = Uint8Array.from(atob('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jVxkAAAAASUVORK5CYII='), c => c.charCodeAt(0));
    const photo = `${a.id}/${p.id}/security-${crypto.randomUUID()}.png`;
    const route = '/storage/v1/object/storybook-photos/' + photo;
    check('Owner uploads private photo', (await request(route, { token: a.token, method: 'POST', body: pixel,
      headers: { 'Content-Type': 'image/png', 'Cache-Control': 'no-store' } })).ok);
    photos.push({ path: photo, token: a.token });
    check('Friend reads private photo', (await request(route, { token: b.token })).ok);
    check('Anonymous cannot download photo', !(await request(route)).ok);
    check('Public URL cannot download photo', !(await request('/storage/v1/object/public/storybook-photos/' + photo)).ok);
    check('Friend cannot replace photo', !(await request(route, { token: b.token, method: 'PUT', body: pixel,
      headers: { 'Content-Type': 'image/png' } })).ok);
    await request('/storage/v1/object/storybook-photos', { token: b.token, method: 'DELETE', body: { prefixes: [photo] } });
    check('Friend cannot delete photo', (await request(route, { token: a.token })).ok);
    const stale = await login(accounts[1]);
    check('Logout succeeds', (await request('/auth/v1/logout?scope=local', { token: stale.token, method: 'POST' })).ok);
    check('Revoked JWT immediately loses people access', denied(await request('/rest/v1/sb_people?id=eq.' + p.id, { token: stale.token })));
    check('Revoked JWT immediately loses membership access', denied(await request('/rest/v1/sb_members?select=id', { token: stale.token })));
    check('Revoked JWT immediately loses photo access', !(await request(route, { token: stale.token })).ok);
    check('Revoked JWT cannot create records', !(await request('/rest/v1/sb_people', { token: stale.token,
      method: 'POST', body: { owner_id: stale.id, name: 'Forbidden revoked session' } })).ok);
    check('Other active session still works', (await request('/rest/v1/sb_people?id=eq.' + p.id, { token: b.token })).data.length === 1);
    check('Owner record unchanged', (await request('/rest/v1/sb_people?id=eq.' + p.id, { token: a.token })).data[0]?.name === p.name);
  } finally {
    for (const photo of photos) {
      const r = await request('/storage/v1/object/storybook-photos', { token: photo.token, method: 'DELETE', body: { prefixes: [photo.path] } });
      if (!r.ok) throw new Error('Synthetic photo cleanup failed');
    }
    for (const row of rows) {
      const r = await request('/rest/v1/sb_people?id=eq.' + row.id, { token: row.token, method: 'DELETE' });
      if (!r.ok) throw new Error('Synthetic record cleanup failed');
    }
    for (const s of sessions) await request('/auth/v1/logout?scope=local', { token: s.token, method: 'POST' });
  }
  return { checkedAt: new Date().toISOString(), results, passed: results.filter(r => r.passed).length, failed: results.filter(r => !r.passed).length };
}

// Cloud mode: upload or update a project in the database from its folder in projects/.
//   node --env-file=.env tools/push.js example
// Updates the plan and the client's list. Never touches your progress, the client's ticks, or the client link.
const { load, db } = require('./cloud');

(async () => {
  const name = process.argv[2];
  const { R, tasks } = load(name);
  const { name: title, start, client = [], releases = [], ...roadmap } = R;   // client list and dates live in their own columns
  // What the client reads as "needed for": the title of the level each item blocks.
  const fasi = Object.fromEntries(R.levels.map(l => [l.id, `${l.fase} · ${l.t}`]));
  const before = await db(`skilltree_projects?slug=eq.${name}&select=id`);
  await db('skilltree_projects?on_conflict=slug', {
    method: 'POST', headers: { Prefer: 'resolution=merge-duplicates' },
    body: JSON.stringify({ slug: name, name: title || name, start_date: start || null, roadmap, requests: { fasi, items: client }, releases }),
  });
  console.log(`${before.length ? 'Updated' : 'Created'}: ${name} · ${R.levels.length} levels, ${tasks.length} tasks, ${client.length} client items, ${releases.length} releases`);
})().catch(e => { console.error(e.message); process.exit(1); });

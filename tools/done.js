// Lights (or turns off) tasks on the map by writing projects/<name>/state.json. An open map updates by itself.
//   node tools/done.js example "Draw the database schema" "db#3"   light: text (partial is fine) or id
//   node tools/done.js example --off "db#3"                         turn off
//   node tools/done.js example --find rls                           list matching tasks, change nothing
//   node tools/done.js example --node db                            list the tasks of node "db" (the code shown next to its name)
const fs = require('fs'), path = require('path');
const { load, db, cloudOn } = require('./cloud');

const [name, ...args] = process.argv.slice(2);
let project;
try { project = load(name); } catch (e) { console.error(e.message + '\nUsage: done.js <project> [--off|--find|--node] "text or id" …'); process.exit(1); }
const { dir, tasks } = project;
const off = args.includes('--off'), find = args.includes('--find'), query = args.filter(a => !a.startsWith('--'));
if (!query.length) { console.error('Which task? Give its text or id.'); process.exit(1); }

if (args.includes('--node')) {
  for (const q of query) { const hit = tasks.filter(t => t.id.split('#')[0] === q); console.log(`node ${q}: ${hit[0]?.node || 'not found'}`); hit.forEach(t => console.log(`  ${t.id}  ${t.t}`)); }
  process.exit(0);
}
// Cloud mode (keys in .env): write to the database. Otherwise: the local state file.
(async () => {
  const file = path.join(dir, 'state.json');
  const state = !cloudOn() && fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : {};
  state.done ??= {};
  const id = cloudOn() && !find ? (await db(`skilltree_projects?slug=eq.${name}&select=id`))[0]?.id : null;
  if (cloudOn() && !find && !id) throw new Error(`Project "${name}" is not in the database yet: run tools/push.js first`);
  let errors = 0;
  for (const q of query) {
    const hit = tasks.filter(t => t.id === q || t.t.toLowerCase().includes(q.toLowerCase()));
    // More than one match: do not guess. List them and skip this one.
    if (find || hit.length !== 1) {
      console.log(`"${q}": ${hit.length} task(s)`); hit.forEach(t => console.log(`  ${t.id}  ${t.t}  (${t.node})`));
      if (!find) errors++;
      continue;
    }
    if (id) await db('rpc/skilltree_set_state', { method: 'POST', body: JSON.stringify({ p_project: id, p_key: 'done', p_id: hit[0].id, p_on: !off }) });
    else off ? delete state.done[hit[0].id] : state.done[hit[0].id] = Math.floor(Date.now() / 1000);
    console.log(`${off ? 'off' : 'lit'}: ${hit[0].id}  ${hit[0].t}${id ? '  (cloud)' : ''}`);
  }
  if (!find && !id) fs.writeFileSync(file, JSON.stringify(state, null, 1));
  process.exit(errors ? 1 : 0);
})().catch(e => { console.error(e.message); process.exit(1); });

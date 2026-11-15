// Shared by push.js and done.js: read a project folder, and talk to the database in cloud mode.
// Keys come from .env (never from code):  node --env-file=.env tools/…
const fs = require('fs'), path = require('path');

function load(name) {
  const dir = path.join(__dirname, '..', 'projects', name || '');
  if (!/^[a-z0-9-]{1,40}$/.test(name || '') || !fs.existsSync(dir)) throw new Error(`Project "${name}" not found in projects/`);
  global.window = {};
  for (const f of fs.readdirSync(dir).filter(f => f.endsWith('.js')).sort()) require(path.join(dir, f));
  const R = global.window.ROADMAP;
  const tasks = R.levels.flatMap(l => l.nodes.flatMap(n => n.tasks.map((t, i) => ({ id: n.id + '#' + i, t, node: n.t }))));
  return { dir, R, tasks };
}

const cloudOn = () => !!(process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_KEY);

async function db(pathAndQuery, opts = {}) {
  const { SUPABASE_URL: url, SUPABASE_SERVICE_KEY: key } = process.env;
  if (!url || !key) throw new Error('Cloud mode needs SUPABASE_URL and SUPABASE_SERVICE_KEY in .env (run with: node --env-file=.env …)');
  const r = await fetch(url + '/rest/v1/' + pathAndQuery, { ...opts, headers: { apikey: key, Authorization: 'Bearer ' + key, 'Content-Type': 'application/json', ...opts.headers } });
  const txt = await r.text();
  if (!r.ok) throw new Error(`Database: ${r.status} ${txt}`);
  return txt ? JSON.parse(txt) : null;
}

module.exports = { load, db, cloudOn };

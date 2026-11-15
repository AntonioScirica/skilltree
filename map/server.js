// Local server for the map. Serves this folder and saves each project's progress in projects/<name>/state.json.
// Start:  node map/server.js   →  http://localhost:4173
// Local only: it binds to 127.0.0.1 and is not meant to be exposed to a network.
const http = require('http'), fs = require('fs'), path = require('path');

const ROOT = path.resolve(__dirname, '..'), PROJECTS = path.join(ROOT, 'projects'), PORT = +process.env.PORT || 4173;
const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.css': 'text/css', '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg' };
const NAME = /^[a-z0-9-]{1,40}$/;
const stateFile = name => path.join(PROJECTS, name, 'state.json');
const read = name => { try { return JSON.parse(fs.readFileSync(stateFile(name), 'utf8')); } catch { return {}; } };

http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost'), p = decodeURIComponent(url.pathname);

  // Projects = folders in projects/ that contain .js data files, loaded in alphabetical order.
  if (p === '/api/projects') {
    const list = fs.existsSync(PROJECTS) ? fs.readdirSync(PROJECTS).filter(n => NAME.test(n) && fs.statSync(path.join(PROJECTS, n)).isDirectory())
      .map(name => ({ name, files: fs.readdirSync(path.join(PROJECTS, name)).filter(f => f.endsWith('.js')).sort() })).filter(x => x.files.length) : [];
    return res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }).end(JSON.stringify(list));
  }

  // One change at a time: { k: 'done' | 'rel' | 'got', id, v } or { k: 'week', v }.
  if (req.method === 'POST' && p === '/api/state') {
    const name = url.searchParams.get('p') || '';
    // A JSON content type forces browsers to preflight: another open website cannot write here.
    if (!/^application\/json/.test(req.headers['content-type'] || '') || !NAME.test(name) || !fs.existsSync(path.join(PROJECTS, name))) return res.writeHead(400).end();
    let body = '';
    req.on('data', c => { body += c; if (body.length > 1e4) req.destroy(); });
    req.on('end', () => {
      try {
        const { k, id, v } = JSON.parse(body), s = read(name);
        if (k === 'week') s.week = Math.max(0, Math.round(+v) || 0);
        else if (['done', 'rel', 'got'].includes(k) && /^[\w#-]{1,40}$/.test(id)) { s[k] ??= {}; v ? s[k][id] = Math.floor(Date.now() / 1000) : delete s[k][id]; }
        else throw new Error('invalid');
        fs.writeFileSync(stateFile(name), JSON.stringify(s, null, 1));
        res.end('ok');
      } catch { res.writeHead(400).end('invalid request'); }
    });
    return;
  }

  if (p === '/') return res.writeHead(302, { Location: '/map/' }).end();
  let file = path.join(ROOT, path.normalize(p));
  if (!file.startsWith(ROOT) || p.includes('/.')) return res.writeHead(403).end();
  if (fs.existsSync(file) && fs.statSync(file).isDirectory()) {
    if (!p.endsWith('/')) return res.writeHead(302, { Location: p + '/' }).end();
    file = path.join(file, 'index.html');
  }
  fs.readFile(file, (err, data) => {
    // A project with no progress yet simply has no state file.
    if (err && file.endsWith('state.json')) return res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }).end('{}');
    err ? res.writeHead(404).end('not found')
      : res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' }).end(data);
  });
}).listen(PORT, '127.0.0.1', () => console.log(`Skilltree: http://localhost:${PORT}`));

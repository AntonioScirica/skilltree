---
name: skilltree
description: Turn a contract, quote or statement of work (PDF or text) into a game-style skill-tree roadmap in this repo - levels, nodes and small tasks that light up as work gets done, plus what the client owes and when. Use when the user gives a contract/quote/SOW/capitolato/preventivo and asks for a roadmap, project map, skill tree, task breakdown, or to "set up the project".
---

# Skilltree: from a contract to a skill tree

Read a contract, then write one project folder in `projects/<name>/`. The map (`map/`) draws it as an infinite wall: levels along a spine, feature nodes on both sides, tasks as small dots that light up.

**Model to copy: `projects/example/roadmap.js`.** Read it first. Same shape, do not invent a new one.

**Language:** write the project content in the language of the contract (or the user's). Set `lang: 'it'` or `'en'` for the map interface.

## 1. Read the whole contract

Read every page, annexes included (long PDFs in chunks; text-only PDFs with `pdftotext -layout`). If it cites a document you do not have (specification, master document, annex), ask for it: it often prevails in case of conflict.

Extract, kept apart:

1. **Phases and calendar**: name, weeks, what is delivered.
2. **Features**: every requirement, with its row number if there is a matrix.
3. **What the client must provide**, and when (access, content, decisions).
4. **Written approvals**: what, within how many days, how many revision rounds.
5. **Acceptance tests and payments**: instalments, amounts, what triggers them, deadlines.
6. **Warranty and bug reports**: duration, response times, required format.
7. **Exclusions, deviations, optional modules**: do not plan them.
8. **Open choices** the contract leaves to the client.

Then ask the user only what changes the plan: the client's contact person, the current platform if there is a migration, optional modules in or out.

## 2. Write `projects/<name>/`

`<name>`: lowercase letters, digits, hyphens. All `.js` files in the folder are loaded alphabetically and fill `window.*`. One `roadmap.js` is enough for a small project. For a big one, split: `levels-a.js` → `window.LEVELS_A`, `levels-b.js` → `window.LEVELS_B`, and `roadmap.js` uses `levels: [...window.LEVELS_A, ...window.LEVELS_B]`.

`window.ROADMAP` fields: `name`, `lang`, `referente` (the client's contact, shown in the panel), `start` (Monday of week 1 or `null`), `levels`, `client`, `send`, `rituals`.

### Levels, nodes, tasks

One level per calendar block, plus a kickoff level first (contract, accounts, setup) and an after-delivery level last if there is a warranty or monitoring period.

```js
{ id: 'p1', fase: 'Phase 1', t: 'Website and catalogue', w: [3, 5], d: 'One line on what closes this level.',
  nodes: [
    { id: 'db', t: 'Database and roles', req: '11-14', tasks: ['Draw the database schema', 'Enable row level security', …] },
    { id: 'g1', gate: true, t: 'Phase 1 test · instalment 2', tasks: […] },
  ] }
```

Rules:
- **A task** is one verifiable action, 30-90 minutes of work, **50 characters at most**. No "and" joining two jobs: split.
- **6-12 tasks per node**, in the order they are done: schema → server logic → interface → test. One test task for every critical rule (permissions, server-side blocks, isolation between customers).
- **Node ids**: short, unique across the project, stable. The user says them out loud ("do node db").
- **Task id = node id + position.** Append new tasks at the end, never in the middle, or saved progress shifts.
- Internal nodes: `sec1`, `sec2`… and `secfin` (security audit at the end of a phase), `pc1`… (test plan), `gate: true` (acceptance test + payment). Give every phase a security audit node before its test.
- `req`: the contract rows the node covers, if the contract numbers them. `note`: anything odd about the node.
- Big project: have two subagents write the levels in parallel (half each, separate files), giving them this schema and the contract text; then check unique ids and lengths.
- Do not plan what the contract excludes. If a feature is not assigned to any phase, place it where it makes sense and say so in `note`.
- Do not invent features the contract does not include, even obvious ones: report them as "not included, to be quoted".

### `client`: what the client owes

```js
{ id: 'c3', w: 1, per: 'design', t: 'Logo, photos of products and shop' }
```

`w` = the week when its absence **blocks** the work (0 = before kickoff). `per` = the id of the level that stops without it. Order the list by what is needed first. Only ask for what the contract puts on the client.

### `send`: what you owe the client

Proposals, invoices, test plans, reports, documents to approve, with the week they are due. The weekly report is added by the map on its own.

### `rituals`

Things to do by hand on a fixed rhythm (weekly report, chasing, security audit at the end of each phase, written notice of delays).

## 3. Check

- `node tools/done.js <name> --node <id>` on two or three nodes: the tasks come out.
- No task over 50 characters; node ids unique; every `client[].per` is an existing level id. A quick script:

```bash
node -e 'global.window={};const fs=require("fs"),d="projects/NAME/";for(const f of fs.readdirSync(d).filter(f=>f.endsWith(".js")).sort())require("./"+d+f);const R=window.ROADMAP,n=R.levels.flatMap(l=>l.nodes),ids=n.map(x=>x.id);console.log(n.length,"nodes",n.reduce((s,x)=>s+x.tasks.length,0),"tasks · duplicate ids:",ids.filter((x,i)=>ids.indexOf(x)!==i),"· longest task:",Math.max(...n.flatMap(x=>x.tasks.map(t=>t.length))),"· bad per:",R.client.filter(c=>!R.levels.some(l=>l.id===c.per)).map(c=>c.id))'
```

- Start the map (`node map/server.js`) and open `http://localhost:4173/map/?p=<name>`.

## 4. Report to the user

Always, plainly:
- how many levels, nodes, tasks and client items;
- **where the contract is ambiguous or contradicts itself** (with an annex, a master document, another page): these are the real risks;
- phases that look overloaded for their weeks;
- what you assumed without being able to verify.

## While working on the project

The map is the single source of truth.
- Work finished **and verified** → light the task: `node tools/done.js <name> "text or id"`. An open map updates by itself.
- "Do node X" → `node tools/done.js <name> --node X`, do the tasks in order, light them one by one.
- Work with no matching task → append it to the right node, then light it.

## Safety

- Real projects hold a client's contract, prices and deadlines. `projects/` is git-ignored except the example: never publish a real project, and never copy client names or amounts into the example or the README.
- No secrets in project files.

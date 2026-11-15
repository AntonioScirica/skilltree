# Skilltree

Give Claude a contract. Get a game-style skill tree of everything you have to build, where each task lights up when it is done.

<a href="docs/skilltree.mp4"><img src="docs/skilltree.gif" alt="skilltree: a contract becomes a skill tree, tasks light up, the client gets a page" width="100%"></a>

*[Leggi in italiano](README.it.md)*

- An **infinite wall** you drag and zoom: levels along a spine, feature nodes on both sides, tasks as small dots.
- **Tasks light up** when you click them, or when Claude finishes the work and marks them.
- A side panel with **what to do now**, **what the client owes you and when**, and **what you owe the client**.
- Works on your computer. No account, no database, no build step. Just Node.

## Quick start

You need [Node.js](https://nodejs.org) 18+ and [Claude Code](https://claude.com/claude-code).

```bash
git clone https://github.com/AntonioScirica/skilltree.git
```

```bash
cd skilltree
```

```bash
node map/server.js
```

Open http://localhost:4173. You will see the example project, an invented bakery website.

## Make your own map

Open the folder in Claude Code and say:

> Use the skilltree skill on this contract: /path/to/contract.pdf

Claude reads the whole contract and writes `projects/<name>/`: levels, nodes, small tasks, what the client must provide and by which week. It then tells you where the contract is ambiguous and which phases look overloaded.

Open `http://localhost:4173/map/?p=<name>`.

The skill lives in `.claude/skills/skilltree/`, so it is available as soon as you open this folder in Claude Code. To use it in every project, copy that folder to `~/.claude/skills/`.

## Lighting tasks

- **By hand:** click a dot on the map, or tick it in the side panel.
- **From the terminal:**

```bash
node tools/done.js example "Draw the database schema"
```

- **By Claude, while you work:** tell it "do node db". It lists that node's tasks, does them in order and lights them one by one. An open map updates by itself within a few seconds.

Each node shows a short code next to its name (`db`, `catalog`, `orders`). That is what you say to Claude.

## Where your data lives, and how to keep it

Everything is plain files in this folder.

| What | Where |
|---|---|
| The plan (levels, tasks, client items) | `projects/<name>/*.js` |
| Your progress (what is lit, current week) | `projects/<name>/state.json` |

**Back it up.** Copy the `projects/` folder, or keep it in a **private** git repository: every commit is a snapshot of where you were, so you can show progress week by week.

**Real projects are ignored by git on purpose.** The `.gitignore` tracks only the example, because a real project contains your client's contract, prices and deadlines. If you fork this repo publicly, your projects stay on your computer. To version them, use a private repository and remove the two `projects` lines from `.gitignore`.

**Use it on two computers.** Put `projects/` in a private repo or a synced folder. `state.json` is small and merges easily.

**Reset a project.** Delete its `state.json`.

## Cloud mode: a login for you, a private page for your client

Optional, about 15 minutes, needs a free Supabase project. You open the map from anywhere behind a login; your client gets a private link where they see what they owe you and when, upload files, write answers and tick the checks of each release. They never see your tasks.

**[How to turn it on → cloud/README.md](cloud/README.md)**

## Going further on your own

If you would rather wire the map to your own backend, the data model grows naturally:

1. Move each project into one database row: the plan as JSON, the progress as JSON.
2. Change two functions in `map/index.html`: `post()` writes a change, `pull()` reads the state. Point them at your database instead of `/api/state` and `state.json`.
3. Give the client a page that reads **only** the `client` list, behind a secret link, and let them upload files or tick items. Never send them the levels and tasks.
4. Put the access rules in the database (row level security), not in the page.

## How a project file looks

See [`projects/example/roadmap.js`](projects/example/roadmap.js). The rules Claude follows are in [`.claude/skills/skilltree/SKILL.md`](.claude/skills/skilltree/SKILL.md): a task is one verifiable action of 30-90 minutes, 50 characters at most, 6-12 per node.

## License

MIT © Antonio Scirica

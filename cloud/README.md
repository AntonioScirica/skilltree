# Cloud mode: a login for you, a private page for your client

Optional. With it:

- **You** open the map from anywhere, behind a login. The plan comes from the database, not from files.
- **Your client** gets a private link to a page with what they owe you and by when. They can upload files, write answers and tick the checks of each release. They never see your tasks.
- Files and answers show up in your side panel, under the item they belong to.

It takes about 15 minutes and a free [Supabase](https://supabase.com) project. Everything is prefixed `skilltree_`, so it can live in a project you already use for something else.

*Italiano più sotto.*

## Turn it on

1. **Create a Supabase project** (or pick an existing one).
2. **Run the schema.** Open *SQL Editor*, paste the whole of [`schema.sql`](schema.sql), run it.
3. **Create your user.** *Authentication → Users → Add user*, with your email and a password, "Auto confirm" on. Then in the SQL Editor:
   ```sql
   insert into public.skilltree_admins (uid) select id from auth.users where email = 'you@example.com';
   ```
4. **Fill in [`map/config.js`](../map/config.js)** with the project URL and the **anon / publishable** key (*Project Settings → API*). These two are public by design.
5. **Give the tools the secret key.** Create a file named `.env` in the repo root (it is git-ignored):
   ```
   SUPABASE_URL=https://YOUR-PROJECT.supabase.co
   SUPABASE_SERVICE_KEY=your service_role / secret key
   ```
   This key bypasses every rule. It stays on your computer. Never put it in `map/config.js`.
6. **Upload a project:**
   ```bash
   node --env-file=.env tools/push.js example
   ```
7. **Try it locally:** `node map/server.js`, open http://localhost:4173, sign in. Top left you now have *Client page*, *Copy client link* and *Sign out*.
8. **Publish.** Deploy **only the `map/` folder** (for instance on Vercel: *Root Directory* = `map`). It contains no project data: plans and progress are in the database. Send your client the link from *Copy client link*.

From then on:

```bash
node --env-file=.env tools/push.js my-project          # after you change the plan
```

```bash
node --env-file=.env tools/done.js my-project "db#3"   # light a task (Claude does this while working)
```

`push.js` never touches your progress, the client's ticks or the client link.

## Releases with a checklist

Add `releases` to a project's `ROADMAP` and push. The client sees each release with what is new and a list to tick; you see the ticks.

```js
releases: [
  { v: '0.1', data: '27 Nov 2026', titolo: 'Home and menu', novita: ['Home page with opening hours'], controlli: ['Open the home page on a phone', 'Change the opening hours and see them online'] },
],
```

Append new releases at the end. Do not change the `v` or the order of `controlli` of a release already sent: the ticks are tied to them.

## How it stays private

- Nothing about your projects is in the published files. The map asks the database after login; a user who is not in `skilltree_admins` sees nothing.
- The client link carries a long random token after the `#`, so it never reaches server logs. With it one can only read that project's client list and add to it: no reading of files, no listing, no deleting.
- Uploaded files go to a private bucket. Only you can download them.
- The rules are in the database (`schema.sql`), not in the page. `cloud/tests/` checks them: on an empty local Postgres, `psql -d test -f cloud/tests/fake-supabase.sql -f cloud/schema.sql -f cloud/tests/access.sql` must print `ok` on every line.

If a client link leaks, give the project a new token:

```sql
update public.skilltree_projects set client_token = replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '') where slug = 'my-project';
```

## Turn it off

Empty the `skilltree` bucket from the Storage page, run [`uninstall.sql`](uninstall.sql), and clear `map/config.js`. The map goes back to local files.

---

# Modalità cloud, in breve

Facoltativa. Tu apri la mappa da ovunque dietro login; il cliente riceve un link riservato a una pagina con cosa deve mandare ed entro quando, dove carica file, scrive risposte e spunta i controlli di ogni versione. I tuoi task non li vede mai.

1. Crea un progetto Supabase gratuito.
2. Incolla `schema.sql` nel *SQL Editor* ed eseguilo.
3. Crea il tuo utente (*Authentication → Users*), poi rendilo amministratore con la riga SQL qui sopra.
4. Metti indirizzo e chiave **anon** in `map/config.js`.
5. Crea `.env` nella cartella del repo con `SUPABASE_URL` e `SUPABASE_SERVICE_KEY` (la chiave segreta: resta sul tuo computer).
6. `node --env-file=.env tools/push.js example`
7. Prova in locale con `node map/server.js`.
8. Pubblica **solo la cartella `map/`** e manda al cliente il link di *Copy client link*.

Per spegnerla: svuota il bucket `skilltree`, esegui `uninstall.sql`, svuota `map/config.js`.

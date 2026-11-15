# Skilltree

Dai a Claude un contratto. Ottieni un albero delle abilità stile videogioco con tutto quello che devi costruire, dove ogni task si accende quando è fatto.

<a href="docs/skilltree.mp4"><img src="docs/skilltree.gif" alt="skilltree: a contract becomes a skill tree, tasks light up, the client gets a page" width="100%"></a>

*[Read in English](README.md)*

- Un **muro infinito** da trascinare e ingrandire: i livelli lungo una dorsale, i nodi delle funzioni ai lati, i task come piccoli pallini.
- **I task si accendono** quando li clicchi, o quando Claude finisce il lavoro e li segna.
- Un pannello laterale con **cosa fare adesso**, **cosa ti deve il cliente e quando**, **cosa devi tu al cliente**.
- Gira sul tuo computer. Niente account, niente database, niente build. Solo Node.

## Avvio rapido

Servono [Node.js](https://nodejs.org) 18+ e [Claude Code](https://claude.com/claude-code).

```bash
git clone https://github.com/AntonioScirica/skilltree.git
```

```bash
cd skilltree
```

```bash
node map/server.js
```

Apri http://localhost:4173. Vedrai il progetto di esempio, il sito inventato di un panificio.

## Crea la tua mappa

Apri la cartella in Claude Code e scrivi:

> Usa la skill skilltree su questo contratto: /percorso/del/contratto.pdf

Claude legge tutto il contratto e scrive `projects/<nome>/`: livelli, nodi, task piccoli, cosa deve dare il cliente ed entro quale settimana. Poi ti dice dove il contratto è ambiguo e quali fasi sembrano troppo cariche.

Apri `http://localhost:4173/map/?p=<nome>`.

La skill sta in `.claude/skills/skilltree/`, quindi è disponibile appena apri questa cartella in Claude Code. Per usarla in ogni progetto, copia quella cartella in `~/.claude/skills/`.

Per avere la mappa in italiano, nel file del progetto metti `lang: 'it'`. La skill lo fa da sola se il contratto è in italiano.

## Accendere i task

- **A mano:** clicca un pallino sulla mappa, o spuntalo nel pannello laterale.
- **Dal terminale:**

```bash
node tools/done.js example "Draw the database schema"
```

- **Da Claude, mentre lavori:** digli "fai il nodo db". Elenca i task di quel nodo, li fa in ordine e li accende uno a uno. La mappa aperta si aggiorna da sola in pochi secondi.

Ogni nodo mostra una sigla accanto al nome (`db`, `catalog`, `orders`). È quella che dici a Claude.

## Dove stanno i tuoi dati, e come conservarli

È tutto in file semplici dentro questa cartella.

| Cosa | Dove |
|---|---|
| Il piano (livelli, task, richieste al cliente) | `projects/<nome>/*.js` |
| Il tuo avanzamento (cosa è acceso, settimana) | `projects/<nome>/state.json` |

**Fai una copia.** Copia la cartella `projects/`, oppure tienila in un repository git **privato**: ogni commit è una fotografia di dove eri, così puoi mostrare l'avanzamento settimana per settimana.

**I progetti veri sono ignorati da git apposta.** Il `.gitignore` tiene traccia solo dell'esempio, perché un progetto vero contiene il contratto, i prezzi e le scadenze del tuo cliente. Se fai un fork pubblico, i tuoi progetti restano sul tuo computer. Per versionarli, usa un repository privato e togli le due righe `projects` dal `.gitignore`.

**Usarla su due computer.** Metti `projects/` in un repo privato o in una cartella sincronizzata. `state.json` è piccolo e si unisce senza problemi.

**Azzerare un progetto.** Cancella il suo `state.json`.

## Modalità cloud: login per te, pagina riservata per il cliente

Facoltativa, circa 15 minuti, serve un progetto Supabase gratuito. Apri la mappa da ovunque dietro login; il cliente riceve un link riservato dove vede cosa ti deve ed entro quando, carica file, scrive risposte e spunta i controlli di ogni versione. I tuoi task non li vede mai.

**[Come attivarla → cloud/README.md](cloud/README.md)**

## Se preferisci collegarla a un tuo sistema

Il modello dei dati cresce in modo naturale:

1. Sposta ogni progetto in una riga di database: il piano come JSON, l'avanzamento come JSON.
2. Cambia due funzioni in `map/index.html`: `post()` scrive una modifica, `pull()` legge lo stato. Puntale al tuo database invece che a `/api/state` e `state.json`.
3. Dai al cliente una pagina che legge **solo** l'elenco `client`, dietro un link segreto, dove può caricare file o spuntare voci. Non mandargli mai livelli e task.
4. Metti le regole di accesso nel database (row level security), non nella pagina.

## Com'è fatto un file di progetto

Guarda [`projects/example/roadmap.js`](projects/example/roadmap.js). Le regole che Claude segue sono in [`.claude/skills/skilltree/SKILL.md`](.claude/skills/skilltree/SKILL.md): un task è una sola azione verificabile da 30-90 minuti, massimo 50 caratteri, 6-12 per nodo.

## Licenza

MIT © Antonio Scirica

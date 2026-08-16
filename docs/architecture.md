# Architettura

## Perché un backend separato invece di tutto on-device

Gli algoritmi delle fasi future (assistente asta, formazione ottimale, consigliere scambi) devono poter evolvere e i dati di quotazioni/voti devono essere raccolti e condivisi senza duplicare la logica di scraping su ogni telefono. Il backend centralizza:

- la raccolta dati (scraping/import)
- il calcolo degli algoritmi (fasi 2-4)
- lo storico (quotazioni nel tempo, statistiche per giornata)

Il mobile resta un client leggero che consuma API REST e mantiene una cache locale per la consultazione offline.

## Componenti

- **backend/**: Node.js + TypeScript, Fastify, Prisma ORM su SQLite in sviluppo (compatibile Postgres in produzione cambiando solo la connection string).
- **mobile/**: Flutter, Riverpod per lo state management, `dio` per la rete, `go_router` per la navigazione, `hive` per la cache locale.

## Modello dati (Fase 1)

- `Team` — squadre di Serie A
- `Player` — anagrafica giocatore, ruolo Classic/Mantra, quotazione attuale/iniziale, FVM
- `PlayerQuotation` — storico delle quotazioni nel tempo (serve per i trend prezzo e, in Fase 2, per l'assistente asta)
- `MatchdayStat` — voto/fantavoto e statistiche per giornata (serve per calcolare rendimento in Fase 3)
- `DataSourceRun` — log di ogni esecuzione di scraper/importer (fonte, esito, timestamp, eventuale errore) per diagnosticare rapidamente quando una fonte smette di funzionare

## Pattern adapter per le fonti dati

Ogni fonte dati (import quotazioni, scraping voti, scraping calendario) implementa la stessa interfaccia `DataSourceAdapter` (`backend/src/scraper/types.ts`). Questo isola il resto del sistema dai dettagli di parsing di una specifica pagina/file, così che quando una fonte cambia struttura si aggiorna solo il suo adapter, non il resto dell'app. Vedi [data-sources.md](data-sources.md) per il dettaglio delle fonti scelte e i rischi noti.

## Roadmap algoritmi (fasi future, non ancora implementate)

- **Assistente Asta** (Fase 2): dato lo stato live dell'asta (chi è stato preso, a che prezzo, budget rimanenti), suggerisce se rilanciare, abbandonare, chi chiamare e a quanto, basandosi su FVM, quotazione, budget residuo e obiettivi dell'utente.
- **Formazione ottimale** (Fase 3): dato un budget e una lista di giocatori obiettivo, propone la rosa che massimizza il valore atteso (probabile un solver di ottimizzazione tipo knapsack/ILP lato backend).
- **Consigliere Scambi** (Fase 4): valuta uno scambio proposto confrontando rendimento storico, trend quotazioni e bisogno di reparto.

Questi algoritmi vivranno lato backend (endpoint dedicati) proprio per poter essere aggiornati senza richiedere una nuova release dell'app.

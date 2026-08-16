# Fonti dati

Non esiste un'API ufficiale gratuita della Lega Serie A per quotazioni/voti fantacalcio: questi dati sono specifici degli editori fantacalcio (Fantacalcio.it e simili) e non hanno un'API pubblica.

## Fonti in uso (aggiornato in Fase 5)

| Dato | Fonte | Meccanismo | Fragilità |
|---|---|---|---|
| Quotazioni (Listone) — import manuale | File Excel/CSV pubblicato ogni estate, scaricato e caricato dall'utente | `POST /sync/quotazioni` (`quotazioniAdapter.ts`) | Bassa — file strutturato, non HTML da parsare |
| Quotazioni — sync automatica | Pagina pubblica `fantacalcio.it/quotazioni-fantacalcio` | Scraping HTML via `POST /sync/quotazioni-online` (`quotazioniOnlineAdapter.ts`) | Media — dipende dagli attributi `data-col-key`/`data-value` della tabella, più stabili delle classi CSS ma non garantiti nel tempo |
| Voti/fantavoto per giornata | Pagina pubblica `fantacalcio.it/voti-fantacalcio-serie-a/{stagione}/{giornata}` | Scraping HTML via `POST /sync/voti` (`votiAdapter.ts`) | Alta — pagine di questo tipo cambiano struttura più spesso; inoltre le etichette esatte di ammonizioni/espulsioni non sono ancora state verificate con dati reali (vedi sotto) |
| Calendario/risultati Serie A | — | `calendarioAdapter.ts` resta uno **scaffold**, non implementato: l'utente sceglie a mano la giornata da importare, non serve per ora | — |

### Perché scraping HTML e non l'export Excel

Fantacalcio.it espone anche endpoint di export Excel ufficiali (`/api/v1/Excel/prices/{id}` e `/api/v1/Excel/votes/{id}/{giornata}`, gli stessi dietro ai pulsanti "Scarica" del sito) che sarebbero un formato più robusto di un HTML da interpretare. **Verificato che richiedono una sessione utente autenticata** (risposta 401 senza login): usarli avrebbe richiesto salvare le credenziali dell'account fantacalcio.it dell'utente e automatizzare il login, cosa esplicitamente scartata per il rischio di sicurezza (memorizzare una password di terzi) e perché probabilmente viola i termini d'uso del sito sull'automazione. Le pagine HTML pubbliche (senza login) sono quindi la fonte scelta, accettando la maggiore fragilità come compromesso consapevole.

### Note implementative

- **Formato stagione**: la pagina voti accetta l'URL nel formato `{stagione}/{giornata}` dove `{stagione}` è la stessa stringa `"2025-26"` già usata in tutta l'app (verificato: `/voti-fantacalcio-serie-a/2025-26/16` mostra correttamente la giornata 16). La pagina quotazioni invece non accetta un parametro stagione nello scraping attuale: prende sempre la pagina di default (l'ultima mostrata dal sito), quindi la `stagione` passata a `/sync/quotazioni-online` è solo l'etichetta con cui l'utente vuole salvare quei dati nel nostro DB, non necessariamente coincide con l'etichetta interna di fantacalcio.it.
- **Corrispondenza giocatori tra pagine**: `votiAdapter` cerca il giocatore per `(nome, teamId, stagione)` — se il nome è scritto in modo leggermente diverso tra la pagina quotazioni e quella voti (es. abbreviazioni), la riga viene saltata silenziosamente invece di bloccare l'intero import (verificato: su 513 giocatori e 200 righe voti importate in un test reale, alcuni giocatori panchinari non sono stati abbinati — comportamento accettabile, non un errore).
- **Ammonizioni/espulsioni**: le etichette `title` usate dal sito per cartellino giallo/rosso non sono state confermate con un esempio reale (la stagione 2026/27 non era ancora iniziata al momento dell'implementazione, quindi nessuna giornata con cartellini era disponibile per verificare). Il codice in `votiAdapter.ts` prova alcune etichette plausibili (`Ammonizione`, `Espulsione`) con fallback a 0 se non trovate — da verificare e correggere a stagione iniziata, guardando `DataSourceRun`/dati importati dopo una giornata con cartellini reali.
- **Nomi squadra**: derivati dallo slug nell'URL del profilo giocatore (es. `/squadre/hellas-verona/...` → "Hellas Verona"), non da una tabella fissa — cosi' non serve aggiornare il codice ad ogni promozione/retrocessione. Se una squadra scraping ha un nome leggermente diverso da come fu inserita manualmente in passato (es. Fase 1), si creano due righe `Team` distinte: limite noto, non risolto automaticamente.

## Come riconoscere una fonte rotta

Ogni esecuzione di adapter scrive una riga in `DataSourceRun` (source, esito, timestamp, errore, numero di record). Un aumento di `status = "error"` per una fonte specifica, o un `recordsCount` insolitamente basso, indica che l'HTML è cambiato e va aggiornato il selettore nel relativo adapter — nessun altro componente del sistema va toccato grazie al pattern adapter. Sia `quotazioniOnlineAdapter` che `votiAdapter` sollevano esplicitamente un errore se non riconoscono nessun giocatore, invece di salvare silenziosamente zero righe.

## Note legali/etiche

Verificato `robots.txt` di fantacalcio.it: nessuna regola blocca i path usati (`/quotazioni-fantacalcio`, `/voti-fantacalcio-serie-a`). Lo scraping è comunque mirato a dati pubblicamente visibili, per uso personale all'interno di un'app che **non** ridistribuisce né rivende i dati, innescato manualmente dall'utente (nessun job che interroga il sito di continuo). Se in futuro fantacalcio.it dovesse vietare esplicitamente questo tipo di accesso, la fonte va sostituita — il pattern adapter rende questo cambio isolato.

## Alternative valutate

- **Export Excel autenticato di fantacalcio.it**: scartato, vedi sopra (richiede credenziali utente).
- **API a pagamento** (es. API-Football): scartata per ora dall'utente, ma l'architettura ad adapter permette di aggiungerla in futuro come fonte più affidabile per calendario/risultati, mantenendo lo scraping solo per i dati fantacalcio-specifici che restano privi di alternativa.
- **leghefantacalcio.it**: segnalato dall'utente (Fase 6) come possibile fonte futura per calendario/avversari, quando si deciderà di far tener conto anche delle partite al consiglio "Formazione titolare" (oggi basato solo sul rendimento recente dei giocatori). Da valutare con una ricerca dedicata — struttura della pagina, eventuale autenticazione richiesta, `robots.txt` — con lo stesso approccio già usato per scegliere le fonti quotazioni/voti.

import * as cheerio from "cheerio";
import type { DataSourceAdapter } from "./types.js";
import { upsertQuotazione } from "./upsertQuotazione.js";

const QUOTAZIONI_URL = "https://www.fantacalcio.it/quotazioni-fantacalcio";

export interface QuotazioniOnlineInput {
  stagione: string;
}

// Scraping della pagina pubblica quotazioni di fantacalcio.it — non
// richiede login, a differenza dell'export Excel dietro autenticazione
// (verificato: 401 senza sessione). Vedi docs/data-sources.md.
//
// Fragilita' nota: dipende dagli attributi `data-col-key`/`data-value`
// della tabella, piu' stabili delle classi CSS ma comunque soggetti a
// rompersi se il sito viene ridisegnato — da qui il controllo finale che
// solleva un errore esplicito se non viene riconosciuto nessun giocatore,
// invece di salvare silenziosamente zero righe.
export const quotazioniOnlineAdapter: DataSourceAdapter<QuotazioniOnlineInput> = {
  source: "quotazioni-online",

  async run({ stagione }) {
    const response = await fetch(QUOTAZIONI_URL, {
      headers: { "User-Agent": "Mozilla/5.0 (compatible; FantaAppPersonalUse/1.0)" },
    });
    if (!response.ok) {
      throw new Error(`fantacalcio.it ha risposto ${response.status} per le quotazioni`);
    }
    const html = await response.text();
    const $ = cheerio.load(html);

    let count = 0;

    for (const el of $("table.pills-table tbody tr").toArray()) {
      const row = $(el);
      const ruolo = row.find(".player-role-classic .role").attr("data-value")?.toUpperCase();
      const nome = row.find(".player-name a span").first().text().trim();
      const href = row.find(".player-name a").attr("href") ?? "";
      const squadraMatch = href.match(/\/squadre\/([a-z0-9-]+)\//);
      const squadra = squadraMatch ? capitalizzaSquadra(squadraMatch[1]) : null;
      const quotazioneIniziale = Number(row.find('[data-col-key="c_qi"]').text().trim());
      const quotazioneAttuale = Number(row.find('[data-col-key="c_qa"]').text().trim());
      const fvmTesto = row.find('[data-col-key="c_fvm"]').text().trim();
      const fvm = fvmTesto ? Number(fvmTesto) : null;
      const ruoliMantra = row
        .find(".player-role-mantra .role-mantra")
        .toArray()
        .map((r) => $(r).attr("data-value")?.toUpperCase())
        .filter((v): v is string => Boolean(v))
        .join(",");

      if (
        !ruolo ||
        !nome ||
        !squadra ||
        !Number.isFinite(quotazioneIniziale) ||
        !Number.isFinite(quotazioneAttuale)
      ) {
        continue; // riga non riconosciuta (es. intestazione): salta invece di interrompere l'import
      }

      await upsertQuotazione({
        ruolo,
        nome,
        squadra,
        quotazioneIniziale,
        quotazioneAttuale,
        fvm,
        stagione,
        ruoliMantra: ruoliMantra || undefined,
      });
      count++;
    }

    if (count === 0) {
      throw new Error(
        "nessun giocatore riconosciuto nella pagina quotazioni: la struttura della pagina potrebbe essere cambiata",
      );
    }

    return { recordsCount: count };
  },
};

function capitalizzaSquadra(slug: string): string {
  return slug
    .split("-")
    .map((parola) => parola.charAt(0).toUpperCase() + parola.slice(1))
    .join(" ");
}

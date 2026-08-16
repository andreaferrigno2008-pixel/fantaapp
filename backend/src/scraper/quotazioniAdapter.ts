import { parse } from "csv-parse/sync";
import type { DataSourceAdapter } from "./types.js";
import { upsertQuotazione } from "./upsertQuotazione.js";

// Formato CSV atteso (intestazione richiesta, delimitatore virgola, UTF-8):
//   ruolo,nome,squadra,quotazione_iniziale,quotazione_attuale,fvm
// "fvm" e' opzionale. E' il formato piu' affidabile della Fase 1 perche'
// e' un file strutturato scaricato dall'utente (il "Listone" ufficiale),
// non una pagina HTML da interpretare — vedi docs/data-sources.md.
// Per l'import automatico dal sito vedi quotazioniOnlineAdapter.ts.

interface QuotazioniRow {
  ruolo: string;
  nome: string;
  squadra: string;
  quotazione_iniziale: string;
  quotazione_attuale: string;
  fvm?: string;
}

export interface QuotazioniInput {
  csvContent: string;
  stagione: string;
}

export const quotazioniAdapter: DataSourceAdapter<QuotazioniInput> = {
  source: "quotazioni-import",

  async run({ csvContent, stagione }) {
    const rows: QuotazioniRow[] = parse(csvContent, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    });

    for (const row of rows) {
      await upsertQuotazione({
        ruolo: row.ruolo,
        nome: row.nome,
        squadra: row.squadra,
        quotazioneIniziale: Number(row.quotazione_iniziale),
        quotazioneAttuale: Number(row.quotazione_attuale),
        fvm: row.fvm ? Number(row.fvm) : null,
        stagione,
      });
    }

    return { recordsCount: rows.length };
  },
};

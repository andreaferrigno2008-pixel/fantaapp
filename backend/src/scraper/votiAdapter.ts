import * as cheerio from "cheerio";
import { prisma } from "../db/client.js";
import { isRuoloClassic } from "../domain/ruoli.js";
import type { DataSourceAdapter } from "./types.js";

export interface VotiInput {
  stagione: string;
  giornata: number;
}

const TITOLI_BONUS: Record<string, "gol" | "assist" | "autogol"> = {
  "Gol segnati": "gol",
  Assist: "assist",
  Assists: "assist",
  Autoreti: "autogol",
  Autorete: "autogol",
};

// Titoli non ancora confermati con dati reali al momento
// dell'implementazione (stagione 2026/27 non ancora iniziata, nessuna
// giornata con ammonizioni/espulsioni disponibile per verificare
// l'etichetta esatta usata dal sito). Se il sito li chiama diversamente,
// vengono semplicemente ignorati (restano a 0), non causano un errore —
// da verificare a stagione iniziata e correggere qui se serve.
const TITOLI_CARTELLINI: Record<string, "ammonizioni" | "espulsioni"> = {
  Ammonizione: "ammonizioni",
  "Cartellino giallo": "ammonizioni",
  Espulsione: "espulsioni",
  "Cartellino rosso": "espulsioni",
};

// Scraping della pagina pubblica voti di fantacalcio.it, non richiede
// login (a differenza dell'export Excel — vedi docs/data-sources.md). URL
// verificato: /voti-fantacalcio-serie-a/{stagione}/{giornata}, dove
// {stagione} usa lo stesso formato "2025-26" gia' usato nel resto
// dell'app.
export const votiAdapter: DataSourceAdapter<VotiInput> = {
  source: "voti-scraper",

  async run({ stagione, giornata }) {
    const url = `https://www.fantacalcio.it/voti-fantacalcio-serie-a/${stagione}/${giornata}`;
    const response = await fetch(url, {
      headers: { "User-Agent": "Mozilla/5.0 (compatible; FantaAppPersonalUse/1.0)" },
    });
    if (!response.ok) {
      throw new Error(`fantacalcio.it ha risposto ${response.status} per i voti`);
    }
    const html = await response.text();
    const $ = cheerio.load(html);

    let count = 0;

    for (const table of $("table.grades-table").toArray()) {
      const $table = $(table);
      const squadra = $table.find(".team-name").first().text().trim();
      if (!squadra) continue;

      const team = await prisma.team.findUnique({ where: { nome: squadra } });
      if (!team) continue; // squadra non presente nel nostro DB: importare prima le quotazioni

      for (const el of $table.find("tbody tr").toArray()) {
        const row = $(el);
        const ruolo = row.find(".role").first().attr("data-value")?.toUpperCase();
        const nome = row.find(".player-name span").first().text().trim();
        if (!ruolo || !nome || !isRuoloClassic(ruolo)) continue;

        const player = await prisma.player.findUnique({
          where: { nome_teamId_stagione: { nome, teamId: team.id, stagione } },
        });
        // Giocatore non trovato: capita se il nome e' scritto in modo
        // diverso tra pagina quotazioni e pagina voti (es. abbreviazioni
        // come "Martinez L."). Si salta la riga invece di interrompere
        // l'intero import.
        if (!player) continue;

        const votoTesto = row.find(".player-grade").first().attr("data-value");
        const fantavotoTesto = row.find(".player-fanta-grade").first().attr("data-value");
        const voto = votoTesto ? parseVotoItaliano(votoTesto) : null;
        const fantavoto = fantavotoTesto ? parseVotoItaliano(fantavotoTesto) : null;

        let gol = 0;
        let assist = 0;
        let autogol = 0;
        let ammonizioni = 0;
        let espulsioni = 0;

        for (const bonusEl of row.find(".player-bonus").toArray()) {
          const titolo = $(bonusEl).attr("title");
          const valore = Number($(bonusEl).attr("data-value") ?? "0");
          if (!titolo || !Number.isFinite(valore)) continue;

          switch (TITOLI_BONUS[titolo]) {
            case "gol":
              gol = valore;
              break;
            case "assist":
              assist = valore;
              break;
            case "autogol":
              autogol = valore;
              break;
          }

          switch (TITOLI_CARTELLINI[titolo]) {
            case "ammonizioni":
              ammonizioni = valore;
              break;
            case "espulsioni":
              espulsioni = valore;
              break;
          }
        }

        await prisma.matchdayStat.upsert({
          where: { playerId_giornata: { playerId: player.id, giornata } },
          update: { voto, fantavoto, gol, assist, ammonizioni, espulsioni, autogol },
          create: {
            playerId: player.id,
            giornata,
            voto,
            fantavoto,
            gol,
            assist,
            ammonizioni,
            espulsioni,
            autogol,
          },
        });
        count++;
      }
    }

    if (count === 0) {
      throw new Error(
        `nessuna statistica riconosciuta per la giornata ${giornata}: giocatori non presenti nel DB ` +
          "(importa prima le quotazioni) oppure struttura della pagina cambiata",
      );
    }

    return { recordsCount: count };
  },
};

function parseVotoItaliano(testo: string): number | null {
  const numero = Number(testo.replace(",", "."));
  return Number.isFinite(numero) ? numero : null;
}

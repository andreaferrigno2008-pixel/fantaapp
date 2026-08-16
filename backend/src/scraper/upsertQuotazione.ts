import { prisma } from "../db/client.js";
import { isRuoloClassic } from "../domain/ruoli.js";

export interface QuotazioneRiga {
  ruolo: string;
  nome: string;
  squadra: string;
  quotazioneIniziale: number;
  quotazioneAttuale: number;
  fvm: number | null;
  stagione: string;
  // CSV di ruoli Mantra (es. "E,W"), opzionale: il formato CSV manuale
  // storico non li include, lo scraping online si'.
  ruoliMantra?: string;
}

// Upsert condiviso tra gli adapter quotazioni (import manuale CSV e
// scraping automatico dal sito, vedi quotazioniAdapter.ts e
// quotazioniOnlineAdapter.ts): stessa logica di scrittura DB, cambia solo
// come si ottiene la riga (file caricato dall'utente vs pagina web).
export async function upsertQuotazione(riga: QuotazioneRiga): Promise<void> {
  if (!isRuoloClassic(riga.ruolo)) {
    throw new Error(`ruolo non valido per "${riga.nome}": ${riga.ruolo}`);
  }

  const team = await prisma.team.upsert({
    where: { nome: riga.squadra },
    update: {},
    create: { nome: riga.squadra, sigla: riga.squadra.slice(0, 3).toUpperCase() },
  });

  const player = await prisma.player.upsert({
    where: {
      nome_teamId_stagione: { nome: riga.nome, teamId: team.id, stagione: riga.stagione },
    },
    update: {
      quotazioneAttuale: riga.quotazioneAttuale,
      fvm: riga.fvm,
      ruoliMantra: riga.ruoliMantra,
    },
    create: {
      nome: riga.nome,
      teamId: team.id,
      ruoloClassic: riga.ruolo,
      quotazioneIniziale: riga.quotazioneIniziale,
      quotazioneAttuale: riga.quotazioneAttuale,
      fvm: riga.fvm,
      stagione: riga.stagione,
      ruoliMantra: riga.ruoliMantra,
    },
  });

  await prisma.playerQuotation.create({
    data: { playerId: player.id, valore: riga.quotazioneAttuale },
  });
}

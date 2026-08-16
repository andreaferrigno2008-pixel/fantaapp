import type { FastifyInstance } from "fastify";
import { prisma } from "../db/client.js";
import { valoreGiocatore } from "../domain/valoreGiocatore.js";
import { valutaScambio, type GiocatoreScambio } from "../domain/scambioAlgoritmo.js";

async function caricaGiocatoriScambio(ids: string[]): Promise<GiocatoreScambio[]> {
  const players = await prisma.player.findMany({
    where: { id: { in: ids } },
    include: {
      statistiche: { orderBy: { giornata: "desc" }, take: 5 },
    },
  });

  return players.map((p) => {
    const voti = p.statistiche.map((s) => s.fantavoto).filter((v): v is number => v != null);
    const mediaFantavotoRecente =
      voti.length > 0 ? voti.reduce((sum, v) => sum + v, 0) / voti.length : null;

    return {
      id: p.id,
      nome: p.nome,
      valoreBase: valoreGiocatore(p),
      mediaFantavotoRecente,
      quotazioneIniziale: p.quotazioneIniziale,
      quotazioneAttuale: p.quotazioneAttuale,
    };
  });
}

export async function registerScambiRoutes(app: FastifyInstance) {
  app.post("/scambi/valuta", async (req, reply) => {
    const body = req.body as { datiIds?: string[]; ricevutiIds?: string[] };

    if (!body.datiIds?.length || !body.ricevutiIds?.length) {
      return reply.code(400).send({ error: "datiIds e ricevutiIds sono obbligatori" });
    }

    const [dati, ricevuti] = await Promise.all([
      caricaGiocatoriScambio(body.datiIds),
      caricaGiocatoriScambio(body.ricevutiIds),
    ]);

    if (dati.length !== body.datiIds.length || ricevuti.length !== body.ricevutiIds.length) {
      return reply
        .code(404)
        .send({ error: "uno o più giocatori indicati non sono stati trovati" });
    }

    try {
      const risultato = valutaScambio({ dati, ricevuti });
      return risultato;
    } catch (err) {
      return reply.code(400).send({
        error: err instanceof Error ? err.message : "impossibile valutare lo scambio",
      });
    }
  });
}

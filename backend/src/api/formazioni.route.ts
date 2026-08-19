import type { FastifyInstance } from "fastify";
import { prisma } from "../db/client.js";
import { isRuoloClassic, type RuoloClassic } from "../domain/ruoli.js";
import { valoreGiocatore } from "../domain/valoreGiocatore.js";
import { generaFormazione, type CandidatoFormazione } from "../domain/formazioneAlgoritmo.js";
import type { SlotConfig } from "../domain/astaAlgoritmo.js";

async function stagioneFormazioneEffettiva(stagioneRichiesta: string) {
  const esiste = await prisma.player.findFirst({
    where: { stagione: stagioneRichiesta },
    select: { id: true },
  });
  if (esiste) return stagioneRichiesta;

  const piuRecente = await prisma.player.findFirst({
    orderBy: { updatedAt: "desc" },
    select: { stagione: true },
  });
  return piuRecente?.stagione ?? stagioneRichiesta;
}

export async function registerFormazioniRoutes(app: FastifyInstance) {
  app.post("/formazioni/genera", async (req, reply) => {
    const body = req.body as {
      stagione: string;
      budgetTotale: number;
      slotP?: number;
      slotD?: number;
      slotC?: number;
      slotA?: number;
      obiettiviPlayerIds?: string[];
    };

    if (!body.stagione || !body.budgetTotale) {
      return reply.code(400).send({ error: "stagione e budgetTotale sono obbligatori" });
    }

    const slot: SlotConfig = {
      P: body.slotP ?? 3,
      D: body.slotD ?? 8,
      C: body.slotC ?? 8,
      A: body.slotA ?? 6,
    };

    const stagione = await stagioneFormazioneEffettiva(body.stagione);
    const players = await prisma.player.findMany({
      where: { stagione },
      include: { team: true },
    });

    const candidati: CandidatoFormazione[] = players
      .filter((p): p is typeof p & { ruoloClassic: RuoloClassic } =>
        isRuoloClassic(p.ruoloClassic),
      )
      .map((p) => ({
        id: p.id,
        ruolo: p.ruoloClassic,
        prezzo: p.quotazioneAttuale,
        fvm: valoreGiocatore(p),
      }));

    let risultato;
    try {
      risultato = generaFormazione({
        budgetTotale: body.budgetTotale,
        slot,
        candidati,
        obiettiviIds: body.obiettiviPlayerIds ?? [],
      });
    } catch (err) {
      return reply.code(400).send({
        error: err instanceof Error ? err.message : "impossibile generare la formazione",
      });
    }

    const playersById = new Map(players.map((p) => [p.id, p]));
    const formazioneConGiocatori = Object.fromEntries(
      Object.entries(risultato.formazione).map(([ruolo, ids]) => [
        ruolo,
        ids.map((id) => playersById.get(id)),
      ]),
    );

    return {
      formazione: formazioneConGiocatori,
      budgetTotale: body.budgetTotale,
      budgetSpeso: risultato.budgetSpeso,
      budgetResiduo: risultato.budgetResiduo,
      fvmTotale: risultato.fvmTotale,
      warning: risultato.warning,
      stagione,
    };
  });
}

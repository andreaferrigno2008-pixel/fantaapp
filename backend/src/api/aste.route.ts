import type { FastifyInstance } from "fastify";
import { prisma } from "../db/client.js";
import { fasciaDiGiocatore } from "../domain/fasceGiocatore.js";
import { isRuoloClassic, type RuoloClassic } from "../domain/ruoli.js";
import { valoreGiocatore } from "../domain/valoreGiocatore.js";
import {
  calcolaConsiglio,
  ordinaGiocatoriConsigliati,
  slotResiduiPerRuolo,
  type GiocatoreLibero,
  type PickInfo,
  type SlotConfig,
} from "../domain/astaAlgoritmo.js";

async function caricaAstaConDettagli(astaId: string) {
  return prisma.asta.findUnique({
    where: { id: astaId },
    include: {
      partecipanti: true,
      picks: { include: { player: { include: { team: true } }, partecipante: true } },
    },
  });
}

async function stagioneAstaEffettiva(stagioneAsta: string) {
  const esiste = await prisma.player.findFirst({
    where: { stagione: stagioneAsta },
    select: { id: true },
  });
  if (esiste) return stagioneAsta;

  const piuRecente = await prisma.player.findFirst({
    orderBy: { updatedAt: "desc" },
    select: { stagione: true },
  });
  return piuRecente?.stagione ?? stagioneAsta;
}

function toSlotConfig(asta: { slotP: number; slotD: number; slotC: number; slotA: number }): SlotConfig {
  return { P: asta.slotP, D: asta.slotD, C: asta.slotC, A: asta.slotA };
}

function toPickInfo(
  picks: { prezzo: number; partecipante: { sonIo: boolean }; player: { ruoloClassic: string } }[],
): PickInfo[] {
  return picks.map((p) => ({
    ruolo: p.player.ruoloClassic as RuoloClassic,
    prezzo: p.prezzo,
    sonIo: p.partecipante.sonIo,
  }));
}

export async function registerAsteRoutes(app: FastifyInstance) {
  app.post("/aste", async (req, reply) => {
    const body = req.body as {
      stagione: string;
      budgetTotale: number;
      slotP?: number;
      slotD?: number;
      slotC?: number;
      slotA?: number;
      avversari?: string[];
    };

    if (!body.stagione || !body.budgetTotale) {
      return reply.code(400).send({ error: "stagione e budgetTotale sono obbligatori" });
    }

    const asta = await prisma.asta.create({
      data: {
        stagione: body.stagione,
        budgetTotale: body.budgetTotale,
        slotP: body.slotP ?? 3,
        slotD: body.slotD ?? 8,
        slotC: body.slotC ?? 8,
        slotA: body.slotA ?? 6,
        partecipanti: {
          create: [
            { nome: "Io", sonIo: true },
            ...(body.avversari ?? []).map((nome) => ({ nome, sonIo: false })),
          ],
        },
      },
      include: { partecipanti: true },
    });

    return asta;
  });

  app.get("/aste/:id", async (req, reply) => {
    const { id } = req.params as { id: string };
    const asta = await caricaAstaConDettagli(id);
    if (!asta) return reply.code(404).send({ error: "asta non trovata" });

    const slotResidui = slotResiduiPerRuolo(toSlotConfig(asta), toPickInfo(asta.picks));
    const budgetSpesoIo = asta.picks
      .filter((p) => p.partecipante.sonIo)
      .reduce((sum, p) => sum + p.prezzo, 0);

    return {
      ...asta,
      budgetResiduo: asta.budgetTotale - budgetSpesoIo,
      slotResidui,
    };
  });

  app.post("/aste/:id/picks", async (req, reply) => {
    const { id } = req.params as { id: string };
    const body = req.body as { playerId: string; partecipanteId: string; prezzo: number };

    if (!body.playerId || !body.partecipanteId || body.prezzo == null) {
      return reply.code(400).send({ error: "playerId, partecipanteId e prezzo sono obbligatori" });
    }

    try {
      const pick = await prisma.astaPick.create({
        data: {
          astaId: id,
          playerId: body.playerId,
          partecipanteId: body.partecipanteId,
          prezzo: body.prezzo,
        },
        include: { player: { include: { team: true } }, partecipante: true },
      });
      return pick;
    } catch {
      return reply.code(409).send({ error: "giocatore già assegnato in questa asta" });
    }
  });

  app.delete("/aste/:id/picks/:pickId", async (req, reply) => {
    const { pickId } = req.params as { id: string; pickId: string };
    await prisma.astaPick.delete({ where: { id: pickId } });
    return reply.code(204).send();
  });

  app.get("/aste/:id/consiglio", async (req, reply) => {
    const { id } = req.params as { id: string };
    const query = req.query as { playerId?: string; prezzoAttuale?: string };

    if (!query.playerId || query.prezzoAttuale == null) {
      return reply.code(400).send({ error: "playerId e prezzoAttuale sono obbligatori" });
    }

    const asta = await caricaAstaConDettagli(id);
    if (!asta) return reply.code(404).send({ error: "asta non trovata" });

    const giocatore = await prisma.player.findUnique({ where: { id: query.playerId } });
    if (!giocatore) return reply.code(404).send({ error: "giocatore non trovato" });
    if (!isRuoloClassic(giocatore.ruoloClassic)) {
      return reply.code(400).send({ error: `ruolo non valido: ${giocatore.ruoloClassic}` });
    }

    const stagione = await stagioneAstaEffettiva(asta.stagione);
    const idGiaPresi = asta.picks.map((p) => p.playerId);
    const liberiStessoRuolo = await prisma.player.findMany({
      where: {
        stagione,
        ruoloClassic: giocatore.ruoloClassic,
        id: { notIn: idGiaPresi.length > 0 ? idGiaPresi : undefined },
      },
    });
    const fvmMedioLiberiStessoRuolo =
      liberiStessoRuolo.length > 0
        ? liberiStessoRuolo.reduce((sum, p) => sum + valoreGiocatore(p), 0) / liberiStessoRuolo.length
        : 0;

    const consiglio = calcolaConsiglio({
      budgetTotale: asta.budgetTotale,
      slot: toSlotConfig(asta),
      picks: toPickInfo(asta.picks),
      giocatoreRuolo: giocatore.ruoloClassic,
      giocatoreFvm: valoreGiocatore(giocatore),
      fvmMedioLiberiStessoRuolo,
      fasciaGiocatore: fasciaDiGiocatore(valoreGiocatore(giocatore), asta.budgetTotale),
      prezzoAttuale: Number(query.prezzoAttuale),
    });

    return consiglio;
  });

  app.get("/aste/:id/consigliati", async (req, reply) => {
    const { id } = req.params as { id: string };
    const query = req.query as { limit?: string };
    const limit = query.limit ? Number(query.limit) : 20;

    const asta = await caricaAstaConDettagli(id);
    if (!asta) return reply.code(404).send({ error: "asta non trovata" });

    const stagione = await stagioneAstaEffettiva(asta.stagione);
    const idGiaPresi = asta.picks.map((p) => p.playerId);
    const liberi = await prisma.player.findMany({
      where: {
        stagione,
        id: { notIn: idGiaPresi.length > 0 ? idGiaPresi : undefined },
      },
      include: { team: true },
    });

    const slotResidui = slotResiduiPerRuolo(toSlotConfig(asta), toPickInfo(asta.picks));
    const liberiInfo: GiocatoreLibero[] = liberi
      .filter((p): p is typeof p & { ruoloClassic: RuoloClassic } => isRuoloClassic(p.ruoloClassic))
      .map((p) => ({
        id: p.id,
        nome: p.nome,
        ruolo: p.ruoloClassic,
        fvm: valoreGiocatore(p),
        fascia: fasciaDiGiocatore(valoreGiocatore(p), asta.budgetTotale),
      }));

    const ordinati = ordinaGiocatoriConsigliati(liberiInfo, slotResidui).slice(0, limit);
    return ordinati;
  });
}

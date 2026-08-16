import type { FastifyInstance } from "fastify";
import { prisma } from "../db/client.js";
import { isRuoloClassic, type RuoloClassic } from "../domain/ruoli.js";
import {
  calcolaFormazioneTitolare,
  type GiocatoreRosa,
} from "../domain/formazioneTitolareAlgoritmo.js";

const VALORE_NEUTRO = 6;

async function caricaRosaConForma(): Promise<GiocatoreRosa[]> {
  const rosa = await prisma.rosaGiocatore.findMany({
    include: {
      player: {
        include: { statistiche: { orderBy: { giornata: "desc" }, take: 5 } },
      },
    },
  });

  return rosa
    .filter((r): r is typeof r & { player: typeof r.player & { ruoloClassic: RuoloClassic } } =>
      isRuoloClassic(r.player.ruoloClassic),
    )
    .map((r) => {
      const voti = r.player.statistiche
        .map((s) => s.fantavoto)
        .filter((v): v is number => v != null);
      const formaReale = voti.length > 0;
      const valoreForma = formaReale
        ? voti.reduce((s, v) => s + v, 0) / voti.length
        : VALORE_NEUTRO;

      return {
        id: r.player.id,
        nome: r.player.nome,
        ruolo: r.player.ruoloClassic,
        valoreForma,
        formaReale,
      };
    });
}

export async function registerRosaRoutes(app: FastifyInstance) {
  app.get("/rosa", async () => {
    return prisma.rosaGiocatore.findMany({
      include: { player: { include: { team: true } } },
      orderBy: { createdAt: "asc" },
    });
  });

  app.post("/rosa", async (req, reply) => {
    const body = req.body as { playerId?: string };
    if (!body?.playerId) {
      return reply.code(400).send({ error: "campo 'playerId' obbligatorio" });
    }

    const player = await prisma.player.findUnique({ where: { id: body.playerId } });
    if (!player) {
      return reply.code(404).send({ error: "giocatore non trovato" });
    }

    try {
      const entry = await prisma.rosaGiocatore.create({
        data: { playerId: body.playerId },
        include: { player: { include: { team: true } } },
      });
      return entry;
    } catch {
      return reply.code(409).send({ error: "giocatore già presente in rosa" });
    }
  });

  app.delete("/rosa/:playerId", async (req, reply) => {
    const { playerId } = req.params as { playerId: string };
    await prisma.rosaGiocatore.deleteMany({ where: { playerId } });
    return reply.code(204).send();
  });

  app.get("/rosa/formazione-titolare", async (req, reply) => {
    const rosa = await caricaRosaConForma();

    try {
      const risultato = calcolaFormazioneTitolare(rosa);
      return risultato;
    } catch (err) {
      return reply.code(400).send({
        error: err instanceof Error ? err.message : "impossibile calcolare la formazione titolare",
      });
    }
  });
}

import type { FastifyInstance } from "fastify";
import { prisma } from "../db/client.js";
import { isRuoloClassic } from "../domain/ruoli.js";

// Quando coesistono piu' stagioni nel DB (es. dati storici, o piu' sync
// eseguite con etichette diverse), il Listone deve mostrarne una sola per
// evitare di vedere ogni giocatore ripetuto. "Corrente" = la stagione del
// giocatore aggiornato piu' di recente, cosi' l'ultima sincronizzazione
// vince sempre senza bisogno di configurarla a mano.
async function stagioneCorrente(): Promise<string | null> {
  const piuRecente = await prisma.player.findFirst({
    orderBy: { updatedAt: "desc" },
    select: { stagione: true },
  });
  return piuRecente?.stagione ?? null;
}

export async function registerPlayersRoutes(app: FastifyInstance) {
  app.get("/players/current-season", async () => {
    const stagione = await stagioneCorrente();
    return { stagione };
  });

  app.get("/players", async (req, reply) => {
    const query = req.query as {
      ruolo?: string;
      team?: string;
      search?: string;
      stagione?: string;
      tutteStagioni?: string;
    };

    if (query.ruolo && !isRuoloClassic(query.ruolo)) {
      return reply.code(400).send({ error: `ruolo non valido: ${query.ruolo}` });
    }

    const stagione =
      query.tutteStagioni === "true" ? undefined : query.stagione ?? (await stagioneCorrente()) ?? undefined;

    const players = await prisma.player.findMany({
      where: {
        ruoloClassic: query.ruolo,
        teamId: query.team,
        stagione,
        nome: query.search ? { contains: query.search, mode: "insensitive" } : undefined,
      },
      include: { team: true },
      orderBy: { quotazioneAttuale: "desc" },
    });

    return players;
  });

  app.get("/players/:id", async (req, reply) => {
    const { id } = req.params as { id: string };

    const player = await prisma.player.findUnique({
      where: { id },
      include: {
        team: true,
        quotazioni: { orderBy: { data: "asc" } },
        statistiche: { orderBy: { giornata: "asc" } },
      },
    });

    if (!player) {
      return reply.code(404).send({ error: "giocatore non trovato" });
    }

    return player;
  });
}

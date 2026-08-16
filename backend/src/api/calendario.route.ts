import type { FastifyInstance } from "fastify";
import { prisma } from "../db/client.js";

export async function registerCalendarioRoutes(app: FastifyInstance) {
  app.get("/calendario", async (req) => {
    const { stagione } = req.query as { stagione?: string };
    return prisma.calendarioGiornata.findMany({
      where: { stagione },
      orderBy: { giornata: "asc" },
    });
  });

  app.put("/calendario", async (req, reply) => {
    const body = req.body as { stagione?: string; giornata?: number; avversario?: string };

    if (!body.stagione || !body.giornata || !body.avversario?.trim()) {
      return reply.code(400).send({ error: "stagione, giornata e avversario sono obbligatori" });
    }

    return prisma.calendarioGiornata.upsert({
      where: { stagione_giornata: { stagione: body.stagione, giornata: body.giornata } },
      update: { avversario: body.avversario.trim() },
      create: {
        stagione: body.stagione,
        giornata: body.giornata,
        avversario: body.avversario.trim(),
      },
    });
  });

  app.delete("/calendario/:id", async (req) => {
    const { id } = req.params as { id: string };
    await prisma.calendarioGiornata.delete({ where: { id } });
    return { ok: true };
  });
}

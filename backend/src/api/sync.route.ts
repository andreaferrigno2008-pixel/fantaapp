import type { FastifyInstance } from "fastify";
import { prisma } from "../db/client.js";
import { quotazioniAdapter } from "../scraper/quotazioniAdapter.js";
import { quotazioniOnlineAdapter } from "../scraper/quotazioniOnlineAdapter.js";
import { votiAdapter } from "../scraper/votiAdapter.js";
import { runAdapter } from "../scraper/runner.js";

export async function registerSyncRoutes(app: FastifyInstance) {
  app.post("/sync/quotazioni", async (req, reply) => {
    const file = await req.file();
    if (!file) {
      return reply.code(400).send({ error: "file CSV mancante (campo multipart 'file')" });
    }

    const stagione = (file.fields.stagione as { value: string } | undefined)?.value;
    if (!stagione) {
      return reply.code(400).send({ error: "campo 'stagione' mancante (es. 2025-26)" });
    }

    const csvContent = (await file.toBuffer()).toString("utf-8");

    try {
      const result = await runAdapter(quotazioniAdapter, { csvContent, stagione });
      return result;
    } catch (err) {
      return reply.code(400).send({
        error: err instanceof Error ? err.message : "import fallito",
      });
    }
  });

  app.post("/sync/quotazioni-online", async (req, reply) => {
    const body = req.body as { stagione?: string };
    if (!body?.stagione) {
      return reply.code(400).send({ error: "campo 'stagione' mancante (es. 2026-27)" });
    }

    try {
      const result = await runAdapter(quotazioniOnlineAdapter, { stagione: body.stagione });
      return result;
    } catch (err) {
      return reply.code(400).send({
        error: err instanceof Error ? err.message : "import fallito",
      });
    }
  });

  app.post("/sync/voti", async (req, reply) => {
    const body = req.body as { stagione?: string; giornata?: number };
    if (!body?.stagione || body.giornata == null) {
      return reply.code(400).send({ error: "campi 'stagione' e 'giornata' obbligatori" });
    }

    try {
      const result = await runAdapter(votiAdapter, {
        stagione: body.stagione,
        giornata: Number(body.giornata),
      });
      return result;
    } catch (err) {
      return reply.code(400).send({
        error: err instanceof Error ? err.message : "import fallito",
      });
    }
  });

  app.get("/sync/status", async () => {
    return prisma.dataSourceRun.findMany({
      orderBy: { startedAt: "desc" },
      take: 20,
    });
  });
}

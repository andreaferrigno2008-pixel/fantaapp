import type { FastifyInstance } from "fastify";
import { prisma } from "../db/client.js";

export async function registerTeamsRoutes(app: FastifyInstance) {
  app.get("/teams", async () => {
    return prisma.team.findMany({ orderBy: { nome: "asc" } });
  });
}

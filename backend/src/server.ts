import Fastify from "fastify";
import multipart from "@fastify/multipart";
import { registerPlayersRoutes } from "./api/players.route.js";
import { registerTeamsRoutes } from "./api/teams.route.js";
import { registerSyncRoutes } from "./api/sync.route.js";
import { registerAsteRoutes } from "./api/aste.route.js";
import { registerFormazioniRoutes } from "./api/formazioni.route.js";
import { registerScambiRoutes } from "./api/scambi.route.js";
import { registerRosaRoutes } from "./api/rosa.route.js";

const app = Fastify({ logger: true });

await app.register(multipart);

await registerPlayersRoutes(app);
await registerTeamsRoutes(app);
await registerSyncRoutes(app);
await registerAsteRoutes(app);
await registerFormazioniRoutes(app);
await registerScambiRoutes(app);
await registerRosaRoutes(app);

app.get("/health", async () => ({ status: "ok" }));

const port = Number(process.env.PORT ?? 3000);
app.listen({ port, host: "0.0.0.0" }).catch((err) => {
  app.log.error(err);
  process.exit(1);
});

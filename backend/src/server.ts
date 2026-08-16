import Fastify from "fastify";
import multipart from "@fastify/multipart";
import { registerPlayersRoutes } from "./api/players.route.js";
import { registerTeamsRoutes } from "./api/teams.route.js";
import { registerSyncRoutes } from "./api/sync.route.js";
import { registerAsteRoutes } from "./api/aste.route.js";
import { registerFormazioniRoutes } from "./api/formazioni.route.js";
import { registerScambiRoutes } from "./api/scambi.route.js";
import { registerRosaRoutes } from "./api/rosa.route.js";
import { registerCalendarioRoutes } from "./api/calendario.route.js";

const app = Fastify({ logger: true });

// Il backend è pubblico su internet: senza questo controllo chiunque trovi
// l'URL potrebbe leggere/modificare i dati o innescare azioni (inclusa la
// sincronizzazione autenticata con leghe.fantacalcio.it). App singolo
// utente, quindi una chiave condivisa statica è sufficiente — niente
// account/JWT. /health resta pubblico per i controlli di uptime di Render.
const apiKey = process.env.API_KEY;
if (!apiKey) {
  throw new Error("API_KEY non impostata: obbligatoria per proteggere il backend pubblico");
}
app.addHook("onRequest", async (req, reply) => {
  if (req.url === "/health") return;
  if (req.headers["x-api-key"] !== apiKey) {
    return reply.code(401).send({ error: "non autorizzato" });
  }
});

await app.register(multipart);

await registerPlayersRoutes(app);
await registerTeamsRoutes(app);
await registerSyncRoutes(app);
await registerAsteRoutes(app);
await registerFormazioniRoutes(app);
await registerScambiRoutes(app);
await registerRosaRoutes(app);
await registerCalendarioRoutes(app);

app.get("/health", async () => ({ status: "ok" }));

const port = Number(process.env.PORT ?? 3000);
app.listen({ port, host: "0.0.0.0" }).catch((err) => {
  app.log.error(err);
  process.exit(1);
});

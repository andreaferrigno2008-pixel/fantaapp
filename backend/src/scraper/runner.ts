import { prisma } from "../db/client.js";
import type { DataSourceAdapter } from "./types.js";

// Esegue un adapter e logga sempre l'esito in DataSourceRun, cosi' un
// aumento di errori per una fonte specifica e' immediatamente visibile
// senza dover leggere i log applicativi (vedi docs/data-sources.md).
export async function runAdapter<TInput>(
  adapter: DataSourceAdapter<TInput>,
  input: TInput,
) {
  const run = await prisma.dataSourceRun.create({
    data: { source: adapter.source, status: "running" },
  });

  try {
    const result = await adapter.run(input);
    await prisma.dataSourceRun.update({
      where: { id: run.id },
      data: {
        status: "success",
        finishedAt: new Date(),
        recordsCount: result.recordsCount,
      },
    });
    return result;
  } catch (err) {
    await prisma.dataSourceRun.update({
      where: { id: run.id },
      data: {
        status: "error",
        finishedAt: new Date(),
        errorMessage: err instanceof Error ? err.message : String(err),
      },
    });
    throw err;
  }
}

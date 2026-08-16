// Ogni fonte dati (import file o scraping HTML) implementa questa stessa
// interfaccia. Isola il resto del sistema dai dettagli di parsing di una
// fonte specifica: quando una pagina/file cambia struttura, si aggiorna
// solo il suo adapter — vedi docs/data-sources.md.

export interface DataSourceRunResult {
  recordsCount: number;
}

export interface DataSourceAdapter<TInput> {
  source: string;
  run(input: TInput): Promise<DataSourceRunResult>;
}

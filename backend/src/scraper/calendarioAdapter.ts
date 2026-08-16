import * as cheerio from "cheerio";
import type { DataSourceAdapter } from "./types.js";

// Scaffold: stesso motivo di votiAdapter.ts — la fonte reale va scelta e
// verificata quando serve (Fase 2), non indovinata ora.

export interface CalendarioInput {
  stagione: string;
}

export const calendarioAdapter: DataSourceAdapter<CalendarioInput> = {
  source: "calendario-scraper",

  async run({ stagione }) {
    void cheerio;
    throw new Error(
      `calendarioAdapter non ancora implementato (stagione ${stagione}): scegliere e validare una fonte reale in Fase 2`,
    );
  },
};

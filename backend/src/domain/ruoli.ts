// Ruoli non sono un enum a livello DB (SQLite non li supporta nativamente
// in Prisma): la validazione vive qui, unica fonte di verità applicativa.

export const RUOLI_CLASSIC = ["P", "D", "C", "A"] as const;
export type RuoloClassic = (typeof RUOLI_CLASSIC)[number];

export const RUOLI_MANTRA = [
  "POR",
  "DC",
  "DD",
  "DS",
  "B",
  "E",
  "M",
  "C",
  "W",
  "T",
  "A",
  "PC",
] as const;
export type RuoloMantra = (typeof RUOLI_MANTRA)[number];

export function isRuoloClassic(value: string): value is RuoloClassic {
  return (RUOLI_CLASSIC as readonly string[]).includes(value);
}

export function parseRuoliMantra(csv: string | null): RuoloMantra[] {
  if (!csv) return [];
  return csv
    .split(",")
    .map((r) => r.trim())
    .filter((r): r is RuoloMantra => (RUOLI_MANTRA as readonly string[]).includes(r));
}

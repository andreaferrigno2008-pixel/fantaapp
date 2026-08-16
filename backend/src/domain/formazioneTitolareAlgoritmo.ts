import type { RuoloClassic } from "./ruoli.js";

export interface GiocatoreRosa {
  id: string;
  nome: string;
  ruolo: RuoloClassic;
  // Media fantavoto delle ultime giornate disponibili, oppure 6 (la
  // sufficienza) se il giocatore non ha ancora statistiche — vedi
  // formaReale per distinguere i due casi.
  valoreForma: number;
  formaReale: boolean;
}

export interface ModuloValutazione {
  modulo: string;
  fattibile: boolean;
  valoreTotale: number | null;
}

export interface FormazioneTitolareOutput {
  modulo: string;
  titolari: Record<RuoloClassic, GiocatoreRosa[]>;
  panchina: GiocatoreRosa[];
  moduliValutati: ModuloValutazione[];
  warning: string[];
}

// Moduli Classic standard: 1 portiere + 10 giocatori, D-C-A che sommano
// sempre a 10.
const MODULI: { nome: string; D: number; C: number; A: number }[] = [
  { nome: "3-4-3", D: 3, C: 4, A: 3 },
  { nome: "3-5-2", D: 3, C: 5, A: 2 },
  { nome: "4-3-3", D: 4, C: 3, A: 3 },
  { nome: "4-4-2", D: 4, C: 4, A: 2 },
  { nome: "4-5-1", D: 4, C: 5, A: 1 },
  { nome: "5-3-2", D: 5, C: 3, A: 2 },
  { nome: "5-4-1", D: 5, C: 4, A: 1 },
];

// Senza un budget da rispettare, per un ruolo/modulo fissato la scelta
// ottima e' semplicemente prendere i migliori per valore di forma — a
// differenza dell'Assistente Asta e di Formazione ottimale non serve una
// DP: qui non c'e' alcun vincolo che leghi le scelte tra loro.
export function calcolaFormazioneTitolare(rosa: GiocatoreRosa[]): FormazioneTitolareOutput {
  const perRuolo: Record<RuoloClassic, GiocatoreRosa[]> = { P: [], D: [], C: [], A: [] };
  for (const g of rosa) perRuolo[g.ruolo].push(g);
  for (const ruolo of Object.keys(perRuolo) as RuoloClassic[]) {
    perRuolo[ruolo].sort((a, b) => b.valoreForma - a.valoreForma);
  }

  if (perRuolo.P.length === 0) {
    throw new Error("in rosa non c'è nessun portiere: impossibile proporre una formazione");
  }
  const portiere = perRuolo.P[0];

  const moduliValutati: ModuloValutazione[] = [];
  let migliore: { modulo: string; D: number; C: number; A: number; valoreTotale: number } | null =
    null;

  for (const m of MODULI) {
    const fattibile =
      perRuolo.D.length >= m.D && perRuolo.C.length >= m.C && perRuolo.A.length >= m.A;

    if (!fattibile) {
      moduliValutati.push({ modulo: m.nome, fattibile: false, valoreTotale: null });
      continue;
    }

    const valoreTotale =
      portiere.valoreForma +
      somma(perRuolo.D.slice(0, m.D)) +
      somma(perRuolo.C.slice(0, m.C)) +
      somma(perRuolo.A.slice(0, m.A));

    moduliValutati.push({ modulo: m.nome, fattibile: true, valoreTotale });

    if (!migliore || valoreTotale > migliore.valoreTotale) {
      migliore = { modulo: m.nome, D: m.D, C: m.C, A: m.A, valoreTotale };
    }
  }

  if (!migliore) {
    throw new Error(
      "nessun modulo standard è fattibile con la rosa attuale: servono più giocatori per ruolo",
    );
  }

  const titolariD = perRuolo.D.slice(0, migliore.D);
  const titolariC = perRuolo.C.slice(0, migliore.C);
  const titolariA = perRuolo.A.slice(0, migliore.A);
  const titolariIds = new Set(
    [portiere, ...titolariD, ...titolariC, ...titolariA].map((g) => g.id),
  );

  const panchina = rosa.filter((g) => !titolariIds.has(g.id));
  const titolariSenzaForma = rosa.filter((g) => !g.formaReale && titolariIds.has(g.id));

  const warning: string[] = [];
  if (titolariSenzaForma.length > 0) {
    warning.push(
      `${titolariSenzaForma.length} titolare/i senza statistiche di rendimento reali ` +
        `(valore stimato neutro 6.0): ${titolariSenzaForma.map((g) => g.nome).join(", ")}`,
    );
  }

  return {
    modulo: migliore.modulo,
    titolari: { P: [portiere], D: titolariD, C: titolariC, A: titolariA },
    panchina,
    moduliValutati: moduliValutati.sort(
      (a, b) => (b.valoreTotale ?? -Infinity) - (a.valoreTotale ?? -Infinity),
    ),
    warning,
  };
}

function somma(giocatori: GiocatoreRosa[]): number {
  return giocatori.reduce((s, g) => s + g.valoreForma, 0);
}

import { RUOLI_CLASSIC, type RuoloClassic } from "./ruoli.js";
import { percentualiRicalibrate, type SlotConfig } from "./astaAlgoritmo.js";

export interface CandidatoFormazione {
  id: string;
  ruolo: RuoloClassic;
  prezzo: number;
  fvm: number;
}

export interface FormazioneInput {
  budgetTotale: number;
  slot: SlotConfig;
  // Tutti i giocatori disponibili per la stagione (non solo i liberi: qui
  // non c'e' un'asta in corso, e' una pianificazione stand-alone).
  candidati: CandidatoFormazione[];
  obiettiviIds: string[];
}

export interface FormazioneOutput {
  formazione: Record<RuoloClassic, string[]>;
  budgetSpeso: number;
  budgetResiduo: number;
  fvmTotale: number;
  warning: string[];
}

export function generaFormazione(input: FormazioneInput): FormazioneOutput {
  const { budgetTotale, slot, candidati, obiettiviIds } = input;
  const warning: string[] = [];

  const byId = new Map(candidati.map((c) => [c.id, c]));
  const obiettivi = obiettiviIds.map((id) => {
    const c = byId.get(id);
    if (!c) throw new Error(`giocatore obiettivo non trovato: ${id}`);
    return c;
  });

  const obiettiviPerRuolo: Record<RuoloClassic, number> = { P: 0, D: 0, C: 0, A: 0 };
  for (const o of obiettivi) obiettiviPerRuolo[o.ruolo]++;
  for (const ruolo of RUOLI_CLASSIC) {
    if (obiettiviPerRuolo[ruolo] > slot[ruolo]) {
      throw new Error(
        `troppi obiettivi in ruolo ${ruolo}: ${obiettiviPerRuolo[ruolo]} obiettivi ma solo ${slot[ruolo]} slot`,
      );
    }
  }

  const selezionati: Record<RuoloClassic, CandidatoFormazione[]> = { P: [], D: [], C: [], A: [] };
  for (const o of obiettivi) selezionati[o.ruolo].push(o);

  const obiettiviIdSet = new Set(obiettiviIds);
  const budgetDopoObiettivi = budgetTotale - obiettivi.reduce((sum, o) => sum + o.prezzo, 0);
  if (budgetDopoObiettivi < 0) {
    warning.push("Gli obiettivi selezionati superano da soli il budget totale.");
  }

  const slotResidui: Record<RuoloClassic, number> = {
    P: slot.P - selezionati.P.length,
    D: slot.D - selezionati.D.length,
    C: slot.C - selezionati.C.length,
    A: slot.A - selezionati.A.length,
  };

  let budgetResiduo = Math.max(budgetDopoObiettivi, 0);
  const percentuali = percentualiRicalibrate(slotResidui);

  for (const ruolo of RUOLI_CLASSIC) {
    const k = slotResidui[ruolo];
    if (k <= 0) continue;

    const candidatiRuolo = candidati.filter(
      (c) => c.ruolo === ruolo && !obiettiviIdSet.has(c.id),
    );

    if (candidatiRuolo.length < k) {
      throw new Error(
        `non ci sono abbastanza giocatori disponibili in ruolo ${ruolo} ` +
          `(servono ${k}, disponibili ${candidatiRuolo.length})`,
      );
    }

    const subBudget = Math.round(budgetResiduo * percentuali[ruolo]);
    const { selezionati: scelti, costo, sforato } = scegliMigliori(candidatiRuolo, k, subBudget);

    if (sforato) {
      warning.push(
        `Budget stimato per ${ruolo} insufficiente: presa la selezione più economica disponibile.`,
      );
    }

    selezionati[ruolo].push(...scelti);
    budgetResiduo -= costo;
  }

  const tuttiSelezionati = RUOLI_CLASSIC.flatMap((r) => selezionati[r]);
  const budgetSpeso = budgetTotale - budgetResiduo;
  const fvmTotale = tuttiSelezionati.reduce((sum, c) => sum + c.fvm, 0);

  if (budgetResiduo < 0) {
    warning.push("Budget totale superato: la rosa proposta costa più del budget indicato.");
  }

  const formazione: Record<RuoloClassic, string[]> = { P: [], D: [], C: [], A: [] };
  for (const ruolo of RUOLI_CLASSIC) formazione[ruolo] = selezionati[ruolo].map((c) => c.id);

  return { formazione, budgetSpeso, budgetResiduo, fvmTotale, warning };
}

interface RisultatoScelta {
  selezionati: CandidatoFormazione[];
  costo: number;
  sforato: boolean;
}

function scegliMigliori(
  candidati: CandidatoFormazione[],
  k: number,
  subBudget: number,
): RisultatoScelta {
  const perValore = [...candidati].sort((a, b) => b.fvm - a.fvm);
  const topK = perValore.slice(0, k);
  const costoTopK = topK.reduce((sum, c) => sum + c.prezzo, 0);

  // Budget non vincolante: la selezione a massimo valore rientra gia' nel
  // sotto-budget, quindi e' gia' ottima senza risolvere il knapsack (ed
  // evita di dover dimensionare la DP su budget enormi).
  if (costoTopK <= subBudget) {
    return { selezionati: topK, costo: costoTopK, sforato: false };
  }

  const risultato = knapsackEsattamenteK(candidati, k, Math.max(subBudget, 0));
  if (risultato) {
    return { selezionati: risultato.selezionati, costo: risultato.costo, sforato: false };
  }

  // Nessuna combinazione di k giocatori rientra nel sotto-budget: si
  // garantisce comunque una rosa completa prendendo i k piu' economici.
  const perPrezzo = [...candidati].sort((a, b) => a.prezzo - b.prezzo);
  const scelti = perPrezzo.slice(0, k);
  return {
    selezionati: scelti,
    costo: scelti.reduce((sum, c) => sum + c.prezzo, 0),
    sforato: true,
  };
}

// Limite di sicurezza sulla larghezza della tabella DP. I sotto-budget per
// ruolo realistici stanno ben sotto questa soglia; quando la superano, il
// ramo "budget non vincolante" sopra evita comunque di eseguire la DP.
const LARGHEZZA_MASSIMA_DP = 5000;

// Knapsack 0/1 "scegli esattamente k elementi massimizzando il valore
// (FVM) senza superare il budget": dp[i][j][b] = valore massimo scegliendo
// esattamente j elementi tra i primi i candidati con costo totale <= b.
function knapsackEsattamenteK(
  candidati: CandidatoFormazione[],
  k: number,
  subBudget: number,
): { selezionati: CandidatoFormazione[]; costo: number } | null {
  const w = Math.min(Math.floor(subBudget), LARGHEZZA_MASSIMA_DP);
  const n = candidati.length;

  const dp: Int32Array[][] = Array.from({ length: n + 1 }, () =>
    Array.from({ length: k + 1 }, () => new Int32Array(w + 1).fill(-1)),
  );
  for (let b = 0; b <= w; b++) dp[0][0][b] = 0;

  for (let i = 1; i <= n; i++) {
    const item = candidati[i - 1];
    // Prezzi oltre w non sono mai selezionabili: si "clampano" a w+1 cosi'
    // la condizione costo <= b non e' mai vera, senza rami separati.
    const costo = Math.min(item.prezzo, w + 1);
    for (let j = 0; j <= k; j++) {
      for (let b = 0; b <= w; b++) {
        let migliore = dp[i - 1][j][b];
        if (j > 0 && costo <= b) {
          const conItem = dp[i - 1][j - 1][b - costo];
          if (conItem >= 0 && conItem + item.fvm > migliore) {
            migliore = conItem + item.fvm;
          }
        }
        dp[i][j][b] = migliore;
      }
    }
  }

  if (dp[n][k][w] < 0) return null;

  const selezionati: CandidatoFormazione[] = [];
  let j = k;
  let b = w;
  for (let i = n; i >= 1 && j > 0; i--) {
    if (dp[i][j][b] !== dp[i - 1][j][b]) {
      const item = candidati[i - 1];
      selezionati.push(item);
      b -= Math.min(item.prezzo, w + 1);
      j--;
    }
  }

  return { selezionati, costo: selezionati.reduce((sum, c) => sum + c.prezzo, 0) };
}

import { ETICHETTA_FASCIA, type Fascia } from "./fasceGiocatore.js";
import { RUOLI_CLASSIC, type RuoloClassic } from "./ruoli.js";

// Percentuali standard di ripartizione budget tra ruoli, valori comuni
// nelle guide fantacalcio. Ricalibrate a runtime sui soli ruoli con slot
// ancora scoperti (vedi percentualiRicalibrate), cosi' sommano sempre 100%.
const PERCENTUALE_RUOLO: Record<RuoloClassic, number> = {
  A: 0.45,
  C: 0.3,
  D: 0.17,
  P: 0.08,
};

export interface SlotConfig {
  P: number;
  D: number;
  C: number;
  A: number;
}

export interface PickInfo {
  ruolo: RuoloClassic;
  prezzo: number;
  sonIo: boolean;
}

export function budgetResiduo(budgetTotale: number, picks: PickInfo[]): number {
  const speso = picks.filter((p) => p.sonIo).reduce((sum, p) => sum + p.prezzo, 0);
  return budgetTotale - speso;
}

export function slotResiduiPerRuolo(
  slot: SlotConfig,
  picks: PickInfo[],
): Record<RuoloClassic, number> {
  const presiDaMe: Record<RuoloClassic, number> = { P: 0, D: 0, C: 0, A: 0 };
  for (const p of picks) {
    if (p.sonIo) presiDaMe[p.ruolo]++;
  }
  return {
    P: slot.P - presiDaMe.P,
    D: slot.D - presiDaMe.D,
    C: slot.C - presiDaMe.C,
    A: slot.A - presiDaMe.A,
  };
}

// Solo i ruoli con almeno uno slot ancora scoperto contribuiscono al
// calcolo, ricalibrati per sommare sempre 1: cosi' il budget non viene
// "sprecato" su un reparto gia' completo.
export function percentualiRicalibrate(
  slotResidui: Record<RuoloClassic, number>,
): Record<RuoloClassic, number> {
  const ruoliAperti = RUOLI_CLASSIC.filter((r) => slotResidui[r] > 0);
  const totalePeso = ruoliAperti.reduce((sum, r) => sum + PERCENTUALE_RUOLO[r], 0);
  const result: Record<RuoloClassic, number> = { P: 0, D: 0, C: 0, A: 0 };
  if (totalePeso <= 0) return result;
  for (const r of ruoliAperti) result[r] = PERCENTUALE_RUOLO[r] / totalePeso;
  return result;
}

export interface ConsiglioInput {
  budgetTotale: number;
  slot: SlotConfig;
  picks: PickInfo[];
  giocatoreRuolo: RuoloClassic;
  giocatoreFvm: number;
  // FVM medio dei giocatori dello stesso ruolo ancora liberi in questa
  // asta: calcolato dal chiamante (query sui Player non presenti in
  // nessun AstaPick), non e' responsabilita' di questo modulo puro.
  fvmMedioLiberiStessoRuolo: number;
  // Fascia del giocatore (top/semitop/fascia_media/scommessa), calcolata
  // dal chiamante in base a FVM e budget totale dell'asta — vedi
  // fasceGiocatore.ts. Usata per non trattare allo stesso modo giocatori
  // di caratura diversa quando il tetto di sicurezza (vedi sotto) li
  // capperebbe altrimenti allo stesso prezzo massimo.
  fasciaGiocatore: Fascia;
  prezzoAttuale: number;
}

export interface ConsiglioOutput {
  verdetto: "RILANCIA" | "ABBANDONA";
  prezzoMassimoConsigliato: number;
  budgetResiduo: number;
  slotResiduiRuolo: number;
  slotResiduiTotali: number;
  fascia: Fascia;
  motivazione: string;
}

export function calcolaConsiglio(input: ConsiglioInput): ConsiglioOutput {
  const budget = budgetResiduo(input.budgetTotale, input.picks);
  const slotResidui = slotResiduiPerRuolo(input.slot, input.picks);
  const slotResiduiTotali = slotResidui.P + slotResidui.D + slotResidui.C + slotResidui.A;
  const ruolo = input.giocatoreRuolo;
  const slotRuolo = slotResidui[ruolo];

  if (slotRuolo <= 0) {
    return {
      verdetto: "ABBANDONA",
      prezzoMassimoConsigliato: 0,
      budgetResiduo: budget,
      slotResiduiRuolo: slotRuolo,
      slotResiduiTotali,
      fascia: input.fasciaGiocatore,
      motivazione: `Hai già completato il reparto ${ruolo}: nessuno slot residuo per questo ruolo.`,
    };
  }

  const percentuali = percentualiRicalibrate(slotResidui);
  const budgetRuolo = budget * percentuali[ruolo];
  const prezzoMedioSlot = budgetRuolo / slotRuolo;
  const pesoValore =
    input.fvmMedioLiberiStessoRuolo > 0
      ? input.giocatoreFvm / input.fvmMedioLiberiStessoRuolo
      : 1;

  // Regola di sicurezza fantacalcio: ogni slot ancora da riempire deve
  // valere almeno 1 credito, altrimenti non si riesce a completare la rosa.
  // Questo tetto e' identico per qualunque giocatore valutato nello stesso
  // momento dell'asta (dipende solo da budget e slot residui, non dal
  // giocatore) — quando e' lui a limitare il prezzo (capVincolaValore =
  // false), il numero risultante NON riflette il valore del giocatore, solo
  // quanto puoi permetterti in assoluto. Per questo, se in quel caso la
  // fascia e' "scommessa", conviene comunque abbandonare: spendere gli
  // ultimi crediti liberi sul giocatore piu' scarso e' un cattivo uso del
  // vincolo, meglio risparmiarli per un'occasione migliore.
  const tettoSicurezza = budget - Math.max(slotResiduiTotali - 1, 0);
  const prezzoMassimoGrezzo = Math.round(prezzoMedioSlot * pesoValore);
  const capVincolaValore = prezzoMassimoGrezzo <= tettoSicurezza;
  const prezzoMassimoConsigliato = Math.max(1, Math.min(prezzoMassimoGrezzo, tettoSicurezza));

  let verdetto: "RILANCIA" | "ABBANDONA" =
    input.prezzoAttuale < prezzoMassimoConsigliato ? "RILANCIA" : "ABBANDONA";
  if (!capVincolaValore && input.fasciaGiocatore === "scommessa") {
    verdetto = "ABBANDONA";
  }

  const nomeFascia = ETICHETTA_FASCIA[input.fasciaGiocatore];
  const notaTetto = capVincolaValore
    ? ""
    : ` Attenzione: questo tetto è dettato dal budget rimanente rispetto agli slot da riempire, ` +
      `non dal valore del giocatore (fascia ${nomeFascia})` +
      (input.fasciaGiocatore === "scommessa"
        ? " — su una scommessa conviene comunque risparmiare per un'occasione migliore."
        : ".");

  const motivazione =
    `Budget residuo: ${budget} crediti, ${slotRuolo} slot liberi in ${ruolo} ` +
    `(${slotResiduiTotali} totali). Budget stimato per ${ruolo}: ${Math.round(budgetRuolo)} ` +
    `crediti (~${Math.round(prezzoMedioSlot)}/slot). FVM giocatore ${input.giocatoreFvm} ` +
    `(fascia ${nomeFascia}) vs media liberi ${Math.round(input.fvmMedioLiberiStessoRuolo)} ` +
    `(peso ${pesoValore.toFixed(2)}x) → prezzo massimo consigliato ${prezzoMassimoConsigliato}.` +
    notaTetto;

  return {
    verdetto,
    prezzoMassimoConsigliato,
    budgetResiduo: budget,
    slotResiduiRuolo: slotRuolo,
    slotResiduiTotali,
    fascia: input.fasciaGiocatore,
    motivazione,
  };
}

export interface GiocatoreLibero {
  id: string;
  nome: string;
  ruolo: RuoloClassic;
  fvm: number;
  fascia: Fascia;
}

// Ordina i giocatori ancora liberi per convenienza (FVM relativo alla
// media del proprio ruolo), tenendo solo i ruoli con slot ancora scoperti.
// Utile come suggerimento "chi chiamare" nei momenti morti dell'asta.
export function ordinaGiocatoriConsigliati(
  giocatoriLiberi: GiocatoreLibero[],
  slotResidui: Record<RuoloClassic, number>,
): GiocatoreLibero[] {
  const fvmMedioPerRuolo: Record<RuoloClassic, number> = { P: 0, D: 0, C: 0, A: 0 };
  for (const ruolo of RUOLI_CLASSIC) {
    const delRuolo = giocatoriLiberi.filter((g) => g.ruolo === ruolo);
    fvmMedioPerRuolo[ruolo] =
      delRuolo.length > 0
        ? delRuolo.reduce((sum, g) => sum + g.fvm, 0) / delRuolo.length
        : 0;
  }

  return giocatoriLiberi
    .filter((g) => slotResidui[g.ruolo] > 0)
    .map((g) => ({
      giocatore: g,
      peso: fvmMedioPerRuolo[g.ruolo] > 0 ? g.fvm / fvmMedioPerRuolo[g.ruolo] : 0,
    }))
    .sort((a, b) => b.peso - a.peso)
    .map((x) => x.giocatore);
}

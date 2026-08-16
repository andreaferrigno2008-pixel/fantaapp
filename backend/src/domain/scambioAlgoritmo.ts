export interface GiocatoreScambio {
  id: string;
  nome: string;
  valoreBase: number;
  // Media fantavoto delle ultime giornate disponibili; null se il
  // giocatore non ha ancora statistiche importate (vedi docs/data-sources.md
  // sullo stato dello scraping voti).
  mediaFantavotoRecente: number | null;
  quotazioneIniziale: number;
  quotazioneAttuale: number;
}

export interface DettaglioGiocatoreScambio {
  id: string;
  nome: string;
  valoreBase: number;
  fattoreForma: number;
  fattoreTrend: number;
  valoreScambio: number;
}

export interface ScambioInput {
  dati: GiocatoreScambio[];
  ricevuti: GiocatoreScambio[];
}

export interface ScambioOutput {
  verdetto: "FAVOREVOLE" | "SFAVOREVOLE" | "EQUILIBRATO";
  percentuale: number;
  totaleDato: number;
  totaleRicevuto: number;
  dettaglioDati: DettaglioGiocatoreScambio[];
  dettaglioRicevuti: DettaglioGiocatoreScambio[];
  // true se NESSUNO dei giocatori coinvolti ha statistiche di rendimento:
  // la valutazione si basa allora solo su valore/trend prezzo, va segnalato
  // in UI invece di lasciarlo un limite nascosto.
  nessunaStatisticaDisponibile: boolean;
}

// Ogni punto di fantavoto sopra/sotto la sufficienza (6) sposta il valore
// dell'8%, con un tetto del 30% cosi' poche giornate non stravolgono la
// valutazione.
function fattoreForma(mediaFantavoto: number | null): number {
  if (mediaFantavoto == null) return 1;
  const delta = (mediaFantavoto - 6) * 0.08;
  return 1 + Math.max(-0.3, Math.min(0.3, delta));
}

// Una quotazione in crescita durante l'anno e' un segnale positivo
// aggiuntivo; clampato per evitare che dati anomali stravolgano il calcolo.
function fattoreTrend(quotazioneIniziale: number, quotazioneAttuale: number): number {
  if (quotazioneIniziale <= 0) return 1;
  const rapporto = quotazioneAttuale / quotazioneIniziale;
  return Math.max(0.7, Math.min(1.4, rapporto));
}

function calcolaDettaglio(g: GiocatoreScambio): DettaglioGiocatoreScambio {
  const ff = fattoreForma(g.mediaFantavotoRecente);
  const ft = fattoreTrend(g.quotazioneIniziale, g.quotazioneAttuale);
  return {
    id: g.id,
    nome: g.nome,
    valoreBase: g.valoreBase,
    fattoreForma: ff,
    fattoreTrend: ft,
    valoreScambio: Math.round(g.valoreBase * ff * ft),
  };
}

export function valutaScambio(input: ScambioInput): ScambioOutput {
  if (input.dati.length === 0 || input.ricevuti.length === 0) {
    throw new Error("uno scambio deve avere almeno un giocatore dato e uno ricevuto");
  }
  const idsDati = new Set(input.dati.map((g) => g.id));
  if (input.ricevuti.some((g) => idsDati.has(g.id))) {
    throw new Error("un giocatore non può comparire sia tra quelli dati che tra quelli ricevuti");
  }

  const dettaglioDati = input.dati.map(calcolaDettaglio);
  const dettaglioRicevuti = input.ricevuti.map(calcolaDettaglio);

  const totaleDato = dettaglioDati.reduce((sum, d) => sum + d.valoreScambio, 0);
  const totaleRicevuto = dettaglioRicevuti.reduce((sum, d) => sum + d.valoreScambio, 0);
  const percentuale = totaleDato > 0 ? (totaleRicevuto - totaleDato) / totaleDato : 0;

  let verdetto: ScambioOutput["verdetto"];
  if (percentuale > 0.05) verdetto = "FAVOREVOLE";
  else if (percentuale < -0.05) verdetto = "SFAVOREVOLE";
  else verdetto = "EQUILIBRATO";

  const nessunaStatisticaDisponibile = [...input.dati, ...input.ricevuti].every(
    (g) => g.mediaFantavotoRecente == null,
  );

  return {
    verdetto,
    percentuale,
    totaleDato,
    totaleRicevuto,
    dettaglioDati,
    dettaglioRicevuti,
    nessunaStatisticaDisponibile,
  };
}

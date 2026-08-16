export type Fascia = "top" | "semitop" | "fascia_media" | "scommessa";

// Soglie standard delle guide fantacalcio, con budget di riferimento a 500
// crediti: Top da 30 crediti in su, Semitop 15-29, terza fascia/fascia
// media 6-14, Scommesse 1-5 (verificato: SOS Fanta, Fantacalcio-Online,
// Economia e Sport, stagione 2026/27). Scalate linearmente sul budget
// totale configurato dall'utente, cosi' restano corrette anche per leghe
// con budget diverso da 500 (es. 250 o 1000 crediti) senza bisogno di
// aggiornare soglie a mano ogni stagione o scraping esterno: si basano
// solo su FVM/quotazione gia' importati nel listone.
const SOGLIE_STANDARD_BUDGET_500 = { top: 30, semitop: 15, fasciaMedia: 6 };

export function fasciaDiGiocatore(valore: number, budgetTotale: number): Fascia {
  const fattoreScala = budgetTotale / 500;
  if (valore >= SOGLIE_STANDARD_BUDGET_500.top * fattoreScala) return "top";
  if (valore >= SOGLIE_STANDARD_BUDGET_500.semitop * fattoreScala) return "semitop";
  if (valore >= SOGLIE_STANDARD_BUDGET_500.fasciaMedia * fattoreScala) return "fascia_media";
  return "scommessa";
}

export const ETICHETTA_FASCIA: Record<Fascia, string> = {
  top: "Top",
  semitop: "Semitop",
  fascia_media: "Fascia media",
  scommessa: "Scommessa",
};

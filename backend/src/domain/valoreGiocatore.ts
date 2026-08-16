// Valore usato per stimare il peso di un giocatore quando l'FVM non e'
// disponibile nel listone importato: la quotazione attuale resta un
// proxy ragionevole del suo valore relativo. Condiviso tra l'algoritmo
// asta e l'algoritmo formazione.
export function valoreGiocatore(p: { fvm: number | null; quotazioneAttuale: number }): number {
  return p.fvm ?? p.quotazioneAttuale;
}

# Fanta-App

App mobile (Flutter, Android) per aiutare nel fantacalcio: assistente asta, formazione ottimale in base a budget/obiettivi, consigli sugli scambi. **Non è un'app su cui si gioca** — è uno strumento di supporto che affianca la lega ufficiale (es. Fantacalcio.it, Leghe Fantacalcio, ecc).

## Struttura del monorepo

```
fanta-app/
  backend/   API REST + scraper/importer dati (Node.js, TypeScript, Fastify, Prisma)
  mobile/    App Flutter (Android)
  docs/      Note architetturali e decisioni sulle fonti dati
```

## Stato del progetto

**Fase 1 — Fondamenta** (in corso): modello dati, import quotazioni, struttura app base (lista giocatori, dettaglio, squadra utente, impostazioni).

Fasi successive pianificate:
- **Fase 2**: Assistente Asta live
- **Fase 3**: Formazione ottimale
- **Fase 4**: Consigliere Scambi

Dettagli architetturali in [docs/architecture.md](docs/architecture.md) e sulle fonti dati in [docs/data-sources.md](docs/data-sources.md).

## Avvio rapido

### Backend
```bash
cd backend
npm install
npx prisma migrate dev
npm run dev
```

### Mobile
Richiede Flutter SDK installato (vedi https://docs.flutter.dev/get-started/install/windows).
```bash
cd mobile
flutter pub get
flutter run
```

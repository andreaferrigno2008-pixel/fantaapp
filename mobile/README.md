# Fanta-App — mobile (Flutter, Android)

## Stato

Tutto il codice Dart (`lib/`) e `pubspec.yaml` sono pronti. **Mancano ancora i file di progetto nativi Android** (`android/`, Gradle, ecc.): non sono stati generati a mano perché il modo corretto e affidabile per crearli è il comando `flutter create`, che richiede il Flutter SDK — non installato su questa macchina al momento della scrittura.

## Setup (una tantum)

1. Installa il Flutter SDK (include Dart) e Android Studio con l'Android SDK: https://docs.flutter.dev/get-started/install/windows
2. Verifica l'installazione:
   ```bash
   flutter doctor
   ```
   Risolvi eventuali problemi segnalati (licenze Android SDK, `ANDROID_HOME`, ecc.) prima di continuare.
3. Nella cartella `mobile/`, genera i file di piattaforma Android mancanti:
   ```bash
   flutter create --platforms=android --org com.fantaapp .
   ```
   Questo comando aggiunge `android/` senza toccare `lib/`. **Verifica dopo l'esecuzione che `pubspec.yaml` non sia stato sovrascritto** (confronta con git, o riapplica le dipendenze elencate in cima a questo file se necessario) — è una precauzione standard quando si esegue `flutter create` su una cartella non vuota.
4. Installa le dipendenze:
   ```bash
   flutter pub get
   ```
5. Avvia un emulatore Android da Android Studio (o collega un dispositivo fisico con debug USB attivo).
6. Avvia il backend (vedi `../backend/README` nel root del progetto) — l'app si aspetta di trovarlo su `http://10.0.2.2:3000` quando gira su emulatore (loopback verso il computer host).
7. Esegui l'app:
   ```bash
   flutter run
   ```

## Note

- Se testi su un dispositivo fisico anziché sull'emulatore, cambia `defaultBaseUrl` in [`lib/data/api_client.dart`](lib/data/api_client.dart) con l'IP LAN del computer che fa girare il backend (non `10.0.2.2`, che funziona solo da emulatore).
- L'app funziona anche offline in lettura: la lista giocatori viene messa in cache localmente all'ultima sincronizzazione riuscita (vedi `lib/data/local_cache.dart`).

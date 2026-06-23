// ATENÇÃO: Este arquivo é um template.
// Para usar Firebase, execute: flutterfire configure
// O app funciona sem Firebase (modo offline com SQLite local)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase não configurado. Execute: flutterfire configure\n'
      'O app funciona em modo offline sem esta configuração.',
    );
  }
}

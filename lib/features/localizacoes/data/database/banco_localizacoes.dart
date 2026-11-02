import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  Future<Database>? _abertura;

  Future<Database> get conexao async {
    // Reutiliza também uma abertura que ainda está em andamento.
    final abertura = _abertura ??= _abrir();
    try {
      return await abertura;
    } catch (_) {
      if (identical(_abertura, abertura)) _abertura = null;
      rethrow; // A próxima chamada poderá tentar abrir novamente.
    }
  }

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();
    return openDatabase(
      join(pasta, 'localizacoes.db'),
      version: 1,
      onCreate: (banco, versao) async {
        await banco.execute('''
          CREATE TABLE localizacoes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            precisao REAL NOT NULL,
            instante TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> fechar() async {
    final abertura = _abertura;
    _abertura = null;
    if (abertura != null) {
      try {
        final banco = await abertura;
        await banco.close();
      } catch (_) {
        // Se a abertura falhou, não existe conexão a fechar.
      }
    }
  }
}

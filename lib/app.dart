import 'package:flutter/material.dart';
import 'features/localizacoes/data/database/banco_localizacoes.dart';
import 'features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'features/localizacoes/services/servico_localizacao.dart';
import 'features/localizacoes/presentation/screens/tela_coleta.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Uma instância compartilhada: todas as telas usam o mesmo banco.
  final BancoLocalizacoes _banco = BancoLocalizacoes();
  late final RepositorioLocalizacoes _repositorio =
      RepositorioLocalizacoes(_banco);
  final ServicoLocalizacao _servico = ServicoLocalizacao();

  @override
  void dispose() {
    _banco.fechar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minhas localizações',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: TelaColeta(repositorio: _repositorio, servico: _servico),
    );
  }
}

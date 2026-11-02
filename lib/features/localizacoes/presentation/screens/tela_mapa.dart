import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../models/localizacao.dart';
import '../../data/repositories/repositorio_localizacoes.dart';
import '../../services/cache_mapa.dart';
import '../widgets/mapa_localizacoes.dart';

class TelaMapa extends StatefulWidget {
  final RepositorioLocalizacoes repositorio;

  const TelaMapa({super.key, required this.repositorio});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  List<Localizacao> _registros = [];
  BuiltInMapCachingProvider? _cache;
  bool _carregando = true;
  String? _erro;
  int _versao = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final registros = await widget.repositorio.consultar();
      // Prepara a pasta ANTES de criar o widget que baixa as imagens.
      final cache = await CacheMapa.preparar();
      if (!mounted) return;
      setState(() {
        _registros = registros;
        _cache = cache;
        _versao++;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() => _erro = 'Erro ao carregar o mapa: $erro');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _conteudo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) return Center(child: Text(_erro!));
    if (_registros.isEmpty) {
      return const Center(child: Text('Histórico vazio.'));
    }
    return MapaLocalizacoes(
      key: ValueKey(_versao),
      registros: _registros,
      cache: _cache!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de localizações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar registros',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _conteudo(),
    );
  }
}

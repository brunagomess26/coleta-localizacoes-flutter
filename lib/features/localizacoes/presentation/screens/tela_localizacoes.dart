import 'package:flutter/material.dart';
import '../../models/localizacao.dart';
import '../../data/repositories/repositorio_localizacoes.dart';
import '../widgets/item_localizacao.dart';

class TelaLocalizacoes extends StatefulWidget {
  final RepositorioLocalizacoes repositorio;
  final bool Function() coletaAtiva;

  const TelaLocalizacoes({
    super.key,
    required this.repositorio,
    required this.coletaAtiva,
  });

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  List<Localizacao> _registros = [];
  bool _ocupada = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _ocupada = true;
      _erro = null;
    });
    try {
      final registros = await widget.repositorio.consultar();
      if (!mounted) return;
      setState(() => _registros = registros);
    } catch (erro) {
      if (!mounted) return;
      setState(() => _erro = 'Erro ao consultar: $erro');
    } finally {
      if (mounted) setState(() => _ocupada = false);
    }
  }

  Future<void> _limpar() async {
    final ativa = widget.coletaAtiva();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Limpar todo o histórico?'),
        content: Text('A exclusão de todos os registros é permanente, '
            'incluindo os anteriores aos 100 exibidos.'
            '${ativa ? '\nA coleta está ativa: novos registros continuarão sendo salvos.' : ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _ocupada = true);
    try {
      await widget.repositorio.limpar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Histórico limpo com sucesso.')),
      );
      await _carregar();
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao limpar histórico: $erro')),
      );
    } finally {
      if (mounted) setState(() => _ocupada = false);
    }
  }

  Widget _conteudo() {
    if (_ocupada) return const Center(child: CircularProgressIndicator());
    if (_erro != null) return Center(child: Text(_erro!));
    if (_registros.isEmpty) {
      return const Center(child: Text('Histórico vazio.'));
    }
    return ListView.builder(
      itemCount: _registros.length,
      itemBuilder: (_, indice) =>
          ItemLocalizacao(localizacao: _registros[indice]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Últimas 100 localizações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _ocupada ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: _ocupada ? null : _limpar,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: _conteudo(),
    );
  }
}
